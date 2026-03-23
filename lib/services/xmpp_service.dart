import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
import '../models/chat_message.dart';
import '../models/roster_contact.dart';

enum XmppConnectionState { disconnected, connecting, connected, error }

/// Singleton service that manages the XMPP connection lifecycle
/// using the `xmpp_stone` package (version 0.4.4-dev.7).
class XmppService extends ChangeNotifier {
  static final XmppService _instance = XmppService._internal();
  factory XmppService() => _instance;
  XmppService._internal();

  /// Dominio XMPP exclusivo del servicio.
  static const String _domain = 'vuelo.email';

  // ── Connection state ──────────────────────────────────────────────────────
  XmppConnectionState _connectionState = XmppConnectionState.disconnected;
  XmppConnectionState get connectionState => _connectionState;

  String _myBareJid = '';
  String get myBareJid => _myBareJid;

  // ── Internal xmpp_stone components ────────────────────────────────────────
  xmpp.Connection? _connection;
  xmpp.MessageHandler? _messageHandler;
  xmpp.PresenceManager? _presenceManager;
  xmpp.RosterManager? _rosterManager;

  // ── Contacts & Conversations ──────────────────────────────────────────────
  final List<RosterContact> _contacts = [];
  List<RosterContact> get contacts => List.unmodifiable(_contacts);

  final Map<String, bool> _presenceMap = {};
  bool isOnline(String jid) => _presenceMap[_bare(jid)] ?? false;

  final Map<String, List<ChatMessage>> _conversations = {};
  Map<String, List<ChatMessage>> get conversations =>
      Map.unmodifiable(_conversations);

  List<ChatMessage> messagesFor(String jid) =>
      List.unmodifiable(_conversations[_bare(jid)] ?? []);

  // ── Incoming message broadcast stream ─────────────────────────────────────
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Opens an XMPP connection to Openfire.
  /// [username] can be just 'user' or 'user@vuelo.email'.
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

    final localPart = username.split('@').first;
    _myBareJid = '$localPart@$_domain';
    _setConnectionState(XmppConnectionState.connecting);

    try {
      final jidStr = '$localPart@$_domain/vuelo';
      final settings = xmpp.XmppAccountSettings.fromJid(jidStr, password);
      settings.host = host;
      settings.port = port;
      settings.totalReconnections = 5;

      _connection = xmpp.Connection(settings);

      // xmpp_stone auto-initializes handlers in Connection constructor,
      // but we get the instances to listen to their streams.
      _messageHandler = xmpp.MessageHandler.getInstance(_connection!);
      _presenceManager = xmpp.PresenceManager.getInstance(_connection!);
      _rosterManager = xmpp.RosterManager.getInstance(_connection!);

      // ── Listen to Connection State ────────────────────────────────────────
      _connection!.connectionStateStream.listen((state) {
        if (state == xmpp.XmppConnectionState.Ready) {
          _setConnectionState(XmppConnectionState.connected);
        } else if (state == xmpp.XmppConnectionState.Closed ||
            state == xmpp.XmppConnectionState.ForcefullyClosed) {
          _setConnectionState(XmppConnectionState.disconnected);
        } else if (state == xmpp.XmppConnectionState.AuthenticationFailure) {
          _setConnectionState(XmppConnectionState.error);
        }
      });

      // ── Listen to Incoming Messages ───────────────────────────────────────
      _messageHandler!.messagesStream.listen((stanza) {
        if (stanza == null || stanza.body == null || stanza.body!.isEmpty) {
          return;
        }

        final fromJid = stanza.fromJid?.userAtDomain ?? '';
        if (fromJid.isEmpty || fromJid == _myBareJid) return;

        final msg = ChatMessage(
          id: stanza.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          from: fromJid,
          to: _myBareJid,
          body: stanza.body!,
          timestamp: DateTime.now(),
          isMe: false,
        );
        _addMessage(fromJid, msg);
        _messageController.add(msg);
        _ensureContact(fromJid);
      });

      // ── Listen to Presence Updates ─────────────────────────────────────────
      _presenceManager!.presenceStream.listen((presenceData) {
        final fromJid = presenceData.jid?.userAtDomain ?? '';
        if (fromJid.isEmpty || fromJid == _myBareJid) return;

        // PresenceManager: null showElement means 'Available' (Online).
        // It uses PresenceShowElement.XA for 'Unavailable'.
        final bool online =
            presenceData.showElement != xmpp.PresenceShowElement.XA;

        _presenceMap[fromJid] = online;
        final idx = _contacts.indexWhere((c) => c.jid == fromJid);
        if (idx != -1) {
          _contacts[idx].isOnline = online;
        } else if (online) {
          _contacts.add(RosterContact(
            jid: fromJid,
            name: fromJid.split('@').first,
            isOnline: true,
          ));
        }
        notifyListeners();
      });

      // ── Listen to Roster changes ──────────────────────────────────────────
      _rosterManager!.rosterStream.listen((buddies) {
        for (final buddy in buddies) {
          final jidStr = buddy.jid?.userAtDomain ?? '';
          if (jidStr.isEmpty || jidStr == _myBareJid) continue;

          _ensureContact(jidStr, name: buddy.name);
        }
        notifyListeners();
      });

      _connection!.connect();
    } catch (e) {
      _setConnectionState(XmppConnectionState.error);
    }
  }

  /// Sends a chat message to [toJid].
  void sendMessage(String toJid, String body) {
    if (_connection == null ||
        _connectionState != XmppConnectionState.connected) {
      return;
    }

    final localPart = _bare(toJid).split('@').first;
    final bareTargetStr = '$localPart@$_domain';
    final targetJid = xmpp.Jid.fromFullJid(bareTargetStr);

    // Using ChatManager for a more robust 1-to-1 chat flow
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
    );
    _addMessage(bareTargetStr, msg);
    _ensureContact(bareTargetStr);
  }

  /// Disconnects from the XMPP server and resets all state.
  Future<void> disconnect() async {
    _connection?.close();
    _connection = null;
    _contacts.clear();
    _presenceMap.clear();
    _conversations.clear();
    _setConnectionState(XmppConnectionState.disconnected);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _ensureContact(String bareJid, {String? name}) {
    if (!_contacts.any((c) => c.jid == bareJid)) {
      _contacts.add(RosterContact(
        jid: bareJid,
        name: name ?? bareJid.split('@').first,
        isOnline: _presenceMap[bareJid] ?? false,
      ));
      notifyListeners();
    }
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

  String _bare(String jid) => jid.split('/').first;

  @override
  void dispose() {
    _messageController.close();
    super.dispose();
  }
}
