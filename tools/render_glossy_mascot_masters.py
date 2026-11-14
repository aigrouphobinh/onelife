#!/usr/bin/env python3
"""Render and validate the four original OneLife Glossy V2 master candidates.

This never fabricates animation frames. Source master WebP files were
specifically generated for this app and are committed as immutable inputs.
No paid API, external model or network request is required.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'assets' / 'characters-v2'
OUT = ROOT / 'design' / 'review'
SOURCES = {
    'cat': '6b47d6054c7ed09da4974546fcefd027258787cd4cc0dd2c75f6b1fbd0f09582',
    'dog': '43d5f2f2e6026bd0af2255677a04f90bb1b41b88b3704d7c58439bd0af94b045',
    'robot': 'b15b973836f7e46f8947b5adfa28a2b5a8957ec72ea3b353c057336f6c111b0f',
    'sprout': '908371601fd0cb54d28e7615f3d8e1f94c5003813818fb6ea8cc39c146ce1e3e',
}


def digest(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.new('RGB', (680, 700), (248, 246, 252))
    draw = ImageDraw.Draw(sheet)
    records = []
    for idx, (character, expected) in enumerate(SOURCES.items()):
        folder = BASE / character
        source = folder / 'master.webp'
        if not source.is_file():
            raise AssertionError(f'{character}: missing original master.webp')
        if digest(source) != expected:
            raise AssertionError(f'{character}: source SHA256 mismatch')
        with Image.open(source) as original:
            master = original.convert('RGBA')
        if master.size != (512, 512):
            raise AssertionError(f'{character}: expected 512x512 actual source')
        alpha = master.getchannel('A')
        box = alpha.getbbox()
        if box is None:
            raise AssertionError(f'{character}: no visible character')
        if min(box[0], box[1], 512-box[2], 512-box[3]) < 8:
            raise AssertionError(f'{character}: clipped silhouette {box}')
        for xy in ((0, 0), (511, 0), (0, 511), (511, 511)):
            if alpha.getpixel(xy) != 0:
                raise AssertionError(f'{character}: nontransparent corner {xy}')

        master_png = folder / 'master.png'
        master.save(master_png, optimize=True)
        thumbnail = folder / 'thumbnail.png'
        preview = master.resize((160, 160), Image.Resampling.LANCZOS)
        preview.save(thumbnail, optimize=True)
        metadata = {
            'schemaVersion': 1,
            'characterId': character,
            'artStyle': 'glossy-kawaii-v2',
            'assetKind': 'single-master-artwork',
            'originalSource': 'master.webp',
            'masterAsset': 'master.png',
            'thumbnailAsset': 'thumbnail.png',
            'sourceSha256': expected,
            'masterSha256': digest(master_png),
            'sourceDimensions': [512, 512],
            'masterDimensions': [512, 512],
            'transparentBackground': True,
            'states': {},
            'animationReady': False,
            'productionReady': False,
            'humanArtReview': 'pending',
            'devicePerformanceReview': 'pending',
            'licenseRef': 'docs/ASSET_REGISTER.md',
            'provenance': 'Original AI-generated OneLife four-mascot concept; transparent masking with local segmentation. No third-party character source.',
        }
        (folder / 'metadata.json').write_text(json.dumps(metadata, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
        records.append({'characterId': character, 'sha256': metadata['masterSha256'], 'sourceSha256': expected, 'alphaBounds': list(box), 'technicalQA': 'passed', 'artApproval': 'pending'})

        pos = (30 + (idx % 2) * 330, 32 + (idx // 2) * 335)
        thumb = master.resize((270, 270), Image.Resampling.LANCZOS)
        sheet.paste(thumb, pos, thumb)
        draw.text((pos[0]+8, pos[1]+274), character.upper(), fill=(65, 45, 105))
        print(f'PASS {character} master 512 RGBA; alpha bbox={box} sha256={expected}')

    sheet.save(OUT / 'glossy-other-mascots.png', optimize=True)
    (OUT / 'glossy-other-mascots-qa.json').write_text(json.dumps({
        'status': 'PASS — structural tests only',
        'characters': records,
        'verifiedMasterCount': len(records),
        'animationClipCount': 0,
        'artApproval': 'pending',
        'phoneQA': 'pending',
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('PASS: 4 master candidates, no animation clips claimed')


if __name__ == '__main__':
    main()
