#!/usr/bin/env python3
"""Validate real bundled Dog/Robot PNG alpha without the Flutter UI renderer.

Full RGBA image decoding is performed by Pillow in asset QA, instead of
keeping Flutter unit tests busy for ten minutes decoding large atlases.
"""
import hashlib
import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
PATTERN = re.compile(
    r"^\s+- (assets/characters-v2/(dog|robot)/([^/]+)/sheet\.png)\s*$",
    re.MULTILINE,
)


def validate(path_text: str, character: str, state: str) -> None:
    image_path = ROOT / path_text
    metadata = json.loads(
        (image_path.parent / "metadata.json").read_text(encoding="utf-8")
    )
    assert metadata["characterId"] == character
    assert metadata["state"] == state
    assert hashlib.sha256(image_path.read_bytes()).hexdigest() == metadata["sha256"], path_text
    frames = metadata["frames"]
    cols = metadata["columns"]
    width = metadata["frameWidth"]
    height = metadata["frameHeight"]
    rows = (frames + cols - 1) // cols
    assert cols == 4 and width == 256 and height == 256
    assert 8 <= frames <= 12
    with Image.open(image_path) as atlas:
        assert atlas.mode == "RGBA", f"Missing RGBA channel: {path_text}"
        assert atlas.size == (cols * width, rows * height), path_text
        for index in range(frames):
            left = (index % cols) * width
            top = (index // cols) * height
            # Each frame must have transparent outer canvas and visible art.
            assert atlas.getpixel((left + 1, top + 1))[3] == 0, (path_text, index)
            with atlas.crop((left, top, left + width, top + height)) as frame:
                assert frame.getchannel("A").getbbox() is not None, (path_text, index)
    print("OK", character, state, frames)


def main() -> None:
    sprites = PATTERN.findall(MANIFEST)
    counts = {"dog": 0, "robot": 0}
    assert len(sprites) == len(set(p for p, _, _ in sprites)), "Duplicate pubspec assets"
    for path, character, state in sprites:
        validate(path, character, state)
        counts[character] += 1
    assert counts == {"dog": 15, "robot": 12}, counts
    print("PASS: 27 packaged PNG atlases with SHA, geometry and frame alpha")


if __name__ == "__main__":
    main()
