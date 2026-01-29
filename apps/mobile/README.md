# ProjectFlow – OpenProject Mobil İstemci

OpenProject web arayüzüne mobil cihazlardan (online) erişim sağlayan Flutter uygulaması. Bağlantı, iş paketleri listesi/detay, kayıtlı görünümler, bildirimler, zaman girişi, profil ve tema desteği sunar.

## Özellikler

- **Bağlantı:** Instance URL ve API key ile güvenli giriş; ayarlar cihazda saklanır (çıkışta silinmez).
- **Projeler:** Aktif proje seçimi; tek proje varsa otomatik devam.
- **Benim işlerim:** Açık işler listesi, filtre (tümü / bugün bitiş / gecikmiş), sıralama, sayfalama.
- **Görünümler:** OpenProject’te kayıtlı görünümleri seçme; gruplu ve hiyerarşik liste; filtre formu; kolon seçimi; görünüm sonuçları için “daha fazla yükle”.
- **İş detayı:** Durum, tip, atanan, yorum/aktivite, zaman kayıtları; düzenleme ve zaman girişi ekleme.
- **Yeni iş paketi:** AppBar’daki “+” ile proje/tip/başlık formu; oluşturulunca detay ekranına geçiş.
- **Bildirimler:** Okunmamış/tümü listesi; okundu işaretleme; bildirimden iş paketine geçiş.
- **Profil:** Görünen ad, tema (açık/koyu/sistem), çıkış.
- **Dashboard:** Durum/tip grafikleri, zaman serisi, yaklaşan bitiş listesi; ayarlar kalıcı saklanır.

## Gereksinimler

- Flutter SDK ^3.10.7
- Android (minSdk 21) veya iOS

## Kurulum ve çalıştırma

```bash
cd apps/mobile
flutter pub get
flutter run
```

Android emülatör veya bağlı cihaz seçilir; uygulama açıldığında bağlantı ekranı gelir.

## Bağlantı

1. OpenProject instance adresinizi girin (örn. `https://openproject.example.com`).
2. Kişisel API anahtarınızı girin (Kullanıcı menüsü → Hesabım → API erişimi).
3. “Bağlan” ile giriş yapın; proje listesinden bir proje seçin.

## Proje yapısı (lib)

- `api/` – OpenProject REST API istemcisi
- `models/` – Proje, iş paketi, bildirim, zaman kaydı vb. modeller
- `screens/` – Bağlantı, projeler, dashboard, iş listesi, iş detayı, yeni iş, bildirimler, profil
- `state/` – Auth, tema, dashboard tercihleri
- `theme/` – Açık/koyu tema
- `utils/` – Hata mesajları, log, haptic
- `widgets/` – Avatar, logo buton, liste aksiyonları

## Test

```bash
flutter test
```

Smoke test: Uygulama ayağa kalkar ve başlangıç ekranı render edilir.
