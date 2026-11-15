#!/usr/bin/env python3
"""Check illustrated sprite candidates before adding them to animation_sources.json.

Technical-only preflight: never modifies source images or grants art/device approval.
Requires Pillow. Usage:
  python tools/check_sprite_candidate.py candidate.webp --json candidate.qa.json
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat


def inspect(path: Path, *, frames: int = 12, cols: int = 4, cell: int = 256) -> dict:
    if not 1 <= frames <= 24 or cols < 1 or cell < 32:
        raise ValueError('Invalid frame geometry')
    rows = (frames + cols - 1) // cols
    with Image.open(path) as source:
        atlas = source.convert('RGBA')
        mode = source.mode
        has_real_alpha = ('A' in source.getbands()) or ('transparency' in source.info)
    expected = (cols * cell, rows * cell)
    if atlas.size != expected:
        raise ValueError(f'Expected {expected} atlas; got {atlas.size}')

    warnings = []
    slices = []
    for i in range(frames):
        frame = atlas.crop(((i % cols) * cell, (i // cols) * cell,
                            (i % cols + 1) * cell, (i // cols + 1) * cell))
        alpha = frame.getchannel('A')
        transparent_fraction = alpha.histogram()[0] / (cell * cell)
        if transparent_fraction < 0.10:
            warnings.append(f'frame {i:02}: insufficient fully-transparent pixels ({transparent_fraction:.1%}); painted background suspected')
        bbox = alpha.point(lambda a: 255 if a > 24 else 0).getbbox()
        if bbox is None:
            warnings.append(f'frame {i:02}: empty image')
        else:
            margin = min(bbox[0], bbox[1], cell - bbox[2], cell - bbox[3])
            if margin < 3:
                warnings.append(f'frame {i:02}: touches cell edge (bbox={bbox})')
        border = [
            alpha.crop((0, 0, cell, 1)),
            alpha.crop((0, cell - 1, cell, cell)),
            alpha.crop((0, 0, 1, cell)),
            alpha.crop((cell - 1, 0, cell, cell)),
        ]
        if any(ImageStat.Stat(edge).extrema[0][1] > 24 for edge in border):
            warnings.append(f'frame {i:02}: nontransparent border')
        slices.append(frame)

    # Reject art hidden in unused cells of a partial final row. Otherwise a
    # purported 10-frame source could silently contain 12 painted poses while
    # the renderer/coverage counts only 10.
    for i in range(frames, rows * cols):
        unused = atlas.crop(((i % cols) * cell, (i // cols) * cell,
                             (i % cols + 1) * cell, (i // cols + 1) * cell))
        alpha = unused.getchannel('A')
        if alpha.getextrema()[1] > 24:
            warnings.append(f'unused cell {i:02}: contains visible pixels')

    adjacent = []
    for i in range(1, frames):
        matte = Image.new('RGBA', (cell, cell), (248, 246, 253, 255))
        a = Image.alpha_composite(matte, slices[i - 1]).convert('RGB')
        b = Image.alpha_composite(matte, slices[i]).convert('RGB')
        rms = sum(ImageStat.Stat(ImageChops.difference(a, b)).rms) / 3
        adjacent.append(round(rms, 2))
        if rms < 2:
            warnings.append(f'frame {i - 1:02}->{i:02}: near duplicate ({rms:.2f} RMS)')
    if not has_real_alpha:
        warnings.append(f'source mode {mode}: no alpha channel or transparency metadata')

    return {
        'source': str(path),
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'geometry': {'frames': frames, 'columns': cols, 'rows': rows,
                     'cellPx': cell, 'atlasPx': list(atlas.size)},
        'adjacentVisibleRms': adjacent,
        'warnings': warnings,
        'technicalPreflightPassed': not warnings,
        'humanVisualApproval': 'pending',
        'realDeviceApproval': 'pending',
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('atlas', type=Path)
    parser.add_argument('--frames', type=int, default=12)
    parser.add_argument('--columns', type=int, default=4)
    parser.add_argument('--cell', type=int, default=256)
    parser.add_argument('--json', type=Path)
    args = parser.parse_args()
    report = inspect(args.atlas, frames=args.frames, cols=args.columns, cell=args.cell)
    payload = json.dumps(report, indent=2, ensure_ascii=False) + '\n'
    print(payload, end='')
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(payload, encoding='utf-8')
    return 0 if report['technicalPreflightPassed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
