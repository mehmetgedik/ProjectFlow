import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_navigation.dart';
import 'app_providers.dart';
import 'init/platform_init.dart';
import 'screens/authenticated_gate_screen.dart';
import 'screens/connect_screen.dart';
import 'screens/splash_screen.dart';
import 'services/local_notification_service.dart';
import 'state/auth_state.dart';
import 'state/theme_state.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: appProviders,
      child: const ProjectFlowApp(),
    ),
  );
  // İlk frame çizildikten sonra platform init; kısa gecikme ile ana thread’e
  // nefes aldırıp “Skipped N frames” / Davey uyarılarını azaltıyoruz.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 150), () {
      runPlatformInit().then((_) {
        LocalNotificationService.onNotificationTappedCallback = (id, payload) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.pushNamed(AppRoutes.timeTracking);
          });
        };
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        completePlatformInit();
      });
    });
  });
}

class ProjectFlowApp extends StatelessWidget {
  const ProjectFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeState>(
      builder: (context, themeState, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [appRouteObserver],
          title: 'ProjectFlow',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeState.themeMode,
          routes: AppRoutes.routes,
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
    return const AuthenticatedGateScreen();
  }
}
