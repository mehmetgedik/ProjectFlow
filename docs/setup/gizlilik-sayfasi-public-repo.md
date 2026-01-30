# Gizlilik politikası: Sadece bu sayfa public (private repo kalır)

Ana proje **ProjectFlow** private kalsın; sadece gizlilik politikası sayfası public bir repoda yayınlansın. GitHub’da tek bir repoda “bazı dosyalar public, bazıları private” yapılamaz; bunun yerine **ayrı, küçük bir public repo** kullanılır.

## Mantık

- **ProjectFlow (mevcut repo):** Private → kod, keystore yolları, dokümanlar kapalı kalır.
- **Yeni public repo:** Sadece `gizlilik-politikasi.html` (ve isteğe bağlı README) → GitHub Pages bu repoda çalışır, Play Console’a verdiğin URL buradan gelir.

Böylece “gizlilik sayfası public, geri kalan her şey private” mümkün olur.

---

## Adımlar

### 1. Yeni public repo oluştur

- GitHub’da **New repository**.
- **Repository name:** Örn. `projectflow-privacy` veya `projectflow-policy`.
- **Public** seç.
- **Add a README** işaretleme (boş repo yeterli).
- **Create repository** de.

### 2. Gizlilik sayfasını bu repoya koy

- Yeni repoda **Add file → Upload files**.
- Projedeki **`gizlilik-politikasi.html`** dosyasını sürükle (proje kökündeki veya `docs/setup/` içindeki aynı içerik).
- Commit: örn. “Gizlilik politikası sayfası”.

İstersen dosyayı kökte bırakırsın; URL `https://KULLANICI.github.io/REPO_ADI/gizlilik-politikasi.html` olur.  
Veya `docs/` altına koyup Pages’i “Deploy from branch” → “/docs” yaparsan URL `https://KULLANICI.github.io/REPO_ADI/gizlilik-politikasi.html` olur (dosya `docs/gizlilik-politikasi.html` ise).

### 3. GitHub Pages aç

- Yeni repo → **Settings** → sol menü **Pages**.
- **Source:** Deploy from a branch.
- **Branch:** `main` (veya default branch), **Folder:** `/ (root)`.
- Save.

Birkaç dakika sonra site yayında olur.

### 4. URL’i al

- Repo adı `projectflow-privacy` ve kullanıcı `mehmetgedik` ise:
  - **`https://mehmetgedik.github.io/projectflow-privacy/gizlilik-politikasi.html`**

Bu URL’i Play Console’daki **Gizlilik politikası** alanına yapıştır.

---

## Özet

| Repo              | Görünürlük | İçerik                          |
|-------------------|------------|----------------------------------|
| ProjectFlow       | Private    | Tüm kod, dokümanlar, keystore   |
| projectflow-privacy | Public   | Sadece gizlilik politikası HTML |

Gizlilik sayfası güncellemek istediğinde sadece public repodaki `gizlilik-politikasi.html` dosyasını düzenleyip commit atman yeterli; ana proje private kalır.
