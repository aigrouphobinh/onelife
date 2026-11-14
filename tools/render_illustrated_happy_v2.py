#!/usr/bin/env python3
"""Render the separately illustrated, user-style-aligned Happy V2 sprite atlas.
The 12 poses are original glossy artwork. The source is an immutable WebP committed
to Git; preview PNG/GIF, mirror, and manifests are generated reproducibly.
"""
from pathlib import Path
from PIL import Image, ImageChops
import hashlib, json, shutil

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets/characters-v2/brain/happy/sheet_illustrated.webp"
OUT = SRC.parent
LIVE = ROOT / "assets/characters/brain/happy"
SOURCE_SHA256 = "0de17ddd7099186a2993ad41a2477298a49c0d5f75b5d0a7fc9939add949f689"
CELL, COUNT, COLUMNS, DURATION = 256, 12, 4, 95

def sha(path:Path)->str: return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    assert SRC.is_file(), "Missing committed illustrated Happy V2 source"
    assert sha(SRC)==SOURCE_SHA256, "Happy original source checksum mismatch"
    with Image.open(SRC) as image:
        atlas=image.convert("RGBA")
    assert atlas.size==(1024,768), atlas.size
    frames=[]
    for i in range(COUNT):
        x,y=(i%4)*CELL,(i//4)*CELL
        f=atlas.crop((x,y,x+CELL,y+CELL))
        box=f.getchannel("A").getbbox()
        assert box and min(box[0],box[1],CELL-box[2],CELL-box[3])>=1,(i,box)
        assert f.getpixel((0,0))[3]<16,(i,"nontransparent edge")
        frames.append(f)
    transitions=sum(ImageChops.difference(a,b).getbbox() is not None for a,b in zip(frames,frames[1:]))
    assert transitions==COUNT-1,transitions
    OUT.mkdir(parents=True,exist_ok=True); LIVE.mkdir(parents=True,exist_ok=True)
    atlas.save(OUT/"sheet.png",optimize=True)
    # WebP is the original illustrated source of this clip, not the old montage.
    shutil.copyfile(SRC,OUT/"sheet.webp")
    previews=[]
    for f in frames:
        canvas=Image.new("RGB",(CELL,CELL),(247,243,252))
        canvas.paste(f,mask=f.getchannel("A"))
        previews.append(canvas)
    previews[0].save(OUT/"preview.gif",save_all=True,append_images=previews[1:],
      duration=DURATION,loop=0,disposal=2,optimize=False)
    meta={
      "characterId":"brain","state":"happy","version":"2.2.0-illustrated-candidate",
      "artStyle":"glossy-kawaii-v2","frames":COUNT,"columns":4,"rows":3,
      "frameWidth":CELL,"frameHeight":CELL,"frameDurationMs":DURATION,"loop":True,
      "anchorX":0.5,"anchorY":0.92,"source":"sheet_illustrated.webp",
      "runtimeAsset":"sheet.png","webPreviewAsset":"sheet.webp","preview":"preview.gif",
      "sha256":sha(OUT/"sheet.png"),"sourceSha256":SOURCE_SHA256,
      "licenseRef":"docs/ASSET_REGISTER.md",
      "reviewStatus":"original illustrated poses; manual continuity and phone QA pending"
    }
    (OUT/"metadata.json").write_text(json.dumps(meta,ensure_ascii=False,indent=2)+"\n")
    for file in ("sheet.png","sheet.webp","preview.gif","metadata.json"):
        shutil.copy2(OUT/file,LIVE/file)
    for basedir in (ROOT/"assets/characters-v2/brain",ROOT/"assets/characters/brain"):
        file=basedir/"manifest.json"
        manifest=json.loads(file.read_text())
        manifest.setdefault("states",{})["happy"]={
            "file":str((basedir/"happy/metadata.json").relative_to(ROOT)),"frames":COUNT
        }
        manifest["productionReady"]=False
        manifest["artReview"]="Happy original 12 illustrated poses require human and device review; Resting still montage"
        file.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    print("PASS illustrated happy 12 frames, 11 moving transitions",meta["sha256"])

if __name__=="__main__": main()
