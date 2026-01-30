# Mobil uygulama için test ortamı

Mobil OpenProject uygulamasını test etmek için iki seçenek: **resmi trial** (önerilen) veya **kendi instance’ında izole bir demo projesi**.

---

## Öncelik 1: Resmi OpenProject trial (önerilen)

OpenProject’in herkese açık sabit bir “demo.openproject.org” sunucusu **yok**. Bunun yerine **14 günlük ücretsiz Enterprise Cloud trial** kullanabilirsiniz; bu instance tam API v3 destekler ve mobil uygulamayı buna bağlamak mükemmel bir test ortamı sağlar.

### Adımlar

1. **Trial oluşturma**  
   [https://start.openproject.com](https://start.openproject.com) adresine gidin.  
   Organizasyon adı girin (URL’nin parçası olur, örn. `mobil-test` → `mobil-test.openproject.com`).  
   “Start Free Trial” ile devam edin; e-posta ile hesap oluşturup instance’a giriş yapın.

2. **Instance URL**  
   Trial’ınızın adresi: `https://<organizasyon-adi>.openproject.com`  
   Mobil uygulamada **Instance adresi** alanına bunu yazın (örn. `https://mobil-test.openproject.com`).  
   Uygulama gerekirse sonuna `/api/v3` ekleyerek API base’i oluşturur.

3. **API key alma**  
   OpenProject’te giriş yaptıktan sonra:  
   **Kullanıcı menüsü (sağ üst) → Hesabım → API erişimi** bölümünden kişisel API anahtarını oluşturup kopyalayın.  
   Bu anahtarı mobil uygulamada **API key** alanına yapıştırın.

4. **Bağlantı**  
   Uygulamada “OpenProject hesabına bağlan” ekranında Instance adresi + API key ile bağlanın.  
   Trial’da oluşturduğunuz projeler ve iş paketleri mobilde görünür.

**Not:** Trial 14 gün sonra otomatik sonlanır ve bir süre sonra silinir. Yeni bir trial için aynı sayfadan tekrar organizasyon adı ile başlayabilirsiniz. Kalıcı kullanım için [OpenProject hosting / planlar](https://www.openproject.org/enterprise-edition/#hosting-options) sayfasına bakın.

---

## Öncelik 2: Kendi instance’ınızda izole demo projesi

Kendi OpenProject instance’ınız (örn. https://openproject.example.com/) varsa ve bunu test için kullanmak istiyorsanız, **tüm instance’ı açmak yerine sadece yeni bir proje** açıp örnek süreç gösterebilirsiniz.

### Mantık

- Mevcut projelerinize dokunmayın.
- Sadece **yeni bir proje** oluşturun (örn. “Mobil Demo” veya “Uygulama Test Projesi”).
- Bu projede örnek **Epic** ve **Task** (ve isterseniz Bug, Milestone) oluşturun.
- Test kullanıcısına sadece bu projeye erişim verin; mobil uygulamada varsayılan proje olarak bu projeyi seçin.

### Adımlar (kısa)

1. Instance’ta yeni proje: **Projeler → Yeni proje**; isim ve tanımlayıcı verin (örn. `mobil-demo`).
2. Projede örnek iş paketleri:
   - 1–2 **Epic** (örn. “Mobil uygulama v1”, “Bildirimler”).
   - Her epic altında birkaç **Task** (farklı durumlar: Açık, İşlemde, Tamamlandı).
   - İsterseniz tarih (başlangıç/bitiş), atama, öncelik ekleyin.
3. Mobil uygulamada Instance = `https://openproject.example.com`, API key = bu kullanıcının API anahtarı; varsayılan proje = “Mobil Demo”.

Böylece gerçek işleriniz yerine sadece bu demo projesi test ortamı olarak kullanılır.

### Script ile örnek veri (önerilen)

Repoda `tools/openproject_demo_seed.py` script’i var. Kendi instance’ınızda **kimlik bilgilerini sohbete veya repoya yazmadan** şu şekilde çalıştırın:

1. **API key alın:** OpenProject’te giriş yapın → Kullanıcı menüsü → Hesabım → API erişimi → API anahtarı oluşturup kopyalayın.

2. **Script’i kendi bilgisayarınızda** çalıştırın (kimlik bilgileri sadece sizin ortamınızda kalır):

   **Windows (CMD):**
   ```bat
   pip install requests
   set OPENPROJECT_URL=https://openproject.example.com
   set OPENPROJECT_API_KEY=buraya_api_anahtarinizi_yapistirin
   python tools\openproject_demo_seed.py
   ```

   **Windows (PowerShell):**
   ```powershell
   $env:OPENPROJECT_URL="https://openproject.example.com"
   $env:OPENPROJECT_API_KEY="buraya_api_anahtarinizi_yapistirin"
   python tools/openproject_demo_seed.py
   ```

   **Alternatif (komut satırı):**
   ```bat
   python tools\openproject_demo_seed.py --url https://openproject.example.com --api-key YOUR_API_KEY
   ```

3. Script **yeni bir “Mobil Demo” projesi** oluşturur ve içine 3 epic + her epic altında 5’er task ekler. Bittiğinde proje URL’sini ve mobil bağlantı bilgisini yazdırır.

**Güvenlik:** API key’i sohbete, e-postaya veya repoya yapıştırmayın. Sadece kendi makinenizde ortam değişkeni veya `--api-key` ile kullanın.

---

## Özet

| Seçenek | Avantaj | Dikkat |
|--------|---------|--------|
| **Resmi trial** (start.openproject.com) | Kendi instance’ınızı açmadan, tam API’li resmi ortam; mobil test için ideal. | 14 gün sonra silinir; kalıcı kullanım için plan gerekir. |
| **Kendi instance’da demo projesi** | Kendi sunucunuz, kalıcı; gerçek verilerinizden ayrı tek proje. | Instance’ı paylaşmak istemiyorsanız sadece “Mobil Demo” projesi + sınırlı kullanıcı ile sınırlayın. |

**Öneri:** Önce [start.openproject.com](https://start.openproject.com) ile trial açıp mobil uygulamayı oraya bağlayın. İhtiyaç kalırsa openproject.example.com üzerinde ayrı bir “Mobil Demo” projesi ile izole test yapın.
