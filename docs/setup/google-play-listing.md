# Google Play Store – ProjectFlow Yayın Bilgileri

Bu doküman, **ProjectFlow for OpenProject** uygulamasının Google Play’de yayınlanması için gerekli store listing ve teknik bilgileri özetler.

## Uygulama kimliği

| Alan | Değer |
|------|--------|
| **Uygulama adı (cihazda)** | ProjectFlow *(kısa; isteğe bağlı “ProjectFlow for OpenProject”)* |
| **Store başlığı (önerilen)** | ProjectFlow for OpenProject *(max 30 karakter)* |
| **Paket adı (applicationId)** | `com.openproject.openproject_mobile` |
| **Versiyon** | `pubspec.yaml` → `version: 1.0.0+1` (versionName + versionCode) |

## Store listing (Play Console)

### Kısa açıklama (Short description) – max 80 karakter
Örnek (Türkçe):
```
Ücretsiz indir; OpenProject’e bağlan. Pro tek seferlik satın alma ile gelişmiş özellikler.
```
İngilizce örnek:
```
Free download; connect to OpenProject. Pro one-time purchase unlocks advanced features.
```

### Uzun açıklama (Full description) – max 4000 karakter
Örnek (Türkçe):
```
ProjectFlow, OpenProject sunucunuza bağlanan mobil istemcidir. Temel özellikler ücretsiz; gelişmiş özellikler Pro ile açılır.

ÜCRETSİZ:
• Sunucuya bağlanma ve giriş
• Proje listesi ve proje seçimi
• Benim işlerim listesi ve detay
• Durum / atama hızlı güncelleme
• Yorum görüntüleme ve yeni yorum ekleme
• Bildirim listesi ve okundu işaretleme
• Zaman kaydı ekleme ve listeleme

PRO İLE:
• Zaman kayıtlarını düzenleme ve silme, raporlama
• Kayıtlı görünümler ve gelişmiş filtreleme
• Kolon ayarları (liste görünümü)
• Ek (dosya) yükleme ve gelişmiş görüntüleme
• İş paketi ilişkileri (parent/child/related)
• Gelişmiş bildirim deneyimi
• Gantt ve ileri görünümler

OpenProject hesabınızdan API anahtarını alıp ProjectFlow ile bağlanarak işlerinizi mobilde yönetin. Pro’yu uygulama içinden satın alarak gelişmiş özellikleri açabilirsiniz.
```

### Pro ve Ücretsiz karşılaştırması (store dışı / ekran görüntüsü metni)
Mağaza dışında (web sitesi, sosyal medya, feature graphic metni) kullanılabilecek kısa karşılaştırma:

**Tek cümle (Türkçe):**  
Temel özellikler ücretsiz; Pro ile zaman raporlama, kayıtlı görünümler, ekler ve Gantt gibi gelişmiş özellikler açılır.

**Tek cümle (İngilizce):**  
Core features are free; Pro unlocks time reporting, saved views, attachments, and Gantt.

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
- **Uygulama başlığı:** Store’da “ProjectFlow for OpenProject”; UI’da “ProjectFlow” veya “ProjectFlow for OpenProject”
- **Android `android:label`:** `ProjectFlow` (`AndroidManifest.xml`)

Bu dosyayı yayın sürecinde güncelleyebilirsiniz (ör. final store metinleri, gizlilik politikası linki).
