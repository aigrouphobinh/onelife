#!/usr/bin/env python3
"""Regression tests for visibility-aware glossy sprite motion QA."""
import importlib.util
import unittest
from pathlib import Path

from PIL import Image

MODULE = Path(__file__).with_name("render_glossy_character_animation.py")
spec = importlib.util.spec_from_file_location("glossy_renderer", MODULE)
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)


class VisibleMotionTests(unittest.TestCase):
    def test_hidden_rgb_does_not_count_as_motion(self):
        a = Image.new("RGBA", (32, 32), (255, 0, 0, 0))
        b = Image.new("RGBA", (32, 32), (0, 255, 255, 0))
        self.assertEqual(renderer.visible_motion_rms(a, b), 0)

    def test_visible_color_change_counts(self):
        a = Image.new("RGBA", (32, 32), (0, 0, 0, 255))
        b = Image.new("RGBA", (32, 32), (255, 255, 255, 255))
        self.assertGreater(renderer.visible_motion_rms(a, b), 2)

    def test_visible_alpha_change_counts(self):
        a = Image.new("RGBA", (32, 32), (255, 0, 0, 0))
        b = Image.new("RGBA", (32, 32), (255, 0, 0, 255))
        self.assertGreater(renderer.visible_motion_rms(a, b), 2)

    def test_identical_visible_frames_with_different_hidden_rgb(self):
        a = Image.new("RGBA", (32, 32), (255, 0, 0, 0))
        b = Image.new("RGBA", (32, 32), (0, 255, 0, 0))
        for frame in (a, b):
            for x in range(8, 24):
                for y in range(8, 24):
                    frame.putpixel((x, y), (50, 20, 100, 255))
        self.assertEqual(renderer.visible_motion_rms(a, b), 0)


if __name__ == "__main__":
    unittest.main()
