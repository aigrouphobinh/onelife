#!/usr/bin/env python3
"""Render contact sheet of all 15 *real committed* Brain V2 animation atlases."""
from __future__ import annotations
import hashlib,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1]
BR=ROOT/"assets/characters-v2/brain"
OUT=ROOT/"design/review"
ORDER=["idle","remind","happy","overloaded","resting","alarm","sleepy","recovering",
       "focus","study","done","thinking","sad","balanced","strained"]
W,H=362,252

def main():
    manifest=json.loads((BR/"manifest.json").read_text(encoding="utf-8"))
    assert set(ORDER)==set(manifest["states"])
    try:
        titlefont=ImageFont.truetype("DejaVuSans-Bold.ttf",17)
        smallfont=ImageFont.truetype("DejaVuSans.ttf",11)
    except OSError:
        titlefont=ImageFont.load_default()
        smallfont=ImageFont.load_default()
    canvas=Image.new("RGB",(W*5,H*3),(242,237,252))
    draw=ImageDraw.Draw(canvas)
    report={"schemaVersion":1,"artApproval":False,"frames":0,"clips":[]}
    for i,state in enumerate(ORDER):
        p=BR/state
        meta=json.loads((p/"metadata.json").read_text(encoding="utf-8"))
        with Image.open(p/"sheet.png") as im: atlas=im.convert("RGBA")
        n=meta["frames"]
        assert atlas.size==(1024,((n+3)//4)*256)
        assert hashlib.sha256((p/"sheet.png").read_bytes()).hexdigest()==meta["sha256"]
        x=(i%5)*W;y=(i//5)*H
        draw.rounded_rectangle((x+8,y+9,x+W-8,y+H-8),radius=22,fill=(255,255,255),outline=(215,205,237),width=2)
        draw.text((x+24,y+21),state.title(),font=titlefont,fill=(73,46,111))
        origin=meta.get("generationClass","illustrated-source")
        derived=origin=="derived-pose-composite"
        kind="REVIEW COMPOSITE" if derived else "GLOSSY ORIGINAL"
        draw.text((x+24,y+47),kind,font=smallfont,fill=(128,106,153))
        samples=(0,n//2)
        for j,k in enumerate(samples):
            frame=atlas.crop(((k%4)*256,(k//4)*256,(k%4+1)*256,(k//4+1)*256))
            frame=frame.resize((160,160),Image.Resampling.LANCZOS)
            px=x+17+j*170;py=y+70
            canvas.paste(frame,(px,py),frame)
        draw.text((x+W-90,y+24),f"{n} frames",font=smallfont,fill=(127,103,149))
        report["clips"].append({"state":state,"frames":n,"sourceClass":origin,"sha256":meta["sha256"]})
        report["frames"]+=n
    assert report["frames"]==156
    assert len(report["clips"])==15
    OUT.mkdir(parents=True,exist_ok=True)
    png=OUT/"glossy-brain-v2-contact.png"
    canvas.save(png,optimize=True)
    (OUT/"glossy-brain-v2-contact.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    print(f"PASS: {len(report['clips'])} V2 clips, {report['frames']} frames, preview {png}")

if __name__=="__main__":
    main()
