/// Sık değişmeyen API referans verileri için önbellek (statuses, priorities, projects, vb.).
/// Çıkış veya hesap değişiminde [clear] çağrılmalı.
class ApiReferenceCache {
  ApiReferenceCache._();

  static final ApiReferenceCache _instance = ApiReferenceCache._();

  static ApiReferenceCache get instance => _instance;

  /// Varsayılan TTL: 1 saat.
  static const Duration defaultTtl = Duration(hours: 1);

  final Map<String, _CachedEntry> _cache = {};

  /// Key için önbellekte veri varsa ve süresi dolmamışsa döner, yoksa null.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Veriyi önbelleğe yazar. [ttl] verilmezse [defaultTtl] kullanılır; null ise süresiz (sadece clear ile temizlenir).
  void put<T>(String key, T value, {Duration? ttl}) {
    final expiresAt = ttl == null
        ? null
        : DateTime.now().add(ttl == Duration.zero ? defaultTtl : ttl);
    _cache[key] = _CachedEntry(data: value, expiresAt: expiresAt);
  }

  /// Tüm önbelleği temizler. Çıkış veya hesap değişiminde çağrılmalı.
  void clear() {
    _cache.clear();
  }
}

class _CachedEntry {
  final dynamic data;
  final DateTime? expiresAt;

  _CachedEntry({required this.data, this.expiresAt});
}
