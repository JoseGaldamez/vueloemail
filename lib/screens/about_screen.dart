import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/vuelo-email-logo.png',
                  height: 90,
                  width: 90,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App name
            const Text(
              'Vuelo Email',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 36),

            // Divider
            const Divider(),
            const SizedBox(height: 20),

            // About section
            _buildSection(
              icon: Icons.info_outline,
              title: '¿Qué es Vuelo Email?',
              body:
                  'Vuelo Email es una aplicación de comunicación completa que combina el correo electrónico tradicional con la mensajería instantánea, todo en un solo lugar. Diseñada para ofrecerte una experiencia fluida y segura.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              icon: Icons.mail_outline,
              title: 'Correo Electrónico',
              body:
                  'Gestiona tu bandeja de entrada y tus correos enviados de manera sencilla. Redacta, responde y organiza tus mensajes con una interfaz limpia y moderna.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              icon: Icons.chat_bubble_outline,
              title: 'Mensajería Instantánea',
              body:
                  'Conéctate con tus contactos en tiempo real gracias al protocolo XMPP. Chatea de forma privada y segura sin salir de la aplicación.',
            ),
            const SizedBox(height: 24),

            _buildSection(
              icon: Icons.security_outlined,
              title: 'Privacidad y Seguridad',
              body:
                  'Tu privacidad es nuestra prioridad. Todas las comunicaciones están protegidas y tus credenciales se almacenan de forma segura en tu dispositivo.',
            ),
            const SizedBox(height: 36),

            const Divider(),
            const SizedBox(height: 20),

            // Equipo: Lista de integrantes
            _buildTeamSection(),
            const SizedBox(height: 36),

            const Divider(),
            const SizedBox(height: 20),

            // Footer
            Text(
              '© 2026 Vuelo Email. Todos los derechos reservados.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Desarrollado con ❤️ en Flutter',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    const members = [
      {'name': 'José Galdámez', 'role': 'Arquitecto de Software'},
      {'name': 'Michelle Perdomo', 'role': 'Desarrollador'},
      {'name': 'Jose Daniel Fernández', 'role': 'Diseñador UX/UI'},
      {'name': 'Esdras Josué Moreno', 'role': 'Desarrollador'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.group_outlined,
                color: AppTheme.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Equipo de Desarrollo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...members.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain,
                        ),
                      ),
                      Text(
                        m['role']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
