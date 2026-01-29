from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops


def crop_and_normalize_square(path: Path, pad_ratio: float, threshold: int) -> None:
    img = Image.open(path).convert("RGBA")

    # Compute difference from a white background to find content bounds.
    # Use a threshold so near-white background doesn't get treated as content.
    rgb = img.convert("RGB")
    bg_rgb = Image.new("RGB", rgb.size, (255, 255, 255))
    diff = ImageChops.difference(rgb, bg_rgb)
    mask = diff.convert("L").point(lambda p: 255 if p > threshold else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise RuntimeError("No non-white content found to crop.")

    left, top, right, bottom = bbox
    bw, bh = right - left, bottom - top
    pad = int(round(max(bw, bh) * pad_ratio))

    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(img.width, right + pad)
    bottom = min(img.height, bottom + pad)

    cropped = img.crop((left, top, right, bottom))

    # Square canvas with white background.
    side = max(cropped.width, cropped.height)
    out = Image.new("RGBA", (side, side), (255, 255, 255, 255))
    out.paste(
        cropped,
        ((side - cropped.width) // 2, (side - cropped.height) // 2),
        cropped,
    )

    # Keep original output size (launcher icon generators expect consistent size).
    out = out.resize((img.width, img.height), Image.Resampling.LANCZOS)
    out.save(path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Auto-crop app icon whitespace.")
    parser.add_argument(
        "--path",
        required=True,
        help="Path to PNG icon (e.g. apps/mobile/assets/icon/app_icon.png)",
    )
    parser.add_argument(
        "--pad",
        type=float,
        default=0.025,
        help="Padding ratio around detected content (default: 0.025)",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=12,
        help="White-difference threshold (default: 12). Higher crops more aggressively.",
    )
    args = parser.parse_args()

    icon_path = Path(args.path)
    crop_and_normalize_square(icon_path, pad_ratio=args.pad, threshold=args.threshold)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

