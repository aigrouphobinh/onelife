#!/usr/bin/env python3
"""Validate and optionally import an external Robot Glossy V2 candidate ZIP.

Pack contract: BUILD_REPORT.json plus <state>/sheet_illustrated.webp and
<state>/metadata.json. Missing source art is never synthesized. This tool
does not grant human art approval or real-device approval.

Usage: python tools/import_robot_v2_pack.py pack.zip [--apply]
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import math
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

from PIL import Image, ImageChops, ImageStat

STATES = (
    'idle', 'remind', 'happy', 'overloaded', 'resting', 'alarm',
    'sleepy', 'recovering', 'focus', 'study', 'done', 'thinking',
    'sad', 'balanced', 'strained',
)
MAX_ASSET_BYTES = 12_000_000
MAX_TOTAL_UNCOMPRESSED_BYTES = 160_000_000
MAX_COMPRESSION_RATIO = 250
ALLOWED_STATE_MEMBERS = frozenset({
    'sheet_illustrated.webp', 'metadata.json', 'sheet.png',
    'preview.gif', 'candidate_qa.json',
})


def validate_pack(path: Path) -> list[dict]:
    """Preflight every source without changing the repository."""
    result = []
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate ZIP member name')
        for name in names:
            p = PurePosixPath(name)
            if p.is_absolute() or '..' in p.parts or '\\' in name:
                raise ValueError(f'Unsafe ZIP member: {name!r}')
            if z.getinfo(name).file_size > MAX_ASSET_BYTES:
                raise ValueError(f'Oversized ZIP member: {name!r}')
        # ZIPs from the art pipeline contain review PNG/GIF/QA alongside
        # immutable WebPs. Reject untracked paths and decompression bombs.
        if sum(z.getinfo(name).file_size for name in names) > MAX_TOTAL_UNCOMPRESSED_BYTES:
            raise ValueError('ZIP uncompressed size exceeds safety limit')
        for name in names:
            info = z.getinfo(name)
            if info.file_size > 4096 and info.file_size / max(1, info.compress_size) > MAX_COMPRESSION_RATIO:
                raise ValueError(f'Excessive ZIP compression ratio: {name!r}')
            if name == 'BUILD_REPORT.json':
                continue
            parts = PurePosixPath(name).parts
            if len(parts) != 2 or parts[0] not in STATES or parts[1] not in ALLOWED_STATE_MEMBERS:
                raise ValueError(f'Unexpected ZIP member: {name!r}')
        if 'BUILD_REPORT.json' not in names:
            raise ValueError('Missing BUILD_REPORT.json')
        report = json.loads(z.read('BUILD_REPORT.json'))
        specs = report.get('qa')
        if not isinstance(specs, list) or not specs:
            raise ValueError('Empty candidate report')
        if 'count' in report and (type(report['count']) is not int or report['count'] != len(specs)):
            raise ValueError('BUILD_REPORT count does not match listed states')
        seen = set()
        for entry in specs:
            state = entry.get('state')
            if state not in STATES or state in seen:
                raise ValueError(f'Unknown/duplicate Robot state: {state!r}')
            seen.add(state)
            image_name = f'{state}/sheet_illustrated.webp'
            metadata_name = f'{state}/metadata.json'
            if image_name not in names or metadata_name not in names:
                raise ValueError(f'Missing source or metadata for {state}')
            source = z.read(image_name)
            source_sha = hashlib.sha256(source).hexdigest()
            if source_sha != entry.get('sourceSha256'):
                raise ValueError(f'{state}: source checksum mismatch')
            metadata = json.loads(z.read(metadata_name))
            for field, expected in (
                ('characterId', 'robot'), ('state', state),
                ('sourceSha256', source_sha), ('columns', 4),
                ('frameWidth', 256), ('frameHeight', 256),
                ('productionReady', False),
            ):
                if metadata.get(field) != expected:
                    raise ValueError(f'{state}: invalid {field}')
            if type(metadata.get('loop')) is not bool:
                raise ValueError(f'{state}: invalid loop flag')
            frames = metadata.get('frames')
            duration = metadata.get('frameDurationMs')
            if type(frames) is not int or not 2 <= frames <= 24:
                raise ValueError(f'{state}: invalid frame count')
            if frames != entry.get('frames'):
                raise ValueError(f'{state}: inconsistent frame count')
            if type(duration) is not int or not 60 <= duration <= 1000:
                raise ValueError(f'{state}: invalid frame duration')
            if (metadata.get('artReview') != 'pending' or
                    metadata.get('deviceReview') != 'pending'):
                raise ValueError(f'{state}: human/device review gate must remain pending')
            with Image.open(io.BytesIO(source)) as im:
                if im.format != 'WEBP' or im.mode != 'RGBA':
                    raise ValueError(f'{state}: source must be RGBA WebP')
                atlas = im.convert('RGBA')
            rows = math.ceil(frames / 4)
            if atlas.size != (1024, rows * 256):
                raise ValueError(f'{state}: expected 1024x{rows * 256} pixels')
            slices = []
            for i in range(frames):
                x, y = (i % 4) * 256, (i // 4) * 256
                frame = atlas.crop((x, y, x + 256, y + 256))
                alpha = frame.getchannel('A')
                if alpha.histogram()[0] / 65536 < 0.10:
                    raise ValueError(f'{state} frame {i}: insufficient transparency')
                bbox = alpha.point(lambda a: 255 if a > 24 else 0).getbbox()
                if not bbox or min(
                    bbox[0], bbox[1], 256 - bbox[2], 256 - bbox[3]
                ) < 3:
                    raise ValueError(f'{state} frame {i}: empty or clipped sprite')
                slices.append(frame)
            for i in range(frames, rows * 4):
                x, y = (i % 4) * 256, (i // 4) * 256
                if atlas.crop(
                    (x, y, x + 256, y + 256)
                ).getchannel('A').getextrema()[1] > 24:
                    raise ValueError(f'{state}: art in unused cell {i}')
            matte = Image.new('RGBA', (256, 256), (248, 246, 253, 255))
            for i in range(1, len(slices)):
                left = Image.alpha_composite(matte, slices[i - 1]).convert('RGB')
                right = Image.alpha_composite(matte, slices[i]).convert('RGB')
                rms = sum(
                    ImageStat.Stat(ImageChops.difference(left, right)).rms
                ) / 3
                if rms < 2:
                    raise ValueError(
                        f'{state}: near-duplicate visible frames {i - 1} -> {i}'
                    )
            result.append({
                'state': state, 'frames': frames, 'frameDurationMs': duration,
                'loop': metadata.get('loop') is True,
                'sha256': source_sha, 'bytes': len(source),
                'zip_member': image_name,
            })
        extras = {name.split('/', 1)[0] for name in names if name != 'BUILD_REPORT.json'} - seen
        if extras:
            raise ValueError(f'Unlisted Robot state assets: {sorted(extras)!r}')
    return result


def import_pack(path: Path, *, version: str, apply: bool) -> list[dict]:
    specs = validate_pack(path)
    if not apply:
        return specs
    # Never touch the catalog until all source files have passed QA.
    from import_glossy_candidate import (
        CATALOG, V2_ROOT, candidate_spec, import_candidate,
    )

    catalog = json.loads(CATALOG.read_text(encoding='utf-8'))
    for item in specs:
        state = item['state']
        if any(
            x['characterId'] == 'robot' and x['state'] == state
            for x in catalog['animationSources']
        ):
            raise ValueError(f'{state}: already registered, no overwrite')
        if (V2_ROOT / 'robot' / state / 'sheet_illustrated.webp').exists():
            raise ValueError(f'{state}: existing source, no overwrite')
    with tempfile.TemporaryDirectory(prefix='onelife-robot-v2-') as tmp:
        with zipfile.ZipFile(path) as z:
            for item in specs:
                state = item['state']
                dest = Path(tmp) / f'{state}.webp'
                dest.write_bytes(z.read(item['zip_member']))
                spec = candidate_spec(
                    character='robot', state=state, version=version,
                    sha256=item['sha256'], frames=item['frames'],
                    duration_ms=item['frameDurationMs'], loop=item['loop'],
                )
                import_candidate(dest, spec)
    return specs


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('zip', type=Path)
    p.add_argument('--apply', action='store_true')
    p.add_argument('--version', default='2.40.0-illustrated-candidate')
    args = p.parse_args()
    specs = import_pack(args.zip, version=args.version, apply=args.apply)
    print(json.dumps({
        'verified': len(specs), 'applied': args.apply,
        'productionReady': False, 'states': specs,
    }, indent=2))


if __name__ == '__main__':
    main()
