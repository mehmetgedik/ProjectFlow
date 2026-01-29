## Feature: Time entry (zaman kaydı)

## Amaç

Kullanıcı bir iş üzerinden hızlıca zaman kaydı girebilsin.

## Kapsam

- Dahil:
  - Work package üzerinden time entry ekleme
  - Temel alanlar: tarih, süre, açıklama (gerekiyorsa), activity (gerekiyorsa)
  - İlgili iş bağlamında girilmiş zaman kayıtlarını tarih bazlı görüntüleme
- Hariç:
  - Offline time entry
  - İleri raporlama

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak bir iş üzerinde zaman kaydı girmek istiyorum, böylece yapılan işi raporlayayım.

## Kabul kriterleri

- [ ] Kullanıcı yetkisi varsa time entry ekleyebilir.
- [ ] Zorunlu alanlar boş geçilemez; kullanıcı uyarılır.
- [ ] Süre formatı geçersizse kayıt alınmaz ve kullanıcı uyarılır.
- [ ] Kayıt başarısız olursa hata ve tekrar deneme sunulur.

- [ ] Kullanıcı ilgili işin zaman kayıtlarını en yeni kayıt en üstte olacak şekilde listelenmiş görür (destekleniyorsa).

