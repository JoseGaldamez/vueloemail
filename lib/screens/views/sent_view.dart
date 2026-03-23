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
      child: ListView.separated(
        itemCount: emails.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final thread = emails[index];
          final latestEmail = thread.latestMessage;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(
                latestEmail.to.isNotEmpty
                    ? latestEmail.to[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Para: ${latestEmail.to}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (thread.messages.length > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  thread.subject,
                  style: const TextStyle(color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  latestEmail.body,
                  style: TextStyle(color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            onTap: () {
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
