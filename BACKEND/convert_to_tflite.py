import tensorflow as tf
import os

model_path = r'c:\Users\vivek\DENTCARE\BACKEND\teeth_classifierA.keras'
tflite_path = r'c:\Users\vivek\DENTCARE\FRONTEND\assets\model.tflite'

# Create assets folder if it doesn't exist
os.makedirs(os.path.dirname(tflite_path), exist_ok=True)

print(f"Loading model from {model_path}...")
model = tf.keras.models.load_model(model_path)

print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

print(f"Saving TFLite model to {tflite_path}...")
with open(tflite_path, 'wb') as f:
    f.write(tflite_model)

print("Conversion successful!")
