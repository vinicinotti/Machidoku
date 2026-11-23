extends RefCounted
## Perceptual separation on the region adjacency graph (CIE76, D65).
const COLORS := [Color("#FEDA4B"), Color("#BE81EF"), Color("#86EB7F"),
    Color("#55BEFA"), Color("#F28CB9"), Color("#FE8E61"), Color("#59AAF0"),
    Color("#6DDBBB"), Color("#EB856C"), Color("#9691ED"), Color("#D6E76E"), Color("#CEAB77")]
const MIN_DISTANCE := 24.0

static func lab(color: Color) -> Vector3:
    var rgb := color.srgb_to_linear()
    var xyz := Vector3((rgb.r * 0.4124564 + rgb.g * 0.3575761 + rgb.b * 0.1804375) / 0.95047,
        rgb.r * 0.2126729 + rgb.g * 0.7151522 + rgb.b * 0.0721750,
        (rgb.r * 0.0193339 + rgb.g * 0.1191920 + rgb.b * 0.9503041) / 1.08883)
    for axis in range(3):
        xyz[axis] = pow(xyz[axis], 1.0 / 3.0) if xyz[axis] > 0.008856 else 7.787 * xyz[axis] + 16.0 / 116.0
    return Vector3(116 * xyz.y - 16, 500 * (xyz.x - xyz.y), 200 * (xyz.y - xyz.z))

static func distance(a: Color, b: Color) -> float:
    return lab(a).distance_to(lab(b))

static func adjacency(grid: Array) -> Array[Dictionary]:
    var n := grid.size()
    var graph: Array[Dictionary] = []
    for i in range(n):
        graph.append({})
    for r in range(n):
        for c in range(n):
            var current := int(grid[r][c])
            for step in [Vector2i(1, 0), Vector2i(0, 1)]:
                var rr: int = r + step.x
                var cc: int = c + step.y
                if rr < n and cc < n:
                    var neighbor := int(grid[rr][cc])
                    if current != neighbor:
                        graph[current][neighbor] = true
                        graph[neighbor][current] = true
    return graph

static func assign(grid: Array) -> Array[Color]:
    var graph := adjacency(grid)
    var chosen: Array[int] = []
    chosen.resize(graph.size())
    chosen.fill(-1)
    var distances: Array = []
    for a in COLORS:
        var row: Array[float] = []
        for b in COLORS:
            row.append(distance(a, b))
        distances.append(row)
    var success := color_next(graph, chosen, distances)
    assert(success, "Sector palette cannot meet the minimum perceptual distance")
    var result: Array[Color] = []
    for index in chosen:
        result.append(COLORS[maxi(index, 0)])
    return result

static func color_next(graph: Array[Dictionary], chosen: Array[int], distances: Array) -> bool:
    var vertex := -1
    var priority := -1
    for i in range(graph.size()):
        if chosen[i] >= 0:
            continue
        var saturation := {}
        for neighbor in graph[i]:
            if chosen[neighbor] >= 0:
                saturation[chosen[neighbor]] = true
        var weight := saturation.size() * 100 + graph[i].size()
        if weight > priority:
            priority = weight
            vertex = i
    if vertex == -1:
        return true
    var options: Array = []
    for color in range(COLORS.size()):
        var separation := 1000.0
        for neighbor in graph[vertex]:
            if chosen[neighbor] >= 0:
                separation = minf(separation, distances[color][chosen[neighbor]])
        if separation >= MIN_DISTANCE:
            options.append({"color": color, "score": separation * 0.05 + (200.0 - color * 10.0 if not chosen.has(color) else 0.0) - chosen.count(color) * 4.0})
    options.sort_custom(func(a: Dictionary, b: Dictionary): return a.score > b.score if a.score != b.score else a.color < b.color)
    for option in options:
        chosen[vertex] = option.color
        if color_next(graph, chosen, distances):
            return true
    chosen[vertex] = -1
    return false
