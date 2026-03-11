import time
import psutil
from fastapi import FastAPI, UploadFile, File, HTTPException
import os
import tempfile
from starlette.concurrency import run_in_threadpool
from model_code import predict_image

app = FastAPI(title="DentCare AI Backend", version="2.0.0")

# Track start time for uptime calculation
START_TIME = time.time()

@app.get("/")
def root():
    return {"status": "DentShade backend running", "model": "teeth_classifierA"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    # Use a temporary file carefully
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg", mode="wb") as tmp:
        try:
            content = await file.read()
            tmp.write(content)
            tmp_path = tmp.name
        finally:
            tmp.close()

    try:
        # Run the CPU-bound prediction in a threadpool to avoid blocking
        result = await run_in_threadpool(predict_image, tmp_path)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")
    finally:
        # Always clean up the temp file
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

    return result

@app.get("/health")
def health_check():
    return {
        "status": "online",
        "service": "dentshade-inference",
        "version": "2.0.0",
        "uptime_seconds": round(time.time() - START_TIME)
    }

@app.get("/metrics")
def get_metrics():
    process = psutil.Process(os.getpid())
    return {
        "cpu_usage_percent": psutil.cpu_percent(interval=0.1),
        "ram_usage_mb": round(process.memory_info().rss / (1024 * 1024), 2),
        "active_threads": process.num_threads(),
        "gpu_available": False, # Switch to True if TensorFlow picks up a GPU
        "tflite_model": "teeth_classifierA.h5 (Keras/optimized)"
    }
