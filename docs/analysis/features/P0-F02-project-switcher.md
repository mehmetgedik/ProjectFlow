## Feature: Proje seçimi (Project switcher)

## Amaç

Kullanıcı projeler arasında hızlı geçiş yapabilsin ve seçimini koruyabilsin.

## Kapsam

- Dahil:
  - Proje listesi
  - Proje seçimi
  - Son seçilen proje hatırlama
- Hariç:
  - Proje yönetimi / admin işlemleri

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak projelerimi listede görmek istiyorum, böylece doğru projeyi seçeyim.
- [ ] Kullanıcı olarak son seçtiğim projenin hatırlanmasını istiyorum, böylece hız kazanayım.
- [ ] Kullanıcı olarak listede sadece aktif projelerimi görmek istiyorum, böylece pasif/kapalı projelerle karışmadan doğru projeyi seçebileyim.
- [ ] Kullanıcı olarak sadece tek aktif projem varsa, proje seçimi ekranına uğramadan doğrudan o projede devam etmek istiyorum, böylece gereksiz adım kaybetmeyeyim.

## Kabul kriterleri

- [ ] Kullanıcı erişebildiği projeleri listede görür.
- [ ] Proje listesi yüklenemezse hata ve tekrar deneme gösterilir.
- [ ] Kullanıcı bir proje seçtiğinde uygulama bu projeyi “aktif proje” olarak kullanır.
- [ ] Uygulama yeniden açıldığında son aktif proje otomatik seçili gelir.

- [ ] Proje listesinde pasif/kapalı projeler varsayılan olarak gösterilmez; kullanıcı yalnızca aktif projelerini görür.
- [ ] Kullanıcının erişebildiği yalnızca tek bir aktif proje varsa, uygulama proje listesi ekranını göstermeden bu projeyi otomatik olarak "aktif proje" olarak seçer.

## İş kuralları

- Kullanıcı yalnızca yetkili olduğu projeleri görebilir.
- Proje listesinde varsayılan olarak sadece aktif projeler gösterilir; pasif/kapalı projeler ayrı bir filtre veya görünüm olmadan listede yer almaz.
- Kullanıcının erişebildiği tek bir aktif proje varsa, uygulama bunu otomatik "aktif proje" kabul eder ve ek bir proje seçimi adımı göstermez.

