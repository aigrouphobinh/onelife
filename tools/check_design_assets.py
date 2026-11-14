#!/usr/bin/env python3
"""Check OneLife sprites/screens/sounds, render five expression contact sheets."""
from pathlib import Path
import hashlib, json, sys, wave
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
CHARS=("brain","cat","dog","robot","sprout")
STATES={"idle":8,"happy":10,"remind":12,"alarm":12,"focus":8,"study":12,"sleepy":10,"done":12,"thinking":8,"sad":8,"balanced":8,"strained":10,"overloaded":12,"resting":10,"recovering":12}
OUT=ROOT/"design/review"
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def run():
    (OUT/"reports").mkdir(parents=True,exist_ok=True)
    (OUT/"contact-sheets").mkdir(parents=True,exist_ok=True)
    errors=[];warnings=[];records=[]
    try: font=ImageFont.truetype("DejaVuSans.ttf",14)
    except OSError: font=ImageFont.load_default()
    for character in CHARS:
        basedir=ROOT/"assets/characters"/character
        if not (basedir/"master.svg").is_file(): errors.append(character+": master missing")
        canvas=Image.new("RGB",(900,672),(248,247,252))
        painter=ImageDraw.Draw(canvas)
        for index,(state,count) in enumerate(STATES.items()):
            path=basedir/state; tag=character+"/"+state
            required=[path/x for x in ("sheet.svg","sheet.png","preview.gif","metadata.json")]
            if any(not x.is_file() for x in required):
                errors.append(tag+": required file missing");continue
            try:
                expected = 12 if character == "brain" and state in ("happy", "sleepy") else count
                m=json.loads(required[-1].read_text())
                # V1 source frame counts remain unchanged; promoted glossy live
                # art may intentionally have a different number of painted poses.
                if character=="brain" and state in ("happy", "sleepy") and m.get("artStyle")=="glossy-kawaii-v2":
                    count=12
                if (m["characterId"],m["state"],m["frames"],m["columns"],m["rows"],m["frameWidth"],m["frameHeight"]) != (character,state,expected,4,(expected+3)//4,256,256):
                    errors.append(tag+": metadata mismatch")
                if m.get("sha256")!=sha(required[1]): errors.append(tag+": PNG checksum mismatch")
                with Image.open(required[2]) as g:
                    if getattr(g,"n_frames",0)<2: errors.append(tag+": not an animated GIF")
                with Image.open(required[1]) as img: atlas=img.convert("RGBA")
                if atlas.size!=(1024,((count+3)//4)*256):errors.append(tag+": invalid atlas dimensions");continue
                clips=[];changes=0;prev=None
                centers=[]
                for i in range(count):
                    x,y=(i%4)*256,(i//4)*256
                    frame=atlas.crop((x,y,x+256,y+256))
                    bbox=frame.getchannel("A").getbbox()
                    if not bbox: errors.append(tag+": empty frame "+str(i));continue
                    if min(bbox[0],bbox[1],256-bbox[2],256-bbox[3])<1:
                        errors.append(tag+": clipped frame "+str(i))
                    centers.append(((bbox[0]+bbox[2])/2,(bbox[1]+bbox[3])/2))
                    fingerprint=hashlib.blake2s(frame.tobytes()).digest()
                    if prev is not None and prev!=fingerprint:changes+=1
                    prev=fingerprint
                    clips.append(frame)
                if changes<round((count-1)*.65):warnings.append(tag+": only "+str(changes)+" moving transitions")
                if centers and (max(x for x,_ in centers)-min(x for x,_ in centers)>48 or max(y for _,y in centers)-min(y for _,y in centers)>48):
                    warnings.append(tag+": bounding box drift; review visually")
                if clips:
                    frame=clips[min(len(clips)-1,count//2)].resize((162,162),Image.Resampling.LANCZOS)
                    px=(index%5)*180+9;py=(index//5)*224+8
                    canvas.paste(frame,(px,py),frame)
                    painter.text((px+7,py+173),state.upper(),font=font,fill=(43,38,69))
                    painter.text((px+7,py+194),str(count)+" frames",font=font,fill=(105,97,126))
                records.append({"character":character,"state":state,"frames":count,"changingTransitions":changes,"pngBytes":required[1].stat().st_size})
            except (OSError,KeyError,TypeError,ValueError) as e:
                errors.append(tag+": "+str(e))
        canvas.save(OUT/"contact-sheets"/(character+".png"),optimize=True)
    try:
        manifest=json.loads((ROOT/"design/screens/manifest.json").read_text())
        if len(manifest["screens"])!=10:errors.append("Expected 10 design screens")
        for s in manifest["screens"]:
            img=ROOT/"design/screens"/s["file"]
            if not img.is_file() or not img.with_suffix(".svg").is_file() or sha(img)!=s["sha256"]:
                errors.append("Screen missing/mismatch "+s["file"])
            else:
                with Image.open(img) as screen:
                    if screen.size!=(s["width"],s["height"]):errors.append("Screen size "+s["file"])
    except (OSError,KeyError,ValueError) as e:errors.append("Screen manifest: "+str(e))
    try:
        darkdir=ROOT/"design/screens/dark"
        dark=json.loads((darkdir/"manifest.json").read_text())
        if len(dark["screens"])!=10:errors.append("Expected 10 dark design screens")
        for s in dark["screens"]:
            p=darkdir/s["file"]
            if not p.is_file() or not p.with_suffix(".svg").is_file() or sha(p)!=s["sha256"]:
                errors.append("Dark screen missing/mismatch "+s["file"])
            else:
                with Image.open(p) as im:
                    if im.size!=(s["width"],s["height"]):errors.append("Dark screen size "+s["file"])
    except (OSError,KeyError,ValueError) as e:errors.append("Dark manifest: "+str(e))
    try:
        concepts_dir=ROOT/"design/wellbeing"
        concepts=json.loads((concepts_dir/"manifest.json").read_text())
        if len(concepts["files"])!=12:errors.append("Expected 12 Brain Balance storyboard images")
        for s in concepts["files"]:
            p=concepts_dir/s["file"]
            if not p.is_file() or not (concepts_dir/s["source"]).is_file() or sha(p)!=s["sha256"]:
                errors.append("Brain Balance storyboard missing/checksum mismatch: "+s["file"])
            else:
                with Image.open(p) as im:
                    if im.size!=(s["width"],s["height"]):errors.append("Brain Balance dimensions: "+s["file"])
    except (OSError,KeyError,ValueError) as e:errors.append("Brain Balance storyboard: "+str(e))
    try:
        manifest=json.loads((ROOT/"assets/sounds/manifest.json").read_text())
        for name,s in manifest["sounds"].items():
            p=ROOT/"assets/sounds"/s["file"]
            if not p.is_file() or sha(p)!=s["sha256"]:errors.append("Sound mismatch "+name);continue
            with wave.open(str(p),"rb") as w:
                if not .1<=(w.getnframes()/w.getframerate())<=5:errors.append("Sound duration "+name)
    except (OSError,KeyError,ValueError) as e:errors.append("Sound manifest: "+str(e))
    total=sum(x["frames"] for x in records)
    if len(records)!=75 or total!=764:errors.append("Expected 75 clips/764 active frames, got "+str((len(records),total)))
    report={"schemaVersion":1,"automatedOnly":True,"passed":not errors,"clips":len(records),"frames":total,"errors":errors,"warnings":warnings,"records":records}
    (OUT/"reports/asset-qa.json").write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n")
    lines=["# Automated OneLife Asset QA","","Status: **"+("PASS" if not errors else "FAIL")+"** — automated only, not visual or device sign-off.","",f"Clips: {len(records)}/75 · active frames: {total}/764","",
           "## Errors"]+["- "+x for x in errors or ["None"]]+["","## Warnings"]+["- "+x for x in warnings or ["None"]]+["","## Contact sheets"]+["- ["+x+"](../contact-sheets/"+x+".png)" for x in CHARS]+["",
           "Unverified: artistic quality, reduced-motion accessibility, battery consumption, real Android/iOS playback and platform permissions."]
    (OUT/"reports/asset-qa.md").write_text("\n".join(lines)+"\n")
    print("Asset QA:",len(records),"clips,",total,"frames,",len(errors),"errors,",len(warnings),"warnings")
    for e in errors:print("ERROR:",e)
    for w in warnings:print("WARNING:",w)
    return 1 if errors else 0
if __name__=="__main__":sys.exit(run())
