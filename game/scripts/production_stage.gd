extends Control
## Native display base behind the transparent vehicle, with no game state.
const V = preload("res://scripts/visuals.gd")
const T = preload("res://scripts/ui_tokens.gd")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    resized.connect(queue_redraw)

func _draw() -> void:
    if get_viewport_rect().size.x >= T.DESKTOP_MIN_WIDTH:
        var center := Vector2(size.x/2.0,size.y*T.PLATFORM.center_y)
        draw_set_transform(center+Vector2(0,size.y*T.PLATFORM.shadow_y),0,Vector2(1,T.PLATFORM.radius_y))
        draw_circle(Vector2.ZERO,size.x*T.PLATFORM.radius_x,T.PLATFORM.shadow,true,-1.0,true)
        draw_set_transform(center+Vector2(0,size.y*T.PLATFORM.depth),0,Vector2(1,T.PLATFORM.radius_y))
        draw_circle(Vector2.ZERO,size.x*T.PLATFORM.radius_x,T.PLATFORM.base,true,-1.0,true)
        draw_set_transform(center,0,Vector2(1,T.PLATFORM.radius_y))
        draw_circle(Vector2.ZERO,size.x*T.PLATFORM.radius_x,T.PLATFORM.rim,true,-1.0,true)
        draw_circle(Vector2.ZERO,size.x*T.PLATFORM.radius_x-T.unit(T.PLATFORM.rim_width),T.PLATFORM.top,true,-1.0,true)
        draw_set_transform(Vector2.ZERO)
        return
    var center := Vector2(size.x / 2.0, size.y * 0.84)
    draw_set_transform(center + Vector2(0, 5), 0, Vector2(1, 0.16))
    draw_circle(Vector2.ZERO, size.x * 0.47, Color(V.BLUE, 0.10), true, -1.0, true)
    draw_set_transform(center, 0, Vector2(1, 0.13))
    draw_circle(Vector2.ZERO, size.x * 0.47, V.GOLD, true, -1.0, true)
    draw_circle(Vector2(0, -8), size.x * 0.46, V.PAPER, true, -1.0, true)
    draw_circle(Vector2(0, -8), size.x * 0.43, V.BLUE.lerp(V.PAPER, 0.40), true, -1.0, true)
    draw_set_transform(Vector2.ZERO)
