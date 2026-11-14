#!/usr/bin/env python3
"""Pack genuine individually illustrated RGBA frames into a Glossy V2 source atlas.

This tool NEVER invents or interpolates missing art. It only converts an exact
sequence of individually supplied frame_00.png .. frame_NN.png into a WebP atlas.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageStat

CELL = 256
COLS = 4

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def pack(source_dir: Path, output: Path, duration_ms: int = 140,
         loop: bool = True, quality: int = 86) -> dict:
    if not source_dir.is_dir():
        raise ValueError("Missing frame directory")
    inputs = sorted(source_dir.glob("*.png"))
    n = len(inputs)
    if not 8 <= n <= 24:
        raise ValueError(f"Need 8–24 individually illustrated frames; found {n}")
    expected = [f"frame_{i:02d}.png" for i in range(n)]
    if [p.name for p in inputs] != expected:
        raise ValueError("Frame files must be contiguous frame_00.png ... frame_NN.png")
    if not 60 <= duration_ms <= 1000:
        raise ValueError("Frame duration must be 60–1000 ms")
    if not 50 <= quality <= 100:
        raise ValueError("WebP quality must be 50–100")

    frames = []
    bounds = []
    previous = None
    adjacent_rms = []
    dimensions = None
    for i, path in enumerate(inputs):
        with Image.open(path) as im:
            if im.mode != "RGBA":
                raise ValueError(f"{path.name}: require true RGBA (RGB/checkerboard is not transparency)")
            if im.width != im.height or im.width < 256:
                raise ValueError(f"{path.name}: source should be square and at least 256 px")
            if dimensions is None:
                dimensions = im.size
            elif im.size != dimensions:
                raise ValueError(f"{path.name}: inconsistent source size; align before packing")
            frame = im.resize((CELL, CELL), Image.Resampling.LANCZOS)
        alpha = frame.getchannel("A")
        bbox = alpha.getbbox()
        if bbox is None:
            raise ValueError(f"{path.name}: empty frame")
        if min(bbox[0], bbox[1], CELL-bbox[2], CELL-bbox[3]) < 2:
            raise ValueError(f"{path.name}: clipped/touches tile boundary {bbox}")
        if max(frame.getpixel((x,y))[3] for x,y in ((0,0),(CELL-1,0),(0,CELL-1),(CELL-1,CELL-1))) > 20:
            raise ValueError(f"{path.name}: opaque corner, possible baked checkerboard")
        if previous is not None:
            diff = ImageChops.difference(previous, frame)
            rms = sum(ImageStat.Stat(diff).rms[:3]) / 3
            if rms < 2.0:
                raise ValueError(f"{path.name}: nearly same pose as previous frame (RMS {rms:.2f})")
            adjacent_rms.append(round(rms,2))
        previous = frame
        frames.append(frame)
        bounds.append(list(bbox))
    rows = (n + COLS - 1)//COLS
    atlas = Image.new("RGBA", (COLS*CELL, rows*CELL))
    for i, frame in enumerate(frames):
        atlas.alpha_composite(frame, (i%COLS*CELL, i//COLS*CELL))
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, "WEBP", quality=quality, method=6, exact=True)
    with Image.open(output) as check:
        if check.size != atlas.size or check.convert("RGBA").getpixel((0,0))[3] > 20:
            raise AssertionError("WebP output failed geometry/alpha round-trip")
    report = {
        "status":"source-packing-qa-only",
        "artApproval":"pending",
        "deviceApproval":"pending",
        "frames":n, "columns":COLS, "rows":rows,
        "frameWidth":CELL, "frameHeight":CELL, "sourceDimensions":list(dimensions),
        "frameDurationMs":duration_ms, "loop":loop,
        "sourceFiles":[{"file":p.name,"sha256":sha(p)} for p in inputs],
        "frameBounds":bounds, "adjacentRgbRms":adjacent_rms,
        "webpFile":output.name, "webpSha256":sha(output),
    }
    report_path = output.with_name("pack_qa.json")
    report_path.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(f"PASS packed {n} illustrated frames -> {output} (SHA256 {report['webpSha256']})")
    return report

def self_test() -> None:
    # Synthetic shapes test only the importer, NEVER count as character artwork.
    with tempfile.TemporaryDirectory(prefix="onelife_frame_pack_") as tmp:
        root = Path(tmp)
        src = root/"frames"
        src.mkdir()
        for i in range(8):
            im=Image.new("RGBA",(256,256))
            d=ImageDraw.Draw(im)
            d.rounded_rectangle((68+i*5,70,170+i*5,198),radius=28,fill=(182,126,232,255))
            im.save(src/f"frame_{i:02d}.png")
        data=pack(src,root/"sheet_illustrated.webp",150,True)
        assert data["frames"]==8 and len(data["adjacentRgbRms"])==7
        assert (root/"pack_qa.json").is_file()
        (src/"frame_03.png").rename(src/"frame_90.png")
        try:
            pack(src,root/"should_fail.webp")
        except ValueError as exc:
            assert "contiguous" in str(exc)
        else:
            raise AssertionError("Noncontiguous frames must fail")
    print("PASS packer self-test: geometry, alpha, frame order, motion and WebP source")

def main() -> None:
    parser=argparse.ArgumentParser()
    parser.add_argument("--frames-dir",type=Path)
    parser.add_argument("--output",type=Path)
    parser.add_argument("--duration-ms",type=int,default=140)
    parser.add_argument("--one-shot",action="store_true")
    parser.add_argument("--quality",type=int,default=86)
    parser.add_argument("--self-test",action="store_true")
    args=parser.parse_args()
    if args.self_test:
        self_test()
        return
    if args.frames_dir is None or args.output is None:
        parser.error("Provide --frames-dir and --output, or --self-test")
    pack(args.frames_dir,args.output,args.duration_ms,not args.one_shot,args.quality)

if __name__=="__main__":
    main()
