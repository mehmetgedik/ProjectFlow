# Release imzalama – adım adım (Google Play)

ProjectFlow uygulamasını Google Play’e yüklemek için release keystore ve `key.properties` gerekiyor. Bu dosya adımları tek tek anlatır.

---

## Adım 1: Keystore oluşturma

1. **Terminal açın** ve proje uygulama klasörüne gidin:
   ```bash
   cd d:\MG\Project\Mobile\OpenProject\apps\mobile
   ```

2. **Aşağıdaki komutu çalıştırın.** Şifre ve ad girmeniz istenecek; girdiğiniz şifreleri güvenli yerde saklayın (key.properties’te kullanacaksınız).
   ```bash
   keytool -genkey -v -keystore keystores/projectflow-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. İstenen bilgiler:
   - **Keystore şifresi** ve **tekrar:** Güçlü bir şifre (en az 6 karakter). Bunu `key.properties` içinde `storePassword` ve `keyPassword` olarak yazacaksınız.
   - **Ad, birim, kuruluş, şehir, il, ülke kodu:** İsterseniz gerçek bilgilerinizi veya “ProjectFlow” gibi genel bir değer girebilirsiniz.

4. **Keystore dosyası** `apps/mobile/keystores/projectflow-upload.jks` konumunda oluşur. Bu klasör `.gitignore`’da olduğu için repoya eklenmez.

---

## Adım 2: key.properties oluşturma

1. **Dosya kopyalama:** `apps/mobile/android/key.properties.example` dosyasını kopyalayıp adını `key.properties` yapın (aynı `android` klasöründe).

2. **key.properties dosyasını açın** ve aşağıdaki alanları kendi değerlerinizle doldurun:
   ```properties
   storeFile=../keystores/projectflow-upload.jks
   storePassword=GIRDIGINIZ_KEYSTORE_SIFRESI
   keyAlias=upload
   keyPassword=GIRDIGINIZ_KEY_SIFRESI
   ```
   - `storeFile`: Keystore yoludur. Yukarıdaki gibi bırakırsanız `android` klasörüne göre `../keystores/projectflow-upload.jks` doğru yoldur.
   - `storePassword` ve `keyPassword`: Adım 1’de keytool’a girdiğiniz şifreler (genelde aynı).
   - `keyAlias`: Adım 1’de kullandığınız alias; komutta `-alias upload` kullandıysanız `upload` kalmalı.

3. **key.properties dosyasını asla repoya eklemeyin** (zaten `.gitignore`’da).

---

## Adım 3: Release AAB üretme

1. **Terminalde** uygulama klasöründe olduğunuzdan emin olun:
   ```bash
   cd d:\MG\Project\Mobile\OpenProject\apps\mobile
   ```

2. **App bundle oluşturun:**
   ```bash
   flutter build appbundle
   ```

3. Başarılı olursa AAB dosyası şurada olur:
   ```
   apps/mobile/build/app/outputs/bundle/release/app-release.aab
   ```
   Bu dosyayı Google Play Console’da “App bundle’ları yükle” ile yüklersiniz.

---

## Sorun giderme

- **“keytool bulunamadı”:** JDK kurulu olmalı. JDK’yı PATH’e ekleyin veya Android Studio’nun içindeki JDK’yı kullanın (ör. `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`).
- **“Keystore was tampered with”:** Şifre yanlış; `key.properties`’teki `storePassword` ve `keyPassword`’ü kontrol edin.
- **“release” signing config bulunamıyor:** `key.properties` dosyası `apps/mobile/android/` içinde mi ve dört alan da dolu mu kontrol edin.
