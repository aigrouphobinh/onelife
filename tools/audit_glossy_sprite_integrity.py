#!/usr/bin/env python3
"""Independent source and render consistency audit for OneLife mascot sprites."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/characters-v2"
catalog = json.loads((BASE / "animation_sources.json").read_text())
seen = set()
for spec in catalog["animationSources"]:
    key = (spec["characterId"], spec["state"])
    assert key not in seen, f"Duplicate state: {key}"
    seen.add(key)
    assert spec["columns"] == 4 and spec["frameWidth"] == spec["frameHeight"] == 256
    assert 8 <= spec["frames"] <= 24 and 60 <= spec["frameDurationMs"] <= 1000
    folder = BASE / key[0] / key[1]
    source = folder / spec["sourceFile"]
    assert source.is_file(), f"Missing source: {key}"
    assert hashlib.sha256(source.read_bytes()).hexdigest() == spec["sourceSha256"], key
    metadata = json.loads((folder / "metadata.json").read_text())
    atlas = folder / "sheet.png"
    qa = json.loads((folder / "qa_report.json").read_text())
    assert metadata["sourceSha256"] == spec["sourceSha256"], key
    assert metadata["sha256"] == hashlib.sha256(atlas.read_bytes()).hexdigest(), key
    assert qa["passed"] and qa["runtimeSha256"] == metadata["sha256"], key
    assert metadata["frames"] == spec["frames"] and metadata["loop"] == spec["loop"], key
    with Image.open(atlas) as image:
        assert image.mode == "RGBA" and image.size == (1024, ((spec["frames"]+3)//4)*256), key
    with Image.open(folder / "preview.gif") as gif:
        assert gif.n_frames == spec["frames"], key
        assert gif.info.get("loop") == (0 if spec["loop"] else None), key
print(f"PASS: {len(seen)} registered sprite clips, sources, atlases, metadata, QA and GIF playback")
