extends Control
## Shared native cog artwork for earned ratings and remaining lives.
const V = preload("res://scripts/visuals.gd")
const FULL = preload("res://assets/ui/icon_life.svg")
const EMPTY = preload("res://assets/ui/icon_life_empty.svg")
var active := 3
var unknown := false

func _init() -> void:
    custom_minimum_size = Vector2(79, 27)
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_count(value: int) -> void:
    unknown = value < 0
    active = clampi(value, 0, 3)
    queue_redraw()

func _draw() -> void:
    var side := minf(size.y, size.x / 3.0)
    for i in range(3):
        var center := Vector2(size.x / 6.0 + i * size.x / 3.0, size.y / 2.0)
        draw_texture_rect(FULL if i < active else EMPTY, Rect2(center - Vector2.ONE * side / 2.0, Vector2.ONE * side), false, Color(1,1,1,0.6 if unknown else 1.0))
