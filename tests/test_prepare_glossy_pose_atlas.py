"""Test generated 4x3 pose-board normalization (technical QA, not art approval)."""
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from prepare_glossy_pose_atlas import prepare


class PrepareGlossyPoseAtlasTests(unittest.TestCase):
    def make_source(self, folder, *, mode="RGBA", wrong_geometry=False):
        size = (160, 128 if wrong_geometry else 120)
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        painter = ImageDraw.Draw(img)
        for i in range(12):
            x, y = (i % 4) * 40, (i // 4) * 40
            painter.ellipse((x + 9, y + 5, x + 29, y + 35),
                            fill=(160, 100 + i, 240, 255))
        if mode == "RGB":
            img = img.convert("RGB")
        path = Path(folder) / "board.png"
        img.save(path)
        return path

    def test_rgba_sheet_normalized_to_true_alpha_webp(self):
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder) / "out.webp"
            report = prepare(self.make_source(folder), output)
            self.assertEqual(report["frames"], 12)
            self.assertEqual(len(report["sha256"]), 64)
            with Image.open(output) as img:
                self.assertEqual(img.size, (1024, 768))
                self.assertIn("A", img.getbands())
                self.assertEqual(img.getpixel((0, 0))[3], 0)
                for index in range(12):
                    region = img.crop(
                        ((index % 4) * 256, (index // 4) * 256,
                         ((index % 4) + 1) * 256, ((index // 4) + 1) * 256)
                    )
                    self.assertIsNotNone(region.getchannel("A").getbbox())

    def test_opaque_image_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError, "real alpha"):
                prepare(self.make_source(folder, mode="RGB"),
                        Path(folder) / "out.webp")

    def test_non_square_cells_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError, "square input cells"):
                prepare(self.make_source(folder, wrong_geometry=True),
                        Path(folder) / "out.webp")

    def test_invalid_threshold_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError, "threshold"):
                prepare(self.make_source(folder), Path(folder) / "out.webp",
                        threshold=0)


if __name__ == "__main__":
    unittest.main()
