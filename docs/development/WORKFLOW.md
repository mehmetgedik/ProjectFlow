## Paralel geliştirme iş akışı (Cursor)

Hedef: P0 özelliklerini paralel geliştirmek, ardından bağımsız kontrol yaptırmak ve her şeyi dokümante etmek.

### Geliştirme sırası (P0)

Bağımlılık ve en hızlı “çalışan demo” mantığıyla önerilen sıra:

1. **P0-F01 Connect & Auth**
2. **P0-F02 Project switcher**
3. **P0-F03 My work packages list**
4. **P0-F04 Work package detail**
5. **P0-F05 Comments & activity**
6. **P0-F07 Time entry**
7. **P0-F06 Notifications**

> Not: Bildirimler çok önemli; ancak pratikte “detaya gidiş” ve temel ekranlar oturmadan bildirim UX’i eksik kalır. Bu yüzden Notification’ı P0 sonunda, ama P0 içinde tutuyoruz.

### Paralel paketleme (agent görevleri)

Her feature için 2 iş paketi aç:

- **Implementer paketi**: Kod + test + kısa özet
- **Reviewer paketi**: Finding/Impact/Recommendation/Evidence

Önerilen paralel ayrım:

- **Agent A (API/Domain)**: API client, auth/session, modeller, error handling
- **Agent B (UI)**: navigasyon, ekran iskeletleri, state management
- **Agent C (Feature implementer)**: seçilen feature’ın uçtan uca bağlanması (A+B üstüne)
- **Agent R (Reviewer)**: bağımsız kontrol ve notlama

### Cursor’da “arka planda” çalışma ve takip

Amaç: Uzun işlemleri arka planda yürütürken, çıktıyı Cursor arayüzünde görüp takip etmek.

- Her agent’ı **ayrı bir terminal** ve/veya **ayrı sohbet** olarak çalıştır.
- Uzun süren işler (örn. `flutter pub get`, build, test) için komutu “arka planda” çalıştır:
  - Terminal açık kalır, çıktıyı izleyebilirsin.
- “Reviewer” akışını, implementer tamamladıktan sonra ayrı bir sohbet/terminalde başlat.

### Analiz dosyaları (kaynak)

- **Kaynak**: Tüm “ne isteniyor” ve kabul kriterleri `docs/analysis/` altındaki epics ve features dosyalarında.
- **Sen analizde değişiklik yapabilirsin**; implementer ve reviewer her turda güncel analiz dosyalarını okuyup ona göre çalışır.
- Öncelik: ilgili feature/epic analiz dosyası → sonra kod.

### Dokümantasyon standardı

- Analiz: `docs/analysis/**` (sadece “ne isteniyor + kabul kriteri”)
- Review çıktısı: `docs/reviews/<tarih>-<feature>.md`
- Karar: `docs/decisions/<tarih>-<konu>.md`

