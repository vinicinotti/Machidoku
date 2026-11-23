extends RefCounted
## Presentation only: retain the original CheckBox, labels, button and callbacks.
const T = preload("res://scripts/ui_tokens.gd")
const V = preload("res://scripts/visuals.gd")
const Shared = preload("res://scripts/ui_shell.gd")
const Completion = preload("res://scripts/ui_completion.gd")
static var checks := {}

static func check_icon(checked: bool, extent: int) -> Texture2D:
    var key := str([checked,extent])
    if not checks.has(key):
        var top: Color = T.RESTART.top if checked else T.SHELL.card_top
        var bottom: Color = T.RESTART.bottom if checked else T.SHELL.card_bottom
        var lip: Color = T.RESTART.edge if checked else T.SHELL.card_lip
        var border: Color = T.SHELL.card_top if checked else T.SHELL.card_lip
        var mark := '<path d="m10 17 5 5 11-12" fill="none" stroke="white" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/>' if checked else ''
        var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36"><defs><linearGradient id="face" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="2" y="3" width="32" height="32" rx="10" fill="#%s"/><rect x="2" y="1" width="32" height="31" rx="10" fill="url(#face)" stroke="#%s" stroke-width="1.2"/>%s</svg>' % [top.to_html(false),bottom.to_html(false),lip.to_html(false),border.to_html(false),mark]
        var source := Image.new()
        source.load_svg_from_string(svg,float(extent)/36.0)
        checks[key] = ImageTexture.create_from_image(source)
    return checks[key]

static func apply(game) -> void:
    if not is_instance_valid(game.options_overlay):
        return
    var overlay: Control = game.options_overlay
    var center: CenterContainer
    for child in overlay.get_children():
        if child is CenterContainer:
            center = child
            break
    if not is_instance_valid(center):
        return
    var panel: PanelContainer = center.get_child(0)
    var column: VBoxContainer = panel.get_child(0)
    var title: Label = column.get_child(0)
    var effects: CheckBox = column.get_child(1)
    var status: Label = column.get_child(2)
    var close: Button = column.get_child(3)
    if not overlay.has_meta("ui_options_styled"):
        var shade: ColorRect = overlay.get_child(0)
        var copy := BackBufferCopy.new()
        copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
        overlay.add_child(copy)
        overlay.move_child(copy,0)
        shade.material = Completion.overlay_material()
        shade.material.set_shader_parameter("progress",1.0)
        shade.color = Color.WHITE
        overlay.set_meta("ui_options_styled",true)
    var factor := maxf(T.OPTIONS_MODAL.minimum_scale,minf(game.size.x/T.canvas().x,game.size.y/T.canvas().y))
    var height: float = T.unit(T.OPTIONS_MODAL.toggle_height)*factor
    panel.custom_minimum_size.x = minf(T.unit(T.OPTIONS_MODAL.width)*factor,game.size.x-T.unit(T.OPTIONS_MODAL.viewport_margin)*2.0)
    panel.add_theme_stylebox_override("panel",Shared.card(T.unit(T.OPTIONS_MODAL.width)*factor,T.OPTIONS_MODAL.padding*factor,T.OPTIONS_MODAL.radius*factor))
    column.add_theme_constant_override("separation",roundi(T.unit(T.OPTIONS_MODAL.gap)*factor))
    title.add_theme_font_override("font",V.DISPLAY)
    title.add_theme_font_size_override("font_size",roundi(T.unit(T.OPTIONS_MODAL.title_font)*factor))
    title.add_theme_color_override("font_color",V.BLUE)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    effects.custom_minimum_size.y = height
    effects.add_theme_font_override("font",V.HUD)
    effects.add_theme_font_size_override("font_size",roundi(T.unit(T.OPTIONS_MODAL.label_font)*factor))
    effects.add_theme_constant_override("h_separation",roundi(T.unit(T.OPTIONS_MODAL.toggle_gap)*factor))
    effects.add_theme_constant_override("check_v_offset",0)
    effects.add_theme_constant_override("icon_max_width",roundi(T.unit(T.OPTIONS_MODAL.check_size)*factor))
    for state in ["normal","hover","pressed","disabled"]:
        effects.add_theme_stylebox_override(state,Shared.card(height,T.OPTIONS_MODAL.toggle_padding*factor,T.SHELL.radius*factor))
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        effects.add_theme_color_override(state,V.BLUE)
    effects.add_theme_stylebox_override("focus",V.box(Color.TRANSPARENT,roundi(T.unit(T.SHELL.radius)*factor),0,V.BLUE))
    for state in ["checked","unchecked","checked_disabled","unchecked_disabled"]:
        effects.add_theme_icon_override(state,check_icon(state.begins_with("checked"),roundi(T.unit(T.OPTIONS_MODAL.check_size)*factor)))
    status.add_theme_font_override("font",V.HUD)
    status.add_theme_font_size_override("font_size",roundi(T.unit(T.OPTIONS_MODAL.status_font)*factor))
    status.add_theme_color_override("font_color",V.MUTED)
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    Shared.button(close,true,T.OPTIONS_MODAL.close_height*factor)
    close.add_theme_font_size_override("font_size",roundi(T.unit(T.SHELL.font)*factor))
