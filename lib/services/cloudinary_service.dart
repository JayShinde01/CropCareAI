// lib/services/cloudinary_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Needed for Uint8List (file bytes)
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Import for platform checks

class CloudinaryService {
  // Your Cloudinary info (Ensure these are correct)
  static const String cloudName = "dmteuzsos";
  static const String uploadPreset = "dmteuzsos"; 

  /// Upload image to Cloudinary (unsigned)
  /// Accepts either a File (mobile/desktop) OR fileBytes + fileName (web).
  static Future<String?> uploadImage({
    File? file, 
    Uint8List? fileBytes, 
    String? fileName, 
    String folder = "general"
  }) async {
    if (file == null && fileBytes == null) {
      print("❌ Cloudinary upload failed: No file or file bytes provided.");
      return null;
    }

    try {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      final request = http.MultipartRequest("POST", uri);

      request.fields["upload_preset"] = uploadPreset;
      request.fields["folder"] = folder; 

      // --- CRITICAL CROSS-PLATFORM FILE HANDLING ---
      if (file != null) {
        // MOBILE/DESKTOP: Upload from file path (dart:io)
        request.files.add(await http.MultipartFile.fromPath("file", file.path));
      } else if (fileBytes != null && fileName != null) {
        // WEB: Upload from memory bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            "file", 
            fileBytes,
            filename: fileName,
          ),
        );
      } else {
         throw Exception('Incomplete file data (bytes or file missing).');
      }
      
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(respStr);
        return data["secure_url"];
      } else {
        print("❌ Cloudinary upload failed (Status ${response.statusCode}): $respStr");
        return null;
      }
    } catch (e, st) {
      print("🔥 Cloudinary EXCEPTION: $e\n$st");
      return null;
    }
  }
}