import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Zaman takibi hatırlatması bildirim id aralığı: 100 = Pazartesi, 106 = Pazar.
const int _kTimeTrackingReminderIdBase = 100;

/// Yerel bildirimleri yönetir (uygulama açıkken veya arka plandayken).
/// Android 13+ için POST_NOTIFICATIONS izni gerekir.
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._();
  factory LocalNotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timeZoneInitialized = false;

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

    if (!_timeZoneInitialized) {
      tz_data.initializeTimeZones();
      _timeZoneInitialized = true;
    }

    _initialized = true;
  }

  void _ensureTimeZone() {
    if (!_timeZoneInitialized) {
      tz_data.initializeTimeZones();
      _timeZoneInitialized = true;
    }
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

  /// Zaman takibi hatırlatması bildirimlerini iptal eder.
  Future<void> cancelTimeTrackingReminders() async {
    for (int id = _kTimeTrackingReminderIdBase; id <= _kTimeTrackingReminderIdBase + 6; id++) {
      await _plugin.cancel(id);
    }
  }

  /// Çalışma günlerinde mesai bitimine yakın zaman takibi hatırlatması planlar.
  /// [workingWeekdays]: OpenProject hafta günü 1–7 (1 = Pazartesi).
  /// [hour], [minute]: Hatırlatma saati (yerel saat, mesai bitişinden önce örn. 16:45).
  Future<void> scheduleTimeTrackingReminders({
    required List<int> workingWeekdays,
    required int hour,
    required int minute,
  }) async {
    if (!Platform.isAndroid) return;
    await initialize();
    _ensureTimeZone();

    await cancelTimeTrackingReminders();

    const androidDetails = AndroidNotificationDetails(
      'time_tracking_reminder',
      'Zaman takibi hatırlatması',
      channelDescription: 'Mesai bitimine yakın zaman kaydı hatırlatması',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    final location = tz.local;
    // 2024-01-01 = Pazartesi (day 1); gün 1–7 için referans tarih.
    for (final day in workingWeekdays) {
      if (day < 1 || day > 7) continue;
      final id = _kTimeTrackingReminderIdBase + (day - 1);
      final scheduledDate = tz.TZDateTime(location, 2024, 1, day, hour, minute);
      await _plugin.zonedSchedule(
        id,
        'ProjectFlow',
        'Bugünkü zaman kaydınızı girmeyi unutmayın.',
        scheduledDate,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }
}
