/// Kullanıcıya gösterilecek Türkçe hata mesajları.
/// API/exception metnini kullanıcı dostu metne çevirir.
class ErrorMessages {
  ErrorMessages._();

  /// [error] veya [message]'dan kullanıcı dostu Türkçe metin üretir.
  static String userFriendly(dynamic error, {String? message}) {
    final raw = message ?? error?.toString() ?? '';
    final lower = raw.toLowerCase();

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Sunucu yanıt vermedi. Bağlantıyı kontrol edip tekrar deneyin.';
    }
    if (lower.contains('401') || lower.contains('yetkisiz') || lower.contains('unauthorized')) {
      return 'Oturum geçersiz. Lütfen tekrar giriş yapın.';
    }
    if (lower.contains('403') || lower.contains('forbidden') || lower.contains('yetki')) {
      return 'Bu işlem için yetkiniz yok.';
    }
    if (lower.contains('404') || lower.contains('not found') || lower.contains('bulunamadı')) {
      return 'İstenen kayıt bulunamadı.';
    }
    if (lower.contains('406')) {
      return 'Sunucu bu işlemi kabul etmiyor. Lütfen OpenProject sürümünüzü kontrol edin.';
    }
    if (lower.contains('422') || lower.contains('unprocessable')) {
      return 'Gönderilen veri geçersiz. Lütfen bilgileri kontrol edin.';
    }
    if (lower.contains('500') || lower.contains('502') || lower.contains('503')) {
      return 'Sunucu geçici olarak yanıt veremiyor. Lütfen daha sonra tekrar deneyin.';
    }
    if (lower.contains('socket') || lower.contains('connection') || lower.contains('bağlantı') || lower.contains('network')) {
      return 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
    }
    if (lower.contains('bildirim') && (lower.contains('404') || lower.contains('kullanılamıyor'))) {
      return 'Bildirim özelliği bu OpenProject kurulumunda kapalı olabilir.';
    }
    if (lower.contains('bildirim') && lower.contains('okundu')) {
      return 'Bildirim şu anda okundu olarak işaretlenemedi. Lütfen daha sonra tekrar deneyin.';
    }
    if (lower.contains('filtre') && lower.contains('geçersiz')) {
      return 'Bildirim listesi filtresi sunucu tarafından kabul edilmedi. Tüm bildirimler gösteriliyor.';
    }
    if (lower.contains('time_entries') || lower.contains('zaman') && (lower.contains('403') || lower.contains('yetki'))) {
      return 'Zaman kaydı görüntüleme veya ekleme yetkiniz yok.';
    }
    if (lower.contains('zaman') && lower.contains('yüklenirken')) {
      return 'Zaman kayıtları yüklenemedi. Yetkinizi veya bağlantıyı kontrol edin.';
    }
    if (raw.length > 120) {
      return 'Bir hata oluştu. Lütfen tekrar deneyin veya bağlantınızı kontrol edin.';
    }
    if (raw.trim().isEmpty) return 'Beklenmeyen bir hata oluştu.';
    return raw;
  }
}
