#!/usr/bin/env python3
"""Fail-closed QA for the one completed Dog Idle candidate (not a device acceptance)."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageStat

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/characters-v2/dog/idle'
PAGE=ROOT/'design/review/glossy-dog-idle.html'

def sha(p: Path) -> str: return hashlib.sha256(p.read_bytes()).hexdigest()

def visible(im):
    return Image.alpha_composite(Image.new('RGBA',im.size,(246,241,250,255)),im.convert('RGBA')).convert('RGB')

def main():
    catalog=json.loads((ROOT/'assets/characters-v2/animation_sources.json').read_text())
    entries=[e for e in catalog['animationSources'] if e['characterId']=='dog' and e['state']=='idle']
    assert len(entries)==1, 'Expected exactly one dog/idle catalog entry'
    spec=entries[0]
    meta=json.loads((SOURCE/'metadata.json').read_text())
    report=json.loads((SOURCE/'qa_report.json').read_text())
    assert spec['sourceSha256']==sha(SOURCE/'sheet_illustrated.webp')==meta['sourceSha256']
    assert meta['sha256']==sha(SOURCE/'sheet.png')
    assert spec['frames']==meta['frames']==8 and meta['columns']==4 and meta['rows']==2
    assert meta['frameDurationMs']==150 and meta['loop'] is True
    assert report['passed'] is True and report['previewLoop']=='infinite'
    with Image.open(SOURCE/'sheet.png') as original:
        atlas=original.convert('RGBA')
    assert atlas.size==(1024,512)
    frames=[atlas.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256)) for i in range(8)]
    for i,frame in enumerate(frames):
        bounds=frame.getchannel('A').getbbox()
        assert bounds is not None, f'Empty frame {i}'
        assert min(bounds[0],bounds[1],256-bounds[2],256-bounds[3])>=2, f'Clipped frame {i}'
        assert frame.getpixel((0,0))[3]<=20, f'Nontransparent corner {i}'
    motion=[]
    for left,right in zip(frames,frames[1:]):
        diff=ImageChops.difference(visible(left),visible(right))
        rms=sum(ImageStat.Stat(diff).rms)/3
        assert rms>=2, f'Near duplicate {rms:.2f}'
        motion.append(rms)
    with Image.open(SOURCE/'preview.gif') as gif:
        assert gif.n_frames==8
        assert gif.info.get('loop')==0
    html=PAGE.read_text(encoding='utf-8')
    for token in ('../../assets/characters-v2/dog/idle/sheet.png','id="toggle"','id="seek"','id="theme"','id="size"','requestAnimationFrame','prefers-reduced-motion'):
        assert token in html, f'Missing gallery contract: {token}'
    print(f'PASS Dog Idle glossy V2: 8 frames, 7 changing neighbors, min visible RMS {min(motion):.2f}; review and phone QA pending')

if __name__=='__main__': main()
