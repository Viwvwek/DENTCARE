import json
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow.keras.models import load_model


# ---------- Load metadata ----------
with open("class_indicesA.json", "r") as f:
    class_indices = json.load(f)

# index → class name
CLASSES = sorted(class_indices.keys(), key=lambda k: class_indices[k])


# ---------- Load model ----------
MODEL_PATH = "teeth_classifierA.keras"
model = load_model(MODEL_PATH)


# ---------- Simple preprocess ----------
def preprocess_image(image_path, img_size=224):
    img = Image.open(image_path).convert("RGB")
    img = img.resize((img_size, img_size))
    arr = np.array(img).astype("float32")
    arr = arr / 255.0  # simple normalization
    arr = np.expand_dims(arr, axis=0)
    return arr


# ---------- Prediction function ----------
def predict_image(image_path):
    print(f"Analyzing image: {image_path}")
    inp = preprocess_image(image_path)
    probs = model.predict(inp)[0]

    top_idx = int(np.argmax(probs))
    confidence = float(probs[top_idx])

    result = {
        "shade": CLASSES[top_idx],
        "confidence": round(confidence, 3)
    }
    print(f"Prediction result: {result}")
    return result
