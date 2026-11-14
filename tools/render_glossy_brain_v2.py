#!/usr/bin/env python3
"""Mirror verified glossy Brain V2 assets byte-identically into the versioned folder.

Active path is the source of truth; legacy flat SVG generator must not replace V2.
"""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json, shutil

ROOT=Path(__file__).resolve().parents[1]
LIVE=ROOT/'assets/characters/brain'
VERSIONED=ROOT/'assets/characters-v2/brain'
STATES={'idle':(8,2),'remind':(12,3)}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    master=LIVE/'master.png'
    with Image.open(master) as im:
        assert im.size==(640,640) and im.mode=='RGBA'
        assert im.getchannel('A').getextrema()==(0,255)
    (VERSIONED).mkdir(parents=True,exist_ok=True)
    shutil.copyfile(master,VERSIONED/'master.png')
    state_index={}
    for state,(frame_count,rows) in STATES.items():
        folder=LIVE/state
        meta=json.loads((folder/'metadata.json').read_text(encoding='utf-8'))
        assert meta['artStyle']=='glossy-kawaii-v2'
        assert meta['frames']==frame_count and meta['columns']==4 and meta['rows']==rows
        assert meta['frameWidth']==256 and meta['frameHeight']==256
        assert sha(folder/'sheet.png')==meta['sha256']
        if 'masterSha256' in meta:
            assert sha(master)==meta['masterSha256']
        with Image.open(folder/'sheet.png') as im:
            atlas=im.convert('RGBA')
        assert atlas.size==(1024,rows*256)
        prev=None
        for i in range(frame_count):
            crop=atlas.crop(((i%4)*256,(i//4)*256,((i%4)+1)*256,((i//4)+1)*256))
            bbox=crop.getchannel('A').getbbox()
            assert bbox and min(bbox[0],bbox[1],256-bbox[2],256-bbox[3])>=1,(state,i,bbox)
            if prev is not None:
                assert ImageChops.difference(prev,crop).getbbox() is not None,(state,i)
            prev=crop
        with Image.open(folder/'preview.gif') as gif:
            assert gif.n_frames==frame_count,(state,gif.n_frames)
        output=VERSIONED/state
        output.mkdir(parents=True,exist_ok=True)
        for name in ('sheet.png','sheet.webp','preview.gif','metadata.json'):
            src=folder/name
            assert src.is_file(),(state,name)
            shutil.copyfile(src,output/name)
        state_index[state]={'file':f'assets/characters-v2/brain/{state}/metadata.json',
                            'frames':frame_count}
        print('PASS V2 mirror',state,frame_count,'frames',meta['sha256'])
    manifest={'characterId':'brain','assetVersion':'2.0.0-partial',
              'sourceOfTruth':'assets/characters/brain',
              'artMaster':'assets/characters-v2/brain/master.png',
              'states':state_index,
              'v1FallbackAllowed':True,'productionReady':False,
              'note':'Only idle and remind are glossy; 13 other Brain states remain V1'}
    (VERSIONED/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    print('PASS 640px glossy Brain master and both idle/remind sets mirrored without re-rendering')

if __name__=='__main__':
    main()
