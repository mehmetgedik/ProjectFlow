# IAP ve Pro Durumu Yönetimi – Detaylı Plan (Sunucusuz)

Bu doküman dört şeyi netleştirir:

1. **İki uygulama değil, tek uygulama:** Play Store’da tek listing; “Pro” ayrı bir uygulama değil, uygulama içi satın alınan bir ürün.
2. **Pro olup olmadığı nasıl bilinir:** Tamamen **Google Play** üzerinden (ve isteğe bağlı **yerel deneme süresi**); sizin sunucunuz, web siteniz veya API’niz gerekmez.
3. **Uygulama içinde Pro durumunun nasıl yönetileceği:** Akışlar, veri kaynağı, çevrimdışı davranış, restore.
4. **Belirli süre deneme (trial) nasıl verilir:** İki yöntem (abonelik + Google ücretsiz denemesi / tek seferlik Pro + yerel deneme).

---

## 1. Tek uygulama, iki uygulama değil

| Yanlış anlama | Doğru model |
|---------------|-------------|
| Play Store’a “ProjectFlow” (ücretsiz) ve “ProjectFlow Pro” (ücretli) diye **iki ayrı uygulama** yüklemek | Play Store’da **tek uygulama**: “ProjectFlow”. Uygulama **ücretsiz indirilir**. “Pro” özellikler **uygulama içi satın alma (IAP)** ile açılır. |
| Pro’nun ayrı bir APK / ayrı listing olması | Pro, **aynı uygulamanın içinde** satın alınan bir **ürün** (product). Kullanıcı tek uygulamayı indirir; ister ücretsiz kullanır, ister uygulama içinden “Pro’yu satın al” der. |

**Sonuç:**  
- **Bir tane** Google Play listing.  
- **Bir tane** uygulama (tek APK / App Bundle).  
- Pro = bu uygulamanın içinde tanımlı bir **In-App Product** (tek seferlik veya abonelik).

---

## 2. Pro olup olmadığını kim, nerede tutar? (Sunucu gerekmez)

Pro bilgisi **Google’ın sunucularında** tutulur. Sizin bir web siteniz, sunucunuz veya API’niz olması gerekmez.

### 2.1 Veri nerede?

| Bilgi | Nerede tutulur | Sizin yapmanız gereken |
|-------|-----------------|-------------------------|
| “Bu Google hesabı Pro satın aldı mı?” | **Google Play** (Google sunucuları) | Hiçbir şey. Sadece uygulama içinden “bu kullanıcı Pro ürününe sahip mi?” diye sormak. |
| Satın alma geçmişi, iptal, yenileme | **Google Play** | Yok. Abonelik iptal/yenileme de Google tarafından yönetilir. |
| Ödeme, fatura, para | **Google Play** | Play Console’dan gelir takibi; kullanıcıya fatura Google tarafından. |

### 2.2 Akış (özet)

```
[Kullanıcı cihazı]  ←→  [Sizin uygulamanız]  ←→  [Google Play Billing API]  ←→  [Google sunucuları]
                              ↑
                    “Pro ürünü satınlı mı?”
                    “Satın al” / “Restore”
                    Sonuç: evet/hayır
```

- Uygulama, **Google Play Billing** (Flutter’da `in_app_purchase` paketi) ile konuşur.
- Billing API, Google sunucularıyla konuşur; satın alma ve “bu hesap bu ürünü aldı mı?” bilgisi orada.
- Siz arada **kendi backend’iniz olmadan** sadece Billing API’ye soru sorar, satın alma/restore tetiklersiniz.

**Özet:** Pro olup olmadığı **tamamen Google Play üzerinden** yönetilir; sunucu/API zorunlu değil.

---

## 3. Pro durumunu uygulama içinde nasıl kullanacaksınız?

### 3.1 Kaynak of truth (tek doğru kaynak)

- **Asıl kaynak:** Google Play Billing’den alınan “past purchases” / “purchase details”.  
  Yani: “Bu cihazda giriş yapan Google hesabı için `projectflow_pro` (veya tanımladığınız product id) satın alınmış mı?” (Abonelikte “deneme aktif” veya “abonelik aktif” de Pro sayılır.)
- **İsteğe bağlı ikinci kaynak (deneme):** Belirli süre deneme veriyorsanız, **Yöntem B** ile yerel `trial_ends_at` de Pro kararına dahil edilir: isPro = satın alma VEYA şimdi < trial_ends_at. Bkz. bölüm 5.
- Uygulama bu bilgiyi:
  - Uygulama açılışında veya Pro gerektiren ekrana girildiğinde **sorgular** (ve yerel trial varsa onu da okur).
  - İsterseniz **yerel olarak cache’ler** (aşağıda); ama “Pro mu?” kararı Google verisi (ve isteğe bağlı yerel deneme) ile türetilir.

### 3.2 Ne zaman “Pro mu?” sorusu sorulur?

| Zaman | Amaç |
|-------|------|
| Uygulama ilk açılışında / ana ekrana gelindiğinde | Mevcut satın almaları yükle (restore), Pro durumunu güncelle. |
| Kullanıcı “Pro’ya yükselt” veya “Satın al” dediğinde | Satın alma akışını başlat; tamamlanınca Pro’yu aç. |
| Kullanıcı “Satın almaları geri yükle” dediğinde | Yine Google’dan past purchases çek; Pro varsa kilidi kaldır. |
| Premium özelliğe (örn. gelişmiş time tracking) girildiğinde | Pro değilse “Bu özellik Pro’da” + “Yükselt” göster; Pro ise özelliği aç. |

Bu sayede **arka planda kendi API’niz olmadan** Pro durumu sürekli Google’a göre güncel kalır.

### 3.3 Yerel cache (isteğe bağlı, çevrimdışı için)

- **Amaç:** İnternet yokken “Pro’yu az önce açtım” deneyimini bozmamak; gereksiz tekrarlayan sorguyu azaltmak.
- **Ne yapılır:** Google’dan “Pro satın alındı” sonucu geldiğinde, uygulama bunu **yerel** olarak (ör. `shared_preferences` veya `flutter_secure_storage`) “Pro: true” + isteğe bağlı son doğrulama zamanı olarak kaydeder.
- **Kural:**  
  - Cache sadece **Google’dan gelen olumlu yanıt sonrası** güncellenir.  
  - İnternet varken belirli aralıklarla veya kritik ekranlarda **Google’dan tekrar sorgulama** yapılabilir; böylece iptal / hesap değişikliği gibi durumlar yakalanır.  
  - Çevrimdışıda sadece cache’e güvenilir; çevrimdışı süre uzunsa “yeniden girişte veya çevrim içi olunca doğrula” politikası uygulanabilir.

Bu tamamen **sizin uygulama içi tercihiniz**; Google’a sormak zorunlu, cache isteğe bağlı.

---

## 4. Adım adım veri ve ekran akışı

### 4.1 Uygulama ilk açıldığında

1. Billing bağlantısı kurulur (`InAppPurchase.instance` vb.).
2. “Past purchases” / “restore” çağrılır → Google’a “bu hesap için hangi ürünler satın alınmış?” sorusu gider.
3. Google yanıtında `projectflow_pro` (veya sizin product id) varsa → Pro = true.
4. Bu sonuç yerel cache’e yazılır (isterseniz).
5. Uygulama bu “Pro” bayrağına göre menüde/ekranlarda “Pro” rozeti veya kilit gösterir.

### 4.2 Kullanıcı “Pro’yu satın al” dediğinde

1. Uygulama, Billing API üzerinden “Şu product id için satın alma başlat” der.
2. Google, kendi ödeme ekranını gösterir (kullanıcı ödemeyi tamamlar veya iptal eder).
3. Tamamlandıysa uygulama “purchase stream” üzerinden satın alma nesnesini alır.
4. **Acknowledgment:** Tüketici olmayan (consumable olmayan) ürünler için satın almayı “acknowledge” etmeniz gerekir; etmezseniz Google bir süre sonra iade eder. Flutter’da bu adım paket dokümantasyonunda yer alır.
5. Acknowledgment sonrası Pro = true; cache güncellenir; ilgili ekranlar Pro’ya açılır.

Bu süreçte **sizin sunucunuza hiç veri göndermeniz gerekmez**; tüm iletişim uygulama ↔ Google Play.

### 4.3 Kullanıcı “Satın almaları geri yükle” dediğinde

1. Aynı “past purchases” / restore çağrısı yapılır.
2. Google, bu Google hesabına bağlı satın almaları döner.
3. `projectflow_pro` varsa Pro = true yapılır, cache güncellenir.
4. Yeni cihaz veya uygulama silip yeniden yükleme senaryosu da böyle çözülür; yine **sunucu gerekmez**.

### 4.4 Premium özelliğe tıklandığında

- **Pro ise:** Özellik açılır (örn. gelişmiş time tracking ekranı).
- **Pro değilse:**  
  - “Bu özellik Pro sürümünde. Pro’ya yükseltmek ister misiniz?” metni.  
  - “Yükselt” → yukarıdaki satın alma akışı.  
  - “Satın almaları geri yükle” → restore akışı.

Tüm bu akışlar **sadece uygulama + Google Play** ile çalışır; web siteniz veya API’niz olmasa da olur.

---

## 5. Belirli süre deneme (trial) nasıl verilir?

Kullanıcılara “X gün Pro’yu ücretsiz dene” vermek için iki pratik yöntem vardır; sunucu gerekmez.

### 5.1 Yöntem A: Abonelik + Google ücretsiz denemesi (önerilen, en sade)

- **Ne:** Pro’yu **abonelik (subscription)** olarak tanımlarsınız; Play Console’da bu abonelik için **ücretsiz deneme süresi** (örn. 7 gün, 14 gün, 1 ay) verirsiniz.
- **Nasıl:** Play Console → Monetize → **Subscriptions** → Pro aboneliğini oluşturun → **Free trial** alanında süreyi seçin (ör. 7 days). Kullanıcı “Pro’ya başla” dediğinde önce deneme başlar; süre bitince otomatik ücretlendirme (veya iptal ederse deneme biter, Pro kapanır).
- **Uygulama tarafı:** Ekstra mantık yazmazsınız. Pro durumu yine **Billing / past purchases** ile okunur; Google “deneme aktif” veya “abonelik aktif” döndüğü sürece uygulama Pro = true kabul eder. Deneme bitip abonelik yoksa Google “Pro yok” döner.
- **Avantaj:** Süre ve “deneme bitti” Google tarafından yönetilir; cihaz değişimi / yeniden yükleme ile deneme süresi sıfırlanmaz (hesaba bağlı). Sunucu/API gerekmez.
- **Dezavantaj:** Pro’yu **abonelik** olarak sunmanız gerekir; tek seferlik satın alma ile aynı ürün için Google’ın yerleşik “free trial”ı yoktur.

**Özet:** Deneme süresi vermek istiyorsanız ve abonelik modeli uygunsa: Pro’yu **subscription** yapın, Play Console’da **free trial** süresini tanımlayın; uygulama sadece satın alma/abonelik durumunu okur.

### 5.2 Yöntem B: Tek seferlik Pro + yerel deneme (uygulama içi süre)

- **Ne:** Pro **tek seferlik ürün** olarak kalır; deneme süresi **uygulama içinde** tutulur. “İlk kez Pro özelliğine girildiğinde” veya “uygulama ilk açıldığında” yerel olarak deneme bitiş tarihi kaydedilir; bu tarihe kadar Pro = true kabul edilir.
- **Nasıl:**  
  1. Kullanıcı ilk kez uygulamayı açar (veya ilk kez bir Pro özelliğine girer).  
  2. Uygulama o anda “deneme başladı” sayar; `trial_ends_at = şimdi + X gün` (örn. 7 gün) değerini **yerel** olarak kaydeder (örn. `shared_preferences` veya `flutter_secure_storage`).  
  3. Her “Pro mu?” kontrolünde: **Pro = (Google’dan satın alma var) VEYA (şimdi < trial_ends_at)**.  
  4. `trial_ends_at` geçtikten sonra sadece Google satın alma ile Pro açık kalır.
- **Veri:** Deneme bitiş tarihi yalnızca **cihazda** tutulur; sunucu yok. Yeni cihazda veya uygulama silinip yeniden yüklendiğinde deneme **yeniden başlar** (çünkü yerel veri sıfırlanır). İsterseniz “deneme yalnızca bir kez” kısıtı için tek seferlik bir bayrak da tutabilirsiniz (örn. “trial_used”); bu da yerelde kalır, cihaz değişince yine sıfırlanır.
- **Avantaj:** Tek seferlik Pro satın alma modelini korursunuz; deneme süresi tamamen uygulama içi, ek sunucu gerekmez.  
- **Dezavantaj:** Deneme cihaza bağlıdır; uygulama silinip yeniden yüklenince veya yeni cihazda deneme tekrar kullanılabilir (kötüye kullanım mümkün; birçok uygulama bunu kabul eder).

**Özet:** Pro tek seferlik ürünse ve “X gün deneme” istiyorsanız: Uygulama ilk açılışta (veya ilk Pro erişiminde) `trial_ends_at` kaydeder; Pro = satın alma VEYA şimdi < trial_ends_at.

### 5.3 Pro durumu formülü (deneme dahil)

Deneme kullanıyorsanız “Pro mu?” kararı şöyle olabilir:

- **Yöntem A (abonelik + Google trial):**  
  `isPro = Google Billing’den abonelik/deneme aktif mi?`  
  (Mevcut Billing sorgusu yeterli; ek alan gerekmez.)
- **Yöntem B (yerel trial):**  
  `isPro = (Google’dan Pro satın alınmış) VEYA (yerel trial_ends_at > şimdi)`  
  (İlk açılışta veya ilk Pro erişiminde trial_ends_at set edilir; süre dolunca sadece satın alma geçerli.)

### 5.4 Deneme bittiğinde kullanıcıya gösterme

- Deneme bittiğinde (Yöntem B’de `trial_ends_at` geçtiğinde, Yöntem A’da Google deneme/abonelik bitince) premium özelliğe girildiğinde yine “Bu özellik Pro’da” + “Yükselt” / “Satın almaları geri yükle” ekranı gösterilir. İsterseniz metinde “Deneme süreniz sona erdi” gibi bir cümle eklenebilir.

### 5.5 Özet tablo

| Yöntem | Pro ürün türü | Deneme nerede? | Sunucu | Deneme sıfırlanır mı? (yeni cihaz / reinstal) |
|--------|----------------|----------------|--------|-----------------------------------------------|
| A: Abonelik + Google free trial | Subscription | Google | Hayır | Hayır (hesaba bağlı) |
| B: Tek seferlik + yerel trial | One-time | Uygulama (yerel) | Hayır | Evet (yerel veri gider) |

---

## 6. Sizin yapmanız gerekenler (özet)

| Yapılacak | Nerede / nasıl |
|-----------|-----------------|
| Tek uygulama | Play Store’da tek “ProjectFlow” listing; ikinci bir “Pro” uygulaması oluşturmayın. |
| Bir “Pro” ürünü tanımlamak | Play Console → Uygulama → Monetize → In-app products (veya Subscriptions) → Tek seferlik ürün veya abonelik; örn. product id: `projectflow_pro`. |
| Deneme süresi (isteğe bağlı) | **Yöntem A:** Pro’yu abonelik yapın, Play Console’da free trial süresi verin. **Yöntem B:** Tek seferlik Pro + uygulama içinde ilk açılışta/ilk Pro erişiminde `trial_ends_at` kaydedin; isPro = satın alma VEYA şimdi < trial_ends_at. |
| Uygulama içinde satın alma ve “Pro mu?” sorusu | Flutter’da `in_app_purchase` ile: bağlan, past purchases al, satın alma başlat, gelen purchase’ı acknowledge et; deneme kullanıyorsanız yerel trial_ends_at ile birleştirin; sonuca göre Pro bayrağını (ve isteğe bağlı cache’i) güncelleyin. |
| Premium ekranlarda kilitleme | Pro bayrağı false ise “Pro’da” mesajı + “Yükselt” / “Geri yükle” (deneme bittiyse “Deneme süreniz sona erdi” eklenebilir); true ise özelliği açın. |
| Restore | Ayarlar veya Pro ekranında “Satın almaları geri yükle” butonu → aynı Billing “restore / past purchases” çağrısı. |

---

## 7. Kabul kriterleri (test edilebilir)

- Uygulama yalnızca **tek** Play Store listing ile yayınlanır; “Pro” ayrı uygulama değildir.
- Pro durumu **yalnızca** Google Play Billing’den (past purchases / satın alma sonucu) ve isteğe bağlı **yerel deneme süresi** ile türetilir; kendi sunucu/API’den okunmaz.
- Satın alma tamamlanıp acknowledge edildikten sonra ilgili premium özellikler açılır.
- “Satın almaları geri yükle” ile aynı Google hesabıyla Pro erişimi yeniden sağlanır (yeni cihaz / yeniden yükleme).
- Pro değilken premium özelliğe girildiğinde “Pro’da” mesajı ve “Yükselt” / “Geri yükle” seçenekleri sunulur.
- İnternet yokken (ve cache varsa) son bilinen Pro durumu kullanılabilir; çevrim içi olunca tekrar doğrulama yapılabilir.
- **Deneme (trial) kullanılıyorsa:** Yöntem A’da deneme süresi boyunca Pro özellikleri açıktır; süre bitince (abonelik yoksa) Pro kapanır. Yöntem B’da yerel trial_ends_at’e kadar Pro açıktır; süre geçince yalnızca satın alma ile Pro açık kalır.

---

## 8. İleride kendi API’niz olursa (opsiyonel)

İleride kendi sunucunuz/API’niz olursa:

- **Doğrulama:** Sunucu, Google Play Developer API (örn. “purchases.products.get”) ile satın almayı doğrulayabilir; bu genelde ek güvenlik veya cross-platform (web vs mobil) senaryoları için kullanılır.
- **Zorunluluk:** Pro kilidini sadece uygulama içinde Billing’e göre açacaksanız **sunucu zorunlu değildir**; bu plan sunucusuz çalışacak şekilde tasarlanmıştır.

---

Bu doküman, “tek uygulama + IAP” modelini ve Pro durumunun **sunucu/API olmadan** nasıl yönetileceğini detaylı planlar. İmplementasyon adımları (hangi paket, hangi metodlar) ayrı bir teknik dokümanda ele alınabilir.

**İlgili:** Satın alma yapmadan Pro testi ve belirli kişilere (örn. ekibinize) ücretsiz Pro verme: [IAP test ve ücretsiz Pro](iap-test-ve-ucretsiz-pro.md).
