import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/time_entry.dart';
import '../models/time_entry_activity.dart';
import '../models/week_day.dart';
import '../services/api_reference_cache.dart';
import '../utils/app_logger.dart';
import 'openproject_base.dart';

class TimeEntryApi {
  TimeEntryApi(this._base);

  final OpenProjectBase _base;

  Future<List<WeekDay>> getWeekDays() async {
    final cached = ApiReferenceCache.instance.get<List<WeekDay>>('week_days');
    if (cached != null) return cached;
    try {
      final data = await _base.getJson('/days/week');
      final elements = _base.elementsFromResponse(data);
      final result =
          elements.whereType<Map<String, dynamic>>().map(WeekDay.fromJson).toList(growable: false);
      ApiReferenceCache.instance.put('week_days', result);
      return result;
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Hafta günleri yüklenemedi', error: e);
      return const [];
    }
  }

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
    final data = await _base.getJson('/time_entries', query: query);
    final elements = _base.elementsFromResponse(data);
    return elements.whereType<Map>().map(TimeEntry.fromJson).toList(growable: false);
  }

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
    final data = await _base.getJson(
      '/time_entries',
      query: <String, String>{'filters': jsonEncode(filters)},
    );
    final elements = _base.elementsFromResponse(data);
    return elements.whereType<Map>().map(TimeEntry.fromJson).toList(growable: false);
  }

  Future<List<TimeEntryActivity>> getTimeEntryActivities() async {
    final cached = ApiReferenceCache.instance.get<List<TimeEntryActivity>>('time_entry_activities');
    if (cached != null) return cached;
    try {
      final data = await _base.getJson('/time_entries/activities');
      final elements = _base.elementsFromResponse(data);
      final list = elements.whereType<Map>().map((e) {
        final links = e['_links'] as Map<String, dynamic>?;
        final self = links?['self'] as Map?;
        return TimeEntryActivity(
          id: (e['id'] ?? '').toString(),
          name: (e['name'] ?? self?['title'] ?? '').toString(),
          isDefault: e['default'] == true,
        );
      }).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      ApiReferenceCache.instance.put('time_entry_activities', list);
      return list;
    } catch (e) {
      if (kDebugMode) AppLogger.logError('Zaman girişi aktiviteleri yüklenemedi', error: e);
      return [];
    }
  }

  Future<void> createTimeEntry({
    required String workPackageId,
    required double hours,
    required DateTime spentOn,
    String? comment,
    String? activityId,
  }) async {
    if (hours <= 0) throw Exception('Saat pozitif olmalıdır.');
    final duration = 'PT${hours.toString()}H';
    final links = <String, dynamic>{
      'entity': <String, String>{
        'href': '/api/v3/work_packages/$workPackageId',
      },
    };
    if (activityId != null && activityId.isNotEmpty) {
      links['activity'] = <String, String>{
        'href': '/api/v3/time_entries/activities/$activityId',
      };
    }
    final body = <String, dynamic>{
      'hours': duration,
      'spentOn': spentOn.toIso8601String().split('T').first,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': <String, dynamic>{'raw': comment},
      '_links': links,
    };
    await _base.postJson('/time_entries', body);
  }

  Future<void> updateTimeEntry(
    String timeEntryId, {
    double? hours,
    DateTime? spentOn,
    String? comment,
    String? activityId,
  }) async {
    final body = <String, dynamic>{};
    if (hours != null && hours > 0) {
      body['hours'] = 'PT${hours.toString()}H';
    }
    if (spentOn != null) {
      body['spentOn'] = spentOn.toIso8601String().split('T').first;
    }
    if (comment != null) {
      body['comment'] = <String, dynamic>{'raw': comment};
    }
    if (activityId != null && activityId.isNotEmpty) {
      body['_links'] = <String, dynamic>{
        'activity': <String, String>{'href': '/api/v3/time_entries/activities/$activityId'},
      };
    }
    if (body.isEmpty) return;
    await _base.patchJson('/time_entries/$timeEntryId', body);
  }

  Future<void> deleteTimeEntry(String timeEntryId) async {
    await _base.deleteJson('/time_entries/$timeEntryId');
  }
}
