## Feature: Instance’a bağlanma ve giriş

## Amaç

Kullanıcı OpenProject instance’ına mobil uygulamayı bağlayıp kimliğini doğrulayabilsin.

## Kapsam

- Dahil:
  - Instance adresiyle bağlantı kurulması
  - Kullanıcının kimliğinin doğrulanması
  - Başarılı giriş sonrası uygulamaya erişim
- Hariç:
  - Offline kullanım

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak instance adresimi girip giriş yapabilmek istiyorum, böylece kendi OpenProject ortamımı kullanabileyim.
- [ ] Kullanıcı olarak girişte verdiğim ayarların (ör. instance adresi ve tercih ettiğim seçenekler) cihazda hatırlanmasını istiyorum, böylece her seferinde tekrar tekrar girmek zorunda kalmayayım.
- [ ] Kullanıcı olarak bu kayıtlı giriş ayarlarını tek bir yerden temizleyebilmek istiyorum, böylece cihazı paylaştığımda veya ortam değiştirdiğimde kontrol bende olsun.

## Kabul kriterleri

- [ ] Kullanıcı instance adresini girerek bağlantı başlatabilir.
- [ ] Giriş başarılı olduğunda kullanıcı bilgisi görüntülenebilir (ör. ad/username).
- [ ] Hatalı girişte kullanıcıya anlaşılır hata mesajı gösterilir.
- [ ] Ağ yoksa/zaman aşımı olursa kullanıcıya tekrar deneme sunulur.
- [ ] Kullanıcı çıkış yapınca uygulama yetkili alanlara erişim vermemelidir.

- [ ] Kullanıcı girişte verdiği instance adresi ve ilgili giriş ayarları cihazda güvenli şekilde saklanır ve uygulama yeniden açıldığında bu bilgiler otomatik doldurulur veya kullanılır.
- [ ] Kullanıcı, kayıtlı giriş ayarlarını açık bir aksiyonla (ör. “ayarları temizle” veya “bu cihazdan çıkış yap”) temizleyene kadar bu bilgiler silinmez.
- [ ] Kullanıcı kayıtlı giriş ayarlarını temizlediğinde, bir sonraki girişte instance adresi ve diğer bilgiler otomatik doldurulmaz.

## İş kuralları

- Kimlik doğrulama bilgileri güvenli depolanır.

- Girişte verilen instance adresi ve ilgili ayarlar, kullanıcı açıkça temizleyene kadar cihazda güvenli şekilde saklanır.
- Kullanıcı kayıtlı ayarları temizlediğinde, uygulama bu ayarları bir daha otomatik kullanmaz; kullanıcı yeniden giriş bilgisi vermek zorundadır.

## Hata durumları

- Yanlış instance adresi
- Yetkisiz erişim
- Ağ hatası / zaman aşımı

- Kayıtlı giriş ayarlarının bozulması veya geçersiz hale gelmesi (ör. instance artık erişilemez) durumunda kullanıcıya anlamlı bir mesaj gösterilir ve yeniden giriş ayarlarını güncellemesi istenir.

