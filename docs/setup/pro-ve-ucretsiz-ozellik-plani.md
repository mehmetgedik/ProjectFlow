# Pro ve Ücretsiz Özellik Planı

Bu doküman, **indirmeleri düşürmeyecek** (ücretsiz kullanıcı deneyimi yeterli kalsın) ve **satışları düşürmeyecek** (Pro’ya geçiş için net değer sunulsun) şekilde hangi özelliklerin ücretsiz, hangilerinin Pro olacağını tanımlar. Analiz kuralına uygun: amaç, kapsam, kabul kriterleri ve iş kuralları; teknik “nasıl” yok.

---

## Amaç

- Ücretsiz kullanıcı: uygulamayı indirip günlük temel işini (iş paketleri, bildirim, zaman girişi, yorum) rahatça yapabilsin; deneyip beğenirse Pro’ya geçmeyi düşünsün.
- Pro kullanıcı: gelişmiş zaman yönetimi, ekler, ilişkiler, kayıtlı filtreler gibi “güç kullanıcı” özelliklerine erişsin; satın alma değeri net olsun.
- Sonuç: İndirme ve ilk kullanım memnuniyeti korunsun; Pro’ya dönüşüm teşvik edilsin.

---

## Kapsam

- Dahil: Hangi özelliklerin ücretsiz, hangilerinin Pro olduğunun listesi; karar kuralları; kabul kriterleri.
- Hariç: Fiyatlandırma, mağaza metni, teknik implementasyon.

---

## Ücretsiz kalacak özellikler (indirmeleri korumak)

Aşağıdakiler **Pro olmadan** kullanılabilir olmalıdır. Kullanıcı uygulamayı indirdiğinde “günlük işimi yapabiliyorum” hissini almalıdır.

| Alan | Ücretsizde olması gereken |
|------|----------------------------|
| **Bağlantı ve oturum** | Sunucu bağlantısı, giriş, oturum yönetimi, çıkış. |
| **Projeler** | Proje listesi, proje seçimi, favori projeler (temel). |
| **İş paketleri** | “Benim işlerim” listesi; iş paketi detayı; durum/atama gibi alanlarda hızlı güncelleme (tek tık / basit form). |
| **Yorum ve aktivite** | İş paketinde yorum/aktivite görüntüleme; yeni yorum ekleme. |
| **Bildirimler** | Bildirim listesi; bildirimi okundu işaretleme; temel liste görünümü. |
| **Zaman takibi (temel)** | Tek bir zaman kaydı ekleme (süre + isteğe bağlı açıklama); kaydın listelenmesi. |

**Kabul kriterleri (ücretsiz):**

- [ ] Ücretsiz kullanıcı sunucuya bağlanıp giriş yapabilmeli; proje seçip “benim işlerim” listesini görebilmeli.
- [ ] Ücretsiz kullanıcı iş paketi detayını açıp yorumları görebilmeli ve yeni yorum ekleyebilmeli.
- [ ] Ücretsiz kullanıcı bildirim listesini görüp bildirimi okundu işaretleyebilmeli.
- [ ] Ücretsiz kullanıcı en az bir zaman kaydı ekleyebilmeli ve eklediği kayıtları liste halinde görebilmeli.

---

## Pro’da olacak özellikler (satışları beslemek)

Aşağıdakiler **Pro satın alındığında** açılmalıdır. Pro olmayan kullanıcı bu özelliklere tıkladığında “Bu özellik Pro’da” mesajı ve Yükselt / Geri yükle seçenekleri sunulmalıdır. İstenen yerlerde **teaser** (içeriği soluk gösterip “Pro’yu satın al” ile yönlendirme) kullanılabilir.

| Alan | Pro’da olması gereken | Not |
|------|------------------------|-----|
| **Zaman takibi (gelişmiş)** | Zaman kayıtlarını düzenleme ve silme; raporlama / haftalık özet (varsa). | Teaser önerilir: ekran görünsün, kullanmak için Pro istenebilir. |
| **Kayıtlı filtreler / gelişmiş filtreleme** | Kullanıcının kaydettiği filtreler; proje/durum/atama bazlı özel listeler. | |
| **Ekler (attachments)** | Dosya veya kameradan ek yükleme; ekleri görüntüleme/indirme (gelişmiş görünüm). | Temel “ek var mı” bilgisi ücretsizde kalabilir; yükleme ve tam görüntüleme Pro. |
| **İş paketi ilişkileri** | Parent/child/related görüntüleme ve yönetim. | |
| **Bildirimler (gelişmiş)** | Gruplama, filtreleme, “okundu” yönetimi (toplu işlem vb.). | Temel liste ücretsiz; gelişmiş deneyim Pro. |
| **Gantt / ileri görünümler** | Gantt, dashboard benzeri ekranlar (P2). | |
| **Çoklu hesap / çoklu instance** | Birden fazla OpenProject sunucusu veya hesabı (P2). | |

**Kabul kriterleri (Pro):**

- [ ] Pro olmayan kullanıcı “zaman kaydı düzenle/sil” veya “gelişmiş zaman raporu” gibi Pro özelliğe girdiğinde kilit mesajı veya teaser ile Yükselt / Geri yükle görmeli.
- [ ] Pro kullanıcı zaman kayıtlarını düzenleyebilmeli ve silebilmeli (yetki ve API destekliyse).
- [ ] Pro kullanıcı kayıtlı filtreler, ek yükleme, iş paketi ilişkileri ve bildirimde gelişmiş deneyime erişebilmeli.
- [ ] Pro olmayan kullanıcı bu özelliklere doğrudan tam erişememeli; Yükselt ile satın alma akışına yönlendirilmelidir.

---

## Karar kuralları (dengenin korunması)

1. **P0 temel akış ücretsiz:** Bağlantı, proje seçimi, “benim işlerim”, iş paketi detay, yorum, temel bildirim, tek zaman kaydı ekleme — hepsi ücretsiz kalır. Böylece ilk indirme ve günlük kullanım memnuniyeti korunur.
2. **“Günlük işini görsün” ücretsiz:** Kullanıcı liste görsün, detay açsın, yorum yapsın, bildirim okusun, en az bir zaman girişi yapsın. Bu seviye ücretsizde kalır.
3. **“Güç kullanıcı / raporlama / ekler / ilişkiler” Pro:** Düzenleme/silme, kayıtlı filtreler, ek yükleme, ilişkiler, gelişmiş bildirim ve ileri görünümler Pro’da sunulur; satın alma değeri net olur.
4. **Teaser kullanımı:** Pro özellik ekranlarında (ör. gelişmiş time tracking) içerik soluk gösterilip “Pro’yu satın al” ile yönlendirme yapılabilir; kullanıcı ne kaçırdığını görsün, dönüşüm artabilsin.
5. **Yeni özellik sınıflandırması:** Yeni bir özellik eklenirken “günlük temel iş” mi yoksa “gelişmiş / raporlama / yönetim” mi olduğuna göre ücretsiz veya Pro’ya atanır; bu plandaki tablolar güncellenir.

---

## Hata ve sınır durumları

- Pro satın alındığı halde mağaza/cihaz nedeniyle Pro açılmazsa: “Satın almaları geri yükle” ve hata mesajı sunulur; tekrar deneme imkânı olur.
- Ücretsiz özellikler hiçbir koşulda Pro kontrolüne bağlanmaz; sunucu/API kapalı olsa bile ücretsiz tanımlı ekranlar yalnızca veri yoksa “veri yok” gibi genel mesaj gösterir, “Pro’ya yükselt” ile kilitlenmez.
- Store açıklamasında “temel özellikler ücretsiz, gelişmiş özellikler Pro ile” ifadesi kullanılır; hangi özelliklerin Pro olduğu bu planla uyumlu tutulur.

---

## Özet tablo

| Hedef | Nasıl korunur |
|------|----------------|
| **İndirmeleri düşürmemek** | Giriş, proje, iş paketleri (liste + detay + hızlı güncelleme), yorum, temel bildirim, tek zaman kaydı ekleme ücretsiz kalır; kullanıcı uygulamayı deneyip günlük işini yapabilir. |
| **Satışları düşürmemek** | Zaman kaydı düzenleme/silme, kayıtlı filtreler, ekler, ilişkiler, gelişmiş bildirim, Gantt/ileri görünümler, çoklu hesap Pro’da sunulur; değer net, teaser ile dönüşüm teşvik edilir. |

- **Satış ve kullanım:** Pro, uygulama içinde “En çok tercih edilen” olarak vurgulanır (yükselt ekranı, karşılaştırma, ücretsiz banner). Amaç: kullanıcıyı satın almaya yönlendirmek ve kullanımı artırmak.
- **İleride ek kademe:** Pro+ (Pro üstü) kademesi `PlanTier` içinde tanımlıdır; ayrı IAP ürünü ve özellik seti ile açılabilir.

Bu plan, [monetizasyon rehberi](monetizasyon-rehberi.md) ve [IAP ve Pro durumu planı](iap-ve-pro-durumu-plani.md) ile uyumludur. Hangi ekranın ProGate ile nasıl kilitleneceği [pro-premium-kilidi-yapisi.md](pro-premium-kilidi-yapisi.md) dokümanında yer alır.
