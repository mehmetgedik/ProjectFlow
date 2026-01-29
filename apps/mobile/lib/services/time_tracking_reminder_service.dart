import '../api/openproject_client.dart';
import '../state/time_tracking_reminder_prefs.dart';
import 'local_notification_service.dart';

/// Zaman takibi hatırlatmasını OpenProject çalışma günleri ve kullanıcı tercihine göre planlar veya iptal eder.
class TimeTrackingReminderService {
  static final TimeTrackingReminderService _instance = TimeTrackingReminderService._();
  factory TimeTrackingReminderService() => _instance;

  TimeTrackingReminderService._();

  /// Hatırlatma açıksa çalışma günlerinde planlar, kapalıysa veya client yoksa iptal eder.
  Future<void> scheduleFromPrefs(OpenProjectClient? client) async {
    final enabled = await TimeTrackingReminderPrefs.getEnabled();
    if (!enabled || client == null) {
      await LocalNotificationService().cancelTimeTrackingReminders();
      return;
    }

    List<int> workingWeekdays = const [1, 2, 3, 4, 5]; // varsayılan Pzt–Cuma
    try {
      final weekDays = await client.getWeekDays();
      if (weekDays.isNotEmpty) {
        workingWeekdays = weekDays.where((d) => d.working).map((d) => d.day).toList(growable: false);
        if (workingWeekdays.isEmpty) return;
      }
    } catch (_) {
      // API hatası; varsayılan çalışma günleri kullanılır
    }

    final hour = await TimeTrackingReminderPrefs.getReminderHour();
    final minute = await TimeTrackingReminderPrefs.getReminderMinute();

    await LocalNotificationService().scheduleTimeTrackingReminders(
      workingWeekdays: workingWeekdays,
      hour: hour,
      minute: minute,
    );
  }

  /// Hatırlatmayı iptal eder.
  Future<void> cancel() async {
    await LocalNotificationService().cancelTimeTrackingReminders();
  }
}
