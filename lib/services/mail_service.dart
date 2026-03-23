import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/email_message.dart';

class MailService {
  static const String imapServer = 'mail.vuelo.email';
  static const int imapPort = 993;
  static const String smtpServer = 'mail.vuelo.email';
  static const int smtpPort = 587;

  // Login and Validate Credentials via IMAP
  Future<bool> login(String email, String password) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(imapServer, imapPort, isSecure: true);
      await client.login(email, password);
      await client.logout();
      return true;
    } catch (e) {
      throw Exception('Error de autenticación o de conexión: ${e.toString()}');
    }
  }

  // Fetch Inbox Emails
  Future<List<EmailMessage>> fetchInbox(String email, String password) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(imapServer, imapPort, isSecure: true);
      await client.login(email, password);

      final mailbox = await client.selectInbox();
      if (mailbox.messagesExists == 0) {
        await client.logout();
        return [];
      }

      // Fetch the last 20 messages
      final fetchSequence = MessageSequence();
      final totalMessages = mailbox.messagesExists;
      final start = totalMessages > 20 ? totalMessages - 19 : 1;
      fetchSequence.addRange(start, totalMessages);

      final fetchResult = await client.fetchMessages(
        fetchSequence,
        '(UID FLAGS ENVELOPE BODY.PEEK[])',
      );

      int fallbackCounter = 0;
      final messages = fetchResult.messages.reversed.map((msg) {
        fallbackCounter++;

        final messageId = msg.getHeaderValue('Message-ID') ?? '';
        final inReplyTo = msg.getHeaderValue('In-Reply-To');
        final referencesStr = msg.getHeaderValue('References') ?? '';
        final referencesList = referencesStr.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

        return EmailMessage(
          id: msg.uid != null
              ? msg.uid.toString()
              : '${DateTime.now().millisecondsSinceEpoch}_$fallbackCounter',
          messageId: messageId,
          inReplyTo: inReplyTo,
          references: referencesList,
          from: msg.from?.first.email ?? 'Desconocido',
          to: msg.to?.first.email ?? email,
          subject: msg.decodeSubject() ?? 'Sin asunto',
          body: msg.decodeTextPlainPart() ?? '...',
          htmlBody: msg.decodeTextHtmlPart(),
          timestamp: msg.decodeDate() ?? DateTime.now(),
          isRead: msg.hasFlag(MessageFlags.seen),
        );
      }).toList();

      await client.logout();
      return messages;
    } catch (e) {
      throw Exception('Error al descargar bandeja de entrada: ${e.toString()}');
    }
  }

  // Fetch Sent Emails
  Future<List<EmailMessage>> fetchSent(String email, String password) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(imapServer, imapPort, isSecure: true);
      await client.login(email, password);

      // Sent is typically 'Sent', 'Enviados', or can be found dynamically,
      // Default to "Sent" folder for most IMAP servers representing sent mail
      Mailbox? mailbox;
      try {
        mailbox = await client.selectMailboxByPath('Sent');
      } catch (_) {
        // Fallback to Spanish or generic if exact path differs
        try {
          mailbox = await client.selectMailboxByPath('Sent Items');
        } catch (_) {
          mailbox = await client.selectMailboxByPath('Enviados');
        }
      }

      final fetchSequence = MessageSequence();

      if (mailbox.messagesExists == 0) {
        await client.logout();
        return [];
      }

      final totalMessages = mailbox.messagesExists;
      final start = totalMessages > 20 ? totalMessages - 19 : 1;
      fetchSequence.addRange(start, totalMessages);

      final fetchResult = await client.fetchMessages(
        fetchSequence,
        '(UID FLAGS ENVELOPE BODY.PEEK[])',
      );

      int fallbackCounter = 0;
      final messages = fetchResult.messages.reversed.map((msg) {
        fallbackCounter++;

        final messageId = msg.getHeaderValue('Message-ID') ?? '';
        final inReplyTo = msg.getHeaderValue('In-Reply-To');
        final referencesStr = msg.getHeaderValue('References') ?? '';
        final referencesList = referencesStr.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

        return EmailMessage(
          id: msg.uid != null
              ? msg.uid.toString()
              : '${DateTime.now().millisecondsSinceEpoch}_$fallbackCounter',
          messageId: messageId,
          inReplyTo: inReplyTo,
          references: referencesList,
          from: msg.from?.first.email ?? email,
          to: msg.to?.first.email ?? 'Desconocido',
          subject: msg.decodeSubject() ?? 'Sin asunto',
          body: msg.decodeTextPlainPart() ?? '...',
          htmlBody: msg.decodeTextHtmlPart(),
          timestamp: msg.decodeDate() ?? DateTime.now(),
          isRead: true, // Sent items are naturally read
        );
      }).toList();

      await client.logout();
      return messages;
    } catch (e) {
      throw Exception('Error al descargar correos enviados: ${e.toString()}');
    }
  }

  // Send Email (SMTP + IMAP Append)
  Future<bool> sendEmail(String to, String subject, String body) async {
    const secureStorage = FlutterSecureStorage();
    final email = await secureStorage.read(key: 'user_email');
    final password = await secureStorage.read(key: 'user_password');

    if (email == null || password == null) {
      throw Exception('Credenciales no encontradas');
    }

    // Constructor de MIME
    final mimeMessage = MessageBuilder.buildSimpleTextMessage(
      MailAddress(null, email),
      [MailAddress(null, to)],
      body,
      subject: subject,
    );

    // Enviar vía SMTP
    final smtpClient = SmtpClient('vuelo.email', isLogEnabled: false);
    try {
      await smtpClient.connectToServer(smtpServer, smtpPort, isSecure: false);
      await smtpClient.ehlo();

      // Implementamos STARTTLS
      await smtpClient.startTls();
      await smtpClient.ehlo();

      await smtpClient.authenticate(email, password);
      await smtpClient.sendMessage(mimeMessage);
      await smtpClient.disconnect();
    } catch (e) {
      throw Exception('Error al enviar el correo (SMTP): $e');
    }

    // Añadir a Enviados vía IMAP
    final imapClient = ImapClient(isLogEnabled: false);
    try {
      await imapClient.connectToServer(imapServer, imapPort, isSecure: true);
      await imapClient.login(email, password);

      Mailbox? sentMailbox;
      try {
        sentMailbox = await imapClient.selectMailboxByPath('Sent');
      } catch (_) {
        try {
          sentMailbox = await imapClient.selectMailboxByPath('Sent Items');
        } catch (_) {
          sentMailbox = await imapClient.selectMailboxByPath('Enviados');
        }
      }

      // Si no lanzaron excepción, garantizamos usar el mailbox
      await imapClient.appendMessage(mimeMessage, targetMailbox: sentMailbox);
      await imapClient.logout();
    } catch (e) {
      // Si falla IMAP pero ya      print('Advertencia: Correo enviado, pero no copiado a Enviados. $e');
    }

    return true;
  }

  // Mark as Read on Server
  Future<bool> markAsRead(String email, String password, int uid, {String boxName = 'INBOX'}) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(imapServer, imapPort, isSecure: true);
      await client.login(email, password);
      await client.selectMailboxByPath(boxName);
      
      final sequence = MessageSequence()..add(uid);
      await client.uidStore(sequence, [MessageFlags.seen], action: StoreAction.add);
      await client.logout();
      return true;
    } catch (_) {
      return false;
    }
  }
}
