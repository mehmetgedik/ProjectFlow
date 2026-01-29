import 'package:shared_preferences/shared_preferences.dart';

const _kColumns = 'openproject.time_tracking.columns';
const _kGroupBy = 'openproject.time_tracking.groupBy';
const _kShowTeam = 'openproject.time_tracking.showTeam';

/// Varsayılan kolon sırası (görünür).
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
}
