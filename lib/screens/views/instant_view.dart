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

    return ListView.separated(
      itemCount: jids.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final jid = jids[index];
        final msgs = conversations[jid]!;
        final lastMsg = msgs.last;
        final contact = _findContact(xmpp.contacts, jid);

        return ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  contact.displayName.isNotEmpty
                      ? contact.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: xmpp.isOnline(jid)
                        ? Colors.green
                        : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            contact.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            lastMsg.isMe ? 'Tú: ${lastMsg.body}' : lastMsg.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            _formatTime(lastMsg.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(jid: jid, name: contact.displayName),
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
