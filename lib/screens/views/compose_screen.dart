import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/mail_service.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  final _mailService = MailService();
  bool _isSending = false;

  void _sendEmail() async {
    final to = _toController.text.trim();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    // Validaciones
    if (to.isEmpty || !to.contains('@')) {
      _showError('Por favor ingresa un correo destinatario válido.');
      return;
    }
    if (body.isEmpty && subject.isEmpty) {
      _showError('No puedes enviar un correo vacío sin asunto.');
      return;
    }

    // Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    try {
      final success = await _mailService.sendEmail(to, subject, body);
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          _showSuccess('Correo enviado correctamente');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showError('No se pudo enviar el correo. Revisa tu conexión.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Redactar'),
            actions: [
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _isSending ? null : _sendEmail,
              ),
            ],
          ),
          body: Column(
            children: [
              // Para
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _toController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Para',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Asunto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _subjectController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Asunto',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ),
              const Divider(height: 1),
              // Cuerpo
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _bodyController,
                    maxLines: null,
                    expands: true,
                    textCapitalization: TextCapitalization.sentences,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu correo aquí...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.only(top: 8.0, bottom: 24.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Capa de carga elegante encima (Backdrop)
        if (_isSending)
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
