#!/usr/bin/env python3
"""Verify the optional Wukong V2 candidate, without changing core 4x15 coverage.

Usage: python tools/check_wukong_candidate.py [--base assets/characters-v2/wukong]
Requires Pillow. No generated frames are fabricated by this validator.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def visible(frame: Image.Image) -> Image.Image:
    return Image.alpha_composite(Image.new('RGBA', frame.size, (247, 243, 252, 255)), frame).convert('RGB')


def verify(base: Path) -> dict:
    master = base / 'master.png'
    folder = base / 'idle'
    metadata = json.loads((folder / 'metadata.json').read_text(encoding='utf-8'))
    qa = json.loads((folder / 'qa_report.json').read_text(encoding='utf-8'))
    provenance = json.loads((folder / 'provenance.json').read_text(encoding='utf-8'))
    manifest = json.loads((base / 'manifest.json').read_text(encoding='utf-8'))
    assert manifest['characterId'] == 'wukong' and manifest['productionReady'] is False
    assert manifest['states']['idle']['frames'] == 8
    assert metadata['characterId'] == 'wukong' and metadata['state'] == 'idle'
    assert metadata['generationClass'] == 'independently-illustrated-pose-sheet'
    assert metadata['frames'] == 8 and metadata['columns'] == 4 and metadata['rows'] == 2
    assert metadata['frameWidth'] == metadata['frameHeight'] == 256
    assert metadata['frameDurationMs'] == 150 and metadata['loop'] is True
    assert sha256(master) == provenance['masterSha256'] == manifest['masterSha256']
    assert sha256(folder / 'sheet_illustrated.webp') == metadata['sourceSha256'] == provenance['sourceSha256']
    assert sha256(folder / 'sheet.png') == metadata['sha256']
    assert qa['sourceSha256'] == metadata['sourceSha256']
    assert qa['runtimeSha256'] == metadata['sha256'] and qa['passed'] is True
    with Image.open(master) as im:
        assert im.mode == 'RGBA' and im.size == (512, 512)
        assert im.getpixel((0, 0))[3] == 0
    with Image.open(folder / 'sheet.png') as runtime, Image.open(folder / 'sheet_illustrated.webp') as source:
        assert runtime.size == source.size == (1024, 512)
        assert runtime.mode == source.mode == 'RGBA'
        # Lossless source must reproduce the same visible character pixels.
        assert ImageChops.difference(runtime.convert('RGB'), source.convert('RGB')).getbbox() is None, 'Source/runtime RGB diverges'
        assert ImageChops.difference(runtime.getchannel('A'), source.getchannel('A')).getbbox() is None, 'Source/runtime alpha diverges'
        motion = []
        prev = None
        margins = []
        for i in range(8):
            x, y = (i % 4)*256, (i // 4)*256
            frame = runtime.crop((x,y,x+256,y+256))
            bbox = frame.getchannel('A').getbbox()
            assert bbox, f'Empty frame {i}'
            margins.append(min(bbox[0],bbox[1],256-bbox[2],256-bbox[3]))
            assert margins[-1] >= 2, f'Clipped frame {i}'
            assert frame.getpixel((0,0))[3] == 0, f'Non-transparent corner {i}'
            if prev is not None:
                rms = sum(ImageStat.Stat(ImageChops.difference(visible(prev),visible(frame))).rms)/3
                assert rms >= 2, f'Duplicate visible acting pose {i-1} -> {i}: {rms}'
                motion.append(rms)
            prev = frame
    with Image.open(folder / 'preview.gif') as gif:
        assert gif.n_frames == 8 and gif.info.get('loop') == 0
        for i in range(8):
            gif.seek(i)
            assert abs(gif.info.get('duration',0)-150) <= 10, f'GIF timing lost in frame {i}'
    assert min(margins) >= qa['minFrameMarginPx']
    assert len(motion) == qa['adjacentChanges']
    print(f'PASS wukong/idle: 8 real poses, min margin {min(margins)}px, min visible motion RMS {min(motion):.2f}, SHA-256 OK')
    return {'frames':8,'minMargin':min(margins),'minMotionRms':round(min(motion),2)}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--base',type=Path,default=Path(__file__).resolve().parents[1] / 'assets/characters-v2/wukong')
    args = parser.parse_args()
    verify(args.base)
