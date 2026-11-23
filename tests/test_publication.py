"""Security invariants for the public export. Synthetic identifiers only."""
import importlib.util
import json
import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / 'tools/publish/privacy.py'
SPEC = importlib.util.spec_from_file_location('publication_privacy', MODULE_PATH)
privacy = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(privacy)


class PublicationSecurityTest(unittest.TestCase):
    def test_archives_and_credentials_never_pass_the_file_filter(self):
        for path in ['docs/docs.zip', 'game/export_credentials.cfg', '.env', 'docs/account.key', 'docs/account.pem', 'docs/data.private.json', 'build/index.html']:
            with self.subTest(path=path):
                self.assertFalse(privacy.allowed(path))

    def test_game_and_license_files_remain_included(self):
        for path in ['game/scripts/game.gd', 'game/levels/01_hatch.json', 'game/assets/fonts/OFL.txt', '.github/workflows/privacy.yml', 'Publicar.ps1']:
            self.assertTrue(privacy.allowed(path))

    def test_parent_traversal_is_rejected(self):
        self.assertFalse(privacy.allowed('docs/../../account.txt'))

    def test_local_workspace_path_is_sanitized(self):
        path = 'C:' + chr(92) + chr(92).join(['Users', 'sample-user', 'Documents', 'Machidoku'])
        self.assertEqual(privacy.sanitize_text(path), '.')
        self.assertTrue(privacy.audit_text('sample', path))

    def test_json_escaped_home_is_detected_after_decoding(self):
        value = 'C:' + chr(92) + chr(92).join(['Users', 'sample-user', 'private'])
        parsed = json.loads(json.dumps({'source': value}))
        clean = privacy.sanitize_json(parsed)
        self.assertNotIn('sample-user', clean['source'])

    def test_unix_home_is_sanitized(self):
        value = '/' + '/'.join(['home', 'sample-user', 'private'])
        self.assertNotIn('sample-user', privacy.sanitize_text(value))

    def test_credential_findings_never_contain_the_matched_value(self):
        token = 'ghp_' + 'a' * 36
        result = privacy.audit_text('fixture', token)
        self.assertTrue(result)
        self.assertNotIn(token, json.dumps(result))

    def test_personal_email_is_blocked(self):
        value = 'sample-user' + '@' + 'example.test'
        self.assertTrue(privacy.audit_text('fixture', value))

    def test_github_noreply_is_allowed(self):
        value = '123+sample' + '@' + 'users.noreply.github.com'
        self.assertEqual(privacy.audit_text('fixture', value), [])

    def test_private_and_public_ip_addresses_are_blocked(self):
        for value in ['192.168.' + '1.50', '203.0.' + '113.7', '2001:db8:' + ':1']:
            self.assertTrue(privacy.audit_text('fixture', value))
        self.assertEqual(privacy.audit_text('fixture', '127.0.' + '0.1'), [])

    def test_png_metadata_removal_preserves_all_pixel_chunks(self):
        def chunk(kind, payload):
            return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind + payload) & 0xffffffff)
        ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 6, 0, 0, 0))
        pixels = chunk(b'IDAT', zlib.compress(b'\x00\xff\x80\x20\xff'))
        metadata = chunk(b'tEXt', b'Author\x00synthetic author')
        ending = chunk(b'IEND', b'')
        source = privacy.PNG_SIGNATURE + ihdr + metadata + pixels + ending
        clean, removed = privacy.strip_png_metadata(source)
        self.assertEqual(removed, ['tEXt'])
        self.assertEqual(clean, privacy.PNG_SIGNATURE + ihdr + pixels + ending)

    def test_network_hardware_addresses_do_not_confuse_svg_coordinates(self):
        pairs = ['aa', 'bb', 'cc', 'dd', 'ee', 'ff']
        self.assertTrue(privacy.audit_text('fixture', ':'.join(pairs)))
        self.assertTrue(privacy.audit_text('fixture', 'mac=' + '-'.join(pairs)))
        self.assertEqual(privacy.audit_text('game/icon.svg', 'M98 0-20-46-46-89-64 14-123'), [])

    def test_private_material_blocks_an_export_audit(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'docs').mkdir()
            (root / 'docs/personal.txt').write_text('sample-user' + '@' + 'example.test', encoding='utf-8')
            self.assertFalse(privacy.audit_tree(root)['passed'])


if __name__ == '__main__':
    unittest.main()
