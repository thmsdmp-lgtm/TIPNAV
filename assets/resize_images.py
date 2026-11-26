#!/usr/bin/env python3
"""
Recursively find images in a folder and scale them down by a percentage.

- Files keep their original relative path (and name).
- Aspect ratio is preserved (same scale factor applied to width and height).
- By default, the resized images are written to a separate output folder that
  mirrors the input folder structure. Use --in-place to overwrite originals.

Requires: Pillow  ->  pip install pillow

Examples:
    python resize_images.py ./photos 50
    python resize_images.py ./photos 25 -o ./photos_small
    python resize_images.py ./photos 50 --in-place
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageOps

IMAGE_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".bmp", ".gif", ".tif", ".tiff", ".webp",
}


def find_images(root: Path, skip_dir: Path | None = None):
    """Yield every image file under root (deep search), skipping skip_dir."""
    for path in root.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in IMAGE_EXTENSIONS:
            continue
        if skip_dir is not None and skip_dir in path.parents:
            continue
        yield path


def resize_image(src: Path, dst: Path, percent: float) -> tuple[tuple, tuple]:
    """Resize src to `percent`% of its pixel dimensions and save to dst."""
    scale = percent / 100.0

    with Image.open(src) as img:
        # Respect EXIF orientation so the result isn't rotated unexpectedly.
        img = ImageOps.exif_transpose(img)
        old_size = img.size
        new_size = (
            max(1, round(old_size[0] * scale)),
            max(1, round(old_size[1] * scale)),
        )

        fmt = img.format or src.suffix.lstrip(".").upper()
        if fmt == "JPG":
            fmt = "JPEG"

        if getattr(img, "is_animated", False) and fmt in ("GIF", "WEBP"):
            # Resize every frame of animated images.
            frames = []
            durations = []
            for frame in range(img.n_frames):
                img.seek(frame)
                frames.append(img.convert("RGBA").resize(new_size, Image.LANCZOS))
                durations.append(img.info.get("duration", 100))
            dst.parent.mkdir(parents=True, exist_ok=True)
            frames[0].save(
                dst,
                format=fmt,
                save_all=True,
                append_images=frames[1:],
                duration=durations,
                loop=img.info.get("loop", 0),
            )
            return old_size, new_size

        resized = img.resize(new_size, Image.LANCZOS)

        save_kwargs = {}
        if fmt == "JPEG":
            if resized.mode not in ("RGB", "L"):
                resized = resized.convert("RGB")
            save_kwargs = {"quality": 90, "optimize": True}
        elif fmt == "PNG":
            save_kwargs = {"optimize": True}

        dst.parent.mkdir(parents=True, exist_ok=True)
        resized.save(dst, format=fmt, **save_kwargs)

    return old_size, new_size


def main():
    parser = argparse.ArgumentParser(
        description="Recursively reduce image pixel size by a percentage."
    )
    parser.add_argument("folder", type=Path, help="Folder to search (recursively).")
    parser.add_argument(
        "percent",
        type=float,
        nargs="?",
        help="Percent of original size to keep (e.g. 50 = half the width/height).",
    )
    parser.add_argument(
        "-o", "--output", type=Path, default=None,
        help="Output folder (default: '<folder>_resized' next to the input folder).",
    )
    parser.add_argument(
        "--in-place", action="store_true",
        help="Overwrite the original images instead of writing to an output folder.",
    )
    args = parser.parse_args()

    root = args.folder.resolve()
    if not root.is_dir():
        sys.exit(f"Error: '{root}' is not a folder.")

    percent = args.percent
    if percent is None:
        try:
            percent = float(input("Resize to what percentage of original size? (e.g. 50): "))
        except ValueError:
            sys.exit("Error: percentage must be a number.")
    if not 0 < percent <= 100:
        sys.exit("Error: percentage must be greater than 0 and at most 100.")

    if args.in_place:
        out_root = root
    else:
        out_root = (args.output or root.with_name(root.name + "_resized")).resolve()
    skip_dir = out_root if out_root != root and root in out_root.parents else None

    if args.in_place:
        confirm = input("This will OVERWRITE original images. Continue? [y/N]: ")
        if confirm.strip().lower() != "y":
            sys.exit("Aborted.")

    done = failed = 0
    for src in find_images(root, skip_dir):
        rel = src.relative_to(root)  # keeps the original path structure
        dst = out_root / rel
        try:
            old, new = resize_image(src, dst, percent)
            print(f"[OK]   {rel}  {old[0]}x{old[1]} -> {new[0]}x{new[1]}")
            done += 1
        except Exception as e:  # noqa: BLE001
            print(f"[FAIL] {rel}: {e}")
            failed += 1

    print(f"\nDone. {done} resized, {failed} failed.")
    if not args.in_place:
        print(f"Output: {out_root}")


if __name__ == "__main__":
    main()
