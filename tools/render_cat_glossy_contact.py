#!/usr/bin/env python3
"""Build a truthful, visual contact sheet from verified Cat Glossy V2 atlases.

This is a human-review sheet, not an automated art acceptance score.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CAT = ROOT / "assets/characters-v2/cat"
OUT = ROOT / "design/review/cat-glossy-v2-contact.png"
CELL = 256


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def font(size: int):
    try:
        return ImageFont.truetype("DejaVuSans.ttf", size)
    except OSError:
        return ImageFont.load_default()


def main():
    manifest = json.loads((CAT / "manifest.json").read_text(encoding="utf-8"))
    states = list(manifest["states"])
    if not states:
        raise AssertionError("No Cat animation states in manifest")
    cols = len(states)
    x_step, y_step = 282, 316
    top = 92
    board = Image.new("RGB", (max(cols*x_step + 22, 610), top + 4*y_step + 65), (246, 242, 252))
    draw = ImageDraw.Draw(board)
    ink, muted, accent = (57, 40, 81), (117, 104, 137), (125, 83, 207)
    draw.text((25, 18), "OneLife  |  Cat Glossy V2  |  Illustration QA", fill=ink, font=font(23))
    draw.text((25, 55), "Original PNG frames, not static character masters. Visual/device acceptance pending.", fill=muted, font=font(13))

    for col, state in enumerate(states):
        folder = CAT / state
        meta = json.loads((folder / "metadata.json").read_text(encoding="utf-8"))
        path = folder / meta["runtimeAsset"]
        if digest(path) != meta["sha256"]:
            raise AssertionError(f"PNG digest mismatch: {state}")
        with Image.open(path) as atlas:
            img = atlas.convert("RGBA")
        frames = int(meta["frames"])
        columns = int(meta["columns"])
        rows = int(meta["rows"])
        if img.size != (columns*CELL, rows*CELL):
            raise AssertionError(f"Invalid atlas shape: {state}")
        selected = [0, frames//3, 2*frames//3, frames-1]
        x0 = col*x_step + 16
        draw.text((x0+15, 80), f"{state.upper()}  ({frames} frames)", fill=accent, font=font(16))
        for row, index in enumerate(selected):
            x = index % columns * CELL
            y = index // columns * CELL
            frame = img.crop((x, y, x+CELL, y+CELL))
            yy = top + row*y_step
            draw.rounded_rectangle((x0+2, yy+10, x0+265, yy+278), radius=17, fill=(255, 255, 255), outline=(226, 217, 238), width=2)
            board.paste(frame, (x0+7, yy+13), frame)
            # Real 64-pixel view embedded below each pose to reveal small-scale legibility.
            small = frame.resize((64, 64), Image.Resampling.LANCZOS)
            board.paste(small, (x0+186, yy+195), small)
            draw.text((x0+10, yy+282), f"Frame {index+1:02d}/{frames:02d}   |   64px inset", fill=muted, font=font(12))
    draw.text((25, board.height-30), "Technical frame checks do NOT establish emotional quality, smooth animation, or Android/iOS performance.", fill=muted, font=font(12))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    board.save(OUT, optimize=True)
    print(f"PASS: {len(states)} Cat states illustrated, contact sheet: {OUT}")


if __name__ == "__main__":
    main()
