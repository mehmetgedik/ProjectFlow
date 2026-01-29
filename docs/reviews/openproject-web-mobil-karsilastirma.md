# OpenProject Web vs ProjectFlow Mobil – Özellik Karşılaştırması

**Tarih:** Ocak 2025  
**Amaç:** OpenProject web uygulaması ile ProjectFlow (Flutter mobil) uygulamasını özellik bazında karşılaştırmak ve eşleştirmek.

---

## 1. Genel Bakış

| | OpenProject Web | ProjectFlow Mobil |
|---|-----------------|-------------------|
| **Platform** | Tarayıcı (web) | Android / iOS (Flutter) |
| **Bağlantı** | Oturum (cookie) veya API | Sadece API (instance URL + API key) |
| **Kapsam** | Tüm modüller, yönetim, raporlar | Sık kullanılan işlemler, bildirimler, zaman takibi |

Mobil uygulama **online-only** çalışır; web’deki yönetim ve raporlama odaklı özelliklerin bir kısmı mobilde yoktur veya sadeleştirilmiştir.

---

## 2. Özellik Eşleştirme Tablosu

### 2.1 Kimlik ve Erişim

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| Oturum açma (login/parola) | Bağlan: instance URL + API key | ✅ Eşleşir (API key ile) |
| Çoklu oturum / SSO | Tek instance, API key | ⚠️ Web’deki SSO mobilde yok; API key kullanımı eşdeğer |
| Oturum kapatma | Çıkış (instance/API key/proje **silinmez**) | ✅ Eşleşir |
| Instance / API key ayarları | Giriş ekranı → Ayarlar ikonu | ✅ Eşleşir |

### 2.2 Kullanıcı ve Profil

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| Profil: ad, avatar, e-posta | Profil: ad, kullanıcı adı, instance, avatar, e-posta | ✅ Eşleşir |
| Ad/soyad düzenleme | Profil → Ad/soyad düzenle | ✅ Eşleşir |
| Tema (açık/koyu) | Profil → Tema seçimi | ✅ Eşleşir |
| Dil tercihi | Web’de var | ⚠️ Mobilde uygulama Türkçe odaklı; dil ayarı yok |

### 2.3 Projeler ve Gezinme

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| Proje listesi | `getProjects()`; Profil ekranında proje seçimi | ✅ Eşleşir |
| Aktif proje / proje değiştirme | Profil → “Aktif proje” seçimi | ✅ Eşleşir |
| Proje modülleri (aç/kapa) | Web’de proje bazlı | ❌ Mobilde yok (tek akış) |
| Ana sayfa / “My page” | Dashboard (grafikler, yaklaşan işler) | ✅ Eşleşir |

### 2.4 İş Paketleri (Work Packages)

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| İş paketi listesi (sorgular/görünümler) | Benim işlerim: kayıtlı query, filtre, sayfalama | ✅ Eşleşir |
| Hiyerarşi / gruplama | Grup başlıkları, parent/child, collapse/expand | ✅ Eşleşir |
| İş paketi detayı | Detay sekmesi: durum, tip, atanan, tarih, üst iş vb. | ✅ Eşleşir |
| İş paketi düzenleme (durum, atanan, tarih, tip, üst) | Detay ekranında inline düzenleme + `patchWorkPackage` | ✅ Eşleşir |
| Yeni iş paketi oluşturma | “+” → CreateWorkPackageScreen (proje, tip, başlık, atanan, öncelik, durum, üst, versiyon, tarihler) | ✅ Eşleşir |
| Öncelik / versiyon / kategori (web formunda) | Oluşturma formunda öncelik, versiyon; detayda öncelik/versiyon düzenleme kısmen | ⚠️ Kısmi (öncelik/versiyon oluşturmada var) |
| Aktivite / yorum | Aktivite sekmesi, yorum ekleme | ✅ Eşleşir |
| Ekler (dosya) | Web’de var | ❌ Mobilde yok |

### 2.5 Zaman Takibi (Time Tracking)

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| İş paketine zaman girişi | İş detayı → Zaman sekmesi, süre + yorum | ✅ Eşleşir |
| Kendi zaman kayıtları listesi | Zaman takibi sayfası (tablo + Gantt), filtre, gruplama | ✅ Eşleşir |
| Ekip zamanları (yetkili kullanıcılar) | Zaman takibi → “Ekip” modu, proje üyelerine göre | ✅ Eşleşir |
| Labor maliyeti / saatlik ücret | Web’de var | ❌ Mobilde yok |

### 2.6 Bildirimler

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| Bildirim listesi (okunmamış / tümü) | Bildirimler ekranı | ✅ Eşleşir |
| Okundu işaretleme | Tekil + toplu okundu | ✅ Eşleşir |
| Bildirimden iş paketine gitme | Bildirim → iş detayı | ✅ Eşleşir |
| Push / yerel bildirimler | LocalNotificationService, arka plan | ✅ Mobilde ek değer |

### 2.7 Gantt ve Planlama

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| Gantt (proje planı, sürükle-bırak) | İş listesinde Gantt widget; zaman takibinde zaman Gantt’ı | ⚠️ Mobilde görüntüleme odaklı, düzenleme yok |
| Bağımlılıklar (predecessor/successor) | Web’de Gantt içinde | ❌ Mobilde yok |

### 2.8 Diğer Web Modülleri (Mobilde Yok veya Kısıtlı)

| OpenProject Web | ProjectFlow Mobil | Durum |
|-----------------|-------------------|--------|
| Wiki | Proje wiki sayfaları | ❌ Mobilde yok |
| Boards (Kanban) | Agile tahtaları | ❌ Mobilde yok |
| Backlogs (Scrum) | Product backlog, taskboard | ❌ Mobilde yok |
| Toplantılar (Meetings) | Gündem, kararlar | ❌ Mobilde yok |
| Takvim | Proje takvimi | ❌ Mobilde yok |
| Dokümanlar | Dosya depolama | ❌ Mobilde yok |
| Haberler / Duyurular | Proje haberleri | ❌ Mobilde yok |
| Forumlar | Proje forumları | ❌ Mobilde yok |
| Bütçeler (Budgets) | Maliyet / bütçe | ❌ Mobilde yok |
| Yönetim (rol, proje ayarları, özelleştirme) | Web’de admin | ❌ Mobilde yok |

---

## 3. API Eşlemesi (Özet)

Mobil uygulama aşağıdaki OpenProject API uç noktalarını kullanır; web ile aynı REST API üzerinden veri alır.

| API Alanı | Kullanım (Mobil) |
|-----------|------------------|
| `GET /users/me` | Profil, ad, e-posta, avatar |
| `PATCH /users/me` | Ad/soyad güncelleme |
| `GET /my_preferences` | Tercihler (isteğe bağlı) |
| `GET /projects` | Proje listesi, aktif proje |
| `GET /projects/:id/versions` | Versiyonlar (oluşturma formu) |
| `GET /work_packages`, `GET /work_packages/:id` | İş listesi, detay |
| `POST /work_packages` | Yeni iş paketi |
| `PATCH /work_packages/:id` | Durum, atanan, tarih, tip, üst iş |
| `GET /queries`, `GET /views` | Kayıtlı sorgular/görünümler |
| `GET /queries/:id` (with results) | Sayfalı sonuçlar |
| `GET /work_packages/:id/activities` | Aktivite/yorumlar |
| `POST /work_packages/:id/activities` | Yorum ekleme |
| `GET /time_entries`, `POST /time_entries` | Zaman kayıtları, yeni giriş |
| `GET /notifications`, `PATCH /notifications/:id` | Bildirimler, okundu |
| `GET /statuses`, `GET /priorities` | Durum/öncelik listeleri |
| `GET /memberships` (proje) | Proje üyeleri (atama, ekip zamanı) |
| `GET /projects/:id/types` | İş tipleri |

Web arayüzü de aynı API’yi kullandığı için **veri tam uyumludur**; fark sadece sunulan ekranlar ve modüllerdir.

---

## 4. Özet: Ne Eşleşiyor, Ne Eksik?

### Tam veya güçlü eşleşen alanlar

- Bağlantı ve kimlik (API key), ayarlar, çıkış davranışı  
- Profil (ad, avatar, e-posta, tema, aktif proje)  
- İş paketleri: listeleme, filtre, sorgular, hiyerarşi, sayfalama  
- İş paketi detayı ve düzenleme (durum, atanan, tarih, tip, üst)  
- Yeni iş paketi (proje, tip, atanan, öncelik, durum, versiyon, tarihler)  
- Aktivite ve yorumlar  
- Zaman girişi (iş paketi + kendi/ekip zaman listesi, tablo/Gantt)  
- Bildirimler (liste, okundu, işe gitme)  
- Dashboard (grafikler, yaklaşan işler, tercihlerin saklanması)  

### Kısmen eşleşen / sadeleştirilmiş

- Gantt: sadece görüntüleme, web’deki gibi sürükle-bırak planlama yok  
- Öncelik/versiyon/kategori: oluşturmada var, detayda tüm alanlar web ile tam aynı değil  

### Kasıtlı olarak mobilde yok

- Wiki, Boards, Backlogs, Meetings, Takvim, Dokümanlar, Haberler, Forumlar, Bütçeler  
- Web yönetim ekranları (rol, proje modülleri, özelleştirme)  
- Dosya ekleri (ileride eklenebilir)  

Bu belge, OpenProject web ile ProjectFlow mobil uygulamasının **özellik bazında nasıl eşleştiğini** tek bakışta görmek ve eksik/isteğe bağlı iyileştirmeleri planlamak için kullanılabilir.
