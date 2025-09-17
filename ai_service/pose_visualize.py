import cv2
import mediapipe as mp

video_path = 'D:\\sports_person_selection\\Recording 2025-09-14 134057.mp4'

mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

cap = cv2.VideoCapture(video_path)
if not cap.isOpened():
    print(f"Error: Cannot open video file {video_path}")
    exit()

pose = mp_pose.Pose(static_image_mode=False, min_detection_confidence=0.5)

while True:
    ret, frame = cap.read()
    if not ret:
        print("End of video or cannot read the frame.")
        break

    print("Frame read successfully")  # Debug print

    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = pose.process(image_rgb)

    if results.pose_landmarks:
        mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
    
    cv2.imshow('Pose Detection', frame)

    # Increased wait time to 30 ms to allow GUI to update properly
    if cv2.waitKey(30) & 0xFF == ord('q'):
        print("Quitting visualization.")
        break

cap.release()
cv2.destroyAllWindows()
