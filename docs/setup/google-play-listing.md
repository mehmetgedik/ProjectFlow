# Google Play Store – ProjectFlow Yayın Bilgileri

Bu doküman, **ProjectFlow – Mobile Client for OpenProject** uygulamasının Google Play’de yayınlanması için gerekli store listing ve teknik bilgileri özetler.

## Uygulama kimliği

| Alan | Değer |
|------|--------|
| **Uygulama adı (cihazda)** | ProjectFlow |
| **Store başlığı (önerilen)** | ProjectFlow *(max 30 karakter; tam ifade: "ProjectFlow – Mobile Client for OpenProject" kısa açıklamada kullanılabilir)* |
| **Paket adı (applicationId)** | `com.openproject.openproject_mobile` |
| **Versiyon** | `pubspec.yaml` → `version: 1.0.0+1` (versionName + versionCode) |

## Store listing (Play Console)

### Kısa açıklama (Short description) – max 80 karakter
Örnek:
```
OpenProject hesabına bağlan; iş paketleri, bildirimler ve zaman kayıtları.
```
İngilizce örnek:
```
Connect to OpenProject. Work packages, notifications & time entries.
```

### Uzun açıklama (Full description) – max 4000 karakter
Örnek (Türkçe):
```
ProjectFlow, OpenProject sunucunuza bağlanan resmi mobil istemcidir.

• Bağlantı: Instance URL ve API anahtarı ile güvenli giriş
• İş paketleri: Listeleme, detay, hızlı güncellemeler
• Bildirimler: OpenProject bildirimlerinizi takip edin
• Zaman kayıtları: Hızlı time entry
• Projeler: Proje seçimi ve favoriler

OpenProject hesabınızdan API anahtarını alıp ProjectFlow ile bağlanarak işlerinizi mobilde yönetin.
```

### Grafikler
- **Uygulama ikonu:** `apps/mobile/assets/icon/app_icon.png` (512×512 px store için ayrıca yükleyin; Play Console “App icon” alanı)
- **Feature graphic:** 1024×500 px (isteğe bağlı)
- **Ekran görüntüleri:** En az 2 adet; telefon için önerilen en-boy oranı 16:9 veya 9:16

## Teknik / yayın öncesi kontrol

1. **İmzalama:** Release build için kendi keystore ile imzalayın. `android/app/build.gradle.kts` içinde `signingConfig` release için ayarlanmalı (şu an debug kullanılıyor).
   - `apps/mobile/android/key.properties.example` dosyasını `apps/mobile/android/key.properties` olarak kopyalayın (commit etmeyin) ve alanları doldurun.
2. **App icon üretimi:** Logo değiştiğinde launcher ikonlarını yenilemek için:
   ```bash
   cd apps/mobile && dart run flutter_launcher_icons
   ```
3. **İzinler:** `AndroidManifest.xml` içinde yalnızca kullanılan izinler tanımlı (POST_NOTIFICATIONS, INTERNET debug’ta).
4. **Gizlilik politikası:** Google Play, bir gizlilik politikası URL’i isteyebilir. Metin ve yayınlanabilir HTML: `docs/setup/gizlilik-politikasi.md`, `docs/setup/gizlilik-politikasi.html`. Play Console form alanları: `docs/setup/play-console-uygulama-formu.md`.

## Proje içi marka kullanımı

- **Logo:** `apps/mobile/assets/icon/app_icon.png` (splash, connect ekranı ve launcher ikonu bu dosyayı kullanır)
- **Uygulama başlığı:** Tüm UI’da “ProjectFlow”; alt metin olarak “Mobile Client for OpenProject” / “OpenProject hesabına bağlan” kullanılıyor
- **Android `android:label`:** `ProjectFlow` (`AndroidManifest.xml`)

Bu dosyayı yayın sürecinde güncelleyebilirsiniz (ör. final store metinleri, gizlilik politikası linki).
