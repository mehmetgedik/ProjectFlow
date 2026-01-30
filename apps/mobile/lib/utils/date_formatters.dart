/// Ortak tarih/tarih-saat formatlama (DRY).
/// Tüm ekran ve widget'lar bu yardımcıları kullanır.
class DateFormatters {
  DateFormatters._();

  /// Tarih: null ise '-', değilse gg.aa.yyyy (toLocal).
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  /// Tarih + saat: null ise '-', değilse gg.aa.yyyy HH:mm (toLocal).
  static String formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  /// Dashboard grafik key vb. için yyyy-MM-dd (toLocal).
  static String formatDateKey(DateTime d) {
    final dd = d.toLocal();
    return '${dd.year}-${dd.month.toString().padLeft(2, '0')}-${dd.day.toString().padLeft(2, '0')}';
  }
}
