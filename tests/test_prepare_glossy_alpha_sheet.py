"""Synthetic tests: true alpha, no accidental matte, no stray alpha speckles."""
from __future__ import annotations
import importlib.util
import tempfile
import unittest
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "prepare_glossy_alpha_sheet", ROOT / "tools" / "prepare_glossy_alpha_sheet.py"
)
mod = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(mod)


class AlphaSheetTests(unittest.TestCase):
    def test_remove_speckles_preserve_true_alpha(self):
        with tempfile.TemporaryDirectory() as td:
            source, target = Path(td) / "raw.png", Path(td) / "clean.webp"
            art = Image.new("RGBA", (240, 120), (0, 0, 0, 0))
            draw = ImageDraw.Draw(art)
            for i in range(2):
                draw.ellipse((i * 120 + 30, 20, i * 120 + 90, 100),
                             fill=(242, 153, 72, 255))
                draw.ellipse((i * 120 + 4, 4, i * 120 + 8, 8),
                             fill=(255, 0, 0, 255))
            art.save(source)
            report = mod.prepare(source, target, frames=2, columns=2, size=128)
            self.assertEqual(report["alpha"], "true")
            with Image.open(target) as output:
                self.assertEqual(output.size, (256, 128))
                self.assertEqual(output.getpixel((0, 0))[3], 0)
                self.assertEqual(output.getpixel((16, 16))[3], 0)
                self.assertGreater(output.getpixel((64, 64))[3], 240)

    def test_opaque_rgb_input_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            source, target = Path(td) / "rgb.png", Path(td) / "out.webp"
            Image.new("RGB", (240, 120), "white").save(source)
            with self.assertRaisesRegex(ValueError, "alpha channel"):
                mod.prepare(source, target, frames=2, columns=2, size=128)

    def test_invalid_input_grid_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            source, target = Path(td) / "wrong.png", Path(td) / "out.webp"
            Image.new("RGBA", (241, 120)).save(source)
            with self.assertRaisesRegex(ValueError, "divide evenly"):
                mod.prepare(source, target, frames=2, columns=2, size=128)


if __name__ == "__main__":
    unittest.main()
