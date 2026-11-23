"""Machidoku level validation and bounded solution enumeration; standard library only."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LEVELS = ROOT / "game" / "levels"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def coordinates(value: object, size: int, label: str) -> list[tuple[int, int]]:
    require(isinstance(value, list), f"{label}: expected an array")
    result = []
    for cell in value:
        require(isinstance(cell, list) and len(cell) == 2, f"{label}: invalid coordinate")
        require(all(type(v) is int and 0 <= v < size for v in cell), f"{label}: out of bounds")
        result.append(tuple(cell))
    require(len(set(result)) == len(result), f"{label}: duplicate coordinates")
    return result


def check_structure(level: dict) -> int:
    require(isinstance(level, dict), "Level must be an object")
    size = level.get("size")
    require(type(size) is int and 4 <= size <= 12, "size must be an integer from 4 to 12")
    for key in ("name", "world", "product", "vehicle_name", "difficulty"):
        require(isinstance(level.get(key), str) and bool(level[key]), f"Missing {key}")
    require(type(level.get("id")) is int and level["id"] > 0, "Invalid level id")
    regions = level.get("regions")
    require(isinstance(regions, list) and len(regions) == size, "Incorrect region row count")
    require(all(isinstance(row, list) and len(row) == size for row in regions), "Incorrect grid shape")
    require(all(type(v) is int and 0 <= v < size for row in regions for v in row), "Region ids must be 0..N-1")
    for region in range(size):
        cells = {(r, c) for r in range(size) for c in range(size) if regions[r][c] == region}
        require(bool(cells), f"Missing region {region}")
        reached = {next(iter(cells))}
        pending = list(reached)
        while pending:
            r, c = pending.pop()
            for neighbor in ((r - 1, c), (r + 1, c), (r, c - 1), (r, c + 1)):
                if neighbor in cells and neighbor not in reached:
                    reached.add(neighbor)
                    pending.append(neighbor)
        require(reached == cells, f"Region {region} is disconnected")
    return size


def check_solution(level: dict, solution: list[tuple[int, int]]) -> None:
    size = level["size"]
    require(len(solution) == size, "Expected exactly N specialists")
    require(len({r for r, _ in solution}) == size, "Repeated row")
    require(len({c for _, c in solution}) == size, "Repeated column")
    require(len({level['regions'][r][c] for r, c in solution}) == size, "Repeated sector")
    for i, (r, c) in enumerate(solution):
        for rr, cc in solution[i + 1:]:
            require(max(abs(r - rr), abs(c - cc)) > 1, "Specialists touch")


def solve(level: dict, limit: int = 2) -> list[list[tuple[int, int]]]:
    """Count up to limit, respecting fixed specialists; no solution-array lookup."""
    size = check_structure(level)
    fixed = coordinates(level.get("preplaced_specialists", []), size, "preplaced_specialists")
    require(len({r for r, _ in fixed}) == len(fixed), "Repeated fixed row")
    fixed_by_row = dict(fixed)
    results: list[list[tuple[int, int]]] = []

    def visit(row: int, columns: set[int], regions: set[int], placement: list[tuple[int, int]]) -> None:
        if len(results) >= limit:
            return
        if row == size:
            results.append(placement[:])
            return
        options = [fixed_by_row[row]] if row in fixed_by_row else range(size)
        for col in options:
            region = level["regions"][row][col]
            if col in columns or region in regions:
                continue
            if placement and abs(col - placement[-1][1]) <= 1:
                continue
            visit(row + 1, columns | {col}, regions | {region}, placement + [(row, col)])

    visit(0, set(), set(), [])
    return results


def validate_level(level: dict) -> dict:
    size = check_structure(level)
    solution = coordinates(level.get("solution"), size, "solution")
    check_solution(level, solution)
    fixed = coordinates(level.get("preplaced_specialists", []), size, "preplaced_specialists")
    require(set(fixed) <= set(solution), "Fixed specialist not in solution")
    found = solve(level)
    require(len(found) == 1, f"Expected unique solution; found {'2+' if len(found) > 1 else 0}")
    require(set(found[0]) == set(solution), "Stored solution differs from solver")
    return {"id": level["id"], "size": size, "specialists": len(solution), "solutions": 1,
            "connected_sectors": size, "valid": True}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", type=Path)
    args = parser.parse_args()
    paths = args.files or sorted(LEVELS.glob("*.json"))
    if not paths:
        print("FAIL: no levels found")
        return 1
    failed = False
    for path in paths:
        try:
            result = validate_level(json.loads(path.read_text(encoding="utf-8")))
            print(f"OK {path.name}: {json.dumps(result)}")
        except (ValueError, OSError, TypeError, KeyError) as error:
            print(f"FAIL {path.name}: {error}")
            failed = True
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
