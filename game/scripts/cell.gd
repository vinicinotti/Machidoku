extends Control
## A small, passive view: input is routed by BoardInput, state belongs to GameState.

const V = preload("res://scripts/visuals.gd")
const State = preload("res://scripts/game_state.gd")
const SPECIALIST = preload("res://assets/specialists/stamping.tres")
const LOCK = preload("res://assets/ui/icon_lock.svg")
const ERROR = preload("res://assets/ui/icon_error.svg")
const TILE_SURFACE = preload("res://shaders/tile_surface.gdshader")
const Art = preload("res://scripts/specialist_art.gd")

var row := 0
var column := 0
var region_id := 0
var state := State.CellState.EMPTY
var locked_error := false
var hovered := false
var region_color := Color.WHITE
var specialist_texture: Texture2D = SPECIALIST
var reduce_motion := false
var success_glow := 0.0:
    set(value):
        success_glow = value
        queue_redraw()
var success_tween: Tween
var mark_scale := 1.0:
    set(value):
        mark_scale = value
        queue_redraw()
var mark_alpha := 1.0:
    set(value):
        mark_alpha = value
        queue_redraw()
var shake := 0.0
var error_flash := 0.0
var mark_tween: Tween
var error_tween: Tween
var erasing := false
var erase_revision := 0
var tile_face: ColorRect
var portrait_view: TextureRect
var portrait_lock: Control
var portrait_mount: Control

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    tile_face = ColorRect.new()
    tile_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tile_face.show_behind_parent = true
    tile_face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var tile_material := ShaderMaterial.new()
    tile_material.shader = TILE_SURFACE
    tile_face.material = tile_material
    add_child(tile_face)
    portrait_mount = Control.new()
    portrait_mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait_mount.clip_contents = true
    add_child(portrait_mount)
    portrait_view = TextureRect.new()
    portrait_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait_view.texture = specialist_texture
    portrait_view.material = Art.for_sector(specialist_texture, region_color)
    portrait_view.visible = false
    portrait_mount.add_child(portrait_view)
    portrait_lock = Control.new()
    portrait_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait_lock.draw.connect(func():
        var badge := Rect2(Vector2.ZERO, portrait_lock.size)
        portrait_lock.draw_style_box(V.box(V.PAPER, 5, 0), badge)
        portrait_lock.draw_texture_rect(LOCK, badge.grow(-1.0), false))
    add_child(portrait_lock)
    resized.connect(update_surface)
    update_surface()

func update_surface() -> void:
    if is_instance_valid(tile_face):
        tile_face.material.set_shader_parameter("sector",region_color)
        tile_face.material.set_shader_parameter("extent",size.max(Vector2.ONE))
    queue_redraw()

func set_view(next_state: int, next_error: bool, animate: bool = true) -> void:
    animate = animate and not reduce_motion
    var changed := next_state != state
    var new_error := next_error and not locked_error
    if changed or not animate:
        cancel_erase()
    state = next_state
    locked_error = next_error
    if changed and animate:
        if mark_tween:
            mark_tween.kill()
        mark_scale = 1.0
        mark_alpha = 1.0
        if state != State.CellState.EMPTY:
            mark_tween = create_tween()
            var specialist := state == State.CellState.SPECIALIST
            mark_scale = 0.70 if specialist else 0.88
            # Normal annotations are already visible before Tween's first step.
            mark_alpha = 0.30 if state == State.CellState.X else 0.0
            mark_tween.tween_property(self, "mark_scale", 1.10 if specialist else 1.0, 0.09).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
            mark_tween.parallel().tween_property(self, "mark_alpha", 1.0, 0.10)
            if specialist:
                mark_tween.tween_property(self, "mark_scale", 1.0, 0.06)
                if success_tween:
                    success_tween.kill()
                success_glow = 1.0
                success_tween = create_tween()
                success_tween.tween_property(self, "success_glow", 0.0, 0.65)
    if new_error and animate:
        if error_tween:
            error_tween.kill()
        error_tween = create_tween()
        error_tween.tween_method(func(t: float):
            shake = sin(t * TAU * 3) * (1.0 - t) * 4.0
            error_flash = (1.0 - t) * 0.23
            queue_redraw(), 0.0, 1.0, 0.18)
    queue_redraw()

func begin_erase(duration: float, commit: Callable) -> void:
    if state != State.CellState.X or locked_error:
        return
    if mark_tween:
        mark_tween.kill()
    erase_revision += 1
    var revision := erase_revision
    erasing = true
    # Keep X in the model/view until its exit finishes. Unrelated model refreshes
    # must not restart it. A second click or new state invalidates this callback.
    mark_tween = create_tween().set_parallel(true)
    mark_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    mark_tween.tween_property(self, "mark_scale", 0.85, duration)
    mark_tween.tween_property(self, "mark_alpha", 0.0, duration)
    mark_tween.chain().tween_callback(func():
        if erasing and revision == erase_revision and state == State.CellState.X and not locked_error:
            erasing = false
            commit.call())

func cancel_erase() -> void:
    erase_revision += 1
    if not erasing:
        return
    erasing = false
    if mark_tween:
        mark_tween.kill()
    mark_scale = 1.0
    mark_alpha = 1.0

func _draw() -> void:
    portrait_view.visible = state in [State.CellState.SPECIALIST, State.CellState.PREPLACED_SPECIALIST]
    portrait_lock.visible = state == State.CellState.PREPLACED_SPECIALIST
    if error_flash > 0:
        draw_rect(Rect2(Vector2.ZERO, size), Color(V.CORAL, error_flash))
    if success_glow > 0.01:
        var glow := V.box(Color(V.GOLD, success_glow * 0.20), 17, 0, Color(V.GOLD.lightened(0.6), success_glow))
        glow.set_border_width_all(4)
        glow.shadow_color = Color(V.GOLD, success_glow * 0.7)
        glow.shadow_size = 12
        draw_style_box(glow, Rect2(Vector2.ONE * 2, size - Vector2.ONE * 4))
    draw_set_transform(size / 2.0 + Vector2(shake, 0), 0, Vector2.ONE * mark_scale)
    var half := size.x * (0.20 if locked_error else 0.17)
    var weight := maxf(3, size.x * 0.075)
    if state in [State.CellState.X, State.CellState.ERROR_X]:
        var ink: Color = V.CORAL.darkened(0.15) if locked_error else region_color.darkened(0.58)
        ink.a *= mark_alpha
        draw_line(Vector2(-half, -half), Vector2(half, half), ink, weight, true)
        draw_line(Vector2(half, -half), Vector2(-half, half), ink, weight, true)
        for end in [Vector2(-half,-half), Vector2(half,half), Vector2(half,-half), Vector2(-half,half)]:
            draw_circle(end, weight / 2.0, ink, true, -1, true)
    if state in [State.CellState.SPECIALIST, State.CellState.PREPLACED_SPECIALIST]:
        draw_set_transform(size / 2.0 + Vector2(shake, size.y * 0.34), 0, Vector2(mark_scale, mark_scale * 0.20))
        draw_circle(Vector2.ZERO, size.x * 0.28, Color(V.BLUE, 0.10 * mark_alpha), true, -1.0, true)
        draw_set_transform(size / 2.0 + Vector2(shake, 0), 0, Vector2.ONE * mark_scale)
        # Fit the complete portrait, reserving the applied visual overshoot.
        # Desktop keeps a quieter 1.04 pop; the existing mobile fit stays 1.10.
        var desktop := get_viewport_rect().size.x >= 900
        var inset := maxf(3.0,size.x*0.025) if desktop else maxf(4.0,size.x*0.065)
        portrait_mount.position = Vector2.ONE * inset
        portrait_mount.size = size - Vector2.ONE*inset*2.0 - Vector2(0,0 if desktop else 3)
        var portrait_size := specialist_texture.get_size()
        var fit_area := portrait_mount.size-Vector2.ONE*2.0
        var fitted := minf(fit_area.x/portrait_size.x,fit_area.y/portrait_size.y)/(1.04 if desktop else 1.10)
        var drawn := portrait_size*fitted
        portrait_view.size = drawn
        portrait_view.pivot_offset = drawn/2.0
        portrait_view.position = (portrait_mount.size-drawn)/2.0
        portrait_view.scale = Vector2.ONE * (minf(mark_scale,1.04) if desktop else mark_scale)
        portrait_view.modulate.a = mark_alpha
    draw_set_transform(Vector2.ZERO)
    if locked_error:
        draw_style_box(V.box(Color.TRANSPARENT, 7, 0, V.CORAL.darkened(0.12)), Rect2(Vector2.ONE * 3, size - Vector2.ONE * 6))
        var badge_side := clampf(size.x * 0.21, 12, 18)
        draw_texture_rect(ERROR, Rect2(Vector2(size.x - badge_side - 3, 3), Vector2.ONE * badge_side), false)
    if state == State.CellState.PREPLACED_SPECIALIST:
        var badge_side := clampf(size.x * 0.23, 13, 20)
        portrait_lock.position = Vector2(size.x - badge_side - 3, 3)
        portrait_lock.size = Vector2.ONE * badge_side
        portrait_lock.queue_redraw()
    if hovered:
        var hover := V.box(Color(V.PAPER, 0.10), clampi(roundi(size.x * V.CELL_RADIUS_RATIO), 5, 17), 0, Color(V.PAPER, 0.7))
        hover.set_border_width_all(2)
        draw_style_box(hover, Rect2(Vector2.ONE * 2, size - Vector2.ONE * 4))
