class ChatMessage {
  final String id;
  final String from;
  final String to;
  final String body;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    required this.timestamp,
    required this.isMe,
  });
}
