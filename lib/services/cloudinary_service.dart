import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
 
  static const String cloudName = "dmteuzsos";

  // Upload preset you created in screenshot
  static const String uploadPreset = "dmteuzsos";

  static Future<String?> uploadImage(File file) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['secure_url']; // cloudinary image URL
    } else {
      print("Cloudinary error: $responseBody");
      return null;
    }
  }
}
