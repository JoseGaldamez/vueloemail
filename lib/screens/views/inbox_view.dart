import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/email_provider.dart';
import 'package:intl/intl.dart';
import 'thread_detail_screen.dart';
import 'compose_screen.dart';
import '../../models/email_thread.dart';

class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmailProvider>().fetchInbox();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  void _showComposeDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComposeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailProvider = context.watch<EmailProvider>();
    final state = emailProvider.inboxState;
    final emails = emailProvider.inbox;

    return Scaffold(
      body: _buildBody(state, emails, emailProvider.errorMessage),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showComposeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(EmailState state, List<EmailThread> emails, String? error) {
    if (emails.isNotEmpty && state != EmailState.error) {
      return Column(
        children: [
          if (state == EmailState.loading) const LinearProgressIndicator(),
          Expanded(child: _buildEmailList(emails)),
        ],
      );
    }

    switch (state) {
      case EmailState.initial:
      case EmailState.loading:
        return const Center(child: CircularProgressIndicator());
      case EmailState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  error ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<EmailProvider>().fetchInbox(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      case EmailState.empty:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Tu bandeja está vacía',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      case EmailState.loaded:
        return _buildEmailList(emails);
    }
  }

  Widget _buildEmailList(List<EmailThread> emails) {
    return RefreshIndicator(
      onRefresh: () => context.read<EmailProvider>().fetchInbox(),
      child: ListView.separated(
        itemCount: emails.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final thread = emails[index];
          final latestEmail = thread.latestMessage;
          final isUnread = thread.isUnread;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8ECEF),
              child: Text(
                latestEmail.from.isNotEmpty ? latestEmail.from[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF0F223D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    thread.sendersPreview(),
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                      color: isUnread ? Colors.black : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (thread.messages.length > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      thread.messages.length.toString(),
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey.shade700, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(
                  _formatDate(thread.lastMessageDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread ? const Color(0xFFF1653B) : Colors.grey,
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  thread.subject,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
            ),
            onTap: () {
              context.read<EmailProvider>().markAsRead(thread.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ThreadDetailScreen(thread: thread),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
