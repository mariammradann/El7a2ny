import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AiService {
  // Use 10.0.2.2 for Android Emulator, or 127.0.0.1 for Chrome/Desktop
  // Since you are running on Chrome, 127.0.0.1 is correct.
  static const String _baseUrl = 'http://127.0.0.1:8000/api/chat/';

  static Future<String> getResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['reply'] ?? "I couldn't get a clear answer.";
      } else {
        return "Server error: ${response.statusCode}. Please check if the backend is running.";
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      return "Connection error. If this is an emergency, call 123 immediately.";
    }
  }

  static void resetChat() {
    // Session management can be added here if needed in the future
  }
}
