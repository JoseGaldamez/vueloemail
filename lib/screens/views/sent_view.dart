import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/email_provider.dart';
import 'package:intl/intl.dart';
import '../../models/email_thread.dart';
import 'thread_detail_screen.dart';

class SentView extends StatefulWidget {
  const SentView({super.key});

  @override
  State<SentView> createState() => _SentViewState();
}

class _SentViewState extends State<SentView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmailProvider>().fetchSent();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final emailProvider = context.watch<EmailProvider>();
    final state = emailProvider.sentState;
    final emails = emailProvider.sent;

    return Scaffold(
      body: _buildBody(state, emails, emailProvider.errorMessage),
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
                  onPressed: () => context.read<EmailProvider>().fetchSent(),
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
              Icon(Icons.send, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aún no has enviado correos',
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
      onRefresh: () => context.read<EmailProvider>().fetchSent(),
      color: const Color(0xFF0F223D),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: emails.length,
        itemBuilder: (context, index) {
          final thread = emails[index];
          final latestEmail = thread.latestMessage;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEDF2F7),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
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
                        backgroundColor: const Color(0xFFEDF2F7),
                        child: Text(
                          latestEmail.to.isNotEmpty ? latestEmail.to[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
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
                                    'Para: ${latestEmail.to}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A5568),
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (thread.messages.length > 1)
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
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
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFA0AEC0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              thread.subject,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4A5568),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latestEmail.body,
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
