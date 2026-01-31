import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/saved_query.dart';
import '../models/work_package.dart';
import '../models/work_package_activity.dart';
import '../services/api_reference_cache.dart';
import '../utils/app_logger.dart';
import 'openproject_base.dart';

/// Varsayılan "benim açık işlerim" listesi sayfa sonucu (P0-F03 sayfalama).
class MyWorkPackagesResult {
  const MyWorkPackagesResult({required this.workPackages, required this.total});
  final List<WorkPackage> workPackages;
  final int total;
}

class WorkPackageApi {
  WorkPackageApi(this._base);

  final OpenProjectBase _base;

  Future<WorkPackage> getWorkPackage(String id) async {
    final data = await _base.getJson('/work_packages/$id');
    return WorkPackage.fromJson(data);
  }

  Future<WorkPackage> createWorkPackage({
    required String projectId,
    required String typeId,
    required String subject,
    String? description,
    String? assigneeId,
    String? priorityId,
    String? statusId,
    String? parentId,
    String? versionId,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    if (subject.trim().isEmpty) throw Exception('Başlık zorunludur.');
    final links = <String, dynamic>{
      'project': {'href': '/api/v3/projects/$projectId'},
      'type': {'href': '/api/v3/types/$typeId'},
    };
    if (statusId != null && statusId.isNotEmpty) {
      links['status'] = {'href': '/api/v3/statuses/$statusId'};
    }
    if (assigneeId != null && assigneeId.isNotEmpty) {
      links['assignee'] = {'href': '/api/v3/users/$assigneeId'};
    }
    if (priorityId != null && priorityId.isNotEmpty) {
      links['priority'] = {'href': '/api/v3/priorities/$priorityId'};
    }
    if (parentId != null && parentId.isNotEmpty) {
      links['parent'] = {'href': '/api/v3/work_packages/$parentId'};
    }
    if (versionId != null && versionId.isNotEmpty) {
      links['version'] = {'href': '/api/v3/versions/$versionId'};
    }
    final body = <String, dynamic>{
      'subject': subject.trim(),
      '_links': links,
    };
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = {'raw': description.trim()};
    }
    if (startDate != null) {
      body['startDate'] = startDate.toIso8601String().split('T').first;
    }
    if (dueDate != null) {
      body['dueDate'] = dueDate.toIso8601String().split('T').first;
    }
    final data = await _base.postJson('/work_packages', body);
    return WorkPackage.fromJson(data);
  }

  Future<List<WorkPackage>> getWorkPackagesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    // Boş ve sayısal olmayan id'leri atla
    final validIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && int.tryParse(id) != null)
        .toSet()
        .toList(growable: false);
    if (validIds.isEmpty) return const [];

    // Önce toplu id filtresi dene; bazı sunucular "Id filtrede geçersiz değerler var" (400) döner
    try {
      final filters = [
        {'id': {'operator': '=', 'values': validIds}},
      ];
      final query = <String, String>{
        'filters': jsonEncode(filters),
        'pageSize': validIds.length.clamp(1, 100).toString(),
        'offset': '1',
      };
      final data = await _base.getJson('/work_packages', query: query);
      final elements = _base.elementsFromResponse(data);
      return elements.whereType<Map>().map(WorkPackage.fromJson).toList(growable: false);
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('InvalidQuery') ||
          msg.contains('Id filtrede') ||
          msg.contains('400')) {
        return _getWorkPackagesByIdsOneByOne(validIds);
      }
      rethrow;
    }
  }

  /// Id filtresi desteklenmeyen sunucularda tek tek GET /work_packages/:id ile çeker.
  Future<List<WorkPackage>> _getWorkPackagesByIdsOneByOne(List<String> ids) async {
    final results = await Future.wait(
      ids.map((id) async {
        try {
          return await getWorkPackage(id);
        } catch (_) {
          return null;
        }
      }),
    );
    return results.whereType<WorkPackage>().toList(growable: false);
  }

  Future<List<Map<String, String>>> getStatuses() async {
    final cached = ApiReferenceCache.instance.get<List<Map<String, String>>>('statuses');
    if (cached != null) return cached;
    final data = await _base.getJson('/statuses');
    final elements = _base.elementsFromResponse(data);
    final result = <Map<String, String>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['id']?.toString();
      final name = e['name']?.toString();
      final color = e['color']?.toString();
      if (id != null && id.isNotEmpty) {
        final m = <String, String>{'id': id, 'name': name ?? id};
        if (color != null && color.isNotEmpty) m['color'] = color;
        result.add(m);
      }
    }
    ApiReferenceCache.instance.put('statuses', result);
    return result;
  }

  Future<List<Map<String, String>>> getPriorities() async {
    final cached = ApiReferenceCache.instance.get<List<Map<String, String>>>('priorities');
    if (cached != null) return cached;
    final data = await _base.getJson('/priorities');
    final elements = _base.elementsFromResponse(data);
    final result = <Map<String, String>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['id']?.toString();
      final name = e['name']?.toString();
      if (id != null && id.isNotEmpty) {
        result.add({'id': id, 'name': name ?? id});
      }
    }
    ApiReferenceCache.instance.put('priorities', result);
    return result;
  }

  Future<List<Map<String, String>>> getProjectMembers(String projectId) async {
    final key = 'project_members:$projectId';
    final cached = ApiReferenceCache.instance.get<List<Map<String, String>>>(key);
    if (cached != null) return cached;
    final filters = jsonEncode([
      {'project': {'operator': '=', 'values': [projectId]}}
    ]);
    final data = await _base.getJson('/memberships', query: {'filters': filters, 'pageSize': '100'});
    final elements = _base.elementsFromResponse(data);
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
    ApiReferenceCache.instance.put(key, result);
    return result;
  }

  Future<List<Map<String, String>>> getProjectTypes(String projectId) async {
    final key = 'project_types:$projectId';
    final cached = ApiReferenceCache.instance.get<List<Map<String, String>>>(key);
    if (cached != null) return cached;
    final data = await _base.getJson('/projects/$projectId/types');
    final elements = _base.elementsFromResponse(data);
    final result = <Map<String, String>>[];
    for (final e in elements) {
      if (e is! Map<String, dynamic>) continue;
      final id = e['id']?.toString();
      final name = e['name']?.toString();
      final color = e['color']?.toString();
      if (id != null && id.isNotEmpty) {
        final m = <String, String>{'id': id, 'name': name ?? id};
        if (color != null && color.isNotEmpty) m['color'] = color;
        result.add(m);
      }
    }
    ApiReferenceCache.instance.put(key, result);
    return result;
  }

  Future<List<WorkPackage>> searchWorkPackagesForParent({
    required String projectId,
    required String query,
    int pageSize = 20,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final filters = [
      {'project': {'operator': '=', 'values': [projectId]}},
      {'subjectOrId': {'operator': '**', 'values': [q]}},
    ];
    final r = await getWorkPackages(projectId: projectId, filters: filters, pageSize: pageSize, offset: 1);
    return r.workPackages;
  }

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
    final data = await _base.patchJson('/work_packages/$id', body);
    return WorkPackage.fromJson(data);
  }

  Future<List<SavedQuery>> getQueries({String? projectId}) async {
    final key = 'queries:${projectId ?? "null"}';
    final cached = ApiReferenceCache.instance.get<List<SavedQuery>>(key);
    if (cached != null) return cached;
    final fromViews = await getViews(projectId: projectId);
    final result = fromViews.isNotEmpty ? fromViews : await getQueriesLegacy(projectId: projectId);
    ApiReferenceCache.instance.put(key, result);
    return result;
  }

  Future<List<SavedQuery>> getViews({String? projectId}) async {
    for (final filterKey in ['project', 'project_id']) {
      final all = <SavedQuery>[];
      if (projectId != null && projectId.isNotEmpty) {
        final filters = jsonEncode([
          {filterKey: {'operator': '=', 'values': [projectId]}}
        ]);
        try {
          final data = await _base.getJson('/views', query: {'filters': filters});
          final elements = _base.elementsFromResponse(data);
          for (final e in elements) {
            if (e is Map<String, dynamic>) {
              final sq = _savedQueryFromView(e);
              if (sq != null) all.add(sq);
            }
          }
        } catch (e) {
          if (kDebugMode) AppLogger.logError('getQueries /views (project) başarısız', error: e);
        }
      }
      final globalFilters = jsonEncode([
        {filterKey: {'operator': '!*', 'values': null}}
      ]);
      try {
        final data = await _base.getJson('/views', query: {'filters': globalFilters});
        final elements = _base.elementsFromResponse(data);
        for (final e in elements) {
          if (e is Map<String, dynamic>) {
            final sq = _savedQueryFromView(e);
            if (sq != null) all.add(sq);
          }
        }
      } catch (e) {
        if (kDebugMode) AppLogger.logError('getQueries /views (global) başarısız', error: e);
      }
      if (all.isNotEmpty) return all;
    }
    return [];
  }

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

  Future<List<SavedQuery>> getQueriesLegacy({String? projectId}) async {
    final all = <SavedQuery>[];
    for (final filterKey in ['project', 'project_id']) {
      if (projectId != null && projectId.isNotEmpty) {
        final filters = jsonEncode([
          {filterKey: {'operator': '=', 'values': [projectId]}}
        ]);
        try {
          final data = await _base.getJson('/queries', query: {'filters': filters});
          final elements = _base.elementsFromResponse(data);
          for (final e in elements) {
            if (e is Map<String, dynamic>) all.add(SavedQuery.fromJson(e));
          }
          if (all.isNotEmpty) return all;
        } catch (e) {
          if (kDebugMode) AppLogger.logError('getQueriesLegacy /queries (project) başarısız', error: e);
        }
      }
      final globalFilters = jsonEncode([
        {filterKey: {'operator': '!*', 'values': null}}
      ]);
      try {
        final data = await _base.getJson('/queries', query: {'filters': globalFilters});
        final elements = _base.elementsFromResponse(data);
        for (final e in elements) {
          if (e is Map<String, dynamic>) all.add(SavedQuery.fromJson(e));
        }
        if (all.isNotEmpty) return all;
      } catch (e) {
        if (kDebugMode) AppLogger.logError('getQueriesLegacy /queries (global) başarısız', error: e);
      }
    }
    try {
      final data = await _base.getJson('/queries');
      final elements = _base.elementsFromResponse(data);
      for (final e in elements) {
        if (e is Map<String, dynamic>) all.add(SavedQuery.fromJson(e));
      }
    } catch (e) {
      if (kDebugMode) AppLogger.logError('getQueriesLegacy /queries başarısız', error: e);
    }
    return all;
  }

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
    final data = await _base.getJson('/queries/$queryId', query: queryParams);
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
          } catch (e) {
            if (kDebugMode) AppLogger.logError('WorkPackage.fromJson parse hatası', error: e);
          }
        }
      }
    }
    return QueryResults(query: savedQuery, workPackages: elements, total: total);
  }

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
          'operator': 'o',
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
    final data = await _base.getJson('/work_packages', query: query);
    final total = data['total'];
    final totalInt = total is int
        ? total
        : (total != null ? int.tryParse(total.toString()) ?? 0 : 0);
    final elements = _base.elementsFromResponse(data);
    final workPackages =
        elements.whereType<Map>().map(WorkPackage.fromJson).toList(growable: false);
    return MyWorkPackagesResult(workPackages: workPackages, total: totalInt);
  }

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
    final data = await _base.getJson('/work_packages', query: query);
    final total = data['total'];
    final totalInt = total is int
        ? total
        : (total != null ? int.tryParse(total.toString()) ?? 0 : 0);
    final elements = _base.elementsFromResponse(data);
    final workPackages =
        elements.whereType<Map>().map(WorkPackage.fromJson).toList(growable: false);
    return MyWorkPackagesResult(workPackages: workPackages, total: totalInt);
  }

  Future<List<WorkPackageActivity>> getWorkPackageActivities(String workPackageId) async {
    final data = await _base.getJson('/work_packages/$workPackageId/activities');
    final elements = _base.elementsFromResponse(data);
    return elements.whereType<Map>().map(WorkPackageActivity.fromJson).toList(growable: false);
  }

  Future<void> addWorkPackageComment({
    required String workPackageId,
    required String comment,
  }) async {
    if (comment.trim().isEmpty) {
      throw Exception('Yorum metni boş olamaz.');
    }
    await _base.postJson(
      '/work_packages/$workPackageId/activities',
      <String, dynamic>{
        'comment': <String, dynamic>{'raw': comment},
      },
    );
  }
}
