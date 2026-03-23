class ChatMessage {
  final String id;
  final String from;
  final String to;
  final String body;
  final DateTime timestamp;
  final bool isMe;
  bool isRead;

  ChatMessage({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromJid': from,
      'toJid': to,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isMe': isMe ? 1 : 0,
      'isRead': isRead ? 1 : 0,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      from: map['fromJid'],
      to: map['toJid'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      isMe: map['isMe'] == 1,
      isRead: map['isRead'] == 1,
    );
  }
}
