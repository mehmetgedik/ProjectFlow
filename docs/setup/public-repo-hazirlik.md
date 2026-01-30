# Public repo hazırlığı – yapılanlar

Bu dosya, reponun **public** yapılması öncesi güvenlik ve gizlilik için yapılan düzenlemeleri özetler.

## Repodan kaldırılan / takipten çıkarılanlar

| Öğe | Neden |
|-----|--------|
| **docs/analysis/** | İç ürün/özellik analiz dokümanları (epic/feature/screen). Public’te yayımlanmaz; yerelde kalabilir. |
| **docs/reviews/** | İç inceleme raporları. Public’te yayımlanmaz; yerelde kalabilir. |
| **start-emulator.vbs** | Makineye özel emülatör yolu ve AVD adı. Public’te olmamalı. |

Bu klasör/dosyalar **.gitignore**’a eklendi; bir sonraki commit’ten itibaren repoda görünmez. Yerel kopyalarınız silinmedi.

## Zaten repoda olmayan (kontrol edildi)

- **key.properties** – .gitignore’da; asla commit edilmemeli.
- **keystores/*.jks** – .gitignore’da.
- **local.properties**, **.env**, **google-services.json** – .gitignore’da.
- **apps/mobile/build/** – .gitignore’da.

## Public yaptıktan sonra

1. **GitHub Pages:** Repo public olduğunda Pages açılabilir. Gizlilik politikası URL’i:  
   `https://KULLANICI.github.io/ProjectFlow/gizlilik-politikasi.html`
2. **Build almak:** Yerelde `key.properties` ve keystore dosyası olmalı; `docs/setup/release-signing-steps.md` adımlarını uygulayın.
3. **Analiz/review dokümanları:** Sadece yerelde durur; istersen ayrı private depoda tutabilirsiniz.
