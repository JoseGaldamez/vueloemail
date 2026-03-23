import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/email_message.dart';
import '../../models/email_thread.dart';
import '../../services/mail_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class ThreadDetailScreen extends StatefulWidget {
  final EmailThread thread;

  const ThreadDetailScreen({super.key, required this.thread});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isSendingReply = false;

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  bool _isHtml(String text) {
    return RegExp(
      r'<[a-z][\s\S]*>|<!DOCTYPE',
      caseSensitive: false,
    ).hasMatch(text);
  }

  Widget _buildEmailBody(EmailMessage email) {
    final hasHtmlBody = email.htmlBody != null && email.htmlBody!.isNotEmpty;
    final bodyContainsHtml = _isHtml(email.body);

    if (hasHtmlBody || bodyContainsHtml) {
      final data = hasHtmlBody ? email.htmlBody! : email.body;
      return HtmlWidget(
        data,
        textStyle: const TextStyle(fontSize: 15.0, color: Colors.black87),
      );
    } else {
      return Text(
        email.body,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          height: 1.5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            title: Text(
              widget.thread.subject,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.thread.messages.length,
                  itemBuilder: (context, index) {
                    final email = widget.thread.messages[index];
                    // Solo el último mensaje arranca expandido
                    final isLast = index == widget.thread.messages.length - 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isLast ? 2 : 1,
                      child: ExpansionTile(
                        initiallyExpanded: isLast,
                        shape:
                            const Border(), // Remueve las líneas superior e inferior default
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                email.from,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatDateTime(email.timestamp),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        subtitle: isLast
                            ? null
                            : Text(
                                email.body.replaceAll('\n', ' '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                _buildEmailBody(email),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildReplySection(),
            ],
          ),
        ),
        if (_isSendingReply)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, val, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5 * val, sigmaY: 5 * val),
                  child: Container(
                    color: Colors.white.withOpacity(0.3 * val),
                    child: Center(
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 400),
                        scale: val,
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F223D),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: const _FlyingPlaneIcon(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReplySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _replyController,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: 'Escribe tu respuesta...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFF1653B),
                radius: 22,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _isSendingReply ? null : _sendReply,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    // Ocultar teclado inmediatamente
    FocusScope.of(context).unfocus();

    setState(() {
      _isSendingReply = true;
    });

    final replyBody = _replyController.text.trim();
    final latestEmail = widget.thread.latestMessage;

    final originalDate = DateFormat(
      'EEE, d MMM yyyy, hh:mm a',
    ).format(latestEmail.timestamp);
    // Interpolación válida
    final quotedBody =
        "\n\nEl $originalDate, ${latestEmail.from} escribió:\n> "
        "${latestEmail.body.replaceAll('\n', '\n> ')}";

    final fullBody = "$replyBody$quotedBody";

    String subject = widget.thread.subject;
    if (!subject.toLowerCase().startsWith('re:')) {
      subject = 'Re: $subject';
    }

    final mailService = MailService();

    try {
      final success = await mailService.sendEmail(
        latestEmail.from,
        subject,
        fullBody,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Respuesta enviada 🎉')));
          _replyController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingReply = false;
        });
      }
    }
  }
}

class _FlyingPlaneIcon extends StatefulWidget {
  const _FlyingPlaneIcon();

  @override
  State<_FlyingPlaneIcon> createState() => _FlyingPlaneIconState();
}

class _FlyingPlaneIconState extends State<_FlyingPlaneIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final curvedValue = Curves.easeInCirc.transform(_controller.value);

        return Transform.translate(
          offset: Offset(0, 120 - (curvedValue * 240)),
          child: child,
        );
      },
      child: const Center(
        child: Icon(Icons.flight, color: Color(0xFFFFFFFF), size: 68),
      ),
    );
  }
}
