import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/time_entry.dart';

const _kColumns = 'openproject.time_tracking.columns';
const _kGroupBy = 'openproject.time_tracking.groupBy';
const _kShowTeam = 'openproject.time_tracking.showTeam';
const _kSortOrder = 'openproject.time_tracking.sortOrder';
const _kSortBy = 'openproject.time_tracking.sortBy';
const _kWorkStartHour = 'openproject.time_tracking.workStartHour';
const _kWorkStartMinute = 'openproject.time_tracking.workStartMinute';

/// Varsayılan mesai başlangıç saati (ilk zaman kaydı için önerilen başlangıç).
const int kDefaultWorkStartHour = 9;
const int kDefaultWorkStartMinute = 0;

/// Varsayılan kolon sırası (görünür). İş adı varsayılanda ilk satırda sağda tek satır gösterilir.
const List<String> kDefaultTimeTrackingColumns = [
  'date',
  'hours',
  'work_package',
  'comment',
  'activity',
];

/// Tüm seçilebilir kolonlar (kullanıcı ekleyebilir).
const List<String> kAllTimeTrackingColumns = [
  'date',
  'hours',
  'work_package',
  'comment',
  'activity',
  'user',
];

/// Gruplama seçenekleri.
enum TimeTrackingGroupBy {
  none('none', 'Grupsuz'),
  day('day', 'Gün'),
  week('week', 'Hafta'),
  month('month', 'Ay'),
  workPackage('work_package', 'İş');

  const TimeTrackingGroupBy(this.id, this.label);
  final String id;
  final String label;

  static TimeTrackingGroupBy fromId(String? id) {
    if (id == null || id.isEmpty) return TimeTrackingGroupBy.day;
    for (final e in values) {
      if (e.id == id) return e;
    }
    return TimeTrackingGroupBy.day;
  }
}

/// Zaman kayıtları liste sıralaması: en yeni en üstte / en eski en üstte.
enum TimeTrackingSortOrder {
  newestFirst('desc', 'En yeni üstte'),
  oldestFirst('asc', 'En eski üstte');

  const TimeTrackingSortOrder(this.id, this.label);
  final String id;
  final String label;

  static TimeTrackingSortOrder fromId(String? id) {
    if (id == 'asc') return TimeTrackingSortOrder.oldestFirst;
    return TimeTrackingSortOrder.newestFirst;
  }
}

/// Zaman kayıtları sıralama kriteri: kapsadığı tarih (spentOn) veya oluşturulma tarihi (createdAt).
enum TimeTrackingSortBy {
  spentOn('spent_on', 'Kapsadığı tarih'),
  createdAt('created_at', 'Oluşturulma tarihi');

  const TimeTrackingSortBy(this.id, this.label);
  final String id;
  final String label;

  static TimeTrackingSortBy fromId(String? id) {
    if (id == 'created_at') return TimeTrackingSortBy.createdAt;
    return TimeTrackingSortBy.spentOn;
  }
}

/// Zaman takibi kolon ve gruplama tercihlerini kalıcı saklar.
class TimeTrackingPrefs {
  static Future<List<String>> getColumns() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kColumns);
    if (list == null || list.isEmpty) return List.from(kDefaultTimeTrackingColumns);
    return list;
  }

  static Future<void> setColumns(List<String> columnIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kColumns, columnIds);
  }

  static Future<TimeTrackingGroupBy> getGroupBy() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kGroupBy);
    return TimeTrackingGroupBy.fromId(id);
  }

  static Future<void> setGroupBy(TimeTrackingGroupBy value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGroupBy, value.id);
  }

  static Future<bool> getShowTeam() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTeam) ?? false;
  }

  static Future<void> setShowTeam(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowTeam, value);
  }

  /// Zaman kayıtları sıralaması: en yeni en üstte (varsayılan) veya en eski en üstte.
  static Future<TimeTrackingSortOrder> getSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kSortOrder);
    return TimeTrackingSortOrder.fromId(id);
  }

  static Future<void> setSortOrder(TimeTrackingSortOrder value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSortOrder, value.id);
  }

  /// Sıralama kriteri: kapsadığı tarih (spentOn) veya oluşturulma tarihi (createdAt).
  static Future<TimeTrackingSortBy> getSortBy() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_kSortBy);
    return TimeTrackingSortBy.fromId(id);
  }

  static Future<void> setSortBy(TimeTrackingSortBy value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSortBy, value.id);
  }

  /// Zaman kayıtlarını aynı mantıkla sıralar (zaman takibi sayfası ve iş detayı zaman sekmesi).
  /// Kriter: [sortBy] (spentOn veya createdAt), yön: [order] (en yeni üstte / en eski üstte). Eşitlikte id kullanılır.
  static void sortTimeEntries(
    List<TimeEntry> list,
    TimeTrackingSortOrder order,
    TimeTrackingSortBy sortBy,
  ) {
    int compareDate(DateTime? da, DateTime? db) {
      final a = da ?? DateTime.fromMillisecondsSinceEpoch(0);
      final b = db ?? DateTime.fromMillisecondsSinceEpoch(0);
      return a.compareTo(b);
    }
    list.sort((a, b) {
      final aDate = sortBy == TimeTrackingSortBy.createdAt ? a.createdAt : a.spentOn;
      final bDate = sortBy == TimeTrackingSortBy.createdAt ? b.createdAt : b.spentOn;
      final dateCmp = compareDate(aDate, bDate);
      if (dateCmp != 0) return order == TimeTrackingSortOrder.newestFirst ? -dateCmp : dateCmp;
      final aId = int.tryParse(a.id) ?? 0;
      final bId = int.tryParse(b.id) ?? 0;
      return order == TimeTrackingSortOrder.newestFirst ? bId.compareTo(aId) : aId.compareTo(bId);
    });
  }

  /// Mesai başlangıç saati (o gün ilk kayıt için önerilen başlangıç).
  static Future<TimeOfDay> getWorkStartTimeOfDay() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_kWorkStartHour) ?? kDefaultWorkStartHour;
    final minute = prefs.getInt(_kWorkStartMinute) ?? kDefaultWorkStartMinute;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  static Future<void> setWorkStartTimeOfDay(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWorkStartHour, time.hour);
    await prefs.setInt(_kWorkStartMinute, time.minute);
  }
}
