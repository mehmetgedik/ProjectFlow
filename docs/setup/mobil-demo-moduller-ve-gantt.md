# Mobil Demo projesi: Modüller ve Gantt görünümü

Projede birçok modülü (Gantt dahil) açmak için **Proje ayarları → Modüller** ekranını kullanın. API ile modül açma birçok kurulumda desteklenmediği için bu adımlar manuel yapılır.

## Adımlar

1. **Modüller sayfasına gidin**
   - Doğrudan link:  
     **https://openproject.example.com/projects/mobil-demo/settings/modules**
   - Veya: Proje **Mobil Demo** seçili iken sol menüden **Proje ayarları** → **Modüller**.

2. **Açmak istediğiniz modülleri işaretleyin**
   - **Gantt charts** – Zaman çizelgesi / Gantt görünümü (önerilen).
   - **Work packages** – Zaten açık; iş paketleri listesi ve detay.
   - **Time tracking** – Zaman kaydı.
   - **Calendar** – Takvim görünümü.
   - **Activity** – Son aktiviteler.
   - **Wiki** – Wiki sayfaları.
   - **News** – Haberler.
   - **Meetings** – Toplantılar (varsa).
   - **Documents** – Belgeler (varsa).
   - **Boards** – Kanban/Agile panolar (varsa).
   - **Backlogs** – Scrum backlog (varsa).

3. **Kaydedin**
   - Sayfanın altındaki **Kaydet** butonuna tıklayın.

4. **Gantt görünümünü açın**
   - Sol proje menüsünde **Gantt charts** görünür.
   - Tıklayınca projedeki iş paketleri tarih çizelgesi (Gantt) olarak listelenir.

## Not

- Hangi modüllerin listede olduğu, OpenProject sürümüne ve yönetici ayarlarına bağlıdır.
- Bazı modüller (örn. Backlogs, Boards) Enterprise veya ek eklentilerle gelir; yoksa listede çıkmayabilir.
- Script: `tools/openproject_demo_modules.py` API ile modül açmayı dener; kurulumunuz desteklemiyorsa yukarıdaki manuel adımları kullanın.
