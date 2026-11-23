extends RefCounted
## Shared materials for Home and Results, from the approved gameplay palette.
const T = preload("res://scripts/ui_tokens.gd")
const V = preload("res://scripts/visuals.gd")
const Ui = preload("res://scripts/ui_desktop_refinement.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")

static func card(height: float, padding: float = T.SHELL.padding, radius: float = T.SHELL.radius) -> StyleBoxTexture:
    var recipe := {"top":T.SHELL.card_top,"base":T.SHELL.card_base,"bottom":T.SHELL.card_bottom,"lip":T.SHELL.card_lip}
    return UiSkin.box(recipe,minf(T.unit(radius)/height,T.RESTART.radius),T.unit(padding),T.SHELL.lip,false,0.0,height)

static func button(button: Button, primary: bool, height: float) -> void:
    button.add_theme_font_override("font",V.HUD)
    button.add_theme_font_size_override("font_size",roundi(T.unit(T.SHELL.font if primary else T.SHELL.secondary_font)))
    button.expand_icon = true
    button.custom_minimum_size.y = T.unit(height)
    if primary:
        var specification := T.RESTART.duplicate()
        specification.height = height
        Ui.action_skin(button,specification)
    else:
        for state in ["normal","hover","pressed","disabled"]:
            var recipe := {"top":T.SHELL.card_top,"base":T.SHELL.card_base.lightened(T.SHELL.hover if state=="hover" else 0.0),"bottom":T.SHELL.card_bottom,"lip":T.SHELL.card_lip}
            var depth: float = T.TILE.pressed_lip/height if state=="pressed" else T.SHELL.lip
            var skin := UiSkin.box(recipe,T.SETTINGS.radius,T.unit(T.ROW_PADDING_Y),depth,false,0.0,T.unit(height))
            skin.content_margin_left = T.unit(T.SHELL.padding)
            skin.content_margin_right = T.unit(T.SHELL.padding)
            button.add_theme_stylebox_override(state,skin)
        button.add_theme_stylebox_override("focus",V.box(Color.TRANSPARENT,roundi(T.unit(height)*T.SETTINGS.radius),0,V.BLUE))
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        button.add_theme_color_override(state,V.HIGHLIGHT if primary else V.BLUE)

static func brand(row: HBoxContainer) -> void:
    row.add_theme_constant_override("separation",T.length("brand_row_separation"))
    row.get_child(0).custom_minimum_size = T.design_vector("brand_row_get_child_0_custom_minimum_size")
    Ui.style_wordmark(row.get_child(1))
    row.get_child(1).add_theme_color_override("font_shadow_color",V.DARK)
    row.get_child(1).add_theme_constant_override("shadow_offset_y",T.length("wordmark_shadow_offset_y"))
    row.get_child(1).add_theme_color_override("font_outline_color",V.HIGHLIGHT)
    row.get_child(1).add_theme_constant_override("outline_size",T.length("wordmark_outline_size"))

static func capture_controls(root: Control) -> Array:
    var records: Array = []
    for node in root.find_children("*","Control",true,false):
        var overrides := {}
        for property in node.get_property_list():
            if str(property.name).begins_with("theme_override_"):
                overrides[property.name] = node.get(property.name)
        records.append({"node":node,"parent":node.get_parent(),"index":node.get_index(true),"minimum":node.custom_minimum_size,"visible":node.visible,"overrides":overrides,"anchors":[node.anchor_left,node.anchor_top,node.anchor_right,node.anchor_bottom],"offsets":[node.offset_left,node.offset_top,node.offset_right,node.offset_bottom]})
    return records

static func restore_controls(records: Array) -> void:
    for record in records:
        var node: Control = record.node
        if node.get_parent()!=record.parent:
            node.reparent(record.parent,false)
            record.parent.move_child(node,mini(record.index,record.parent.get_child_count()-1))
        node.visible = record.visible
        node.custom_minimum_size = record.minimum
        node.anchor_left = record.anchors[0]
        node.anchor_top = record.anchors[1]
        node.anchor_right = record.anchors[2]
        node.anchor_bottom = record.anchors[3]
        node.offset_left = record.offsets[0]
        node.offset_top = record.offsets[1]
        node.offset_right = record.offsets[2]
        node.offset_bottom = record.offsets[3]
        for property in node.get_property_list():
            var name := str(property.name)
            var key := name.get_slice("/",1)
            if name.begins_with("theme_override_styles/"): node.remove_theme_stylebox_override(key)
            elif name.begins_with("theme_override_fonts/"): node.remove_theme_font_override(key)
            elif name.begins_with("theme_override_font_sizes/"): node.remove_theme_font_size_override(key)
            elif name.begins_with("theme_override_colors/"): node.remove_theme_color_override(key)
            elif name.begins_with("theme_override_constants/"): node.remove_theme_constant_override(key)
        for property in record.overrides:
            node.set(property,record.overrides[property])
