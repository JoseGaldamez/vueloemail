import 'email_message.dart';

class EmailThread {
  final String id;
  final String subject;
  final List<EmailMessage> messages;

  EmailThread({
    required this.id,
    required this.subject,
    required this.messages,
  }) {
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  bool get isUnread => messages.any((msg) => !msg.isRead);

  DateTime get lastMessageDate => messages.isNotEmpty 
      ? messages.last.timestamp 
      : DateTime.now();

  EmailMessage get firstMessage => messages.first;
  EmailMessage get latestMessage => messages.last;

  String sendersPreview() {
    if (messages.isEmpty) return 'Desconocido';
    final senders = messages.map((m) => m.from.split('@').first).toSet().toList();
    if (senders.length == 1) {
      return senders.first;
    } else if (senders.length == 2) {
      return '${senders[0]}, ${senders[1]}';
    } else {
      return '${senders[0]}, ${senders[1]} +${senders.length - 2}';
    }
  }

  static List<EmailThread> groupMessages(List<EmailMessage> messages) {
    final List<EmailThread> threads = [];

    final sorted = List<EmailMessage>.from(messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var msg in sorted) {
      final normalizedSubject = _normalizeSubject(msg.subject);

      EmailThread? targetThread;

      for (var thread in threads) {
        bool matchByHeader = false;
        for (var existingMsg in thread.messages) {
          if (msg.inReplyTo != null && msg.inReplyTo!.isNotEmpty && msg.inReplyTo == existingMsg.messageId) {
            matchByHeader = true; break;
          }
          if (msg.references.contains(existingMsg.messageId) && existingMsg.messageId.isNotEmpty) {
            matchByHeader = true; break;
          }
          if (existingMsg.inReplyTo != null && existingMsg.inReplyTo == msg.messageId && msg.messageId.isNotEmpty) {
            matchByHeader = true; break;
          }
        }
        if (matchByHeader) {
          targetThread = thread;
          break;
        }
      }

      if (targetThread == null) {
        for (var thread in threads) {
          if (_normalizeSubject(thread.subject) == normalizedSubject && normalizedSubject.isNotEmpty) {
            targetThread = thread;
            break;
          }
        }
      }

      if (targetThread != null) {
        targetThread.messages.add(msg);
      } else {
        threads.add(EmailThread(
          id: msg.id,
          subject: normalizedSubject.isEmpty ? msg.subject : normalizedSubject,
          messages: [msg],
        ));
      }
    }

    threads.sort((a, b) => b.lastMessageDate.compareTo(a.lastMessageDate));
    return threads;
  }

  static String _normalizeSubject(String subject) {
    return subject.replaceAll(RegExp(r'^(Re:\s*|Fwd:\s*|Rv:\s*|RE:\s*)+', caseSensitive: false), '').trim();
  }
}
