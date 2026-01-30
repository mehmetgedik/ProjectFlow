# Bildirimler ve Mesai Hatırlatması – Akış ve Test

Bu dokümanda OpenProject bildirimlerinin mobil uygulamaya nasıl yansıdığı ve mesai saati (zaman takibi) hatırlatmasının nasıl çalıştığı özetlenir; test için kontrol listesi verilir.

---

## 1. OpenProject bildirimleri → Mobil uygulama

### Nasıl çalışır?

1. **OpenProject tarafı**  
   Kullanıcının OpenProject bildirim ayarlarına göre (mention, atama, tarih uyarısı vb.) hem **e-posta** hem **uygulama içi bildirim (IAN)** oluşturulur. Aynı ayarlar her iki kanalı da besler.

2. **Mobil uygulama**
   - **Uygulama açıkken:** Her **5 dakikada** bir `GET /api/v3/notifications` (sadece okunmamış) ile sayı alınır. Önceki sayıdan büyükse ve Profil > Bildirim ayarlarından “Yeni bildirimde telefon bildirimi” açıksa **yerel (telefon) bildirimi** gösterilir.
   - **Uygulama kapalı / arka plandayken:** **Workmanager** ile **ağ bağlıyken** yaklaşık **30 dakikada** bir aynı API çağrılır; ilk çalışma girişten **1 dakika** sonra, sonra periyodik devam eder. Sayı artmışsa yine yerel bildirim gösterilir (profil ayarına bağlı).
   - **İzin:** Giriş (connect) sonrası **bildirim izni** istenir; verilmezse telefon bildirimi gösterilmez.

3. **Sonuç**  
   OpenProject’te oluşan **uygulama içi bildirimler** (e-postayla aynı olaylarda) API üzerinden sayılıyor; sayı arttığında mobil uygulama telefon bildirimi gösteriyor. İçerik/detay OpenProject’te; mobil tarafta sadece “X okunmamış bildirim” özeti var.

### Kontrol listesi – OpenProject bildirimleri mobilde gelsin

- [ ] **OpenProject (web):** Hesap → Bildirim ayarlarında ilgili olaylar (participating, date alerts vb.) açık; böylece **uygulama içi bildirim** de oluşuyor.
- [ ] **Profil (mobil):** “Bildirim ayarları” > “Yeni bildirimde telefon bildirimi” **açık**.
- [ ] **Cihaz:** Uygulama için **bildirim izni** verilmiş (Android 13+ POST_NOTIFICATIONS).
- [ ] **Test:** OpenProject’te sizi tetikleyecek bir olay oluşturun (ör. bir işe atanın veya bir yorumda @mention). En geç ~5 dk (uygulama açık) veya ~30 dk (arka plan) içinde “X okunmamış bildirim” telefon bildirimi gelmeli.

---

## 2. Mesai saati (zaman takibi) hatırlatması

### Nasıl çalışır?

1. **Profil > Zaman takibi hatırlatması**  
   - Açık/kapalı switch.  
   - “Mesai bitiş saati” (örn. 17:00): Bu saatten **15 dakika önce** hatırlatma planlanır (örn. 16:45).

2. **Zamanlama**
   - **Çalışma günleri:** OpenProject’ten alınan haftalık çalışma günleri kullanılır (varsayılan Pazartesi–Cuma).
   - **Saat dilimi:** Cihazın yerel saat dilimi (`flutter_timezone`) kullanılır; hatırlatma **cihazın yerel saatine** göre (örn. 16:45 Türkiye saati) tetiklenir.
   - **Tekrarlama:** Her çalışma günü için aynı saatte (örn. her Pazartesi 16:45) tekrarlayan bildirim planlanır.

3. **Ne zaman planlanır?**  
   - **Giriş (connect)** ve **uygulama her açıldığında (initialize)** `TimeTrackingReminderService.scheduleFromPrefs` çağrılır; böylece mesai hatırlatması her zaman güncel kalır (cihaz yeniden başlasa bile uygulama bir kez açıldığında yeniden planlanır).
   - Profil’de hatırlatmayı açıp mesai bitiş saatini kaydettikten sonra da aynı servis tetiklenir.

### Kontrol listesi – Mesai hatırlatması gelsin

- [ ] **Profil (mobil):** “Zaman takibi hatırlatması” **açık**.
- [ ] **Profil (mobil):** “Mesai bitiş saati” ayarlı (örn. 17:00 → hatırlatma 16:45’te).
- [ ] **Cihaz:** Uygulama için **bildirim izni** verilmiş.
- [ ] **Test için:** Mesai bitiş saatini **birkaç dakika sonrasına** ayarlayın (örn. şu an 14:00 ise 14:05; hatırlatma 13:50’de planlanır, geçmişte kaldığı için bir sonraki çalışma gününe düşer). Daha net test için saati **2–3 dakika sonrasına** (ve bugün çalışma günüyse) ayarlayıp uygulamayı kapatıp bekleyin; 15 dk öncesi = mesai 14:05 ise 13:50’de bildirim gelmeli (cihaz saati yerel).

### Bilinen noktalar

- İlk kurulumda veya timezone hiç ayarlanmadıysa, `tz.local` UTC olabilir; bu yüzden cihaz saat dilimi `flutter_timezone` ile alınıp `tz.setLocalLocation` ile ayarlanıyor. Bu sayede “mesai bitiş saati” gerçekten yerel saate göre işlenir.
- Hatırlatma sadece **çalışma günlerinde** (OpenProject’teki haftalık çalışma takvimine göre) planlanır; izin günü vb. atlanır.

---

## 3. Özet

| Özellik | Tetikleyen | Mobilde ne zaman? |
|--------|------------|-------------------|
| OpenProject bildirimleri | OpenProject’te IAN oluşması | Sayı artınca: uygulama açıkken ~5 dk, kapalıyken ~30 dk içinde telefon bildirimi |
| Mesai hatırlatması | Profil’de açık + mesai bitiş saati | Her çalışma günü, mesai bitişinden 15 dk önce (cihaz yerel saati) |

Her iki özellik de **Profil > Bildirim / Zaman takibi** ayarlarına ve cihaz bildirim iznine bağlıdır; yukarıdaki listeler test sırasında kontrol edilebilir.

### Arka planın güvenilir çalışması için

- **Bildirim izni:** Giriş sonrası istenen izni vermeniz gerekir; aksi halde arka planda gelen bildirimler gösterilmez.
- **Pil / pil optimizasyonu:** Bazı cihazlarda “Pil tasarrufu” veya “Arka plan kısıtlaması” uygulamayı sınırlayabilir. Arka plan bildirimlerinin düzenli gelmesi için **Ayarlar → Uygulamalar → ProjectFlow → Pil** (veya benzeri) bölümünden uygulamanın kısıtlanmadığından emin olun.
