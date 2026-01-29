## Feature: Benim işlerim (Work packages listesi)

## Amaç

Kullanıcı günlük işlerini “benim işlerim” listesi üzerinden hızlıca takip edebilsin.

## Kapsam

- Dahil:
  - Üzerime atanmış işlerin listelenmesi
  - Temel filtreleme ve sıralama
  - Webdeki “Benim işlerim” görünümüne benzer liste davranışı
  - Çok sayıda kayıt olduğunda sayfalama / parti parti listeleme
  - Hiyerarşik işler için (ana/alt iş) ağaç (tree) görünüm desteği (destekleniyorsa)
  - Liste öğesinden detaya geçiş
- Hariç:
  - Offline listeleme

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak üzerime atanmış açık işleri görmek istiyorum, böylece günümü planlayayım.
- [ ] Kullanıcı olarak listede durum, tarih ve öncelik gibi alanlara göre filtre uygulamak istiyorum, böylece o an ihtiyacım olan işleri göreyim.
- [ ] Kullanıcı olarak sadece açık işlerimi veya tüm işlerimi hızlıca seçebilmek istiyorum, böylece görünümü web ile tutarlı kullanabileyim.
- [ ] Kullanıcı olarak çok uzun listelerde sayfa sayfa veya “daha fazla yükle” mantığıyla ilerlemek istiyorum, böylece tek seferde aşırı kayıtla karşılaşmayayım.
- [ ] Kullanıcı olarak ana iş ve alt işleri ağaç yapıda görebilmek istiyorum, böylece hiyerarşiyi kaybetmeden çalışabileyim (web’deki tree görünüme benzer).

## Kabul kriterleri

- [ ] Liste, kullanıcıya atanmış işleri gösterir (en az “açık” durumdakiler).
- [ ] Liste öğesinde en az şu bilgiler görünür: başlık, durum, atanan, bitiş tarihi (varsa).
- [ ] Kullanıcı temel filtre uygulayabilir (en az: durum).
- [ ] Kullanıcı temel sıralama uygulayabilir (en az: güncellenme tarihi veya bitiş tarihi), destekleniyorsa öncelik veya bitiş tarihine göre sıralama yapabilir.
- [ ] Liste yüklenemiyorsa hata ve tekrar deneme sunulur.
- [ ] Liste öğesine tıklanınca ilgili işin detayına gidilir.

- [ ] Varsayılan görünümde liste yalnızca “üzerime atanmış” ve “açık” durumdaki işleri gösterir.
- [ ] Kullanıcı, varsayılan filtreden çıkarak kapalı işleri veya tüm işleri görebilir.
- [ ] Uygulanan filtre ve sıralama, listede kullanıcıya anlaşılır bir şekilde gösterilir (ör. “Açık işlerim, bitiş tarihine göre sıralı” gibi).
- [ ] Çok sayıda kayıt olduğunda liste makul büyüklükte sayfalara veya partilere bölünür; kullanıcı daha fazlasını istediğinde yeni kayıtlar yüklenir.
- [ ] Hiyerarşik işler (ana/alt iş) destekleniyorsa, kullanıcı bu işleri ağaç yapıda genişletip daraltarak görebilir.

