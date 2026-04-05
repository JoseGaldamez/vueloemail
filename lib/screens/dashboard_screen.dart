import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/email_provider.dart';
import '../services/xmpp_service.dart';
import 'views/inbox_view.dart';
import 'views/instant_view.dart';
import 'views/sent_view.dart';
import 'login_screen.dart';
import 'about_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  EmailProvider? _emailProvider;

  // Tab pages
  static const List<Widget> _views = [InboxView(), SentView(), InstantView()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start email polling
      _emailProvider = context.read<EmailProvider>();
      _emailProvider?.startPolling();

      // Connect XMPP with current user credentials
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user != null &&
          user.email.isNotEmpty &&
          user.passwordHash?.isNotEmpty == true) {
        final username = user.email.split('@').first;
        context.read<XmppService>().connect(username, user.passwordHash!);
      }
    });
  }

  @override
  void dispose() {
    _emailProvider?.stopPolling();
    super.dispose();
  }

  void _onTabTapped(int index) => setState(() => _currentIndex = index);

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    final xmppService = Provider.of<XmppService>(context, listen: false);

    emailProvider.stopPolling();
    emailProvider.clearState();
    await xmppService.disconnect();
    await authProvider.logout();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _openAbout() {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final emailDisplay = user?.email ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/vuelo-email-logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Vuelo', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      drawer: _buildDrawer(emailDisplay),
      body: _views[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'Entrada',
          ),
          NavigationDestination(
            icon: Icon(Icons.send_outlined),
            selectedIcon: Icon(Icons.send),
            label: 'Enviados',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Instantáneo',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(String emailDisplay) {
    final xmpp = context.watch<XmppService>();
    final xmppConnected = xmpp.connectionState == XmppConnectionState.connected;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
            ),
            accountName: const Text(
              'Cuenta Activa',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            accountEmail: Text(
              emailDisplay,
              style: const TextStyle(
                color: Color(0xFF0F223D),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Color(0xFF0F223D),
              child: Icon(Icons.person, color: Colors.white, size: 36),
            ),
          ),
          // XMPP status badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: xmppConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  xmppConnected
                      ? 'Mensajería conectada'
                      : 'Mensajería desconectada',
                  style: TextStyle(
                    fontSize: 12,
                    color: xmppConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.inbox),
            title: const Text('Bandeja de Entrada'),
            selected: _currentIndex == 0,
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: const Text('Enviados'),
            selected: _currentIndex == 1,
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Instantáneo'),
            selected: _currentIndex == 2,
            onTap: () {
              Navigator.pop(context);
              _onTabTapped(2);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            onTap: _openAbout,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }
}
