"""Regression tests for true source alpha in Glossy Kawaii sprite atlases.

Run: python -m unittest discover -s tests -p 'test_sprite_candidate_alpha.py'
Requires Pillow.
"""
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from check_sprite_candidate import inspect


class SpriteAlphaTests(unittest.TestCase):
    def make_atlas(self, directory, mode):
        path = Path(directory) / f"atlas_{mode}.png"
        atlas = Image.new("RGBA", (128, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(atlas)
        draw.ellipse((12, 12, 43, 43), fill=(255, 80, 120, 255))
        draw.ellipse((84, 12, 115, 43), fill=(60, 160, 255, 255))
        if mode == "RGB":
            atlas = atlas.convert("RGB")
        elif mode == "P":
            # Palette images without a transparency entry must not be
            # accepted merely because converting them yields an A channel.
            atlas = atlas.convert("RGB").convert("P")
        atlas.save(path)
        return path

    def test_rgba_with_true_alpha_passes(self):
        with tempfile.TemporaryDirectory() as directory:
            report = inspect(self.make_atlas(directory, "RGBA"), frames=2, cols=2, cell=64)
            self.assertTrue(report["technicalPreflightPassed"], report["warnings"])

    def test_rgb_without_alpha_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            report = inspect(self.make_atlas(directory, "RGB"), frames=2, cols=2, cell=64)
            self.assertFalse(report["technicalPreflightPassed"])
            self.assertTrue(any("no alpha channel" in w for w in report["warnings"]))

    def test_palette_without_transparency_fails(self):
        with tempfile.TemporaryDirectory() as directory:
            report = inspect(self.make_atlas(directory, "P"), frames=2, cols=2, cell=64)
            self.assertFalse(report["technicalPreflightPassed"])
            self.assertTrue(any("no alpha channel" in w for w in report["warnings"]))


if __name__ == "__main__":
    unittest.main()
