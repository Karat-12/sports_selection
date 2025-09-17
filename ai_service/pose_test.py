from pose_extractor import extract_pose_angle_sequence
import numpy as np

video_path = 'D:\\sports_person_selection\\Recording 2025-09-14 134057.mp4'
seq_length = 30  # Number of frames per extracted sequence

# Extract angles sequence from video
angles_seq = extract_pose_angle_sequence(video_path, seq_length=seq_length)

print("Extracted pose angle sequence shape:", angles_seq.shape)

# Print angles for first and last frames to verify
print("First frame angles:", angles_seq[0])
print("Last frame angles:", angles_seq[-1])
