# ProjectFlow – İlk uygulama yayınına hazırlık kontrolü

Bu liste, Google Play’e **ilk kez** uygulama eklerken tamamlamanız gereken adımları özetler. Her maddeyi işaretleyerek ilerleyin.

---

## 1. Git / repo

| Durum | Madde |
|-------|--------|
| ☑ | Son değişiklikler commit edildi (`git status` temiz). |
| ☑ | Hassas dosyalar repoda yok: `key.properties`, `keystores/`, `local.properties` (.gitignore’da). |

**Not:** Working tree şu an temiz; yeni değişiklik yoksa ek commit gerekmez.

---

## 2. Uygulama yapılandırması

| Durum | Madde |
|-------|--------|
| ☑ | **Versiyon:** `pubspec.yaml` → `1.0.0+1` (versionName 1.0.0, versionCode 1). |
| ☑ | **Paket adı:** `com.openproject.openproject_mobile` (build.gradle.kts). |
| ☑ | **Uygulama adı (cihazda):** ProjectFlow (AndroidManifest). |
| ☑ | **Release imzalama:** `key.properties` ve keystore mevcut; build.gradle release signing ayarlı. |
| ☑ | **İzinler:** INTERNET, POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED (AndroidManifest). |

---

## 3. AAB (App Bundle) üretimi

| Durum | Madde |
|-------|--------|
| ☑ | **AAB oluşturuldu:** `flutter build appbundle` hatasız tamamlandı. |
| ☑ | **Dosya yolu:** `apps/mobile/build/app/outputs/bundle/release/app-release.aab` mevcut. |

**Komut (uygulama klasöründe):**
```bash
cd d:\MG\Project\Mobile\OpenProject\apps\mobile
flutter build appbundle
```
(Flutter PATH’te değilse tam yol: `C:\src\flutter\bin\flutter.bat`)

---

## 4. Gizlilik politikası

| Durum | Madde |
|-------|--------|
| ☑ | **Metin/HTML hazır:** `docs/setup/gizlilik-politikasi.md` ve `gizlilik-politikasi.html` mevcut. |
| ☑ | **E-posta dolduruldu:** HTML ve MD içinde iletişim e-postası dolduruldu (kendi adresinizse tamam). |
| ☐ | **Yayınlandı:** `gizlilik-politikasi.html` bir web sunucusunda veya GitHub Pages’te yayında. |
| ☐ | **URL alındı:** Play Console’da “Gizlilik politikası” alanına yapıştıracağınız URL hazır (örn. `https://mehmetgedik.github.io/ProjectFlow/gizlilik-politikasi.html`). |

**Madde 4 – Şimdi yapılacaklar:**  
1. `gizlilik-politikasi.html` dosyasını GitHub Pages veya kendi sitenize yükleyin.  
2. Sayfanın tam URL’ini alın (örn. `https://mehmetgedik.github.io/ProjectFlow/gizlilik-politikasi.html`).  
3. Bu URL’i bir yere not edin; Madde 7’de Play Console’a gireceksiniz.

---

## 5. Play Console – Uygulama oluşturma

| Durum | Madde |
|-------|--------|
| ☐ | **Uygulama oluştur:** Play Console → “Uygulama oluştur” → ad (ProjectFlow), dil, uygulama/ücretsiz. |
| ☐ | **Form bilgileri:** `docs/setup/play-console-uygulama-formu.md` içindeki değerler kopyala-yapıştır ile dolduruldu. |

---

## 5b. Uygulama içi satın alma (Pro)

| Durum | Madde |
|-------|--------|
| ☐ | **Play Console’da ürün:** Monetize → In-app products → `projectflow_pro` (tek seferlik) oluşturuldu ve **Aktif**. |
| ☐ | **Fiyatlandırma:** Uygulama “Ücretsiz”; gelir Pro (uygulama içi) ile. |

| ☑ | **Test ekleri kaldırıldı:** Pro ekranında dev override yok; Play sürümünde yalnızca IAP/restore/deneme kullanılır. |
| ☑ | **Promo kod:** İstediklerinize ücretsiz Pro vermek için Play Console'da promo kodu oluşturup dağıtın; kullanıcı kodu Play Store'da kullanır, uygulamada "Satın almaları geri yükle" ile Pro etkinleşir. Detay: `docs/setup/iap-test-ve-ucretsiz-pro.md`. |

**Detay:** `docs/setup/google-play-free-pro-inceleme.md`

---

## 6. Mağaza listesi (Store listing)

| Durum | Madde |
|-------|--------|
| ☐ | **Kısa açıklama** (max 80 kr): “OpenProject hesabına bağlan; iş paketleri, bildirimler ve zaman kayıtları.” |
| ☐ | **Uzun açıklama** (max 4000 kr): `play-console-uygulama-formu.md` içindeki Türkçe metin. |
| ☐ | **Uygulama ikonu:** 512×512 px PNG; kaynak: `apps/mobile/assets/icon/app_icon.png` (gerekirse 512x512’ye kırpın). |
| ☐ | **Ekran görüntüleri:** En az 2 adet (telefon; 16:9 veya 9:16). |
| ☐ | **Feature graphic:** 1024×500 px (isteğe bağlı). |

---

## 7. Play Console – Politika ve anketler

| Durum | Madde |
|-------|--------|
| ☐ | **Gizlilik politikası URL’i** Store listesine / politika alanına girildi. |
| ☐ | **İçerik derecelendirmesi** anketi dolduruldu. |
| ☐ | **Hedef kitle / reklam:** Hedef yaş ve “Reklam yok” (uygunsa) işaretlendi. |
| ☐ | **Uygulama erişimi:** “Giriş gerekli (OpenProject API anahtarı)” açıklaması eklendi; gerekirse test hesabı bilgisi. |

---

## 8. Yükleme

| Durum | Madde |
|-------|--------|
| ☐ | **AAB yüklendi:** Production veya Internal/Closed testing → “App bundle’ları yükle” → `app-release.aab` seçildi. |
| ☐ | **İnceleme gönderildi:** Tüm zorunlu bölümler tamamlandıktan sonra incelemeye gönderildi. |

---

## 9. Çalışma log’ları ve Google Play

`flutter run` veya release build çalışırken aşağıdaki log satırları görülebilir. **Hiçbiri Google Play yüklemesine veya incelemeye engel değildir.**

| Log mesajı | Açıklama | Play’e engel? |
|------------|----------|----------------|
| **FlutterJNI.loadLibrary / init called more than once** | Flutter engine veya eklentiler (Workmanager, bildirimler, IAP) ilk açılışta native tarafı birden tetikliyor. Bilinen davranış. | Hayır |
| **Skipped N frames – too much work on its main thread** | İlk açılışta ana thread yoğun; özellikle emülatörde görülür. Platform init 150 ms ertelenerek hafifletildi. | Hayır |
| **Davey! duration=…ms** | Bir frame uzun sürdü (ilk çizim veya ağır iş). Emülatör/ilk açılışta normal; gerçek cihazda genelde daha iyi. | Hayır |
| **In-app billing API version 3 is not supported on this device** | Emülatörde IAP tam desteklenmez. Pro satın alma testi için **gerçek cihaz** kullanın. | Hayır |
| **userfaultfd: MOVE ioctl seems unsupported** | Emülatör/çekirdek ile ilgili; gerçek cihazda görünmez. | Hayır |
| **BOOT_COMPLETED / RescheduleReceiver** | Workmanager veya benzeri bileşenin boot sonrası planlaması; beklenen davranış. | Hayır |

**Özet:** Bu uyarılar yayına veya incelemeye **engel teşkil etmez**. IAP testi için gerçek Android cihaz kullanın.

---

## Özet – Şu anki durum

| Bölüm | Hazır mı? | Not |
|--------|-----------|-----|
| Git / repo | ☑ | Working tree temiz; hassas dosyalar .gitignore’da. |
| Uygulama yapılandırması | ☑ | Versiyon, paket adı, imzalama, izinler uygun. |
| AAB | ☐ | `flutter build appbundle` çalıştırılıp AAB üretilmeli. |
| Gizlilik politikası | Kısmen | Metin/HTML var; e-posta doldurulup sayfa yayınlanmalı, URL alınmalı. |
| Play Console formu | Hazır | `play-console-uygulama-formu.md` kopyala-yapıştır için hazır. |
| Mağaza grafikleri | ☐ | 512×512 ikon ve en az 2 ekran görüntüsü hazırlanmalı. |
| Yükleme | ☐ | AAB ve listeleme tamamlandıktan sonra. |

**İlk yayın için sıra (Free/Pro):** AAB üret (son değişikliklerle) → Play Console’da uygulama içi ürün `projectflow_pro` oluştur ve aktif et → Gizlilik sayfasını yayınla (URL al) → Play Console’da uygulama oluştur → Mağaza listesi + grafikler + politika URL’i → İçerik derecelendirmesi / hedef kitle → AAB yükle → İncelemeye gönder.  
**Ücretsiz/Pro detay:** `docs/setup/google-play-free-pro-inceleme.md`
