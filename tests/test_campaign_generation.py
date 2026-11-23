import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from tools.generator.generate import ROOT
from tools.solver.validate import validate_level


class CampaignGenerationTests(unittest.TestCase):
    def test_seasons_cover_published_ids_independently_of_products(self):
        seasons = json.loads((ROOT / 'game/data/seasons.json').read_text(encoding='utf-8'))['seasons']
        ids = [level_id for season in seasons for level_id in season['level_ids']]
        published = sorted(json.loads(path.read_text(encoding='utf-8'))['id'] for path in (ROOT / 'game/levels').glob('*.json'))
        self.assertEqual(sorted(ids), published)
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len({season['id'] for season in seasons}), len(seasons))
        for season in seasons:
            self.assertTrue(season['level_ids'])
            self.assertTrue(season['display_name'])
            self.assertNotIn('product', season)

    def run_generator(self, *args):
        return subprocess.run([sys.executable, str(ROOT / 'tools/generator/generate.py'), *map(str, args)], capture_output=True, text=True)

    def test_product_batch_reproducible_and_protected_from_overwrite(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            outputs = []
            for name in ('a', 'b'):
                target = root / name
                result = self.run_generator('--product', 'sedan', '--count', 2, '--start-id', 16, '--seed', 8123, '--output', target, '--report', root / (name + '.json'))
                self.assertEqual(result.returncode, 0, result.stderr)
                batch = [json.loads(p.read_text(encoding='utf-8')) for p in sorted(target.glob('*.json'))]
                self.assertEqual([level['id'] for level in batch], [16, 17])
                for level in batch:
                    self.assertEqual(level['world'], 'automotive')
                    self.assertEqual(level['product'], 'sedan')
                    self.assertEqual(level['product_display_name'], 'Sedan')
                    self.assertTrue(validate_level(level)['valid'])
                outputs.append(batch)
            self.assertEqual(outputs[0], outputs[1])
            before = {p.name: p.read_bytes() for p in (root / 'a').glob('*.json')}
            result = self.run_generator('--product', 'sedan', '--count', 2, '--start-id', 16, '--output', root / 'a')
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(before, {p.name: p.read_bytes() for p in (root / 'a').glob('*.json')})

    def test_catalogue_collision_and_unknown_product_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = (ROOT / 'game/levels/01_hatch.json').read_bytes()
            (root / '01_hatch.json').write_bytes(original)
            result = self.run_generator('--product', 'sedan', '--count', 1, '--start-id', 1, '--output', root)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Duplicate catalogue id', result.stderr)
            self.assertEqual((root / '01_hatch.json').read_bytes(), original)
            result = self.run_generator('--product', 'unknown', '--output', root / 'new')
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((root / 'new').exists())
