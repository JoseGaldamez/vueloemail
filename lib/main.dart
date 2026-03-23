import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vueloemail/screens/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/email_provider.dart';
import 'services/xmpp_service.dart';
import 'services/notification_service.dart';
import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize NotificationService
  await NotificationService().init();

  // Initialize AuthProvider securely
  final authProvider = AuthProvider();
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
        ChangeNotifierProvider(create: (_) => XmppService()),
      ],
      child: const VueloApp(),
    ),
  );
}

class VueloApp extends StatelessWidget {
  const VueloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vuelo Email',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const DashboardScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
