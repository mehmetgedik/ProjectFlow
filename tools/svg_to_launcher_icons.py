"""
Beyaz arka planlı SVG'den uygulama galerisi (launcher) ikonu PNG'lerini üretir.
Galeride görünen logonun arka planı her zaman beyaz olur.

Sırayla dener: Inkscape -> ImageMagick -> cairosvg (Windows'ta Cairo DLL gerekir).
Hiçbiri yoksa manuel talimat verir.

Kullanım: PROJE KÖKÜNDEN: python tools/svg_to_launcher_icons.py
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "apps" / "mobile" / "assets"
WHITE_SVG = ASSETS / "brand" / "projectflow_lockup_white.svg"
ICON_DIR = ASSETS / "icon"
LEGACY_PNG = ICON_DIR / "app_icon_legacy.png"
FOREGROUND_PNG = ICON_DIR / "app_icon_foreground.png"
SIZE = 1024


def _svg_to_png_inkscape(svg: Path, png: Path) -> bool:
    """Inkscape ile SVG -> PNG (Windows'ta Cairo gerekmez)."""
    exe = shutil.which("inkscape")
    if not exe:
        return False
    try:
        subprocess.run(
            [
                exe,
                str(svg),
                "--export-type=png",
                f"--export-filename={png}",
                f"--export-width={SIZE}",
                f"--export-height={SIZE}",
            ],
            check=True,
            capture_output=True,
        )
        return png.exists()
    except (subprocess.CalledProcessError, OSError):
        return False


def _svg_to_png_imagemagick(svg: Path, png: Path) -> bool:
    """ImageMagick (magick) ile SVG -> PNG."""
    for cmd in ("magick", "convert"):
        exe = shutil.which(cmd)
        if not exe:
            continue
        try:
            if cmd == "magick":
                subprocess.run(
                    [exe, str(svg), "-resize", f"{SIZE}x{SIZE}", str(png)],
                    check=True,
                    capture_output=True,
                )
            else:
                subprocess.run(
                    [exe, "-background", "white", str(svg), "-resize", f"{SIZE}x{SIZE}", str(png)],
                    check=True,
                    capture_output=True,
                )
            return png.exists()
        except (subprocess.CalledProcessError, OSError):
            continue
    return False


def _svg_to_png_cairosvg(svg: Path, png: Path) -> bool:
    """cairosvg ile SVG -> PNG (Windows'ta Cairo DLL gerekir)."""
    try:
        import cairosvg
        cairosvg.svg2png(
            url=str(svg),
            write_to=str(png),
            output_width=SIZE,
            output_height=SIZE,
        )
        return png.exists()
    except (ImportError, OSError, Exception):
        return False


def main() -> int:
    if not WHITE_SVG.exists():
        print(f"Hata: Beyaz logo bulunamadı: {WHITE_SVG}", file=sys.stderr)
        return 1

    ICON_DIR.mkdir(parents=True, exist_ok=True)

    for name, fn in (
        ("Inkscape", _svg_to_png_inkscape),
        ("ImageMagick", _svg_to_png_imagemagick),
        ("cairosvg", _svg_to_png_cairosvg),
    ):
        if fn(WHITE_SVG, LEGACY_PNG):
            print(f"[{name}] Yazıldı: {LEGACY_PNG}")
            if fn(WHITE_SVG, FOREGROUND_PNG):
                print(f"[{name}] Yazıldı: {FOREGROUND_PNG}")
                print("\nLauncher ikonları güncellendi. Sonra: cd apps\\mobile  ve  dart run flutter_launcher_icons")
                return 0
            break

    # Hiçbiri çalışmadı – manuel talimat
    print("Otomatik dönüştürücü bulunamadı (Inkscape, ImageMagick veya cairosvg+Cairo DLL).", file=sys.stderr)
    print("\n--- Manuel yöntem ---", file=sys.stderr)
    print(f"1. Şu dosyayı aç: {WHITE_SVG}", file=sys.stderr)
    print("2. Tarayıcıda açıp ekran görüntüsü al veya Inkscape/Illustrator ile 1024x1024 PNG dışa aktar.", file=sys.stderr)
    print(f"3. PNG'yi şu iki yere 1024x1024 olarak kaydet:", file=sys.stderr)
    print(f"   - {LEGACY_PNG}", file=sys.stderr)
    print(f"   - {FOREGROUND_PNG}", file=sys.stderr)
    print("4. Sonra: cd apps\\mobile  ve  dart run flutter_launcher_icons", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
