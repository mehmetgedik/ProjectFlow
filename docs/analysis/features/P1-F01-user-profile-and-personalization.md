## Feature: Kullanıcı profili & kişiselleştirme (P1)

## Amaç

Kullanıcı kendi profil bilgilerini ve temel tercihlerini mobil uygulama içinden görebilsin, gerektiğinde güncelleyebilsin ve uygulama görünümü/bildirim davranışını kişiselleştirebilsin.

## Kapsam

- Dahil:
  - Profil/hesap görünümü (ad, kullanıcı adı, e‑posta – API’nin izin verdiği ölçüde)
  - Profil avatarı:
    - Eğer OpenProject’te profil resmi/gravatare benzer bir kaynak varsa onu gösterme,
    - Yoksa kullanıcının adından türetilen baş harf avatarı (renkli daire içinde).
  - Yetkiye bağlı alan güncellemeleri:
    - Kullanıcının kendi bilgilerini (ör. ad, açıklama vb.) OpenProject API ve yetkiler izin veriyorsa güncelleyebilmesi.
  - Uygulama içi görünüm/deneyim tercihleri:
    - Bildirim kısayolları (ör. her ekrandan görülebilen bildirim ikonu/badge),
    - Sık kullanılan aksiyonlar için yüzer butonlar (FAB) veya context aksiyon butonları.
  - Ses ile giriş / sesli etkileşim:
    - En azından giriş ekranında (instance URL / API key alanları) cihazın sunduğu sesle yazma özelliğine hızlı erişim (örn. text field yanında mikrofon ikonu ile sistem ses klavyesini açma),
    - İleride belirli komutlar (örn. “Benim işlerim sayfasını aç”) için sesli kısayollar (API ve platform olanaklarına bağlı olarak).
- Hariç:
  - Push bildirim ayarlarının her detayı (örn. bildirim kanalı bazlı ayrıntılı ayarlar),
  - Gelişmiş görünüm temaları (dark mode gibi) – ayrı bir feature konusu olabilir.

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak kendi profil bilgilerimi (ad, kullanıcı adı vb.) mobil uygulamada görmek istiyorum, böylece hangi hesapla giriş yaptığımı net görebileyim.
- [ ] Kullanıcı olarak ismimin yanında bir avatar/profil resmi görmek istiyorum, böylece arayüz daha tanıdık ve kişisel hissettirsin.
- [ ] Kullanıcı olarak yetkim varsa kendi profil bilgilerimi mobil uygulamadan güncelleyebilmek istiyorum, böylece küçük değişiklikler için web’e gitmek zorunda kalmayayım.
- [ ] Kullanıcı olarak her ekrandan bildirimlere hızlı erişim sağlayan bir ikon veya kısayol görmek istiyorum, böylece önemli güncellemeleri kaçırmayayım.
- [ ] Kullanıcı olarak sık yaptığım eylemler için (örn. yeni zaman kaydı ekleme, yeni iş oluşturma – desteklendiği ölçüde) ekranda yüzer bir aksiyon butonu ile hızlı erişim istiyorum.
- [ ] Kullanıcı olarak giriş ekranında metin alanlarına sesle yazma (mikrofon) desteğine kolayca erişebilmek istiyorum, böylece mobilde uzun URL veya anahtarları daha rahat girebileyim.

## Kabul kriterleri

- [ ] Profil/hesap ekranı veya alanı, en azından şu bilgileri gösterir:
  - Kullanıcının görünen adı (veya login),
  - Kullanıcının OpenProject içindeki kullanıcı adı / login bilgisi (uygulanabildiği ölçüde),
  - Giriş yapılan instance bilgisi (örn. domain).
- [ ] Kullanıcının adının yanında bir avatar gösterilir:
  - Eğer API’den profil resmi/benzeri görsel alınabiliyorsa bu görsel kullanılır,
  - Aksi halde kullanıcının adının baş harflerinden oluşan renkli bir daire avatarı gösterilir.
- [ ] Kullanıcı yetkisi yoksa, profil bilgileri salt okunur olarak gösterilir; düzenleme aksiyonları pasif veya gizli olur ve kullanıcıya yetki olmadığı açık bir mesajla belirtilir.
- [ ] Kullanıcı yetkisi varsa ve API ilgili alan(lar) için güncellemeye izin veriyorsa:
  - Kullanıcı ilgili alanı düzenleyebilir,
  - Başarılı güncelleme sonrası yeni değer hem ekranda hem de bir sonraki oturumda tutarlı biçimde görünür.
- [ ] Uygulamanın ana akışlarında (ör. proje listesi, Benim işlerim, iş detayı) bildirimlere götüren belirgin bir ikon veya kısayol bulunur:
  - Bu ikon, okunmamış bildirim varsa görsel olarak vurgulanabilir (örn. badge veya renk),
  - İkona tıklanınca Bildirimler ekranına geçilir.
- [ ] En az bir ekranda (ör. Benim işlerim veya iş detayı) sık kullanılan aksiyonlar için yüzer aksiyon butonu (FAB) veya benzeri bir kısa yol sunulur:
  - FAB, ekranın ana amacını bozmayacak şekilde konumlandırılır,
  - FAB aksiyonu açık ve anlaşılır bir ikon/metinle ifade edilir.
- [ ] Giriş ekranında (instance URL / API key alanları) cihazın sunduğu sesle yazma özelliğine hızlıca erişilebilen bir mikrofon ikonu veya benzeri kısa yol bulunur:
  - Sesle yazma desteği, platform tarafından desteklenmiyorsa kullanıcıya bu konuda anlaşılır bir mesaj gösterilir veya ikon pasif olur.

## Notlar / İş kuralları

- Profil düzenleme kısmı, OpenProject API’nin kullanıcı güncelleme izinleri ve endpoint’leri ile sınırlıdır; desteklenmeyen alanlar için sadece görüntüleme yapılır.
- Ses ile giriş için, mümkün olduğunca cihazın yerleşik sesle yazma özelliği kullanılmalı; özel bir STT altyapısı gerektiren kapsamlar ayrı bir feature olarak ele alınmalıdır.
- Yüzer butonlar ve ikonlar, mobil UX açısından kullanıcıyı rahatsız etmeyecek ve ana içeriği kapatmayacak şekilde tasarlanmalıdır.

