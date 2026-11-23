"""Regression checks for the level contract and the independent Python solver."""
import copy
import json
from pathlib import Path
import unittest

from tools.solver.validate import LEVELS, check_solution, check_structure, solve, validate_level


class LevelTests(unittest.TestCase):
    def setUp(self):
        self.levels = [json.loads(p.read_text(encoding="utf-8")) for p in sorted(LEVELS.glob("*.json"))]
        self.level = copy.deepcopy(self.levels[0])

    def test_all_sixty_unique(self):
        self.assertEqual(len(self.levels), 60)
        for level in self.levels:
            with self.subTest(level=level['id']):
                self.assertTrue(validate_level(level)['valid'])

    def test_catalog_progression(self):
        self.assertEqual([level['id'] for level in self.levels], list(range(1,61)))
        catalog = json.loads((LEVELS.parent / 'data/campaign.json').read_text(encoding='utf-8'))
        for product in catalog['worlds'][0]['products']:
            batch = [level for level in self.levels if level['product'] == product['id']]
            self.assertEqual(len(batch), 15)
            self.assertEqual([level['id'] for level in batch], list(range(product['start_id'], product['start_id'] + 15)))
            self.assertTrue(all(level['vehicle_name'] == product['display_name'] for level in batch))
            self.assertEqual({level['size'] for level in batch}, {5,6,7,8,9})
            self.assertEqual(sum(level['difficulty'] == 'very_hard' for level in batch), 2)

    def test_enumeration_ignores_stored_answer(self):
        expected = solve(self.level)
        self.level['solution'] = []
        self.assertEqual(expected, solve(self.level))

    def test_duplicate_specialist_rejected(self):
        self.level['solution'][1] = self.level['solution'][0]
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            validate_level(self.level)

    def test_diagonal_contact_rejected(self):
        self.level['regions'] = [[r]*5 for r in range(5)]
        with self.assertRaisesRegex(ValueError, 'touch'):
            check_solution(self.level, [(r,r) for r in range(5)])

    def test_disconnected_sector_rejected(self):
        self.level['regions'][4][4] = 0
        with self.assertRaisesRegex(ValueError, 'disconnected'):
            check_structure(self.level)

    def test_missing_sector_rejected(self):
        self.level['regions'] = [[0]*5 for _ in range(5)]
        with self.assertRaisesRegex(ValueError, 'Missing region'):
            check_structure(self.level)

    def test_invalid_grid_dimensions_rejected(self):
        self.level['regions'][0].pop()
        with self.assertRaisesRegex(ValueError, 'shape'):
            validate_level(self.level)

    def test_fixed_specialist_must_be_in_solution(self):
        self.level['preplaced_specialists'] = [[0,1]]
        with self.assertRaisesRegex(ValueError, 'Fixed specialist'):
            validate_level(self.level)

    def test_ambiguous_level_rejected(self):
        self.level['regions'] = [[r]*5 for r in range(5)]
        self.level['preplaced_specialists'] = []
        self.assertEqual(len(solve(self.level)), 2)
        with self.assertRaisesRegex(ValueError, 'unique'):
            validate_level(self.level)

    def test_impossible_fixed_positions(self):
        self.level['preplaced_specialists'] = [[0,0],[1,1]]
        self.assertEqual(solve(self.level), [])

    def test_out_of_bounds_rejected(self):
        self.level['solution'][0] = [-1,0]
        with self.assertRaisesRegex(ValueError, 'bounds'):
            validate_level(self.level)

    def test_boolean_is_not_a_region_id(self):
        self.level['regions'][0][0] = True
        with self.assertRaisesRegex(ValueError, 'Region ids'):
            validate_level(self.level)


if __name__ == '__main__':
    unittest.main()
