import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Zaman takibi hatırlatması bildirim id aralığı: 100 = Pazartesi, 106 = Pazar.
const int _kTimeTrackingReminderIdBase = 100;
/// Bugün için tek seferlik mesai hatırlatması (recurring bazen ilk gün tetiklenmediği için).
const int _kTimeTrackingReminderTodayId = 90;

/// Mesai hatırlatması / test bildirimi id’leri: tıklanınca zaman takibi sayfasına gider.
bool _isTimeTrackingNotificationId(int id) {
  return (id >= _kTimeTrackingReminderIdBase && id <= _kTimeTrackingReminderIdBase + 6) || id == _kTimeTrackingReminderTodayId;
}

/// Verilen hafta günü (1=Pzt, 7=Paz) ve saatteki bir sonraki (veya aynı) oluşumu döndürür.
/// Geçmiş tarih kullanımı iOS/Android’de sorun çıkarabildiği için gelecekteki ilk tetiklemeyi hesaplıyoruz.
tz.TZDateTime? _nextWeekdayAtTime(
  tz.Location location,
  int day, // 1=Pzt, 7=Paz (OpenProject convention)
  int hour,
  int minute,
  tz.TZDateTime now,
) {
  var candidate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
  if (candidate.weekday == day) {
    if (!candidate.isBefore(now)) return candidate;
    return candidate.add(const Duration(days: 7));
  }
  var daysToAdd = day - candidate.weekday;
  if (daysToAdd < 0) daysToAdd += 7;
  candidate = candidate.add(Duration(days: daysToAdd));
  if (!candidate.isBefore(now)) return candidate;
  return candidate.add(const Duration(days: 7));
}

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
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        final location = tz.getLocation(tzInfo.identifier);
        tz.setLocalLocation(location);
      } catch (_) {
        // Cihaz timezone alınamazsa varsayılan (UTC) kalır; hatırlatma yine de planlanır.
      }
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

  /// Cihazın yerel saat dilimini ayarlar; mesai hatırlatması doğru saatte tetiklensin.
  Future<void> _setLocalTimezoneFromDevice() async {
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(tzInfo.identifier);
      tz.setLocalLocation(location);
    } catch (_) {
      // Timezone alınamazsa tz.local varsayılan (UTC veya önceki set) kalır.
    }
  }

  /// Bildirime tıklandığında çağrılır; zaman takibi bildirimi ise zaman takibi sayfasına gidilmesi için main’de kullanılır.
  static void Function(int id, String? payload)? onNotificationTappedCallback;

  void _onNotificationTapped(NotificationResponse response) {
    final id = response.id ?? -1;
    final payload = response.payload;
    if (_isTimeTrackingNotificationId(id) || payload == 'time_tracking') {
      onNotificationTappedCallback?.call(id, payload);
    }
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

  /// Zaman takibi hatırlatması bildirimlerini iptal eder (bugün tek seferlik + haftalık).
  Future<void> cancelTimeTrackingReminders() async {
    await _plugin.cancel(_kTimeTrackingReminderTodayId);
    for (int id = _kTimeTrackingReminderIdBase; id <= _kTimeTrackingReminderIdBase + 6; id++) {
      await _plugin.cancel(id);
    }
  }

  /// Mesai hatırlatması kanalı için aynı AndroidNotificationDetails (kanal oluşturma / test için).
  static const AndroidNotificationDetails _timeTrackingReminderDetails =
      AndroidNotificationDetails(
    'time_tracking_reminder',
    'Zaman takibi hatırlatması',
    channelDescription: 'Mesai bitimine yakın zaman kaydı hatırlatması',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Çalışma günlerinde mesai bitimine yakın zaman takibi hatırlatması planlar.
  /// [workingWeekdays]: OpenProject hafta günü 1–7 (1 = Pazartesi).
  /// [hour], [minute]: Hatırlatma saati (cihazın yerel saatine göre; mesai bitişinden 15 dk önce).
  Future<void> scheduleTimeTrackingReminders({
    required List<int> workingWeekdays,
    required int hour,
    required int minute,
  }) async {
    if (!Platform.isAndroid) return;
    await initialize();
    _ensureTimeZone();
    await _setLocalTimezoneFromDevice();

    await cancelTimeTrackingReminders();

    const details = NotificationDetails(android: _timeTrackingReminderDetails);

    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    for (final day in workingWeekdays) {
      if (day < 1 || day > 7) continue;
      final id = _kTimeTrackingReminderIdBase + (day - 1);
      final scheduledDate = _nextWeekdayAtTime(location, day, hour, minute, now);
      if (scheduledDate == null) continue;
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
        payload: 'time_tracking',
      );
    }

    // Bugün çalışma günüyse ve hatırlatma saati henüz geçmediyse, bugün için tek seferlik alarm da planla
    // (recurring alarm bazı cihazlarda ilk gün tetiklenmeyebiliyor).
    final todayWeekday = now.weekday; // Dart: 1=Pzt, 7=Paz
    if (workingWeekdays.contains(todayWeekday)) {
      final todayAtReminder = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
      if (todayAtReminder.isAfter(now)) {
        await _plugin.zonedSchedule(
          _kTimeTrackingReminderTodayId,
          'ProjectFlow',
          'Bugünkü zaman kaydınızı girmeyi unutmayın.',
          todayAtReminder,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'time_tracking',
        );
      }
    }
  }
}
