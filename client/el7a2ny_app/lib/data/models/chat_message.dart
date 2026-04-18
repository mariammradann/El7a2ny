enum MessageSource { user, bot }

class ChatMessage {
  final String text;
  final MessageSource source;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.source,
    required this.timestamp,
  });
}
