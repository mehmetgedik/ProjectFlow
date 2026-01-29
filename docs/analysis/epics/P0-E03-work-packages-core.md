## Epic: Work Packages (Core)

## Amaç

Kullanıcı iş paketlerini mobilde takip edebilsin ve günlük işlerini hızlıca yönetebilsin.

## Kapsam

- Dahil:
  - “Benim işlerim” listesi (üzerime atanan, açık durumdaki işler)
  - İş paketi listeleme (temel filtre/sıralama, çok sayıda kayıt için sayfalama/parti listeleme)
  - İş paketi detay görüntüleme
  - İş paketinde temel alanların güncellenmesi (durum, atanan, bitiş tarihi gibi)
  - Aktivite/yorum görüntüleme ve yorum ekleme
- Hariç:
  - Offline çalışma
  - Çok ileri raporlama/özel görünümler

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak üzerime atanmış açık işleri görmek istiyorum, böylece günümü planlayayım.
- [ ] Kullanıcı olarak bir işin detaylarını görmek istiyorum, böylece doğru aksiyonu alayım.
- [ ] Kullanıcı olarak bir işi güncelleyebilmek istiyorum, böylece ilerlemeyi sisteme yansıtayım.
- [ ] Kullanıcı olarak bir işe yorum yazabilmek istiyorum, böylece ekip iletişimi sağlansın.

## Kabul kriterleri

- [ ] “Benim işlerim” ekranı, kullanıcıya atanmış ve açık durumdaki işleri listeler.
- [ ] Liste ekranında en az şu bilgiler görünür: başlık, durum, atanan, öncelik (varsa), bitiş tarihi (varsa).
- [ ] Liste ekranında kullanıcı temel filtreleri uygulayabilir (en az: durum / atanan / tarih).
- [ ] “Benim işlerim” görünümünde varsayılan filtre; atanan = kullanıcı ve durum = açık olacak şekilde tanımlıdır.
- [ ] Kullanıcı, varsayılan filtreden çıkarak kapalı işleri veya tüm işleri görebilir.
- [ ] Liste, uygulanan filtre ve sıralamayı kullanıcıya görünür bir şekilde gösterir.
- [ ] Çok sayıda kayıt olduğunda liste makul büyüklükte sayfalara veya partilere bölünür; kullanıcı daha fazlasını istediğinde yeni kayıtlar yüklenir.
- [ ] Detay ekranı işin temel alanlarını ve açıklamasını gösterir.
- [ ] Kullanıcı işin durumunu güncelleyebilir.
- [ ] Kullanıcı işin atanan kişisini güncelleyebilir (yetkisi varsa).
- [ ] Kullanıcı işin bitiş tarihini güncelleyebilir (yetkisi varsa).
- [ ] Kullanıcı işin aktivite/yorum geçmişini görebilir.
- [ ] Kullanıcı yeni yorum ekleyebilir (yetkisi varsa).
- [ ] Yetki yoksa, ilgili alanlar salt-okunur gösterilir ve kullanıcı bilgilendirilir.
- [ ] Ağ hatalarında kullanıcıya tekrar deneme sunulur.

## İş kuralları

- Güncelleme işlemleri yetkilere tabidir.
- Mobilde gösterilen alanlar web ile aynı olmak zorunda değildir; ancak bilgi kaybı kullanıcıyı engellememelidir.
- P0 kapsamında mobil uygulamada iş paketleri için yalnızca liste görünümü desteklenir; web’deki ileri görünümler (ör. board/kanban) bu epic kapsamı dışındadır.

## Hata durumları

- Yetkisiz işlem denemesi
- Çakışan güncellemeler (sunucu reddi)
- Ağ hatası / zaman aşımı

