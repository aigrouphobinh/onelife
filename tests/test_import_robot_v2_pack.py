"""Robot candidate pack import regression tests (synthetic art only)."""
import hashlib
import io
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from import_robot_v2_pack import validate_pack


def fixture():
    atlas = Image.new('RGBA', (1024, 512), (0, 0, 0, 0))
    for i in range(8):
        face = Image.new('RGBA', (256, 256))
        draw = ImageDraw.Draw(face)
        x = 20 + i * 12
        draw.ellipse((x, 40, x + 75, 185), fill=(40, 180, 240, 255))
        draw.ellipse((60, 85, 95, 120), fill=(255, 255, 255, 255))
        atlas.alpha_composite(face, (i % 4 * 256, i // 4 * 256))
    encoded = io.BytesIO()
    atlas.save(encoded, 'WEBP', lossless=True)
    source = encoded.getvalue()
    sha = hashlib.sha256(source).hexdigest()
    metadata = dict(
        characterId='robot', state='idle', sourceSha256=sha,
        columns=4, frameWidth=256, frameHeight=256,
        frames=8, frameDurationMs=140, loop=True,
        artReview='pending', deviceReview='pending', productionReady=False,
    )
    manifest = {'qa': [{'state': 'idle', 'frames': 8, 'sourceSha256': sha}]}
    return {
        'BUILD_REPORT.json': json.dumps(manifest).encode(),
        'idle/metadata.json': json.dumps(metadata).encode(),
        'idle/sheet_illustrated.webp': source,
    }


def write_zip(path, members):
    with zipfile.ZipFile(path, 'w') as z:
        for name, payload in members.items():
            z.writestr(name, payload)


class TestRobotPack(unittest.TestCase):
    def reject(self, modify, pattern):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'pack.zip'
            members = fixture()
            modify(members)
            write_zip(path, members)
            with self.assertRaisesRegex(ValueError, pattern):
                validate_pack(path)

    def test_accepts_real_alpha_valid_sha(self):
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'pack.zip'
            write_zip(path, fixture())
            specs = validate_pack(path)
            self.assertEqual([item['state'] for item in specs], ['idle'])
            self.assertEqual(specs[0]['frames'], 8)

    def test_rejects_sha_mismatch(self):
        def modify(members):
            report = json.loads(members['BUILD_REPORT.json'])
            report['qa'][0]['sourceSha256'] = '0' * 64
            members['BUILD_REPORT.json'] = json.dumps(report).encode()
        self.reject(modify, 'checksum mismatch')

    def test_rejects_missing_source(self):
        self.reject(
            lambda members: members.pop('idle/sheet_illustrated.webp'),
            'Missing source',
        )

    def test_rejects_zip_traversal(self):
        self.reject(
            lambda members: members.update({'../unsafe.bin': b'bad'}),
            'Unsafe ZIP member',
        )

    def test_rejects_false_approval(self):
        def modify(members):
            metadata = json.loads(members['idle/metadata.json'])
            metadata['productionReady'] = True
            members['idle/metadata.json'] = json.dumps(metadata).encode()
        self.reject(modify, 'invalid productionReady')

    def test_rejects_duplicate_state(self):
        def modify(members):
            report = json.loads(members['BUILD_REPORT.json'])
            report['qa'].append(report['qa'][0])
            members['BUILD_REPORT.json'] = json.dumps(report).encode()
        self.reject(modify, 'duplicate Robot state')


if __name__ == '__main__':
    unittest.main()
