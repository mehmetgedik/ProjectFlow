# keytool soruları ve örnek cevaplar (ProjectFlow keystore)

Keystore oluştururken keytool sırayla şu soruları sorar. Aşağıdaki değerleri kopyalayıp kullanabilir veya kendi bilgilerinizi yazabilirsiniz.

---

## Soru sırası ve örnek cevaplar

| Sıra | keytool sorusu | Örnek cevap (kopyalayabilirsiniz) |
|------|----------------|-----------------------------------|
| 1 | **Enter keystore password:** | *(Kendi belirlediğiniz güçlü bir şifre – en az 6 karakter. Bu şifreyi key.properties’te storePassword ve keyPassword olarak yazacaksınız. Bu dosyaya yazmayın, güvenli yerde saklayın.)* |
| 2 | **Re-enter new password:** | *(1. adımda yazdığınız şifrenin aynısı)* |
| 3 | **What is your first and last name?** | `ProjectFlow Developer` |
| 4 | **What is the name of your organizational unit?** | `Mobile` |
| 5 | **What is the name of your organization?** | `ProjectFlow` |
| 6 | **What is the name of your City or Locality?** | `Istanbul` |
| 7 | **What is the name of your State or Province??** | `Istanbul` |
| 8 | **What is the two-letter country code for this unit?** | `TR` |
| 9 | **Is CN=..., OU=..., O=..., L=..., ST=..., C=... correct?** | `yes` |
| 10 | **Enter key password for &lt;upload&gt;** *(veya “RETURN if same as keystore password”)* | *(Enter’a basın = keystore şifresiyle aynı kabul edilir; genelde aynı kullanılır)* |

---

## Özet – tek blok (kopyala-yapıştır için)

- **Ad Soyad:** ProjectFlow Developer  
- **Organizational Unit:** Mobile  
- **Organization:** ProjectFlow  
- **City/Locality:** Istanbul  
- **State/Province:** Istanbul  
- **Country code:** TR  
- **Şifre:** Kendi belirlediğiniz şifre (bu dosyada veya repoda yazmayın; key.properties’te kullanacaksınız).

---

## Not

- **Şifre:** Sadece sizin belirlemeniz gerekir; yukarıdaki tabloda “örnek cevap” olarak yazılmaz. Güçlü bir şifre seçin ve güvenli yerde (şifre yöneticisi veya güvenli not) saklayın. Aynı şifreyi `key.properties` içinde `storePassword` ve `keyPassword` olarak yazacaksınız.
- **Ülke kodu:** Türkiye = `TR`. Başka ülke kullanıyorsanız iki harfli ISO kodu yazın (örn. US, DE, GB).
- **Key password:** “RETURN if same as keystore password” denirse Enter’a basmak yeterli; böylece key şifresi keystore şifresiyle aynı olur.
