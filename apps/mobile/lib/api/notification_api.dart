import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notification_item.dart';
import 'openproject_base.dart';

class NotificationApi {
  NotificationApi(this._base);

  final OpenProjectBase _base;

  Future<List<NotificationItem>> getNotifications({bool onlyUnread = false}) async {
    final query = <String, String>{'pageSize': '100'};
    if (onlyUnread) {
      final filters = <Map<String, dynamic>>[
        {'readIAN': {'operator': '=', 'values': ['f']}},
      ];
      query['filters'] = jsonEncode(filters);
    }

    final res = await _base.getResponse('/notifications', query: query);
    if (res.statusCode == 404) {
      throw Exception(
        'Bildirim API\'si bu OpenProject kurulumunda kullanılamıyor (HTTP 404). '
        'Sunucu tarafında bildirim özelliği devre dışı olabilir.',
      );
    }
    if (res.statusCode == 400) {
      if (onlyUnread) {
        final fallbackRes = await _base.getResponse('/notifications', query: {'pageSize': '100'});
        if (fallbackRes.statusCode == 200) {
          final data = jsonDecode(fallbackRes.body) as Map<String, dynamic>;
          final elements = _base.elementsFromResponse(data);
          final list =
              elements.whereType<Map>().map(NotificationItem.fromJson).toList(growable: false);
          return list.where((n) => !n.read).toList(growable: false);
        }
      }
      throw Exception('Bildirim listesi alınamadı (filtre sunucu tarafından kabul edilmedi).');
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Yetkisiz erişim (HTTP ${res.statusCode}). API key ve yetkileri kontrol edin.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('İstek başarısız oldu (HTTP ${res.statusCode}): ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final elements = _base.elementsFromResponse(data);
    return elements.whereType<Map>().map(NotificationItem.fromJson).toList(growable: false);
  }

  Future<int> getUnreadNotificationCount() async {
    final filters = <Map<String, dynamic>>[
      {'readIAN': {'operator': '=', 'values': ['f']}},
    ];
    final res = await _base.getResponse(
      '/notifications',
      query: {'filters': jsonEncode(filters), 'pageSize': '1'},
    );
    if (res.statusCode == 404 || res.statusCode == 401 || res.statusCode == 403) return 0;
    if (res.statusCode < 200 || res.statusCode >= 300) return 0;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final total = data['total'];
    if (total is int) return total;
    if (total != null) return int.tryParse(total.toString()) ?? 0;
    return 0;
  }

  Future<void> markNotificationRead(String id) async {
    final uri = _base.resolve('/notifications/$id/read_ian');
    final headers = _base.headers(jsonBody: true);
    var res = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(<String, dynamic>{}),
    );
    if (res.statusCode == 406) {
      final patchUri = _base.resolve('/notifications/$id');
      res = await http.patch(
        patchUri,
        headers: headers,
        body: jsonEncode(<String, dynamic>{'readIAN': true}),
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Bildirim okundu olarak işaretlenemedi (HTTP ${res.statusCode}).');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final uri = _base.resolve('/notifications/read_ian');
    final res = await http.post(
      uri,
      headers: _base.headers(jsonBody: true),
      body: jsonEncode(<String, dynamic>{}),
    );
    if (res.statusCode == 404) {
      throw Exception(
        'Bildirim API\'si bu OpenProject kurulumunda kullanılamıyor (HTTP 404).',
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Tümü okundu işaretlenemedi (HTTP ${res.statusCode}).');
    }
  }
}
