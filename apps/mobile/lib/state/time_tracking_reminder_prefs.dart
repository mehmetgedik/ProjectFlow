import 'package:shared_preferences/shared_preferences.dart';

const _kReminderEnabled = 'openproject.time_tracking_reminder.enabled';
const _kReminderEndHour = 'openproject.time_tracking_reminder.endHour';
const _kReminderEndMinute = 'openproject.time_tracking_reminder.endMinute';

/// Mesai bitimine kaç dakika kala hatırlatma gösterileceği.
const int kReminderMinutesBeforeEnd = 15;

/// Zaman takibi hatırlatması tercihleri (açık/kapalı, mesai bitiş saati).
class TimeTrackingReminderPrefs {
  static Future<bool> getEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kReminderEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kReminderEnabled, value);
  }

  /// Mesai bitiş saati: saat (0–23). Varsayılan 17.
  static Future<int> getEndHour() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kReminderEndHour);
    return v != null && v >= 0 && v <= 23 ? v : 17;
  }

  static Future<void> setEndHour(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderEndHour, value.clamp(0, 23));
  }

  /// Mesai bitiş saati: dakika (0–59). Varsayılan 0.
  static Future<int> getEndMinute() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kReminderEndMinute);
    return v != null && v >= 0 && v <= 59 ? v : 0;
  }

  static Future<void> setEndMinute(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderEndMinute, value.clamp(0, 59));
  }

  /// Hatırlatma saati = mesai bitişinden [kReminderMinutesBeforeEnd] dakika önce.
  static Future<int> getReminderHour() async {
    final hour = await getEndHour();
    final minute = await getEndMinute();
    var reminderMinute = minute - kReminderMinutesBeforeEnd;
    var reminderHour = hour;
    if (reminderMinute < 0) {
      reminderMinute += 60;
      reminderHour--;
    }
    if (reminderHour < 0) reminderHour += 24;
    return reminderHour;
  }

  static Future<int> getReminderMinute() async {
    final minute = await getEndMinute();
    var reminderMinute = minute - kReminderMinutesBeforeEnd;
    if (reminderMinute < 0) reminderMinute += 60;
    return reminderMinute;
  }
}
