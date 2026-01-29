import 'package:shared_preferences/shared_preferences.dart';

const _kShowStatusChart = 'openproject.dashboard.showStatusChart';
const _kShowTypeChart = 'openproject.dashboard.showTypeChart';
const _kShowTimeSeriesChart = 'openproject.dashboard.showTimeSeriesChart';
const _kShowUpcoming = 'openproject.dashboard.showUpcoming';
const _kStatusChartType = 'openproject.dashboard.statusChartType';
const _kTypeChartType = 'openproject.dashboard.typeChartType';
const _kRecentlyOpenedIds = 'openproject.dashboard.recentlyOpenedIds';
const _kRecentlyOpenedMax = 15;

/// Dashboard bileşen ve grafik türü tercihlerini kalıcı saklar.
class DashboardPrefs {
  static Future<bool> getShowStatusChart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowStatusChart) ?? true;
  }

  static Future<void> setShowStatusChart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowStatusChart, value);
  }

  static Future<bool> getShowTypeChart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTypeChart) ?? true;
  }

  static Future<void> setShowTypeChart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowTypeChart, value);
  }

  static Future<bool> getShowTimeSeriesChart() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowTimeSeriesChart) ?? false;
  }

  static Future<void> setShowTimeSeriesChart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowTimeSeriesChart, value);
  }

  static Future<bool> getShowUpcoming() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kShowUpcoming) ?? false;
  }

  static Future<void> setShowUpcoming(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowUpcoming, value);
  }

  static Future<String> getStatusChartType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kStatusChartType) ?? 'bar';
  }

  static Future<void> setStatusChartType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStatusChartType, value);
  }

  static Future<String> getTypeChartType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTypeChartType) ?? 'pie';
  }

  static Future<void> setTypeChartType(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTypeChartType, value);
  }

  /// Son açılan iş paketi id listesi (en son açılan başta).
  static Future<List<String>> getRecentlyOpenedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kRecentlyOpenedIds) ?? const [];
  }

  /// Bir iş paketi açıldığında çağrılır; id listesinin başına eklenir (en fazla [_kRecentlyOpenedMax]).
  static Future<void> addRecentlyOpened(String workPackageId) async {
    if (workPackageId.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_kRecentlyOpenedIds) ?? [];
    final updated = [workPackageId.trim(), ...current.where((id) => id != workPackageId.trim())];
    await prefs.setStringList(_kRecentlyOpenedIds, updated.take(_kRecentlyOpenedMax).toList());
  }
}
