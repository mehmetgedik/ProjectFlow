# Proje İnceleme Raporu – OpenProject Mobile (ProjectFlow)

**Tarih:** Ocak 2025  
**Kapsam:** `apps/mobile` Flutter uygulaması, API, state, ekranlar, dokümantasyon.

---

## 1. Özet

Uygulama, OpenProject web deneyimini mobilde (online) sunmak için iyi bir temel sunuyor: bağlantı/auth, proje seçimi, iş paketleri listesi ve detay, görünüm/query, bildirimler, zaman girişi, profil ve tema seçimi mevcut. Aşağıda **yapılması gerekenler**, **eklenmesi önerilenler** ve **değiştirilmesi gerekenler** kategorize edilmiştir.

---

## 2. Kritik / Hemen Yapılması Gerekenler

### 2.1 Test: `widget_test.dart` hatalı

- **Finding:** `test/widget_test.dart` hâlâ varsayılan Flutter şablonunu kullanıyor: `MyApp`, `Counter`, `find.text('0')` / `find.text('1')`. Projede `MyApp` ve counter yok; uygulama `ProjectFlowApp` ve `RootRouter` ile başlıyor.
- **Impact:** `flutter test` çalıştırıldığında testler fail olur; CI/CD veya yerel test güvenilir değildir.
- **Recommendation:** Testi ProjectFlow’a uyumlu hale getirin: `ProjectFlowApp` + gerekli Provider’lar ile pump edin; en azından splash veya connect ekranının render edildiğini doğrulayın. İsterseniz şimdilik “placeholder” bir test bırakıp ileride gerçek widget testleri ekleyin.

### 2.2 Bildirim API: HTTP 406 / filtre hataları

- **Finding:** Kullanıcı raporu: “Bildirim okundu işaretlenemedi (HTTP 406)”, “Filters Uygulama içi okuyun filtrede geçersiz değerler var”. OpenProject API dokümantasyonunda filtre adı `readIAN`, okundu işareti için `read_ian` action kullanılıyor.
- **Impact:** Bazı OpenProject sürümlerinde veya kurulumlarında bildirim listesi yüklenemiyor veya “okundu” işaretlenemiyor.
- **Recommendation:**
  - `markNotificationRead`: Endpoint’in tam path’ini ve HTTP metodunu (POST/PATCH) OpenProject sürümünüze göre doğrulayın; 406 genelde Accept/Content-Type veya gövde formatından kaynaklanır – gerekirse `Accept` header’ı veya boş JSON gövdesi formatını dokümana göre ayarlayın.
  - Liste filtreleri: `readIAN` ve `values: ['f']` / `['t']` kullanımını API dokümantasyonu ve sunucu yanıtına göre kontrol edin; sunucu farklı bir değer (örn. boolean) bekliyorsa uyarlayın.
  - Hata mesajlarını kullanıcı dostu Türkçe metinlerle gösterin (örn. “Bildirim şu anda okundu olarak işaretlenemiyor. Lütfen daha sonra tekrar deneyin.”).

### 2.3 İş detayı – Zaman sekmesi hatası

- **Finding:** Konuşma özetinde “Zaman sekmesi hata veriyor” ifadesi geçiyor; detay kodda `_TimeTab` `getWorkPackageTimeEntries` kullanıyor.
- **Impact:** Kullanıcı zaman girişi ekleyemiyor veya mevcut kayıtları göremiyor.
- **Recommendation:** Time entries API çağrısını (endpoint, filtreler, yetki) kontrol edin; 403/404/422 durumlarında anlamlı mesaj gösterin. Gerekirse `time_entries` için proje/izin gereksinimlerini dokümandan doğrulayın.

---

## 3. Güvenlik

### 3.1 Mevcut iyi uygulamalar

- API key ve instance URL `FlutterSecureStorage` ile saklanıyor.
- Çıkışta hassas bilgiler silinmiyor (kasıtlı; tekrar girişte form dolu kalıyor); tam temizlik için `clearStoredSettings()` var.
- Avatar ve API isteklerinde Basic auth header kullanımı tutarlı.

### 3.2 Öneriler

- **Loglama:** `AppLogger.logError` ve `debugPrint` kullanımında API key, token veya hassas kullanıcı verisi loglanmıyor olmalı; bir kez kod taraması yapın.
- **Sertifika / pinning:** Şu an yok; kurumsal ortamda ileride certificate pinning eklenebilir (ayrı bir görev olarak planlanabilir).

---

## 4. Eksik veya İyileştirilmesi Gereken Özellikler (Dokümana göre)

### 4.1 P1-F01 (Profil ve kişiselleştirme)

- **Sesle giriş (mikrofon):** Kabul kriterinde “Giriş ekranında sesle yazma için mikrofon ikonu” geçiyor; `connect_screen.dart` ve `connect_settings_screen.dart` içinde mikrofon/voice input yok. Platformun text-to-speech / sesle yazma özelliğine kısayol (örn. TextField yanında ikon) eklenebilir.
- **Profil:** Ad/soyad düzenleme ve tema seçimi mevcut. E-posta ve diğer alanlar API’den geliyorsa salt okunur gösterilebilir (şu an sadece name/login/instance var).

### 4.2 Dashboard

- Grafik türü seçenekleri (`DashboardChartType`) var ancak kullanıcı tercihi kalıcı değil (uygulama yeniden başlayınca sıfırlanır). `ThemeState` veya `SharedPreferences` ile dashboard tercihlerini (hangi grafikler açık, hangi tür) saklamak dokümandaki “özelleştirilebilir dashboard” hedefine uygun olur.
- Zaman bazlı grafikler şu an “benim açık işlerim” verisiyle; ileride time entries verisiyle (günlük/haftalık toplam) zenginleştirilebilir.

### 4.3 İş paketleri

- **Yeni iş paketi oluşturma:** P1-F01’de “sık kullanılan aksiyon (FAB)” geçiyor; “Benim işlerim” veya dashboard’da FAB ile yeni iş paketi oluşturma henüz yok. OpenProject API’de `POST /work_packages` ile eklenebilir; proje ve tip zorunludur.
- **Düzenleme:** Detay ekranında durum, tip, atanan vb. güncellenebiliyor; tüm web alanlarıyla tam parity için eksik alanlar dokümandan çıkarılıp planlanabilir.

### 4.4 Görünümler (P1-F02)

- Kayıtlı görünüm seçimi, filtre formu, gruplama ve hiyerarşi mevcut. Query sonuçları için sayfalama (offset > 1) yok; çok büyük görünümlerde “daha fazla yükle” eklenebilir.

---

## 5. Kod Kalitesi ve Mimari

### 5.1 Route yapısı

- `main.dart`: `/my-work`, `/dashboard`, `/notifications`, `/profile` tanımlı; `ProjectsScreen` home, oradan `pushNamed('/dashboard')` kullanılıyor. Route isimleri tek yerde; tutarlı.

### 5.2 Büyük ekranlar

- `my_work_packages_screen.dart` 1700+ satır. Filtre formu, gruplu/hiyerarşik satır üretimi ve liste item builder ayrı widget’lara veya mixin’lere bölünerek okunabilir ve test edilebilir hale getirilebilir.
- `work_package_detail_screen.dart` da uzun; Detay / Aktivite / Zaman sekmeleri ayrı dosyalara taşınabilir.

### 5.3 Hata mesajları

- Birçok yerde `e.toString()` doğrudan gösteriliyor. Ağ hatası, 401, 404, 422 gibi durumlar için kullanıcı dostu Türkçe mesajlar (örn. “Bağlantı hatası”, “Yetkiniz yok”, “Kayıt bulunamadı”) eşleştirilmesi UX’i iyileştirir.

### 5.4 Tutarlılık

- Pull-to-refresh: Liste ekranlarında ve proje listesinde var; kullanım tutarlı.
- Loading: Genelde `CircularProgressIndicator`; iyi.
- Boş liste metinleri: “Üzerine atanmış açık iş bulunamadı”, “Henüz aktivite bulunmuyor” vb. – tutarlı.

---

## 6. API ve Veri

### 6.1 Query sonuçları sayfalama

- `getQueryWithResults` şu an tek sayfa (offset 1, pageSize). Çok büyük görünümlerde “Sonraki sayfa” veya “Daha fazla” ile offset artırılıp sonuçlar eklenebilir.

### 6.2 Bildirimler

- `getNotifications(onlyUnread: true)` filtreleri: `readIAN` + `values: ['f']`. OpenProject sürümüne göre `values` formatı (string/boolean) doğrulanmalı; 400 hatası alınıyorsa sunucu logları veya API dokümantasyonu ile karşılaştırın.
- `NotificationItem.fromJson`: `read: json['readIAN'] == true` – API’nin döndüğü alan adı ve tipi (boolean vs string) ile uyumlu olmalı.

### 6.3 Zaman kayıtları

- `getWorkPackageTimeEntries` entity_type/entity_id filtreleri kullanılıyor; `createTimeEntry` `_links.entity` ile work package bağlı. Yetki (project/time_entries izni) ve endpoint path’leri OpenProject sürümüne göre teyit edilmeli.

---

## 7. Dokümantasyon ve Geliştirme

### 7.1 README

- Kök `README.md`: Analiz ve çalışma prensibi açıklanmış.
- `apps/mobile/README.md`: Hâlâ “A new Flutter project” ve genel Flutter kaynakları; “ProjectFlow – OpenProject mobil istemci, bağlantı, iş paketleri, bildirimler, zaman girişi” gibi kısa bir proje özeti ve `flutter pub get` / çalıştırma adımları eklenebilir.

### 7.2 Versiyon ve Changelog

- `pubspec.yaml`: `version: 1.0.0+1`. Önemli değişiklikler için `CHANGELOG.md` (veya benzeri) eklenmesi dağıtım ve iletişim için faydalı olur.

### 7.3 Cursor rules

- `.cursor/rules` altında `dart-flutter-standards.mdc`, `mobile-product-scope.mdc` vb. var; kod stili ve kapsam için referans olarak kullanılmaya devam edilebilir.

---

## 8. Yapılacaklar Özet Listesi (Öncelik sırasıyla)

| Öncelik | Madde | Kategori |
|--------|--------|----------|
| 1 | `widget_test.dart`’ı ProjectFlow’a uyumlu hale getir veya anlamlı bir smoke test yaz | Kritik |
| 2 | Bildirim API: 406 ve filtre hatalarını gidermek (endpoint, header, readIAN değerleri) | Kritik |
| 3 | Zaman sekmesi hatasını tespit et ve düzelt (time entries API / yetki) | Kritik |
| 4 | Hata mesajlarını kullanıcı dostu Türkçe metinlere çevir | UX |
| 5 | Dashboard tercihlerini (grafik türü vb.) kalıcı sakla | Özellik |
| 6 | Giriş ekranına sesle yazma (mikrofon) kısayolu ekle (P1-F01) | Özellik |
| 7 | Query sonuçları için “daha fazla yükle” / sayfalama | Özellik |
| 8 | Büyük ekranları parçalara böl (my_work_packages_screen, work_package_detail_screen) | Kod kalitesi |
| 9 | Yeni iş paketi oluşturma (FAB + form) | Özellik |
| 10 | README (apps/mobile) ve isteğe bağlı CHANGELOG güncellemesi | Dokümantasyon |

---

## 9. Sonuç

Proje, OpenProject mobil istemci hedefi için sağlam bir temel sunuyor. Öncelik verilmesi gerekenler: **testlerin düzeltilmesi**, **bildirim ve zaman API hatalarının giderilmesi** ve **kullanıcıya gösterilen hata metinlerinin iyileştirilmesi**. Bunların ardından dashboard kişiselleştirme, sesle giriş, sayfalama ve yeni iş paketi oluşturma gibi özellikler dokümandaki kabul kriterleriyle uyumlu şekilde eklenebilir.
