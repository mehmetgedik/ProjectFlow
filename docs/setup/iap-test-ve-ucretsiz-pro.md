# IAP Test ve Belirli Kişilere Ücretsiz Pro Verme

Bu doküman iki konuyu planlar:

1. **Satın alma yapmadan Pro testleri nasıl yapılır** (License testers, internal testing, sandbox).
2. **Belirli kişilere (örn. kendi ekibinize) ödeme yapmadan Pro vermek** (Promo kodları, isteğe bağlı “ekip build’i”).

---

## En mantıklı seçenek: Promo kodları

Belirli kişilere (ekip, algoritma ile ürettiğiniz kodları verdiğiniz kişiler) **Store’dan indirilen uygulamada** ücretsiz Pro vermek için **en mantıklı yöntem promo kodlarıdır**.

| Neden | Açıklama |
|-------|----------|
| Tek dağıtım | Herkes aynı uygulamayı Store’dan indirir; ayrı “ekip build’i” yönetmezsiniz. |
| Resmi kanal | Google’ın sunduğu mekanizma; sunucu/API gerekmez. |
| Kontrol sizde | Kodu kime verdiğinizi siz belirlersiniz; kod sayısı sınırlı olabilir. |
| Kullanıcı deneyimi | Kullanıcı kodu girer, Pro tanınır; uygulama tarafında ekstra “Pro bypass” mantığı yazmazsınız. |

“Ekip build’i” (Pro her zaman açık APK) sadece Store’a hiç çıkmayan, sadece sizin dağıttığınız bir sürüm istiyorsanız alternatiftir; çoğu senaryoda **promo kodu yeterli ve daha sade**dir.

Aşağıda promo kodlarının **detaylı notu** yer alıyor.

---

## 1. Satın alma yapmadan Pro nasıl test edilir?

Gerçek para ödemeden uygulama içi satın alma (IAP) ve Pro ekranlarını test etmek için Google Play’in sağladığı yöntemler yeterlidir.

### 1.1 License testers (lisans test kullanıcıları)

- **Ne:** Play Console’da uygulamanızın **License testing** bölümüne e-posta adresleri eklersiniz. Bu hesaplar **test kullanıcısı** sayılır.
- **Nasıl:** Play Console → Uygulamanız → **Setup** → **License testing** → “Add license testers” ile Gmail adresleri ekleyin (kendi hesabınız, ekibinizin hesapları).
- **Sonuç:** Bu hesaplarla uygulamada “Pro satın al” dediğinizde **gerçek ödeme alınmaz**. Sandbox modunda satın alma tamamlanır; uygulama Pro’yu açık görür. İstediğiniz kadar “satın al / iptal / tekrar al” deneyebilirsiniz.
- **Nerede çalışır:** Uygulamayı **internal testing** veya **closed testing** track’ine yükleyip bu test hesaplarıyla indirdiğinizde IAP sandbox’ta çalışır. Aynı hesaplar production’da normal kullanıcı gibi davranır (orada gerçek satın alma olur).

**Özet:** Pro testleri için **para ödemeden** kendi ve ekibinizin Gmail hesaplarını “License testers” olarak ekleyin; bu hesaplarla internal/closed test build’inde satın alma akışını ve Pro ekranlarını test edin.

### 1.2 Internal testing track

- **Ne:** Play Console’da **Internal testing** track’i oluşturulur; buraya yüklediğiniz build’i sadece siz ve eklediğiniz testçiler indirebilir.
- **Nasıl:** Release → Testing → Internal testing → Testers ekleyin (e-posta listesi veya e-posta listesi linki). Build yükleyin; testçiler linkten veya Play Store’dan “Internal test” sürümünü indirir.
- **IAP:** Bu track’te IAP **sandbox** modunda çalışır. License testers olarak eklediğiniz hesaplarla giriş yapıldığında satın alma gerçek para çekmez.
- **Kullanım:** Pro özellikleri ve “Satın al / Geri yükle” akışını gerçek cihazda, gerçek Billing API ile test etmek için internal testing + license testers yeterlidir.

### 1.3 Emülatör / debug build’te dikkat

- Emülatörde veya “debug” build’te Google Play (ve Billing) bazen tam çalışmayabilir. **Gerçek cihaz + internal testing build** ile test etmek daha güvenilirdir.
- Test için: Gerçek cihaza internal test sürümünü yükleyin, cihazda License tester hesabıyla Google’a giriş yapın, uygulamada Pro satın alın; ödeme istenmez, Pro açılır.

**Kabul kriteri:** License testers listesindeki hesaplarla, internal test build’inde, gerçek para ödemeden Pro satın alma akışı tamamlanır ve Pro özellikleri açılır.

---

## 2. Belirli kişilere (örn. kendi ekibinize) ödeme yapmadan Pro vermek

“Kendi ekibime / belirli kişilere Pro’yu ücretsiz vermek istiyorum” senaryosu için seçenekler:

### 2.1 Promo kodları (önerilen, production için)

- **Ne:** Google Play’de uygulama içi ürünler (tek seferlik veya abonelik) için **promosyon kodu** oluşturabilirsiniz. Kod, ürünü bedava verir.
- **Nasıl:** Play Console → Uygulamanız → **Monetize** → **In-app products** → Pro ürününüz → **Promo codes** (veya ilgili kampanya/promo bölümü). Kod oluşturur, indirirsiniz (ör. CSV). Bu kodları ekibinize e-posta veya başka kanalla verirsiniz.
- **Kullanıcı tarafı:** Kullanıcı Play Store’da (veya uygulama içi “Kod kullan” akışında, destekliyorsa) kodu girer; Pro ürünü bu hesaba **ücretsiz** tanınır. Sonrasında uygulama normal şekilde “past purchases” ile Pro’yu görür.
- **Avantaj:** Kendi sunucunuz yok; her şey Google üzerinden. Ekibinize veya seçtiğiniz kişilere sınırlı sayıda kod verirsiniz.
- **Sınır:** Promo kodları genelde sınırlı sayıda üretilir; kim ne kullandı sizin takibinize kalmayabilir (sadece kod dağıtımını siz kontrol edersiniz).

**Özet:** Kendi ekibinize veya belirli kişilere **ödeme yapmadan Pro** vermek için Play Console’dan Pro ürünü için **promo kodu** oluşturup bu kodları dağıtın; kod kullanan hesap Pro’ya sahip olur.

### 2.2 License testers (sadece test için)

- License testers **test build’lerinde** (internal/closed) “satın al” dediklerinde para ödenmez; ama bu “test” amaçlıdır.
- **Production** (canlı) sürümde aynı hesaplar normal kullanıcıdır; orada bedava Pro otomatik değildir. Yani “ekibe kalıcı ücretsiz Pro” için license testers **yetmez**; bunun yerine **promo kodu** veya aşağıdaki “ekip build’i” kullanılır.

### 2.3 “Ekip build’i” / Pro her zaman açık build (isteğe bağlı)

- **Fikir:** Store’a yüklediğiniz **production** uygulama IAP ile Pro açar. Ayrıca **sadece dağıtım için** kullandığınız bir build’te (ör. debug, veya farklı bir flavor) “Pro” her zaman **açık** kabul edilir; satın alma ekranı gösterilmez veya atlanır.
- **Nasıl:**  
  - Build türüne veya bir **flavor**’a göre (ör. `team`, `dev`) `isPro` değişkeni **her zaman true** döner.  
  - Veya derleme zamanında bir **const / env** ile “Pro bypass” açılır; bu build **Play Store’a yüklenmez**, sadece APK olarak veya internal track’te ekip linkiyle dağıtılır.
- **Kim kullanır:** Sadece siz ve ekibiniz bu özel APK’yı veya internal linki kullanır. Normal kullanıcılar Store’dan indirdiği için IAP’lı sürümü kullanır.
- **Avantaj:** Sunucu veya promo kodu yönetmeye gerek kalmaz; ekip tek build’i yükler, Pro hep açıktır.  
- **Dikkat:** Bu build’in **Store’da yayınlanmaması** gerekir (farklı versionCode veya sadece internal testte kalması, Store’a production olarak gönderilmemesi).

**Özet:** Algoritma/ekip için “ödeme yapmadan Pro” istiyorsanız:  
- **Production’da (Store’dan indiren herkes):** Promo kodu ile belirli kişilere ücretsiz Pro.  
- **Sadece kendi ekibiniz:** İsterseniz ek olarak “Pro her zaman açık” olan ayrı bir build (APK veya internal test) dağıtabilirsiniz; bu build Store’a production olarak çıkmaz.

---

## 3. Promo kodları – detaylı not

Bu bölüm, “belirli kişilere ücretsiz Pro vermek” için promo kodlarının mantığını, adımlarını ve uygulama tarafındaki davranışı tek yerde toplar.

### 3.1 Mantık özeti

- **Siz:** Play Console’da Pro in-app ürünü için promo kodları oluşturursunuz. Kodlar, o ürünü **bedava** verir (ödeme alınmaz).
- **Kullanıcı:** Kodu Play Store üzerinden (veya uygulama içinde “promo kodu kullan” varsa orada) girer. Google, o Google hesabına Pro ürününü **satın alınmış** gibi tanır.
- **Uygulama:** Pro durumunu her zaman “Google Play’den satın almaları sor” ile öğrenir. Kod kullanan kullanıcı için Google “Pro satın alınmış” döner; uygulama ekstra bir “promo kodu” mantığı yazmaz; sadece IAP / past purchases kullanır.

Yani: Promo kodu = Google nezdinde **ücretsiz satın alma**. Uygulama tarafında tek kaynak yine **Billing / past purchases**’tır.

### 3.2 Play Console’da promo kodu oluşturma

| Adım | Ne yapılır |
|------|-------------|
| 1 | Play Console → Uygulamanız → **Monetize** → **In-app products** (veya **Subscriptions** abonelikse). |
| 2 | Pro ürününüzü seçin (örn. `projectflow_pro`). Ürün **Active** olmalı. |
| 3 | İlgili ürün sayfasında **Promo codes** / **Promotional codes** (veya **Campaigns** altında promo) bölümüne girin. (Arayüz sürüme göre “Monetize” → “Campaigns” veya ürün detayında “Promo codes” olabilir.) |
| 4 | “Create codes” / “Generate codes” ile kod oluşturun. Genelde **kaç adet** ve **bitiş tarihi** (opsiyonel) seçilir. |
| 5 | Kodları **indirin** (CSV veya liste). Bu listeyi güvende tutun; kodları sadece vermek istediğiniz kişilere iletin. |

**Not:** Promo kodları bazen **tek seferlik ürün** ve **abonelik** için ayrı arayüzlerde olabilir; Play Console’daki güncel menüyü takip edin. Abonelik kodları genelde “X gün ücretsiz” veya “X ay bedava” şeklinde de tanımlanabilir.

### 3.3 Kullanıcı kodu nasıl kullanır?

| Yol | Açıklama |
|-----|----------|
| **Play Store (telefon)** | Kullanıcı **Play Store** uygulamasını açar → Menü (veya profil) → **Ödeme ve abonelik** → **Redeem** / **Kod kullan** (veya **Promosyon kodu**). Kodu girer; Pro ürünü bu Google hesabına tanınır. |
| **Play Store (web)** | play.google.com → Giriş → Hesap → **Redeem a gift card or promotional code**. Kodu girer. |
| **Uygulama içi** | Uygulamanızda “Promo kodu gir” alanı sunarsanız, kullanıcı kodu orada girebilir; ancak **gerçek tanıma yine Google Billing** üzerinden olur. Flutter’da `in_app_purchase` ile “redeem code” akışı destekleniyorsa (platform/API’ye göre) uygulama içinden de tetiklenebilir; yoksa kullanıcıyı “Play Store’da kod kullan” diye yönlendirirsiniz. |

Kod kullanıldıktan sonra **aynı kod tekrar kullanılamaz**. Her kod genelde **bir kez** kullanılır (tek seferlik ürün için).

### 3.4 Kod kullandıktan sonra uygulamada ne olur?

- Kullanıcı kodu Play Store’da kullandığı anda, Google o hesaba Pro ürününü **satın alınmış** olarak işler.
- Uygulama **ekstra bir şey yapmaz**. Uygulama açıldığında veya “Satın almaları geri yükle” denildiğinde **past purchases** sorgulanır; Google “Pro satın alınmış” döner; uygulama `isPro = true` yapar ve Pro özelliklerini açar.
- Yani: **Promo kodu = Google’da ücretsiz satın alma**. Uygulama tarafında fark yok; sadece IAP / restore akışı kullanılır (bkz. [IAP ve Pro durumu planı](iap-ve-pro-durumu-plani.md)).

### 3.5 Bir kod kaç kişi kullanabilir?

- Genelde **her promo kodu bir kez** kullanılır; bir kod bir Google hesabına tanındıktan sonra tekrar kullanılamaz.
- 10 kişiye ücretsiz Pro vermek istiyorsanız **en az 10 ayrı kod** oluşturup her birini bir kişiye vermeniz gerekir. Kodları kimin kullandığını Google detaylı göstermeyebilir; siz sadece “bu kodu kime gönderdim” listesini kendiniz tutabilirsiniz.

### 3.6 Son kullanma / geçerlilik

- Play Console’da kod oluştururken **bitiş tarihi** verilebiliyorsa, o tarihten sonra kod kullanılamaz.
- Kod **kullanıldıktan** sonra Pro (tek seferlik ürünse) **kalıcı**dır; abonelik kodları ise tanımlandığı süre kadar (örn. 1 ay bedava) geçerli olur.

### 3.7 Sizin yapmanız gerekenler (özet)

| Siz | Not |
|-----|-----|
| Pro in-app ürününü tanımlayın | Play Console → In-app products → `projectflow_pro` (veya seçtiğiniz id). |
| Promo kodları oluşturun | Aynı ürün için Promo codes bölümünden adet ve (isteğe bağlı) bitiş tarihi ile. |
| Kodları indirip güvende tutun | CSV/liste; sadece ekibinize veya hedef kişilere iletin. |
| Uygulama tarafında | Ekstra “promo kodu” state’i tutmanız gerekmez; Pro = Billing’den gelen “past purchases” ile aynı. |
| Kullanıcıya bilgi | “Pro’yu ücretsiz almak için bu kodu Play Store’da kullanın: …” ve gerekirse Play Store’da kod girme adımlarını kısaca anlatın. |

### 3.8 İsteğe bağlı: Kod kullanım takibi

- Google, bazı raporlarda promo kod kullanımını özetleyebilir (kaç kod kullanıldı vb.). Kimin hangi kodu kullandığını uygulama içinde görmek için **kendi sunucunuz** gerekir (kullanıcı kodu uygulama içinde girip sizin API’nize gönderir; siz eşleştirirsiniz). Sunucusuz çalışıyorsanız takip sadece “kime hangi kodu gönderdim” listesiyle sizin elinizde olur.

---

## 4. Özet tablo

| Amaç | Yöntem | Nerede / kime |
|------|--------|-----------------|
| Satın alma yapmadan Pro **testi** | License testers + Internal testing | Kendiniz ve testçiler; test build’inde IAP sandbox, para çekilmez. |
| Belirli kişilere **kalıcı ücretsiz Pro** (Store sürümünde) | Promo kodları | Kod verdiğiniz kişiler; kod kullanınca Pro tanınır. |
| Ekip için **her zaman Pro**, Store’a çıkmayan sürüm | “Ekip build’i” (Pro bypass) | Sadece sizin dağıttığınız APK / internal link; Play Store production’da değil. |

---

## 5. Kabul kriterleri (test edilebilir)

- License testers listesindeki hesaplarla, internal test build’inde, gerçek ödeme yapılmadan Pro satın alma akışı tamamlanır ve Pro özellikleri açılır.
- Promo kodu kullanan hesap, uygulama açıldığında veya “Satın almaları geri yükle” sonrası Pro erişimine sahip olur.
- “Ekip build’i” kullanılıyorsa: Bu build’de Pro her zaman açıktır; bu build Play Store production’da yayınlanmaz.

Bu doküman, [IAP ve Pro durumu planı](iap-ve-pro-durumu-plani.md) ile birlikte kullanılır; test ve ücretsiz Pro senaryolarını tamamlar.
