import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Yerel bildirimleri yönetir (uygulama açıkken veya arka plandayken).
/// Android 13+ için POST_NOTIFICATIONS izni gerekir.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._();
  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  LocalNotificationService._();

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!Platform.isAndroid) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Uygulama açılır; bildirimler sayfasına yönlendirme route ile yapılabilir.
  }

  /// Android 13+ bildirim iznini ister. İzin verilmezse bildirimler gösterilmez.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;
    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Okunmamış bildirim sayısı için tek bir bildirim gösterir (özet).
  Future<void> showUnreadSummary({required int count, String? body}) async {
    if (!_initialized || count <= 0) return;

    const android = AndroidNotificationDetails(
      'openproject_notifications',
      'Bildirimler',
      channelDescription: 'ProjectFlow bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _plugin.show(
      0,
      'ProjectFlow',
      body ?? (count == 1 ? '1 okunmamış bildirim' : '$count okunmamış bildirim'),
      const NotificationDetails(android: android),
    );
  }

  /// Tüm bildirimleri kaldırır.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
