import copy
import json
import random
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from tools.generator.generate import ROOT, candidate, extended_candidate
from tools.difficulty.analyze import analyze
from tools.solver.validate import LEVELS, check_structure, check_solution, validate_level


class PipelineTests(unittest.TestCase):
    def test_generated_candidates_cover_grid_and_connect(self):
        for n in range(5,10):
            for seed in range(10):
                level = candidate(random.Random(seed), {'id':1,'size':n,'fixed':2,'difficulty':'normal'})
                self.assertEqual(check_structure(level), n)
                check_solution(level, list(map(tuple,level['solution'])))
                self.assertEqual(len(level['preplaced_specialists']), 2)

    def test_seed_is_reproducible(self):
        profile = {'id':2,'size':7,'fixed':1,'difficulty':'normal'}
        self.assertEqual(candidate(random.Random(77),profile), candidate(random.Random(77),profile))

    def test_all_delivered_traces_solve_without_answer(self):
        for path in sorted(LEVELS.glob('*.json')):
            level = json.loads(path.read_text(encoding='utf-8'))
            expected = sorted(level['solution'])
            blank = copy.deepcopy(level)
            blank['solution'] = []
            result = analyze(blank)
            with self.subTest(id=level['id']):
                self.assertTrue(result['solved_logically'])
                self.assertEqual(result['derived_solution'], expected)
                self.assertEqual(result['score'], level['difficulty_metrics']['score'])
                if level['id'] != 1:
                    self.assertEqual(result['classification'], level['difficulty'])

    def test_geometry_is_not_duplicated(self):
        grids = [json.loads(path.read_text(encoding='utf-8'))['regions'] for path in LEVELS.glob('*.json')]
        self.assertEqual(len({json.dumps(g) for g in grids}),60)

    def test_trace_is_deterministic(self):
        level = json.loads((LEVELS / '01_hatch.json').read_text(encoding='utf-8'))
        self.assertEqual(analyze(level), analyze(level))

    def test_all_published_levels_pass_full_validator(self):
        for path in LEVELS.glob('*.json'):
            self.assertTrue(validate_level(json.loads(path.read_text(encoding='utf-8')))['valid'])

    def test_extended_candidates_keep_solution_and_connected_coverage(self):
        base = json.loads((LEVELS / '14_hatch.json').read_text(encoding='utf-8'))
        original = copy.deepcopy(base)
        for seed in range(5):
            level = extended_candidate(random.Random(seed), base, {'id':15,'size':9,'fixed':1,'difficulty':'very_hard'})
            self.assertEqual(check_structure(level),9)
            check_solution(level,list(map(tuple,level['solution'])))
            self.assertEqual(len(level['preplaced_specialists']),1)
        self.assertEqual(base,original)

    def test_exhausted_search_does_not_publish_invalid_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            profile = folder / 'profiles.json'
            profile.write_text(json.dumps([{'id':99,'size':5,'fixed':5,'difficulty':'very_hard'}]),encoding='utf-8')
            output = folder / 'output'
            result = subprocess.run([sys.executable,str(ROOT/'tools/generator/generate.py'),'--profiles',str(profile),'--output',str(output),'--attempts','2'],capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('no invalid fallback',result.stderr)
            self.assertFalse(output.exists())
