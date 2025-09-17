import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_registerpage.dart';
import 'package:file_picker/file_picker.dart';
import 'uploads_page.dart';
import 'dart:convert'; // for jsonDecode
import 'package:flutter/services.dart' show rootBundle; // for loading assets

class VideoUploadPage extends StatefulWidget {
  const VideoUploadPage({Key? key}) : super(key: key);

  @override
  VideoUploadPageState createState() => VideoUploadPageState();
}

class VideoUploadPageState extends State<VideoUploadPage> {
  PlatformFile? runningVideo;
  PlatformFile? jumpingVideo;
  PlatformFile? pushupsVideo;

  String userName = "Guest"; // default if skipped login

  Future<void> pickVideo(String type) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        if (type == 'running') runningVideo = result.files.first;
        if (type == 'jumping') jumpingVideo = result.files.first;
        if (type == 'pushups') pushupsVideo = result.files.first;
      });
    }
  }

  Widget instructionTile(String step) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30, width: 1),
      ),
      child: Text(
        step,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget actionTile(String title, PlatformFile? file, String type) {
    return GestureDetector(
      onTap: () => pickVideo(type),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.video_camera_back,
              size: 30,
              color: Colors.black87,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title + (file != null ? " : ${file.name}" : ""),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.upload_file, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  //UPLOAD VIDEO FUNCTION

  void uploadVideo() async {
    if (runningVideo != null && jumpingVideo != null && pushupsVideo != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Please login first")));
        return;
      }

      List<String> videoNames = [
        runningVideo!.name,
        jumpingVideo!.name,
        pushupsVideo!.name,
      ];

      // Load sample JSON from assets
      final String jsonString = await rootBundle.loadString(
        'ML_assets/sample_analysis.json',
      );
      final Map<String, dynamic> analysisData = jsonDecode(jsonString);

      String uploadId = FirebaseFirestore.instance
          .collection('uploads')
          .doc()
          .id;

      await FirebaseFirestore.instance.collection('uploads').doc(uploadId).set({
        "user_id": user.uid,
        "video_names": videoNames,
        "upload_date": DateTime.now(),
        "status": "draft",
        "verdict": "ongoing",
        "analysis": analysisData, //nested JSON data
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload saved as draft!")));

      setState(() {
        runningVideo = null;
        jumpingVideo = null;
        pushupsVideo = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required videos.")),
      );
    }
  }

  /*
  void submitVideos() {
    if (runningVideo != null && jumpingVideo != null && pushupsVideo != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Videos submitted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required videos.")),
      );
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6E6F2), // light vintage blue
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6E6F2),
        elevation: 0,
        title: const Text(
          "Sports Talent Platform",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        //SIDE NAVIGATION BAR
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: const Color(0xFFD6E6F2)),
              child: Text(
                "Hello $userName",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text("Uploads"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadsPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text("Contact"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Instructions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            instructionTile(
              "Running: Place your phone in pocket or on tripod. Record 20-30m sprint.",
            ),
            instructionTile(
              "Jumping: Ensure full body is visible from the side. Perform 2-3 jumps.",
            ),
            instructionTile(
              "Pushups: Phone should capture full torso, side/front view. Perform maximum correct reps in 60 seconds.",
            ),
            const SizedBox(height: 20),
            const Text(
              "Upload Videos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            actionTile("Running Video", runningVideo, 'running'),
            actionTile("Jumping Video", jumpingVideo, 'jumping'),
            actionTile("Pushups Video", pushupsVideo, 'pushups'),
            const SizedBox(height: 30),
            Center(
              child: GestureDetector(
                onTap: uploadVideo, //VIDEO UPLOAD FUNCTION CALLED
                child: Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      "Submit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
