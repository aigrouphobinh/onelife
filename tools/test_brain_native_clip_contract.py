#!/usr/bin/env python3
"""Contract: Android Brain native animation uses real candidate PNG atlases.

State durations/counts are checked against *committed* metadata, not invented
uniform 8-frame assumptions. This does not approve the art for production.
"""
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BRAIN = ROOT / "assets/characters-v2/brain"
EXPECTED = {
    "idle": (8, 2, 140),
    "focus": (8, 2, 160),
    "balanced": (8, 2, 140),
    "strained": (10, 3, 160),
    "overloaded": (12, 3, 115),
}


def main():
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    native = (ROOT / "android/app/src/main/kotlin/com/aigrouphobinh/onelife/"
              "BrainOverlayService.kt").read_text(encoding="utf-8")
    manifest = json.loads((BRAIN / "manifest.json").read_text(encoding="utf-8"))
    assert manifest.get("productionReady") is False, (
        "Do not silently promote candidate art to production-approved"
    )
    for state, (frames, rows, duration) in EXPECTED.items():
        folder = BRAIN / state
        meta = json.loads((folder / "metadata.json").read_text(encoding="utf-8"))
        assert meta["state"] == state
        assert (meta["frames"], meta["columns"], meta["rows"],
                meta["frameDurationMs"]) == (frames, 4, rows, duration)
        assert meta["frameWidth"] == meta["frameHeight"] == 256
        assert meta["runtimeAsset"] == "sheet.png"
        file = folder / "sheet.png"
        with file.open("rb") as stream:
            header = stream.read(24)
        assert header[:8] == b"\x89PNG\r\n\x1a\n", state
        width, height = struct.unpack(">II", header[16:24])
        assert (width, height) == (1024, rows * 256), (
            state, (width, height)
        )
        path = "assets/characters-v2/brain/" + state + "/sheet.png"
        assert path in pubspec, ("Missing from APK Flutter assets", path)

    assert '"strained" -> 10' in native
    assert '"overloaded" -> 12' in native
    assert '"focus", "strained" -> 160L' in native
    assert '"overloaded" -> 115L' in native
    assert "frameIndex % frameCount(currentState)" in native
    assert "focused && focusSheet != null" in native
    assert "wellbeingSheet = decode(desired)" in native
    assert "handler.removeCallbacks(refreshBehavior)" in native
    print("PASS: Five real Brain atlases, 8/10/12 frame geometry, timings and candidate QA status")


if __name__ == "__main__":
    main()
