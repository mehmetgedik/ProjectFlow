## Epic: Notifications (OpenProject parity)

## Amaç

Kullanıcı OpenProject’te oluşan bildirimleri mobil uygulamada da görebilsin ve ilgili kayda hızlıca gidebilsin.

## Kapsam

- Dahil:
  - Bildirim listesini görüntüleme
  - Okundu/okunmadı durumunu görüntüleme
  - Bildirimden ilgili kayda (ör. work package) geçiş
  - Bildirimleri okundu olarak işaretleme (destekleniyorsa)
  - Basit filtreleme (en az: okunmamış / tüm bildirimler)
- Hariç:
  - Offline bildirim deneyimi

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak bildirimlerimi mobilde görebilmek istiyorum, böylece web’e girmeden gelişmelerden haberdar olayım.
- [ ] Kullanıcı olarak bildirime tıklayınca ilgili iş kaydına gidebilmek istiyorum, böylece hızlı aksiyon alabileyim.

## Kabul kriterleri

- [ ] Kullanıcı bildirim listesini görüntüleyebilir.
- [ ] Bildirimler okundu/okunmadı olarak ayırt edilir.
- [ ] Kullanıcı bir bildirime tıklayınca ilgili kaydın detayına gider.
- [ ] Bildirim listesi yüklenemezse kullanıcıya hata ve tekrar deneme sunulur.
- [ ] Bildirim okundu işaretleme destekleniyorsa kullanıcı bunu yapabilir.

- [ ] Kullanıcı bildirim listesini en az “yalnızca okunmamış” ve “tüm bildirimler” olarak filtreleyebilir.
- [ ] Bildirim listesi varsayılan olarak en yeni bildirimi en üstte gösterecek şekilde sıralanır.

## İş kuralları

- Kullanıcı yalnızca yetkili olduğu bildirim/nesneleri görebilir.
- Bildirimden açılan kayıt kullanıcı yetkisi yoksa uygun mesaj ile sınırlandırılır.

## Hata durumları

- Bildirim kaynağına erişilemiyor
- İlgili kayıt bulunamadı / silindi
- Yetki hatası

