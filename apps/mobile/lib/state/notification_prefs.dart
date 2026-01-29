import 'package:shared_preferences/shared_preferences.dart';

const _kMobileNotificationsEnabled = 'openproject.notification.mobile_enabled';

/// Uygulama içi bildirim tercihleri (profil ayarlarında yönetilir).
class NotificationPrefs {
  /// Yeni OpenProject bildirimi geldiğinde telefon bildirimi gösterilsin mi? Varsayılan: evet.
  static Future<bool> getMobileNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kMobileNotificationsEnabled) ?? true;
  }

  static Future<void> setMobileNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMobileNotificationsEnabled, value);
  }
}
