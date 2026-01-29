## Windows 11 + Flutter + Android (VS Code) kurulum rehberi

Bu rehber, bu makinede daha önce mobil geliştirme yapılmadığı varsayımıyla yazıldı.
Hedef: Flutter ile **Android cihazda** uygulamayı çalıştırmak.

### Mevcut durum (bu makinede yapılan kurulum)

- **Flutter SDK**: `C:\src\flutter` (3.38.8 stable)
- **PATH**: Kullanıcı PATH’e `C:\Program Files\Git\bin` ve `C:\src\flutter\bin` eklendi.
- **Android SDK**: `C:\Users\HP\AppData\Local\Android\Sdk` — Flutter’a tanımlandı (`flutter config --android-sdk`).
- **flutter doctor**: Flutter, Windows, Chrome, **Android toolchain tam (cmdline-tools + lisanslar kabul edildi)**, Network, cihazlar OK. Visual Studio bileşenleri sadece Windows masaüstü uygulaması için; Android için gerekmez.

Yeni bir terminalde `flutter` komutunu kullanabilirsin.

### 0) Ön koşullar

- İnternet bağlantısı
- Yönetici yetkisi (bazı adımlar için)
- Android telefon (USB kablo ile)

### 1) Flutter SDK indir

1. Flutter SDK (Stable) zip indir.
2. Zip’i şu gibi bir dizine çıkar:
   - Öneri: `C:\src\flutter`
3. `PATH` ortam değişkenine `C:\src\flutter\bin` ekle.

Kontrol (PowerShell):

```powershell
flutter --version
```

### 2) Android Studio + Android SDK (zorunlu)

Android cihazda çalıştırmak için Android SDK gerekir. En kolay yol Android Studio kurmak.

1. Android Studio indirip kur.
2. Android Studio aç → **SDK Manager**:
   - Android SDK Platform (en az 1 güncel API)
   - Android SDK Build-Tools
   - Android SDK Platform-Tools (adb)
   - Android SDK Command-line Tools
3. Android Studio → Settings → Android SDK ekranındaki **SDK path**’i not et.

> Not: Sadece VS Code kullanacağız; Android Studio’yu SDK için kuruyoruz.

### 3) Android cihazı hazırlama (gerçek cihaz)

1. Telefon → Ayarlar → “Build number” 7 kez → **Developer options** aç.
2. Developer options → **USB debugging** aç.
3. Telefonu USB ile bağla.
4. Telefonda çıkan “USB debugging authorize” penceresinde izin ver.

Kontrol:

```powershell
adb devices
```

Listede cihaz görünmeli.

### 4) Flutter doktor ile eksikleri gör

```powershell
flutter doctor -v
```

### 5) Android lisansları

```powershell
flutter doctor --android-licenses
```

### 6) VS Code eklentileri

VS Code → Extensions:

- Flutter
- Dart

### 7) İlk projeyi çalıştırma

Bu repo içinde Flutter uygulamasını `apps/mobile/` altında tutacağız.

```powershell
cd apps/mobile
flutter pub get
flutter run
```

### 8) Sık hatalar

- `flutter` komutu bulunamıyor:
  - PATH’e `...\flutter\bin` eklenmemiştir, VS Code/terminal yeniden açılmalıdır.
- Cihaz görünmüyor:
  - USB debugging açık mı, yetki verildi mi, kablo data destekli mi?
- Android SDK bulunamıyor:
  - Android Studio SDK Manager kurulumu eksik olabilir.

