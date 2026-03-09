from fastapi import FastAPI, UploadFile, File
import shutil
import os

from model_code import predict_image

app = FastAPI()


@app.get("/")
def root():
    return {"status": "DentShade backend running"}


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    # Save uploaded image temporarily
    temp_path = f"temp_{file.filename}"

    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Run prediction
    result = predict_image(temp_path)

    # Clean up
    os.remove(temp_path)

    return result
