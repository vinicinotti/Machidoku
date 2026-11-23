extends Control
## Time-based visual feedback only. The model has already committed victory.
const T = preload("res://scripts/ui_tokens.gd")
const V = preload("res://scripts/visuals.gd")
var game
var started := 0
var reduced := false
var backdrop: ColorRect

static func overlay_material() -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = preload("res://shaders/ui_result_backdrop.gdshader")
    material.set_shader_parameter("dim",T.RESULTS.overlay_dim)
    material.set_shader_parameter("saturation",T.RESULTS.overlay_saturation)
    material.set_shader_parameter("navy_tint",T.RESULTS.overlay_tint)
    material.set_shader_parameter("blur_lod",T.RESULTS.overlay_blur)
    material.set_shader_parameter("navy",V.DARK)
    material.set_shader_parameter("progress",0.0)
    return material

static func play(target) -> void:
    if target.size.x<T.DESKTOP_MIN_WIDTH:
        target.board.pulse_victory()
        await target.get_tree().create_timer(T.COMPLETION.legacy_wait).timeout
        return
    var layer := Control.new()
    layer.set_script(load("res://scripts/ui_completion.gd"))
    layer.game = target
    layer.reduced = target.reduced_motion()
    layer.started = Time.get_ticks_msec()
    layer.z_index = 19
    layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    target.add_child(layer)
    target.set_meta("ui_completion_layer",layer)
    target.set_meta("ui_completion_started_ms",layer.started)
    # A monotonic visual deadline avoids accumulated frame-delta drift, without
    # advancing the already-stopped gameplay/scoring clock.
    var tree: SceneTree = target.get_tree()
    var deadline: int = layer.started+roundi(T.COMPLETION.modal*1000.0)
    while Time.get_ticks_msec()<deadline:
        await tree.process_frame
        if not is_instance_valid(target) or not target.is_inside_tree():
            return

func _process(_delta: float) -> void:
    if not is_instance_valid(game):
        return
    var age := float(Time.get_ticks_msec()-started)/1000.0
    if not reduced:
        for cell in game.board.cells:
            var delay: float = (cell.row+cell.column)*T.COMPLETION.wave_delay
            var phase: float = (age-T.COMPLETION.settle-delay)/T.COMPLETION.tile_duration
            var bump := sin(clampf(phase,0.0,1.0)*PI) if phase>=0 and phase<=1 else 0.0
            cell.tile_face.pivot_offset = cell.tile_face.size/2.0
            cell.tile_face.scale = Vector2.ONE*(1.0+bump*(T.COMPLETION.tile_scale-1.0))
    if age>=T.COMPLETION.overlay_start:
        if not is_instance_valid(backdrop):
            var copy := BackBufferCopy.new()
            copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
            add_child(copy)
            backdrop = ColorRect.new()
            backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
            backdrop.material = overlay_material()
            backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            add_child(backdrop)
        backdrop.material.set_shader_parameter("progress",clampf((age-T.COMPLETION.overlay_start)/T.COMPLETION.overlay_fade,0.0,1.0))
    queue_redraw()
    if age>T.COMPLETION.modal+T.RESULTS.entrance:
        set_process(false)

func _draw() -> void:
    if not is_instance_valid(game):
        return
    var age := float(Time.get_ticks_msec()-started)/1000.0
    if age<T.COMPLETION.settle or age>T.COMPLETION.overlay_start:
        return
    var frame: Rect2 = game.board_mount.get_global_rect()
    frame.position -= global_position
    var phase := clampf((age-T.COMPLETION.settle)/(T.COMPLETION.wave_end-T.COMPLETION.settle),0.0,1.0)
    var glow_alpha: float = T.COMPLETION.glow_alpha*(sin(phase*PI) if not reduced else 0.5)
    var glow := V.box(Color.TRANSPARENT,roundi(T.unit(T.RESULTS.radius)),0,Color(V.CREAM,glow_alpha))
    glow.set_border_width_all(roundi(T.unit(T.COMPLETION.glow_width)))
    # StyleBoxFlat shadows fill their interior even on transparent boxes.
    # Keep the celebration on the perimeter instead of tinting the puzzle.
    glow.shadow_size = 0
    draw_style_box(glow,frame)
    var edge := V.box(Color.TRANSPARENT,roundi(T.unit(T.RESULTS.radius)),0,Color(T.FRAME.border,glow_alpha/2.0))
    edge.set_border_width_all(roundi(T.unit(T.TILE.highlight)))
    draw_style_box(edge,frame.grow(T.unit(T.COMPLETION.glow_width)/2.0))
    if reduced:
        return
    for i in range(T.COMPLETION.particles):
        var local_phase := clampf(phase-float(i%7)*T.COMPLETION.wave_delay,0.0,1.0)
        var angle := float(i)/T.COMPLETION.particles*TAU
        var position := frame.get_center()+Vector2(cos(angle)*frame.size.x/2.0,sin(angle)*frame.size.y/2.0)
        position += Vector2(sin(angle)*T.unit(T.COMPLETION.particle_drift)*local_phase,-T.unit(T.COMPLETION.particle_drift)*local_phase)
        var ink: Color = T.COMPLETION.colors[i%T.COMPLETION.colors.size()]
        ink.a = sin(local_phase*PI)*T.COMPLETION.glow_alpha
        draw_circle(position,T.unit(T.COMPLETION.particle_size)*(1.0-local_phase/2.0),ink,true,-1.0,true)
