#!/usr/bin/env python3
"""Build and validate the genuinely illustrated 12-frame glossy Brain overloaded atlas.

The source sheet.webp is an optimized, RGBA-composited export of original
AI-generated art. It is not reconstructed from flat SVG or from one scaled pose.
This script is deterministic for a given WebP and Pillow version.
"""
from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageChops
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "assets/characters-v2/brain/overloaded"
LIVE = ROOT / "assets/characters/brain/overloaded"
SOURCE = STAGE / "sheet.webp"
FRAME_COUNT, COLUMNS, CELL, DURATION = 12, 4, 256, 115
SOURCE_SHA256 = "e75d3b4c0b07c98c98161fa6141ae2331f04d732f5ce8bc4275c7039181d4f57"

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main() -> None:
    assert SOURCE.is_file(), f"Missing real glossy source WebP: {SOURCE}"
    assert sha(SOURCE) == SOURCE_SHA256, "Source WebP changed without review"
    STAGE.mkdir(parents=True, exist_ok=True)
    with Image.open(SOURCE) as image:
        atlas = image.convert("RGBA")
    assert atlas.size == (1024, 768), atlas.size
    frames = []
    bboxes = []
    for i in range(FRAME_COUNT):
        x = i % COLUMNS * CELL
        y = i // COLUMNS * CELL
        frame = atlas.crop((x, y, x+CELL, y+CELL))
        bbox = frame.getchannel("A").getbbox()
        assert bbox and min(bbox[0],bbox[1],CELL-bbox[2],CELL-bbox[3]) >= 1, (i,bbox)
        assert frame.getpixel((0,0))[3] < 12, f"non-transparent background: {i}"
        bboxes.append(bbox)
        frames.append(frame)
    distinct = sum(ImageChops.difference(a,b).getbbox() is not None for a,b in zip(frames, frames[1:]))
    assert distinct == FRAME_COUNT - 1, f"Duplicate adjacent poses: {distinct}"
    sheet_png = STAGE / "sheet.png"
    atlas.save(sheet_png,optimize=True)
    # GIF is a review preview, not the Flutter runtime animation source.
    rgb_frames = []
    for frame in frames:
        canvas = Image.new("RGB",frame.size,(247,243,252))
        canvas.paste(frame,mask=frame.getchannel("A"))
        rgb_frames.append(canvas)
    rgb_frames[0].save(STAGE/"preview.gif",save_all=True,append_images=rgb_frames[1:],
        duration=DURATION,loop=0,disposal=2,optimize=True)
    metadata = {
        "characterId":"brain","state":"overloaded","version":"2.0.0",
        "artStyle":"glossy-kawaii-v2",
        "source":"sheet.webp","runtimeAsset":"sheet.png","webPreviewAsset":"sheet.webp",
        "preview":"preview.gif","frames":FRAME_COUNT,"columns":COLUMNS,"rows":3,
        "frameWidth":CELL,"frameHeight":CELL,
        "frameDurationMs":DURATION,"loop":True,"anchorX":0.5,"anchorY":0.92,
        "sha256":sha(sheet_png),"sourceSha256":SOURCE_SHA256,
        "licenseRef":"docs/ASSET_REGISTER.md",
        "reviewStatus":"illustrated v2 candidate; human motion and real-device checks pending",
        "interpretation":"Friendly metaphor for a user-defined break goal, not a medical diagnosis",
    }
    (STAGE/"metadata.json").write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+"\n")
    for filename in ("sheet.png","sheet.webp","preview.gif","metadata.json"):
        LIVE.mkdir(parents=True,exist_ok=True)
        shutil.copy2(STAGE/filename,LIVE/filename)
    manifest_path=ROOT/"assets/characters-v2/brain/manifest.json"
    manifest=json.loads(manifest_path.read_text())
    manifest.setdefault("states",{})["overloaded"]={
        "file":"assets/characters-v2/brain/overloaded/metadata.json","frames":FRAME_COUNT
    }
    manifest["note"]="Glossy Brain V2 states idle, remind, overloaded; 12 others remain V1."
    manifest["productionReady"]=False
    manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    live_manifest_path=ROOT/"assets/characters/brain/manifest.json"
    if live_manifest_path.exists():
        live_manifest=json.loads(live_manifest_path.read_text())
        live_manifest.setdefault("states",{})["overloaded"]={
            "file":"assets/characters/brain/overloaded/metadata.json","frames":FRAME_COUNT
        }
        live_manifest_path.write_text(json.dumps(live_manifest,ensure_ascii=False,indent=2)+"\n")
    report={"passed":True,"clip":"brain/overloaded","frames":FRAME_COUNT,
        "uniqueAdjacentTransitions":distinct,"rgbaSize":[1024,768],
        "sha256":metadata["sha256"],"sourceSha256":SOURCE_SHA256,
        "alphaBounds":bboxes,"humanVisualReview":"pending","deviceTest":"pending"}
    (STAGE/"qa_report.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n")
    assert sha(LIVE/"sheet.png")==metadata["sha256"]
    print(f"PASS glossy Brain overloaded: {FRAME_COUNT} original illustrated frames; SHA {metadata['sha256']}")
if __name__ == "__main__":
    main()
