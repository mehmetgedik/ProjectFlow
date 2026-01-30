# Pro / IAP – Geliştirme ve Play sürümü

Pro durumu yalnızca **satın alma**, **promo kodu** (Play'de kullanılan kod = aynı IAP) veya **deneme süresi** ile belirlenir.

**Google Play'e yüklenecek sürüm:** Release build'te (`flutter build appbundle --release`) Pro yalnızca gerçek IAP, restore veya yerel deneme ile açılır; test switch'i **derlenmez** (yalnızca debug'da görünür).

**Emülatörde Pro testi:** Debug modda (`flutter run`) Profil → Pro ekranında "Geliştirme (sadece debug)" kartı ve **Pro'yu aç (test – IAP atla)** switch'i görünür. Açınca Pro özellikleri emülatörde de aktif olur; release build'te bu kart yoktur.

---

## Özet

| Ne yapmak istiyorsunuz? | Nasıl? |
|------------------------|--------|
| **IAP / satın alma testi** | Uygulamayı **internal testing** track'ine yükleyin; **license testers** ekleyin. Bu hesaplarla satın alma para çekmeden tamamlanır. |
| **Belirli kişilere ücretsiz Pro** | Play Console'da Pro ürünü için **promo kodu** oluşturup dağıtın. Kod kullanan hesap Pro'ya sahip olur; uygulamada "Satın almaları geri yükle" ile etkinleştirir. |
| **Emülatörde Pro testi** | Debug modda (`flutter run`) Pro ekranında "Pro'yu aç (test – IAP atla)" switch'ini açın; release build'te bu switch görünmez. |
| **Release (Play'e yükleme)** | `flutter build appbundle --release`. Pro yalnızca satın alma / promo / deneme ile açılır; test switch'i release'de yoktur. |

---

## Promo kodu – istediklerinize ücretsiz Pro

- **Siz:** Play Console → Monetize → In-app products → Pro ürünü → Promo codes ile kod oluşturup indirin (CSV). Kodları sadece vermek istediğiniz kişilere iletin.
- **Kullanıcı:** Play Store'da kodu kullanır (Ödeme ve abonelik → Kod kullan). Sonra uygulamada **Pro → Satın almaları geri yükle** ile Pro'yu etkinleştirir.
- **Uygulama:** Ekstra doğrulama yok; Pro durumu yine Google Billing / restore ile alınır. Promo = ücretsiz satın alma.

Detaylı adımlar: [IAP test ve ücretsiz Pro](iap-test-ve-ucretsiz-pro.md) (promo kodları bölümü).

---

## Not

- **"In-app billing API version 3 is not supported on this device"**: Emülatör veya Play Store olmayan cihazda normal; IAP testi için uygulamayı Play Store üzerinden (internal test) indiren gerçek cihaz kullanın.
