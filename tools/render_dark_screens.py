#!/usr/bin/env python3
"""Reproducibly export dark-mode UI mockups from the editable light SVGs."""
from pathlib import Path
import hashlib, json, xml.etree.ElementTree as ET
import cairosvg
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/"design/screens"
DST=SRC/"dark"
SVG_NS="http://www.w3.org/2000/svg"
ET.register_namespace("",SVG_NS)
MAP={
 "#F8F6FD":"#17152A",
 "#ECE7F6":"#4E4567",
 "#E3DEEF":"#49415F",
 "#292448":"#F7F3FF",
 "#7F7995":"#C4BBDC",
 "#958EA9":"#B7AED0",
 "#EDE8F9":"#38304F",
 "#F0E8FD":"#413457",
 "#FFF0F6":"#49324B",
 "#F0E6FF":"#382B55",
 "#FFE0EF":"#51364E",
 "#E4D8FF":"#49355F",
 "#E3F9F0":"#274840",
 "#FFE7F0":"#553447",
 "#E1F2FF":"#2D3E59",
 "#F5EDFF":"#443753",
 "#F3E6FA":"#483650",
 "#DBCEF8":"#E5D9FB",
 "#7759CB":"#B5A4FF",
 "#C65F95":"#FFA7CE",
 "#B89FEA":"#A88AEA",
}
def map_colors(element,inside_mascot=False):
    tag=element.tag.rsplit("}",1)[-1]
    inside_mascot=inside_mascot or element.attrib.get("id")=="region-mascot"
    if not inside_mascot:
        for key in ("fill","stroke","stop-color"):
            val=element.attrib.get(key,"")
            keycolor=val.upper()
            if keycolor=="#FFF" or keycolor=="#FFFFFF":
                # Preserve bright text in the dark header, but recolor white cards.
                if key=="fill" and tag not in ("text","tspan"):
                    element.set(key,"#29243F")
            elif keycolor in MAP:
                element.set(key,MAP[keycolor])
    for child in element: map_colors(child,inside_mascot)
def run():
    DST.mkdir(parents=True,exist_ok=True)
    light=json.loads((SRC/"manifest.json").read_text())
    entries=[]
    for item in light["screens"]:
        stem=item["screen"]
        source=SRC/(stem+".svg")
        tree=ET.parse(source)
        root=tree.getroot()
        map_colors(root)
        root.set("aria-label","OneLife "+stem+" Dark Mode design mockup")
        darksvg=DST/(stem+".svg")
        tree.write(darksvg,encoding="utf-8",xml_declaration=True)
        png=DST/(stem+".png")
        cairosvg.svg2png(url=str(darksvg),write_to=str(png))
        with Image.open(png) as img:
            if img.size!=(390,844):raise RuntimeError("Invalid dark screen dimensions: "+stem)
        entries.append({"screen":stem,"file":png.name,"sha256":hashlib.sha256(png.read_bytes()).hexdigest(),"width":390,"height":844,"mode":"dark"})
        print("PASS dark mode",stem)
    (DST/"manifest.json").write_text(json.dumps({"schemaVersion":1,"derivedFrom":"design/screens/*.svg","status":"dark theme design only, not Flutter app screenshots","screens":entries},indent=2)+"\n")
if __name__=="__main__":run()
