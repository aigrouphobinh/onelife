#!/usr/bin/env python3
"""Verify the actual glossy V2 binary is present at versioned and live paths."""
import hashlib, json
from pathlib import Path
from PIL import Image, ImageChops

root=Path(__file__).resolve().parents[1]
brain=root/"assets/characters/brain"
v2=root/"assets/characters-v2/brain"
spec=json.loads((brain/"remind/metadata.json").read_text(encoding="utf-8"))
assert spec["artStyle"]=="glossy-kawaii-v2"
assert spec["frames"]==12 and spec["columns"]==4 and spec["rows"]==3
pairs=[(brain/"master.png",v2/"master.png",spec["masterSha256"]),
       (brain/"remind/sheet.png",v2/"remind/sheet.png",spec["sha256"])]
for current,versioned,expected in pairs:
    assert current.is_file() and versioned.is_file()
    for path in (current,versioned):
        assert hashlib.sha256(path.read_bytes()).hexdigest()==expected,(str(path),"checksum mismatch")
with Image.open(brain/"master.png") as im:
    assert im.size==(640,640) and im.mode=="RGBA"
with Image.open(brain/"remind/sheet.png") as im:
    atlas=im.convert("RGBA")
assert atlas.size==(1024,768)
frames=[]
for i in range(12):
    x,y=(i%4)*256,(i//4)*256
    crop=atlas.crop((x,y,x+256,y+256))
    bbox=crop.getchannel("A").getbbox()
    assert bbox is not None and min(bbox[0],bbox[1],256-bbox[2],256-bbox[3])>=1,(i,bbox)
    frames.append(crop)
assert all(ImageChops.difference(frames[i],frames[i+1]).getbbox() is not None for i in range(11))
with Image.open(brain/"remind/preview.gif") as gif:
    assert gif.n_frames>=11
print("PASS: genuine glossy Brain master + 12-frame remind are deployed and valid; remaining states are V1")
