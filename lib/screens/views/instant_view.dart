import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/xmpp_service.dart';
import '../../models/chat_message.dart';
import '../../models/roster_contact.dart';
import '../instant/contact_list_sheet.dart';
import '../instant/chat_screen.dart';

class InstantView extends StatelessWidget {
  const InstantView({super.key});

  @override
  Widget build(BuildContext context) {
    final xmpp = context.watch<XmppService>();
    final conversations = xmpp.conversations;

    return Scaffold(
      body: _buildBody(context, xmpp, conversations),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo chat',
        onPressed: () => _openContactSheet(context),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    XmppService xmpp,
    Map<String, List<ChatMessage>> conversations,
  ) {
    if (xmpp.connectionState == XmppConnectionState.connecting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Conectando al servidor de mensajería…'),
          ],
        ),
      );
    }

    if (xmpp.connectionState == XmppConnectionState.error) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No se pudo conectar al servidor XMPP.'),
          ],
        ),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin conversaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca + para iniciar un nuevo chat',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final jids = conversations.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: jids.length,
      itemBuilder: (context, index) {
        final jid = jids[index];
        final msgs = conversations[jid]!;
        final lastMsg = msgs.last;
        final contact = _findContact(xmpp.contacts, jid);
        final isUnread = xmpp.hasUnreadMessages(jid);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isUnread ? Colors.white : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? const Color(0xFFE2E8F0) : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              if (isUnread)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                xmpp.markAsRead(jid);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(jid: jid, name: contact.displayName),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isUnread 
                            ? const Color(0xFFE8ECEF) 
                            : const Color(0xFFEDF2F7),
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isUnread ? const Color(0xFF0F223D) : const Color(0xFF6B7280),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: xmpp.isOnline(jid)
                                  ? const Color(0xFF38A169) // Modern green
                                  : const Color(0xFFA0AEC0),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.displayName,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: isUnread ? const Color(0xFF0F223D) : const Color(0xFF1E2632),
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMsg.isMe ? 'Tú: ${lastMsg.body}' : lastMsg.body,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                              color: isUnread ? const Color(0xFF4A5568) : const Color(0xFFA0AEC0),
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(lastMsg.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnread
                                ? const Color(0xFFF1653B)
                                : const Color(0xFFA0AEC0),
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(height: 6),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1653B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Returns the matching roster contact, or a fallback using the JID.
  RosterContact _findContact(List<RosterContact> contacts, String jid) {
    try {
      return contacts.firstWhere((c) => c.jid == jid);
    } catch (_) {
      return RosterContact(jid: jid, name: '');
    }
  }

  void _openContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ContactListSheet(),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}
