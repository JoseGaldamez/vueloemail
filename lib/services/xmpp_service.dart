import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import '../models/chat_message.dart';
import '../models/roster_contact.dart';
import 'database_service.dart';
import 'notification_service.dart';

enum XmppConnectionState { disconnected, connecting, connected, error }

class XmppService extends ChangeNotifier with WidgetsBindingObserver {
  static final XmppService _instance = XmppService._internal();
  factory XmppService() => _instance;
  XmppService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static const String _domain = 'vuelo.email';
  final DatabaseService _db = DatabaseService();

  XmppConnectionState _connectionState = XmppConnectionState.disconnected;
  XmppConnectionState get connectionState => _connectionState;

  String _myBareJid = '';
  String get myBareJid => _myBareJid;

  xmpp.Connection? _connection;
  xmpp.MessageHandler? _messageHandler;
  xmpp.PresenceManager? _presenceManager;
  xmpp.RosterManager? _rosterManager;
  Timer? _pingTimer;
  final List<StreamSubscription> _subscriptions = [];
  DateTime? _lastReconnectAttempt;

  String? _savedUsername;
  String? _savedPassword;
  String? _savedHost;
  int? _savedPort;

  final List<RosterContact> _contacts = [];
  List<RosterContact> get contacts => List.unmodifiable(_contacts);

  final Map<String, bool> _presenceMap = {};
  bool isOnline(String jid) => _presenceMap[_bare(jid)] ?? false;

  final Map<String, List<ChatMessage>> _conversations = {};
  Map<String, List<ChatMessage>> get conversations =>
      Map.unmodifiable(_conversations);

  List<ChatMessage> messagesFor(String jid) =>
      List.unmodifiable(_conversations[_bare(jid)] ?? []);

  bool hasUnreadMessages(String jid) {
    final msgs = _conversations[_bare(jid)] ?? [];
    return msgs.any((m) => !m.isMe && !m.isRead);
  }

  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  Future<void> connect(
    String username,
    String password, {
    String host = '35.222.164.116',
    int port = 5222,
  }) async {
    if (_connectionState == XmppConnectionState.connected ||
        _connectionState == XmppConnectionState.connecting) {
      return;
    }

    final now = DateTime.now();
    if (_lastReconnectAttempt != null &&
        now.difference(_lastReconnectAttempt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastReconnectAttempt = now;

    await _cleanupConnection();

    _savedUsername = username;
    _savedPassword = password;
    _savedHost = host;
    _savedPort = port;

    final localPart = username.split('@').first;
    _myBareJid = '$localPart@$_domain';
    _setConnectionState(XmppConnectionState.connecting);

    try {
      await _loadFromDatabase();

      final jidStr = '$localPart@$_domain/vuelo';
      final settings = xmpp.XmppAccountSettings.fromJid(jidStr, password);
      settings.host = host;
      settings.port = port;
      settings.totalReconnections = 0;

      _connection = xmpp.Connection(settings);

      _messageHandler = xmpp.MessageHandler.getInstance(_connection!);
      _presenceManager = xmpp.PresenceManager.getInstance(_connection!);
      _rosterManager = xmpp.RosterManager.getInstance(_connection!);

      // ── Listener: Estado de Conexión ──
      _subscriptions.add(
        _connection!.connectionStateStream.listen((state) {
          if (state == xmpp.XmppConnectionState.Ready) {
            _setConnectionState(XmppConnectionState.connected);
            _rosterManager!.queryForRoster();
            _startPingTimer();
          } else if (state == xmpp.XmppConnectionState.Closed ||
              state == xmpp.XmppConnectionState.ForcefullyClosed) {
            _setConnectionState(XmppConnectionState.disconnected);
          } else if (state == xmpp.XmppConnectionState.AuthenticationFailure) {
            _setConnectionState(XmppConnectionState.error);
          }
        }),
      );

      // ── Listener: Mensajes Entrantes ──
      _subscriptions.add(
        _messageHandler!.messagesStream.listen((stanza) {
          if (stanza == null || stanza.body == null || stanza.body!.isEmpty)
            return;

          final fromJid = stanza.fromJid?.userAtDomain ?? '';
          if (fromJid.isEmpty || fromJid == _myBareJid) return;

          final msg = ChatMessage(
            id: stanza.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
            from: fromJid,
            to: _myBareJid,
            body: stanza.body!,
            timestamp: DateTime.now(),
            isMe: false,
            isRead: false,
          );

          _addMessage(fromJid, msg);
          _messageController.add(msg);

          // Actualizamos UI solo una vez por mensaje
          if (_ensureContact(fromJid)) notifyListeners();

          _db.insertChatMessage(msg, _myBareJid).catchError((_) {});

          NotificationService().showNotification(
            id: fromJid.hashCode,
            title: 'Mensaje de ${fromJid.split('@').first}',
            body: stanza.body!,
          );
        }),
      );

      // ── Listener: Presencia ──
      _subscriptions.add(
        _presenceManager!.presenceStream.listen((presenceData) {
          final fromJid = presenceData.jid?.userAtDomain ?? '';
          if (fromJid.isEmpty || fromJid == _myBareJid) return;

          final bool online =
              presenceData.showElement != xmpp.PresenceShowElement.XA;
          _presenceMap[fromJid] = online;

          bool changed = _ensureContact(fromJid);
          final idx = _contacts.indexWhere((c) => c.jid == fromJid);
          if (idx != -1 && _contacts[idx].isOnline != online) {
            _contacts[idx].isOnline = online;
            changed = true;
          }

          // Evitamos spamear a Flutter, notificamos solo si hubo cambios reales
          if (changed) notifyListeners();
        }),
      );

      // ── Listener: Roster ──
      _subscriptions.add(
        _rosterManager!.rosterStream.listen((buddies) {
          bool changed = false;
          for (final buddy in buddies) {
            final jidStr = buddy.jid?.userAtDomain ?? '';
            if (jidStr.isEmpty || jidStr == _myBareJid) continue;
            if (_ensureContact(jidStr, name: buddy.name)) changed = true;
          }
          if (changed) notifyListeners();
        }),
      );

      _connection!.connect();
    } catch (e) {
      _setConnectionState(XmppConnectionState.error);
    }
  }

  Future<void> _loadFromDatabase() async {
    _contacts.clear();
    _conversations.clear();
    try {
      final savedContacts = await _db.getContacts(_myBareJid);
      _contacts.addAll(savedContacts);

      final savedMessages = await _db.getChatMessages(_myBareJid);
      for (var msg in savedMessages) {
        final otherSide = msg.isMe ? msg.to : msg.from;
        _conversations.putIfAbsent(otherSide, () => []);
        _conversations[otherSide]!.add(msg);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading DB: $e");
    }
  }

  void sendMessage(String toJid, String body) {
    if (_connection == null ||
        _connectionState != XmppConnectionState.connected)
      return;

    final bareTargetStr = formatJid(toJid);
    final targetJid = xmpp.Jid.fromFullJid(bareTargetStr);

    final chatManager = xmpp.ChatManager.getInstance(_connection!);
    final chat = chatManager.getChat(targetJid);
    chat.sendMessage(body);

    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      from: _myBareJid,
      to: bareTargetStr,
      body: body,
      timestamp: DateTime.now(),
      isMe: true,
      isRead: true,
    );

    _addMessage(bareTargetStr, msg);
    if (_ensureContact(bareTargetStr)) notifyListeners();
    _db.insertChatMessage(msg, _myBareJid).catchError((_) {});
  }

  Future<void> markAsRead(String jid) async {
    final bareJid = _bare(jid);
    final msgs = _conversations[bareJid];
    if (msgs == null) return;

    bool changed = false;
    for (var m in msgs) {
      if (!m.isMe && !m.isRead) {
        m.isRead = true;
        changed = true;
      }
    }

    if (changed) {
      await _db.markChatAsRead(bareJid, _myBareJid).catchError((_) {});
      notifyListeners();
    }
  }

  Future<void> _cleanupConnection() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _connection?.close();
    _connection = null;
  }

  Future<void> disconnect() async {
    await _cleanupConnection();
    _contacts.clear();
    _presenceMap.clear();
    _conversations.clear();
    _setConnectionState(XmppConnectionState.disconnected);
  }

  // Devuelve true si la lista de contactos fue modificada (para saber si hay que actualizar la UI)
  bool _ensureContact(String bareJid, {String? name}) {
    final idx = _contacts.indexWhere((c) => c.jid == bareJid);
    if (idx == -1) {
      final newContact = RosterContact(
        jid: bareJid,
        name: name ?? bareJid.split('@').first,
        isOnline: _presenceMap[bareJid] ?? false,
      );
      _contacts.add(newContact);
      _db.insertContact(newContact, _myBareJid).catchError((_) {});
      return true;
    } else if (name != null && name.isNotEmpty && _contacts[idx].name != name) {
      _contacts[idx] = RosterContact(
        jid: bareJid,
        name: name,
        isOnline: _contacts[idx].isOnline,
      );
      _db.insertContact(_contacts[idx], _myBareJid).catchError((_) {});
      return true;
    }
    return false;
  }

  void _addMessage(String bareJid, ChatMessage msg) {
    _conversations.putIfAbsent(bareJid, () => []);
    _conversations[bareJid]!.add(msg);
    notifyListeners();
  }

  void _setConnectionState(XmppConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_connectionState == XmppConnectionState.connected &&
          _connection != null) {
        try {
          // XEP-0199 Ping 100% nativo y seguro. Si el socket murió, writeStanza explotará y atraparemos el error.
          final iqStanza = xmpp.IqStanza(
            xmpp.AbstractStanza.getRandomId(),
            xmpp.IqStanzaType.GET,
          );
          iqStanza.toJid = xmpp.Jid.fromFullJid(_domain);

          final pingElement = xmpp.XmppElement();
          pingElement.name = 'ping';
          pingElement.addAttribute(
            xmpp.XmppAttribute('xmlns', 'urn:xmpp:ping'),
          );
          iqStanza.addChild(pingElement);

          _connection!.writeStanza(iqStanza);
        } catch (e) {
          debugPrint(
            'Socket cerrado detectado durante el Ping. Reconectando...',
          );
          _handleConnectionFailure();
        }
      }
    });
  }

  void _handleConnectionFailure() {
    _setConnectionState(XmppConnectionState.disconnected);
    if (_savedUsername != null && _savedPassword != null) {
      Future.delayed(const Duration(seconds: 2), () {
        connect(
          _savedUsername!,
          _savedPassword!,
          host: _savedHost!,
          port: _savedPort!,
        );
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_connectionState != XmppConnectionState.connected &&
          _savedUsername != null &&
          _savedPassword != null) {
        connect(
          _savedUsername!,
          _savedPassword!,
          host: _savedHost!,
          port: _savedPort!,
        );
      }
    }
  }

  String _bare(String jid) => jid.split('/').first;

  String formatJid(String input) {
    if (input.contains('@')) return input.toLowerCase();
    return '$input@$_domain'.toLowerCase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupConnection();
    _messageController.close();
    super.dispose();
  }
}
