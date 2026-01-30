import 'dart:convert';

import '../models/project.dart';
import '../models/version.dart';
import '../services/api_reference_cache.dart';
import 'openproject_base.dart';

class ProjectApi {
  ProjectApi(this._base);

  final OpenProjectBase _base;

  Future<List<Project>> getProjects() async {
    final cached = ApiReferenceCache.instance.get<List<Project>>('projects');
    if (cached != null) return cached;
    final filters = <Map<String, dynamic>>[
      {
        'active': {
          'operator': '=',
          'values': ['t'],
        },
      },
    ];
    final data = await _base.getJson(
      '/projects',
      query: <String, String>{'filters': jsonEncode(filters)},
    );
    final elements = _base.elementsFromResponse(data);
    final result = elements.whereType<Map>().map(Project.fromJson).toList(growable: false);
    ApiReferenceCache.instance.put('projects', result);
    return result;
  }

  Future<List<Version>> getProjectVersions(String projectId) async {
    if (projectId.isEmpty) return const [];
    final key = 'project_versions:$projectId';
    final cached = ApiReferenceCache.instance.get<List<Version>>(key);
    if (cached != null) return cached;
    final data = await _base.getJson('/projects/$projectId/versions');
    final elements = _base.elementsFromResponse(data);
    final result = elements.whereType<Map<String, dynamic>>().map(Version.fromJson).toList(growable: false);
    ApiReferenceCache.instance.put(key, result);
    return result;
  }

}
