# ProjectFlow – Google Play yükleme hazırlığı (Ücretsiz / Pro inceleme)

Bu doküman, **ücretsiz + Pro (uygulama içi satın alma)** eklenmiş haliyle uygulamanın Google Play’e yüklenmeye hazır olup olmadığını madde madde özetler.

---

## 1. Ücretsiz / Pro yapısı – inceleme özeti

| Konu | Durum | Not |
|------|--------|-----|
| **ProState** | ☑ | `lib/state/pro_state.dart` – isPro: satın alma geçerli, 7 gün deneme veya (sadece debug) dev override. |
| **ProIapService** | ☑ | `lib/services/pro_iap_service.dart` – in_app_purchase kullanıyor; ürün ID: `projectflow_pro`. |
| **Tek seferlik satın alma** | ☑ | `buyNonConsumable` – Pro tek seferlik (consumable değil). |
| **Deneme süresi** | ☑ | 7 gün trial; ilk açılışta başlar, SharedPreferences’ta saklanır. |
| **Geri yükleme** | ☑ | `restorePurchases()` uygulama açılışında ve Pro ekranında çağrılıyor. |
| **Pro ekranı** | ☑ | `ProUpgradeScreen` – Satın al, Geri yükle; hata/Pro sahip mesajları. |
| **ProGate / FreePlanBanner** | ☑ | Pro gerektiren yerlerde (zaman takibi, kolonlar vb.) kilit + yükselt yönlendirmesi. |
| **Debug override** | ☑ | Sadece debug’ta; release’de etkisiz; geliştirme için Pro açık/kapalı test edilebilir. |

**Sonuç:** Ücretsiz / Pro akışı tutarlı; mağaza tarafında yapmanız gereken tek kritik adım **Play Console’da uygulama içi ürün tanımlamak**.

---

## 2. Play Console – Uygulama içi ürün (zorunlu)

Kodda kullanılan ürün kimliği:

```
projectflow_pro
```

**Yapılacaklar:**

1. Play Console → Uygulamanız → **Monetize** → **Products** → **In-app products**.
2. **Create product** → Ürün kimliği: **`projectflow_pro`** (tam olarak bu; kodda `kProProductId` ile aynı).
3. Ürün türü: **One-time product** (tek seferlik; consumable değil).
4. **Fiyat:** Ürün sayfasında **Pricing** / **Fiyat** alanında fiyat ve para birimini seçin (örn. TRY, USD). **Fiyatı yalnızca burada belirliyorsunuz;** uygulama kodunda fiyat yoktur; satın alma ekranında Google Play fiyatı gösterir.
5. Açıklama girin; kaydedin ve **Activate** edin.
6. Uygulama ilk yayına alınmadan önce bu ürün **aktif** olmalı; aksi halde “Bu cihazda uygulama içi satın alma kullanılamıyor” veya ürün bulunamadı hatası alınabilir.

**Fiyat nerede belirlenir?**  
Google Play Console → Uygulamanız → **Monetize** → **In-app products** → **projectflow_pro** ürününü açın → **Pricing** (Fiyat) bölümünde fiyat ve para birimini girin veya değiştirin. Uygulama bu değeri kodda tutmaz; kullanıcı "Pro'yu satın al" dediğinde Google Play kendi satın alma ekranında fiyatı gösterir.

**Kontrol:** Uygulama yayında iken Pro ekranında “Pro’yu satın al” tıklandığında mağaza penceresi açılıyorsa ve `projectflow_pro` listeleniyorsa tanım doğrudur.

---

## 3. AndroidManifest ve izinler

| Kontrol | Durum |
|--------|--------|
| INTERNET | ☑ |
| POST_NOTIFICATIONS | ☑ |
| SCHEDULE_EXACT_ALARM | ☑ |
| RECEIVE_BOOT_COMPLETED | ☑ |
| BILLING | ☑ Gerek yok (in_app_purchase / Billing Library 5+ kendi ekliyor). |

Ek izin gerekmiyor.

---

## 4. Versiyon ve imzalama

| Kontrol | Değer |
|--------|--------|
| **versionName / versionCode** | `pubspec.yaml` → `1.0.0+1` (1.0.0 / 1). |
| **Release imzalama** | `key.properties` + keystore ile release build; build.gradle.kts uyumlu. |

Yeni geliştirmeler yaptıysanız **AAB’yi yeniden üretin** ve bu AAB’yi yükleyin:

```bash
cd apps/mobile
flutter build appbundle
```

Çıktı: `build/app/outputs/bundle/release/app-release.aab`

---

## 5. Mağaza listesi (Free + Pro için)

Uygulama **ücretsiz**; gelir **uygulama içi satın alma** (Pro) ile. Play Console’da:

- **Fiyatlandırma:** Ücretsiz.
- **Uygulama içi ürünler:** Evet (Pro tek seferlik ürün).
- **Kısa açıklama** örneği (max 80 kr):  
  `OpenProject hesabına bağlan; iş paketleri, bildirimler, zaman kayıtları. Pro ile daha fazlası.`
- **Uzun açıklama:** Mevcut metne “Pro sürümü: gelişmiş zaman takibi, özel kolonlar, Gantt görünümü vb.” gibi bir cümle ekleyebilirsiniz (isteğe bağlı).

---

## 6. Gizlilik politikası

Mevcut gizlilik politikası (instance URL, API anahtarı, tercihler) yeterli. **Ödeme bilgisi** Google tarafından işlendiği için “Ödeme bilgileri Google tarafından işlenir; uygulama kredi kartı vb. saklamaz.” gibi tek cümle eklemeniz iyi olur (isteğe bağlı). Zorunlu değil; Play politikalarına uyum için mevcut metin temel olarak yeterli.

---

## 7. Yükleme öncesi kontrol listesi (Free/Pro)

| # | Madde | Yapıldı mı? |
|---|--------|-------------|
| 1 | AAB **güncel** (son Free/Pro değişiklikleriyle build) | ☐ |
| 2 | Play Console’da **uygulama içi ürün** `projectflow_pro` oluşturuldu ve **aktif** | ☐ |
| 3 | Uygulama **Ücretsiz** olarak ayarlandı; “In-app products” işaretli | ☐ |
| 4 | Gizlilik politikası URL’i girildi | ☐ |
| 5 | Mağaza listesi (kısa/uzun açıklama, ikon, ekran görüntüleri) tamamlandı | ☐ |
| 6 | İçerik derecelendirmesi ve hedef kitle dolduruldu | ☐ |
| 7 | AAB yüklendi (Internal/Closed/Production) | ☐ |
| 8 | İncelemeye gönderildi | ☐ |

---

## 8. Özet – Yüklenmeye hazır mı?

| Bölüm | Hazır mı? | Eksik / yapılacak |
|--------|-----------|--------------------|
| **Kod (Free/Pro)** | ☑ | ProState, IAP, Pro ekranı, ProGate/banner tutarlı. |
| **IAP ürün ID** | ☐ | Play Console’da `projectflow_pro` (tek seferlik) tanımlanmalı ve aktif edilmeli. |
| **AAB** | ☐ | Son değişikliklerle yeniden `flutter build appbundle` alınmalı. |
| **Mağaza / politika** | ☐ | Mevcut yayına hazırlık dokümanındaki adımlar + “Pro” ve uygulama içi ürün bilgisi. |

**Sonuç:** Uygulama **Google Play’e yüklenmeye teknik olarak hazır**; yüklemeyi yapmadan önce **AAB’yi güncel build ile alın** ve **Play Console’da `projectflow_pro` uygulama içi ürününü oluşturup aktif edin**. Diğer tüm adımlar (gizlilik, listeleme, anketler, yükleme) mevcut “yayına hazırlık” dokümanındaki gibi tamamlanmalı.
