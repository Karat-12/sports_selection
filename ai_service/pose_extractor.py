import cv2
import numpy as np
import mediapipe as mp

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
        a = np.array(a)
        b = np.array(b)
        c = np.array(c)
        radians = np.arctan2(c[1]-b[1], c[0]-b[0]) - np.arctan2(a[1]-b[1], a[0]-b[0])
        angle = np.abs(radians * 180.0 / np.pi)
        if angle > 180.0:
            angle = 360 - angle
        return angle

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

    # Replace NaNs with zeroes
    angles = [0 if (np.isnan(a) or a is None) else a for a in angles]

    return angles

def normalize_angles(angle_sequence):
    # Normalize each angle from degrees to 0-1 range
    angle_sequence = np.array(angle_sequence)
    normalized = angle_sequence / 180.0
    return normalized

def smooth_angles(angle_sequence, window_size=3):
    smoothed = np.copy(angle_sequence)
    for i in range(angle_sequence.shape[1]):  # loop over each angle dimension
        smoothed[:, i] = np.convolve(angle_sequence[:, i], np.ones(window_size) / window_size, mode='same')
    return smoothed

def extract_pose_angle_sequence(video_path, seq_length=30):
    cap = cv2.VideoCapture(video_path)
    pose = mp_pose.Pose(static_image_mode=False, min_detection_confidence=0.5)

    angle_sequence = []
    while len(angle_sequence) < seq_length:
        ret, frame = cap.read()
        if not ret:
            break
        img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = pose.process(img_rgb)
        if results.pose_landmarks:
            angles = extract_angles_from_landmarks(results.pose_landmarks.landmark, frame.shape[:2])
            angle_sequence.append(angles)
        else:
            angle_sequence.append([0] * 11)

    cap.release()
    pose.close()

    # Pad sequence if shorter than seq_length
    while len(angle_sequence) < seq_length:
        angle_sequence.append([0] * 11)

    angle_sequence = normalize_angles(angle_sequence)
    angle_sequence = smooth_angles(angle_sequence, window_size=3)
    return angle_sequence.astype(np.float32)
