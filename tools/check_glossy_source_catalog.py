#!/usr/bin/env python3
"""Fail-closed validation of the Glossy V2 illustration source catalog.

This checks catalog integrity before the renderer reads any source file. It
does not generate art, award art approval, or count candidate clips.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets" / "characters-v2"
CATALOG = ASSET_ROOT / "animation_sources.json"
VALID_CHARACTERS = {"cat", "dog", "robot", "sprout"}
VALID_STATES = {
    "idle", "remind", "alarm", "happy", "overloaded", "resting",
    "sleepy", "recovering", "focus", "study", "done", "thinking",
    "sad", "balanced", "strained",
}
HEX_SHA = re.compile(r"^[0-9a-f]{64}$")


def validate(catalog: dict, root: Path, verify_files: bool = True) -> int:
    if not isinstance(catalog, dict) or not isinstance(catalog.get("animationSources"), list):
        raise ValueError("animationSources must be a list")
    seen = set()
    for index, item in enumerate(catalog["animationSources"]):
        if not isinstance(item, dict):
            raise ValueError(f"entry {index}: expected object")
        char, state = item.get("characterId"), item.get("state")
        if char not in VALID_CHARACTERS or state not in VALID_STATES:
            raise ValueError(f"entry {index}: unknown character/state")
        key = (char, state)
        if key in seen:
            raise ValueError(f"duplicate animation source: {char}/{state}")
        seen.add(key)
        if item.get("sourceFile") != "sheet_illustrated.webp":
            raise ValueError(f"{char}/{state}: unexpected source filename")
        if not isinstance(item.get("version"), str) or not item["version"].strip():
            raise ValueError(f"{char}/{state}: missing version")
        if item.get("generationClass") != "independently-illustrated-pose-sheet":
            raise ValueError(f"{char}/{state}: source provenance must be independently illustrated")
        sha = item.get("sourceSha256")
        if not isinstance(sha, str) or HEX_SHA.fullmatch(sha) is None:
            raise ValueError(f"{char}/{state}: invalid source SHA-256")
        for field, value in (
            ("frames", item.get("frames")),
            ("columns", item.get("columns")),
            ("frameWidth", item.get("frameWidth")),
            ("frameHeight", item.get("frameHeight")),
            ("frameDurationMs", item.get("frameDurationMs")),
        ):
            if type(value) is not int:
                raise ValueError(f"{char}/{state}: {field} must be an integer")
        if not 8 <= item["frames"] <= 24 or item["columns"] != 4:
            raise ValueError(f"{char}/{state}: unsupported frame layout")
        if item["frameWidth"] != 256 or item["frameHeight"] != 256:
            raise ValueError(f"{char}/{state}: unsupported cell size")
        if not 60 <= item["frameDurationMs"] <= 1000:
            raise ValueError(f"{char}/{state}: unsupported frame duration")
        if type(item.get("loop")) is not bool:
            raise ValueError(f"{char}/{state}: loop must be a boolean")
        if verify_files:
            source = root / char / state / "sheet_illustrated.webp"
            if not source.is_file():
                raise ValueError(f"{char}/{state}: source file missing")
            if hashlib.sha256(source.read_bytes()).hexdigest() != sha:
                raise ValueError(f"{char}/{state}: source checksum mismatch")
    return len(seen)


class ContractTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        data = b"example source bytes"
        source = self.root / "cat" / "balanced" / "sheet_illustrated.webp"
        source.parent.mkdir(parents=True)
        source.write_bytes(data)
        self.item = {
            "characterId": "cat", "state": "balanced", "version": "test",
            "sourceFile": "sheet_illustrated.webp",
            "sourceSha256": hashlib.sha256(data).hexdigest(),
            "frames": 12, "columns": 4, "frameWidth": 256,
            "frameHeight": 256, "frameDurationMs": 180, "loop": True,
            "generationClass": "independently-illustrated-pose-sheet",
        }

    def check(self, entries):
        return validate({"animationSources": entries}, self.root)

    def test_valid_source(self):
        self.assertEqual(self.check([self.item]), 1)

    def test_duplicate_source_rejected(self):
        with self.assertRaisesRegex(ValueError, "duplicate"):
            self.check([self.item, dict(self.item)])

    def test_missing_source_rejected(self):
        (self.root / "cat" / "balanced" / "sheet_illustrated.webp").unlink()
        with self.assertRaisesRegex(ValueError, "missing"):
            self.check([self.item])

    def test_changed_source_rejected(self):
        (self.root / "cat" / "balanced" / "sheet_illustrated.webp").write_bytes(b"tampered")
        with self.assertRaisesRegex(ValueError, "checksum mismatch"):
            self.check([self.item])

    def test_non_boolean_loop_rejected(self):
        with self.assertRaisesRegex(ValueError, "loop"):
            self.check([{**self.item, "loop": 1}])

    def test_non_integer_frame_count_rejected(self):
        with self.assertRaisesRegex(ValueError, "frames"):
            self.check([{**self.item, "frames": 12.0}])

    def test_unsafe_filename_rejected(self):
        with self.assertRaisesRegex(ValueError, "filename"):
            self.check([{**self.item, "sourceFile": "../../secret.webp"}])

    def test_derived_source_rejected(self):
        with self.assertRaisesRegex(ValueError, "provenance"):
            self.check([{**self.item, "generationClass": "derived-pose-composite"}])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        result = unittest.TextTestRunner(verbosity=2).run(
            unittest.defaultTestLoader.loadTestsFromTestCase(ContractTests)
        )
        raise SystemExit(0 if result.wasSuccessful() else 1)
    count = validate(json.loads(CATALOG.read_text(encoding="utf-8")), ASSET_ROOT)
    print(f"PASS: {count} distinct illustrated source catalog entries, hashes verified")
    

if __name__ == "__main__":
    main()
