import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  final String accountId = dotenv.get('CLOUDFLARE_ACCOUNT_ID');
  final String apiToken = dotenv.get('CLOUDFLARE_API_TOKEN');
  final String model = "@cf/stabilityai/stable-diffusion-xl-base-1.0";

  Future<Uint8List?> generateImage(String prompt) async {
    final url = Uri.parse(
      "https://api.cloudflare.com/client/v4/accounts/$accountId/ai/run/$model",
    );
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"prompt": prompt}),
      );
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> editImage(Uint8List sourceImage, String prompt) async {
    final url = Uri.parse(
      "https://api.cloudflare.com/client/v4/accounts/$accountId/ai/run/$model",
    );

    try {
      String base64Image = base64Encode(sourceImage);

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "prompt": prompt,
          "image_b64": base64Image,
          "strength": 0.5,
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print("Cloudflare Edit Error: ${response.statusCode}");
        print("Response Body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Connection Exception: $e");
      return null;
    }
  }
}
