# OpenProject Mobile – Assets (ProjectFlow)

## Logo: SVG (tema uyumlu)

Uygulama logoları **SVG** ile gösteriliyor; böylece her temada (açık/koyu) arka plan sorunu olmadan uyumlu görünür.

| Asset | Açıklama | Kullanım yeri |
|-------|----------|----------------|
| **`brand/projectflow_mark.svg`** | Sadece mark (ikon). **Arka plan yok (şeffaf).** | AppBar’daki logo butonu (Profil, Projeler, İş paketleri, Bildirimler, Dashboard). |
| **`brand/projectflow_lockup.svg`** | Mark + “ProjectFlow” yazısı. **Arka plan yok (şeffaf).** | Splash ekranı, Login (Bağlan) ekranı. |
| **`brand/projectflow_lockup_white.svg`** | Beyaz arka planlı lockup (yedek). | Gerekirse koyu zeminlerde kullanılabilir. |

Mark ve lockup şu an **seffaf.svg** (şeffaf) ile dolduruldu; **beyaz.svg** `projectflow_lockup_white.svg` olarak yedekte. PNG yedekleri (`projectflow_mark.png`, `projectflow_lockup.png`) hâlâ asset listesinde.

---

## Senden istenen SVG’ler

**Her türlü temaya uyumlu** logo için şu iki dosyayı **SVG** olarak sağlaman yeterli:

1. **`projectflow_mark.svg`**  
   - Sadece ikon (mor + turkuaz şekiller).  
   - Arka plan olmasın (şeffaf).  
   - İstersen yazı/metin renginin temaya göre değişmesi için SVG içinde `fill="currentColor"` kullan; uygulama tema rengini otomatik verir.

2. **`projectflow_lockup.svg`**  
   - İkon + “ProjectFlow” yazısı.  
   - Arka plan olmasın (şeffaf).  
   - Yazı için `fill="currentColor"` kullanırsan açık/koyu temada okunaklı olur.

Dosyaları şuraye koy:  
`apps/mobile/assets/brand/`  
- `projectflow_mark.svg`  
- `projectflow_lockup.svg`  

Mevcut placeholder SVG’leri bu dosyalarla değiştir; uygulama aynı yolları kullanıyor.

---

## Diğer asset’ler (launcher – arka plan her zaman beyaz)

Galeride görünen ikonun arka planı her zaman beyaz: Android `ic_launcher_background` = `#FFFFFF`, `adaptive_icon_background: "#FFFFFF"`. Kaynak PNG'ler beyaz logodan (beyaz.svg) üretilmeli.

| Asset | Açıklama |
|-------|----------|
| **`icon/app_icon_legacy.png`** | Tam ikon, beyaz zemin (galeri). |
| **`icon/app_icon_foreground.png`** | Adaptive ikon ön planı (Android 8+); arka plan beyaz. |

**Beyaz SVG'den launcher PNG üretmek (Windows):**

**A) Tek tık (önerilen):**  
Proje kökündeki **`generate_launcher_icons.bat`** dosyasını çalıştır (çift tık veya CMD'den tam yol):
```bat
D:\MG\Project\Mobile\OpenProject\generate_launcher_icons.bat
```
Bittikten sonra: `cd D:\MG\Project\Mobile\OpenProject\apps\mobile` → `dart run flutter_launcher_icons`

**B) Elle:** Önce **mutlaka proje köküne** geç (prompt `D:\MG\Project\Mobile\OpenProject>` olmalı):
```bat
cd /d D:\MG\Project\Mobile\OpenProject
python tools\svg_to_launcher_icons.py
```
Sonra: `cd apps\mobile` → `dart run flutter_launcher_icons`

Alternatif: beyaz.svg'yi 1024×1024 PNG olarak dışa aktarıp `apps/mobile/assets/icon/` altında `app_icon_legacy.png` ve `app_icon_foreground.png` olarak kaydet, sonra `dart run flutter_launcher_icons`.
