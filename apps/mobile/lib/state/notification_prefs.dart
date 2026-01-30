import 'package:shared_preferences/shared_preferences.dart';

const _kMobileNotificationsEnabled = 'openproject.notification.mobile_enabled';
const _kNotificationSettingsInfoDismissed = 'openproject.notification.settings_info_dismissed';

/// Son bildirim sayısı (arka plan ve uygulama senkronu). AuthState ve notification_background_service ile paylaşılır.
const String kPrefKeyLastNotifiedUnreadCount = 'openproject.last_notified_unread_count';

/// Uygulama içi bildirim tercihleri (profil ayarlarında yönetilir).
class NotificationPrefs {
  /// Bildirimler sayfasındaki "OpenProject ayarları" bilgi banner'ı bir kez kapatıldı mı?
  static Future<bool> getNotificationSettingsInfoDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationSettingsInfoDismissed) ?? false;
  }

  static Future<void> setNotificationSettingsInfoDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationSettingsInfoDismissed, value);
  }

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
