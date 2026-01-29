import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/openproject_client.dart';
import '../models/project.dart';
import '../services/local_notification_service.dart';
import '../services/notification_background_service.dart';
import '../services/time_tracking_reminder_service.dart';

class AuthState extends ChangeNotifier {
  static const _kKeyInstance = 'openproject.instanceBaseUrl';
  static const _kKeyApiKey = 'openproject.apiKey';
  static const _kKeyActiveProjectId = 'openproject.activeProjectId';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool isInitialized = false;
  OpenProjectClient? client;
  Project? activeProject;
  String? userDisplayName;
  String? userLogin;
  String? userAvatarUrl;
  String? userEmail;
  int unreadNotificationCount = 0;

  /// Yeni bildirim geldiğinde telefon bildirimi göstermek için; -1 = henüz bilinmiyor.
  int _lastNotifiedUnreadCount = -1;
  Timer? _notificationPollTimer;

  String? _storedInstanceBaseUrl;
  String? _storedApiKey;
  String? _activeProjectId;
  Uri? _instanceOrigin;
  String? _instanceApiBaseUrl;

  String? get storedInstanceBaseUrl => _storedInstanceBaseUrl;
  String? get storedApiKey => _storedApiKey;
  String? get activeProjectId => _activeProjectId;

  /// Instance kök URL (avatar gibi göreli URL'leri çözmek ve auth header için).
  Uri? get instanceOrigin => _instanceOrigin;

  /// API base URL (örn. https://host/api/v3) – avatar endpoint'i web ile aynı: /api/v3/users/{id}/avatar.
  String? get instanceApiBaseUrl => _instanceApiBaseUrl;

  /// Aynı instance'tan gelen resimler (örn. özel avatar) için Authorization header.
  /// Sadece avatar URL'si instance ile aynı host ise kullanın.
  Map<String, String>? get authHeadersForInstanceImages {
    if (_storedApiKey == null || _storedApiKey!.isEmpty) return null;
    final auth = base64Encode(utf8.encode('apikey:$_storedApiKey'));
    return {'Authorization': 'Basic $auth'};
  }

  /// Instance adresi (profilde göstermek için; /api/v3 kısmı çıkarılmış).
  String? get instanceDisplayUrl {
    final base = _storedInstanceBaseUrl;
    if (base == null || base.isEmpty) return null;
    final normalized = base.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.endsWith('/api/v3')) {
      return normalized.substring(0, normalized.length - 8);
    }
    return normalized;
  }

  bool get isAuthenticated => client != null;

  Future<void> initialize() async {
    _storedInstanceBaseUrl = await _storage.read(key: _kKeyInstance);
    _storedApiKey = await _storage.read(key: _kKeyApiKey);
    _activeProjectId = await _storage.read(key: _kKeyActiveProjectId);

    if (_storedInstanceBaseUrl != null &&
        _storedApiKey != null &&
        _storedInstanceBaseUrl!.isNotEmpty &&
        _storedApiKey!.isNotEmpty) {
      final apiBase = _normalizeApiBase(_storedInstanceBaseUrl!);
      client = OpenProjectClient(
        apiBase: Uri.parse(apiBase),
        apiKey: _storedApiKey!,
      );
      // API base örn: https://host/api/v3/ -> avatar URL'leri bu base ile oluşturulur (web ile aynı endpoint).
      _instanceOrigin = Uri.parse(apiBase);
      _instanceApiBaseUrl = apiBase.replaceAll(RegExp(r'/+$'), '');
      await _loadLastNotifiedCountFromPrefs();
      _loadUserDisplayName();
      startNotificationPolling();
      registerBackgroundNotificationCheck();
    }

    isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadUserDisplayName() async {
    final c = client;
    if (c == null) return;
    try {
      final me = await c.getMe();
      if (me.isNotEmpty) {
        userDisplayName = me['name'];
        userLogin = me['login'];
        userAvatarUrl = me['avatar'];
        userEmail = me['email'];
        // Web'deki gibi: API avatar dönmezse /my/avatar yedek URL kullan
        if (userAvatarUrl == null || userAvatarUrl!.isEmpty) {
          final displayUrl = instanceDisplayUrl;
          if (displayUrl != null && displayUrl.isNotEmpty) {
            userAvatarUrl = displayUrl.replaceAll(RegExp(r'/+$'), '') + '/my/avatar';
          }
        }
        notifyListeners();
      }
    } catch (_) {
      // ignore; user name is optional
    }
    _refreshUnreadNotificationCount();
  }

  /// Okunmamış bildirim sayısını günceller (badge için). Hata durumunda 0 yapar.
  Future<void> refreshUnreadNotificationCount() async {
    await _refreshUnreadNotificationCount();
  }

  /// Profil bilgisini API'den yeniden yükler (P1-F01 profil güncelleme sonrası).
  Future<void> refreshUserProfile() async {
    await _loadUserDisplayName();
  }

  Future<void> _loadLastNotifiedCountFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(kPrefKeyLastNotifiedUnreadCount);
      if (last != null) _lastNotifiedUnreadCount = last;
    } catch (_) {}
  }

  Future<void> _saveLastNotifiedCountToPrefs(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kPrefKeyLastNotifiedUnreadCount, count);
    } catch (_) {}
  }

  Future<void> _refreshUnreadNotificationCount() async {
    final c = client;
    if (c == null) return;
    try {
      final count = await c.getUnreadNotificationCount();
      if (unreadNotificationCount != count) {
        unreadNotificationCount = count;
        notifyListeners();
      }
      // Yeni bildirim arttıysa telefon bildirimi göster (ilk yüklemede gösterme).
      if (_lastNotifiedUnreadCount >= 0 && count > _lastNotifiedUnreadCount) {
        LocalNotificationService().showUnreadSummary(count: count);
      }
      _lastNotifiedUnreadCount = count;
      await _saveLastNotifiedCountToPrefs(count);
    } catch (_) {
      if (unreadNotificationCount != 0) {
        unreadNotificationCount = 0;
        notifyListeners();
      }
    }
  }

  /// Uygulama açıkken periyodik kontrol (daha sık; 5 dakika). Arka plan için Workmanager kullanılır.
  void startNotificationPolling() {
    if (client == null || _notificationPollTimer != null) return;
    _notificationPollTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => refreshUnreadNotificationCount(),
    );
  }

  void _stopNotificationPolling() {
    _notificationPollTimer?.cancel();
    _notificationPollTimer = null;
    _lastNotifiedUnreadCount = -1;
  }

  Future<void> connect({required String instanceBaseUrl, required String apiKey}) async {
    if (apiKey.isEmpty) throw Exception('API key boş olamaz.');

    final apiBase = _normalizeApiBase(instanceBaseUrl);
    final c = OpenProjectClient(apiBase: Uri.parse(apiBase), apiKey: apiKey);
    _instanceOrigin = Uri.parse(apiBase);

    await c.validateMe();

    await _storage.write(key: _kKeyInstance, value: instanceBaseUrl);
    await _storage.write(key: _kKeyApiKey, value: apiKey);

    _storedInstanceBaseUrl = instanceBaseUrl;
    _storedApiKey = apiKey;
    client = c;
    final me = await c.getMe();
    if (me.isNotEmpty) {
      userDisplayName = me['name'];
      userLogin = me['login'];
      userAvatarUrl = me['avatar'];
    }
    startNotificationPolling();
    registerBackgroundNotificationCheck();
    TimeTrackingReminderService().scheduleFromPrefs(c);
    refreshUnreadNotificationCount();
    notifyListeners();
  }

  void setActiveProject(Project project) {
    activeProject = project;
    _activeProjectId = project.id;
    _storage.write(key: _kKeyActiveProjectId, value: project.id);
    notifyListeners();
  }

  /// Çıkış: Oturum kapatılır; instance URL ve API key gibi ayarlar silinmez, tekrar girişte formda kalır.
  Future<void> logout() async {
    _stopNotificationPolling();
    await cancelBackgroundNotificationCheck();
    await TimeTrackingReminderService().cancel();
    client = null;
    activeProject = null;
    userDisplayName = null;
    userLogin = null;
    userAvatarUrl = null;
    unreadNotificationCount = 0;
    _activeProjectId = null;
    _instanceOrigin = null;
    _instanceApiBaseUrl = null;
    // _storedInstanceBaseUrl ve _storedApiKey silinmez; çıkış sonrası formda kalır.
    notifyListeners();
  }

  /// Saklanan tüm bağlantı bilgilerini siler (instance URL, API key, aktif proje). Oturum da kapatılır.
  Future<void> clearStoredSettings() async {
    _stopNotificationPolling();
    await TimeTrackingReminderService().cancel();
    await _storage.delete(key: _kKeyInstance);
    await _storage.delete(key: _kKeyApiKey);
    await _storage.delete(key: _kKeyActiveProjectId);
    client = null;
    activeProject = null;
    userDisplayName = null;
    userLogin = null;
    userAvatarUrl = null;
    unreadNotificationCount = 0;
    _storedInstanceBaseUrl = null;
    _storedApiKey = null;
    _activeProjectId = null;
    _instanceOrigin = null;
    _instanceApiBaseUrl = null;
    notifyListeners();
  }

  String _normalizeApiBase(String instanceBaseUrl) {
    final base = instanceBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/api/v3')) return '$base/';
    return '$base/api/v3/';
  }
}

