import 'dart:typed_data';

/// Profil/avatar görselleri için paylaşılan bellek önbelleği.
/// Aynı URL tekrar kullanıldığında ağ isteği atılmadan bytes döner.
/// Çıkış veya hesap değiştiğinde [clear] çağrılmalı.
class AvatarCache {
  AvatarCache._();

  static final AvatarCache _instance = AvatarCache._();

  static AvatarCache get instance => _instance;

  static const int _maxEntries = 200;

  final Map<String, Uint8List> _cache = {};
  final List<String> _order = [];

  static String _normalizeKey(String url) {
    final s = url.trim();
    return s.endsWith('/') ? s.substring(0, s.length - 1) : s;
  }

  /// URL için önbellekte bytes varsa döner, yoksa null.
  Uint8List? get(String url) {
    final key = _normalizeKey(url);
    if (key.isEmpty) return null;
    return _cache[key];
  }

  /// İndirilen avatar bytes'ını önbelleğe yazar.
  void put(String url, Uint8List bytes) {
    final key = _normalizeKey(url);
    if (key.isEmpty) return;
    if (_cache.containsKey(key)) {
      _cache[key] = bytes;
      _order.remove(key);
      _order.add(key);
      return;
    }
    while (_cache.length >= _maxEntries && _order.isNotEmpty) {
      final evict = _order.removeAt(0);
      _cache.remove(evict);
    }
    _cache[key] = bytes;
    _order.add(key);
  }

  /// Tüm önbelleği temizler. Çıkış veya hesap değişiminde çağrılmalı.
  void clear() {
    _cache.clear();
    _order.clear();
  }
}
