"""Deterministic, answer-independent logical trace and editorial difficulty heuristic."""
from __future__ import annotations

from collections import Counter
from tools.solver.validate import check_structure, coordinates


def analyze(level: dict) -> dict:
    n = check_structure(level)
    grid = level['regions']
    all_cells = {(r, c) for r in range(n) for c in range(n)}
    candidates = set(all_cells)
    placed = set(coordinates(level.get('preplaced_specialists', []), n, 'preplaced_specialists'))
    removed_depth: dict[tuple[int, int], int] = {}
    placed_depth = {p: 0 for p in placed}
    trace = []
    initial_candidates = None
    initial_singles = 0

    def conflicts(a, b):
        return a[0] == b[0] or a[1] == b[1] or grid[a[0]][a[1]] == grid[b[0]][b[1]] or max(abs(a[0]-b[0]), abs(a[1]-b[1])) <= 1

    groups = []
    for kind in ('row', 'column', 'sector'):
        for index in range(n):
            members = {p for p in all_cells if (p[0] if kind == 'row' else p[1] if kind == 'column' else grid[p[0]][p[1]]) == index}
            groups.append((kind, index, members))

    while len(placed) < n:
        for p in sorted(candidates):
            blockers = [q for q in placed if conflicts(p, q)]
            if blockers:
                candidates.remove(p)
                removed_depth[p] = min(placed_depth[q] + 1 for q in blockers)
        active = [(kind, index, members, members & candidates) for kind, index, members in groups if not members & placed]
        if initial_candidates is None:
            initial_candidates = len(candidates)
            initial_singles = sum(len(remaining) == 1 for _, _, _, remaining in active)
        if any(not remaining for _, _, _, remaining in active):
            break
        singles = [(kind, index, members, remaining) for kind, index, members, remaining in active if len(remaining) == 1]
        if singles:
            kind, index, members, remaining = singles[0]
            cell = min(remaining)
            depth = 1 + max((removed_depth.get(p, 0) for p in members - remaining), default=0)
            placed.add(cell)
            placed_depth[cell] = depth
            trace.append({'rule': kind + '_single', 'group': index, 'cell': list(cell), 'depth': depth})
            continue
        changed = False
        # A sector confined to an axis reserves it; an axis confined to a sector
        # also reserves that sector. Both follow directly from exactly-one rules.
        for kind, index, members, remaining in active:
            targets = ('row', 'column') if kind == 'sector' else ('sector',)
            for target in targets:
                values = {(p[0] if target == 'row' else p[1] if target == 'column' else grid[p[0]][p[1]]) for p in remaining}
                if len(values) != 1:
                    continue
                value = min(values)
                eliminated = {p for p in candidates - remaining if (p[0] if target == 'row' else p[1] if target == 'column' else grid[p[0]][p[1]]) == value}
                if not eliminated:
                    continue
                depth = 1 + max((removed_depth.get(p, 0) for p in members - remaining), default=0)
                for p in eliminated:
                    removed_depth[p] = depth
                candidates -= eliminated
                trace.append({'rule': kind + '_in_' + target, 'group': index, 'target': value,
                              'eliminated': [list(p) for p in sorted(eliminated)], 'depth': depth})
                changed = True
                break
            if changed:
                break
        if not changed:
            break
    counts = Counter(t['rule'] for t in trace)
    locks = sum(value for rule, value in counts.items() if '_in_' in rule)
    depth = max((step['depth'] for step in trace), default=0)
    # No grid-size term: this measures this restricted proof, not player skill.
    score = locks * 3 + depth
    category = 'very_hard' if locks >= 4 and score >= 28 else 'hard' if locks >= 2 and score >= 17 else 'normal' if locks or depth >= 10 else 'easy'
    return {'solved_logically': len(placed) == n, 'classification': category,
            'score': score, 'confinements': locks, 'max_dependency_depth': depth,
            'initial_candidates': initial_candidates or 0, 'initial_singletons': initial_singles,
            'fixed_specialists': len(level.get('preplaced_specialists', [])),
            'rule_counts': dict(sorted(counts.items())), 'trace': trace,
            'derived_solution': [list(p) for p in sorted(placed)]}
