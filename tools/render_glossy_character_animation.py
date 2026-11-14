#!/usr/bin/env python3
"""OneLife Glossy V2 animation importer.

Input: independently illustrated WebP sprite atlases listed in animation_sources.json.
Outputs: 256px RGBA PNG atlas, browser review GIF, metadata, manifest.
Only imports explicitly listed sources. Does not synthesize animation from a still.
"""
from __future__ import annotations
import argparse
import hashlib
import io
import json
import sys
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = ROOT / 'assets/characters-v2'
CATALOG = SRC_ROOT / 'animation_sources.json'


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(character: str, state: str, spec: dict) -> None:
    folder = SRC_ROOT / character / state
    source = folder / spec['sourceFile']
    if not source.is_file():
        raise AssertionError(f'Missing illustration source: {source}')
    if sha(source) != spec['sourceSha256']:
        raise AssertionError(f'Source checksum mismatch: {source}')

    frames = int(spec['frames'])
    cols = int(spec['columns'])
    width = int(spec['frameWidth'])
    height = int(spec['frameHeight'])
    rows = (frames + cols - 1) // cols
    if not (1 <= frames <= 24 and cols == 4 and width == height == 256):
        raise AssertionError('Unsupported sprite geometry')
    duration = int(spec['frameDurationMs'])
    if not 60 <= duration <= 1000:
        raise AssertionError('Invalid frame duration')

    with Image.open(source) as raw:
        atlas = raw.convert('RGBA')
    if atlas.size != (cols * width, rows * height):
        raise AssertionError(f'Unexpected atlas size: {atlas.size}')

    slices = []
    prev = None
    min_motion = 999
    for i in range(frames):
        x = (i % cols) * width
        y = (i // cols) * height
        frame = atlas.crop((x, y, x+width, y+height))
        alpha = frame.getchannel('A')
        bbox = alpha.getbbox()
        if bbox is None:
            raise AssertionError(f'{character}/{state} frame {i} empty')
        edge_margin = min(bbox[0], bbox[1], width-bbox[2], height-bbox[3])
        if edge_margin < 2:
            raise AssertionError(f'{character}/{state} frame {i} clipped: {bbox}')
        if frame.getpixel((0, 0))[3] > 20:
            raise AssertionError(f'{character}/{state} frame {i} alpha background not transparent')
        if prev is not None:
            rms = sum(ImageStat.Stat(ImageChops.difference(prev, frame)).rms[:3]) / 3
            if rms < 2.0:
                raise AssertionError(f'{character}/{state} frame {i} is near duplicate of {i-1}: {rms:.2f}')
            min_motion = min(min_motion, rms)
        prev = frame
        slices.append(frame)

    target = folder / 'sheet.png'
    atlas.save(target, optimize=True)
    rendered = []
    for frame in slices:
        bg = Image.new('RGB', frame.size, (247, 243, 252))
        bg.paste(frame, mask=frame.getchannel('A'))
        rendered.append(bg)
    rendered[0].save(folder / 'preview.gif', save_all=True,
        append_images=rendered[1:], duration=duration, loop=0,
        disposal=2, optimize=False)
    with Image.open(folder / 'preview.gif') as check:
        if getattr(check, 'n_frames', 1) != frames:
            raise AssertionError('GIF encoder omitted/combined frames')

    metadata = {
        'characterId': character, 'state': state, 'version': spec['version'],
        'artStyle': 'glossy-kawaii-v2', 'source': spec['sourceFile'],
        'runtimeAsset': 'sheet.png', 'preview': 'preview.gif',
        'frames': frames, 'columns': cols, 'rows': rows,
        'frameWidth': width, 'frameHeight': height,
        'frameDurationMs': duration, 'loop': bool(spec['loop']),
        'anchorX': 0.5, 'anchorY': 0.92,
        'sourceSha256': spec['sourceSha256'], 'sha256': sha(target),
        'licenseRef': 'docs/ASSET_REGISTER.md',
        'generationClass': spec['generationClass'],
        'reviewStatus': 'automated-qa-passed; human and phone QA pending',
    }
    (folder / 'metadata.json').write_text(json.dumps(metadata, indent=2, ensure_ascii=False)+'\n')
    qa = {
        'passed': True, 'frames': frames, 'adjacentChanges': frames - 1,
        'minimumAdjacentRgbRms': round(min_motion, 2),
        'runtimeSha256': metadata['sha256'], 'sourceSha256': metadata['sourceSha256'],
        'visualReview': 'pending', 'realDeviceTest': 'pending',
    }
    (folder / 'qa_report.json').write_text(json.dumps(qa, indent=2)+'\n')
    manifest_path = SRC_ROOT / character / 'manifest.json'
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {
        'characterId': character, 'assetVersion': '2.5.0-candidate',
        'artMaster': f'assets/characters-v2/{character}/master.png',
        'productionReady': False, 'states': {},
    }
    manifest.setdefault('states', {})[state] = {
        'file': f'assets/characters-v2/{character}/{state}/metadata.json',
        'frames': frames,
        'generationClass': spec['generationClass'],
    }
    manifest['productionReady'] = False
    manifest['note'] = 'Visual/phone sign-off required; no inferred or synthesized state completion.'
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False)+'\n')
    print(f'PASS {character}/{state}: {frames} frames, {frames-1} distinct transitions, min motion RMS={min_motion:.2f}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--character', default=None)
    args = parser.parse_args()
    catalog = json.loads(CATALOG.read_text())
    assets = catalog['animationSources']
    found = 0
    for item in assets:
        if args.character and item['characterId'] != args.character:
            continue
        build(item['characterId'], item['state'], item)
        found += 1
    if found == 0:
        raise SystemExit(f'No illustration sources for {args.character}')
    print('Total sourced glossy animations rendered:', found)

if __name__ == '__main__':
    main()
