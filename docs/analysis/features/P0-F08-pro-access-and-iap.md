## Feature: Pro erişimi, satın alma, geri yükleme ve deneme

## Amaç

Pro durumunun belirlenmesi; satın alma akışı; satın almaları geri yükleme; isteğe bağlı deneme süresi; premium özellikte kilitleme ve “Bu özellik Pro’da” + Yükselt / Geri yükle; Pro/Upgrade erişim noktası (profil veya ayarlar).

## Kapsam

- Dahil:
  - Pro durumunun belirlenmesi: satın alma geçerli VEYA deneme süresi aktif.
  - Satın alma akışı (başlat, tamamla); tamamlanınca Pro açılır.
  - Satın almaları geri yükleme; aynı hesapta Pro yeniden sağlanır.
  - İsteğe bağlı deneme: deneme süresi boyunca Pro açık; süre bitince yalnızca satın alma geçerli.
  - Premium özellik girişinde kilitleme: Pro yoksa “Bu özellik Pro’da” + Yükselt + Geri yükle; Pro varsa özellik açılır.
  - Pro/Upgrade’a tek yerden erişim (profil veya ayarlar).
- Hariç:
  - Hangi ekranların premium olduğunun sabit listesi (ayrı kapsamda tanımlanır).

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak uygulama açıldığında veya Pro ekranına girdiğimde mevcut satın almalarımın sorgulanmasını ve Pro ise erişimin açılmasını istiyorum.
- [ ] Kullanıcı olarak “Pro’yu satın al” ile satın alma akışını başlatıp tamamlayabilmek istiyorum; tamamlanınca Pro açılsın.
- [ ] Kullanıcı olarak “Satın almaları geri yükle” ile aynı hesapta Pro erişimini yeniden sağlayabilmek istiyorum.
- [ ] Kullanıcı olarak deneme süresi boyunca Pro özelliklerini kullanabilmek, süre bitince satın alma ile devam edebilmek istiyorum.
- [ ] Kullanıcı olarak Pro değilken premium özelliğe girdiğimde “Bu özellik Pro’da” mesajı ve Yükselt / Geri yükle seçeneklerini görmek istiyorum.
- [ ] Kullanıcı olarak Pro veya Yükselt ekranına profil veya ayarlardan tek yerden erişebilmek istiyorum.

## Kabul kriterleri

- [ ] Uygulama açılışında veya Pro ekranına girildiğinde mevcut satın almalar sorgulanır; Pro varsa erişim açılır.
- [ ] Kullanıcı “Pro’yu satın al” ile satın alma akışını başlatabilir; akış tamamlanınca Pro açılır.
- [ ] Kullanıcı “Satın almaları geri yükle” ile aynı hesapta Pro erişimini yeniden sağlayabilir.
- [ ] Deneme kullanılıyorsa: deneme süresi boyunca Pro özellikleri açıktır; süre bitince yalnızca satın alma ile Pro açık kalır.
- [ ] Pro olmayan kullanıcı premium özelliğe girdiğinde “Bu özellik Pro’da” mesajı ve Yükselt / Geri yükle seçenekleri sunulur.
- [ ] Pro veya Yükselt ekranına profil veya ayarlar gibi tek bir giriş noktasından erişilebilir.
- [ ] Satın alma iptal, mağaza/ağ hatası veya restore başarısız olduğunda kullanıcıya anlamlı mesaj ve tekrar deneme sunulur.

## Kurallar / İş mantığı

- Pro = (satın alma geçerli) VEYA (deneme süresi aktif).
- Deneme süresi ya mağaza abonelik denemesi ya da yerel “ilk kullanımda X gün” ile tanımlanabilir.
- Pro bilgisi yalnızca mağaza ve isteğe bağlı yerel denemeye dayanır; kendi sunucu/API zorunlu değildir.

## Hata durumları

- Satın alma iptal edildiğinde kullanıcıya bilgi verilir; tekrar satın alma deneyebilir.
- Mağaza veya ağ hatası durumunda anlamlı hata mesajı ve tekrar deneme sunulur.
- Restore başarısız olduğunda kullanıcıya mesaj ve tekrar geri yükleme denemesi sunulur.
- Deneme süresi dolduğunda premium özellik kilitli kalır; kullanıcı Yükselt ile satın alma akışına yönlendirilir.
