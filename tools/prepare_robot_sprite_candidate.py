#!/usr/bin/env python3
"""Prepare OneLife Robot Glossy V2 4x3 concept boards for strict sprite QA.

This is a *candidate preparation* tool, not an art approval or automatic import.
It preserves each original pose as a distinct frame, fits within a 256x256
transparent cell, and runs the project's standard illustrated-sprite preflight.

Usage:
  python tools/prepare_robot_sprite_candidate.py /path/to/robot_remind.png \
    --output /tmp/robot_remind.webp

The generated WebP may be imported with tools/import_glossy_candidate.py
ONLY after its QA report passes and its identity/edges are reviewed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

from check_sprite_candidate import inspect


def prepare(source: Path, output: Path, *, columns: int = 4,
            rows: int = 3, cell: int = 256, margin: int = 12) -> dict:
    if columns != 4 or rows != 3 or cell != 256:
        raise ValueError("Robot candidate contract requires 4 columns, 3 rows and 256px cells")
    if not 4 <= margin <= 32:
        raise ValueError("margin must be 4..32")
    with Image.open(source) as original:
        if original.mode != "RGBA":
            raise ValueError("Source must have genuine RGBA; refusing opaque or RGB art")
        image = original.copy()
    if image.getchannel("A").getextrema()[0] != 0:
        raise ValueError("No transparent pixels in source")
    if image.width < columns * 128 or image.height < rows * 128:
        raise ValueError("Source is too small for 12 distinct poses")

    # Pixel-accurate integer partitions, avoiding rounding gaps on e.g. 1448x1086.
    atlas = Image.new("RGBA", (columns * cell, rows * cell), (0, 0, 0, 0))
    for index in range(columns * rows):
        col, row = index % columns, index // columns
        bounds = (
            round(col * image.width / columns),
            round(row * image.height / rows),
            round((col + 1) * image.width / columns),
            round((row + 1) * image.height / rows),
        )
        frame = image.crop(bounds)
        alpha = frame.getchannel("A")
        bbox = alpha.point(lambda a: 255 if a > 24 else 0).getbbox()
        if bbox is None:
            raise ValueError(f"Frame {index} is empty")
        # Refuse artwork crossing tile boundaries. A simple rescale cannot
        # restore cropped antennae, arms, particles, or shadows.
        if min(bbox[0], bbox[1], frame.width - bbox[2],
               frame.height - bbox[3]) < 2:
            raise ValueError(
                f"Frame {index} touches original tile boundary: {bbox}. "
                "Repair/re-illustrate this pose before importing."
            )
        cropped = frame.crop(bbox)
        scale = min((cell - 2 * margin) / cropped.width,
                    (cell - 2 * margin) / cropped.height)
        width = max(1, round(cropped.width * scale))
        height = max(1, round(cropped.height * scale))
        resized = cropped.resize((width, height), Image.Resampling.LANCZOS)
        x = col * cell + (cell - width) // 2
        y = row * cell + (cell - height) // 2
        atlas.alpha_composite(resized, (x, y))

    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, "WEBP", lossless=True, method=6)
    report = inspect(output, frames=12, cols=4, cell=256)
    report.update({
        "characterId": "robot",
        "candidateOnly": True,
        "productionReady": False,
        "sourceImage": str(source),
        "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "outputSha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "manualIdentityReview": "pending",
        "manualMatteAndEdgeReview": "pending",
        "realDeviceReview": "pending",
    })
    output.with_suffix(".qa.json").write_text(
        json.dumps(report, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    report = prepare(args.source, args.output)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["technicalPreflightPassed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
