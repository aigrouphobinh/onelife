#!/usr/bin/env python3
"""Render committed vector mascot sprite sheets to PNG/GIF without modifying source SVG."""
from __future__ import annotations
import hashlib
import io
import json
from pathlib import Path
import xml.etree.ElementTree as ET

import cairosvg
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[1]
CELL = 256
STATES = {
    "idle": (8, 140, True),
    "happy": (10, 85, True),
    "remind": (12, 110, True),
    "alarm": (12, 80, True),
    "focus": (8, 160, True),
    "study": (12, 120, True),
    "sleepy": (10, 180, True),
    "done": (12, 95, False),
    "thinking": (8, 140, True),
    "sad": (8, 160, False),
    # Brain Balance: purely metaphorical visual reflection of opt-in usage goals.
    "balanced": (8, 140, True),
    "strained": (10, 160, True),
    "overloaded": (12, 115, True),
    "resting": (10, 205, True),
    "recovering": (12, 110, False),
}

def generate(path: Path) -> dict:
    char_id = path.parent.parent.name
    state = path.parent.name
    if state not in STATES:
        raise ValueError(f"Unexpected animation state: {path}")
    # Approved glossy V2 raster takes precedence over the older flat SVG source.
    # Never overwrite the actual user-selected artwork when regenerating SVG assets.
    if char_id == "brain" and path.with_name("metadata.json").exists():
        metadata_path = path.with_name("metadata.json")
        if metadata_path.exists():
            current = json.loads(metadata_path.read_text(encoding="utf-8"))
            if current.get("artStyle") == "glossy-kawaii-v2":
                png_path = path.with_name("sheet.png")
                actual = hashlib.sha256(png_path.read_bytes()).hexdigest()
                if actual != current["sha256"]:
                    raise AssertionError("Glossy Brain V2 atlas checksum mismatch")
                print("PASS verified glossy Brain V2 atlas (not regenerated from V1 SVG)")
                return current
    frames, duration, loop = STATES[state]
    columns = 4
    rows = (frames + columns - 1) // columns
    xml = ET.parse(path).getroot()
    if xml.attrib.get("viewBox") != f"0 0 {columns * CELL} {rows * CELL}":
        raise AssertionError(f"Invalid viewBox in {path}: {xml.attrib.get('viewBox')}")
    rendered = cairosvg.svg2png(url=str(path))
    rgba = Image.open(io.BytesIO(rendered)).convert("RGBA")
    if rgba.size != (columns * CELL, rows * CELL):
        raise AssertionError(f"Unexpected pixel dimensions: {path} {rgba.size}")
    if rgba.getpixel((0, 0))[3] != 0:
        raise AssertionError(f"Nontransparent canvas background: {path}")
    slices = []
    for i in range(frames):
        x, y = i % columns, i // columns
        frame = rgba.crop((x * CELL, y * CELL, (x + 1) * CELL, (y + 1) * CELL))
        if frame.getbbox() is None:
            raise AssertionError(f"Empty frame #{i} in {path}")
        slices.append(frame)
    # Reject fully identical frame sequences, including seamless loops with an idle hold.
    unique = sum(ImageChops.difference(a, b).getbbox() is not None for a, b in zip(slices, slices[1:]))
    # Intentional animation holds (e.g. sleepy eyelid pause) are allowed,
    # provided at least ~75% of adjacent transitions visibly change.
    minimum_transitions = max(5, round((frames - 1) * 0.75))
    if unique < minimum_transitions:
        raise AssertionError(f"Insufficient distinct poses ({unique}/{frames-1}) in {path}")
    png_path = path.with_name("sheet.png")
    rgba.save(png_path, optimize=True)
    # GIF is only a review preview, the PNG atlas remains the intended runtime asset.
    # Composite each RGBA frame against the app's light surface. GIF has no
    # true RGBA: explicitly converting to RGB avoids Pillow invalid-palette errors.
    resized = []
    for frame in slices:
        small = frame.resize((192, 192), Image.Resampling.LANCZOS)
        background = Image.new("RGB", small.size, (248, 247, 252))
        background.paste(small, mask=small.getchannel("A"))
        resized.append(background)
    resized[0].save(path.with_name("preview.gif"), save_all=True, append_images=resized[1:],
                    duration=duration, loop=0 if loop else 1, disposal=2, optimize=False)
    meta = {
        "characterId": char_id, "state": state, "frames": frames, "columns": columns,
        "rows": rows, "frameWidth": CELL, "frameHeight": CELL,
        "frameDurationMs": duration, "loop": loop, "anchorX": 0.5, "anchorY": 0.92,
        "source": "sheet.svg", "runtimeAsset": "sheet.png", "preview": "preview.gif",
        "licenseRef": "docs/ASSET_REGISTER.md",
        "sha256": hashlib.sha256(png_path.read_bytes()).hexdigest()
    }
    path.with_name("metadata.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n")
    print(f"PASS {char_id}/{state}: {frames} frames -> {png_path.stat().st_size} bytes")
    return meta

def main():
    paths = sorted((ROOT / "assets/characters").glob("*/*/sheet.svg"))
    if not paths:
        raise SystemExit("No animation sheet.svg files")
    manifests = {}
    for path in paths:
        meta = generate(path)
        manifests.setdefault(meta["characterId"], {})[meta["state"]] = {
            "file": str(path.parent.relative_to(ROOT)) + "/metadata.json",
            "frames": meta["frames"]
        }
    for char, states in manifests.items():
        manifest_path = ROOT / "assets/characters" / char / "manifest.json"
        # Preserve V2 visual overrides and default preview when updating state indices.
        old_manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
        next_manifest = {"characterId": char, "version": old_manifest.get("version", "1.0.0"), "states": states}
        for preserved in ("defaultPreviewAsset", "visualStateVersions"):
            if preserved in old_manifest:
                next_manifest[preserved] = old_manifest[preserved]
        manifest_path.write_text(json.dumps(next_manifest, indent=2) + "\n")
    print(f"Rendered {len(paths)} animations across {len(manifests)} characters.")

if __name__ == "__main__":
    main()
