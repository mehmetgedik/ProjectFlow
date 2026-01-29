import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/connect_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_work_packages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/splash_screen.dart';
import 'services/local_notification_service.dart';
import 'state/auth_state.dart';
import 'state/theme_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService().initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ThemeState()),
      ],
      child: const ProjectFlowApp(),
    ),
  );
}

class ProjectFlowApp extends StatelessWidget {
  const ProjectFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeState>(
      builder: (context, themeState, _) {
        return MaterialApp(
          title: 'ProjectFlow',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeState.themeMode,
          routes: {
            '/my-work': (_) => const MyWorkPackagesScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/profile': (_) => const ProfileScreen(),
          },
          home: const RootRouter(),
        );
      },
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (!auth.isInitialized) return const SplashScreen();
    if (!auth.isAuthenticated) return const ConnectScreen();
    return const ProjectsScreen();
  }
}
