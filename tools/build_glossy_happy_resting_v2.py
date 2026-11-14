#!/usr/bin/env python3
"""Create glossy Happy and Resting *candidate* sprite clips from painted V2 poses.

Both clips use multiple existing painted Brain frames, not flat SVGs. They are
pose montages with drawn accent effects, not a substitute for future bespoke
hand-painted in-between frames or Android device acceptance.
"""
from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import hashlib, json, math, shutil

ROOT=Path(__file__).resolve().parents[1]
BRAIN=ROOT/"assets/characters-v2/brain"
CELL=256
STATES={
 "happy":{"source":[("idle",0),("idle",1),("idle",6),("idle",4),("idle",5),("idle",6),("overloaded",11),("idle",4),("idle",6),("idle",7),("idle",2),("idle",0)],"ms":105},
 "resting":{"source":[("idle",3),("overloaded",8),("overloaded",9),("overloaded",9),("overloaded",9),("overloaded",9),("overloaded",9),("overloaded",9),("overloaded",8),("idle",3)],"ms":185},
}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def source_frame(name,index):
    with Image.open(BRAIN/name/"sheet.png") as im: atlas=im.convert("RGBA")
    x,y=index%4,index//4
    return atlas.crop((x*CELL,y*CELL,(x+1)*CELL,(y+1)*CELL))

def render(state,config):
    folder=BRAIN/state;folder.mkdir(parents=True,exist_ok=True)
    count=len(config["source"])
    atlas=Image.new("RGBA",(1024,CELL*((count+3)//4)))
    frames=[]
    for i,(source,frame_i) in enumerate(config["source"]):
        phase=math.tau*i/count
        painted=source_frame(source,frame_i)
        scale=.934+math.sin(phase)*.018
        size=round(CELL*scale)
        painted=painted.resize((size,size),Image.Resampling.LANCZOS)
        tile=Image.new("RGBA",(CELL,CELL))
        yy=round((CELL-size)/2-(4 if state=="happy" else 1)*math.sin(phase))
        tile.alpha_composite(painted,((CELL-size)//2,yy))
        fx=Image.new("RGBA",(CELL,CELL));pen=ImageDraw.Draw(fx)
        if state=="happy":
            for k in (0,1):
                x=183+13*k+round(4*math.sin(phase))
                y=79+18*k+round(8*math.cos(phase))
                r=3+round(2*abs(math.sin(phase+k)))
                pen.polygon([(x,y-r*2),(x+r,y),(x,y+r*2),(x-r,y)],fill=(255,203,79,200))
        else:
            radius=86+round(3*math.sin(phase))
            pen.arc((128-radius,154-radius,128+radius,154+radius),40,155,fill=(113,185,212,45),width=3)
            if 2<=i<=8:
                d=round(3*math.sin(phase))
                pen.line([(179+d,69),(191+d,69),(180+d,82),(192+d,82)],fill=(135,112,218,175),width=3)
        tile.alpha_composite(fx)
        bbox=tile.getchannel("A").getbbox()
        assert bbox and min(bbox[0],bbox[1],CELL-bbox[2],CELL-bbox[3])>=1,(state,i,bbox)
        frames.append(tile)
        atlas.alpha_composite(tile,((i%4)*CELL,(i//4)*CELL))
    distinct=sum(ImageChops.difference(a,b).getbbox() is not None for a,b in zip(frames,frames[1:]))
    assert distinct>=count-2,(state,distinct)
    atlas.save(folder/"sheet.png",optimize=True)
    atlas.save(folder/"sheet.webp",quality=85,method=6,exact=True)
    review=[]
    for frame in frames:
        rgb=Image.new("RGB",(CELL,CELL),(247,243,252))
        rgb.paste(frame,mask=frame.getchannel("A"));review.append(rgb)
    review[0].save(folder/"preview.gif",save_all=True,append_images=review[1:],duration=config["ms"],loop=0,disposal=2,optimize=False)
    metadata={"characterId":"brain","state":state,"version":"2.1.0-candidate","artStyle":"glossy-kawaii-v2",
      "frames":count,"columns":4,"rows":(count+3)//4,"frameWidth":CELL,"frameHeight":CELL,
      "frameDurationMs":config["ms"],"loop":True,"anchorX":.5,"anchorY":.92,
      "runtimeAsset":"sheet.png","webPreviewAsset":"sheet.webp","preview":"preview.gif",
      "sha256":sha(folder/"sheet.png"),"licenseRef":"docs/ASSET_REGISTER.md",
      "source":"Montage of existing original painted Brain V2 idle and overloaded key poses",
      "reviewStatus":"technical candidate; new custom in-between drawings and real-device review pending"}
    (folder/"metadata.json").write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+"\n")
    live=ROOT/"assets/characters/brain"/state;live.mkdir(parents=True,exist_ok=True)
    for fn in ("sheet.png","sheet.webp","preview.gif","metadata.json"):shutil.copy2(folder/fn,live/fn)
    print("PASS",state,count,"frames",distinct,"transitions",metadata["sha256"])

def main():
    for state,config in STATES.items():render(state,config)
    for base in (BRAIN,ROOT/"assets/characters/brain"):
        manifest=base/"manifest.json"
        obj=json.loads(manifest.read_text()) if manifest.exists() else {"characterId":"brain","states":{}}
        for state,config in STATES.items():
            obj.setdefault("states",{})[state]={"file":str((base/state/"metadata.json").relative_to(ROOT)),"frames":len(config["source"])}
        obj["productionReady"]=False
        obj["artReview"]="Happy and Resting use painted key-pose montages; bespoke frame-by-frame artwork pending"
        manifest.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+"\n")
if __name__=="__main__":main()
