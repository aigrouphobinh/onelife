#!/usr/bin/env python3
"""Render real glossy Brain V2 from committed WebP sources; do not synthesize flat SVG substitutes."""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json

ROOT=Path(__file__).resolve().parents[1]
ASSET=ROOT/'assets/characters-v2/brain'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    master_source=ASSET/'master_512.webp'
    sheet_source=ASSET/'remind/sheet_source_1024.webp'
    if not master_source.is_file() or not sheet_source.is_file():
        raise FileNotFoundError('Required glossy source files are missing')
    with Image.open(master_source) as source: master=source.convert('RGBA')
    if master.size != (512,512) or master.getchannel('A').getextrema() != (0,255):
        raise AssertionError('Master must be 512px transparent RGBA')
    master.save(ASSET/'master.png',optimize=True)
    with Image.open(sheet_source) as source: sheet=source.convert('RGBA')
    if sheet.size != (1024,768) or sheet.getpixel((0,0))[3] > 15:
        raise AssertionError('Sheet must be a transparent 4x3 atlas of 256px cells')
    png=ASSET/'remind/sheet.png'
    sheet.save(png,optimize=True)
    frames=[]
    previous=None
    transitions=0
    for i in range(12):
        frame=sheet.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256))
        bbox=frame.getchannel('A').getbbox()
        if bbox is None or min(bbox[0],bbox[1],256-bbox[2],256-bbox[3])<1:
            raise AssertionError(f'Empty or clipped frame {i}: {bbox}')
        if previous is not None and ImageChops.difference(previous,frame).getbbox() is not None:
            transitions+=1
        previous=frame
        matte=Image.new('RGBA',frame.size,(248,245,252,255))
        matte.alpha_composite(frame)
        frames.append(matte.convert('RGB').resize((192,192),Image.Resampling.LANCZOS))
    if transitions<10: raise AssertionError(f'Only {transitions} moving transitions')
    frames[0].save(ASSET/'remind/preview.gif',save_all=True,append_images=frames[1:],
        duration=110,loop=0,disposal=2,optimize=False)
    meta={
        'version':'2.0.0','characterId':'brain','state':'remind','frames':12,
        'columns':4,'rows':3,'frameWidth':256,'frameHeight':256,'frameDurationMs':110,
        'loop':True,'anchorX':0.5,'anchorY':0.92,'runtimeAsset':'sheet.png',
        'source':'sheet_source_1024.webp','preview':'preview.gif',
        'sha256':sha(png),'sourceSha256':sha(sheet_source),
        'artDirection':'design/STYLE_LOCK_V2.md',
        'status':'visual_review_candidate_not_entire_character_pack'
    }
    (ASSET/'remind/metadata.json').write_text(json.dumps(meta,indent=2)+'\n')
    manifest={'characterId':'brain','assetVersion':'2.0.0',
              'artMaster':'assets/characters-v2/brain/master.png',
              'states':{'remind':{'file':'assets/characters-v2/brain/remind/metadata.json','frames':12}},
              'v1FallbackAllowed':False,'productionReady':False}
    (ASSET/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('PASS: Real glossy Brain V2 master, 12 reminder frames, GIF and metadata')
if __name__=='__main__': main()
