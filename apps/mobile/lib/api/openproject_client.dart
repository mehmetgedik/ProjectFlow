import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/project.dart';
import '../models/saved_query.dart';
import '../models/version.dart';
import '../models/work_package.dart';
import '../models/work_package_activity.dart';
import '../models/time_entry.dart';
import '../models/notification_item.dart';
import '../models/week_day.dart';

class OpenProjectClient {
  final Uri apiBase;
  final String apiKey;

  OpenProjectClient({
    required this.apiBase,
    required this.apiKey,
  });

  Map<String, String> _headers({bool jsonBody = false}) {
    // OpenProject API key usage: Basic auth with username "apikey" and password = api key.
    final auth = base64Encode(utf8.encode('apikey:$apiKey'));
    return {
      'Accept': 'application/hal+json',
      if (jsonBody) 'Content-Type': 'application/json',
      'Authorization': 'Basic $auth',
    };
  }

  Uri _resolve(String path, {Map<String, String>? query}) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return apiBase.resolve(normalized).replace(queryParameters: query);
  }

  /// Varsayılan istek süresi (saniye). Görünüm sonuçları büyük olabildiği için yeterli süre verilir.
  static const int _defaultTimeoutSeconds = 90;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) async {
    final uri = _resolve(path, query: query);
    final duration = timeout ?? const Duration(seconds: _defaultTimeoutSeconds);
    try {
      final res = await http.get(uri, headers: _headers()).timeout(
        duration,
        onTimeout: () => throw TimeoutException(
          'Sunucu yanıt vermedi (${duration.inSeconds} sn). Bağlantıyı veya sayfa boyutunu kontrol edin.',
        ),
      );
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw Exception('Yetkisiz erişim (HTTP ${res.statusCode}). API key ve yetkileri kontrol edin.');
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('İstek başarısız oldu (HTTP ${res.statusCode}): ${res.body}');
      }
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on TimeoutException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final uri = _resolve(path);
    final res = await http.post(uri, headers: _headers(jsonBody: true), body: jsonEncode(body));
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Yetkisiz erişim (HTTP ${res.statusCode}). API key ve yetkileri kontrol edin.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('İstek başarısız oldu (HTTP ${res.statusCode}): ${res.body}');
    }
    if (res.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) async {
    final uri = _resolve(path);
    final res = await http.patch(uri, headers: _headers(jsonBody: true), body: jsonEncode(body));
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('Yetkisiz erişim (HTTP ${res.statusCode}). API key ve yetkileri kontrol edin.');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('İstek başarısız oldu (HTTP ${res.statusCode}): ${res.body}');
    }
    if (res.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> validateMe() async {
    await getJson('/users/me');
  }

  /// Returns user display name (name, or firstName + lastName, or login).
  Future<String?> getMeDisplayName() async {
    final data = await getMe();
    return data['name'] ?? data['login'];
  }

  /// Returns user info for profile: name, login, avatar, firstName, lastName (API izin verdiği ölçüde).
  /// Avatar: API'dan gelir veya web'deki gibi /api/v3/users/{id}/avatar ile oluşturulur (cookie/Basic auth ile aynı endpoint).
  Future<Map<String, String>> getMe() async {
    final data = await getJson('/users/me') as Map<String, dynamic>;
    String? name = data['name']?.toString();
    final first = data['firstName']?.toString() ?? '';
    final last = data['lastName']?.toString() ?? '';
    if (name == null || name.isEmpty) {
      name = '$first $last'.trim();
    }
    if (name == null || name.isEmpty) name = data['login']?.toString();
    final login = data['login']?.toString();
    String? avatar = data['avatar']?.toString();
    if (avatar == null || avatar.isEmpty) {
      final links = data['_links'] as Map<String, dynamic>?;
      final avatarLink = links?['avatar'];
      if (avatarLink is Map) {
        avatar = avatarLink['href']?.toString();
      } else if (avatarLink != null) {
        avatar = avatarLink.toString();
      }
    }
    // Göreli avatar URL'ini (örn. /api/v3/users/5/avatar) mutlak yap
    if (avatar != null && avatar.isNotEmpty && avatar.startsWith('/')) {
      avatar = apiBase.origin + avatar;
    }
    // Uygulama her zaman API avatar endpoint'ini kullanır: /api/v3/users/{id}/avatar (web ile aynı; Basic auth kabul eder)
    final idObj = data['id'];
    final idStr = idObj?.toString();
    if (idStr != null && idStr.isNotEmpty) {
      final base = apiBase.toString().replaceAll(RegExp(r'/+$'), '');
      avatar = '$base/users/$idStr/avatar';
    } else if (avatar == null || avatar.isEmpty) {
      // id yoksa API'den gelen avatar (örn. Gravatar) kalsın
    }
    final email = data['email']?.toString();
    return <String, String>{
      if (idStr != null && idStr.isNotEmpty) 'id': idStr,
      if (name != null && name.isNotEmpty) 'name': name,
      if (login != null && login.isNotEmpty) 'login': login,
      if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
      if (email != null && email.isNotEmpty) 'email': email,
      'firstName': first,
      'lastName': last,
    };
  }

  /// Kendi profilini günceller (P1-F01). Yetki yoksa 403. firstName/lastName API izin veriyorsa yazılır.
  Future<void> patchMe({String? firstName, String? lastName}) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (body.isEmpty) return;
    await patchJson('/users/me', body);
  }

  /// Work schedule: haftanın hangi günleri çalışma günü (1 = Pazartesi, 7 = Pazar).
  /// API 404/403 dönerse boş liste veya varsayılan (Pzt–Cuma) kullanılabilir.
  Future<List<WeekDay>> getWeekDays() async {
    try {
      final data = await getJson('/days/week');
      final embedded = data['_embedded'] as Map<String, dynamic>?;
      final elements = (embedded?['elements'] as List?) ?? const [];
      return elements.whereType<Map<String, dynamic>>().map(WeekDay.fromJson).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Sadece aktif projeleri getirir (arşivlenmiş/pasif projeler listelenmez).
  Future<List<Project>> getProjects() async {
    final filters = <Map<String, dynamic>>[
      {
        'active': {
          'operator': '=',
          'values': ['t'], // sadece aktif (true)
        },
      },
    ];
    final data = await getJson(
      '/projects',
      query: <String, String>{'filters': jsonEncode(filters)},
    );
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    return elements.whereType<Map>().map(Project.fromJson).toList(growable: false);
  }

  /// Projedeki versiyonları (sprint / release) getirir. Açık sprint seçimi için kullanılır.
  Future<List<Version>> getProjectVersions(String projectId) async {
    if (projectId.isEmpty) return const [];
    final data = await getJson('/projects/$projectId/versions');
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    return elements.whereType<Map<String, dynamic>>().map(Version.fromJson).toList(growable: false);
  }

  Future<WorkPackage> getWorkPackage(String id) async {
    final data = await getJson('/work_packages/$id');
    return WorkPackage.fromJson(data);
  }

  /// Yeni iş paketi oluşturur. projectId ve typeId zorunlu.
  Future<WorkPackage> createWorkPackage({
    required String projectId,
    required String typeId,
    required String subject,
    String? description,
  }) async {
    if (subject.trim().isEmpty) throw Exception('Başlık zorunludur.');
    final body = <String, dynamic>{
      'subject': subject.trim(),
      '_links': <String, dynamic>{
        'project': {'href': '/api/v3/projects/$projectId'},
        'type': {'href': '/api/v3/types/$typeId'},
      },
    };
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = {'raw': description.trim()};
    }
    final data = await postJson('/work_packages', body);
    return WorkPackage.fromJson(data);
  }

  /// Verilen id listesine ait iş paketlerini tek istekle getirir (bildirim satırlarında durum/tip göstermek için).
  Future<List<WorkPackage>> getWorkPackagesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final uniqueIds = ids.toSet().toList(growable: false);
    final filters = [
      {'id': {'operator': '=', 'values': uniqueIds}},
    ];
    final query = <String, String>{
      'filters': jsonEncode(filters),
      'pageSize': uniqueIds.length.clamp(1, 100).toString(),
      'offset': '1',
    };
    final data = await getJson('/work_packages', query: query);
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    return elements.whereType<Map>().map(WorkPackage.fromJson).toList(growable: false);
  }

  /// Tüm durumları getirir (iş paketi güncellemede seçim için). P0-F04.
  Future<List<Map<String, String>>> getStatuses() async {
    final data = await getJson('/statuses');
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    final result = <Map<String, String>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['id']?.toString();
      final name = e['name']?.toString();
      if (id != null && id.isNotEmpty) {
        result.add({'id': id, 'name': name ?? id});
      }
    }
    return result;
  }

  /// Projedeki üyeleri getirir (atanan seçimi için). P0-F04. Yetki: view_members veya manage_members.
  Future<List<Map<String, String>>> getProjectMembers(String projectId) async {
    final filters = jsonEncode([
      {'project': {'operator': '=', 'values': [projectId]}}
    ]);
    final data = await getJson('/memberships', query: {'filters': filters, 'pageSize': '100'});
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) continue;
      final principal = e['_links']?['principal'] as Map<String, dynamic>?;
      if (principal == null) continue;
      final href = principal['href']?.toString() ?? '';
      final title = principal['title']?.toString() ?? '';
      final id = href.contains('/users/') ? href.split('/users/').last.split('/').first : null;
      if (id != null && id.isNotEmpty && !seen.contains(id)) {
        seen.add(id);
        result.add({'id': id, 'name': title.isNotEmpty ? title : id});
      }
    }
    return result;
  }

  /// Projedeki kullanılabilir tipleri getirir (iş tipi seçimi için).
  Future<List<Map<String, String>>> getProjectTypes(String projectId) async {
    final data = await getJson('/projects/$projectId/types');
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    final result = <Map<String, String>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['id']?.toString();
      final name = e['name']?.toString();
      if (id != null && id.isNotEmpty) {
        result.add({'id': id, 'name': name ?? id});
      }
    }
    return result;
  }

  /// İş paketini günceller (durum, tip, üst iş, atanan, bitiş tarihi). Yetki: edit work packages.
  /// assigneeId verilirse o kullanıcı atanır; clearAssignee true ise atanan kaldırılır (href: null).
  Future<WorkPackage> patchWorkPackage(
    String id, {
    String? statusId,
    String? assigneeId,
    bool clearAssignee = false,
    DateTime? dueDate,
    String? typeId,
    String? parentId,
    bool clearParent = false,
  }) async {
    final links = <String, dynamic>{};
    if (statusId != null && statusId.isNotEmpty) {
      links['status'] = {'href': '/api/v3/statuses/$statusId'};
    }
    if (clearAssignee) {
      links['assignee'] = {'href': null};
    } else if (assigneeId != null && assigneeId.isNotEmpty) {
      links['assignee'] = {'href': '/api/v3/users/$assigneeId'};
    }
    if (typeId != null && typeId.isNotEmpty) {
      links['type'] = {'href': '/api/v3/types/$typeId'};
    }
    if (clearParent) {
      links['parent'] = {'href': null};
    } else if (parentId != null && parentId.isNotEmpty) {
      links['parent'] = {'href': '/api/v3/work_packages/$parentId'};
    }
    final body = <String, dynamic>{};
    if (links.isNotEmpty) body['_links'] = links;
    if (dueDate != null) {
      body['dueDate'] = dueDate.toIso8601String().split('T').first;
    }
    if (body.isEmpty) return getWorkPackage(id);
    final data = await patchJson('/work_packages/$id', body);
    return WorkPackage.fromJson(data);
  }

  /// Kayıtlı görünümleri getirir: önce /views API dener (web arayüzüyle aynı), yoksa /queries.
  /// projectId verilirse o projeye + global görünümler birleştirilir.
  Future<List<SavedQuery>> getQueries({String? projectId}) async {
    final fromViews = await getViews(projectId: projectId);
    if (fromViews.isNotEmpty) return fromViews;

    return getQueriesLegacy(projectId: projectId);
  }

  /// GET /api/v3/views ile görünüm listesi (OpenProject yeni sürümlerde Views kullanır).
  Future<List<SavedQuery>> getViews({String? projectId}) async {
    for (final filterKey in ['project', 'project_id']) {
      final all = <SavedQuery>[];
      if (projectId != null && projectId.isNotEmpty) {
        final filters = jsonEncode([
          {filterKey: {'operator': '=', 'values': [projectId]}}
        ]);
        try {
          final data = await getJson('/views', query: {'filters': filters});
          final embedded = data['_embedded'] as Map<String, dynamic>?;
          final elements = (embedded?['elements'] as List?) ?? const [];
          for (final e in elements) {
            if (e is Map<String, dynamic>) {
              final sq = _savedQueryFromView(e);
              if (sq != null) all.add(sq);
            }
          }
        } catch (_) {}
      }
      final globalFilters = jsonEncode([
        {filterKey: {'operator': '!*', 'values': null}}
      ]);
      try {
        final data = await getJson('/views', query: {'filters': globalFilters});
        final embedded = data['_embedded'] as Map<String, dynamic>?;
        final elements = (embedded?['elements'] as List?) ?? const [];
        for (final e in elements) {
          if (e is Map<String, dynamic>) {
            final sq = _savedQueryFromView(e);
            if (sq != null) all.add(sq);
          }
        }
      } catch (_) {}
      if (all.isNotEmpty) return all;
    }
    return [];
  }

  /// View JSON'ından minimal SavedQuery üretir (query id, name, projectId; kolonlar boş).
  SavedQuery? _savedQueryFromView(Map<String, dynamic> view) {
    final links = view['_links'] as Map<String, dynamic>? ?? {};
    final queryLink = links['query'];
    if (queryLink == null) return null;
    final href = queryLink is Map ? queryLink['href']?.toString() : null;
    if (href == null || href.isEmpty) return null;
    final queryIdStr = href.contains('/queries/')
        ? href.split('/queries/').last.split('/').first.split('?').first.trim()
        : null;
    final queryId = int.tryParse(queryIdStr ?? '');
    if (queryId == null || queryId < 1) return null;
    final name = view['name']?.toString() ?? '';
    if (name.isEmpty) return null;
    String? projectId;
    final projectLink = links['project'];
    if (projectLink is Map) {
      final ph = projectLink['href']?.toString() ?? '';
      if (ph.contains('/projects/')) {
        projectId = ph.split('/projects/').last.split('/').first.trim();
      }
    }
    return SavedQuery(
      id: queryId,
      name: name,
      projectId: projectId?.isEmpty == true ? null : projectId,
      columns: const [],
      starred: view['starred'] == true,
      public: view['public'] == true,
      hidden: false,
    );
  }

  /// Eski /queries endpoint; filtre adı olarak project ve project_id denenir.
  Future<List<SavedQuery>> getQueriesLegacy({String? projectId}) async {
    final all = <SavedQuery>[];
    for (final filterKey in ['project', 'project_id']) {
      if (projectId != null && projectId.isNotEmpty) {
        final filters = jsonEncode([
          {filterKey: {'operator': '=', 'values': [projectId]}}
        ]);
        try {
          final data = await getJson('/queries', query: {'filters': filters});
          final embedded = data['_embedded'] as Map<String, dynamic>?;
          final elements = (embedded?['elements'] as List?) ?? const [];
          for (final e in elements) {
            if (e is Map<String, dynamic>) all.add(SavedQuery.fromJson(e));
          }
          if (all.isNotEmpty) return all;
        } catch (_) {}
      }
      final globalFilters = jsonEncode([
        {filterKey: {'operator': '!*', 'values': null}}
      ]);
      try {
        final data = await getJson('/queries', query: {'filters': globalFilters});
        final embedded = data['_embedded'] as Map<String, dynamic>?;
        final elements = (embedded?['elements'] as List?) ?? const [];
        for (final e in elements) {
          if (e is Map<String, dynamic>) all.add(SavedQuery.fromJson(e));
        }
        if (all.isNotEmpty) return all;
      } catch (_) {}
    }
    try {
      final data = await getJson('/queries');
      final embedded = data['_embedded'] as Map<String, dynamic>?;
      final elements = (embedded?['elements'] as List?) ?? const [];
      for (final e in elements) {
        if (e is Map<String, dynamic>) all.add(SavedQuery.fromJson(e));
      }
    } catch (_) {}
    return all;
  }

  /// Tek bir görünümü sayfalı sonuçlarla getirir. Kolonlar ve sıralama görünümden gelir.
  /// [overrideFilters] verilirse sorgunun filtrelerini override eder (OpenProject API: filters query param).
  Future<QueryResults> getQueryWithResults(
    int queryId, {
    int pageSize = 50,
    int offset = 1,
    List<Map<String, dynamic>>? overrideFilters,
    List<List<String>>? sortBy,
    String? groupBy,
  }) async {
    final queryParams = <String, String>{
      'pageSize': pageSize.toString(),
      'offset': offset.toString(),
    };
    if (overrideFilters != null && overrideFilters.isNotEmpty) {
      queryParams['filters'] = jsonEncode(overrideFilters);
    }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParams['sortBy'] = jsonEncode(sortBy);
    }
    if (groupBy != null && groupBy.isNotEmpty) {
      queryParams['groupBy'] = groupBy;
    }
    final data = await getJson('/queries/$queryId', query: queryParams);
    final savedQuery = SavedQuery.fromJson(data);
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final results = embedded?['results'] as Map<String, dynamic>?;
    int total = 0;
    final elements = <WorkPackage>[];
    if (results != null) {
      final totalVal = results['total'] ?? results['count'];
      total = totalVal is int
          ? totalVal
          : (totalVal != null ? int.tryParse(totalVal.toString()) ?? 0 : 0);
      final resEmbedded = results['_embedded'] as Map<String, dynamic>?;
      final list = (resEmbedded?['elements'] as List?) ?? (results['elements'] as List?) ?? const [];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            elements.add(WorkPackage.fromJson(e));
          } catch (_) {
            // Tek kayıt parse hatası listeyi bırakma
          }
        }
      }
    }
    return QueryResults(query: savedQuery, workPackages: elements, total: total);
  }

  /// Varsayılan "benim açık işlerim" listesi; sayfalama destekler (P0-F03).
  /// [extraFilters] ek filtreler (AND ile birleştirilir).
  Future<MyWorkPackagesResult> getMyOpenWorkPackages({
    String? projectId,
    int pageSize = 20,
    int offset = 1,
    List<Map<String, dynamic>>? extraFilters,
  }) async {
    final filters = <Map<String, dynamic>>[
      {
        'assignee': {
          'operator': '=',
          'values': ['me'],
        },
      },
      {
        'status': {
          'operator': 'o', // open
          'values': <String>[],
        },
      },
    ];

    if (projectId != null && projectId.isNotEmpty) {
      filters.add({
        'project': {
          'operator': '=',
          'values': [projectId],
        },
      });
    }
    if (extraFilters != null && extraFilters.isNotEmpty) {
      filters.addAll(extraFilters);
    }

    final query = <String, String>{
      'filters': jsonEncode(filters),
      'pageSize': pageSize.toString(),
      'offset': offset.toString(),
    };
    final data = await getJson('/work_packages', query: query);
    final total = data['total'];
    final totalInt = total is int
        ? total
        : (total != null ? int.tryParse(total.toString()) ?? 0 : 0);
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    final workPackages =
        elements.whereType<Map>().map(WorkPackage.fromJson).toList(growable: false);
    return MyWorkPackagesResult(workPackages: workPackages, total: totalInt);
  }

  /// İş paketlerini özel filtrelerle getirir (OpenProject: GET /work_packages?filters=...).
  Future<MyWorkPackagesResult> getWorkPackages({
    String? projectId,
    required List<Map<String, dynamic>> filters,
    List<List<String>>? sortBy,
    int pageSize = 20,
    int offset = 1,
  }) async {
    if (filters.isEmpty) {
      return getMyOpenWorkPackages(projectId: projectId, pageSize: pageSize, offset: offset);
    }
    final list = List<Map<String, dynamic>>.from(filters);
    if (projectId != null && projectId.isNotEmpty) {
      list.add({
        'project': {'operator': '=', 'values': [projectId]},
      });
    }
    final query = <String, String>{
      'filters': jsonEncode(list),
      'pageSize': pageSize.toString(),
      'offset': offset.toString(),
    };
    if (sortBy != null && sortBy.isNotEmpty) {
      query['sortBy'] = jsonEncode(sortBy);
    }
    final data = await getJson('/work_packages', query: query);
    final total = data['total'];
    final totalInt = total is int
        ? total
        : (total != null ? int.tryParse(total.toString()) ?? 0 : 0);
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    final workPackages =
        elements.whereType<Map>().map(WorkPackage.fromJson).toList(growable: false);
    return MyWorkPackagesResult(workPackages: workPackages, total: totalInt);
  }

  Future<List<WorkPackageActivity>> getWorkPackageActivities(String workPackageId) async {
    final data = await getJson('/work_packages/$workPackageId/activities');
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    return elements.whereType<Map>().map(WorkPackageActivity.fromJson).toList(growable: false);
  }

  Future<void> addWorkPackageComment({
    required String workPackageId,
    required String comment,
  }) async {
    if (comment.trim().isEmpty) {
      throw Exception('Yorum metni boş olamaz.');
    }
    await postJson(
      '/work_packages/$workPackageId/activities',
      <String, dynamic>{
        'comment': <String, dynamic>{'raw': comment},
      },
    );
  }

  /// Zaman kayıtlarını tarih aralığına (ve isteğe bağlı kullanıcıya) göre getirir.
  /// [userId] verilirse o kullanıcının kayıtları (yetki: view time entries / view own).
  /// OpenProject API: spent_on <>d, user_id filtresi.
  Future<List<TimeEntry>> getMyTimeEntries({
    DateTime? from,
    DateTime? to,
    String? userId,
  }) async {
    final filters = <Map<String, dynamic>>[];
    if (userId != null && userId.isNotEmpty) {
      filters.add({
        'user_id': {'operator': '=', 'values': [userId]},
      });
    }
    if (from != null && to != null) {
      final fromStr = from.toIso8601String().split('T').first;
      final toStr = to.toIso8601String().split('T').first;
      filters.add({
        'spent_on': {
          'operator': '<>d',
          'values': [fromStr, toStr],
        },
      });
    } else if (from != null) {
      filters.add({
        'spent_on': {
          'operator': '>=',
          'values': [from.toIso8601String().split('T').first],
        },
      });
    } else if (to != null) {
      filters.add({
        'spent_on': {
          'operator': '<=',
          'values': [to.toIso8601String().split('T').first],
        },
      });
    }
    final query = <String, String>{
      'pageSize': '500',
      'sortBy': jsonEncode([['spent_on', 'desc']]),
    };
    if (filters.isNotEmpty) query['filters'] = jsonEncode(filters);
    final data = await getJson('/time_entries', query: query);
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    return elements.whereType<Map>().map(TimeEntry.fromJson).toList(growable: false);
  }

  /// Zaman kayıtları listesi. OpenProject API: entity_type + entity_id kullanılır (workPackage deprecated).
  Future<List<TimeEntry>> getWorkPackageTimeEntries(String workPackageId) async {
    final filters = <Map<String, dynamic>>[
      {
        'entity_type': {
          'operator': '=',
          'values': ['WorkPackage'],
        },
      },
      {
        'entity_id': {
          'operator': '=',
          'values': [workPackageId],
        },
      },
    ];
    final data = await getJson(
      '/time_entries',
      query: <String, String>{'filters': jsonEncode(filters)},
    );
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    return elements.whereType<Map>().map(TimeEntry.fromJson).toList(growable: false);
  }

  /// Yeni zaman kaydı oluşturur. API: _links.entity kullanılır (workPackage deprecated).
  Future<void> createTimeEntry({
    required String workPackageId,
    required double hours,
    required DateTime spentOn,
    String? comment,
  }) async {
    if (hours <= 0) throw Exception('Saat pozitif olmalıdır.');
    final duration = 'PT${hours.toString()}H';
    final body = <String, dynamic>{
      'hours': duration,
      'spentOn': spentOn.toIso8601String().split('T').first,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': <String, dynamic>{'raw': comment},
      '_links': <String, dynamic>{
        'entity': <String, String>{
          'href': '/api/v3/work_packages/$workPackageId',
        },
      },
    };
    await postJson('/time_entries', body);
  }

  Future<List<NotificationItem>> getNotifications({bool onlyUnread = false}) async {
    final query = <String, String>{'pageSize': '100'};
    if (onlyUnread) {
      final filters = <Map<String, dynamic>>[
        {'readIAN': {'operator': '=', 'values': ['f']}},
      ];
      query['filters'] = jsonEncode(filters);
    }

    final uri = _resolve('/notifications', query: query);
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 404) {
      throw Exception(
        'Bildirim API\'si bu OpenProject kurulumunda kullanılamıyor (HTTP 404). '
        'Sunucu tarafında bildirim özelliği devre dışı olabilir.',
      );
    }
    if (res.statusCode == 400) {
      // Filtre bazı sunucularda geçersiz olabiliyor; filtre olmadan dene ve istemci tarafında filtrele.
      if (onlyUnread) {
        final fallbackUri = _resolve('/notifications', query: {'pageSize': '100'});
        final fallbackRes = await http.get(fallbackUri, headers: _headers());
        if (fallbackRes.statusCode == 200) {
          final data = jsonDecode(fallbackRes.body) as Map<String, dynamic>;
          final embedded = data['_embedded'] as Map<String, dynamic>?;
          final elements = (embedded?['elements'] as List?) ?? const [];
          final list = elements.whereType<Map>().map(NotificationItem.fromJson).toList(growable: false);
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
    final embedded = data['_embedded'] as Map<String, dynamic>?;
    final elements = (embedded?['elements'] as List?) ?? const [];
    return elements.whereType<Map>().map(NotificationItem.fromJson).toList(growable: false);
  }

  /// Okunmamış bildirim sayısı (badge için). API total döndürür.
  Future<int> getUnreadNotificationCount() async {
    final filters = <Map<String, dynamic>>[
      {'readIAN': {'operator': '=', 'values': ['f']}},
    ];
    final uri = _resolve('/notifications', query: {'filters': jsonEncode(filters), 'pageSize': '1'});
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 404 || res.statusCode == 401 || res.statusCode == 403) return 0;
    if (res.statusCode < 200 || res.statusCode >= 300) return 0;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final total = data['total'];
    if (total is int) return total;
    if (total != null) return int.tryParse(total.toString()) ?? 0;
    return 0;
  }

  Future<void> markNotificationRead(String id) async {
    final uri = _resolve('/notifications/$id/read_ian');
    final headers = _headers(jsonBody: true);
    var res = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(<String, dynamic>{}),
    );
    if (res.statusCode == 406) {
      // Bazı sunucular POST read_ian yerine PATCH ile readIAN güncellemesi bekler.
      final patchUri = _resolve('/notifications/$id');
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

  /// Tüm bildirimleri okundu olarak işaretler (OpenProject API: POST /notifications/read_ian).
  Future<void> markAllNotificationsRead() async {
    final uri = _resolve('/notifications/read_ian');
    final res = await http.post(
      uri,
      headers: _headers(jsonBody: true),
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

/// Varsayılan "benim açık işlerim" listesi sayfa sonucu (P0-F03 sayfalama).
class MyWorkPackagesResult {
  final List<WorkPackage> workPackages;
  final int total;

  const MyWorkPackagesResult({required this.workPackages, required this.total});
}

