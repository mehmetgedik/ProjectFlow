# Google Play Console – Uygulama Oluştur / Store Listesi Formu

Bu doküman, **ProjectFlow** uygulamasını Play Console’da oluştururken ve mağaza listesini doldururken kopyala-yapıştır yapabileceğiniz tüm alanları içerir. **[ ]** içindeki yerleri kendi bilgilerinizle değiştirin.

---

## A. Uygulama oluştur (Create app)

| Alan | Değer |
|------|--------|
| **Uygulama adı** | ProjectFlow |
| **Varsayılan dil** | Türkçe (Türkiye) — veya İngilizce (ABD) |
| **Uygulama mı yoksa oyun mu?** | Uygulama |
| **Ücretsiz mi ücretli mi?** | Ücretsiz |
| **Bulgular, reklamlar vb.** | Hayır (reklam yok; isteğe göre işaretleyin) |

---

## B. Mağaza listesi (Store listing)

### Ana mağaza listesi (varsayılan dil)

| Alan | Karakter sınırı | Değer (kopyala-yapıştır) |
|------|------------------|--------------------------|
| **Uygulama adı** | 30 | ProjectFlow |
| **Kısa açıklama** | 80 | OpenProject hesabına bağlan; iş paketleri, bildirimler ve zaman kayıtları. |
| **Uzun açıklama** | 4000 | Aşağıdaki “Uzun açıklama metni” kutusundan kopyalayın. |

**Uzun açıklama metni (Türkçe):**
```
ProjectFlow, OpenProject sunucunuza bağlanan mobil istemcidir.

• Bağlantı: Instance URL ve API anahtarı ile güvenli giriş
• İş paketleri: Listeleme, detay, hızlı güncellemeler
• Bildirimler: OpenProject bildirimlerinizi takip edin
• Zaman kayıtları: Hızlı time entry
• Projeler: Proje seçimi ve favoriler

OpenProject hesabınızdan API anahtarını alıp ProjectFlow ile bağlanarak işlerinizi mobilde yönetin.
```

**Uzun açıklama (İngilizce) – ikinci dil ekliyorsanız:**
```
ProjectFlow is the mobile client for your OpenProject server.

• Connect: Sign in with your instance URL and API key
• Work packages: List, view details, quick updates
• Notifications: Keep track of your OpenProject notifications
• Time entries: Quick time logging
• Projects: Switch projects and use favorites

Get your API key from OpenProject and manage your work on the go with ProjectFlow.
```

---

## C. Grafikler

| Alan | Gereksinim | Projedeki dosya / not |
|------|------------|---------------------------|
| **Uygulama ikonu** | 512 x 512 px, 32-bit PNG | `apps/mobile/assets/icon/app_icon.png` — gerekirse 512x512’ye kırpın/ölçekleyin. |
| **Feature graphic** | 1024 x 500 px (isteğe bağlı) | Yoksa boş bırakılabilir veya sonra eklenir. |
| **Ekran görüntüleri (telefon)** | En az 2 adet; 16:9 veya 9:16 önerilir | Emülatör veya cihazda uygulamayı açıp ekran görüntüsü alın (en az 2 farklı ekran). |

---

## D. Kategorilendirme

| Alan | Değer |
|------|--------|
| **Uygulama kategorisi** | İş (Business) veya Verimlilik (Productivity) |
| **İçerik derecelendirmesi** | Anketi doldurun; genelde “Tüm yaşlar” veya düşük yaş aralığı çıkar. |
| **Hedef kitle (yaş)** | 18 ve üzeri (iş uygulaması) — anket sonucuna göre ayarlayın. |

---

## E. İletişim ve politika

| Alan | Değer |
|------|--------|
| **E-posta adresi** | [Geliştirici / destek e-posta adresiniz] |
| **Gizlilik politikası URL’i** | [Gizlilik politikası sayfanızın tam URL’i] |

**Gizlilik politikası URL’i nasıl oluşur?**
- `docs/setup/gizlilik-politikasi.html` dosyasını bir web sunucusuna veya GitHub Pages’e yükleyin.
- Örnek: `https://mehmetgedik.github.io/ProjectFlow/gizlilik-politikasi.html` veya kendi sitenizde bir sayfa.
- HTML dosyasında “[Buraya e-posta adresinizi yazın]” kısmını kendi e-posta adresinizle değiştirmeyi unutmayın.

---

## F. Uygulama erişimi (App access)

| Soru | Önerilen yanıt |
|------|-----------------|
| Tüm işlevler herkese açık mı? | Hayır — OpenProject hesabı (API anahtarı) gerekir. |
| Giriş bilgisi gerekli mi? | Evet. |
| Giriş bilgileri (test için) | “Kullanıcılar kendi OpenProject instance’larına kendi API anahtarlarıyla giriş yapar. Test için kendi OpenProject sunucunuzda bir test hesabı kullanabilirsiniz.” — Gerekirse test kullanıcı adı/şifre veya demo instance bilgisi ekleyin (güvenli bir şekilde). |

---

## G. Reklamlar (Ads)

| Soru | Değer |
|------|--------|
| Uygulama reklam içeriyor mu? | Hayır |

---

## H. Teknik bilgiler (kontrol için)

| Alan | Değer |
|------|--------|
| **Paket adı (applicationId)** | com.openproject.openproject_mobile |
| **Versiyon adı (versionName)** | 1.0.0 |
| **Versiyon kodu (versionCode)** | 1 |
| **AAB dosyası** | `apps/mobile/build/app/outputs/bundle/release/app-release.aab` |

---

## Yapılacaklar özeti

1. **[ ]** ile işaretli yerleri doldurun: e-posta, gizlilik politikası URL’i.
2. Gizlilik politikası sayfasını yayınlayın; `gizlilik-politikasi.html` içindeki iletişim e-postasını güncelleyin.
3. Uygulama ikonunu (512x512) ve en az 2 ekran görüntüsünü hazırlayın.
4. Play Console’da “Uygulama oluştur” ve “Mağaza listesi” adımlarında yukarıdaki değerleri kopyalayıp yapıştırın.
5. İçerik derecelendirmesi anketini doldurun.
6. AAB’yi yükleyin (Production veya Internal/Closed testing).

Bu dosyayı yayın sürecinde güncelleyebilirsiniz (ör. final e-posta, gizlilik URL’i, ekran görüntüleri).
