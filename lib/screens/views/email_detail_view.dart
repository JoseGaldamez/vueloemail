import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/email_message.dart';
import '../../services/mail_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class EmailDetailScreen extends StatefulWidget {
  final EmailMessage email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Leer Correo', style: TextStyle(fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de eliminar no implementada'),
                    ),
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.email.subject,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F223D),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(
                                    0xFFF1653B,
                                  ).withAlpha(51),
                                  child: Text(
                                    widget.email.from.isNotEmpty
                                        ? widget.email.from[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Color(0xFFF1653B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.email.from,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Para: ${widget.email.to}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        _formatDateTime(widget.email.timestamp),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Body
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildEmailContent(),
                      ),
                    ],
                  ),
                ),
              ),

              // Reply Input Section
              _buildReplySection(),
            ],
          ),
        ),
        // Capa de carga elegante encima (Backdrop)
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

  bool _isHtml(String text) {
    return RegExp(
      r'<[a-z][\s\S]*>|<!DOCTYPE',
      caseSensitive: false,
    ).hasMatch(text);
  }

  Widget _buildEmailContent() {
    final hasHtmlBody =
        widget.email.htmlBody != null && widget.email.htmlBody!.isNotEmpty;
    final bodyContainsHtml = _isHtml(widget.email.body);

    if (hasHtmlBody || bodyContainsHtml) {
      final data = hasHtmlBody ? widget.email.htmlBody! : widget.email.body;

      return HtmlWidget(
        data,
        textStyle: const TextStyle(fontSize: 16.0, color: Colors.black87),
      );
    } else {
      return Text(
        widget.email.body,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.black87,
        ),
      );
    }
  }

  Widget _buildReplySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
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
                    hintText: 'Responder...',
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
    final originalDate = DateFormat(
      'EEE, d MMM yyyy, hh:mm a',
    ).format(widget.email.timestamp);
    final quotedBody =
        "\n\nEl $originalDate, ${widget.email.from} escribió:\n> ${widget.email.body.replaceAll('\n', '\n> ')}";

    final fullBody = replyBody + quotedBody;

    String subject = widget.email.subject;
    if (!subject.toLowerCase().startsWith('re:')) {
      subject = 'Re: $subject';
    }

    final mailService = MailService();

    try {
      final success = await mailService.sendEmail(
        widget.email.from,
        subject,
        fullBody,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Respuesta enviada 🎉')));
          _replyController.clear();
          FocusScope.of(context).unfocus();
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
          // Animación puramente vertical (y) cubriendo toda la caja de 120px
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
