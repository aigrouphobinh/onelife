#!/usr/bin/env python3
"""Fail-closed illustrated Dog Sleepy V2 regression test; not human art approval."""
from pathlib import Path
from PIL import Image, ImageChops, ImageStat
import hashlib, json

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / "assets/characters-v2/dog/sleepy"
SRC = FOLDER / "sheet_illustrated.webp"
CATALOG = ROOT / "assets/characters-v2/animation_sources.json"
VIEWER = ROOT / "design/review/glossy-dog-idle.html"
EXPECTED = "3aa07462a3d4819981c532fb2b09761cbf536f5358105589d87891924eedb347"

def checksum(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def visible(frame):
    return Image.alpha_composite(Image.new("RGBA",frame.size,(247,243,252,255)),frame.convert("RGBA")).convert("RGB")

def run():
    source_spec = [x for x in json.loads(CATALOG.read_text())["animationSources"]
                   if x["characterId"] == "dog" and x["state"] == "sleepy"]
    assert len(source_spec) == 1, "Expected exactly one dog/sleepy source"
    spec = source_spec[0]
    assert checksum(SRC) == EXPECTED == spec["sourceSha256"], "Source checksum"
    meta = json.loads((FOLDER/"metadata.json").read_text())
    report = json.loads((FOLDER/"qa_report.json").read_text())
    assert spec["frames"] == meta["frames"] == 12
    assert spec["frameDurationMs"] == meta["frameDurationMs"] == 180
    assert spec["loop"] is False and meta["loop"] is False
    assert report["passed"] is True and report["previewLoop"] == "once"
    assert checksum(FOLDER/"sheet.png") == meta["sha256"]
    with Image.open(FOLDER/"sheet.png") as im:
        atlas = im.convert("RGBA")
    assert atlas.size == (1024,768), "Invalid atlas dimensions"
    frames = [atlas.crop((i%4*256,i//4*256,(i%4+1)*256,(i//4+1)*256)) for i in range(12)]
    for i,frame in enumerate(frames):
        bbox = frame.getchannel("A").getbbox()
        assert bbox and min(bbox[0],bbox[1],256-bbox[2],256-bbox[3]) >= 2, f"Clipped frame {i}"
        assert frame.getpixel((0,0))[3] <= 20, f"Background alpha {i}"
    scores = []
    for a,b in zip(frames,frames[1:]):
        d = ImageChops.difference(visible(a),visible(b))
        scores.append(sum(ImageStat.Stat(d).rms)/3)
    assert min(scores) >= 2, "Near-duplicate visible frames"
    with Image.open(FOLDER/"preview.gif") as gif:
        assert gif.n_frames == 12
        assert gif.info.get("loop") is None, "Sleepy GIF must play once"
    html = VIEWER.read_text(encoding="utf-8")
    assert 'value="sleepy"' in html and "dog/sleepy/sheet.png" in html
    assert "ms:180,loop:false" in html
    print(f"PASS Dog Sleepy V2: 12 poses, 11 visible transitions, min RMS {min(scores):.2f}; human/device QA pending")

if __name__ == "__main__":
    run()
