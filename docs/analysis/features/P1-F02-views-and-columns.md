# Feature: Görünümler ve Kolonlar (Kayıtlı görünümler + liste kolonları)

## Amaç

Kullanıcı iş listesinde OpenProject’te tanımlı kayıtlı görünümleri (queries) kullanabilsin; ayrıca listede hangi kolonların görüneceğini seçebilsin. Görünüm seçildiğinde sıralama, filtre, kolon ayarları ve kayıt sayısı gibi ayarlar OpenProject’ten gelir.

## Kapsam

- Dahil:
  - OpenProject API’den kayıtlı görünümlerin (queries) listelenmesi (proje kapsamında veya global).
  - Kullanıcının bir görünüm seçerek o görünümün filtre, sıralama ve kolonlarıyla listeyi görmesi.
  - Listede gösterilecek kolonların seçilebilmesi (ID, başlık, tür, durum, öncelik, atanan, bitiş tarihi, güncellenme tarihi vb.).
  - Varsayılan “Benim açık işlerim” görünümünün mevcut davranışla uyumlu kalması.
  - Görünüm değiştiğinde sayfalama (pageSize/offset) ve toplam kayıt sayısının anlamlı kullanılması.
- Hariç:
  - Görünüm oluşturma/düzenleme (sadece mevcut görünümleri listele ve kullan).
  - Gantt / takım planlayıcı / takvim gibi farklı projeksiyonlar (sadece tablo/liste).

## Kullanıcı hikayeleri

- [ ] Kullanıcı olarak OpenProject’te kaydettiğim görünümleri mobilde görmek ve seçmek istiyorum, böylece web’de kullandığım filtre ve sıralamayı aynen kullanabileyim.
- [ ] Kullanıcı olarak listede hangi kolonların (durum, atanan, bitiş tarihi, tür, öncelik, güncellenme vb.) görüneceğini seçebilmek istiyorum, böylece ihtiyacıma göre bilgi yoğunluğunu ayarlayayım.
- [ ] Kullanıcı olarak seçtiğim görünümdeki toplam kayıt sayısını ve sayfalama bilgisini görmek istiyorum, böylece listenin kapsamını anlayayım.

## Kabul kriterleri

- [ ] Ekranda “Görünüm” seçeneği vardır; “Varsayılan (açık işlerim)” ve API’den gelen kayıtlı görünümler listelenir.
- [ ] Bir kayıtlı görünüm seçildiğinde liste, o görünümün filtre ve sıralamasına göre yüklenir; kolonlar görünümün kolon ayarına uygun (veya kullanıcı kolon seçimine göre) gösterilir.
- [ ] Listede en az şu kolonlar (açılıp kapatılabilir) desteklenir: ID, başlık, tür, durum, öncelik, atanan, bitiş tarihi, güncellenme tarihi.
- [ ] Varsayılan görünüm seçiliyken mevcut “benim açık işlerim” davranışı korunur.
- [ ] Görünüm değiştiğinde hata durumunda kullanıcıya mesaj ve tekrar deneme sunulur.

## Kurallar / İş mantığı

- Görünüm listesi: proje seçiliyse o projeye ait + global görünümler; proje yoksa global görünümler (API: `/api/v3/queries`, project filtresi).
- Tek bir görünümün sonuçları: API’deki query’nin `results` linki veya `GET /api/v3/queries/{id}` ile alınır; `pageSize` ve `offset` desteklenir.
- Kolon kimlikleri API’deki QueryColumn id’leri ile eşleşir (id, subject, type, status, priority, assignee, dueDate, updated_at vb.); WorkPackage modelinde bu alanlar varsa listelemede kullanılır.

## Hata durumları

- Görünüm listesi alınamazsa: Hata mesajı ve yenile butonu.
- Seçilen görünümün sonuçları alınamazsa: Hata mesajı ve yenile; isteğe bağlı “Varsayılan görünüme dön” seçeneği.

## Notlar

- OpenProject API: Queries endpoint’i (`/api/v3/queries`), View query (`/api/v3/queries/{id}`), Query columns (`_links.columns`), results embedded veya `_links.results` href.
- Dokümanda teknik çözüm detayı yok; implementasyon analizden sonra geliştirme adımında belirlenir.
