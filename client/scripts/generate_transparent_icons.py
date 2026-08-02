#!/usr/bin/env python3
"""
Generate transparent app icon PNGs from a source logo PNG.

Why this exists:
- `assets/icons/logo.png` may contain a solid background (often black) that
  shows up as an unwanted square in-app.
- Some resize pipelines can also strip the alpha channel.

This script:
- Removes a solid edge-connected background via flood-fill from the image border.
- Preserves alpha.
- Writes:
  - assets/icons/app_logo_1024.png
  - assets/icons/app_logo_512.png
  - assets/icons/app_logo_256.png
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image


@dataclass(frozen=True)
class Config:
    input_path: Path
    output_dir: Path
    sizes: tuple[int, ...] = (1024, 512, 256)
    # Max color distance from the detected background for flood fill.
    # Increase if your background isn't perfectly flat.
    bg_threshold: int = 18


def _color_dist(a: tuple[int, int, int], b: tuple[int, int, int]) -> int:
    return abs(a[0] - b[0]) + abs(a[1] - b[1]) + abs(a[2] - b[2])


def _border_coords(w: int, h: int) -> Iterable[tuple[int, int]]:
    for x in range(w):
        yield (x, 0)
        yield (x, h - 1)
    for y in range(1, h - 1):
        yield (0, y)
        yield (w - 1, y)


def remove_edge_connected_background(img: Image.Image, threshold: int) -> Image.Image:
    """
    Flood-fill from the border using the top-left pixel as the background color.
    Any pixel edge-connected to the border whose RGB is within `threshold` of the
    background RGB will be made fully transparent.
    """
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    bg = px[0, 0][:3]
    visited = bytearray(w * h)
    q: deque[tuple[int, int]] = deque()

    def push(x: int, y: int) -> None:
        idx = y * w + x
        if visited[idx]:
            return
        visited[idx] = 1
        rgb = px[x, y][:3]
        if _color_dist(rgb, bg) <= threshold:
            q.append((x, y))

    for x, y in _border_coords(w, h):
        push(x, y)

    while q:
        x, y = q.popleft()
        r, g, b, _a = px[x, y]
        px[x, y] = (r, g, b, 0)

        if x > 0:
            push(x - 1, y)
        if x + 1 < w:
            push(x + 1, y)
        if y > 0:
            push(x, y - 1)
        if y + 1 < h:
            push(x, y + 1)

    return rgba


def main() -> int:
    cfg = Config(
        input_path=Path("assets/icons/logo.png"),
        output_dir=Path("assets/icons"),
    )

    if not cfg.input_path.exists():
        raise SystemExit(f"Missing input file: {cfg.input_path}")

    cfg.output_dir.mkdir(parents=True, exist_ok=True)

    src = Image.open(cfg.input_path)
    cleaned = remove_edge_connected_background(src, cfg.bg_threshold)

    # Always write the 1024 first, then downscale from that for consistent results.
    out_1024 = cfg.output_dir / "app_logo_1024.png"
    cleaned.resize((1024, 1024), Image.Resampling.LANCZOS).save(out_1024)

    for size in (512, 256):
        out = cfg.output_dir / f"app_logo_{size}.png"
        Image.open(out_1024).resize((size, size), Image.Resampling.LANCZOS).save(out)

    print("Wrote:")
    for size in cfg.sizes:
        print(f" - {cfg.output_dir / f'app_logo_{size}.png'}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())


