## Feature: Seyrek değişen verilerin önbelleğe alınması (P1)

## Amaç

Profil resmi ve benzeri sık kullanılan ama seyrek değişen verilerin tekrarlı ağ istekleri olmadan sunulması; kullanıcı aynı bilgiyi her ekranda yeniden indirmemeli.

## Kapsam

- Dahil:
  - Profil/avatar görselleri: liste, detay, bildirim ve profil ekranlarında aynı kaynak tekrar indirilmeden gösterilebilmeli.
  - İsteğe bağlı: Diğer “seyrek değişen” görüntülenen veriler (ör. kullanıcı listesi özeti) – ileride aynı mantıkla genişletilebilir.
- Hariç:
  - Offline-first senaryolar; uygulamanın çevrimdışı çalışması zorunluluğu.
  - Tüm uygulama verisinin önbelleğe alınması.

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak profil resmimi ve diğer kullanıcıların avatar’larını liste, detay ve bildirimde gördüğümde, aynı resim sürekli yeniden indirilmeden gösterilsin; böylece veri tasarrufu olsun ve ekranlar daha hızlı dolsun.
- [ ] Kullanıcı olarak çıkış yaptığımda önbelleğin hesaba özel verileri tutmaması gerekir; böylece başka hesapla giriş yaptığımda eski hesaba ait görseller kullanılmasın.

## Kabul kriterleri

- [ ] Aynı avatar/profil resmi kaynağı tekrar kullanıldığında belirli bir süre boyunca yeniden ağ isteği atılmadan gösterilebilmeli.
- [ ] Çıkış (ve varsa hesap değiştirme) yapıldığında ilgili önbellek temizlenmeli; bir sonraki girişte eski hesaba ait avatar/profil verisi kullanılmamalı.
- [ ] İsteğe bağlı: Belirli bir süre sonra (örn. günlük) veri yenilenebilmeli; ürün kararı ile süre belirlenir.
- [ ] Önbellekte olmayan veya hata veren kaynaklar için mevcut fallback (harf avatarı vb.) sunulmaya devam etmeli.

## Kurallar / İş mantığı

- Çıkış anında önbellek invalidation zorunludur.
- Yenileme süresi (belirli aralıklarla önbelleği tazeleme) varsa ürün kararı ile belirlenir.
- Tekrarlı hata veren kaynaklar gereksiz yere sürekli denenmemeli; giriş veya profil yenileme sonrası tekrar denenebilir.

## Hata durumları

- Ağ hatası, zaman aşımı veya sunucu hata yanıtı (4xx/5xx) durumunda kullanıcıya fallback (mevcut harf avatarı vb.) sunulmalı; tekrar deneme politikası sınırlı olmalı.
- Yetkisiz/erişim reddi (401/403) durumunda fallback gösterilmeli; çıkış/giriş veya oturum yenileme sonrası aynı kaynak tekrar denenebilmeli.
- Önbellek süresi dolmuş veya veri yoksa normal şekilde ağ isteği yapılır; hata durumunda yine fallback sunulur.

## Notlar

- Bu dokümanda teknik çözüm (kütüphane, sınıf, mimari) anlatılmaz; sadece “ne” istenildiği tanımlanır.
