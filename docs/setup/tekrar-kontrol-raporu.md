# ProjectFlow – Tekrar kontrol raporu (Google Play)

**Tarih:** Bu rapor proje klasöründe çalıştırılan kontrollere göre oluşturuldu. Her madde tek tek doğrulanmıştır.

---

## 1. Git / repo

| # | Kontrol | Sonuç | Not |
|---|---------|--------|-----|
| 1.1 | Hassas dosya repoda izleniyor mu? | ☑ OK | `git ls-files` ile key.properties, local.properties, .jks, .keystore, .env arandı; **hiçbiri** listede yok (sadece key.properties.example kabul edilir). |
| 1.2 | .gitignore hassas kalıpları kapsıyor mu? | ☑ OK | key.properties, keystores/, local.properties, *.jks, *.keystore, .env, credentials.json, *.pem tanımlı. |
| 1.3 | Working tree | ⚠ Dikkat | Commit edilmemiş değişiklikler var (modified + untracked). Yayından önce isterseniz commit/push yapın. |

---

## 2. Uygulama yapılandırması

| # | Kontrol | Sonuç | Değer / Not |
|---|---------|--------|--------------|
| 2.1 | Versiyon (versionName + versionCode) | ☑ OK | `pubspec.yaml` → **1.0.0+1** (1.0.0 / 1). |
| 2.2 | applicationId | ☑ OK | **com.openproject.openproject_mobile** (build.gradle.kts). |
| 2.3 | Uygulama adı (cihazda) | ☑ OK | **ProjectFlow** (AndroidManifest android:label). |
| 2.4 | Release imzalama | ☑ OK | build.gradle.kts: key.properties + signingConfigs.release; release build type release imzası kullanıyor. |
| 2.5 | key.properties dosyası | ☑ OK | **Var** (apps/mobile/android/key.properties). |
| 2.6 | Keystore dosyası | ☑ OK | **Var** (apps/mobile/keystores/projectflow-upload.jks). |

---

## 3. AndroidManifest

| # | Kontrol | Sonuç |
|---|---------|--------|
| 3.1 | INTERNET | ☑ |
| 3.2 | POST_NOTIFICATIONS | ☑ |
| 3.3 | SCHEDULE_EXACT_ALARM | ☑ |
| 3.4 | RECEIVE_BOOT_COMPLETED | ☑ |
| 3.5 | Main activity exported | ☑ android:exported="true" |
| 3.6 | LAUNCHER intent-filter | ☑ |
| 3.7 | BILLING izni | ☑ Gerek yok (kütüphane ekliyor). |

---

## 4. Ücretsiz / Pro (IAP)

| # | Kontrol | Sonuç | Not |
|---|---------|--------|-----|
| 4.1 | ProState / ProIapService | ☑ OK | pro_state.dart, pro_iap_service.dart mevcut. |
| 4.2 | Ürün kimliği (kod) | ☑ OK | **projectflow_pro** (pro_iap_service.dart → kProProductId). |
| 4.3 | Tek seferlik satın alma | ☑ OK | buyNonConsumable kullanılıyor. |
| 4.4 | Play Console’da ürün | ☐ Yapılacak | Play Console → Monetize → In-app products → **projectflow_pro** (tek seferlik) oluşturulup **Aktif** edilmeli. |

---

## 5. AAB (App Bundle)

| # | Kontrol | Sonuç | Not |
|---|---------|--------|-----|
| 5.1 | app-release.aab mevcut mu? | ☑ OK | **Var.** `flutter build appbundle` ile üretildi (45.8 MB). Yol: `apps/mobile/build/app/outputs/bundle/release/app-release.aab` |
| 5.2 | Yükleme | ☐ | Bu AAB dosyasını Play Console’da “App bundle’ları yükle” ile yükleyin. |

---

## 6. Gizlilik politikası ve mağaza dokümanları

| # | Kontrol | Sonuç |
|---|---------|--------|
| 6.1 | gizlilik-politikasi.md | ☑ Var (docs/setup/) |
| 6.2 | gizlilik-politikasi.html | ☑ Var (docs/setup/) |
| 6.3 | play-console-uygulama-formu.md | ☑ Var (docs/setup/) |
| 6.4 | Gizlilik sayfası yayında mı? URL alındı mı? | ☐ Sizin yapacaklarınız (GitHub Pages veya kendi siteniz). |
| 6.5 | Play Console’da politika URL’i girildi mi? | ☐ Uygulama oluşturulduktan sonra girilecek. |

---

## 7. Play Console – Genel

| # | Madde | Durum |
|---|--------|--------|
| 7.1 | Uygulama oluşturuldu (ad, dil, ücretsiz) | ☐ |
| 7.2 | Mağaza listesi (kısa/uzun açıklama, ikon 512×512, en az 2 ekran görüntüsü) | ☐ |
| 7.3 | Uygulama içi ürün `projectflow_pro` tanımlı ve aktif | ☐ |
| 7.4 | Gizlilik politikası URL’i girildi | ☐ |
| 7.5 | İçerik derecelendirmesi / hedef kitle dolduruldu | ☐ |
| 7.6 | AAB yüklendi | ☐ |
| 7.7 | İncelemeye gönderildi | ☐ |

---

## 8. Özet – Tek cümlelik durum

| Bölüm | Durum |
|--------|--------|
| **Güvenlik (hassas dosyalar)** | ☑ Repoda yok; .gitignore doğru. |
| **Versiyon / paket / imzalama** | ☑ Uygun; key.properties ve keystore mevcut. |
| **Manifest / izinler** | ☑ Eksik izin yok. |
| **Free/Pro kodu** | ☑ Tutarlı; ürün ID: projectflow_pro. |
| **AAB** | ☑ **Var** – `flutter build appbundle` ile üretildi (45.8 MB). |
| **Play Console** | ☐ Uygulama + mağaza + IAP ürünü + politika URL’i + AAB yükleme sizin tamamlayacağınız adımlar. |

**Sonuç:** Kod, yerel yapılandırma ve AAB Google Play yüklemesine **hazır**. Kalan: **Play Console’da** uygulama oluşturma, mağaza listesi, **projectflow_pro** ürünü, gizlilik URL’i ve bu AAB’yi yükleyip incelemeye gönderme.
