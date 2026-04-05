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
      color: const Color(0xFF0F223D),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding to clear FAB
        itemCount: emails.length,
        itemBuilder: (context, index) {
          final thread = emails[index];
          final latestEmail = thread.latestMessage;
          final isUnread = thread.isUnread;

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
            padding: const EdgeInsets.all(2), // Slight padding to clip inner material ripple
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  context.read<EmailProvider>().markAsRead(thread.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThreadDetailScreen(thread: thread),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isUnread 
                          ? const Color(0xFFE8ECEF) 
                          : const Color(0xFFEDF2F7),
                        child: Text(
                          latestEmail.from.isNotEmpty ? latestEmail.from[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isUnread ? const Color(0xFF0F223D) : const Color(0xFF6B7280),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    thread.sendersPreview(),
                                    style: TextStyle(
                                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                      color: isUnread ? const Color(0xFF0F223D) : const Color(0xFF6B7280),
                                      fontSize: 16,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (thread.messages.length > 1)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8, right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDF2F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      thread.messages.length.toString(),
                                      style: const TextStyle(
                                        fontSize: 12, 
                                        color: Color(0xFF6B7280), 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Text(
                                  _formatDate(thread.lastMessageDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isUnread ? const Color(0xFFF1653B) : const Color(0xFFA0AEC0),
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              thread.subject,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                color: isUnread ? const Color(0xFF1E2632) : const Color(0xFF4A5568),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestEmail.body, // Showing preview snippet
                              style: const TextStyle(
                                color: Color(0xFFA0AEC0),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Optional unread dot indicator
                      if (isUnread) ...[
                         const SizedBox(width: 8),
                         Container(
                           margin: const EdgeInsets.only(top: 8),
                           width: 8,
                           height: 8,
                           decoration: const BoxDecoration(
                             color: Color(0xFFF1653B),
                             shape: BoxShape.circle,
                           ),
                         ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
