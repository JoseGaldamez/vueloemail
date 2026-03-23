class EmailMessage {
  final String id;
  final String messageId;
  final String? inReplyTo;
  final List<String> references;
  final String from;
  final String to;
  final String subject;
  final String body;
  final String? htmlBody;
  final DateTime timestamp;
  final bool isRead;

  EmailMessage({
    required this.id,
    this.messageId = '',
    this.inReplyTo,
    this.references = const [],
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    this.htmlBody,
    required this.timestamp,
    this.isRead = false,
  });

  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'] ?? '',
      messageId: json['messageId'] ?? '',
      inReplyTo: json['inReplyTo'],
      references: (json['references'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      htmlBody: json['htmlBody'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messageId': messageId,
      'inReplyTo': inReplyTo,
      'references': references.join(','),
      'from': from,
      'to': to,
      'subject': subject,
      'body': body,
      'htmlBody': htmlBody,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
