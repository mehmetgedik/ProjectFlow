import 'package:flutter/material.dart';

import 'models/work_package.dart';
import 'screens/create_work_package_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/my_work_packages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pro_upgrade_screen.dart';
import 'screens/time_tracking_screen.dart';
import 'screens/work_package_detail_screen.dart';

/// Uygulama genelinde kullanılan route observer.
/// İş detayı gibi ekranlar, üzerlerine push edilen route pop edildiğinde
/// (örn. bildirimler, zaman kaydı formu) veriyi yenileyebilir.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Named route sabitleri ve route map.
abstract final class AppRoutes {
  static const String home = '/';
  static const String myWork = '/my-work';
  static const String dashboard = '/dashboard';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String proUpgrade = '/pro-upgrade';
  static const String timeTracking = '/time-tracking';

  static Map<String, Widget Function(BuildContext)> get routes => {
        myWork: (_) => const MyWorkPackagesScreen(),
        dashboard: (_) => const DashboardScreen(),
        notifications: (_) => const NotificationsScreen(),
        profile: (_) => const ProfileScreen(),
        proUpgrade: (_) => const ProUpgradeScreen(),
        timeTracking: (_) => const TimeTrackingScreen(),
      };
}

/// Navigasyon helper'ları: tekrarlayan push kalıplarını kısaltır.
abstract final class NavHelpers {
  NavHelpers._();

  /// İş detay ekranına gider.
  static Future<T?> toWorkPackageDetail<T>(BuildContext context, WorkPackage wp) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => WorkPackageDetailScreen(workPackage: wp),
      ),
    );
  }

  /// Yeni iş paketi oluşturma ekranına gider. Dönüşte [onPopped] çağrılır (örn. liste yenileme).
  static Future<T?> toCreateWorkPackage<T>(
    BuildContext context, {
    void Function()? onPopped,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => const CreateWorkPackageScreen()),
    ).then((result) {
      onPopped?.call();
      return result;
    });
  }
}
