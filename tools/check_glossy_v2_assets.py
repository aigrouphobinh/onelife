#!/usr/bin/env python3
"""Verify glossy V2 Brain master and active idle/remind atlases against versioned assets."""
import hashlib, json
from pathlib import Path
from PIL import Image, ImageChops
root=Path(__file__).resolve().parents[1]
active=root/"assets/characters/brain"
versions=root/"assets/characters-v2/brain"
master=active/"master.png"
with Image.open(master) as im:
    assert im.size==(640,640) and im.mode=="RGBA"
for state,n,rows in [("idle",8,2),("remind",12,3)]:
    meta=json.loads((active/state/"metadata.json").read_text(encoding="utf-8"))
    assert meta["artStyle"]=="glossy-kawaii-v2" and meta["frames"]==n
    assert (meta["columns"],meta["rows"],meta["frameWidth"],meta["frameHeight"])==(4,rows,256,256)
    for parent in (active,versions):
        path=parent/state/"sheet.png"
        assert path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==meta["sha256"],(state,path)
        for filename in ("preview.gif","sheet.webp","metadata.json"):
            assert (parent/state/filename).is_file(),(state,filename)
    with Image.open(active/state/"sheet.png") as im:
        atlas=im.convert("RGBA")
    assert atlas.size==(1024,256*rows)
    frames=[]
    for i in range(n):
        x,y=i%4*256,i//4*256
        frame=atlas.crop((x,y,x+256,y+256))
        bbox=frame.getchannel("A").getbbox()
        assert bbox and min(bbox[0],bbox[1],256-bbox[2],256-bbox[3])>=1,(state,i,bbox)
        frames.append(frame)
    assert all(ImageChops.difference(frames[i],frames[i+1]).getbbox() is not None for i in range(n-1))
    with Image.open(active/state/"preview.gif") as gif:assert gif.n_frames==n,(state,gif.n_frames)
    print("PASS glossy V2",state,n,"distinct frames with alpha and stable geometry")
print("PASS high-fidelity Brain master; 2/15 character states migrated to glossy V2")
