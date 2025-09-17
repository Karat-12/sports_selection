import os
import tempfile
import time
import numpy as np
from flask import Flask, request, jsonify
from tensorflow.keras.models import load_model

import cv2
import mediapipe as mp

app = Flask(__name__)
model = load_model('exercise_correctness_model.h5')
labels = ['Jumping Jacks', 'Push-ups', 'Pull-ups', 'Squats', 'Russian Twists']

mp_pose = mp.solutions.pose

def extract_angles_from_landmarks(landmarks, image_shape):
    ih, iw = image_shape

    def lm_to_point(lm):
        return [lm.x * iw, lm.y * ih]

    shoulder_l = lm_to_point(landmarks[mp_pose.PoseLandmark.LEFT_SHOULDER.value])
    elbow_l = lm_to_point(landmarks[mp_pose.PoseLandmark.LEFT_ELBOW.value])
    wrist_l = lm_to_point(landmarks[mp_pose.PoseLandmark.LEFT_WRIST.value])
    hip_l = lm_to_point(landmarks[mp_pose.PoseLandmark.LEFT_HIP.value])
    knee_l = lm_to_point(landmarks[mp_pose.PoseLandmark.LEFT_KNEE.value])
    ankle_l = lm_to_point(landmarks[mp_pose.PoseLandmark.LEFT_ANKLE.value])

    shoulder_r = lm_to_point(landmarks[mp_pose.PoseLandmark.RIGHT_SHOULDER.value])
    elbow_r = lm_to_point(landmarks[mp_pose.PoseLandmark.RIGHT_ELBOW.value])
    wrist_r = lm_to_point(landmarks[mp_pose.PoseLandmark.RIGHT_WRIST.value])
    hip_r = lm_to_point(landmarks[mp_pose.PoseLandmark.RIGHT_HIP.value])
    knee_r = lm_to_point(landmarks[mp_pose.PoseLandmark.RIGHT_KNEE.value])
    ankle_r = lm_to_point(landmarks[mp_pose.PoseLandmark.RIGHT_ANKLE.value])

    def calculate_angle(a, b, c):
        import numpy as np
        a = np.array(a)
        b = np.array(b)
        c = np.array(c)
        radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
        angle = np.abs(radians*180.0/np.pi)
        if angle > 180.0:
            angle = 360 - angle
        return angle

    # Calculate 11 angles as before...
    knee_angle_l = calculate_angle(hip_l, knee_l, ankle_l)
    ankle_angle_l = calculate_angle(knee_l, ankle_l, [ankle_l[0], ankle_l[1] - 1])
    shoulder_ground_angle_l = calculate_angle(shoulder_l, hip_l, [hip_l[0], hip_l[1] + 100])
    elbow_ground_angle_l = calculate_angle(elbow_l, shoulder_l, [shoulder_l[0], shoulder_l[1] + 100])
    hip_ground_angle_l = calculate_angle(hip_l, knee_l, [knee_l[0], knee_l[1] + 100])
    knee_ground_angle_l = calculate_angle(knee_l, ankle_l, [ankle_l[0], ankle_l[1] + 100])
    ankle_ground_angle_l = calculate_angle(ankle_l, [ankle_l[0], ankle_l[1] - 1], [ankle_l[0], ankle_l[1] + 100])

    knee_angle_r = calculate_angle(hip_r, knee_r, ankle_r)
    ankle_angle_r = calculate_angle(knee_r, ankle_r, [ankle_r[0], ankle_r[1] - 1])
    shoulder_ground_angle_r = calculate_angle(shoulder_r, hip_r, [hip_r[0], hip_r[1] + 100])
    elbow_ground_angle_r = calculate_angle(elbow_r, shoulder_r, [shoulder_r[0], shoulder_r[1] + 100])

    angles = [
        knee_angle_l,
        ankle_angle_l,
        shoulder_ground_angle_l,
        elbow_ground_angle_l,
        hip_ground_angle_l,
        knee_ground_angle_l,
        ankle_ground_angle_l,
        knee_angle_r,
        ankle_angle_r,
        shoulder_ground_angle_r,
        elbow_ground_angle_r
    ]

    angles = [0 if (np.isnan(a) or a is None) else a for a in angles]

    return angles

def extract_pose_angle_sequence(video_path, seq_length=30):
    cap = cv2.VideoCapture(video_path)
    angle_sequence = []

    pose = mp_pose.Pose(static_image_mode=False, min_detection_confidence=0.5)

    while len(angle_sequence) < seq_length:
        ret, frame = cap.read()
        if not ret:
            break
        image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(image_rgb)
        if results.pose_landmarks:
            angles = extract_angles_from_landmarks(results.pose_landmarks.landmark, frame.shape[:2])
            angle_sequence.append(angles)
        else:
            angle_sequence.append([0]*11)

    cap.release()
    pose.close()

    while len(angle_sequence) < seq_length:
        angle_sequence.append([0]*11)

    return np.array(angle_sequence, dtype=np.float32)

def process_video(file):
    # Create temp file in a 'with' block so it closes immediately after saving
    with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as tmp:
        file.save(tmp.name)
        temp_path = tmp.name

    angles_seq = extract_pose_angle_sequence(temp_path, seq_length=30)

    input_data = np.expand_dims(angles_seq, axis=0)
    preds = model.predict(input_data)
    pred_idx = np.argmax(preds)
    confidence = preds[0][pred_idx]

    os.unlink(temp_path)

    return labels[pred_idx], confidence

@app.route('/upload_multiple', methods=['POST'])
def upload_multiple_videos():
    if 'videos' not in request.files:
        return jsonify({'error': 'No videos uploaded.'}), 400

    videos = request.files.getlist('videos')
    if not videos:
        return jsonify({'error': 'No video files provided.'}), 400

    results = []
    for video_file in videos:
        exercise, confidence = process_video(video_file)
        results.append({
            'filename': video_file.filename,
            'exercise': exercise,
            'confidence': float(confidence)
        })

    required_exercises = ['Push-ups', 'Squats', 'Jumping Jacks']
    eligible = all(any(r['exercise'] == req and r['confidence'] > 0.7 for r in results) for req in required_exercises)

    report = "Eligible for selection" if eligible else "Not eligible"

    return jsonify({
        'per_video_results': results,
        'final_report': report
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)

