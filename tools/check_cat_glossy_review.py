#!/usr/bin/env python3
"""Fail closed when Cat Glossy preview invents states or omits an installed clip.
Design-only QA; this does not sign off motion quality or device performance.
"""
from __future__ import annotations
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
CAT=ROOT/"assets/characters-v2/cat"
HTML=ROOT/"design/review/glossy-cat-idle.html"

def main():
    html=HTML.read_text(encoding="utf-8")
    manifest=json.loads((CAT/"manifest.json").read_text(encoding="utf-8"))
    wanted=set(manifest["states"])
    match=re.search(r'<select id="state">([\s\S]*?)</select>',html)
    assert match, "Character state dropdown missing"
    options=set(re.findall(r'<option value="([a-z]+)">',match.group(1)))
    assert options==wanted, f"Mismatch: UI={options} manifest={wanted}"
    configs=re.search(r'const config=\{([\s\S]*?)\};',html)
    assert configs,"Preview playback config missing"
    found=set(re.findall(r'(?:^|,)([a-z]+):\{frames:',configs.group(1)))
    assert found==wanted, f"Mismatch: config={found} manifest={wanted}"
    for state in wanted:
        meta=json.loads((CAT/state/"metadata.json").read_text(encoding="utf-8"))
        assert meta["characterId"]=="cat" and meta["state"]==state
        assert (CAT/state/"sheet.png").exists()
        state_config=re.search(r'(?:^|,)'+re.escape(state)+r':\{frames:(\d+),duration:(\d+),loop:(true|false)\}',configs.group(1))
        assert state_config, f"Missing static config for {state}"
        assert int(state_config.group(1))==meta["frames"],f"Frame mismatch {state}"
        assert int(state_config.group(2))==meta["frameDurationMs"],f"Timing mismatch {state}"
        assert (state_config.group(3)=="true")==bool(meta["loop"]),f"Loop mismatch {state}"
    scripts=re.findall(r'<script>([\s\S]*?)</script>',html)
    assert len(scripts)==1
    p=subprocess.run(["node","--check","-"],input=scripts[0],text=True,capture_output=True)
    assert p.returncode==0,p.stderr
    assert "prefers-reduced-motion" in html
    print(f"PASS Cat preview: {len(wanted)} states, runtime metadata matches playback, JS valid")

if __name__=="__main__":
    main()
