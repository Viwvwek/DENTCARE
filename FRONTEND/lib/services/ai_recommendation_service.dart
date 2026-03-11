import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIRecommendationService {
  static Future<String> generateTreatmentRecommendation({
    required String predictedShade,
    required double confidence,
    String? patientNotes,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return "AI recommendations are currently disabled due to missing API key. Please check configuration.";
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );

      final prompt = """
You are an elite AI dental consultant working for DentCare Premium services.
A dental scan has just been analyzed and predicted the tooth shade as VITA Classical: "$predictedShade" with a confidence of ${(confidence * 100).toStringAsFixed(1)}%.
${patientNotes != null ? "Patient context/Notes: $patientNotes" : ""}

Please provide a concise, highly professional clinical recommendation (2-3 short paragraphs max).
Include:
1. Implications of this specific shade (e.g., $predictedShade indicates a specific brightness/hue).
2. Potential restoratives or bleaching protocols to consider.
3. Next steps for the clinician.
Keep the tone clinical, objective, and premium. Do not use generic greetings, just output the recommendation directly.
""";

      final response = await model.generateContent([Content.text(prompt)]);
      
      return response.text?.trim() ?? "Unable to generate recommendation at this time. Please proceed with standard clinical protocol.";
    } catch (e) {
      return "Analysis engine error. Standard protocol advised. Error detail: $e";
    }
  }
}
