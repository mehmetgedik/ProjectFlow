# Mobil Demo: Sorgular ve Kontrol

Mobil Demo projesi için kayıtlı sorgular (görünümler) oluşturma ve proje durumunu kontrol etme.

## Gantt dahil tüm durumları izleme

Kontrol scripti aşağıdakileri raporlar:

| İzlenen durum | Açıklama |
|---------------|----------|
| **Proje modülleri** | Gantt, Calendar, Time tracking vb. – API döndürürse listelenir; birçok instance’ta API’de yok, o zaman “Proje ayarları → Modüller” ile manuel kontrol edilir. |
| **İş paketi sayısı** | Projedeki toplam iş paketi. |
| **Tip dağılımı** | Epik / Görev (ve diğer tipler) adetleri. |
| **Durum dağılımı** | Açık (Yeni, Devam ediyor) ve kapalı (Tamamlandı vb.) adetleri. |
| **Proje üyeleri** | Yetki varsa üye ve rol listesi. |
| **Kayıtlı sorgular** | Projeye ait görünümler (Açık işler, Tamamlananlar, Epic'ler vb.). |

Gantt’ın açık olup olmadığı: Eğer proje API yanıtında `enabled_module_names` (veya modül listesi) varsa script bunu gösterir; yoksa [Modüller ve Gantt](mobil-demo-moduller-ve-gantt.md) sayfasındaki manuel adımlarla kontrol edilir.

## Kontrol scripti

`tools/openproject_demo_check.py` ile proje durumu özetlenir:

- Proje adı ve ID
- Proje modülleri (Gantt dahil – API’de varsa)
- İş paketi sayısı, tip ve durum dağılımı
- Proje üyeleri (yetki varsa)
- Kayıtlı sorgular listesi

**Kullanım**

```bash
set OPENPROJECT_URL=https://openproject.example.com
set OPENPROJECT_API_KEY=your_api_key
python tools/openproject_demo_check.py
```

İsteğe bağlı: `--project mobil-demo` (varsayılan zaten `mobil-demo`).

## Kayıtlı sorgu oluşturma

`tools/openproject_demo_queries.py` Mobil Demo projesi için örnek görünümler oluşturur:

| Sorgu adı        | Açıklama                          |
|------------------|-----------------------------------|
| Açık işler       | Durumu "açık" olan iş paketleri   |
| Tamamlananlar    | Durumu "kapalı" olan iş paketleri |
| Epic'ler         | Tipi Epik olanlar                 |
| Görevler         | Tipi Görev olanlar                |
| Bana atananlar   | Bana atanmış iş paketleri         |

Aynı isimde sorgu zaten varsa atlanır. Oluşturulan sorgular projeye özeldir ve varsayılan olarak gizli (public=False).

**Kullanım**

```bash
set OPENPROJECT_URL=https://openproject.example.com
set OPENPROJECT_API_KEY=your_api_key
python tools/openproject_demo_queries.py
```

- `--project-id 10` ile proje ID verilebilir (yoksa `mobil-demo` identifier ile bulunur).
- `--dry-run` ile sadece yapılacak işler listelenir, sorgu oluşturulmaz.

Kimlik bilgileri `bilgiler.txt` (repo dışında tutulmalı) ile de verilebilir: ilk satır URL, ikinci satır API anahtarı.

## esad.gedik kullanıcı aktivitesi (zaman kayıtları)

Demo artık **esad.gedik** kullanıcısı ile çalışıyor gibi göstermek için, bu kullanıcıya farklı zamanlarda yapılmış geliştirme çalışması gibi görünen **zaman kayıtları** eklenebilir.

**Script:** `tools/openproject_demo_esad_activity.py`

- `esad.gedik` kullanıcısını bulur ve bu kullanıcı adına (veya API kullanıcısı adına, yetkiye göre) zaman kayıtları oluşturur.
- Son N gün içinde hafta içi tarihlere dağıtılmış, farklı iş paketlerinde, geliştirme/code review/test benzeri yorumlarla kayıt ekler.

**Kullanım**

```bash
set OPENPROJECT_URL=https://openproject.example.com
set OPENPROJECT_API_KEY=your_api_key
python tools/openproject_demo_esad_activity.py
```

- `--count 24` – eklenecek zaman kaydı sayısı (varsayılan 24)
- `--days-back 28` – kaç gün geriye kadar tarih dağıtılsın (varsayılan 28)
- `--dry-run` – sadece ne yapılacağını yazdırır

Kayıtların **esad.gedik** kullanıcısına görünmesi: API anahtarı sahibinin “başkası adına zaman kaydetme” yetkisi varsa kayıtlar esad.gedik’e atanır; yoksa API anahtarı sahibi kullanıcıya kaydedilir (o durumda demo için esad.gedik’in API anahtarı ile çalıştırmak gerekir).

## Demo projede başka kullanım senaryoları

Proje yönetim sisteminde olması gereken farklı kullanım örneklerini Mobil Demo’ya eklemek için:

**Script:** `tools/openproject_demo_scenarios.py`

Eklenen senaryo türleri:

| Senaryo | Açıklama | Örnekler |
|---------|----------|----------|
| **Kilometre taşları (milestone)** | Tarihli hedefler | v1.0 Planlama tamamlandı, İlk release (alfa), Beta yayını, v1.0 Release |
| **Hata (bug)** | Hata takibi, farklı öncelikler | Login ekranında hata, Bildirim gecikmesi, Çökme: detay ekranı |
| **Destek / talep** | Farklı durumlar (yeni, işlemde, tamamlandı, iptal) | Bildirim ayarı (yeni), Liste yenileme (işlemde), Dokümantasyon (tamamlandı), Dark mode (yeni), Oturum zaman aşımı (işlemde), İptal talebi (iptal) |
| **Görev (task)** | Farklı öncelikler (acil, yüksek, normal, düşük) ve durumlar | Acil: güvenlik güncellemesi, Yüksek: raporlama, Normal: birim testleri, Düşük: UI iyileştirme, Acil: production hotfix (tamamlandı) |
| **Toplantı** | Tarihli toplantılar | Sprint planlama, Retrospective, Teknik değerlendirme |
| **Blokaj / risk** | Risk ve blokaj takibi | Blokaj: API yanıt süresi, Risk: yetkilendirme |
| **Faz (phase)** | Dönemler, Gantt için tarih aralığı | Faz 1: Planlama, Faz 2: Geliştirme, Faz 3: Test ve release |

Instance’ta **Bug** tipi varsa hatalar Bug olarak, **Milestone / Meeting / Phase / Support** tipleri varsa ilgili tip kullanılır; yoksa Görev (Task) ile oluşturulur. Tarihli öğeler Gantt görünümünde görülebilir. Varsayılan atanan: **esad.gedik**.

**Kullanım**

```bash
set OPENPROJECT_URL=https://openproject.example.com
set OPENPROJECT_API_KEY=your_api_key
python tools/openproject_demo_scenarios.py
```

- `--dry-run` – sadece eklenecek senaryoları listeler.

## Proje sürümleri (versions) ve zamanı geçmiş / devam eden task’lar

Mobil Demo projesi için **sürümler** (v1.0, v1.1, Sprint 1, Sprint 2, Beta) oluşturulur ve iş paketlerine sürüm + bitiş/başlangıç tarihi atanır; böylece **zamanı geçmiş** (overdue) ve **devam eden** (ongoing) task’lar senaryoda yer alır.

**Script:** `tools/openproject_demo_versions.py`

- Projede sürüm yoksa oluşturur: **v1.0** (kapalı, geçmiş), **v1.1** (açık, devam eden), **Sprint 1** (kapalı), **Sprint 2** (açık), **Beta** (açık).
- İş paketlerinin yaklaşık 1/4’üne **zamanı geçmiş** (due date geçmişte), 1/2’sine **devam eden** (due date bugün civarı veya yakın gelecek), 1/4’üne **gelecek** tarih atanır ve ilgili sürüme bağlanır.

**Kullanım**

```bash
set OPENPROJECT_URL=https://openproject.example.com
set OPENPROJECT_API_KEY=your_api_key
python tools/openproject_demo_versions.py
```

- `--dry-run` – sadece yapılacak işleri listeler.
- Sürüm oluşturmak için **manage versions** yetkisi gerekir.

## Takip notu ve durum ilerletme (test, gözden geçirme)

Bazı task’lara **takip notu** (yorum/aktivite) eklemek ve bazı task’ların durumunu **test**, **gözden geçirme**, **tamamlandı** vb. ilerletmek için:

**Script:** `tools/openproject_demo_notes_and_status.py`

- Seçilen task’lara takip notu metinleri ekler (POST `/work_packages/{id}/activities`).
- Seçilen task’ların durumunu günceller: **Devam ediyor**, **Test**, **Gözden geçirme**, **Tamamlandı** (instance’ta bu isimlerde status varsa).

**Kullanım**

```bash
set OPENPROJECT_URL=https://openproject.example.com
set OPENPROJECT_API_KEY=your_api_key
python tools/openproject_demo_notes_and_status.py
```

- `--notes-count 18` – kaç task’a takip notu eklensin (varsayılan 18).
- `--status-count 25` – kaç task’ın durumu güncellensin (varsayılan 25).
- `--dry-run` – sadece ne yapılacağını yazdırır.

Yorumlar API anahtarı sahibi kullanıcı adına eklenir (ilgili kullanıcı olarak görünür).

## Sıra önerisi

1. `openproject_demo_check.py` ile mevcut durumu kontrol et.
2. `openproject_demo_queries.py` ile kayıtlı sorguları oluştur.
3. `openproject_demo_scenarios.py` ile farklı kullanım senaryolarını (milestone, bug, destek, toplanti, risk, faz) ekle.
4. `openproject_demo_versions.py` ile proje sürümlerini oluştur; zamanı geçmiş ve devam eden task’lara sürüm ve tarih ata.
5. İsteğe bağlı: `openproject_demo_esad_activity.py` ile esad.gedik için zaman kayıtları ekle.
6. `openproject_demo_notes_and_status.py` ile bazı task’lara takip notu ekleyip durumları test/gözden geçirme/tamamlandı ilerlet.
7. Tekrar `openproject_demo_check.py` ile iş paketi sayısı, durum dağılımı ve sürümleri doğrula.
8. Web veya mobil uygulamada projeyi açıp "Görünümler" / kayıtlı sorgulardan birini seçerek, sürüm filtresi ve Gantt’ta tarihli/overdue öğeleri görüntüleyerek test et.
