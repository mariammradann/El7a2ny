import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AiService {
  // 1. Your Gemini API Key from Google AI Studio
  static const String _apiKey = 'AIzaSyBeExrFjAdlEre6mo1H_dUxwmkn40WWt6Y';

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  static ChatSession? _chatSession;

  // 2. The "Brain" of your Agent - This makes it unlimited
  static const String _systemPrompt = """
  You are 'El7a2ny AI Assistant', a specialized emergency response agent for an Egyptian emergency app.
  
  CORE MISSION:
  Provide instant, life-saving instructions for ANY medical, fire, or safety emergency reported by the user.
  
  DYNAMIC RULES:
  1. ADAPT TO CONTEXT: 
     - If the user says they are ALONE (لوحدي), give instructions they can perform on themselves safely.
     - If the user says someone is WITH them (معايا حد), give instructions for the bystander to help the victim.
  2. LANGUAGE: Always respond in the SAME language the user uses (Egyptian Arabic or English).
  3. CRITICAL ACTION: If the situation sounds life-threatening, tell them to press the Red SOS button in the app and call 123 (Ambulance) or 122 (Police) immediately.
  4. NO LIMITS: Do not say "I don't know". Use your medical knowledge to provide the best first-aid steps for the specific case mentioned.
  5. STYLE: Be calm, urgent, and use bullet points for clarity.
  """;

  /// This function now talks to Gemini directly without any hardcoded 'if' statements.
  static Future<String> getResponse(String userMessage) async {
    try {
      // Safety check for the API key
      if (_apiKey.isEmpty || _apiKey.startsWith('REPLACE')) {
        return "API Key is missing. Please configure it in ai_service.dart";
      }

      // Initialize the chat session with our System Prompt as the starting point
      _chatSession ??= _model.startChat(
        history: [
          Content.text(_systemPrompt),
          Content.model([
            TextPart(
              "Understood. I am ready to assist as El7a2ny AI. What is the emergency?",
            ),
          ]),
        ],
      );

      // Send the user message to the AI
      final response = await _chatSession!.sendMessage(
        Content.text(userMessage),
      );

      // Return the AI's generated response
      return response.text ??
          "I'm having trouble processing that. Please call 123 or 122 immediately.";
    } catch (e) {
      debugPrint('AI Error: $e');
      // If there's an error (like a timeout), we reset the session so it can try fresh next time
      _chatSession = null;
      return "Connection error. If this is an emergency, stay calm and call 123 for an ambulance.";
    }
  }

  /// Call this when the user leaves the chat or starts a new emergency
  static void resetChat() {
    _chatSession = null;
  }
}
