import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Profil resmi (imageUrl) varsa onu gösterir, yoksa veya yüklenemezse baş harf avatarı.
class LetterAvatar extends StatelessWidget {
  final String? displayName;
  /// API'den gelen avatar URL (örn. Gravatar veya OpenProject özel yükleme); boşsa veya hata verirse harf avatarı kullanılır.
  final String? imageUrl;
  /// Aynı instance'tan gelen resimler için Authorization header (OpenProject özel avatar için gerekli).
  final Map<String, String>? imageHeaders;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Decode hatası veren URL'ler; tekrar denemeyelim. Auth (401/403) hariç tutulur; giriş yenilenince temizlenir.
  static final Set<String> _failedUrls = {};
  static void _recordFailedUrl(String url) {
    if (_failedUrls.length < 200) _failedUrls.add(url);
  }

  /// Giriş / profil yenileme sonrası çağrılır; avatar yeniden denenir.
  static void clearFailedCache() {
    _failedUrls.clear();
  }

  const LetterAvatar({
    super.key,
    this.displayName,
    this.imageUrl,
    this.imageHeaders,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
  });

  static Color _colorFromString(String s) {
    var h = 0;
    for (var i = 0; i < s.length; i++) {
      h = (h * 31 + s.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    h = h.abs();
    const tones = [0xFF2F5D95, 0xFF1E88E5, 0xFF5E35B1, 0xFF00897B, 0xFF2E7D32];
    return Color(tones[h % tones.length]);
  }

  String get _initial {
    if (displayName == null || displayName!.isEmpty) return '?';
    final t = displayName!.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts.first.isNotEmpty ? parts.first[0] : '';
      final last = parts.last.isNotEmpty ? parts.last[0] : '';
      return (first + last).toUpperCase();
    }
    return t.length >= 1 ? t.substring(0, 1).toUpperCase() : '?';
  }

  Widget _buildLetterAvatar(BuildContext context) {
    final bg = backgroundColor ?? _colorFromString(displayName ?? '?');
    final fg = foregroundColor ?? Colors.white;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      foregroundColor: fg,
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static bool _hasImageExtension(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  /// Uzantısız avatar URL'si mi (/my/avatar, /users/123/avatar).
  static bool _isExtensionLessAvatarUrl(Uri? uri) {
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) return false;
    final path = uri.path.toLowerCase();
    if (_hasImageExtension(uri)) return false;
    return path.contains('avatar');
  }

  static bool _isLikelyAvatarUrl(Uri? uri) {
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) return false;
    return _hasImageExtension(uri) || _isExtensionLessAvatarUrl(uri);
  }

  /// Content-Type bitmap mi (SVG/HTML değil).
  static bool _isBitmapContentType(String? contentType) {
    if (contentType == null || contentType.isEmpty) return false;
    final t = contentType.toLowerCase().split(';').first.trim();
    if (!t.startsWith('image/')) return false;
    if (t == 'image/svg+xml') return false;
    return t == 'image/png' || t == 'image/jpeg' || t == 'image/jpg' || t == 'image/gif' || t == 'image/webp';
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) return _buildLetterAvatar(context);

    final url = imageUrl!.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !_isLikelyAvatarUrl(uri)) return _buildLetterAvatar(context);
    if (_failedUrls.contains(url)) return _buildLetterAvatar(context);

    // Uzantısız URL: önce HTTP ile çek, Content-Type kontrol et; sadece bitmap ise göster (SVG/HTML decoder'a gitmesin).
    if (_isExtensionLessAvatarUrl(uri)) {
      return _AvatarFromUrl(
        url: url,
        headers: imageHeaders,
        size: size,
        fallback: _buildLetterAvatar(context),
        onFailed: () => _recordFailedUrl(url),
      );
    }

    // Uzantılı URL: Image.network (zaten bitmap bekleniyor).
    final pixelSize = (size * 2).toInt().clamp(1, 256);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: size,
          height: size,
          cacheWidth: pixelSize,
          cacheHeight: pixelSize,
          headers: imageHeaders,
          errorBuilder: (_, __, ___) {
            _recordFailedUrl(url);
            return _buildLetterAvatar(context);
          },
          frameBuilder: (_, child, frame, __) {
            if (frame == null) return _buildLetterAvatar(context);
            return child;
          },
        ),
      ),
    );
  }
}

/// Uzantısız avatar URL'sini HTTP ile çeker; Content-Type bitmap ise Image.memory ile gösterir, değilse fallback.
class _AvatarFromUrl extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final double size;
  final Widget fallback;
  final VoidCallback onFailed;

  const _AvatarFromUrl({
    required this.url,
    required this.headers,
    required this.size,
    required this.fallback,
    required this.onFailed,
  });

  @override
  State<_AvatarFromUrl> createState() => _AvatarFromUrlState();
}

class _AvatarFromUrlState extends State<_AvatarFromUrl> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final headers = <String, String>{
        'Accept': 'image/png, image/jpeg, image/gif, image/webp, image/*',
        ...?widget.headers,
      };
      final response = await http.get(
        Uri.parse(widget.url),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode != 200) {
        setState(() => _failed = true);
        // 401/403: yetki; kalıcı önbelleğe ekleme, giriş yenilenince tekrar dene
        if (response.statusCode != 401 && response.statusCode != 403) {
          widget.onFailed();
        }
        return;
      }

      final contentType = response.headers['content-type'];
      if (!LetterAvatar._isBitmapContentType(contentType)) {
        setState(() => _failed = true);
        widget.onFailed();
        return;
      }

      setState(() => _bytes = Uint8List.fromList(response.bodyBytes));
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
        widget.onFailed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _bytes == null) return widget.fallback;

    final pixelSize = (widget.size * 2).toInt().clamp(1, 256);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(
        child: Image.memory(
          _bytes!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          cacheWidth: pixelSize,
          cacheHeight: pixelSize,
          errorBuilder: (_, __, ___) {
            widget.onFailed();
            return widget.fallback;
          },
        ),
      ),
    );
  }
}
