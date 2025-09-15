import numpy as np
from tensorflow.keras.models import load_model
from pose_extractor import extract_pose_angle_sequence

# Load your trained model file
model = load_model('exercise_correctness_model.h5')

# Input test video path
video_path = r'path/to/your_pushup_video.mp4'
seq_length = 30

# Extract angles sequence using your updated pose extractor
angles_seq = extract_pose_angle_sequence(video_path, seq_length)

# Check shape and prepare input shape (1, 30, 11)
print("Input shape for model:", angles_seq.shape)
input_data = np.expand_dims(angles_seq, axis=0)

# Run prediction
predictions = model.predict(input_data)
predicted_index = np.argmax(predictions)
confidence = predictions[0][predicted_index]

# Adjust labels based on your training dataset classes
labels = ['Jumping Jacks', 'Push-ups', 'Pull-ups', 'Squats', 'Russian Twists']

print(f"Predicted exercise: {labels[predicted_index]} with confidence {confidence:.2f}")
