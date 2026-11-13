#!/usr/bin/env python3
"""Render OneLife design mockups from SVG into review PNGs and verify geometry."""
import hashlib
import io
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import cairosvg
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SCREENS=ROOT/"design"/"screens"

def main():
    sources=sorted(SCREENS.glob("*.svg"))
    if len(sources)!=10:
        raise SystemExit(f"Expected 10 page SVG designs, found {len(sources)}")
    records=[]
    for p in sources:
        svg=ET.parse(p).getroot()
        if svg.attrib.get("viewBox")!="0 0 390 844":
            raise ValueError(f"Unexpected screen canvas: {p}")
        image=Image.open(io.BytesIO(cairosvg.svg2png(url=str(p)))).convert("RGBA")
        if image.size!=(390,844):
            raise AssertionError(f"Wrong raster dimensions {p}")
        out=p.with_suffix(".png")
        image.save(out,optimize=True)
        records.append({"screen":p.stem,"file":out.name,"sha256":hashlib.sha256(out.read_bytes()).hexdigest(),"width":390,"height":844})
        print(f"PASS {p.stem}: {out.stat().st_size} bytes")
    (SCREENS/"manifest.json").write_text(json.dumps({"schemaVersion":1,"status":"design mockups, not real app screenshots","screens":records},ensure_ascii=False,indent=2)+"\n")
if __name__=="__main__":
    main()
