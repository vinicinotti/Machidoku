extends Node
## Keeps the decorated modal centered through native Container size changes.
const T = preload("res://scripts/ui_tokens.gd")
var game
func _process(_delta: float) -> void:
    if not is_instance_valid(game) or not is_instance_valid(game.result_panel):
        return
    var panel: Control = game.result_panel
    var design_factor: float = minf(game.size.x/T.canvas().x,game.size.y/T.canvas().y) if game.size.x>=T.DESKTOP_MIN_WIDTH else 1.0
    var viewport_size: Vector2 = game.get_viewport_rect().size
    var available: Vector2 = viewport_size-Vector2.ONE*T.unit(T.RESULTS.padding)*2.0
    var factor := minf(design_factor,minf(available.x/maxf(1,panel.size.x),available.y/maxf(1,panel.size.y)))
    panel.pivot_offset = panel.size/2.0
    panel.scale = Vector2.ONE*factor
    # CenterContainer cannot center an oversized minimum size by itself.
    # Position the unscaled panel symmetrically so its scaled bounds stay centered.
    var center: Control = panel.get_parent()
    panel.position = viewport_size/2.0-center.global_position-panel.size/2.0
