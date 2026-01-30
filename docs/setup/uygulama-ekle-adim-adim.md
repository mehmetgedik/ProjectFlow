# ProjectFlow – Play Console’a uygulama ekle (adım adım)

Bu rehberi sırayla takip edin. Kopyala-yapıştır yapacağınız tüm metinler aşağıda.

---

## Önce hazırlayın

| Ne | Nerede / nasıl |
|----|-----------------|
| **AAB dosyası** | `d:\MG\Project\Mobile\OpenProject\apps\mobile\build\app\outputs\bundle\release\app-release.aab` (zaten üretildi). |
| **Uygulama ikonu** | 512×512 px PNG. Kaynak: `apps/mobile/assets/icon/app_icon.png` — gerekirse 512×512’ye kırpın/ölçekleyin. |
| **En az 2 ekran görüntüsü** | Telefonda veya emülatörde uygulamayı açıp 2 farklı ekranın ekran görüntüsünü alın (16:9 veya 9:16). |
| **Gizlilik politikası URL’i** | `gizlilik-politikasi.html` dosyasını GitHub Pages veya bir web sitesine yükleyin; tam URL’i alın (örn. `https://mehmetgedik.github.io/ProjectFlow/gizlilik-politikasi.html`). |
| **E-posta adresiniz** | Destek/geliştirici e-postası (Play Console’da istenecek). |

---

## Uygulama ekleme sayfası – Tüm alanlar ve seçenekler

Play Console’da **“Uygulama oluştur”** (Create app) tıkladığınızda açılan formda aşağıdaki alanlar çıkar. Her satırda **ne yazacağınız / hangi seçeneği işaretleyeceğiniz** tek tek yazıyor.

---

### Form alanları (sırayla)

| # | Formdaki alan adı | Tür | Ne yapacaksınız / Seçenekler |
|---|-------------------|-----|------------------------------|
| 1 | **Uygulama adı** *(App name)* | Metin kutusu | Yazın: **ProjectFlow for OpenProject** *(max 30 karakter; 27 karakter)* |
| 2 | **Varsayılan dil** *(Default language)* | Açılır liste | Seçin: **Türkçe (Türkiye)** — alternatif: İngilizce (Amerika Birleşik Devletleri) |
| 3 | **Uygulama veya oyun?** *(App or game?)* | Seçim (radio) | Seçin: **Uygulama** *(Game değil)* |
| 4 | **Ücretsiz mi ücretli mi?** *(Free or paid?)* | Seçim (radio) | Seçin: **Ücretsiz**. Uygulama indirme ücretsiz; Pro sürümü uygulama içinden tek seferlik satın alınır (in-app purchase). Bu soru “indirme ücreti” içindir; uygulama içi satın alma “ücretsiz” uygulama ile birlikte kullanılır. |
| 5 | **Bulgular / Beyanlar** *(Declarations)* | Onay kutusu | **Reklamlar:** “Uygulamam reklam içermiyor” → **Evet** / işaretleyin. Gerekirse diğer beyanlar (veri güvenliği, COVID vb.) sayfada çıkana göre işaretleyin. |

**Özet kopyala-yapıştır (metin alanları):**

| Alan | Kopyalayıp yapıştırın |
|------|------------------------|
| Uygulama adı | `ProjectFlow for OpenProject` |

**Özet seçimler:**

| Soru | Seçenek |
|------|--------|
| Uygulama mı, oyun mu? | **Uygulama** |
| Ücretsiz mi, ücretli mi? | **Ücretsiz** *(İndirme ücretsiz; Pro uygulama içi satın alma ile)* |
| Uygulama reklam içeriyor mu? | **Hayır** |

---

### Adım 1: Formu gönderme

1. **https://play.google.com/console** adresine gidin; Google hesabınızla giriş yapın.
2. **“Uygulama oluştur”** (Create app) butonuna tıklayın.
3. Yukarıdaki tabloya göre tüm alanları doldurun ve seçimleri yapın.
4. **“Uygulama oluştur”** / **“Create app”** butonuna basın. Uygulama paneli açılacak.

---

## Adım 2: Mağaza listesi (Store listing)

Sol menüden **“Mağaza ayarları”** → **“Mağaza listesi”** (veya **“Ana mağaza listesi”**) bölümüne girin.

| Alan | Karakter | Kopyala-yapıştır |
|------|----------|-------------------|
| **Uygulama adı** | Max 30 | `ProjectFlow for OpenProject` |
| **Kısa açıklama** | Max 80 | `Ücretsiz indir; OpenProject’e bağlan. Pro tek seferlik satın alma ile gelişmiş özellikler.` |
| **Uzun açıklama** | Max 4000 | Aşağıdaki kutu. |

**Uzun açıklama (tümünü kopyalayın):**
```
ProjectFlow for OpenProject, OpenProject sunucunuza bağlanan mobil istemcidir.

ÜCRETSİZ SÜRÜM
• Uygulama ücretsiz indirilir; temel özellikler herkese açıktır.
• Bağlantı: Instance URL ve API anahtarı ile güvenli giriş
• İş paketleri: Listeleme, detay, hızlı güncellemeler
• Bildirimler: OpenProject bildirimlerinizi takip edin
• Zaman kayıtları: Temel time entry
• Projeler: Proje seçimi ve favoriler

PRO SÜRÜMÜ (ÜCRETLİ – UYGULAMA İÇİ SATIN ALMA)
Pro, tek seferlik uygulama içi satın alma ile açılır. Ödeme Google Play üzerinden yapılır; kredi kartı vb. uygulama tarafından saklanmaz. Pro ile: gelişmiş zaman takibi, özel kolonlar, takım zaman görünümü, Gantt ve daha fazlası. İlk kullanımda kısa deneme süresi sunulabilir.

OpenProject hesabınızdan API anahtarını alıp ProjectFlow for OpenProject ile bağlanarak işlerinizi mobilde yönetin.
```

**Grafikler:**

| Alan | Ne yüklenecek |
|------|----------------|
| **Uygulama ikonu** | 512×512 px PNG (hazırladığınız ikon). |
| **Ekran görüntüleri (telefon)** | En az 2 adet (hazırladığınız ekran görüntüleri). |
| **Feature graphic** | 1024×500 px — isteğe bağlı; boş bırakılabilir. |

Değişiklikleri **kaydedin**.

---

## Adım 3: Uygulama içi ürün (Pro) tanımla

1. Sol menüden **“Monetize”** (Monetizasyon) → **“Ürünler”** → **“Uygulama içi ürünler”** (In-app products).
2. **“Ürün oluştur”** (Create product) deyin.
3. **Ürün kimliği:** Tam olarak `projectflow_pro` yazın (kodda bu ID kullanılıyor; değiştirmeyin).
4. **Ürün türü:** **Tek seferlik** (One-time product).
5. **Ad / Açıklama:** Örn. ad: “ProjectFlow Pro”, açıklama: “Gelişmiş zaman takibi, özel kolonlar ve daha fazlası.”
6. **Fiyat:** İstediğiniz fiyat ve para birimini seçin (örn. TRY veya USD).
7. Kaydedin ve ürünü **Aktif** (Active) yapın.

---

## Adım 4: Politika ve uygulama erişimi

**İçerik politikası / Gizlilik**

- **Gizlilik politikası URL’i:** Hazırladığınız sayfanın tam adresini yapıştırın (örn. `https://mehmetgedik.github.io/ProjectFlow/gizlilik-politikasi.html`).
- **E-posta:** Geliştirici / destek e-posta adresinizi girin.

**Uygulama erişimi (App access)**

- Tüm işlevler herkese açık mı? → **Hayır**
- Giriş gerekli mi? → **Evet**
- Açıklama kutusuna yapıştırın:  
  `Kullanıcılar kendi OpenProject instance’larına kendi API anahtarlarıyla giriş yapar. Test için kendi OpenProject sunucunuzda bir test hesabı kullanabilirsiniz.`

**Reklamlar**

- Uygulama reklam içeriyor mu? → **Hayır**

---

## Adım 5: İçerik derecelendirmesi ve hedef kitle

- **İçerik derecelendirmesi:** Anketi doldurun (genelde “Tüm yaşlar” veya düşük yaş çıkar).
- **Hedef kitle / yaş:** İş uygulaması için genelde 18+ uygun; anket sonucuna göre işaretleyin.

---

## Adım 6: AAB yükle

1. Sol menüden **“Yayın”** (Release) → **“Üretim”** (Production) veya önce **“İç test”** (Internal testing) seçin.
2. **“Yeni sürüm oluştur”** (Create new release) deyin.
3. **“App bundle’ları yükle”** (Upload) bölümüne girin.
4. Bilgisayarınızdan bu dosyayı seçin:  
   **`d:\MG\Project\Mobile\OpenProject\apps\mobile\build\app\outputs\bundle\release\app-release.aab`**
5. Yüklenince sürüm notları ekleyin (örn. “İlk sürüm. OpenProject bağlantısı, iş paketleri, bildirimler, zaman kaydı, Pro sürümü.”).
6. **“İncelemeye gönder”** (Submit for review) deyin.

---

## Kontrol listesi (sırayla)

- [ ] AAB, ikon ve en az 2 ekran görüntüsü hazır
- [ ] Gizlilik sayfası yayında; URL’i biliyorum
- [ ] Adım 1: Uygulama oluşturuldu (ProjectFlow for OpenProject, ücretsiz, uygulama)
- [ ] Adım 2: Mağaza listesi dolduruldu (ad, kısa/uzun açıklama, ikon, ekran görüntüleri)
- [ ] Adım 3: Uygulama içi ürün `projectflow_pro` oluşturuldu ve **Aktif**
- [ ] Adım 4: Gizlilik URL’i, e-posta, uygulama erişimi, reklam yok
- [ ] Adım 5: İçerik derecelendirmesi ve hedef kitle tamamlandı
- [ ] Adım 6: AAB yüklendi ve incelemeye gönderildi

---

**Paket adı (kontrol):** `com.openproject.openproject_mobile`  
**Versiyon:** 1.0.0 (1)

İnceleme birkaç saat ile birkaç gün sürebilir. Onay sonrası uygulama mağazada görünür.

---

## Tüm formlar – Tek sayfa özet (diğer bilgiler)

Aşağıda ekleme ve sonraki adımlardaki **tüm alanlar ve kopyala-yapıştır değerleri** tek yerde. Formu doldururken bu tablolardan kopyalayın.

---

### 1. Uygulama oluştur (Create app)

| Alan | Değer / Seçenek |
|------|------------------|
| Uygulama adı | `ProjectFlow for OpenProject` |
| Varsayılan dil | **Türkçe (Türkiye)** |
| Uygulama / Oyun | **Uygulama** |
| Ücretsiz / Ücretli | **Ücretsiz** |
| Reklam | **Hayır** |

---

### 2. Mağaza listesi (Store listing)

| Alan | Sınır | Değer |
|------|--------|--------|
| Uygulama adı | 30 kr | `ProjectFlow for OpenProject` |
| Kısa açıklama | 80 kr | `Ücretsiz indir; OpenProject'e bağlan. Pro tek seferlik satın alma ile gelişmiş özellikler.` |
| Uzun açıklama | 4000 kr | *(Aşağıdaki “Uzun açıklama metni” kutusundan kopyalayın.)* |
| Uygulama ikonu | 512×512 PNG | Dosya: `apps/mobile/assets/icon/app_icon.png` (gerekirse 512×512 yapın) |
| Ekran görüntüleri | En az 2 | Telefon; 16:9 veya 9:16 |
| Feature graphic | 1024×500 | İsteğe bağlı |

**Uzun açıklama metni (tümünü kopyalayın):**
```
ProjectFlow for OpenProject, OpenProject sunucunuza bağlanan mobil istemcidir.

ÜCRETSİZ SÜRÜM
• Uygulama ücretsiz indirilir; temel özellikler herkese açıktır.
• Bağlantı: Instance URL ve API anahtarı ile güvenli giriş
• İş paketleri: Listeleme, detay, hızlı güncellemeler
• Bildirimler: OpenProject bildirimlerinizi takip edin
• Zaman kayıtları: Temel time entry
• Projeler: Proje seçimi ve favoriler

PRO SÜRÜMÜ (ÜCRETLİ – UYGULAMA İÇİ SATIN ALMA)
Pro, tek seferlik uygulama içi satın alma ile açılır. Ödeme Google Play üzerinden yapılır; kredi kartı vb. uygulama tarafından saklanmaz. Pro ile: gelişmiş zaman takibi, özel kolonlar, takım zaman görünümü, Gantt ve daha fazlası. İlk kullanımda kısa deneme süresi sunulabilir.

OpenProject hesabınızdan API anahtarını alıp ProjectFlow for OpenProject ile bağlanarak işlerinizi mobilde yönetin.
```

---

### 3. Uygulama içi ürün (Pro) – Monetize → In-app products

| Alan | Değer |
|------|--------|
| Ürün kimliği *(Product ID)* | `projectflow_pro` *(aynen; değiştirmeyin)* |
| Ürün türü | **Tek seferlik** (One-time product) |
| Ürün adı | `ProjectFlow Pro` *(veya istediğiniz ad)* |
| Açıklama | `Gelişmiş zaman takibi, özel kolonlar, takım zaman görünümü, Gantt ve daha fazlası.` |
| Fiyat | Kendi seçiminiz (örn. TRY veya USD) |
| Durum | **Aktif** (Active) |

---

### 4. Politika ve iletişim

| Alan | Değer |
|------|--------|
| Gizlilik politikası URL’i | *(Kendi URL’iniz, örn. GitHub Pages)* `https://mehmetgedik.github.io/ProjectFlow/gizlilik-politikasi.html` |
| E-posta adresi | *(Kendi e-postanız)* örn. `mehmetgedik@gmail.com` |

---

### 5. Uygulama erişimi (App access)

| Soru | Seçenek / Metin |
|------|------------------|
| Tüm işlevler herkese açık mı? | **Hayır** |
| Giriş gerekli mi? | **Evet** |
| Açıklama *(kopyala-yapıştır)* | `Kullanıcılar kendi OpenProject instance'larına kendi API anahtarlarıyla giriş yapar. Test için kendi OpenProject sunucunuzda bir test hesabı kullanabilirsiniz.` |

---

### 6. Reklamlar (Ads)

| Soru | Seçenek |
|------|--------|
| Uygulama reklam içeriyor mu? | **Hayır** |

---

### 7. İçerik derecelendirmesi ve hedef kitle

| Alan | Seçenek |
|------|--------|
| İçerik derecelendirmesi | Anketi doldurun → genelde **Tüm yaşlar** veya düşük yaş |
| Hedef kitle / yaş | **18 ve üzeri** *(iş uygulaması)* |

---

### 8. Sürüm yükleme (Release)

| Alan | Değer |
|------|--------|
| AAB dosya yolu | `d:\MG\Project\Mobile\OpenProject\apps\mobile\build\app\outputs\bundle\release\app-release.aab` |
| Sürüm notları *(örnek)* | `İlk sürüm. OpenProject bağlantısı, iş paketleri, bildirimler, zaman kaydı. Pro sürümü uygulama içi satın alma ile.` |

---

### Teknik (kontrol)

| Alan | Değer |
|------|--------|
| Paket adı *(applicationId)* | `com.openproject.openproject_mobile` |
| Versiyon adı | `1.0.0` |
| Versiyon kodu | `1` |
