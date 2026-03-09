import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PredictService {
  static Future<Map<String, dynamic>> predictImage(File imageFile) async {
    final uri = Uri.parse("http://127.0.0.1:8000/predict");

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception("Prediction failed: ${response.statusCode}");
    }
  }
}
