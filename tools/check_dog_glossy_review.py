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

    # Additional one-shot Dog Remind clip: validate only when declared by catalog.
    reminder = [e for e in catalog['animationSources'] if e['characterId']=='dog' and e['state']=='remind']
    if reminder:
        assert len(reminder)==1
        folder=ROOT/'assets/characters-v2/dog/remind'
        spec=reminder[0]
        meta=json.loads((folder/'metadata.json').read_text())
        report=json.loads((folder/'qa_report.json').read_text())
        assert sha(folder/'sheet_illustrated.webp')==spec['sourceSha256']==meta['sourceSha256']
        assert sha(folder/'sheet.png')==meta['sha256']
        assert meta['frames']==12 and meta['columns']==4 and meta['rows']==3
        assert meta['frameDurationMs']==125 and meta['loop'] is False
        assert report['passed'] is True and report['previewLoop']=='once'
        with Image.open(folder/'sheet.png') as image:
            assert image.size==(1024,768)
            atlas=image.convert('RGBA')
        frames=[atlas.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256)) for i in range(12)]
        for i,frame in enumerate(frames):
            bounds=frame.getchannel('A').getbbox()
            assert bounds is not None and min(bounds[0],bounds[1],256-bounds[2],256-bounds[3])>=2, f'Dog remind frame {i} clipped'
        for i,(left,right) in enumerate(zip(frames,frames[1:])):
            rms=sum(ImageStat.Stat(ImageChops.difference(visible(left),visible(right))).rms)/3
            assert rms>=2, f'Near duplicate Dog Remind frames {i},{i+1}'
        with Image.open(folder/'preview.gif') as preview:
            assert preview.n_frames==12 and preview.info.get('loop') is None
        assert '../../assets/characters-v2/dog/remind/sheet.png' in html
        print('PASS Dog Remind glossy V2: 12 distinct keyframes, one-shot, SHA verified; human/device QA pending')


    # Dog Alarm independent original illustrations: clock with hands and two bells, not Remind bell.
    alarm = [e for e in catalog['animationSources'] if e['characterId']=='dog' and e['state']=='alarm']
    if alarm:
        assert len(alarm)==1
        folder=ROOT/'assets/characters-v2/dog/alarm'
        spec=alarm[0]
        meta=json.loads((folder/'metadata.json').read_text())
        report=json.loads((folder/'qa_report.json').read_text())
        assert spec['sourceSha256']==sha(folder/'sheet_illustrated.webp')==meta['sourceSha256']
        assert meta['sha256']==sha(folder/'sheet.png')
        assert meta['frames']==12 and meta['columns']==4 and meta['rows']==3
        assert meta['frameDurationMs']==110 and meta['loop'] is False
        assert report['passed'] is True and report['previewLoop']=='once'
        with Image.open(folder/'sheet.png') as sheet:
            assert sheet.size==(1024,768)
            atlas=sheet.convert('RGBA')
        frames=[atlas.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256)) for i in range(12)]
        for i,frame in enumerate(frames):
            bbox=frame.getchannel('A').getbbox()
            assert bbox is not None and min(bbox[0],bbox[1],256-bbox[2],256-bbox[3])>=2, f'Dog Alarm clipped: {i}'
            assert frame.getpixel((0,0))[3]<=20, f'Dog Alarm opaque background: {i}'
        for i,(left,right) in enumerate(zip(frames,frames[1:])):
            rms=sum(ImageStat.Stat(ImageChops.difference(visible(left),visible(right))).rms)/3
            assert rms>=2, f'Dog Alarm near duplicate: {i},{i+1}'
        with Image.open(folder/'preview.gif') as gif:
            assert gif.n_frames==12 and gif.info.get('loop') is None
        assert '../../assets/characters-v2/dog/alarm/sheet.png' in html
        assert 'value="alarm"' in html
        print('PASS Dog Alarm V2: 12 original poses, one-shot, pinned SHA and gallery path; visual/device sign-off pending')

    resting = [e for e in catalog['animationSources'] if e['characterId']=='dog' and e['state']=='resting']
    if resting:
        assert len(resting)==1, 'Duplicate dog resting catalog entries'
        folder=ROOT/'assets/characters-v2/dog/resting'
        spec=resting[0]
        meta=json.loads((folder/'metadata.json').read_text())
        report=json.loads((folder/'qa_report.json').read_text())
        assert sha(folder/'sheet_illustrated.webp')==spec['sourceSha256']==meta['sourceSha256']
        assert sha(folder/'sheet.png')==meta['sha256']
        assert meta['frames']==12 and meta['columns']==4 and meta['rows']==3
        assert meta['frameDurationMs']==200 and meta['loop'] is True
        assert report['passed'] is True and report['previewLoop']=='infinite'
        with Image.open(folder/'sheet.png') as sheet:
            assert sheet.size==(1024,768)
            atlas=sheet.convert('RGBA')
        frames=[atlas.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256)) for i in range(12)]
        assert all(frame.getchannel('A').getbbox() is not None for frame in frames)
        for i,(left,right) in enumerate(zip(frames,frames[1:])):
            rms=sum(ImageStat.Stat(ImageChops.difference(visible(left),visible(right))).rms)/3
            assert rms >= 2, f'Dog Resting adjacent near duplicate: {i}'
        with Image.open(folder/'preview.gif') as gif:
            assert gif.n_frames==12 and gif.info.get('loop')==0
        assert '../../assets/characters-v2/dog/resting/sheet.png' in html
        assert 'value="resting"' in html
        seam=sum(ImageStat.Stat(ImageChops.difference(visible(frames[-1]),visible(frames[0]))).rms)/3
        print(f'PASS Dog Resting: 12 distinct poses, loop preview; seam RMS {seam:.2f} pending art review')


    # Dog Overloaded is a gentle, user-configured screen-break cue, NOT a medical diagnosis.
    overload = [e for e in catalog['animationSources'] if e['characterId']=='dog' and e['state']=='overloaded']
    if overload:
        assert len(overload) == 1, 'Duplicate dog/overloaded source'
        folder = ROOT/'assets/characters-v2/dog/overloaded'
        spec = overload[0]
        meta = json.loads((folder/'metadata.json').read_text())
        report = json.loads((folder/'qa_report.json').read_text())
        assert sha(folder/'sheet_illustrated.webp') == spec['sourceSha256'] == meta['sourceSha256']
        assert sha(folder/'sheet.png') == meta['sha256']
        assert meta['frames'] == 12 and meta['columns'] == 4 and meta['rows'] == 3
        assert meta['frameDurationMs'] == 150 and meta['loop'] is False
        assert report['passed'] and report['previewLoop'] == 'once'
        with Image.open(folder/'sheet.png') as sheet:
            assert sheet.size == (1024,768)
            atlas = sheet.convert('RGBA')
        frames = [atlas.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256)) for i in range(12)]
        for i, frame in enumerate(frames):
            bbox = frame.getchannel('A').getbbox()
            assert bbox and min(bbox[0],bbox[1],256-bbox[2],256-bbox[3]) >= 2, f'Dog Overloaded clipped frame {i}'
            assert frame.getpixel((0,0))[3] <= 20, f'Dog Overloaded opaque corner frame {i}'
        for i,(left,right) in enumerate(zip(frames, frames[1:])):
            rms = sum(ImageStat.Stat(ImageChops.difference(visible(left), visible(right))).rms)/3
            assert rms >= 2, f'Dog Overloaded near-duplicate {i}->{i+1}'
        with Image.open(folder/'preview.gif') as gif:
            assert gif.n_frames == 12 and gif.info.get('loop') is None
        assert '../../assets/characters-v2/dog/overloaded/sheet.png' in html
        assert 'value="overloaded"' in html
        print('PASS Dog Overloaded V2: 12 poses, one-shot, source hash verified; art/mobile QA pending')

    print(f'PASS Dog Idle glossy V2: 8 frames, 7 changing neighbors, min visible RMS {min(motion):.2f}; review and phone QA pending')

if __name__=='__main__': main()
