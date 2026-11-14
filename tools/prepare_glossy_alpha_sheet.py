#!/usr/bin/env python3
"""Make a real-alpha 4-column Glossy Kawaii sprite sheet from an RGBA atlas.

Each input cell must be square. Detached visual particles are removed by
retaining the largest 8-connected alpha silhouette per cell. Review animation
manually: detached motion effects may be intentionally removed.
Example: python tools/prepare_glossy_alpha_sheet.py raw.png sheet_illustrated.webp
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from collections import deque
from PIL import Image, ImageChops, ImageFilter


def largest_component(alpha: Image.Image, threshold: int = 48) -> Image.Image:
    if alpha.mode != "L":
        raise ValueError("Expected grayscale alpha")
    width, height = alpha.size
    binary = alpha.point(lambda a: 255 if a >= threshold else 0)
    binary = binary.filter(ImageFilter.MedianFilter(3))
    values = binary.tobytes()
    visited = bytearray(width * height)
    biggest = []
    for start, value in enumerate(values):
        if not value or visited[start]:
            continue
        visited[start] = 1
        queue = deque([start])
        component = []
        while queue:
            idx = queue.popleft()
            component.append(idx)
            y, x = divmod(idx, width)
            for dx, dy in ((-1, -1), (0, -1), (1, -1), (-1, 0),
                           (1, 0), (-1, 1), (0, 1), (1, 1)):
                xx, yy = x + dx, y + dy
                if not (0 <= xx < width and 0 <= yy < height):
                    continue
                pos = yy * width + xx
                if values[pos] and not visited[pos]:
                    visited[pos] = 1
                    queue.append(pos)
        if len(component) > len(biggest):
            biggest = component
    if not biggest:
        raise ValueError("No visible sprite silhouette in frame")
    data = bytearray(width * height)
    for pos in biggest:
        data[pos] = 255
    return Image.frombytes("L", (width, height), bytes(data)).filter(
        ImageFilter.MaxFilter(5)
    )


def prepare(source: Path, output: Path, frames: int = 12,
            columns: int = 4, size: int = 256, padding: int = 12) -> dict:
    if not 2 <= frames <= 24 or columns < 1 or size < 64:
        raise ValueError("Invalid frame geometry")
    if padding < 4 or padding * 2 >= size:
        raise ValueError("Padding must leave a visible sprite area")
    rows = (frames + columns - 1) // columns
    with Image.open(source) as im:
        if "A" not in im.getbands():
            raise ValueError("Input must have an alpha channel, not a white background")
        if im.width % columns or im.height % rows:
            raise ValueError("Input atlas dimensions must divide evenly by grid")
        if im.width // columns != im.height // rows:
            raise ValueError("Input cells must be square")
        original = im.convert("RGBA")
    incoming = original.width // columns
    sheet = Image.new("RGBA", (columns * size, rows * size), (0, 0, 0, 0))
    for i in range(frames):
        col, row = i % columns, i // columns
        frame = original.crop((col * incoming, row * incoming,
                               (col + 1) * incoming, (row + 1) * incoming))
        mask = largest_component(frame.getchannel("A"))
        frame.putalpha(ImageChops.multiply(frame.getchannel("A"), mask))
        side = size - 2 * padding
        frame = frame.resize((side, side), Image.Resampling.LANCZOS)
        sheet.alpha_composite(frame, (col * size + padding, row * size + padding))
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.suffix.lower() == ".webp":
        sheet.save(output, format="WEBP", lossless=True, method=6)
    elif output.suffix.lower() == ".png":
        sheet.save(output, format="PNG", optimize=True)
    else:
        raise ValueError("Output extension must be PNG or WebP")
    with Image.open(output) as verify:
        if verify.mode != "RGBA" or verify.getpixel((0, 0))[3] != 0:
            raise AssertionError("Export lost true alpha transparency")
    return {"source": str(source), "output": str(output),
            "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
            "frames": frames, "columns": columns, "frameSize": size,
            "alpha": "true", "visualReview": "pending", "deviceQA": "pending"}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--frames", type=int, default=12)
    parser.add_argument("--columns", type=int, default=4)
    parser.add_argument("--size", type=int, default=256)
    parser.add_argument("--padding", type=int, default=12)
    args = parser.parse_args()
    print(json.dumps(prepare(args.source, args.output, frames=args.frames,
          columns=args.columns, size=args.size, padding=args.padding), indent=2))


if __name__ == "__main__":
    main()
