import 'dart:async';
import 'package:flutter/material.dart';
import '../models/email_message.dart';
import '../models/email_thread.dart';
import '../services/mail_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

enum EmailState { initial, loading, loaded, empty, error }

class EmailProvider extends ChangeNotifier {
  final MailService _mailService = MailService();
  final _secureStorage = const FlutterSecureStorage();

  List<EmailThread> _inbox = [];
  List<EmailThread> _sent = [];

  List<EmailThread> get inbox => _inbox;
  List<EmailThread> get sent => _sent;

  EmailState _inboxState = EmailState.initial;
  EmailState get inboxState => _inboxState;

  EmailState _sentState = EmailState.initial;
  EmailState get sentState => _sentState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _pollingTimer;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchInbox(isBackground: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Limpia el estado en memoria al cerrar sesión para que el siguiente
  /// usuario no vea datos residuales.
  void clearState() {
    _inbox = [];
    _sent = [];
    _inboxState = EmailState.initial;
    _sentState = EmailState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchInbox({bool isBackground = false}) async {
    final dbService = DatabaseService();

    final userEmail = await _secureStorage.read(key: 'user_email');
    if (userEmail == null) return;

    // 1. Flash load from SQLite (filtrado por usuario)
    if (!isBackground) {
      final localEmails = await dbService.getEmails('inbox', userEmail);
      if (localEmails.isNotEmpty) {
        _inbox = EmailThread.groupMessages(localEmails);
        _inboxState = EmailState.loaded;
        notifyListeners();
      } else {
        _inboxState = EmailState.loading;
        notifyListeners();
      }
    }

    try {
      final password = await _secureStorage.read(key: 'user_password');

      if (password == null) {
        throw Exception('No hay credenciales guardadas');
      }

      // 2. Fetch IMAP updates
      final newEmails = await _mailService.fetchInbox(userEmail, password);

      // Detect new emails for notifications
      if (isBackground && _inbox.isNotEmpty && newEmails.isNotEmpty) {
        final existingIds = _inbox.expand((t) => t.messages).map((m) => m.id).toSet();
        
        for (var email in newEmails) {
          if (!existingIds.contains(email.id)) {
            NotificationService().showNotification(
              id: email.id.hashCode,
              title: 'Nuevo correo de ${email.from}',
              body: email.subject,
            );
          }
        }
      }

      // 3. Cache filtrado por usuario
      await dbService.insertEmails(newEmails, 'inbox', userEmail);

      // 4. Reload FULL dataset del usuario actual
      final allLocalEmails = await dbService.getEmails('inbox', userEmail);

      _inbox = EmailThread.groupMessages(allLocalEmails);
      if (_inbox.isEmpty) {
        _inboxState = EmailState.empty;
      } else {
        _inboxState = EmailState.loaded;
      }
    } catch (e) {
      if (_inbox.isEmpty) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _inboxState = EmailState.error;
      }
    }
    notifyListeners();
  }

  Future<void> fetchSent({bool isBackground = false}) async {
    final dbService = DatabaseService();

    final userEmail = await _secureStorage.read(key: 'user_email');
    if (userEmail == null) return;

    if (!isBackground) {
      final localEmails = await dbService.getEmails('sent', userEmail);
      if (localEmails.isNotEmpty) {
        _sent = EmailThread.groupMessages(localEmails);
        _sentState = EmailState.loaded;
        notifyListeners();
      } else {
        _sentState = EmailState.loading;
        notifyListeners();
      }
    }

    try {
      final password = await _secureStorage.read(key: 'user_password');

      if (password == null) {
        throw Exception('No hay credenciales guardadas');
      }

      final newEmails = await _mailService.fetchSent(userEmail, password);
      await dbService.insertEmails(newEmails, 'sent', userEmail);

      final allLocalEmails = await dbService.getEmails('sent', userEmail);

      _sent = EmailThread.groupMessages(allLocalEmails);
      if (_sent.isEmpty) {
        _sentState = EmailState.empty;
      } else {
        _sentState = EmailState.loaded;
      }
    } catch (e) {
      if (_sent.isEmpty) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _sentState = EmailState.error;
      }
    }
    notifyListeners();
  }

  void markAsRead(String threadId) async {
    var index = _inbox.indexWhere((thread) => thread.id == threadId);
    if (index != -1) {
      var thread = _inbox[index];
      List<String> msgIds = [];

      var updatedMessages = thread.messages.map((m) {
        msgIds.add(m.id);
        return EmailMessage(
          id: m.id,
          messageId: m.messageId,
          inReplyTo: m.inReplyTo,
          references: m.references,
          from: m.from,
          to: m.to,
          subject: m.subject,
          body: m.body,
          htmlBody: m.htmlBody,
          timestamp: m.timestamp,
          isRead: true,
        );
      }).toList();

      _inbox[index] = EmailThread(
        id: thread.id,
        subject: thread.subject,
        messages: updatedMessages,
      );
      notifyListeners();

      final userEmail = await _secureStorage.read(key: 'user_email');
      if (userEmail == null) return;

      final dbService = DatabaseService();
      await dbService.markThreadsAsRead(msgIds, userEmail);

      final password = await _secureStorage.read(key: 'user_password');
      if (password != null) {
        for (var id in msgIds) {
          final uid = int.tryParse(id);
          if (uid != null) {
            await _mailService.markAsRead(userEmail, password, uid);
          }
        }
      }
    }
  }

  void sendNewEmail(EmailMessage email) {
    fetchSent(isBackground: true);
  }
}
