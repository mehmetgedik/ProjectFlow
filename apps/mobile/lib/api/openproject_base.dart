import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Ortak HTTP katmanı: OpenProject API istekleri için get/post/patch/delete ve yardımcılar.
/// Domain API sınıfları bu base'i kullanır; [OpenProjectClient] bu sınıfı extend edip API'leri oluşturur.
abstract class OpenProjectBase {
  Uri get apiBase;
  String get apiKey;

  static const int defaultTimeoutSeconds = 90;

  Map<String, String> headers({bool jsonBody = false}) {
    final auth = base64Encode(utf8.encode('apikey:$apiKey'));
    return {
      'Accept': 'application/hal+json',
      if (jsonBody) 'Content-Type': 'application/json',
      'Authorization': 'Basic $auth',
    };
  }

  Uri resolve(String path, {Map<String, String>? query}) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return apiBase.resolve(normalized).replace(queryParameters: query);
  }

  void checkResponse(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Yetkisiz erişim (HTTP ${res.statusCode}). API key ve yetkileri kontrol edin.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('İstek başarısız oldu (HTTP ${res.statusCode}): ${res.body}');
    }
  }

  List<dynamic> elementsFromResponse(Map<String, dynamic> data) {
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    return (embedded?['elements'] as List?) ?? const [];
  }

  Future<http.Response> getResponse(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    final uri = resolve(path, query: query);
    final duration = timeout ?? Duration(seconds: defaultTimeoutSeconds);
    return http.get(uri, headers: headers()).timeout(
          duration,
          onTimeout: () => throw TimeoutException(
            'Sunucu yanıt vermedi (${duration.inSeconds} sn). Bağlantıyı veya sayfa boyutunu kontrol edin.',
          ),
        );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    final res = await getResponse(path, query: query, timeout: timeout);
    checkResponse(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final uri = resolve(path);
    final res = await http.post(uri, headers: headers(jsonBody: true), body: jsonEncode(body));
    checkResponse(res);
    if (res.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) async {
    final bodyBytes = utf8.encode(jsonEncode(body));
    Uri uri = resolve(path);
    final h = headers(jsonBody: true);
    for (int redirectCount = 0; redirectCount < 3; redirectCount++) {
      final res = await http.patch(uri, headers: h, body: bodyBytes);
      if (res.statusCode == 307 || res.statusCode == 308) {
        final location = res.headers['location'];
        if (location != null && location.isNotEmpty) {
          final next = Uri.tryParse(location);
          if (next != null) {
            uri = next.isAbsolute
                ? next
                : (location.startsWith('/')
                    ? Uri.parse('${apiBase.origin}$location')
                    : apiBase.resolve(location));
            continue;
          }
        }
      }
      checkResponse(res);
      if (res.body.isEmpty) return <String, dynamic>{};
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Çok fazla yönlendirme (308/307).');
  }

  Future<void> deleteJson(String path) async {
    final uri = resolve(path);
    final res = await http.delete(uri, headers: headers());
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Yetkisiz erişim (HTTP ${res.statusCode}). API key ve yetkileri kontrol edin.');
    }
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('İstek başarısız oldu (HTTP ${res.statusCode}): ${res.body}');
    }
  }
}
