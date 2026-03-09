# 🦷 DentShade — AI-Based Dental Shade Detection

DentShade is a mobile application that uses deep learning to automatically detect and predict dental tooth shades from images. Built with **Flutter** for the frontend and **FastAPI + TensorFlow** for the backend, the app delivers real-time shade predictions with confidence scores directly on your Android device.

---

## ✨ Features

- 📸 Capture dental images using the device camera
- 🖼️ Upload images from the gallery
- 🤖 AI-powered dental shade prediction (EfficientNet model)
- 📊 Confidence score display per prediction
- 🔐 User authentication (signup / login)
- 🎨 Custom splash screen & app icon
- 📱 Clean, responsive Flutter UI

---

## 🏗️ System Architecture

```
Flutter Mobile App
       ↓
HTTP Image Upload (multipart/form-data)
       ↓
FastAPI Backend
       ↓
TensorFlow / Keras Model (.keras)
       ↓
Prediction (Shade + Confidence Score)
       ↓
JSON Response → Flutter UI Display
```

---

## 🛠️ Tech Stack

| Layer     | Technology                              |
|-----------|------------------------------------------|
| Frontend  | Flutter, Dart, HTTP, Camera, Image Picker |
| Backend   | Python, FastAPI, TensorFlow/Keras, Uvicorn |

---

## 📁 Project Structure

```
DentShade/
├── frontend/
│   └── dentcare/
│       ├── lib/
│       │   ├── main.dart
│       │   ├── login.dart
│       │   ├── signup.dart
│       │   ├── home.dart
│       │   ├── getstart.dart
│       │   └── services/
│       │       └── predict_service.dart
│       └── pubspec.yaml
│
└── backend/
    ├── app.py
    ├── model_code.py
    ├── dentshade_model.keras
    ├── class_indices.json
    └── class_indices_config.json
```

---

## 🚀 Getting Started

The backend and frontend run **separately**. Follow the steps below in order.

---

### 1️⃣ Run the Backend (FastAPI)

Navigate to the `backend/` folder.

**Create and activate a virtual environment (recommended):**

```bash
python -m venv venv
```

```bash
# Windows
venv\Scripts\activate

# Mac / Linux
source venv/bin/activate
```

**Install dependencies:**

```bash
pip install fastapi uvicorn tensorflow pillow python-multipart
```

**Start the server:**

```bash
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

The backend will be available at:

```
http://<YOUR_LOCAL_IP>:8000
```

> **Tip:** Visit `http://localhost:8000/docs` in your browser to explore and test the API via the interactive Swagger UI.

---

### 2️⃣ Prepare Your Android Device

1. Enable **USB Debugging** on your Android phone
2. Connect the phone to your computer via **USB**
3. Ensure **both devices are on the same WiFi network**

---

### 3️⃣ Find Your Local IP Address

```bash
# Windows
ipconfig

# Mac / Linux
ifconfig
```

Copy your **IPv4 Address** (e.g., `192.168.1.5`).

---

### 4️⃣ Configure the Backend URL in Flutter

Open `frontend/dentcare/lib/services/predict_service.dart` and update the endpoint:

```dart
final uri = Uri.parse("http://192.168.1.5:8000/predict");
```

Replace `192.168.1.5` with your actual local IP address.

---

### 5️⃣ Verify Connectivity

Before launching the app, confirm the backend is reachable by opening the following in your phone's browser:

```
http://192.168.1.5:8000
```

If a response appears, you're good to go.

---

### 6️⃣ Run the Flutter App

```bash
cd frontend/dentcare
flutter pub get
flutter run
```

The app will build and launch on your connected Android device.

---

## 📱 Using the App

1. **Sign up** with an email and password, or use the test account:
   ```
   Email:    example@gmail.com
   Password: 123456
   ```
2. Navigate to **Shade Analysis**
3. Choose **Upload from Gallery** or **Capture with Camera**
4. The image is sent to the backend for inference
5. The **predicted shade** and **confidence score** are displayed

---

## 🌐 Networking Notes

| Setup | API Endpoint |
|---|---|
| Physical Android device (same WiFi) | `http://<YOUR_IPv4>:8000/predict` |
| Android Emulator | `http://10.0.2.2:8000/predict` |

> ⚠️ Do **not** use `http://localhost:8000` on a physical device — it will not work.

---

## 📡 API Reference

### `POST /predict`

Accepts a dental image and returns the predicted shade with confidence.

**Request:** `multipart/form-data`

| Field | Type | Description |
|-------|------|-------------|
| `file` | Image file | Dental image (JPEG/PNG) |

**Response:**

```json
{
  "shade": "A2",
  "confidence": 0.94
}
```

---

## 🧠 Model Details

| Property | Details |
|----------|---------|
| Architecture | EfficientNet |
| Framework | TensorFlow / Keras |
| Format | `.keras` |
| Output | Shade class label + confidence score |
| Label mapping | `class_indices.json` |

---

## 👨‍💻 Developed By

**DentShade Team** — AI-Based Dental Shade Detection System