# GitHub’a Gitmemesi Gereken Dosyalar – Güvenlik Kontrol Listesi

Bu belge, repoyu GitHub’a (veya herhangi bir genel depoya) gönderirken **kesinlikle commit edilmemesi** gereken dosyaları ve güvenlik kontrollerini listeler.

---

## 1. Zorunlu: Asla commit edilmemesi gerekenler

| Dosya / klasör | Neden | .gitignore durumu |
|----------------|--------|-------------------|
| `apps/mobile/android/key.properties` | Release keystore şifreleri (`storePassword`, `keyPassword`) ve keystore yolu. Sızdığında uygulama imzalama ele geçirilebilir. | Kök + `android/.gitignore` |
| `apps/mobile/keystores/*.jks`, `*.keystore` | Android imzalama keystore dosyaları. | Kök .gitignore |
| `**/local.properties` | Android SDK yolu (makineye özel). | Kök .gitignore |
| `google-services.json` | Firebase/Google API anahtarları (varsa). | Kök .gitignore |
| `.env`, `.env.local`, `*.env` | Ortam değişkenleri, API anahtarları (projede şu an kullanılmıyor; eklenirse ignore’a alınmalı). | İhtiyaç halinde ekleyin |

**Kontrol:**  
`git status` ve `git diff --cached` çalıştırdığınızda bu dosyalar listede **olmamalı**.  
Eğer `key.properties` veya bir keystore bir kez commit edildiyse:  
1. Repodan ve geçmişten kaldırın (örn. `git filter-branch` / BFG).  
2. Keystore şifrelerini değiştirip yeni keystore ile uygulamayı yeniden imzalayın.  
3. Eski keystore’u artık kullanmayın.

---

## 2. Şablon dosyalar (commit edilebilir)

| Dosya | Açıklama |
|-------|----------|
| `apps/mobile/android/key.properties.example` | Şifreler **boş** veya örnek metin; gerçek şifre içermemeli. Repoda kalabilir. |

`key.properties` oluştururken bu dosyayı kopyalayıp **sadece kendi makinenizde** gerçek değerleri doldurun; `key.properties`’i asla commit etmeyin.

---

## 3. Uygulama içi hassas veri (kod)

- **API key / token:** Uygulama, kullanıcının girdiği OpenProject instance URL ve API key’i kullanır; bu değerler **kodda sabit (hardcoded) değil**, `FlutterSecureStorage` ile cihazda saklanır. Repoda API key veya parola yazılmamalı.
- **Loglama:** `AppLogger` yalnızca debug modda çalışır; release’de hassas veri loglanmamalı. Exception gövdesi loglanıyorsa, release’de maskeleyin veya kapatın.

---

## 4. Geçici / IDE artifact (commit edilmemeli)

Aşağıdakiler kök `.gitignore`’a eklendi; yanlışlıkla commit edilmişse `git rm --cached` ile takipten çıkarıldı:

- `apps/mobile/Get`
- `apps/mobile/Process`
- `apps/mobile/Run`
- `apps/mobile/flutter`

Bunlar Cursor/VS Code veya Flutter komutlarından kalan geçici dosyalardır; repoda olmamalı.

---

## 5. Push öncesi hızlı kontrol

```bash
# Takip edilen dosyalar arasında hassas isim var mı?
git ls-files | findstr /i "key.properties local.properties .env google-services .jks .keystore"

# Çıktı boş olmalı (hiçbir satır gelmemeli).
```

Ayrıca `git status` ile staged dosyalara bakın; yukarıdaki listeden hiçbiri commit’e eklenmiş olmamalı.

---

## 6. Özet

- **key.properties** ve **keystore (.jks/.keystore)** → Asla GitHub’a gitmemeli; .gitignore’da.  
- **local.properties**, **google-services.json**, **.env** → Makineye/ortama özel veya hassas; .gitignore’da olmalı.  
- **Get, Process, Run, flutter** (apps/mobile altında) → Geçici/IDE artifact; temizlendi ve .gitignore’a eklendi.  
- **key.properties.example** → Şablon; commit edilebilir, gerçek şifre içermemeli.

Bu kontrolleri her push öncesi veya en azından release öncesi yapmanız önerilir.
