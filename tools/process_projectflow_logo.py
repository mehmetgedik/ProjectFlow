from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


def _bbox_from_mask(mask: np.ndarray) -> tuple[int, int, int, int] | None:
    ys, xs = np.where(mask)
    if xs.size == 0 or ys.size == 0:
        return None
    left = int(xs.min())
    right = int(xs.max()) + 1
    top = int(ys.min())
    bottom = int(ys.max()) + 1
    return left, top, right, bottom


def make_mark_icon(src: Path, out_path: Path, pad_ratio: float, white_threshold: int) -> None:
    """
    Produces an icon-only square PNG by cropping the white rounded-square region.
    This avoids the black background and ignores the dark text underneath.
    """
    img = Image.open(src).convert("RGBA")
    arr = np.array(img)
    rgb = arr[..., :3]

    # Detect "white-ish" area (the rounded square).
    white_mask = (rgb.min(axis=2) >= white_threshold)
    bbox = _bbox_from_mask(white_mask)
    if bbox is None:
        raise RuntimeError("Could not detect white icon area.")

    left, top, right, bottom = bbox
    bw, bh = right - left, bottom - top
    pad = int(round(max(bw, bh) * pad_ratio))
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(img.width, right + pad)
    bottom = min(img.height, bottom + pad)

    cropped = img.crop((left, top, right, bottom))

    # Normalize to square on transparent background (keeps icon shape intact).
    side = max(cropped.width, cropped.height)
    out = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    out.paste(
        cropped,
        ((side - cropped.width) // 2, (side - cropped.height) // 2),
        cropped,
    )

    # Store at 1024x1024 to match current assets.
    out = out.resize((1024, 1024), Image.Resampling.LANCZOS)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path)


def make_lockup(src: Path, out_path: Path, pad_ratio: float, black_threshold: int) -> None:
    """
    Produces a full-logo (icon + text) PNG with black background removed (transparent).
    Intended to be placed on a light container inside the app (not on black surfaces).
    """
    img = Image.open(src).convert("RGBA")
    arr = np.array(img)
    rgb = arr[..., :3]
    alpha = arr[..., 3]

    # Remove near-black background pixels (keep dark gray/black text).
    bg_mask = (rgb.max(axis=2) <= black_threshold) & (alpha > 0)
    arr[..., 3] = np.where(bg_mask, 0, alpha)

    out_img = Image.fromarray(arr, mode="RGBA")

    # Crop to remaining visible content (alpha > 0), with padding.
    alpha2 = np.array(out_img)[..., 3]
    bbox = _bbox_from_mask(alpha2 > 0)
    if bbox is None:
        raise RuntimeError("Could not detect lockup content after background removal.")

    left, top, right, bottom = bbox
    bw, bh = right - left, bottom - top
    pad = int(round(max(bw, bh) * pad_ratio))
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(out_img.width, right + pad)
    bottom = min(out_img.height, bottom + pad)

    cropped = out_img.crop((left, top, right, bottom))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(out_path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Process ProjectFlow logo assets.")
    parser.add_argument("--src", required=True, help="Source PNG path")
    parser.add_argument("--out-mark", required=True, help="Output icon-only PNG path")
    parser.add_argument("--out-lockup", required=True, help="Output full-logo PNG path")
    parser.add_argument("--pad", type=float, default=0.02, help="Padding ratio (default: 0.02)")
    parser.add_argument(
        "--white-threshold",
        type=int,
        default=240,
        help="White threshold for detecting icon area (default: 240)",
    )
    parser.add_argument(
        "--black-threshold",
        type=int,
        default=16,
        help="Black threshold for removing background (default: 16)",
    )
    args = parser.parse_args()

    src = Path(args.src)
    make_mark_icon(
        src=src,
        out_path=Path(args.out_mark),
        pad_ratio=args.pad,
        white_threshold=args.white_threshold,
    )
    make_lockup(
        src=src,
        out_path=Path(args.out_lockup),
        pad_ratio=args.pad,
        black_threshold=args.black_threshold,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

