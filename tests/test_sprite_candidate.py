#!/usr/bin/env python3
"""Regression tests for the Glossy Kawaii illustrated-source preflight.

Run: python -m unittest discover -s tests -p 'test_sprite_candidate.py'
Only synthetic in-memory fixtures; no art files or network required.
"""
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "check_sprite_candidate", ROOT / "tools" / "check_sprite_candidate.py"
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(mod)


def fixture(path: Path, *, frames: int = 4, clipped: bool = False,
            duplicates: bool = False, opaque_background: bool = False):
    image = Image.new("RGBA", (1024, 256),
                      (255, 255, 255, 255) if opaque_background else (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    for i in range(frames):
        x = i * 256 + (0 if clipped and i == 0 else 35)
        offset = 0 if duplicates else i * 12
        d.ellipse((x + offset, 52, x + offset + 55, 115),
                  fill=(245, 146, 71, 255))
    image.save(path)


class SpriteCandidateTests(unittest.TestCase):
    def test_valid_distinct_transparent_frames_pass(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "good.png"
            fixture(p)
            result = mod.inspect(p, frames=4)
            self.assertTrue(result["technicalPreflightPassed"])
            self.assertEqual(len(result["adjacentVisibleRms"]), 3)
            self.assertEqual(result["humanVisualApproval"], "pending")

    def test_near_duplicate_frames_fail(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "duplicate.png"
            fixture(p, duplicates=True)
            result = mod.inspect(p, frames=4)
            self.assertFalse(result["technicalPreflightPassed"])
            self.assertTrue(any("near duplicate" in s for s in result["warnings"]))

    def test_clipped_first_frame_fails(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "edge.png"
            fixture(p, clipped=True)
            result = mod.inspect(p, frames=4)
            self.assertFalse(result["technicalPreflightPassed"])
            self.assertTrue(any("edge" in s or "border" in s
                                for s in result["warnings"]))

    def test_opaque_background_fails(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "opaque.png"
            fixture(p, opaque_background=True)
            result = mod.inspect(p, frames=4)
            self.assertFalse(result["technicalPreflightPassed"])
            self.assertTrue(any("border" in s for s in result["warnings"]))

    def test_wrong_geometry_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "wrong.png"
            Image.new("RGBA", (512, 512)).save(p)
            with self.assertRaisesRegex(ValueError, "Expected"):
                mod.inspect(p, frames=4)

    def test_no_invalid_frame_count(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "valid.png"
            fixture(p)
            with self.assertRaisesRegex(ValueError, "Invalid frame geometry"):
                mod.inspect(p, frames=0)

    def test_printed_opaque_panel_is_not_transparency(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "fake_alpha.png"
            image = Image.new("RGBA", (1024, 256), (0, 0, 0, 0))
            d = ImageDraw.Draw(image)
            for i in range(4):
                d.rectangle((i * 256 + 4, 4, i * 256 + 251, 251),
                            fill=(255, 255, 255, 255))
                d.ellipse((i * 256 + 90 + i * 4, 60,
                           i * 256 + 140 + i * 4, 115),
                          fill=(250, 156, 55, 255))
            image.save(p)
            result = mod.inspect(p, frames=4)
            self.assertFalse(result["technicalPreflightPassed"])
            self.assertTrue(any("painted background suspected" in w
                                for w in result["warnings"]))



if __name__ == "__main__":
    unittest.main()
