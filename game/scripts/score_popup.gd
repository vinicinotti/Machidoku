extends Control
const V = preload("res://scripts/visuals.gd")
var points := 100
var streak := 1
var reduced_motion := false
var flare := 1.0:
    set(value):
        flare = value
        queue_redraw()

func _draw() -> void:
    if reduced_motion:
        return
    draw_set_transform(size / 2.0,0,Vector2(1.6,0.65))
    for radius in [38.0,32.0,25.0]:
        draw_circle(Vector2.ZERO,radius,Color(V.GOLD,0.065 * flare),true,-1,true)
    draw_set_transform(Vector2.ZERO)
    for point in [Vector2(15,16),Vector2(166,13),Vector2(20,60),Vector2(160,57)]:
        var diamond := PackedVector2Array([point+Vector2(0,-7),point+Vector2(3,0),point+Vector2(0,7),point+Vector2(-3,0)])
        draw_colored_polygon(diamond,Color(V.HIGHLIGHT,flare))

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    size = Vector2(180,80)
    pivot_offset = size / 2.0
    for layer in range(2):
        var label := V.label("+%d" % points, "HeadingLabel", 52, Color("#FFF38A"))
        label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.add_theme_color_override("font_outline_color", Color("#FFEFA2") if layer == 0 else V.DARK)
        label.add_theme_constant_override("outline_size", 13 if layer == 0 else 7)
        label.add_theme_color_override("font_shadow_color", Color("#FF8D28"))
        label.add_theme_constant_override("shadow_offset_x", 2)
        label.add_theme_constant_override("shadow_offset_y", 3)
        add_child(label)
    if streak > 1:
        var caption := V.label("SEQUÊNCIA %d" % streak, "HeadingLabel", 12, V.PAPER)
        caption.position = Vector2(18,65)
        caption.add_theme_color_override("font_outline_color", V.DARK)
        caption.add_theme_constant_override("outline_size", 4)
        add_child(caption)
    call_deferred("animate_popup")

func animate_popup() -> void:
    scale = Vector2.ONE if reduced_motion else Vector2.ONE * 0.76
    var pop := create_tween()
    if not reduced_motion:
        pop.tween_property(self, "scale", Vector2.ONE * 1.10, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        pop.tween_property(self, "scale", Vector2.ONE, 0.12)
    pop.tween_interval(0.55 if not reduced_motion else 0.8)
    pop.tween_property(self, "modulate:a", 0.0, 0.30)
    pop.tween_callback(queue_free)
    if not reduced_motion:
        var rise := create_tween()
        rise.tween_property(self, "position:y", position.y - 25, 1.20)
        var glow := create_tween()
        glow.tween_property(self,"flare",0.0,0.45).set_delay(0.35)
