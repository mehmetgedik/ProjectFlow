## Epic: Pro erişimi ve uygulama içi satın alma

## Amaç

Kullanıcılar Pro’yu satın alabilsin, satın almaları geri yükleyebilsin ve isteğe bağlı deneme süresiyle Pro’yu deneyebilsin. Pro olmayan kullanıcı premium özellikte “Pro’da” mesajı ve Yükselt / Geri yükle seçeneklerini görsün. Tek uygulama; Pro, uygulama içi satın alınan bir ürün olarak sunulsun.

## Kapsam

- Dahil:
  - Tek mağaza listesi; Pro ayrı bir uygulama değil, uygulama içi satın alınan ürün.
  - Satın alma akışı ve satın almaları geri yükleme.
  - İsteğe bağlı belirli süre deneme (trial).
  - Premium özellik girişinde kilitleme ve “Bu özellik Pro’da” + Yükselt / Geri yükle sunulması.
- Hariç:
  - İki ayrı uygulama (ücretsiz / Pro).
  - Kendi sunucu veya API ile lisans doğrulama.
  - Teknik mimari veya kütüphane detayı.

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak Pro’yu uygulama içinden satın almak istiyorum, böylece premium özelliklere erişeyim.
- [ ] Kullanıcı olarak satın almalarımı geri yükleyebilmek istiyorum, böylece yeni cihazda veya uygulama yeniden yüklendiğinde Pro’ya tekrar erişeyim.
- [ ] Kullanıcı olarak belirli süre deneme ile Pro’yu denemek istiyorum, böylece satın almadan önce özellikleri görebileyim.
- [ ] Kullanıcı olarak Pro değilken premium özelliğe girdiğimde “Bu özellik Pro’da” mesajı ve Yükselt / Geri yükle seçeneklerini görmek istiyorum.

## Kabul kriterleri

- [ ] Uygulama yalnızca tek mağaza listesi ile yayınlanır; Pro ayrı uygulama değildir.
- [ ] Pro durumu satın alma (ve isteğe bağlı deneme süresi) ile belirlenir; kendi sunucu/API zorunlu değildir.
- [ ] Satın alma tamamlandığında ilgili premium özellikler açılır.
- [ ] “Satın almaları geri yükle” ile aynı hesapta Pro erişimi yeniden sağlanır.
- [ ] Deneme kullanılıyorsa: deneme süresi boyunca Pro özellikleri açıktır; süre bitince yalnızca satın alma ile Pro açık kalır.
- [ ] Pro olmayan kullanıcı premium özelliğe girdiğinde “Pro’da” mesajı ve Yükselt / Geri yükle seçenekleri sunulur.

## İş kuralları

- Pro bilgisi yalnızca mağaza (Google Play) ve isteğe bağlı yerel deneme süresine dayanır.
- Satın alma ve geri yükleme mağaza üzerinden yönetilir; sunucu zorunlu değildir.

## Hata durumları

- Satın alma iptal edildiğinde kullanıcıya bilgi verilir.
- Mağaza veya ağ hatası durumunda anlamlı mesaj ve tekrar deneme sunulur.
- Restore başarısız olduğunda kullanıcıya mesaj ve tekrar deneme sunulur.
- Deneme süresi dolduğunda yalnızca satın alma ile Pro açık kalır; kullanıcı Yükselt ile satın alma akışına yönlendirilir.

## Alt özellikler

- [ ] [P0-F08 Pro erişimi, satın alma, geri yükleme ve deneme](../features/P0-F08-pro-access-and-iap.md)
