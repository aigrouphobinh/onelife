#!/usr/bin/env python3
"""Validate V2 source and live Brain raster exports independently."""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json
ROOT=Path(__file__).resolve().parents[1]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def check(folder):
    m=json.loads((folder/'remind/metadata.json').read_text())
    assert m['characterId']=='brain' and m['state']=='remind'
    assert (m['frames'],m['columns'],m['rows'],m['frameWidth'],m['frameHeight'])==(12,4,3,256,256)
    assert 75<=m['frameDurationMs']<=250
    assert sha(folder/'remind/sheet.png')==m['sha256']
    if 'masterSha256' in m: assert sha(folder/'master.png')==m['masterSha256']
    with Image.open(folder/'master.png') as img:
        assert img.mode=='RGBA' and img.width>=256 and img.width==img.height
        assert img.getpixel((0,0))[3]<16
        size=img.size
    with Image.open(folder/'remind/sheet.png') as img: atlas=img.convert('RGBA')
    assert atlas.size==(1024,768)
    frames=[]
    for i in range(12):
        x,y=(i%4)*256,(i//4)*256
        frame=atlas.crop((x,y,x+256,y+256))
        b=frame.getchannel('A').getbbox()
        assert b and min(b[0],b[1],256-b[2],256-b[3])>=1, (i,b)
        frames.append(frame)
    transitions=sum(ImageChops.difference(a,b).getbbox() is not None for a,b in zip(frames,frames[1:]))
    assert transitions>=10
    with Image.open(folder/'remind/preview.gif') as gif: assert gif.n_frames>=11
    print('PASS',folder.relative_to(ROOT),'master',size,'frames',len(frames),'transitions',transitions)
if __name__=='__main__':
    check(ROOT/'assets/characters-v2/brain')
    check(ROOT/'assets/characters/brain')
    print('PASS: V2 and live source verified separately; other states remain unapproved V1')
