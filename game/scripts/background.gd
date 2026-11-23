extends Control
## Illustrated alpha layer stays behind native UI and never receives input.
const COURTYARD = preload("res://assets/decoration/factory_courtyard_v2.png")
const V = preload("res://scripts/visuals.gd")
var haze: GradientTexture2D

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    var soft := ShaderMaterial.new()
    soft.shader = preload("res://shaders/soft_background.gdshader")
    material = soft
    resized.connect(queue_redraw)
    haze = GradientTexture2D.new()
    haze.gradient = Gradient.new()
    haze.gradient.colors = PackedColorArray([Color(V.HIGHLIGHT, 0.34), Color(V.CREAM, 0.02)])
    haze.fill_from = Vector2(0.5, 0)
    haze.fill_to = Vector2(0.5, 1)

func _draw() -> void:
    var ratio := float(COURTYARD.get_width()) / COURTYARD.get_height()
    var width := maxf(size.x, size.y * ratio)
    var height := width / ratio
    draw_texture_rect(COURTYARD, Rect2(Vector2((size.x - width) / 2.0, (size.y - height) / 2.0), Vector2(width, height)), false, Color(1, 0.98, 0.95, 1.0))
    if haze != null:
        draw_texture_rect(haze, Rect2(Vector2.ZERO, size), false)
