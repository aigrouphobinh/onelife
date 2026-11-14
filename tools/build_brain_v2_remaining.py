#!/usr/bin/env python3
"""Produce eight glossy V2 *review candidates* (7 missing states + Resting rework).

The original painted sources are the committed V2 Happy, Sleepy and Recovering
PNG atlases. This pipeline composites state-specific illustrated UI props over
different painted key poses. The resulting frames are NOT independently
illustrated finished animation; metadata must retain that distinction.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageChops
import hashlib, json, math, shutil

ROOT=Path(__file__).resolve().parents[1]
BR=ROOT/"assets/characters-v2/brain"
LIVE=ROOT/"assets/characters/brain"
SPECS={"focus":(8,160,True),"study":(12,120,True),"done":(12,95,False),
       "thinking":(8,140,True),"sad":(8,160,False),"balanced":(8,140,True),
       "strained":(10,160,True),"resting":(10,205,True)}
POSES={
 "focus":[("recovering",3),("recovering",9),("happy",2),("happy",3),("happy",4),("recovering",10),("recovering",11),("recovering",3)],
 "study":[("recovering",3),("happy",0),("happy",1),("recovering",9),("happy",2),("recovering",10),("recovering",11),("happy",3),("happy",4),("recovering",6),("recovering",9),("recovering",3)],
 "done":[("recovering",3),("recovering",4),("happy",5),("recovering",6),("recovering",7),("recovering",8),("happy",7),("happy",8),("recovering",9),("recovering",10),("recovering",11),("happy",0)],
 "thinking":[("recovering",3),("recovering",2),("sleepy",2),("recovering",9),("recovering",10),("recovering",3),("happy",1),("recovering",11)],
 "sad":[("recovering",2),("sleepy",0),("sleepy",1),("sleepy",2),("recovering",1),("sleepy",3),("recovering",2),("sleepy",0)],
 "balanced":[("recovering",11),("recovering",9),("happy",0),("recovering",10),("happy",1),("recovering",9),("recovering",11),("happy",0)],
 "strained":[("recovering",2),("recovering",0),("sleepy",0),("recovering",1),("sleepy",2),("recovering",2),("sleepy",1),("recovering",0),("sleepy",0),("recovering",2)],
 "resting":[("sleepy",2),("sleepy",3),("recovering",0),("sleepy",4),("sleepy",5),("sleepy",6),("sleepy",7),("recovering",0),("sleepy",3),("sleepy",2)]}
def checksum(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def star(draw,x,y,r=8,color="#FFDA6C"):
    pts=[(x,y-r),(x+r*.25,y-r*.25),(x+r,y),(x+r*.25,y+r*.25),(x,y+r),(x-r*.25,y+r*.25),(x-r,y),(x-r*.25,y-r*.25)]
    draw.polygon(pts,fill=color)
    draw.line(pts+[pts[0]],fill="#D3954E",width=2)

def props(state,i,n):
    ang=math.tau*i/n;s=math.sin(ang);c=math.cos(ang)
    pic=Image.new("RGBA",(256,256));d=ImageDraw.Draw(pic)
    if state=="focus":
        y=193+round(2*s)
        d.rounded_rectangle((59,y,200,y+39),radius=9,fill="#6659B4",outline="#3C326E",width=4)
        d.rounded_rectangle((65,y+5,194,y+30),radius=6,fill="#BFB9F5",outline="#8576CA",width=2)
        d.rounded_rectangle((80,y+8,182,y+26),radius=4,fill="#DBE4FC")
        d.ellipse((118,y+14,128,y+24),fill="#977DDF")
        d.line((50,y+36,210,y+36),fill="#504083",width=6)
        if i in (1,4,6):star(d,199,85,7,"#A6E0FA")
    elif state=="study":
        y=190+round(2*s)
        d.polygon([(67,y),(116,y-4),(128,y+3),(186,y-4),(193,y),(193,y+46),(128,y+49),(67,y+46)],fill="#6F5BB1")
        d.polygon([(72,y+3),(115,y-1),(127,y+7),(127,y+44),(72,y+39)],fill="#FFF1DA")
        d.polygon([(129,y+7),(144,y-1),(187,y+3),(187,y+39),(129,y+44)],fill="#F8EACF")
        d.line((128,y+7,128,y+45),fill="#9B81D1",width=3)
        d.line((82,y+16,113,y+16),fill="#D5B6A7",width=2)
        d.line((146,y+16,177,y+16),fill="#D5B6A7",width=2)
        if i in (4,5,6):d.polygon([(129,y+8),(162+round(9*s),y-20),(177,y+5),(146,y+18)],fill="#FCE4AC",outline="#A47CC3")
        if i in (8,9):star(d,199,83,9)
    elif state=="done":
        x,y=194+round(s*6),91+round(c*5)
        d.ellipse((x-24,y-24,x+24,y+24),fill="#58D6A1",outline="#348E6E",width=4)
        d.line([(x-13,y),(x-3,y+10),(x+15,y-13)],fill="white",width=7,joint="curve")
        star(d,60+round(8*s),78,8)
        if i>=5:star(d,201,156,6)
    elif state=="thinking":
        x,y=186+round(7*s),77+round(4*c)
        d.rounded_rectangle((x-31,y-27,x+31,y+28),radius=20,fill="#FFFFFF",outline="#BAA6EC",width=4)
        d.ellipse((x-17,y+27,x-8,y+35),fill="#FFFFFF",outline="#BAA6EC",width=2)
        d.arc((x-12,y-15,x+15,y+13),180,480,fill="#8C68D0",width=5)
        d.ellipse((x,y+16,x+6,y+22),fill="#8C68D0")
    elif state=="sad":
        x=181+round(5*s)
        d.polygon([(x,140),(x-12,162),(x-5,178),(x+8,178),(x+14,165)],fill="#82CDED")
        d.ellipse((x-6,162,x+5,176),fill="#BCE8FF")
    elif state=="balanced":
        star(d,199+round(7*s),84+round(5*c),9,"#62D9B2")
        star(d,60-round(5*c),96+round(6*s),6)
        d.arc((54,58,204,233),20,145,fill="#86DBCE",width=3)
    elif state=="strained":
        x=185+round(3*s)
        d.polygon([(x,122),(x-12,146),(x-8,156),(x+7,159),(x+14,145)],fill="#79C9F0")
        d.ellipse((x-6,143,x+6,156),fill="#AFE5FC")
        d.arc((55,89,201,222),220,300,fill="#A6A0C9",width=3)
    elif state=="resting":
        d.rounded_rectangle((75,206,183,223),radius=9,fill="#C8B9F7",outline="#8971D3",width=3)
        for j in range(2):
            x=191+j*13+round(3*s)
            d.arc((x-8,72+j*13,x+11,93+j*13),210,322,fill="#79CEC5",width=3)
        if i in (3,7):star(d,202,67,5,"#D1C8FA")
    return pic

def load_source(name,index):
    path=BR/name/"sheet.png"
    assert path.exists(), "Missing source "+str(path)
    with Image.open(path) as im:
        return im.convert("RGBA").crop(((index%4)*256,(index//4)*256,(index%4+1)*256,(index//4+1)*256))

def build():
    for state,(count,duration,loop) in SPECS.items():
        directory=BR/state;directory.mkdir(parents=True,exist_ok=True)
        frames=[]
        for i in range(count):
            source_state,source_i=POSES[state][i]
            art=load_source(source_state,source_i).resize((230,230),Image.Resampling.LANCZOS)
            frame=Image.new("RGBA",(256,256));frame.alpha_composite(art,(13,12))
            frame.alpha_composite(props(state,i,count))
            bbox=frame.getchannel("A").getbbox()
            assert bbox and min(bbox[0],bbox[1],256-bbox[2],256-bbox[3])>=1,(state,i,bbox)
            frames.append(frame)
        changing=sum(ImageChops.difference(a,b).getbbox() is not None for a,b in zip(frames,frames[1:]))
        assert changing>=max(5,round((count-1)*.75)),(state,changing)
        rows=(count+3)//4; atlas=Image.new("RGBA",(1024,rows*256))
        for i,frame in enumerate(frames):atlas.alpha_composite(frame,((i%4)*256,(i//4)*256))
        png=directory/"sheet.png";atlas.save(png,optimize=True)
        atlas.save(directory/"sheet.webp",format="WEBP",quality=82,method=5,exact=True)
        previews=[]
        for frame in frames:
            bg=Image.new("RGB",(256,256),(247,243,252));bg.paste(frame,mask=frame.getchannel("A"))
            previews.append(bg)
        previews[0].save(directory/"preview.gif",save_all=True,append_images=previews[1:],duration=duration,loop=0 if loop else 1,disposal=2,optimize=False)
        metadata={
            "characterId":"brain","state":state,"artStyle":"glossy-kawaii-v2","version":"2.4.0-composited-review",
            "frames":count,"columns":4,"rows":rows,"frameWidth":256,"frameHeight":256,
            "frameDurationMs":duration,"loop":loop,"anchorX":.5,"anchorY":.92,
            "runtimeAsset":"sheet.png","webPreviewAsset":"sheet.webp","preview":"preview.gif",
            "sha256":checksum(png),"licenseRef":"docs/ASSET_REGISTER.md",
            "source":"Existing painted Glossy V2 poses: Happy, Sleepy, Recovering; added state-specific animated props",
            "generationClass":"derived-pose-composite",
            "reviewStatus":"CANDIDATE ONLY: NOT fully individually illustrated, human/device approval pending"}
        (directory/"metadata.json").write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+"\n")
        mirror=LIVE/state;mirror.mkdir(parents=True,exist_ok=True)
        for file in ("sheet.png","sheet.webp","preview.gif","metadata.json"):
            shutil.copy2(directory/file,mirror/file)
        print("PASS glossy composite",state,count,"frames",changing,"transitions")
    for base in (BR,LIVE):
        path=base/"manifest.json";manifest=json.loads(path.read_text(encoding="utf-8"))
        for state,(frames,_,_) in SPECS.items():
            manifest.setdefault("states",{})[state]={
               "file":str((base/state/"metadata.json").relative_to(ROOT)),"frames":frames}
        manifest["assetVersion"]="2.4.0-candidates"
        manifest["productionReady"]=False
        manifest["artReview"]="Remaining state clips (and Resting rework) are composited from original painted poses: visual review required, no claims of newly illustrated full motion."
        path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")

if __name__=="__main__":
    build()
