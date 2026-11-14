#!/usr/bin/env python3
"""Keep versioned glossy Brain V2 byte-identical to the verified 640px live art.
The compact WebP reference sources are preserved but must never downgrade live art.
"""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json, shutil

ROOT=Path(__file__).resolve().parents[1]
LIVE=ROOT/'assets/characters/brain'
VERSIONED=ROOT/'assets/characters-v2/brain'

def checksum(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    source_master=LIVE/'master.png'
    source_sheet=LIVE/'remind/sheet.png'
    source_gif=LIVE/'remind/preview.gif'
    source_meta=LIVE/'remind/metadata.json'
    metadata=json.loads(source_meta.read_text(encoding='utf-8'))
    if metadata.get('artStyle')!='glossy-kawaii-v2':
        raise AssertionError('Cannot overwrite V2 with a flat vector art style')
    if metadata['sha256'] != checksum(source_sheet) or metadata['masterSha256'] != checksum(source_master):
        raise AssertionError('Canonical glossy Brain SHA-256 mismatch')
    with Image.open(source_master) as im:
        assert im.size==(640,640) and im.convert('RGBA').getchannel('A').getextrema()==(0,255)
    with Image.open(source_sheet) as im:
        atlas=im.convert('RGBA')
    assert atlas.size==(1024,768)
    previous=None
    for i in range(12):
        frame=atlas.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256))
        box=frame.getchannel('A').getbbox()
        assert box is not None and min(box[0],box[1],256-box[2],256-box[3])>=1,(i,box)
        if previous is not None:
            assert ImageChops.difference(previous,frame).getbbox() is not None,i
        previous=frame
    with Image.open(source_gif) as gif:
        assert gif.n_frames>=11
    (VERSIONED/'remind').mkdir(parents=True,exist_ok=True)
    for src,dst in ((source_master,VERSIONED/'master.png'),
                    (source_sheet,VERSIONED/'remind/sheet.png'),
                    (source_gif,VERSIONED/'remind/preview.gif'),
                    (source_meta,VERSIONED/'remind/metadata.json')):
        shutil.copyfile(src,dst)
    manifest={
      'characterId':'brain','assetVersion':'2.0.0',
      'sourceOfTruth':'assets/characters/brain',
      'artMaster':'assets/characters-v2/brain/master.png',
      'states':{'remind':{'file':'assets/characters-v2/brain/remind/metadata.json','frames':12}},
      'v1FallbackAllowed':False,'productionReady':False
    }
    (VERSIONED/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('PASS canonical 640px V2 master + 12 true glossy frames mirrored to versioned assets')

if __name__=='__main__':
    main()
