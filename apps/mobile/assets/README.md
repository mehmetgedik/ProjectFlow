# OpenProject Mobile – Assets (ProjectFlow)

## Logo kullanımı

| Asset | Açıklama | Kullanım yeri |
|-------|----------|----------------|
| **`brand/projectflow_mark.png`** | Sadece mark (ikon), **şeffaf arka plan**. Çerçeve yok; şeffaf kısımda ekranın arka planı görünür. | AppBar’daki logo butonu (Profil, Projeler, İş paketleri, Bildirimler, Dashboard). |
| **`brand/projectflow_lockup.png`** | Mark + “ProjectFlow” metni. | Splash ekranı, Bağlan ekranı (Container içinde). |
| **`icon/app_icon.png`** | Uygulama launcher ikonu (tam kare). | Genel uygulama ikonu. |
| **`icon/app_icon_foreground.png`** | Adaptive ikon ön planı (Android 8+). | Android adaptive icon. |
| **`icon/app_icon_legacy.png`** | Eski launcher’lar için tam ikon. | Eski Android launcher’lar. |

## Kurallar

- **Uygulama yönetim / profil ekranında** (ve tüm AppBar’larda): Logo **çerçevesiz**; şeffaf kısımda arka plan rengi verilmez, mevcut arka plan görünür.
- **Şeffaf logo** (`projectflow_mark.png`): Sadece mark; kare, şeffaf arka plan – AppBar ve in-app kullanım için.
- **Beyaz arka planlı logo**: Gerekirse splash/connect kartı veya basılı materyaller için kullanılabilir; şu an lockup ayrı bir asset.

## Gerekli boyutlar

- **Mark (AppBar)**: Mevcut `projectflow_mark.png` tek dosya; Flutter `width`/`height` ile ölçeklenir (örn. 28dp). İsterseniz 1x, 2x, 3x için `projectflow_mark.png`, `2.0x/projectflow_mark.png` vb. eklenebilir.
- **Launcher**: `flutter_launcher_icons` kullanılıyor; kaynak `app_icon_foreground.png` ve `app_icon_legacy.png`. Değiştirdikten sonra: `dart run flutter_launcher_icons`.
- **Web**: `web/icons/` ve `web/favicon.png` – gerekirse aynı mark/lockup’tan türetilebilir.
