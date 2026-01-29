# Feature: Gantt görünümü

## Amaç

Kullanıcı, iş paketlerinin zaman çizelgesini Gantt grafiği ile görebilsin. Başlangıç/bitiş tarihi olmasa bile güncelleme tarihi veya (ileride) zaman kayıtlarına göre eksende konumlanabilmeli.

## Kapsam

- Dahil:
  - Seçilen proje veya “benim işlerim” kapsamındaki work package’ların Gantt’ta listelenmesi.
  - **Gantt modları:**
    - **Başlangıç–Bitiş (startDate / dueDate):** İkisi de olan işler; çubuk tarih aralığına göre.
    - **Güncelleme tarihi (updatedAt):** updatedAt olan işler; çubuk o gün tek günlük.
  - Çubuk tıklanınca ilgili work package detayına gidebilme.
  - Tarih ekseninde gün/hafta görünümü ve yatay kaydırma.
- Hariç (ilk sürüm):
  - Gantt üzerinden sürükle‑bırak ile tarih güncelleme.
  - Öncül/ardıl ilişkilerinin çizgi ile gösterilmesi.
  - Takım planlayıcı / kaynak yükleme.

## Gantt nerede kullanılır?

- **İşlerim (liste ekranı):** Liste | Gantt geçişi; Gantt modu “Başlangıç–Bitiş” veya “Güncelleme tarihi”.
- **Zaman takibi ekranı:** Tablo | Gantt geçişi. Gantt, zaman kayıtlarına göre: WP bazlı min(spentOn)..max(spentOn) çubukları. Veri `getMyTimeEntries` ile zaten yüklü; ek API yok.
- **Tamamlanan işler:** Filtre (durum = tamamlandı) ile listeyi daraltıp İşlerim Gantt’ını kullanmak. Gantt modu yine Başlangıç–Bitiş veya Güncelleme tarihi.

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak işlerimi tarih ekseninde Gantt ile görmek istiyorum (başlangıç–bitiş veya güncelleme tarihine göre).
- [ ] Kullanıcı olarak bir Gantt çubuğuna tıklayıp ilgili işin detayına gidebilmek istiyorum.
- [ ] Kullanıcı olarak başlangıç/bitiş tarihi atamadığım işleri “güncelleme tarihi” modunda Gantt’ta görmek istiyorum.

## Kabul kriterleri

- [ ] Gantt ekranına proje veya “benim işlerim” bağlamından erişilebilir.
- [ ] Kullanıcı Gantt modu seçebilir: “Başlangıç–Bitiş” veya “Güncelleme tarihi”.
- [ ] Başlangıç–Bitiş modunda: startDate ve dueDate olan işler çubukla gösterilir; yoksa gösterilmez veya “tarih atanmış iş yok” mesajı.
- [ ] Güncelleme tarihi modunda: updatedAt olan işler o gün tek günlük çubukla gösterilir.
- [ ] Çubuğa tıklayınca ilgili work package detay ekranına gidilir.
- [ ] Tarih ekseni gün/hafta birimiyle sunulur; yatay kaydırma ile farklı aralıklar görüntülenebilir.
- [ ] Veri/API hatası durumunda anlamlı mesaj ve yenile imkânı sunulur.

## İş kuralları

- Gantt verisi work package listesi (listeleme/filtreleme) ile elde edilir.
- Başlangıç–Bitiş: startDate, dueDate kullanılır; ikisi de olmalı, start ≤ end.
- Güncelleme tarihi: updatedAt kullanılır; çubuk o gün (start = end).
- Sadece görüntüleme; tarih güncellemesi detay veya hızlı güncelleme akışlarından yapılır.

## Hata durumları

- Work package listesi alınamazsa: Hata mesajı ve yenile.
- Seçilen moda göre uygun iş yoksa: “Tarih atanmış iş bulunamadı” / “Güncelleme tarihi olan iş bulunamadı” benzeri bilgilendirme.

## İleride / notlar

- **Zaman kaydı girilen işler:** Zaman takibi ekranında Gantt uygulandı (Tablo | Gantt). WP bazlı min..max spentOn çubukları; veri mevcut time entries ile.
- **Tamamlanan işler:** Gantt modu değil, filtre (durum = tamamlandı). Tamamlanan işlerle İşlerim Gantt modları (Başlangıç–Bitiş, Güncelleme tarihi) birlikte kullanılır.

## Notlar

- OpenProject API: startDate, dueDate, updatedAt liste/detay yanıtlarında gelir.
- P1‑F02 (Görünümler ve Kolonlar) kapsamında Gantt “hariç”tir; bu feature Gantt’ı ayrı görünüm olarak ele alır.
