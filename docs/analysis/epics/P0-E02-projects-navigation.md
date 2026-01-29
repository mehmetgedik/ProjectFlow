## Epic: Projects & Navigation

## Amaç

Kullanıcı projeler arasında hızlıca gezinebilsin ve uygulamada tutarlı bir navigasyon deneyimi yaşasın.

## Kapsam

- Dahil:
  - Proje listesi görüntüleme
  - Proje seçimi / son proje hatırlama
  - Proje bazlı ekranlara geçiş
- Hariç:
  - Proje yönetimi (ileri admin işlemleri)

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak projelerimi görebilmek istiyorum, böylece doğru projede çalışabileyim.
- [ ] Kullanıcı olarak son seçtiğim projeyi tekrar açınca da görmek istiyorum, böylece hız kazanayım.
- [ ] Kullanıcı olarak listede sadece aktif projelerimi görmek istiyorum, böylece pasif/kapalı projelerle karışmadan doğru projeyi seçebileyim.
- [ ] Kullanıcı olarak sadece tek aktif projem varsa, proje seçimi ekranına uğramadan doğrudan o projede devam etmek istiyorum, böylece gereksiz adım kaybetmeyeyim.

## Kabul kriterleri

- [ ] Kullanıcı erişebildiği projeleri listede görür.
- [ ] Proje seçimi uygulama oturumu içinde korunur.
- [ ] Uygulama yeniden açıldığında son seçilen proje varsayılan olarak seçili gelir.
- [ ] Proje listesi yüklenemezse kullanıcıya hata ve tekrar deneme sunulur.

- [ ] Proje listesinde pasif/kapalı projeler varsayılan olarak gösterilmez; kullanıcı yalnızca aktif projelerini görür.
- [ ] Kullanıcının erişebildiği yalnızca tek bir aktif proje varsa, uygulama proje listesi ekranını göstermeden bu projeyi otomatik olarak "aktif proje" olarak seçer.

## İş kuralları

- Kullanıcı yalnızca yetkili olduğu projeleri görebilir.

- Proje listesinde varsayılan olarak sadece aktif projeler gösterilir; pasif/kapalı projeler ayrı bir filtre veya görünüm olmadan listede yer almaz.
- Kullanıcının erişebildiği tek bir aktif proje varsa, uygulama bunu otomatik "aktif proje" kabul eder ve ek bir proje seçimi adımı göstermez.

## Hata durumları

- Ağ hatası / zaman aşımı
- Yetki hatası

