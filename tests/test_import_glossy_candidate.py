"""Regression tests for lossless, SHA-locked Glossy sprite imports."""
from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from import_glossy_candidate import candidate_spec, import_candidate  # noqa: E402


def fake_source(path: Path, *, opaque: bool = False):
    atlas = Image.new('RGBA', (1024, 256),
                      (255, 255, 255, 255) if opaque else (0, 0, 0, 0))
    draw = ImageDraw.Draw(atlas)
    for i in range(4):
        x = i * 256
        draw.ellipse((x + 30 + i * 8, 30, x + 190 + i * 8, 204),
                     fill=(235, 139, 63, 255))
    atlas.save(path, format='WEBP', lossless=True)


class ImportCandidateTest(unittest.TestCase):
    def test_rejects_invalid_path_and_hash_spec(self):
        with self.assertRaisesRegex(ValueError, 'Invalid sprite id'):
            candidate_spec(character='dog', state='../escape',
                           version='test', sha256='0' * 64, frames=4,
                           duration_ms=145, loop=False)
        with self.assertRaisesRegex(ValueError, '64 lowercase'):
            candidate_spec(character='dog', state='thinking',
                           version='test', sha256='abc', frames=4,
                           duration_ms=145, loop=False)

    def test_import_valid_source_and_idempotent_reimport(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source = root / 'candidate.webp'
            fake_source(source)
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            spec = candidate_spec(character='dog', state='thinking',
                                  version='test-candidate', sha256=digest,
                                  frames=4, duration_ms=145, loop=False)
            dest_root = root / 'assets'
            dest_root.mkdir()
            catalog = root / 'catalog.json'
            catalog.write_text(json.dumps({'version': '1', 'animationSources': []}))
            first = import_candidate(source, spec, v2_root=dest_root,
                                     catalog_path=catalog)
            second = import_candidate(source, spec, v2_root=dest_root,
                                      catalog_path=catalog)
            self.assertTrue(first['technicalPreflightPassed'])
            self.assertFalse(second['productionReady'])
            target = dest_root / 'dog' / 'thinking' / 'sheet_illustrated.webp'
            self.assertEqual(hashlib.sha256(target.read_bytes()).hexdigest(),
                             digest)
            entries = json.loads(catalog.read_text())['animationSources']
            self.assertEqual(entries, [spec])
            self.assertTrue((target.parent / 'candidate_qa.json').is_file())

    def test_rejects_hash_mismatch_before_writing(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source = root / 'candidate.webp'
            fake_source(source)
            spec = candidate_spec(character='dog', state='thinking',
                                  version='test', sha256='0' * 64, frames=4,
                                  duration_ms=145, loop=False)
            catalog = root / 'catalog.json'
            catalog.write_text('{"animationSources": []}')
            with self.assertRaisesRegex(ValueError, 'SHA-256 mismatch'):
                import_candidate(source, spec, v2_root=root / 'assets',
                                 catalog_path=catalog)
            self.assertFalse((root / 'assets').exists())

    def test_rejects_opaque_matte(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source = root / 'opaque.webp'
            fake_source(source, opaque=True)
            spec = candidate_spec(character='dog', state='thinking',
                                  version='test', sha256=hashlib.sha256(
                                      source.read_bytes()).hexdigest(),
                                  frames=4, duration_ms=145, loop=False)
            catalog = root / 'catalog.json'
            catalog.write_text('{"animationSources": []}')
            with self.assertRaisesRegex(ValueError, 'preflight failed'):
                import_candidate(source, spec, v2_root=root / 'assets',
                                 catalog_path=catalog)

    def test_rejects_conflicting_catalog(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            source = root / 'candidate.webp'
            fake_source(source)
            spec = candidate_spec(character='dog', state='thinking',
                                  version='test', sha256=hashlib.sha256(
                                      source.read_bytes()).hexdigest(),
                                  frames=4, duration_ms=145, loop=False)
            catalog = root / 'catalog.json'
            catalog.write_text(json.dumps({'animationSources': [{
                **spec, 'version': 'different-already-registered'
            }]}))
            with self.assertRaisesRegex(ValueError, 'Conflicting'):
                import_candidate(source, spec, v2_root=root / 'assets',
                                 catalog_path=catalog)


if __name__ == '__main__':
    unittest.main()
