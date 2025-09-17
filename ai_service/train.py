import pandas as pd
import numpy as np
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout, Bidirectional, Input
from tensorflow.keras.callbacks import ModelCheckpoint
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

# Set CSV path (update to actual path)
csv_path = r'D:\sports_person_selection\ai_service\dataset\angles.csv'
df = pd.read_csv(csv_path)

# Exclude non-numeric columns
non_feature_cols = ['Label', 'side']  # add other non-numeric columns if present
angle_columns = [col for col in df.columns if col not in non_feature_cols]

print("Using feature columns:", angle_columns)

SEQ_LENGTH = 30
X, y = [], []

for i in range(0, len(df) - SEQ_LENGTH + 1, SEQ_LENGTH):
    seq_df = df.iloc[i:i+SEQ_LENGTH][angle_columns].apply(pd.to_numeric, errors='coerce')
    seq = seq_df.values
    # Replace NaNs with zeros
    seq = np.nan_to_num(seq)
    label = df['Label'].iloc[i]
    X.append(seq)
    y.append(label)

X = np.array(X, dtype=np.float32)
y = np.array(y)

print(f'Shape of feature data: {X.shape}, dtype: {X.dtype}')

# Encode labels to integers
le = LabelEncoder()
y_encoded = le.fit_transform(y)

# Train-validation split
X_train, X_val, y_train, y_val = train_test_split(
    X, y_encoded, test_size=0.2, stratify=y_encoded, random_state=42
)

print(f"Training samples: {X_train.shape[0]}, Validation samples: {X_val.shape[0]}")
print(f"Input shape (per sample): {X_train.shape[1:]}")

# Build LSTM model
model = Sequential([
    Input(shape=(SEQ_LENGTH, len(angle_columns))),
    Bidirectional(LSTM(64, return_sequences=True)),
    Dropout(0.3),
    LSTM(32),
    Dropout(0.3),
    Dense(16, activation='relu'),
    Dense(len(le.classes_), activation='softmax')
])

model.compile(
    optimizer='adam',
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

model.summary()

checkpoint = ModelCheckpoint('exercise_correctness_model.h5', save_best_only=True, monitor='val_accuracy', verbose=1)

model.fit(
    X_train, y_train,
    validation_data=(X_val, y_val),
    epochs=15,
    batch_size=8,
    callbacks=[checkpoint]
)

# Evaluate model
model.load_weights('exercise_correctness_model.h5')
y_pred = model.predict(X_val).argmax(axis=1)

print("\nClassification Report:")
print(classification_report(y_val, y_pred, target_names=le.classes_))
