// lib/services/cloudinary_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Your Cloudinary info
  static const String cloudName = "dmteuzsos";
  static const String uploadPreset = "dmteuzsos"; // unsigned preset

  /// Upload image to Cloudinary (unsigned)
  /// Works for: Crop Disease images + Community Post images
  /// Optional: specify Cloudinary folder like "crop" or "posts"
  static Future<String?> uploadImage(File file, {String folder = "general"}) async {
    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", uri);

      request.fields["upload_preset"] = uploadPreset;
      request.fields["folder"] = folder; // organize images in Cloudinary
      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      print("🌐 Cloudinary Response: $respStr");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(respStr);
        return data["secure_url"];
      } else {
        print("❌ Cloudinary upload failed: $respStr");
        return null;
      }
    } catch (e, st) {
      print("🔥 Cloudinary EXCEPTION: $e\n$st");
      return null;
    }
  }
}
