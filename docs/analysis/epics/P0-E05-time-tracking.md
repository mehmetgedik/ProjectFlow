## Epic: Time Tracking (Time entries)

## Amaç

Kullanıcı işlere zaman kaydı girebilsin ve zaman kayıtlarını yönetebilsin.

## Kapsam

- Dahil:
  - Bir work package üzerinden zaman kaydı ekleme
  - Tarih/süre/açıklama (varsa) gibi temel alanları girme
  - Girilen zaman kayıtlarını görüntüleme (work package bağlamında)
  - Zaman kayıtlarını tarih bazlı listeleme
- Hariç:
  - Offline zaman kaydı (kuyruklama)
  - İleri raporlama

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak bir işe hızlıca zaman kaydı girmek istiyorum, böylece gün sonunda unutmayayım.
- [ ] Kullanıcı olarak girdiğim zaman kayıtlarını görebilmek istiyorum, böylece kontrol edebileyim.

## Kabul kriterleri

- [ ] Kullanıcı bir work package üzerinden zaman kaydı ekleyebilir (yetkisi varsa).
- [ ] Zaman kaydı en az şu alanları içerir: tarih, süre, açıklama (sistem gerektiriyorsa).
- [ ] Süre alanı geçerli formatta değilse kullanıcı uyarılır ve kayıt alınmaz.
- [ ] Zaman kaydı ekleme başarısız olursa kullanıcıya hata ve tekrar deneme sunulur.
- [ ] Kullanıcı ilgili işin bağlamında zaman kayıtlarını görüntüleyebilir (destekleniyorsa).
- [ ] Yetki yoksa zaman kaydı ekleme aksiyonu pasif/salt-okunur gösterilir.

- [ ] Zaman kayıtları varsayılan olarak en yeni kayıt en üstte olacak şekilde listelenir.

## İş kuralları

- Zaman kaydı yetkilere ve proje ayarlarına tabidir.
- Zorunlu alanlar boş geçilemez.

## Hata durumları

- Yetkisiz işlem
- Zorunlu alan eksikliği
- Ağ hatası / zaman aşımı

