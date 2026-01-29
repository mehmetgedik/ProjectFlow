"""
Şeffaf kısımlarda siyah çerçeve/artefakt kalmaması için PNG temizler.
- Düşük alpha'lı pikselleri tam şeffaf yapar (R,G,B=0, A=0).
- Siyah veya koyu yarı-şeffaf pikselleri de tam şeffaf yapabilir (opsiyonel).
"""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def clean_transparent(
    path: Path,
    alpha_threshold: int = 128,
    black_bleed: bool = True,
    black_rgb_max: int = 24,
    remove_black_bg: bool = False,
    black_bg_max: int = 32,
) -> None:
    """
    path: Girdi/çıktı PNG (üzerine yazar).
    alpha_threshold: Bu değerin altındaki alpha → tam şeffaf (0,0,0,0).
    black_bleed: True ise siyaha yakın + yarı şeffaf pikselleri de tam şeffaf yapar.
    black_rgb_max: black_bleed için RGB max (hepsi <= ise "siyah" sayılır).
    remove_black_bg: True ise tam opak siyah arka plan da şeffaf yapılır (lockup için).
    black_bg_max: remove_black_bg için RGB üst sınırı (hepsi <= ise arka plan sayılır).
    """
    img = Image.open(path).convert("RGBA")
    arr = np.array(img, dtype=np.uint32)
    r = arr[..., 0].astype(np.uint32)
    g = arr[..., 1].astype(np.uint32)
    b = arr[..., 2].astype(np.uint32)
    a = arr[..., 3].astype(np.uint32)

    # Tam opak siyah arka planı kaldır (login lockup'taki siyah kutu).
    if remove_black_bg:
        is_black_bg = (r <= black_bg_max) & (g <= black_bg_max) & (b <= black_bg_max)
        r = np.where(is_black_bg, 0, r)
        g = np.where(is_black_bg, 0, g)
        b = np.where(is_black_bg, 0, b)
        a = np.where(is_black_bg, 0, a)

    # Düşük alpha → tam şeffaf; RGB'yi de sıfırla ki siyah görünmesin.
    low_alpha = a < alpha_threshold
    r = np.where(low_alpha, 0, r)
    g = np.where(low_alpha, 0, g)
    b = np.where(low_alpha, 0, b)
    a = np.where(low_alpha, 0, a)

    if black_bleed:
        # Siyaha yakın ve yarı şeffaf pikseller → tam şeffaf (siyah çerçeve kaldır).
        is_black = (r <= black_rgb_max) & (g <= black_rgb_max) & (b <= black_rgb_max)
        semi = (a > 0) & (a < 255)
        to_clear = is_black & semi
        r = np.where(to_clear, 0, r)
        g = np.where(to_clear, 0, g)
        b = np.where(to_clear, 0, b)
        a = np.where(to_clear, 0, a)

    out = np.stack([r.astype(np.uint8), g.astype(np.uint8), b.astype(np.uint8), a.astype(np.uint8)], axis=-1)
    Image.fromarray(out, mode="RGBA").save(path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Clean transparent areas of a PNG (no black frame).")
    parser.add_argument("path", type=Path, help="PNG file path (modified in place)")
    parser.add_argument("--alpha", type=int, default=128, help="Alpha below this → full transparent (default: 128)")
    parser.add_argument("--no-black-bleed", action="store_true", help="Do not clear semi-transparent black pixels")
    parser.add_argument("--black-max", type=int, default=24, help="RGB max for 'black' in black-bleed (default: 24)")
    parser.add_argument("--remove-black-bg", action="store_true", help="Make solid black background transparent (for lockup)")
    parser.add_argument("--black-bg-max", type=int, default=32, help="RGB max for black background (default: 32)")
    args = parser.parse_args()

    clean_transparent(
        args.path,
        alpha_threshold=args.alpha,
        black_bleed=not args.no_black_bleed,
        black_rgb_max=args.black_max,
        remove_black_bg=args.remove_black_bg,
        black_bg_max=args.black_bg_max,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
