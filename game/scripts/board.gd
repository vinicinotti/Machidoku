extends Control

const CellScene = preload("res://scenes/Cell.tscn")
const Router = preload("res://scripts/board_input.gd")
const Lines = preload("res://scripts/board_lines.gd")
const Palette = preload("res://scripts/sector_palette.gd")
const Art = preload("res://scripts/specialist_art.gd")
const CLICK_ERASE_SECONDS := 0.09
const DRAG_ERASE_SECONDS := 0.055

var model
var cells: Array[Control] = []
var router
var hovered := Vector2i(-1, -1)
var lines
var region_colors: Array[Color] = []
var victory_tween: Tween
var victory_scale := 1.0:
    set(value):
        victory_scale = value
        scale = Vector2.ONE * value
var reduced_motion := false
var focused_region := -1

func focus_region(region: int) -> void:
    focused_region = -1 if focused_region == region else region
    for cell in cells:
        cell.modulate = Color.WHITE if focused_region < 0 or cell.region_id == focused_region else Color(0.72,0.72,0.72,1)

func _ready() -> void:
    router = Router.new()
    router.board = self
    add_child(router)
    lines = Lines.new()
    lines.board = self
    lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(lines)
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    resized.connect(layout_cells)
    mouse_exited.connect(func(): update_hover(Vector2i(-1, -1)))

func setup(state) -> void:
    if model != null and model.changed.is_connected(refresh):
        model.changed.disconnect(refresh)
    model = state
    router.cancel()
    for cell in cells:
        cell.cancel_erase()
        cell.queue_free()
    cells.clear()
    var n := int(model.level.size)
    region_colors = Palette.assign(model.level.regions)
    for r in range(n):
        for c in range(n):
            var cell = CellScene.instantiate()
            cell.row = r
            cell.column = c
            cell.region_id = int(model.level.regions[r][c])
            cell.region_color = region_colors[cell.region_id]
            cell.specialist_texture = Art.for_region(model.level, cell.region_id)
            add_child(cell)
            cells.append(cell)
    model.changed.connect(refresh)
    move_child(lines, -1)
    layout_cells()
    refresh(false)

func layout_cells() -> void:
    if model == null:
        return
    var n := int(model.level.size)
    var side := maxf(0.0, minf(size.x, size.y) - 6.0)
    var origin := (size - Vector2.ONE * side) / 2.0
    var cell_size := side / n
    for cell in cells:
        cell.position = origin + Vector2(cell.column, cell.row) * cell_size
        cell.size = Vector2.ONE * cell_size
        cell.queue_redraw()
    lines.size = size
    lines.rebuild(model.level.regions, Rect2(origin, Vector2.ONE * side))
    pivot_offset = size / 2.0

func cell_at(local: Vector2) -> Vector2i:
    if model == null:
        return Vector2i(-1, -1)
    var side := minf(size.x, size.y) - 6.0
    var origin := (size - Vector2.ONE * side) / 2.0
    var p := local - origin
    if p.x < 0 or p.y < 0 or p.x >= side or p.y >= side:
        return Vector2i(-1, -1)
    return Vector2i(floori(p.y / side * int(model.level.size)), floori(p.x / side * int(model.level.size)))

func refresh(animate: bool = true) -> void:
    for cell in cells:
        var pos := Vector2i(cell.row, cell.column)
        if model.over:
            cell.cancel_erase()
        cell.set_view(model.state_at(pos), model.errors.has(pos), animate)

func remove_x(pos: Vector2i, duration: float) -> void:
    if model == null or not model.can_mark(pos) or model.state_at(pos) != model.CellState.X:
        return
    var source = model
    var cell = cells[model.index(pos)]
    cell.begin_erase(duration, func():
        if model == source and model.can_mark(pos) and model.state_at(pos) == model.CellState.X:
            model.mark_x(pos, true))

func cancel_x_removal(pos: Vector2i) -> void:
    if model != null and model.inside(pos):
        cells[model.index(pos)].cancel_erase()

func pulse_victory() -> void:
    if reduced_motion:
        return
    if victory_tween:
        victory_tween.kill()
    victory_tween = create_tween()
    victory_tween.tween_property(self, "victory_scale", 1.018, 0.09).set_trans(Tween.TRANS_SINE)
    victory_tween.tween_property(self, "victory_scale", 1.0, 0.09).set_trans(Tween.TRANS_SINE)

func update_hover(pos: Vector2i) -> void:
    if hovered == pos:
        return
    hovered = pos
    for cell in cells:
        cell.hovered = Vector2i(cell.row, cell.column) == pos
        cell.queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        update_hover(cell_at(event.position))
    router.handle(event)
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        accept_event()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(router):
        router.cancel()

func _input(event: InputEvent) -> void:
    # Finish a drag released outside the board; do not leave the gesture latched.
    if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if is_instance_valid(router) and router.down and not get_global_rect().has_point(event.position):
            router.cancel()
