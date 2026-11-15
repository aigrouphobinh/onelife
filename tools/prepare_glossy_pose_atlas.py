#!/usr/bin/env python3
"""Prepare an AI-illustrated 4x3 pose board for the OneLife WebP importer.

Removes LOW-ALPHA generator haze and fits distinct illustrated poses into
256px transparent cells. This does not create new acting poses, replace the
character master, or grant art/device acceptance.

Usage:
  python tools/prepare_glossy_pose_atlas.py raw.png candidate.webp
  python tools/check_sprite_candidate.py candidate.webp
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

COLUMNS = 4
ROWS = 3
FRAMES = COLUMNS * ROWS
CELL = 256
PADDING = 12


def prepare(source: Path, target: Path, *, threshold: int = 100) -> dict:
    if not 1 <= threshold <= 245:
        raise ValueError('threshold must be between 1 and 245')
    with Image.open(source) as original:
        if 'A' not in original.getbands() and 'transparency' not in original.info:
            raise ValueError(
                'Source image needs real alpha; opaque background cannot be safely removed'
            )
        img = original.convert('RGBA')
    width, height = img.size
    if width % COLUMNS or height % ROWS or width // COLUMNS != height // ROWS:
        raise ValueError('Expected a 4x3 board of square input cells')
    size = width // COLUMNS
    atlas = Image.new('RGBA', (CELL * COLUMNS, CELL * ROWS))
    for index in range(FRAMES):
        x = index % COLUMNS
        y = index // COLUMNS
        frame = img.crop((x * size, y * size, (x + 1) * size, (y + 1) * size))
        alpha = frame.getchannel('A')
        # Generator backdrops may be low-opacity everywhere, despite the
        # output being nominally transparent. Keep actual illustrated regions.
        # Opaque painted scenery is not removable here: separate QA rejects it.
        silhouette = alpha.point(lambda a: 255 if a >= threshold else 0)
        silhouette = silhouette.filter(ImageFilter.GaussianBlur(1.2))
        source_strength = alpha.point(
            lambda a: max(0, min(255, int((a - 65) * 3.2)))
        )
        frame.putalpha(ImageChops.multiply(source_strength, silhouette))
        resized = frame.resize(
            (CELL - PADDING * 2, CELL - PADDING * 2),
            Image.Resampling.LANCZOS,
        )
        atlas.alpha_composite(
            resized, (x * CELL + PADDING, y * CELL + PADDING)
        )

    target.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(target, 'WEBP', quality=92, method=4)
    sha = hashlib.sha256(target.read_bytes()).hexdigest()
    return {
        'output': str(target), 'sha256': sha, 'inputSize': [width, height],
        'outputSize': list(atlas.size), 'frames': FRAMES,
        'columns': COLUMNS, 'rows': ROWS, 'cellPx': CELL,
        'humanVisualApproval': 'pending', 'phoneQA': 'pending',
        'note': 'Art preparation only; run check_sprite_candidate.py before import.',
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--threshold', type=int, default=100)
    args = parser.parse_args()
    print(json.dumps(prepare(args.source, args.output, threshold=args.threshold),
                     indent=2))


if __name__ == '__main__':
    main()
