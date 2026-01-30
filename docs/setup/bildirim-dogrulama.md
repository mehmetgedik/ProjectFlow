# Bildirim ve Mesai Hatırlatması – Tam Doğrulama

Bu dokümanda tüm bileşenler tek tek kontrol edilmiş ve tutarlılık doğrulanmıştır.

---

## 1. main.dart

| Kontrol | Durum |
|--------|--------|
| Workmanager.initialize(callbackDispatcher) | ✅ main() başında await |
| LocalNotificationService().initialize() | ✅ main() başında await |
| onNotificationTappedCallback → /time-tracking | ✅ Mesai bildirimi tıklanınca zaman takibi sayfasına gider |
| navigatorKey MaterialApp’e verildi | ✅ |

---

## 2. AuthState

| Kontrol | Durum |
|--------|--------|
| initialize(): client varsa _loadLastNotifiedCountFromPrefs | ✅ Arka plan ile sayı senkron |
| initialize(): startNotificationPolling() | ✅ 5 dk Timer |
| initialize(): registerBackgroundNotificationCheck() | ✅ Arka plan görevi kaydedilir |
| initialize(): TimeTrackingReminderService().scheduleFromPrefs(client) | ✅ Her uygulama açılışında mesai hatırlatması yeniden planlanır |
| connect(): LocalNotificationService().requestPermission() | ✅ Giriş sonrası bildirim izni istenir |
| connect(): scheduleFromPrefs(c) | ✅ Mesai hatırlatması girişte planlanır |
| _refreshUnreadNotificationCount: count > _lastNotifiedUnreadCount → showUnreadSummary | ✅ Profil ayarı (getMobileNotificationsEnabled) kontrol edilir |
| _refreshUnreadNotificationCount: _saveLastNotifiedCountToPrefs(count) | ✅ Arka plan ile aynı key kullanılır |
| logout(): cancelBackgroundNotificationCheck, TimeTrackingReminderService().cancel() | ✅ |
| clearStoredSettings(): cancelBackgroundNotificationCheck, TimeTrackingReminderService().cancel() | ✅ |

---

## 3. notification_background_service.dart

| Kontrol | Durum |
|--------|--------|
| callbackDispatcher: taskName == kNotificationBackgroundTaskName | ✅ |
| FlutterSecureStorage ile instance + apiKey okunur | ✅ AuthState ile aynı key’ler (_kKeyInstance, _kKeyApiKey) |
| getUnreadNotificationCount() çağrılır | ✅ |
| lastNotified (SharedPreferences kPrefKeyLastNotifiedUnreadCount) | ✅ AuthState ile aynı key |
| count > lastNotified && mobileEnabled → LocalNotificationService().initialize() + showUnreadSummary(count) | ✅ |
| prefs.setInt(kPrefKeyLastNotifiedUnreadCount, count) | ✅ Güncel sayı kaydedilir |
| registerPeriodicTask: frequency 30 dk, initialDelay 1 dk | ✅ |
| registerPeriodicTask: constraints NetworkType.connected | ✅ Sadece ağ varken çalışır |

---

## 4. local_notification_service.dart

| Kontrol | Durum |
|--------|--------|
| initialize(): Android init, onDidReceiveNotificationResponse | ✅ |
| initialize(): timezone tz_data + FlutterTimezone.getLocalTimezone, setLocalLocation | ✅ Mesai saati yerel saate göre |
| showUnreadSummary: channel openproject_notifications, id 0 | ✅ |
| scheduleTimeTrackingReminders: cancelTimeTrackingReminders önce çağrılır | ✅ |
| scheduleTimeTrackingReminders: her working day için zonedSchedule (id 100–106), matchDateTimeComponents dayOfWeekAndTime | ✅ |
| scheduleTimeTrackingReminders: bugün çalışma günüyse ve saat geçmediyse _kTimeTrackingReminderTodayId (90) tek seferlik | ✅ |
| androidScheduleMode: inexactAllowWhileIdle | ✅ Exact alarm izni gerekmez |
| cancelTimeTrackingReminders: id 90 + 100–106 iptal | ✅ |
| requestPermission() Android 13+ | ✅ |

---

## 5. time_tracking_reminder_service.dart

| Kontrol | Durum |
|--------|--------|
| scheduleFromPrefs: enabled false veya client null → cancelTimeTrackingReminders | ✅ |
| scheduleFromPrefs: getWeekDays() ile çalışma günleri (varsayılan Pzt–Cuma) | ✅ |
| scheduleFromPrefs: getReminderHour/Minute (mesai bitişinden 15 dk önce) | ✅ TimeTrackingReminderPrefs kullanılır |

---

## 6. time_tracking_reminder_prefs.dart

| Kontrol | Durum |
|--------|--------|
| getReminderHour / getReminderMinute: bitiş saatinden 15 dk önce hesaplanır | ✅ |

---

## 7. notification_prefs.dart

| Kontrol | Durum |
|--------|--------|
| getMobileNotificationsEnabled (varsayılan true) | ✅ Hem AuthState hem background task kullanır |
| getNotificationSettingsInfoDismissed (banner bir kez kapatıldı mı) | ✅ Bildirimler sayfası için |

---

## 8. AndroidManifest.xml

| Kontrol | Durum |
|--------|--------|
| INTERNET | ✅ |
| POST_NOTIFICATIONS | ✅ |
| SCHEDULE_EXACT_ALARM | ✅ |
| RECEIVE_BOOT_COMPLETED | ✅ |
| ScheduledNotificationReceiver | ✅ flutter_local_notifications |
| ScheduledNotificationBootReceiver (BOOT_COMPLETED, MY_PACKAGE_REPLACED, QUICKBOOT) | ✅ |

---

## 9. Profil ekranı (mesai hatırlatması)

| Kontrol | Durum |
|--------|--------|
| _onEnabledChanged: scheduleFromPrefs(widget.auth.client) | ✅ Aç/kapa değişince planlama güncellenir |
| _pickEndTime: setEndHour/setEndMinute sonrası scheduleFromPrefs(widget.auth.client) | ✅ Saat değişince planlama güncellenir |

---

## 10. API

| Kontrol | Durum |
|--------|--------|
| getUnreadNotificationCount(): readIAN = f, total döner | ✅ |

---

## 11. Ortak key tutarlılığı

| Key | Kullanan |
|-----|----------|
| openproject.instanceBaseUrl | AuthState (_kKeyInstance), notification_background_service (_kKeyInstance) – FlutterSecureStorage |
| openproject.apiKey | AuthState (_kKeyApiKey), notification_background_service (_kKeyApiKey) – FlutterSecureStorage |
| openproject.last_notified_unread_count | AuthState (_load/_save), notification_background_service (prefs) – SharedPreferences |

---

## Özet

- **Ön plan:** Giriş/initialize sonrası 5 dk’da bir polling; sayı artarsa ve profil ayarı açıksa yerel bildirim; sayı SharedPreferences’a yazılır.
- **Arka plan:** Workmanager 1 dk sonra ilk, sonra 30 dk’da bir; ağ bağlıyken; aynı sayı key’i ile karşılaştırma; artış + profil ayarı ise yerel bildirim.
- **Mesai hatırlatması:** initialize + connect + profil değişince scheduleFromPrefs; yerel saat dilimi; haftalık + bugün tek seferlik; bildirime tıklanınca /time-tracking.
- **İzin:** connect() ve bildirimler sayfası açılışında requestPermission.
- **Çıkış/ayar silme:** Polling durur, Workmanager iptal, mesai hatırlatması iptal.

Tüm bağlantılar ve key kullanımları tutarlı; eksik veya çakışan bir kullanım yok.
