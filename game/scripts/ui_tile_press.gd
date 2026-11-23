extends Node
## Read-only pointer feedback. Never consumes input or changes cell/model state.
const T = preload("res://scripts/ui_tokens.gd")
var face: ColorRect
var was_pressed := false

func _process(_delta: float) -> void:
    var pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and face.get_global_rect().has_point(face.get_global_mouse_position())
    if pressed != was_pressed:
        was_pressed = pressed
        face.material.set_shader_parameter("pressed",pressed)
