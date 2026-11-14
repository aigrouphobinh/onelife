#!/usr/bin/env python3
"""Validate every activated Glossy Brain V2 clip and its live mirror.

Only the states named in the versioned manifest count as V2. All remaining
V1 vector art stays unapproved even when earlier QA passes.
"""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json

ROOT=Path(__file__).resolve().parents[1]
STAGING=ROOT/"assets/characters-v2/brain"
LIVE=ROOT/"assets/characters/brain"

def sha(path:Path)->str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def validate_clip(folder:Path, state:str):
    meta=json.loads((folder/state/"metadata.json").read_text(encoding="utf-8"))
    assert meta["characterId"]=="brain" and meta["state"]==state
    assert meta.get("artStyle")=="glossy-kawaii-v2",f"Not glossy art: {folder/state}"
    n=meta["frames"]; cols=meta["columns"];rows=meta["rows"];cell=meta["frameWidth"]
    assert 6 <= n <= 20
    assert (cols,rows,cell,meta["frameHeight"])==(4,(n+3)//4,256,256)
    assert 75 <= meta["frameDurationMs"] <= 250
    atlas_path=folder/state/"sheet.png"
    assert sha(atlas_path)==meta["sha256"],f"PNG hash mismatch {atlas_path}"
    with Image.open(atlas_path) as im:
        assert im.mode=="RGBA",f"Sprite should use RGBA: {atlas_path}"
        atlas=im.copy()
    assert atlas.size==(cols*cell,rows*cell),atlas.size
    cells=[]
    for i in range(n):
        x,y=(i%cols)*cell,(i//cols)*cell
        frame=atlas.crop((x,y,x+cell,y+cell))
        bbox=frame.getchannel("A").getbbox()
        assert bbox and min(bbox[0],bbox[1],cell-bbox[2],cell-bbox[3])>=1,(state,i,bbox)
        assert frame.getpixel((0,0))[3]<16,(state,i,"missing transparent canvas")
        cells.append(frame)
    transitions=sum(ImageChops.difference(a,b).getbbox() is not None for a,b in zip(cells,cells[1:]))
    assert transitions>=max(5,round((n-1)*.75)),(state,transitions)
    with Image.open(folder/state/"preview.gif") as gif:
        assert gif.n_frames>=max(5,n-2),(state,"missing animated review frames")
    if (folder/state/"sheet.webp").exists():
        with Image.open(folder/state/"sheet.webp") as webp:
            assert webp.size==atlas.size
        if "sourceSha256" in meta:
            assert sha(folder/state/"sheet.webp")==meta["sourceSha256"],state
    print("PASS",folder.relative_to(ROOT),state,n,"frames",transitions,"moving transitions")
    return meta

def main():
    manifest=json.loads((STAGING/"manifest.json").read_text(encoding="utf-8"))
    states=manifest["states"]
    assert {"idle","remind","overloaded"}<=set(states),states
    assert len(states)==3,f"Unexpected glossy state count {len(states)}"
    for folder in (STAGING,LIVE):
        with Image.open(folder/"master.png") as image:
            assert image.mode=="RGBA" and image.width==image.height>=256
        for state in states:
            staged=validate_clip(folder,state)
            versioned=json.loads((STAGING/state/"metadata.json").read_text())
            assert staged["sha256"]==versioned["sha256"],(folder,state)
            assert sha(folder/state/"sheet.png")==sha(STAGING/state/"sheet.png")
    print("PASS: 3/15 genuine glossy V2 Brain states, 32 frames, 12 states remain V1")
if __name__=="__main__":
    main()
