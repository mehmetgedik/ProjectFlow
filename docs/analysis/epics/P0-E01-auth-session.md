## Epic: Authentication & Session

## Amaç

Kullanıcı OpenProject instance’ına mobil uygulamadan giriş yapabilsin ve oturumu güvenli şekilde sürdürülebilsin.

## Kapsam

- Dahil:
  - Kullanıcının kimliğinin doğrulanması
  - Oturumun güvenli saklanması
  - Yetkisiz erişim/oturum hatalarında kullanıcıya anlaşılır geri bildirim
- Hariç:
  - Offline çalışma

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak uygulamaya giriş yapabilmek istiyorum, böylece projelerimi ve işlerimi görebileyim.
- [ ] Kullanıcı olarak oturumumun güvenli saklanmasını istiyorum, böylece tekrar tekrar giriş yapmak zorunda kalmayayım.
- [ ] Kullanıcı olarak girişte verdiğim ayarların (ör. instance adresi ve tercih ettiğim seçenekler) cihazda hatırlanmasını istiyorum, böylece her seferinde tekrar tekrar girmek zorunda kalmayayım.
- [ ] Kullanıcı olarak bu kayıtlı giriş ayarlarını tek bir yerden temizleyebilmek istiyorum, böylece cihazı paylaştığımda veya ortam değiştirdiğimde kontrol bende olsun.

## Kabul kriterleri

- [ ] Giriş yapan kullanıcının kimliği doğrulanır ve kullanıcı bilgisi görüntülenebilir.
- [ ] Oturum bilgisi cihazda güvenli şekilde saklanır.
- [ ] Kullanıcı çıkış yapınca oturum bilgisi temizlenir.
- [ ] Yetkisiz/oturum süresi dolmuş senaryolarında kullanıcı tekrar girişe yönlendirilir.
- [ ] Ağ hatalarında kullanıcıya tekrar deneme sunulur ve hata mesajı anlaşılırdır.

- [ ] Kullanıcı girişte verdiği instance adresi ve ilgili giriş ayarları cihazda güvenli şekilde saklanır ve uygulama yeniden açıldığında bu bilgiler otomatik doldurulur veya kullanılır.
- [ ] Kullanıcı, kayıtlı giriş ayarlarını açık bir aksiyonla (ör. “ayarları temizle” veya “bu cihazdan çıkış yap”) temizleyene kadar bu bilgiler silinmez.
- [ ] Kullanıcı kayıtlı giriş ayarlarını temizlediğinde, bir sonraki girişte instance adresi ve diğer bilgiler otomatik doldurulmaz.

## İş kuralları

- Oturum bilgisi düz metin olarak kalıcı depoya yazılamaz.
- Kullanıcı farklı instance’lara bağlanmayı seçerse mevcut oturum bağımsız yönetilir.

- Girişte verilen instance adresi ve ilgili ayarlar, kullanıcı açıkça temizleyene kadar cihazda güvenli şekilde saklanır.
- Kullanıcı kayıtlı ayarları temizlediğinde, uygulama bu ayarları bir daha otomatik kullanmaz; kullanıcı yeniden giriş bilgisi vermek zorundadır.

## Hata durumları

- Hatalı kimlik bilgisi
- Yetkisiz erişim
- Ağ bağlantısı yok / zaman aşımı

- Kayıtlı giriş ayarlarının bozulması veya geçersiz hale gelmesi (ör. instance artık erişilemez) durumunda kullanıcıya anlamlı bir mesaj gösterilir ve yeniden giriş ayarlarını güncellemesi istenir.

