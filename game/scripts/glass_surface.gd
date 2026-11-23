extends ColorRect
## A single structural surface, sharing the background-only back buffer.
const FROST = preload("res://shaders/frosted_glass.gdshader")
var shadow: Panel

func _init() -> void:
    name = "GlassSurface"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    show_behind_parent = true
    var frost := ShaderMaterial.new()
    frost.shader = FROST
    material = frost
    shadow = Panel.new()
    shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shadow.show_behind_parent = true
    shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shadow)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(update_dimensions)

func update_dimensions() -> void:
    material.set_shader_parameter("panel_size", size.max(Vector2.ONE))
    var surface := StyleBoxFlat.new()
    surface.bg_color = Color.TRANSPARENT
    var corner = material.get_shader_parameter("radius")
    surface.set_corner_radius_all(roundi(corner if corner != null else 32.0))
    surface.corner_detail = 16
    surface.shadow_color = Color(0.12,0.16,0.20,0.12)
    surface.shadow_size = 10
    surface.shadow_offset = Vector2(0,4)
    shadow.add_theme_stylebox_override("panel",surface)
