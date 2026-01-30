import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../api/openproject_client.dart';
import '../constants/connection_storage.dart';
import '../state/notification_prefs.dart';
import 'local_notification_service.dart';

/// Arka planda (uygulama kapalıyken) OpenProject bildirim sayısını kontrol eder.
/// Android Workmanager minimum 15 dakika; daha uzun aralık pil için tercih edilebilir.
const String kNotificationBackgroundTaskName = 'openproject-notification-check';
const String kNotificationBackgroundUniqueName = 'openproject_notification_check';
/// Android minimum 15 dakika; 30 dakika pil dostu.
const Duration kBackgroundCheckInterval = Duration(minutes: 30);
/// İlk çalışma: girişten kısa süre sonra (1 dk) kontrol; sonra periyodik devam eder.
const Duration kBackgroundInitialDelay = Duration(minutes: 1);

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != kNotificationBackgroundTaskName) return false;
    if (!Platform.isAndroid) return true;

    try {
      WidgetsFlutterBinding.ensureInitialized();

      const storage = FlutterSecureStorage();
      final instance = await storage.read(key: ConnectionStorageKeys.instanceBaseUrl);
      final apiKey = await storage.read(key: ConnectionStorageKeys.apiKey);
      if (instance == null || apiKey == null || instance.isEmpty || apiKey.isEmpty) {
        return true;
      }

      final apiBase = normalizeApiBase(instance);
      final client = OpenProjectClient(
        apiBase: Uri.parse(apiBase),
        apiKey: apiKey,
      );
      final count = await client.getUnreadNotificationCount();

      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getInt(kPrefKeyLastNotifiedUnreadCount) ?? -1;
      final mobileEnabled = await NotificationPrefs.getMobileNotificationsEnabled();

      if (lastNotified >= 0 && count > lastNotified && mobileEnabled) {
        await LocalNotificationService().initialize();
        await LocalNotificationService().showUnreadSummary(count: count);
      }
      await prefs.setInt(kPrefKeyLastNotifiedUnreadCount, count);
    } catch (_) {
      // Hata olsa bile task başarılı sayılır; bir sonraki periyotta tekrar dener.
    }
    return true;
  });
}

/// Arka plan bildirim kontrolünü başlatır (giriş sonrası çağrılır). Uygulama kapalıyken de çalışır.
/// Ağ bağlıyken çalışır; ilk çalışma 1 dk sonra, sonra her 30 dk.
Future<void> registerBackgroundNotificationCheck() async {
  if (!Platform.isAndroid) return;
  await Workmanager().registerPeriodicTask(
    kNotificationBackgroundUniqueName,
    kNotificationBackgroundTaskName,
    frequency: kBackgroundCheckInterval,
    initialDelay: kBackgroundInitialDelay,
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

/// Arka plan bildirim kontrolünü iptal eder (çıkış sonrası çağrılır).
Future<void> cancelBackgroundNotificationCheck() async {
  await Workmanager().cancelByUniqueName(kNotificationBackgroundUniqueName);
}
