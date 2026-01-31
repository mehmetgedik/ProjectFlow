import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Ortak tarih/tarih-saat formatlama (DRY).
/// Tüm ekran ve widget'lar bu yardımcıları kullanır.
class DateFormatters {
  DateFormatters._();

  /// Bildirim/aktivite saatlerini göstermek için kullanılacak saat dilimi (örn. Europe/Istanbul).
  /// Profil → Hesap tercihlerinden yüklenir; set edilirse UTC değerler bu dilime çevrilir.
  static String? preferredTimeZoneId;

  /// API'den gelen ISO 8601 tarih/datetime string'ini parse eder.
  /// Sadece datetime (içinde T var) ve timezone yoksa UTC kabul eder (Z eklenir).
  /// Sadece tarih (yyyy-MM-dd) yerel olarak parse edilir; böylece startDate/dueDate/spentOn doğru kalır.
  static DateTime? parseApiDateTime(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final raw = s.trim();
    try {
      final hasTz = raw.endsWith('Z') || _hasTimezoneOffset(raw);
      final isDateTimeWithTime = raw.contains('T');
      if (hasTz) return DateTime.parse(raw);
      if (isDateTimeWithTime) return DateTime.parse('${raw}Z');
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static bool _hasTimezoneOffset(String s) {
    return RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s) || RegExp(r'[+-]\d{4}$').hasMatch(s);
  }

  /// Tarih: null ise '-', değilse gg.aa.yyyy (profil/cihaz saat diliminde).
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    final d = _toLocalDateParts(date);
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static ({int year, int month, int day}) _toLocalDateParts(DateTime date) {
    if (date.isUtc) {
      try {
        tz_data.initializeTimeZones();
        tz.Location location = tz.local;
        if (preferredTimeZoneId != null && preferredTimeZoneId!.trim().isNotEmpty) {
          location = tz.getLocation(preferredTimeZoneId!.trim());
        }
        final tzDt = tz.TZDateTime.from(date, location);
        return (year: tzDt.year, month: tzDt.month, day: tzDt.day);
      } catch (_) {
        final d = date.toLocal();
        return (year: d.year, month: d.month, day: d.day);
      }
    }
    final d = date.toLocal();
    return (year: d.year, month: d.month, day: d.day);
  }

  /// Tarih + saat: null ise '-', değilse gg.aa.yyyy HH:mm.
  /// UTC için önce [preferredTimeZoneId] (profil saat dilimi), yoksa cihaz saat dilimi kullanılır.
  static String formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    int year, month, day, hour, minute;
    if (dt.isUtc) {
      try {
        tz_data.initializeTimeZones();
        tz.Location location = tz.local;
        if (preferredTimeZoneId != null && preferredTimeZoneId!.trim().isNotEmpty) {
          location = tz.getLocation(preferredTimeZoneId!.trim());
        }
        final tzDt = tz.TZDateTime.from(dt, location);
        year = tzDt.year;
        month = tzDt.month;
        day = tzDt.day;
        hour = tzDt.hour;
        minute = tzDt.minute;
      } catch (_) {
        final d = dt.toLocal();
        year = d.year;
        month = d.month;
        day = d.day;
        hour = d.hour;
        minute = d.minute;
      }
    } else {
      final d = dt.toLocal();
      year = d.year;
      month = d.month;
      day = d.day;
      hour = d.hour;
      minute = d.minute;
    }
    final date = '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';
    final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  /// Dashboard grafik key vb. için yyyy-MM-dd (profil/cihaz saat diliminde).
  static String formatDateKey(DateTime d) {
    final p = _toLocalDateParts(d);
    return '${p.year}-${p.month.toString().padLeft(2, '0')}-${p.day.toString().padLeft(2, '0')}';
  }
}
