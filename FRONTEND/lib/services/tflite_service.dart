import 'package:tflite_v2/tflite_v2.dart';
import 'dart:io';
import 'dart:developer' as dev;

class TfliteService {
  static bool _isModelLoaded = false;

  static Future<void> loadModel() async {
    if (_isModelLoaded) return;
    try {
      dev.log("Loading TFLite v2 model...");
      String? res = await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );
      _isModelLoaded = res != null;
      dev.log("Model loaded: $_isModelLoaded");
    } catch (e) {
      dev.log("Error loading TFLite model: $e");
    }
  }

  static Future<Map<String, dynamic>> predict(File imageFile) async {
    await loadModel();
    if (!_isModelLoaded) {
      return {'shade': 'Error', 'confidence': 0.0};
    }

    try {
      var recognitions = await Tflite.runModelOnImage(
        path: imageFile.path,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 1,
        threshold: 0.1,
      );

      if (recognitions == null || recognitions.isEmpty) {
        return {'shade': 'Unknown', 'confidence': 0.0};
      }

      final label = recognitions[0]['label'];
      final confidence = recognitions[0]['confidence'];

      dev.log("Prediction: $label ($confidence)");
      return {
        'shade': label,
        'confidence': confidence,
      };
    } catch (e) {
      dev.log("Prediction error: $e");
      return {'shade': 'Error', 'confidence': 0.0};
    }
  }

  static Future<void> dispose() async {
    await Tflite.close();
    _isModelLoaded = false;
  }
}
