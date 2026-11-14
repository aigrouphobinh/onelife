#!/usr/bin/env python3
"""Safely import one *existing* illustrated WebP into the OneLife Glossy V2 catalog.

This does not synthesize artwork. The source must exist, carry genuine RGBA
transparency, pass the same preflight as other illustrated sprites, and match
its caller-supplied SHA-256. A successful import remains an art candidate.

Example:
  python tools/import_glossy_candidate.py --character dog --state thinking \
    --source /path/to/original.webp --expected-sha256 <64 hex> \
    --version 2.30.0-illustrated-candidate --frame-duration-ms 145
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path

from check_sprite_candidate import inspect
from render_glossy_character_animation import build

ROOT = Path(__file__).resolve().parents[1]
V2_ROOT = ROOT / 'assets' / 'characters-v2'
CATALOG = V2_ROOT / 'animation_sources.json'


def validate_name(name: str) -> str:
    if not re.fullmatch(r'[a-z][a-z0-9_-]{1,31}', name):
        raise ValueError(f'Invalid sprite id: {name!r}')
    return name


def candidate_spec(*, character: str, state: str, version: str,
                   sha256: str, frames: int, duration_ms: int,
                   loop: bool, generation_class: str = 'independently-illustrated-pose-sheet') -> dict:
    validate_name(character)
    validate_name(state)
    if not re.fullmatch(r'[0-9a-f]{64}', sha256):
        raise ValueError('expected-sha256 must be 64 lowercase hex digits')
    if not 2 <= frames <= 24:
        raise ValueError('frames must be between 2 and 24')
    if not 60 <= duration_ms <= 1000:
        raise ValueError('frameDurationMs out of range')
    if not version or len(version) > 96:
        raise ValueError('Invalid source version')
    if generation_class not in ('independently-illustrated-pose-sheet',
                                'retargeted-illustrated-pose-sheet'):
        raise ValueError('Invalid generationClass')
    return {
        'characterId': character, 'state': state,
        'version': version, 'sourceFile': 'sheet_illustrated.webp',
        'sourceSha256': sha256, 'frames': frames, 'columns': 4,
        'frameWidth': 256, 'frameHeight': 256,
        'frameDurationMs': duration_ms, 'loop': loop,
        'generationClass': generation_class,
    }


def import_candidate(source: Path, spec: dict, *, v2_root: Path = V2_ROOT,
                     catalog_path: Path = CATALOG) -> dict:
    source = source.resolve(strict=True)
    if source.suffix.lower() != '.webp':
        raise ValueError('Only source WebP is accepted')
    actual_sha = hashlib.sha256(source.read_bytes()).hexdigest()
    if actual_sha != spec['sourceSha256']:
        raise ValueError('Source SHA-256 mismatch: refusing changed artwork')
    report = inspect(source, frames=spec['frames'], cols=4, cell=256)
    if not report['technicalPreflightPassed']:
        raise ValueError('Technical sprite preflight failed: ' +
                         '; '.join(report['warnings']))

    # Check for conflicts BEFORE copying or touching the catalog.
    catalog = json.loads(catalog_path.read_text(encoding='utf-8'))
    sources = catalog['animationSources']
    current = [entry for entry in sources if
               entry['characterId'] == spec['characterId'] and
               entry['state'] == spec['state']]
    if current and current != [spec]:
        raise ValueError('Conflicting source catalog entry: no overwrite')
    destination = v2_root / spec['characterId'] / spec['state'] / spec['sourceFile']
    if destination.exists() and hashlib.sha256(destination.read_bytes()).hexdigest() != actual_sha:
        raise ValueError('Different source already exists: no overwrite')

    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists():
        shutil.copyfile(source, destination)
    if not current:
        sources.append(spec)
        catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n',
                                encoding='utf-8')
    report = inspect(destination, frames=spec['frames'], cols=4, cell=256)
    (destination.parent / 'candidate_qa.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8'
    )
    # The established renderer validates committed bytes/checksums and generates
    # PNG, GIF, metadata, QA report and manifest. It never authorizes art approval.
    if v2_root == V2_ROOT:
        build(spec['characterId'], spec['state'], spec)
    return {
        'source': str(destination), 'sha256': actual_sha,
        'technicalPreflightPassed': True,
        'productionReady': False,
        'artReview': 'pending',
        'phoneQA': 'pending',
        'registered': True,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--character', required=True)
    parser.add_argument('--state', required=True)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--expected-sha256', required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--frames', type=int, default=12)
    parser.add_argument('--frame-duration-ms', type=int, default=145)
    parser.add_argument('--loop', action='store_true')
    parser.add_argument('--generation-class',
        choices=('independently-illustrated-pose-sheet',
                 'retargeted-illustrated-pose-sheet'),
        default='independently-illustrated-pose-sheet')
    a = parser.parse_args()
    spec = candidate_spec(
        character=a.character, state=a.state, version=a.version,
        sha256=a.expected_sha256, frames=a.frames,
        duration_ms=a.frame_duration_ms, loop=a.loop,
        generation_class=a.generation_class)
    print(json.dumps(import_candidate(a.source, spec),
                     ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
