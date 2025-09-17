// index.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
const multer = require('multer');
const fs = require('fs');
const crypto = require('crypto');
const { spawn } = require('child_process');
const path = require('path');

// --- Init Firebase Admin ---
const serviceAccountPath = process.env.SERVICE_ACCOUNT_PATH || './serviceAccountKey.json';
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Missing serviceAccountKey.json. Put file path in SERVICE_ACCOUNT_PATH');
  process.exit(1);
}
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || undefined
});
const db = admin.firestore();
const bucket = admin.storage().bucket ? admin.storage().bucket() : null;

// --- Express setup ---
const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' })); // allow large JSON summaries if needed
app.get("/test/:id", (req, res) => {
  console.log("Test route hit!", req.params.id);
  res.json({ ok: true, id: req.params.id });
});



// --- Helper: stable JSON stringify (deterministic) for HMAC ---
function stableStringify(obj) {
  if (obj === null || typeof obj !== 'object') return JSON.stringify(obj);
  if (Array.isArray(obj)) return '[' + obj.map(stableStringify).join(',') + ']';
  const keys = Object.keys(obj).sort();
  return '{' + keys.map(k => JSON.stringify(k) + ':' + stableStringify(obj[k])).join(',') + '}';
}

// --- HMAC verification middleware ---
function verifyHmac(req, res, next) {
  const signature = req.get('x-signature'); // frontend should send this header
  if (!signature) {
    req.signature_valid = false;
    return next();
  }
  const secret = process.env.HMAC_SECRET || '';
  const payload = stableStringify(req.body);
  try {
    const expected = crypto.createHmac('sha256', secret).update(payload).digest('hex');
    // safe compare
    const valid = expected.length === signature.length && crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
    req.signature_valid = valid;
  } catch (err) {
    req.signature_valid = false;
  }
  next();
}

// --- Basic plausibility flags helper ---
function addPlausibilityFlags(testType, metrics) {
  const flags = [];
  if (testType === 'sprint') {
    if (metrics.topSpeed && metrics.topSpeed > 15) flags.push('unrealistic_top_speed');
    if (metrics.reactionTime && metrics.reactionTime < 0.03) flags.push('impossible_reaction_time');
  }
  if (testType === 'jump') {
    if (metrics.jumpHeight && metrics.jumpHeight > 120) flags.push('unrealistic_jump_height_cm');
    if (metrics.flightTime && metrics.flightTime > 1.2) flags.push('implausible_flight_time');
  }
  if (testType === 'endurance') {
    if (metrics.reps && metrics.reps > 500) flags.push('unrealistic_reps');
  }
  return flags;
}

// --- Route: health ---
app.get('/ping', (req, res) => res.json({ message: 'Backend alive' }));

// --- Route: submit generic test ---  (frontend or on-device ML calls this)
app.post('/api/submit-test', verifyHmac, async (req, res) => {
  try {
    const { athleteId, testType, metrics, deviceInfo, recordingTime, videoHash } = req.body;
    if (!athleteId || !testType || !metrics) return res.status(400).json({ error: 'athleteId, testType and metrics are required' });

    // plausibility & flags
    const flags = addPlausibilityFlags(testType, metrics);

    // authenticity info (HMAC signature)
    const authenticity = {
      signature_valid: !!req.signature_valid
    };

    const record = {
      athleteId,
      testType,
      metrics,
      deviceInfo: deviceInfo || {},
      recordingTime: recordingTime || new Date().toISOString(),
      videoHash: videoHash || null,
      flags,
      authenticity,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // store into results collection and merge into athlete doc
    const docRef = await db.collection('results').add(record);
    await db.collection('athletes').doc(athleteId).set({
      [testType]: { metrics, flags, authenticity, updatedAt: admin.firestore.FieldValue.serverTimestamp() }
    }, { merge: true });

    return res.json({ message: 'Saved', id: docRef.id, flags, authenticity });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
});

// --- Multer for video upload ---
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir);
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => cb(null, `${Date.now()}_${file.originalname}`)
});
const upload = multer({ storage, limits: { fileSize: 200 * 1024 * 1024 } }); // up to 200MB

// --- Route: upload video file (multipart/form-data) ---
app.post('/api/upload-video', upload.single('video'), async (req, res) => {
  try {
    const athleteId = req.body.athleteId;
    if (!athleteId) {
      // remove file if any
      if (req.file) fs.unlinkSync(req.file.path);
      return res.status(400).json({ error: 'athleteId required' });
    }
    if (!req.file) return res.status(400).json({ error: 'video file required (field: video)' });

    if (!bucket) {
      return res.status(500).json({ error: 'Firebase storage not configured on server' });
    }

    const localPath = req.file.path;
    const dest = `videos/${athleteId}/${path.basename(localPath)}`;

    // upload to Firebase Storage
    await bucket.upload(localPath, {
      destination: dest,
      metadata: { contentType: req.file.mimetype }
    });

    // get signed url (long-lived for demo). In production set limited expiry.
    const fileRef = bucket.file(dest);
    const [signedUrl] = await fileRef.getSignedUrl({ action: 'read', expires: '03-01-2505' });

    // save metadata in Firestore videos collection
    const meta = {
      athleteId,
      storagePath: dest,
      downloadUrl: signedUrl,
      originalName: req.file.originalname,
      size: req.file.size,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    };
    const vref = await db.collection('videos').add(meta);

    // remove local copy
    fs.unlinkSync(localPath);

    return res.json({ message: 'Uploaded', videoId: vref.id, meta });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
});

// --- Route: request heavy processing on uploaded video (optional) ---
app.post('/api/process-video', async (req, res) => {
  try {
    const { videoStoragePath } = req.body;
    if (!videoStoragePath) return res.status(400).json({ error: 'videoStoragePath required (e.g., videos/athleteX/file.mp4)' });

    // Download file to local temp (simplest for demo)
    const tmpLocal = path.join(__dirname, 'uploads', `dl_${Date.now()}_${path.basename(videoStoragePath)}`);
    const file = bucket.file(videoStoragePath);
    await file.download({ destination: tmpLocal });

    // spawn python ML script if exists
    const pythonScript = path.join(__dirname, 'ml', 'forgery_detector.py');
    if (!fs.existsSync(pythonScript)) {
      // cleanup
      fs.unlinkSync(tmpLocal);
      return res.status(500).json({ error: 'ML script not found on server (ml/forgery_detector.py)' });
    }

    const py = spawn('python', [pythonScript, tmpLocal]);

    let out = '';
    let errOut = '';
    py.stdout.on('data', d => out += d.toString());
    py.stderr.on('data', d => errOut += d.toString());

    py.on('close', code => {
      // cleanup
      if (fs.existsSync(tmpLocal)) fs.unlinkSync(tmpLocal);

      if (errOut) console.error('Python stderr:', errOut);
      try {
        const parsed = JSON.parse(out);
        return res.json({ success: true, result: parsed });
      } catch (e) {
        return res.status(500).json({ error: 'ML parsing error', details: out, stderr: errOut });
      }
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
});

// --- Route: get aggregated scorecard for athlete ---
app.get("/api/results/:athleteId", async (req, res) => {
  try {
    const { athleteId } = req.params;

    // Fetch athlete summary
    const athleteDoc = await db.collection("athletes").doc(athleteId).get();
    const athleteData = athleteDoc.exists ? athleteDoc.data() : null;

    // Fetch all results for this athlete
    const resultsSnapshot = await db.collection("results")
      .where("athleteId", "==", athleteId)
      .get();
    const results = [];
    resultsSnapshot.forEach(doc => results.push({ id: doc.id, ...doc.data() }));

    if (!athleteData && results.length === 0) {
      return res.status(404).json({ message: "Athlete not found" });
    }

    res.json({
      athleteId,
      athleteData,
      results
    });
  } catch (error) {
    console.error("Error fetching results:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// --- Start server ---
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Backend listening on http://localhost:${PORT}`));
