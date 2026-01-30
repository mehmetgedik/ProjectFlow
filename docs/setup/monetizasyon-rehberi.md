# ProjectFlow – Monetizasyon Rehberi (Bireysel Geliştirici)

Bu doküman, **bireysel geliştirici** olarak uygulamanın belirli kısımlarını ücretli sunmak ve gelir elde etmek için seçenekleri ve izlenebilecek yöntemi özetler. Teknik mimari veya kütüphane seçimi değil; kapsam, modeller ve pratik adımlar odaklıdır.

**Önemli:** İki ayrı uygulama (biri ücretsiz, biri Pro) yüklemeniz gerekmez. **Tek uygulama** yayınlanır; “Pro” **uygulama içi satın alma (IAP)** ile açılır. Pro olup olmadığı **Google Play** üzerinden yönetilir; kendi sunucunuz veya API’niz zorunlu değildir. Detaylı plan: [IAP ve Pro durumu planı](iap-ve-pro-durumu-plani.md).

---

## 1. Ücretli yapılabilecek kısımlar (öneri)

Uygulamanızın mevcut kapsamına göre mantıklı premium adayları:

| Kısım | Açıklama | Neden ücretli mantıklı |
|-------|----------|------------------------|
| **Time tracking gelişmiş** | Zaman kayıtlarını düzenleme/silme, raporlama, haftalık özet | İş kullanımında değer yüksek; P1 kapsamında |
| **Gelişmiş filtreleme / saved filters** | Kayıtlı filtreler, proje/ durum/atama bazlı özel listeler | Günlük kullanımı hızlandırır; P1 |
| **Ekler (attachments)** | Dosya/kamera ile ek yükleme ve görüntüleme | Web parity’de önemli; P1 |
| **Work package ilişkileri** | Parent/child/related görüntüleme ve yönetim | Proje yönetimi için kritik; P1 |
| **Bildirim gelişmiş** | Gruplama, filtreleme, “okundu” yönetimi | Yoğun kullanıcı için fark yaratır |
| **Gantt / ileri görünümler** | Gantt, dashboard benzeri ekranlar | P2; power user özelliği |
| **Çoklu hesap / çoklu instance** | Birden fazla OpenProject sunucusu veya hesabı | Kurumsal/küçük ekip senaryosu |

**Ücretsiz bırakılması önerilen (giriş engeli olmamalı):**

- Bağlantı ve giriş (auth)
- Temel iş paketleri listesi ve detay
- Temel bildirimler
- Tek proje, temel time entry (tek kayıt ekleme)

Böylece “deneyip beğenirse premium alır” modeli çalışır.

---

## 2. Ücretlendirme modelleri

### 2.1 Freemium (önerilen)

- Temel özellikler ücretsiz, yukarıdaki gelişmiş özellikler ücretli.
- **Uygulama içi satın alma (In-App Purchase – IAP)** ile sunulur; ödeme Google/Apple üzerinden olur, siz sadece “bu kullanıcı premium mu?” kontrolü yaparsınız.

**Avantaj:** Kullanıcı uygulamayı deneyebilir; beğenirse tek seferlik veya abonelikle öder.  
**Dezavantaj:** Store komisyonu (genelde %15–30) düşer.

### 2.2 Tek seferlik satın alma (one-time)

- “Pro” veya “Premium” paketi tek ödeme.
- Kullanıcı bir kez öder, tüm premium özelliklere süresiz erişir.

**Avantaj:** Anlaşılır, tahmin edilebilir.  
**Dezavantaj:** Uzun vadede gelir tek seferlik kalır; abonelik kadar tekrarlayan gelir getirmez.

### 2.3 Abonelik (subscription)

- Aylık/yıllık “Premium” aboneliği.
- Yıllık ödemede indirim vererek yıllık planı özendirebilirsiniz.

**Avantaj:** Düzenli gelir; bireysel geliştirici için bütçe planlaması kolaylaşır.  
**Dezavantaj:** İptal oranları olabilir; fiyatı ve değeri net göstermek gerekir.

### 2.4 Hibrit (önerilen başlangıç)

- **Tek seferlik “Pro” satın alma** ile başlayın: basit, fatura/vergi tarafında daha az karmaşa.
- İleride kullanıcı talebi ve metrikler (dönüşüm, iptal) netleşince **abonelik** ekleyebilirsiniz (aynı premium özellik seti, farklı ödeme tipi).

---

## 3. Bireysel geliştirici olarak izlenecek yöntem

### 3.1 Mağaza tarafı (Google Play)

- **Google Play Developer hesabı:** Tek seferlik kayıt ücreti (bir kerelik). Bireysel geliştirici olarak kayıt yapabilirsiniz; şirket zorunlu değil.
- **Ödemeler:** In-App Purchase kullanırsanız ödeme Google üzerinden toplanır; siz sadece “premium” kilidini uygulama içinde açarsınız.
- **Gelir ödemesi:** Google, geliri belirli periyotlarla size öder (bankaya havale vb.). Ülkeye göre minimum ödeme eşiği ve vergi formu (W-8BEN vb.) istenir.

**Pratik adım:** Play Console’da “Monetize” → “Products” bölümünden uygulama içi ürünler (tek seferlik veya abonelik) tanımlanır. Uygulama tarafında `in_app_purchase` (Flutter paketi) ile bu ürünleri listeleyip satın alma akışını yönetirsiniz.

### 3.2 Vergi ve resmi kuruluş

- **Şahıs olarak:** Gelir vergisi mükellefi olursunuz. Uygulama gelirini “diğer gelir” veya “ticari kazanç” kapsamında beyan etmeniz gerekebilir. Ülkenize göre eşik ve oranlar değişir; bir muhasebeci/vergi danışmanı ile bir kez netleştirmeniz iyi olur.
- **Firma kurmadan:** Küçük ölçekte başlayıp sadece mağaza (Google/Apple) üzerinden gelir almak mümkündür. Fatura genelde mağaza tarafından kesilir (kullanıcıya); sizin ekstra fatura kesmeniz çoğu zaman gerekmez. Yine de yerel mevzuata göre “gelir beyanı” konusunu danışın.
- **İleride:** Gelir büyürse şahıs şirketi veya limited şirket kurup geliri oraya taşımak mantıklı olabilir.

### 3.3 Kullanıcıya sunum

- Store açıklamasında “temel özellikler ücretsiz, gelişmiş özellikler Pro ile” ifadesi kullanılabilir.
- Uygulama içinde premium özelliğe tıklandığında “Bu özellik Pro sürümünde” mesajı + “Yükselt” butonu ile tek seferlik veya abonelik satın alma ekranına yönlendirin.
- Fiyat: Rakip mobil proje/yönetim uygulamalarına ve hedef kitlenize (bireysel/küçük ekip) göre makul bir tek seferlik fiyat (ör. 5–15 USD) veya düşük aylık abonelik (ör. 1–2 USD/ay) ile başlamak genelde iyi bir denge olur.

---

## 4. Önerilen adım sırası

1. **Hangi özelliklerin premium olacağını** yukarıdaki tabloya göre netleştirin (ilk sürümde 1–2 özellikle başlayabilirsiniz).
2. **Google Play Console** üzerinden IAP ürünlerini oluşturun (tek seferlik “ProjectFlow Pro” gibi).
3. **Flutter tarafında** `in_app_purchase` ile satın alma akışını ekleyin; satın alma doğrulandığında yerel bir bayrak veya backend’de (varsa) lisans bilgisini saklayın.
4. **Premium özellik ekranlarında** bu bayrağa göre “Pro’ya yükselt” veya özelliği açık gösterin.
5. **Gizlilik politikası ve store açıklamasını** “ücretsiz + uygulama içi satın alma” olacak şekilde güncelleyin.
6. **Vergi/gelir beyanı** için yerel mevzuata göre (tercihen muhasebeci ile) plan yapın; gelir küçük olsa bile kayıt tutun.

---

## 5. Özet

| Konu | Öneri |
|------|--------|
| Ücretli kısımlar | Time tracking gelişmiş, saved filters, ekler, WP ilişkileri, gelişmiş bildirimler, Gantt/ileri görünümler, çoklu hesap |
| Model | Freemium + tek seferlik “Pro” ile başlama; ihtiyaç olursa abonelik ekleme |
| Ödeme | Google Play In-App Purchase (Flutter: `in_app_purchase`) |
| Resmi kuruluş | Başlangıçta şahıs yeterli; gelir beyanı ve vergi için danışmanlık alın |
| İlk adım | 1–2 premium özellik seçip IAP + uygulama içi kilidi implemente edin |

Bu rehber, kapsam ve yöntem odaklıdır; teknik implementasyon detayı (ör. hangi paket, nasıl doğrulama) ayrı bir teknik taslakta ele alınabilir.
