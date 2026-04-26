import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AiService {
  // Replace with your real Gemini API Key
  static const String _apiKey = 'AIzaSyBeExrFjAdlEre6mo1H_dUxwmkn40WWt6Y';

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  static ChatSession? _chatSession;

  /// System prompt to define the agent's personality and rules
  static const String _systemPrompt = """
  You are 'El7a2ny AI Assistant', a specialized emergency response agent for an Egyptian emergency app.
  Your goal is to provide fast, accurate, and calm guidance during emergencies (medical, fire, accidents).
  
  Rules:
  1. Always respond in the language the user is using (Arabic or English).
  2. If the user reports a critical emergency, tell them to press the Red SOS button immediately and call official services (122 for police, 123 for ambulance).
  3. Provide step-by-step first aid or safety instructions based on the situation.
  4. Keep your tone professional, supportive, and urgent.
  5. If the situation is not an emergency, help with app features (how to add contacts, how to view alerts).
  6. Use Egyptian context when appropriate (e.g., mention 122, 123, 180).
  """;

  static Future<String> getResponse(String userMessage) async {
    try {
      if (_apiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY' || _apiKey.isEmpty) {
        return _getSmartFallback(userMessage);
      }

      _chatSession ??= _model.startChat(history: [Content.text(_systemPrompt)]);
      final response = await _chatSession!.sendMessage(Content.text(userMessage));
      return response.text ?? _getSmartFallback(userMessage);
    } catch (e) {
      debugPrint('AI Error: $e');
      _chatSession = null;
      return _getSmartFallback(userMessage);
    }
  }

  static String _getSmartFallback(String msg) {
    msg = msg.toLowerCase();
    
    // Check for Dizziness/Fainting
    if (msg.contains('دوخة') || msg.contains('دوار') || msg.contains('دويخ') || msg.contains('مش قادر أمشي') || msg.contains('faint') || msg.contains('dizzy')) {
      return "في حالة الدوخة أو عدم القدرة على المشي:\n\n🏠 إذا كنت بمفردك:\n- استلقِ على الأرض فوراً وارفع قدميك على كرسي أو وسادة.\n- لا تحاول الوقوف فجأة لتجنب السقوط.\n\n🤝 إذا كنت مع المريض:\n- ساعده على الاستلقاء ورفع قدميه.\n- تأكد من وجود تيار هواء متجدد.\n- اسأله إذا كان مريض سكري (قد يحتاج سكر).";
    }
    
    // Check for Pressure
    if (msg.contains('ضغط') || msg.contains('pressure')) {
      return "بالنسبة لضغط الدم:\n\n🏠 إذا كنت بمفردك:\n- اجلس في وضع مريح وخذ أنفاساً عميقة.\n- اطلب المساعدة إذا شعرت بصداع مفاجئ.\n\n🤝 إذا كنت مع المريض:\n- ساعده على الجلوس بهدوء.\n- لا تعطِه أي أدوية دون استشارة طبية.";
    }

    // Check for Diabetes
    if (msg.contains('سكر') || msg.contains('diabetes')) {
      return "بالنسبة للسكر:\n\n🏠 إذا كنت بمفردك:\n- تناول ملعقة سكر أو عصير فوراً إذا شعرت برعشة أو عرق بارد.\n- اجلس في مكان آمن.\n\n🤝 إذا كنت مع المريض:\n- إذا كان واعياً، أعطه عصير سكري.\n- إذا غاب عن الوعي، لا تضع شيئاً في فمه.";
    }

    // Check for Heart/Chest
    if (msg.contains('قلب') || msg.contains('صدر') || msg.contains('وجع') || msg.contains('heart') || msg.contains('pain')) {
      return "في حالة وجود ألم:\n\n🏠 إذا كنت بمفردك:\n- توقف عن أي مجهود واجلس فوراً.\n- إذا كان الألم في الصدر، اضغط SOS واترك الباب مفتوحاً.\n\n🤝 إذا كنت مع المريض:\n- ساعده على الجلوس في وضعية مريحة (نصف مستلقٍ).\n- طمئنه واتصل بالإسعاف.";
    }

    // Check for "Alone" or "Someone is with me" specifically
    if (msg.contains('لوحدي') || msg.contains('بمفردي') || msg.contains('alone')) {
      return "بما أنك بمفردك وتعبان، أرجوك اجلس أو استلقِ على الأرض فوراً لضمان سلامتك، وأخبرني ماذا تشعر بالضبط (دوخة؟ ألم في الصدر؟) لكي أساعدك.";
    }
    
    if (msg.contains('معايا') || msg.contains('أحد') || msg.contains('someone')) {
      return "جيد أن هناك من معك. أخبرني ما هي حالة الشخص المصاب لكي أعطيك تعليمات لك وللمرافق لإنقاذه.";
    }

    return "أنا معك لمساعدتك. هل تشعر بـ (دوخة، ألم في الصدر، ضيق تنفس)؟ وهل أنت بمفردك الآن؟";
  }

  static void resetChat() {
    _chatSession = null;
  }
}
