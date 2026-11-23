extends Container
## Visual stretch of the master frame. Board/input keep square local geometry.
var surface: Control

func _init() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    surface = Control.new()
    surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(surface)

func _notification(what: int) -> void:
    if what == NOTIFICATION_SORT_CHILDREN and is_instance_valid(surface):
        var side := maxf(1,minf(size.x,size.y))
        surface.position = Vector2.ZERO
        surface.size = Vector2.ONE * side
        surface.scale = size / side
