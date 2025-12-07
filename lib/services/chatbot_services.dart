import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Backend endpoint
  final String baseUrl = "http://localhost:8000/chat"; // Replace with IP if testing on mobile

  Future<Map<String, dynamic>> sendMessage(
      String message, List<Map<String, String>> history) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": message,
          "history": history,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "reply": data["reply"] ?? "No reply from AI 😕",
          "history": data["history"] ?? history
        };
      } else {
        return {"reply": "Server error ${response.statusCode} 😢", "history": history};
      }
    } catch (e) {
      return {"reply": "Error connecting to backend 😢\n$e", "history": history};
    }
  }
}
