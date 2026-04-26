# AI Agent Integration Guide (Gemini API)

To connect your Emergency Assistant to a real AI agent using Google's Gemini, follow these steps:

## 1. Get an API Key
- Go to [Google AI Studio](https://aistudio.google.com/).
- Create a new project and generate an **API Key**.

## 2. Add the Dependency
Add the `google_generative_ai` package to your `pubspec.yaml`:
```yaml
dependencies:
  google_generative_ai: ^0.4.5
```

## 3. Implementation Steps

### A. Initialize the Model
In your `_EmergencyChatScreenState`, create an instance of the model:

```dart
import 'package:google_generative_ai/google_generative_ai.dart';

// ...
final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: 'YOUR_API_KEY', // Recommended: Use a secure environment variable
);
```

### B. Handle the Chat Session
Modify your `_sendMessage` function to call the AI:

```dart
Future<void> _getAIResponse(String userMessage) async {
  final content = [Content.text(userMessage)];
  
  // Optional: Add system instructions to make it an Emergency Assistant
  final prompt = "You are a professional Emergency Assistant. Provide clear, calm, and actionable advice. User says: $userMessage";
  
  final response = await model.generateContent([Content.text(prompt)]);
  
  setState(() {
    _messages.add(ChatMessage(
      text: response.text ?? "Error: No response",
      source: MessageSource.bot,
      timestamp: DateTime.now(),
    ));
  });
  _scrollToBottom();
}
```

### C. Security Best Practices
> [!WARNING]
> **Warning**: Never hardcode your API key in the production app. 
> 1. Use a Backend Proxy: Send messages to your own server (Django/Node.js), and have the server call Gemini. This keeps your key secret.
> 2. Use `flutter_dotenv`: If you must keep it in the app, use environment variables.

## 4. Connecting Emergency Contacts
To make the "Contacts" button truly dynamic, replace the mock list in `emergency_chat_screen.dart` with a call to your user repository:

```dart
// Example:
final contacts = await userRepository.getEmergencyContacts();
setState(() {
  _contacts = contacts;
});
```
