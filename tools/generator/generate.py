"""Offline connected-region generator. Only validated, uniquely solvable JSONs ship."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
import random
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.solver.validate import solve, validate_level
from tools.difficulty.analyze import analyze

CAMPAIGN = ROOT / 'game/data/campaign.json'


def product_metadata(world: str, product: str) -> dict:
    for entry in json.loads(CAMPAIGN.read_text(encoding='utf-8'))['worlds']:
        if entry['id'] == world:
            for item in entry['products']:
                if item['id'] == product:
                    return item
    raise ValueError(f'Unknown world/product: {world}/{product}; register it in {CAMPAIGN}')


def stamp(level: dict, profile: dict) -> None:
    product = profile.get('product', 'hatch')
    world = profile.get('world', 'automotive')
    name = product_metadata(world, product)['display_name']
    level.update(id=profile['id'], name=f"Linha {name} {profile['id']:02d}",
                 world=world, product=product, vehicle_name=name,
                 product_display_name=name, difficulty=profile['difficulty'])


def candidate(rng: random.Random, profile: dict) -> dict:
    n = profile['size']
    # Build a non-touching permutation first; each seed starts one connected sector.
    while True:
        columns = rng.sample(range(n), n)
        if all(abs(columns[i] - columns[i-1]) > 1 for i in range(1, n)):
            break
    solution = [[r, c] for r, c in enumerate(columns)]
    grid = [[-1] * n for _ in range(n)]
    frontier = []

    def neighbors(r, c):
        return [(rr, cc) for rr, cc in ((r-1,c), (r+1,c), (r,c-1), (r,c+1)) if 0 <= rr < n and 0 <= cc < n]

    for sector, (r, c) in enumerate(solution):
        grid[r][c] = sector
    for sector, (r, c) in enumerate(solution):
        frontier.extend((rr, cc, sector) for rr, cc in neighbors(r, c) if grid[rr][cc] == -1)
    while frontier:
        index = rng.randrange(len(frontier))
        r, c, sector = frontier[index]
        frontier[index] = frontier[-1]
        frontier.pop()
        if grid[r][c] != -1:
            continue
        grid[r][c] = sector
        frontier.extend((rr, cc, sector) for rr, cc in neighbors(r,c) if grid[rr][cc] == -1)
    fixed = sorted(rng.sample(solution, profile['fixed']))
    return {'id': profile['id'], 'name': f"Linha Hatch Compact {profile['id']:02d}",
            'world': 'automotive', 'product': 'hatch', 'vehicle_name': 'Hatch Compact',
            'difficulty': profile['difficulty'], 'size': n, 'regions': grid,
            'solution': solution, 'preplaced_specialists': fixed}


def extended_candidate(rng: random.Random, base: dict, profile: dict) -> dict:
    """Mutate connected boundaries of a proven puzzle, optionally growing it.

    Useful for larger boards with a fixed specialist without discarding logical
    complexity. All mutations and the final result are independently validated.
    """
    from tools.solver.validate import check_structure
    old_n = base['size']
    n = profile['size']
    level = copy.deepcopy(base)
    level.update(id=profile['id'],size=n,difficulty=profile['difficulty'])
    if n == old_n and profile['fixed'] == len(base['preplaced_specialists']):
        pass # Same-size boundary mutation is useful for harder campaign finales.
    elif n == old_n + 1 and profile['fixed'] == 1:
        last_column = dict(base['solution'])[old_n-1]
        options = [c for c in range(n) if abs(last_column + (last_column >= c) - c) > 1]
        col = rng.choice(options)
        level['regions'] = [row[:col] + [row[max(0,col-1)]] + row[col:] for row in base['regions']] + [[old_n]*n]
        level['solution'] = [[r,c+(c>=col)] for r,c in base['solution']] + [[old_n,col]]
        level['preplaced_specialists'] = [[old_n,col]]
    else:
        raise ValueError('Base requires equal size/fixed count, or size=base+1 and fixed=1')
    protected = set(map(tuple, level['solution']))
    changes = 0
    grid = level['regions']
    for _ in range(50):
        r,c = rng.randrange(n),rng.randrange(n)
        if (r,c) in protected:
            continue
        neighbors = [grid[rr][cc] for rr,cc in ((r-1,c),(r+1,c),(r,c-1),(r,c+1))
                     if 0<=rr<n and 0<=cc<n and grid[rr][cc]!=grid[r][c]]
        if not neighbors:
            continue
        old = grid[r][c]
        grid[r][c] = rng.choice(neighbors)
        try:
            check_structure(level)
        except ValueError:
            grid[r][c] = old
            continue
        changes += 1
    level.pop('difficulty_metrics', None)
    level.pop('generation', None)
    level['_mutations'] = changes
    return level


def select(profile: dict, seed: int, attempts: int, seen: set, starter: Path, bases: dict | None = None) -> tuple[dict, dict]:
    rng = random.Random(seed + profile['id'] * 100003 + profile.get('seed_offset', 0))
    for attempt in range(1, attempts + 1):
        if profile.get('starter'):
            level = json.loads(starter.read_text(encoding='utf-8'))
        elif 'base' in profile:
            level = extended_candidate(rng, bases[profile['base']], profile)
            if level['_mutations'] < 8:
                continue
        else:
            level = candidate(rng, profile)
        # Avoid one-cell giveaways, and cap giant regions without requiring equal sizes.
        sizes = [sum(v == sector for row in level['regions'] for v in row) for sector in range(level['size'])]
        if min(sizes) < 2:
            continue
        signature = json.dumps(level['regions'], separators=(',', ':'))
        if signature in seen:
            continue
        # Bounded enumeration usually rejects ambiguous candidates before the
        # more expensive human-proof trace. Neither reads the stored answer.
        if len(solve(level)) != 1:
            continue
        analysis = analyze(level)
        if not analysis['solved_logically']:
            continue
        if not profile.get('starter') and analysis['classification'] != profile['difficulty']:
            continue
        validate_level(level)
        if sorted(level['solution']) != analysis['derived_solution']:
            raise ValueError('Logical trace disagrees with independent solver')
        stamp(level, profile)
        metrics = {key: value for key, value in analysis.items() if key not in ('trace', 'derived_solution')}
        # Starter keeps its introductory label, with its measured category visible.
        level['difficulty_metrics'] = metrics
        level['generation'] = {'version': 2, 'seed': seed, 'attempt': attempt, 'starter': bool(profile.get('starter'))}
        if 'base' in profile:
            level['generation'].update(source_level=profile['base'], boundary_mutations=level.pop('_mutations'))
        seen.add(signature)
        return level, analysis
    raise RuntimeError(f"Profile {profile['id']} exhausted {attempts} attempts; no invalid fallback was saved")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--world', default='automotive')
    parser.add_argument('--product', default='hatch')
    parser.add_argument('--count', type=int)
    parser.add_argument('--start-id', type=int)
    parser.add_argument('--seed', type=int, default=41971)
    parser.add_argument('--profiles', type=Path)
    parser.add_argument('--starter', type=Path, default=ROOT / 'levels/archive/mvp/01_hatch.json')
    parser.add_argument('--output', type=Path, default=ROOT / 'game/levels')
    parser.add_argument('--report', type=Path)
    parser.add_argument('--attempts', type=int, default=100000)
    parser.add_argument('--overwrite', action='store_true')
    parser.add_argument('--resume', action='store_true', help='Reuse validated checkpoints with this seed and identical profile')
    args = parser.parse_args()
    try:
        product = product_metadata(args.world, args.product)
    except ValueError as error:
        parser.error(str(error))
    if args.attempts < 1 or (args.count is not None and args.count < 1) or (args.start_id is not None and args.start_id < 1):
        parser.error('count, start-id and attempts must be positive')
    if args.report is None:
        args.report = ROOT / f'artifacts/generation_{args.world}_{args.product}.json'
    if args.profiles is None:
        args.profiles = Path(__file__).with_name('profiles.json' if args.product == 'hatch' else 'campaign_profiles.json')
    profiles = json.loads(args.profiles.read_text(encoding='utf-8'))
    if not profiles:
        parser.error('Empty difficulty profile')
    # Explicit batch options remap template ids and base dependencies together.
    if args.start_id is not None or args.count is not None or args.product != 'hatch':
        template = profiles
        profiles = []
        start = args.start_id if args.start_id is not None else product['start_id']
        count = args.count if args.count is not None else len(template)
        for index in range(count):
            local = index % len(template)
            profile = copy.deepcopy(template[local])
            profile['id'] = start + index
            if 'base' in profile:
                source = next((i for i, item in enumerate(template) if item['id'] == profile['base']), -1)
                if source < 0 or source >= local:
                    parser.error('Base must precede its dependent template profile')
                profile['base'] = start + index - local + source
            if args.product != 'hatch' or profile['id'] != 1:
                profile.pop('starter', None)
            profiles.append(profile)
    for profile in profiles:
        profile.update(world=args.world, product=args.product)
    ids = [p['id'] for p in profiles]
    if len(set(ids)) != len(ids):
        parser.error('Duplicate profile ids')
    for index, profile in enumerate(profiles):
        if 'base' in profile and profile['base'] not in ids[:index]:
            parser.error('A base profile must appear before the profile that extends it')
    names = [f"{p['id']:02d}_{args.product}.json" for p in profiles]
    for existing in args.output.glob('*.json'):
        if existing.name not in names:
            data = json.loads(existing.read_text(encoding='utf-8'))
            if data.get('id') in ids:
                parser.error(f'Duplicate catalogue id in existing file {existing}; choose another output folder')
    if not args.overwrite and any((args.output / name).exists() for name in names):
        parser.error('Output already exists; choose another folder or explicitly use --overwrite')
    started = time.monotonic()
    results = []
    report = []
    seen = {json.dumps(json.loads(path.read_text(encoding='utf-8'))['regions'], separators=(',', ':'))
            for path in args.output.glob('*.json') if path.name not in names}
    for profile in profiles:
        checkpoint = ROOT / 'artifacts/generator_cache/v2' / args.world / args.product / str(args.seed) / f"{profile['id']:02d}.json"
        cached = json.loads(checkpoint.read_text(encoding='utf-8')) if args.resume and checkpoint.exists() else {}
        context = {}
        if profile.get('starter'):
            context['starter_sha256'] = hashlib.sha256(args.starter.read_bytes()).hexdigest()
        if 'base' in profile:
            base = next(item for item in results if item['id'] == profile['base'])
            context['base_sha256'] = hashlib.sha256(json.dumps(base, sort_keys=True).encode()).hexdigest()
        if cached.get('profile') == profile and cached.get('context', {}) == context:
            level = cached['level']
            stamp(level, profile)
            validate_level(level)
            analysis = analyze(level)
            if not analysis['solved_logically'] or (not profile.get('starter') and analysis['classification'] != profile['difficulty']):
                raise ValueError(f"Checkpoint {profile['id']} does not match current logical criteria; rerun without --resume")
            signature = json.dumps(level['regions'], separators=(',', ':'))
            if signature in seen:
                raise ValueError('Checkpoint duplicates an existing puzzle')
            seen.add(signature)
        else:
            level, analysis = select(profile, args.seed, args.attempts, seen, args.starter, {item['id']: item for item in results})
            checkpoint.parent.mkdir(parents=True, exist_ok=True)
            checkpoint.write_text(json.dumps({'profile':profile,'context':context,'level':level},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        results.append(level)
        report.append({'id':level['id'], 'size':level['size'], 'difficulty':level['difficulty'],
                       'generation':level['generation'], **analysis})
        print(f"OK {level['id']:02d}: {level['size']}x{level['size']} {level['difficulty']} fixed={len(level['preplaced_specialists'])} locks={analysis['confinements']} depth={analysis['max_dependency_depth']} score={analysis['score']} attempt={level['generation']['attempt']}", flush=True)
    # Do not publish a partial block if any profile fails. Each file is atomically replaced.
    args.output.mkdir(parents=True, exist_ok=True)
    for name, level in zip(names, results):
        path = args.output / name
        temp = path.with_suffix('.tmp')
        temp.write_text(json.dumps(level, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        temp.replace(path)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps({'seed':args.seed,'world':args.world,'product':args.product,'profiles':profiles,'levels':report}, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
    print(f"Saved {len(results)} levels in {time.monotonic()-started:.1f}s. Report: {args.report}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
