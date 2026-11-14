"""Safety regressions for external Robot Glossy V2 art packs.

Synthetic source art only. This suite never imports or registers an asset.
"""
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from import_robot_v2_pack import validate_pack
from test_import_robot_v2_pack import fixture, write_zip


class RobotPackGuardrailsTest(unittest.TestCase):
    def assert_rejected(self, change, expected):
        members = fixture()
        change(members)
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'robot.zip'
            write_zip(path, members)
            with self.assertRaisesRegex(ValueError, expected):
                validate_pack(path)

    def test_rejects_extra_untracked_payload(self):
        self.assert_rejected(
            lambda members: members.update({'idle/malware.py': b'print(1)'}),
            'Unexpected ZIP member',
        )

    def test_rejects_unlisted_state_assets(self):
        self.assert_rejected(
            lambda members: members.update({'sad/metadata.json': b'{}'}),
            'Unlisted Robot state assets',
        )

    def test_rejects_missing_loop_flag(self):
        def change(members):
            metadata = json.loads(members['idle/metadata.json'])
            del metadata['loop']
            members['idle/metadata.json'] = json.dumps(metadata).encode()
        self.assert_rejected(change, 'invalid loop flag')

    def test_rejects_string_loop_flag(self):
        def change(members):
            metadata = json.loads(members['idle/metadata.json'])
            metadata['loop'] = 'false'
            members['idle/metadata.json'] = json.dumps(metadata).encode()
        self.assert_rejected(change, 'invalid loop flag')

    def test_rejects_boolean_frame_count(self):
        def change(members):
            metadata = json.loads(members['idle/metadata.json'])
            metadata['frames'] = True
            members['idle/metadata.json'] = json.dumps(metadata).encode()
        self.assert_rejected(change, 'invalid frame count')

    def test_rejects_bogus_report_count(self):
        def change(members):
            report = json.loads(members['BUILD_REPORT.json'])
            report['count'] = 10
            members['BUILD_REPORT.json'] = json.dumps(report).encode()
        self.assert_rejected(change, 'BUILD_REPORT count')

    def test_rejects_compressed_bomb_in_review_file(self):
        members = fixture()
        members['idle/candidate_qa.json'] = b' ' * 500_000
        with tempfile.TemporaryDirectory() as d:
            path = Path(d) / 'compressed.zip'
            with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED) as z:
                for name, payload in members.items():
                    z.writestr(name, payload)
            with self.assertRaisesRegex(ValueError, 'Excessive ZIP compression ratio'):
                validate_pack(path)


if __name__ == '__main__':
    unittest.main()
