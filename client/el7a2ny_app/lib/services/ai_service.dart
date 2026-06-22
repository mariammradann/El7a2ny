import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../data/models/chat_message.dart';

class AiService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/api/assistant/chat/';

  static Future<String> getResponse(List<ChatMessage> history) async {
    try {
      final list = history.map((msg) => {
        'role': msg.source == MessageSource.user ? 'user' : 'model',
        'text': msg.text,
      }).toList();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'history': list}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response'] ?? "I couldn't get a clear answer.";
      } else {
        return "Server error: ${response.statusCode}.";
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

