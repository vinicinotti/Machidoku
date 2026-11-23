"""SVG safety/portability contract; rendering is checked separately in Godot."""
from pathlib import Path
import re
import struct
import json
import hashlib
import unittest
import xml.etree.ElementTree as ET

ASSETS = Path(__file__).resolve().parents[1] / 'game' / 'assets'
CANONICAL = {
    'branding': ['machidoku_logo', 'machidoku_symbol'],
    'specialists': ['specialist_default'],
    'vehicles': ['hatch_compact', 'sedan', 'sport_coupe'],
    'sectors': ['stamping', 'welding', 'painting', 'electrical', 'assembly', 'inspection', 'logistics', 'testing', 'powertrain'],
    'rules': ['one_per_sector', 'one_per_row_column', 'no_touching'],
    'ui': ['icon_' + n for n in ['back', 'restart', 'life', 'error', 'check', 'lock', 'factory', 'car', 'dropdown']],
    'decoration': ['factory_background_left', 'factory_background_right', 'industrial_shapes'],
}


class VisualAssetsTest(unittest.TestCase):
    def test_complete_canonical_family(self):
        expected = [ASSETS / group / (name + '.svg') for group, names in CANONICAL.items() for name in names]
        self.assertEqual(len(expected), 30)
        for path in expected:
            with self.subTest(asset=path.name):
                self.assertTrue(path.is_file(), str(path))

    def test_svg_portable_primitives_and_local_references(self):
        allowed = {'svg', 'g', 'defs', 'path', 'rect', 'circle', 'ellipse', 'polygon', 'polyline', 'line', 'linearGradient', 'radialGradient', 'stop'}
        for path in sorted(ASSETS.rglob('*.svg')):
            with self.subTest(asset=path.relative_to(ASSETS)):
                source = path.read_text(encoding='utf-8')
                self.assertNotRegex(source.lower(), r'base64|<!doctype|<!entity|data:|https?://(?!www.w3.org/2000/svg)')
                root = ET.fromstring(source)
                view = [float(n) for n in root.attrib['viewBox'].split()]
                self.assertEqual(len(view), 4)
                self.assertGreater(min(view[2:]), 0)
                ids, refs = [], []
                for node in root.iter():
                    self.assertIn(node.tag.split('}')[-1], allowed)
                    self.assertFalse((node.text or '').strip(), 'No text content in SVG')
                    for key, value in node.attrib.items():
                        self.assertNotIn(key.split('}')[-1], ['href', 'style', 'filter', 'mask', 'clip-path'])
                        self.assertFalse(key.lower().startswith('on'))
                        self.assertNotIn('font', key)
                        if key == 'id':
                            ids.append(value)
                        refs.extend(re.findall(r'url\(#([\w-]+)\)', value))
                        if 'url(' in value:
                            self.assertRegex(value, r'^url\(#[\w-]+\)$')
                self.assertEqual(len(ids), len(set(ids)))
                self.assertTrue(set(refs).issubset(ids))

    def test_icon_and_character_coordinate_systems(self):
        for group in ['sectors', 'rules', 'ui']:
            for name in CANONICAL[group]:
                root = ET.parse(ASSETS / group / (name + '.svg')).getroot()
                self.assertEqual(root.attrib['viewBox'], '0 0 64 64')
        for name in CANONICAL['vehicles']:
            self.assertEqual(ET.parse(ASSETS / 'vehicles' / (name + '.svg')).getroot().attrib['viewBox'], '0 0 512 256')
        self.assertEqual(ET.parse(ASSETS / 'specialists/specialist_default.svg').getroot().attrib['viewBox'], '0 0 256 256')

    def test_generated_raster_delivery_and_provenance(self):
        root = ASSETS.parents[1]
        manifest = json.loads((root / 'docs/asset_generation.json').read_text(encoding='utf-8'))
        self.assertEqual(len(manifest['assets']), 8)
        self.assertEqual(manifest['tool'], 'Built-in image_gen')
        hashes = set()
        for item in manifest['assets']:
            with self.subTest(asset=item['file']):
                content = (root / item['file']).read_bytes()
                self.assertEqual(content[:8], b'\x89PNG\r\n\x1a\n')
                width, height, depth, color = struct.unpack('>IIBB', content[16:26])
                self.assertEqual([width, height], item['dimensions'])
                self.assertEqual(hashlib.sha256(content).hexdigest(), item['sha256'])
                self.assertGreaterEqual(width, 1024)
                self.assertGreaterEqual(height, 640)
                self.assertLessEqual(max(width, height), 2048)
                self.assertEqual(color, 6 if item['transparent_background'] else 2)
                self.assertIn(depth, [8, 16])
                self.assertGreater(len(item['prompt']), 300)
                hashes.add(hashlib.sha256(content).hexdigest())
        self.assertEqual(len(hashes), 8, 'Distinct requested illustrations must be delivered')


if __name__ == '__main__':
    unittest.main()
