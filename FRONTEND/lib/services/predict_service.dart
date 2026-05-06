import 'dart:io';
import 'tflite_service.dart';
import 'dart:developer' as dev;

class PredictService {
  static Future<Map<String, dynamic>> predictImage(File imageFile) async {
    dev.log("Starting offline prediction...");
    try {
      // Prioritize Offline TFLite Inference
      final result = await TfliteService.predict(imageFile);
      return result;
    } catch (e) {
      dev.log("Offline prediction failed, check model/assets: $e");
      // Fallback to "Unknown" if everything fails
      return {'shade': 'Unknown', 'confidence': 0.0};
    }
  }
}
