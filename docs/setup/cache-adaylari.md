# Cache adayları – sık değişmeyen, sürekli sorgulanan veriler

Performans için önbelleğe alınabilecek API verileri. Avatar cache (P1-F05) dışında, aşağıdaki yapılar da “seyrek değişen ama tekrarlı sorgulanan” veri niteliğinde; istenirse aynı mantıkla (TTL veya çıkışta temizleme) cache’lenebilir.

---

## 1. Referans listeler (instance geneli, çok seyrek değişir)

| Veri | API | Nerede sorgulanıyor | Neden cache adayı |
|------|-----|----------------------|--------------------|
| **Durumlar** | `getStatuses()` | İş oluşturma ekranı (açılışta), iş detayda durum değiştir dialog | Admin ekler/değiştirir; ekran her açılışta tekrar istek atıyor. |
| **Öncelikler** | `getPriorities()` | İş oluşturma ekranı (açılışta) | Seyrek değişir; form açıldıkça tekrar çekiliyor. |
| **Zaman kaydı aktiviteleri** | `getTimeEntryActivities()` | Mesai ekranı (2 yerde), iş detayda zaman kayıtları sekmesi | Kurulumda tanımlı; mesai/iş detay her açılışta aynı liste tekrar isteniyor. |
| **Haftanın günleri** | `getWeekDays()` | Mesai hatırlatma servisi (zamanlama) | Çok seyrek değişir; servis tetiklendiğinde tekrar çağrılabiliyor. |

**Öneri:** Bellek cache; key = endpoint (veya `statuses`, `priorities`, `time_entries/activities`, `week_days`). TTL (örn. 1 saat / 24 saat) veya çıkışta temizleme.

---

## 2. Proje listesi

| Veri | API | Nerede sorgulanıyor | Neden cache adayı |
|------|-----|----------------------|--------------------|
| **Aktif projeler** | `getProjects()` | Giriş sonrası gate (proje seçimi), iş oluşturma ekranı, profil ekranı (proje listesi) | Proje ekleme/arşivleme seyrek; aynı liste birden fazla ekranda ve her açılışta çekiliyor. |

**Öneri:** Key = `projects`. TTL veya “proje seçildiği / iş oluşturma açıldığı” gibi tetikleyicilerle yenileme; çıkışta temizleme.

---

## 3. Proje bazlı referanslar (proje seçildikten sonra)

| Veri | API | Nerede sorgulanıyor | Neden cache adayı |
|------|-----|----------------------|--------------------|
| **Proje tipleri** | `getProjectTypes(projectId)` | İş oluşturma (proje seçilince), iş detayda tip değiştir | Proje ayarı; aynı projede tekrarlı ekran açılışında aynı istek. |
| **Proje versiyonları** | `getProjectVersions(projectId)` | İş oluşturma, dashboard (grafik/sprint) | Sprint/release seyrek değişir; dashboard ve form aynı listeyi tekrar istiyor. |
| **Proje üyeleri** | `getProjectMembers(projectId)` | İş oluşturma (atanan seçimi), iş detay (atanan), mesai ekranı (takım) | Üye ekleme seyrek; atanan/takım seçimi her açılışta aynı liste. |
| **Kayıtlı görünümler** | `getQueries(projectId)` | Benim işlerim (görünüm listesi), dashboard (görünümler) | Görünüm ekleme seyrek; liste ekran açıldıkça tekrar çekiliyor. |

**Öneri:** Key = `project_types:$projectId`, `project_versions:$projectId`, `project_members:$projectId`, `queries:$projectId` (veya `queries:null` global için). TTL veya çıkışta temizleme; proje değişince ilgili proje bazlı key’leri invalide etmek mantıklı.

---

## 4. Cache’e uygun olmayan / dikkatli kullanılması gerekenler

| Veri | Neden cache’e zor / dikkat |
|------|----------------------------|
| İş listesi (`getMyOpenWorkPackages`, `getQueryWithResults`, `getWorkPackages`) | İçerik sık değişir; sayfalama ve güncel veri önemli. Kısa TTL veya sadece “son liste” tutulabilir, tam cache yerine. |
| Bildirimler (`getNotifications`) | Sürekli yeni okuma/ekleme; liste cache’i kısa ömürlü olmalı veya sadece sayı cache’i. |
| Tek iş detayı (`getWorkPackage(id)`), aktiviteler (`getWorkPackageActivities`) | Güncelleme/yorum sonrası taze veri gerekir; cache invalidation karmaşık. |
| Kullanıcı bilgisi (`getMe`) | AuthState zaten tutuyor; ek cache gereksiz. |

---

## 5. Uygulama sırası önerisi

1. **Öncelikli (en çok tekrarlanan):**  
   `getStatuses`, `getPriorities`, `getTimeEntryActivities`, `getProjects`  
   – Birden fazla ekranda veya her form açılışında çağrılıyor.

2. **İkinci:**  
   `getProjectTypes`, `getProjectVersions`, `getProjectMembers`, `getQueries`  
   – Proje bazlı; aynı projede gezerken tekrar tekrar istek atılıyor.

3. **İsteğe bağlı:**  
   `getWeekDays` – Sadece hatırlatma servisinde; çağrı sıklığı düşük.

---

## 6. Ortak kurallar (avatar cache ile uyumlu)

- Çıkış (ve hesap değiştirme) yapıldığında tüm bu cache’ler temizlenmeli.
- TTL kullanılacaksa süre ürün kararı ile belirlenir (örn. 15 dk – 24 saat).
- Cache miss veya hata durumunda mevcut davranış korunmalı (doğrudan API’ye gidilir, fallback).

Bu liste P1-F05 (seyrek değişen veri önbelleği) kapsamındaki “diğer seyrek değişen veriler” için aday setidir; implementasyon aşamasında hangilerinin cache’leneceği ve TTL/invalidation detayları netleştirilir.
