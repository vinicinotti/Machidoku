extends Control
## One overlay above all cells. Each shared sector edge is emitted once.
const V = preload("res://scripts/visuals.gd")
const SECTOR_WIDTH := 1.25
const SECTOR_INK := Color("#2646536B") # Industrial blue at 42% opacity.
var board: Control
var internal_lines := PackedVector2Array()
var sector_lines := PackedVector2Array()
var outline := Rect2()
var boundary_edge_count := 0

func rebuild(grid: Array, area: Rect2) -> void:
    internal_lines.clear()
    sector_lines.clear()
    boundary_edge_count = 0
    outline = area
    var n := grid.size()
    var pitch := area.size.x / n
    for i in range(1, n):
        internal_lines.append_array(PackedVector2Array([area.position + Vector2(0, i * pitch), area.position + Vector2(area.size.x, i * pitch),
            area.position + Vector2(i * pitch, 0), area.position + Vector2(i * pitch, area.size.y)]))
    # Merge collinear runs. Different ids on opposite sides trigger one stroke.
    for axis in range(2):
        for line in range(1, n):
            var run := -1
            for along in range(n + 1):
                var boundary := false
                if along < n:
                    boundary = grid[line - 1][along] != grid[line][along] if axis == 0 else grid[along][line - 1] != grid[along][line]
                if boundary:
                    boundary_edge_count += 1
                    if run == -1:
                        run = along
                elif run >= 0:
                    var a := Vector2(run * pitch, line * pitch) if axis == 0 else Vector2(line * pitch, run * pitch)
                    var b := Vector2(along * pitch, line * pitch) if axis == 0 else Vector2(line * pitch, along * pitch)
                    sector_lines.append(area.position + a)
                    sector_lines.append(area.position + b)
                    run = -1
    queue_redraw()

func _draw() -> void:
    if not internal_lines.is_empty():
        draw_multiline(internal_lines, Color(V.BLUE, 0.12), 0.7, true)
    if not sector_lines.is_empty():
        # Fixed, light strokes avoid oversized seams on short region edges.
        # No extra end caps: overlapping alpha would darken the small joins.
        draw_multiline(sector_lines, SECTOR_INK, SECTOR_WIDTH, true)
    if outline.size.x > 0:
        var rim := V.box(Color.TRANSPARENT, 12, 0, V.FRAME)
        rim.set_border_width_all(3)
        draw_style_box(rim, outline.grow(1))
