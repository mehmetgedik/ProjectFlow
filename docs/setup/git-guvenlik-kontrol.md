# Git commit öncesi güvenlik kontrolü

Her commit öncesi aşağıdaki dosyaların **asla** repoya eklenmediğinden emin olun.

## Commit edilmemesi gereken dosyalar

| Dosya / kalıp | Açıklama |
|---------------|----------|
| `apps/mobile/android/key.properties` | Keystore şifreleri ve yol |
| `apps/mobile/keystores/*` | İmza keystore (.jks) dosyaları |
| `**/local.properties` | SDK/Flutter yolları (makineye özel) |
| `**/*.jks`, `**/*.keystore` | İmza dosyaları |
| `**/.env`, `**/.env.*` | Ortam değişkenleri / API anahtarları |
| `**/credentials.json`, `**/*-credentials.json` | Kimlik bilgileri |
| `**/*.pem` | Sertifika / özel anahtar |

## Kontrol komutları

Commit sonrası hassas dosya izlenmiyor mu kontrol etmek için:

```bash
git ls-files | findstr /i "key.properties local.properties .jks .keystore .env"
```

Çıktı boş olmalı (sadece `key.properties.example` varsa kabul edilebilir).

Staged dosyalarda hassas kalıp var mı kontrol etmek için:

```bash
git diff --cached --name-only | findstr /i "key.properties local.properties .jks .keystore .env credentials .pem"
```

Çıktı boş olmalı.

## .gitignore

Bu kalıplar kök `.gitignore` ve `apps/mobile/android/.gitignore` içinde tanımlıdır. Yeni hassas dosya türü eklediğinizde her iki dosyayı da güncelleyin.
