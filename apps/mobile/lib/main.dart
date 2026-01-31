import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
import 'utils/app_logger.dart';

/// Cihaz saat dilimini erkenden ayarlar; bildirim/liste saatleri doğru gösterilsin (örn. Türkiye UTC+3).
void _initTimezoneForDisplay() {
  Future<void>(() async {
    try {
      tz_data.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {}
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Zone mismatch önlemek için: binding ve runApp arasında başka iş yok.
  WidgetsFlutterBinding.ensureInitialized();
  _initTimezoneForDisplay();
  runApp(
    MultiProvider(
      providers: appProviders,
      child: const ProjectFlowApp(),
    ),
  );

  // Hata yakalayıcılar runApp sonrası (zone zaten ayarlandı)
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.logError(
      'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.logError('Yakalanmamış hata (async)', error: error, stackTrace: stack);
    return true;
  };
  // İlk frame çizildikten sonra platform init; kısa gecikme ile ana thread’e
    // nefes aldırıp “Skipped N frames” / Davey uyarılarını azaltıyoruz.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(milliseconds: 400), () {
      runPlatformInit().then((_) {
        LocalNotificationService.onNotificationTappedCallback = (route) {
          if (route != null && route.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              navigatorKey.currentState?.pushNamed(route);
            });
          }
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
