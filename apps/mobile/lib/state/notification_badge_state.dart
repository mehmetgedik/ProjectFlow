import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/openproject_client.dart';
import '../utils/app_logger.dart';
import 'notification_prefs.dart';
import '../services/local_notification_service.dart';

/// Okunmamış bildirim sayısı ve periyodik güncelleme. AuthState tarafından başlatılır/durdurulur.
class NotificationBadgeState extends ChangeNotifier {
  int unreadNotificationCount = 0;

  OpenProjectClient? _client;
  int _lastNotifiedUnreadCount = -1;
  Timer? _pollTimer;

  /// Client ile polling başlatır. Zaten çalışıyorsa yeniden başlatmaz.
  void start(OpenProjectClient client) {
    if (_client == client && _pollTimer != null) return;
    stop();
    _client = client;
    _loadLastNotifiedCountFromPrefs().then((_) {
      _refreshUnreadNotificationCount();
      _startPolling();
    });
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _client = null;
    _lastNotifiedUnreadCount = -1;
    if (unreadNotificationCount != 0) {
      unreadNotificationCount = 0;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadNotificationCount() async {
    await _refreshUnreadNotificationCount();
  }

  Future<void> _loadLastNotifiedCountFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(kPrefKeyLastNotifiedUnreadCount);
      if (last != null) _lastNotifiedUnreadCount = last;
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Bildirim badge pref okunamadı', error: e);
    }
  }

  Future<void> _saveLastNotifiedCountToPrefs(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kPrefKeyLastNotifiedUnreadCount, count);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Bildirim badge pref yazılamadı', error: e);
    }
  }

  void _startPolling() {
    if (_client == null || _pollTimer != null) return;
    _pollTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshUnreadNotificationCount(),
    );
  }

  Future<void> _refreshUnreadNotificationCount() async {
    final c = _client;
    if (c == null) return;
    try {
      final count = await c.getUnreadNotificationCount();
      if (unreadNotificationCount != count) {
        unreadNotificationCount = count;
        notifyListeners();
      }
      if (_lastNotifiedUnreadCount >= 0 && count > _lastNotifiedUnreadCount) {
        final showMobile = await NotificationPrefs.getMobileNotificationsEnabled();
        if (showMobile) {
          LocalNotificationService().showUnreadSummary(count: count);
        }
      }
      _lastNotifiedUnreadCount = count;
      await _saveLastNotifiedCountToPrefs(count);
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Bildirim sayısı güncellenemedi', error: e);
      if (unreadNotificationCount != 0) {
        unreadNotificationCount = 0;
        notifyListeners();
      }
    }
  }
}
