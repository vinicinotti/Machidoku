extends PanelContainer
const V = preload("res://scripts/visuals.gd")
var difficulty := "normal"
var caption: Label
var tier := 2
var icon: TextureRect
var dots: HBoxContainer

func _ready() -> void:
    tier = {"easy":1,"normal":2,"hard":3,"very_hard":4}.get(difficulty,2)
    var tint: Color = [Color("#48CC4F"), Color("#FFAD29"), Color("#FF8130"), Color("#E96C57")][tier - 1]
    add_theme_stylebox_override("panel", V.surface(tint, 27, 10))
    var row := HBoxContainer.new()
    add_child(row)
    icon = V.texture("res://assets/ui/icon_difficulty.svg", Vector2(48,48))
    row.add_child(icon)
    var text := VBoxContainer.new()
    text.add_theme_constant_override("separation", 2)
    row.add_child(text)
    caption = V.label(V.DIFFICULTIES.get(difficulty,difficulty), "HeadingLabel", 21, V.HIGHLIGHT)
    caption.add_theme_color_override("font_shadow_color", tint.darkened(0.4))
    caption.add_theme_constant_override("shadow_offset_y", 1)
    text.add_child(caption)
    dots = HBoxContainer.new()
    dots.add_theme_constant_override("separation", 7)
    text.add_child(dots)
    for i in range(5):
        var dot := PanelContainer.new()
        dot.custom_minimum_size = Vector2(13,13)
        dot.add_theme_stylebox_override("panel", V.box(V.GOLD if i < tier else tint.lightened(0.20), 7, 0, tint.darkened(0.15)))
        dots.add_child(dot)

func set_compact(compact: bool) -> void:
    if not is_instance_valid(caption):
        return
    icon.custom_minimum_size = Vector2.ONE * (24 if compact else 48)
    caption.add_theme_font_size_override("font_size", 12 if compact else 23 if tier == 4 else 28)
    add_theme_stylebox_override("panel",V.surface([Color("#48CC4F"),Color("#FFAD29"),Color("#FF8130"),Color("#E96C57")][tier-1],7 if compact else 27,4 if compact else 10))
    if not compact:
        var tint: Color = [Color("#48CC4F"),Color("#FFAD29"),Color("#FF8130"),Color("#E96C57")][tier-1]
        add_theme_stylebox_override("panel",V.desktop_surface(tint,25,12))
        icon.custom_minimum_size = Vector2(44,44)
        get_child(0).add_theme_constant_override("separation",14)
        caption.add_theme_font_size_override("font_size",23 if tier == 4 else 26)
    for dot in dots.get_children():
        dot.custom_minimum_size = Vector2.ONE * (6 if compact else 13)
