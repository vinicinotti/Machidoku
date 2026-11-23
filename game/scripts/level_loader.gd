extends RefCounted
## Discover packaged JSONs; ordering and navigation follow ids, not file names.

static func load_levels(directory: String = "res://levels") -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var ids := {}
    if not DirAccess.dir_exists_absolute(directory):
        push_error("Pasta de fases ausente: " + directory)
        return result
    for filename in DirAccess.get_files_at(directory):
        if filename.get_extension().to_lower() != "json":
            continue
        var path := directory.path_join(filename)
        var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not parsed is Dictionary or not validate(parsed):
            push_error("Fase inválida: " + path)
            return []
        if ids.has(int(parsed.id)):
            push_error("Id de fase duplicado: " + str(parsed.id))
            return []
        ids[int(parsed.id)] = true
        result.append(parsed)
    result.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.id) < int(b.id))
    return result

static func validate(level: Dictionary) -> bool:
    if level.has("reference_time_sec"):
        var reference = level.reference_time_sec
        if not (reference is int or reference is float) or not is_finite(float(reference)) or reference <= 0:
            return false
    for key in ["id", "name", "world", "product", "vehicle_name", "difficulty", "size", "regions", "solution", "preplaced_specialists"]:
        if not level.has(key):
            return false
    if not (level.id is int or level.id is float) or level.id != int(level.id) or int(level.id) < 1:
        return false
    if not (level.size is int or level.size is float) or level.size != int(level.size):
        return false
    for key in ["name", "world", "product", "vehicle_name", "difficulty"]:
        if not level[key] is String or level[key].is_empty():
            return false
    for key in ["regions", "solution", "preplaced_specialists"]:
        if not level[key] is Array:
            return false
    var n := int(level.size)
    if n < 4 or n > 12 or level.regions.size() != n or level.solution.size() != n:
        return false
    var sectors := {}
    for row in level.regions:
        if not row is Array or row.size() != n:
            return false
        for value in row:
            if not (value is int or value is float) or value != int(value) or value < 0 or value >= n:
                return false
            sectors[int(value)] = true
    if sectors.size() != n:
        return false
    for sector in range(n):
        var cells: Array[Vector2i] = []
        for r in range(n):
            for c in range(n):
                if int(level.regions[r][c]) == sector:
                    cells.append(Vector2i(r, c))
        var reached := {cells[0]: true}
        var pending := [cells[0]]
        while not pending.is_empty():
            var cell: Vector2i = pending.pop_back()
            for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
                var neighbor: Vector2i = cell + step
                if cells.has(neighbor) and not reached.has(neighbor):
                    reached[neighbor] = true
                    pending.append(neighbor)
        if reached.size() != cells.size():
            return false
    if not valid_placement(level, level.solution):
        return false
    var fixed := {}
    for cell in level.preplaced_specialists:
        if not level.solution.has(cell) or fixed.has(str(cell)):
            return false
        fixed[str(cell)] = true
    return true

static func valid_placement(level: Dictionary, cells: Array) -> bool:
    var n := int(level.size)
    if cells.size() != n:
        return false
    var rows := {}
    var columns := {}
    var sectors := {}
    var positions: Array[Vector2i] = []
    for cell in cells:
        if not cell is Array or cell.size() != 2:
            return false
        if cell[0] != int(cell[0]) or cell[1] != int(cell[1]):
            return false
        var r := int(cell[0])
        var c := int(cell[1])
        if r < 0 or r >= n or c < 0 or c >= n:
            return false
        rows[r] = true
        columns[c] = true
        sectors[int(level.regions[r][c])] = true
        for other in positions:
            if maxi(absi(r - other.x), absi(c - other.y)) <= 1:
                return false
        positions.append(Vector2i(r, c))
    return rows.size() == n and columns.size() == n and sectors.size() == n
