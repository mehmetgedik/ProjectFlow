/// OpenProject bağlantı bilgisi için secure storage anahtarları.
/// AuthState ve notification_background_service ile paylaşılır.
abstract final class ConnectionStorageKeys {
  static const String instanceBaseUrl = 'openproject.instanceBaseUrl';
  static const String apiKey = 'openproject.apiKey';
  static const String activeProjectId = 'openproject.activeProjectId';
}

/// Instance URL'ini OpenProject API v3 base URL'ine çevirir.
/// AuthState ve notification_background_service ile paylaşılır.
String normalizeApiBase(String instanceBaseUrl) {
  final base = instanceBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
  if (base.endsWith('/api/v3')) return '$base/';
  return '$base/api/v3/';
}
