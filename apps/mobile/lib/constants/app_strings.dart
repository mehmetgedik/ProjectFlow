/// Ortak UI metin sabitleri (erişilebilirlik ve tutarlılık için).
abstract final class AppStrings {
  AppStrings._();

  /// Loading göstergesi için Semantics etiketi.
  static const String labelLoading = 'Yükleniyor';

  /// Authenticated gate: projeler yüklenirken.
  static const String labelLoadingProjects = 'Projeler yükleniyor';

  /// Hata sonrası yeniden deneme butonu metni.
  static const String labelRetry = 'Tekrar dene';

  /// İş detay sekme etiketleri.
  static const String tabDetail = 'Detay';
  static const String tabActivity = 'Aktivite';
  static const String tabTime = 'Zaman';

  /// Ortak butonlar.
  static const String buttonBack = 'Geri dön';

  /// Yaygın hata / snack mesajları.
  static const String errorNoActiveProject = 'Aktif proje yok. Önce bir proje seçin.';
  static const String errorWorkListLoadFailed = 'İş listesi yüklenemedi.';
  static const String errorNoOpenWorkInProject = 'Bu projede açık iş yok. Önce iş oluşturun.';
  static const String errorStatusesLoadFailed = 'Durumlar yüklenemedi. Yetkinizi kontrol edin.';
  static const String errorMembersLoadFailed = 'Üyeler yüklenemedi. Yetkinizi kontrol edin.';
  static const String errorTypesLoadFailed = 'İş tipleri yüklenemedi. Yetkinizi kontrol edin.';
  static const String errorSelectProjectFirst = 'Önce proje seçin.';
  static const String errorWorkNotFound = 'İş bulunamadı veya silinmiş.';
  static const String errorProfileLoadFailed = 'Profil bilgisi yüklenemedi.';

  /// Bağlantı ekranları: buton loading metni.
  static const String labelConnecting = 'Bağlanıyor';
  static const String labelConnectingShort = 'Bağlanıyor…';

  /// Bildirimler ve iş listesi.
  static const String labelNotifications = 'Bildirimler';
  static const String labelOpenNotifications = 'Bildirimleri aç';
  static const String labelNewWorkPackage = 'Yeni iş paketi oluştur';
  static const String labelRefreshList = 'Listeyi yenile';

  /// Splash / logo.
  static const String labelProjectFlowLogo = 'ProjectFlow logosu';

  /// Zaman aşımı hatası (iş listesi vb.).
  static const String errorTimeoutDefault =
      'Sunucu yanıt vermedi (zaman aşımı). Bağlantıyı kontrol edip tekrar deneyin veya varsayılan görünüme dönün.';

  /// Pro / yükselt ekranı.
  static const String proFeatureMessage = 'Bu özellik Pro sürümünde.';
  static const String proUpgradeButton = 'Pro\'ya yükselt';
  static const String proRestorePurchases = 'Satın almaları geri yükle';
  static const String proPurchaseLabel = 'Pro\'yu satın al';
}
