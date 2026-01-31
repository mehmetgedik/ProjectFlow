import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/openproject_client.dart';
import '../constants/connection_storage.dart';
import '../init/platform_init.dart';
import '../models/project.dart';
import '../services/api_reference_cache.dart';
import '../services/avatar_cache.dart';
import '../services/local_notification_service.dart';
import '../services/notification_background_service.dart';
import '../widgets/letter_avatar.dart';
import '../services/time_tracking_reminder_service.dart';
import 'notification_badge_state.dart';

class AuthState extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final NotificationBadgeState _notificationBadge = NotificationBadgeState();

  bool isInitialized = false;
  OpenProjectClient? client;
  Project? activeProject;
  String? userDisplayName;
  String? userLogin;
  String? userAvatarUrl;
  String? userEmail;

  /// Okunmamış bildirim sayısı (NotificationBadgeState'ten iletilir).
  int get unreadNotificationCount => _notificationBadge.unreadNotificationCount;

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
    await platformInitFuture;
    _storedInstanceBaseUrl = await _storage.read(key: ConnectionStorageKeys.instanceBaseUrl);
    _storedApiKey = await _storage.read(key: ConnectionStorageKeys.apiKey);
    _activeProjectId = await _storage.read(key: ConnectionStorageKeys.activeProjectId);

    if (_storedInstanceBaseUrl != null &&
        _storedApiKey != null &&
        _storedInstanceBaseUrl!.isNotEmpty &&
        _storedApiKey!.isNotEmpty) {
      final apiBase = normalizeApiBase(_storedInstanceBaseUrl!);
      client = OpenProjectClient(
        apiBase: Uri.parse(apiBase),
        apiKey: _storedApiKey!,
      );
      // API base örn: https://host/api/v3/ -> avatar URL'leri bu base ile oluşturulur (web ile aynı endpoint).
      _instanceOrigin = Uri.parse(apiBase);
      _instanceApiBaseUrl = apiBase.replaceAll(RegExp(r'/+$'), '');
      _notificationBadge.addListener(_onNotificationBadgeChanged);
      _notificationBadge.start(client!);
      _loadUserDisplayName();
      registerBackgroundNotificationCheck();
      await TimeTrackingReminderService().scheduleFromPrefs(client);
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
            userAvatarUrl = '${displayUrl.replaceAll(RegExp(r'/+$'), '')}/my/avatar';
          }
        }
        notifyListeners();
      }
    } catch (_) {
      // ignore; user name is optional
    }
    _notificationBadge.refreshUnreadNotificationCount();
  }

  void _onNotificationBadgeChanged() {
    notifyListeners();
  }

  /// Okunmamış bildirim sayısını günceller (badge için).
  Future<void> refreshUnreadNotificationCount() async {
    await _notificationBadge.refreshUnreadNotificationCount();
  }

  /// Profil bilgisini API'den yeniden yükler (P1-F01 profil güncelleme sonrası).
  Future<void> refreshUserProfile() async {
    await _loadUserDisplayName();
  }

  Future<void> connect({required String instanceBaseUrl, required String apiKey}) async {
    if (apiKey.isEmpty) throw Exception('API key boş olamaz.');

    final apiBase = normalizeApiBase(instanceBaseUrl);
    final c = OpenProjectClient(apiBase: Uri.parse(apiBase), apiKey: apiKey);
    _instanceOrigin = Uri.parse(apiBase);
    _instanceApiBaseUrl = apiBase.replaceAll(RegExp(r'/+$'), '');

    await c.validateMe();

    await _storage.write(key: ConnectionStorageKeys.instanceBaseUrl, value: instanceBaseUrl);
    await _storage.write(key: ConnectionStorageKeys.apiKey, value: apiKey);

    _storedInstanceBaseUrl = instanceBaseUrl;
    _storedApiKey = apiKey;
    client = c;
    final me = await c.getMe();
    if (me.isNotEmpty) {
      userDisplayName = me['name'];
      userLogin = me['login'];
      userAvatarUrl = me['avatar'];
    }
    await LocalNotificationService().requestPermission();
    _notificationBadge.addListener(_onNotificationBadgeChanged);
    _notificationBadge.start(c);
    registerBackgroundNotificationCheck();
    await TimeTrackingReminderService().scheduleFromPrefs(c);
    _notificationBadge.refreshUnreadNotificationCount();
    notifyListeners();
  }

  void setActiveProject(Project project) {
    activeProject = project;
    _activeProjectId = project.id;
    _storage.write(key: ConnectionStorageKeys.activeProjectId, value: project.id);
    notifyListeners();
  }

  /// Çıkış: Oturum kapatılır; instance URL ve API key gibi ayarlar silinmez, tekrar girişte formda kalır.
  Future<void> logout() async {
    _notificationBadge.removeListener(_onNotificationBadgeChanged);
    _notificationBadge.stop();
    await cancelBackgroundNotificationCheck();
    await TimeTrackingReminderService().cancel();
    AvatarCache.instance.clear();
    LetterAvatar.clearFailedCache();
    client = null;
    activeProject = null;
    userDisplayName = null;
    userLogin = null;
    userAvatarUrl = null;
    _activeProjectId = null;
    _instanceOrigin = null;
    _instanceApiBaseUrl = null;
    // _storedInstanceBaseUrl ve _storedApiKey silinmez; çıkış sonrası formda kalır.
    notifyListeners();
  }

  /// Saklanan tüm bağlantı bilgilerini siler (instance URL, API key, aktif proje). Oturum da kapatılır.
  Future<void> clearStoredSettings() async {
    _notificationBadge.removeListener(_onNotificationBadgeChanged);
    _notificationBadge.stop();
    await cancelBackgroundNotificationCheck();
    await TimeTrackingReminderService().cancel();
    ApiReferenceCache.instance.clear();
    AvatarCache.instance.clear();
    LetterAvatar.clearFailedCache();
    await _storage.delete(key: ConnectionStorageKeys.instanceBaseUrl);
    await _storage.delete(key: ConnectionStorageKeys.apiKey);
    await _storage.delete(key: ConnectionStorageKeys.activeProjectId);
    client = null;
    activeProject = null;
    userDisplayName = null;
    userLogin = null;
    userAvatarUrl = null;
    _storedInstanceBaseUrl = null;
    _storedApiKey = null;
    _activeProjectId = null;
    _instanceOrigin = null;
    _instanceApiBaseUrl = null;
    notifyListeners();
  }
}

