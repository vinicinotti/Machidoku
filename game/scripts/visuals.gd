extends RefCounted
## All visual tokens and typography live here. World art is configured separately.

const CREAM := Color("#FFE6CF")
const ORANGE := Color("#FF871C")
const CORAL := Color("#E76F51")
const BLUE := Color("#07365A")
const DARK := Color("#07244B")
const PAPER := Color("#FFF7ED")
const MUTED := Color("#416D7C")
const WARM_SHADOW := Color("#C5824C33")
const HIGHLIGHT := Color("#FFFCF7")
const CARD_RADIUS := 24
const CELL_RADIUS_RATIO := 0.20
const FRAME := Color("#073A53")
const ACTION := Color("#FF681B")
const GOLD := Color("#FFDC47")
const DESKTOP_CANVAS := Vector2(1672, 941)
const SPACE := 12
const SECTORS = preload("res://scripts/sector_palette.gd").COLORS
const REGULAR = preload("res://assets/fonts/Roboto-Regular.ttf")
const MEDIUM = preload("res://assets/fonts/Roboto-Medium.ttf")
const BOLD = preload("res://assets/fonts/Roboto-Bold.ttf")
const DISPLAY = preload("res://assets/fonts/BarlowSemiCondensed-ExtraBold.ttf")
const WORDMARK = preload("res://assets/fonts/BarlowSemiCondensed-Black.ttf")
const HUD = preload("res://assets/fonts/BarlowSemiCondensed-SemiBold.ttf")
static var _wordmark_font: FontVariation
const DIFFICULTIES := {"easy": "FÁCIL", "normal": "NORMAL", "hard": "DIFÍCIL", "very_hard": "MUITO DIFÍCIL"}
static var _materials := {}

static func desktop_surface(color: Color = PAPER, radius: int = 24, padding: int = 12, shadow: bool = true) -> StyleBoxTexture:
    # Square source leaves enough room for every nine-patch corner. The old
    # 72px source let top/bottom slices overlap and stretched the lower curves.
    var key := "desktop:%s:%d:%s" % [color.to_html(),radius,str(shadow)]
    if not _materials.has(key):
        var top := color.lightened(0.24)
        var bottom := color.darkened(0.09) if color.s > 0.45 else color
        var opacity := "1" if color.s > 0.45 else "0.88"
        var shade := '<rect x="3" y="6" width="250" height="248" rx="%d" fill="#634632" opacity="0.10"/>' % radius if shadow else ""
        var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><defs><linearGradient id="face" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs>%s<rect x="3" y="3" width="250" height="248" rx="%d" fill="url(#face)" fill-opacity="%s" stroke="#FFFCF7" stroke-width="1.5"/><rect x="6" y="6" width="244" height="242" rx="%d" fill="none" stroke="white" stroke-opacity="0.15"/></svg>' % [top.to_html(false),bottom.to_html(false),shade,radius,opacity,maxi(1,radius-3)]
        var img := Image.new()
        img.load_svg_from_string(svg)
        _materials[key] = ImageTexture.create_from_image(img)
    var style := StyleBoxTexture.new()
    style.texture = _materials[key]
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
        style.set_texture_margin(side,radius+6)
        style.set_content_margin(side,padding)
    return style

static func circular_action(color: Color) -> StyleBoxTexture:
    var key := "circle:%s" % color.to_html()
    if not _materials.has(key):
        var img := Image.new()
        img.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="66" height="66"><defs><linearGradient id="f" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><circle cx="33" cy="35" r="30" fill="#8C471C" opacity="0.20"/><circle cx="33" cy="33" r="31" fill="url(#f)" stroke="#FFF7ED" stroke-width="1.5"/><path d="M14 15Q33 2 52 15" fill="none" stroke="white" opacity="0.35"/></svg>' % [color.lightened(0.25).to_html(false),color.darkened(0.08).to_html(false)])
        _materials[key] = ImageTexture.create_from_image(img)
    var style := StyleBoxTexture.new()
    style.texture = _materials[key]
    style.set_content_margin_all(8)
    return style

static func surface(color: Color = PAPER, radius: int = 22, padding: int = 12, shadow: bool = true) -> StyleBoxTexture:
    # One face, one edge and one soft shadow. No stacked lower ledges.
    var key := "surface:%s:%d:%s" % [color.to_html(),radius,str(shadow)]
    if not _materials.has(key):
        var top := color.lightened(0.25 if color.s > 0.45 else 0.14)
        var bottom := color.darkened(0.13 if color.s > 0.45 else 0.04)
        if color.s < 0.35 and color.v > 0.85:
            top = color.lightened(0.70)
            bottom = color.lightened(0.12)
        var shadows := '<rect x="1" y="6" width="126" height="64" rx="%d" fill="#654937" fill-opacity="0.045"/><rect x="2" y="5" width="124" height="64" rx="%d" fill="#654937" fill-opacity="0.075"/>' % [radius+1,radius] if shadow else ""
        var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="72" viewBox="0 0 128 72"><defs><linearGradient id="face" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="0.34" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs>%s<rect x="2" y="2" width="124" height="64" rx="%d" fill="url(#face)" stroke="#FFFEF5" stroke-width="1.5"/><path d="M15 11Q64 2 113 11" fill="none" stroke="#FFFFFF" stroke-opacity="0.27" stroke-width="1" stroke-linecap="round"/></svg>' % [top.to_html(false),color.to_html(false),bottom.to_html(false),shadows,radius]
        var image := Image.new()
        image.load_svg_from_string(svg)
        _materials[key] = ImageTexture.create_from_image(image)
    var style := StyleBoxTexture.new()
    style.texture = _materials[key]
    for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
        style.set_texture_margin(side,clampi(radius+5,6,34))
        style.set_content_margin(side,padding)
    return style

static func material(color: Color = PAPER, radius: int = 24, padding: int = 16, pressed: bool = false) -> StyleBoxTexture:
    # A cached procedural SVG nine-patch: native Controls retain layout/input.
    var key := "%s:%d:%s" % [color.to_html(), radius, str(pressed)]
    if not _materials.has(key):
        var top := color.lightened(0.20 if color.get_luminance() >= 0.3 else 0.10)
        var bottom := color.darkened(0.08)
        var edge := color.darkened(0.30)
        if color.get_luminance() > 0.7 and color.s < 0.20:
            top = Color("#FFFCF5")
            bottom = Color("#FFECD7")
            edge = Color("#EFB778")
        var depth := 2 if pressed else 5
        var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><defs><linearGradient id="face" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="2" y="%d" width="124" height="120" rx="%d" fill="#8C471C" fill-opacity="0.16"/><rect x="2" y="2" width="124" height="120" rx="%d" fill="#%s"/><rect x="3" y="2" width="122" height="%d" rx="%d" fill="url(#face)" stroke="#FFFDF4" stroke-width="2"/><rect x="6" y="5" width="116" height="%d" rx="%d" fill="none" stroke="#FFFFFF" stroke-opacity="0.32" stroke-width="1"/></svg>' % [top.to_html(false), bottom.to_html(false), depth + 2, radius, radius, edge.to_html(false), 120 - depth, radius, 113 - depth, maxi(1, radius - 3)]
        var image := Image.new()
        image.load_svg_from_string(svg)
        _materials[key] = ImageTexture.create_from_image(image)
    var style := StyleBoxTexture.new()
    style.texture = _materials[key]
    for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
        style.set_texture_margin(side, clampi(radius + (11 if side == SIDE_BOTTOM else 3), 4, 48))
        style.set_content_margin(side, padding)
    return style

static func box(color: Color, radius: int = 14, padding: int = 16, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(radius)
    style.content_margin_left = padding
    style.content_margin_right = padding
    style.content_margin_top = padding
    style.content_margin_bottom = padding
    style.border_color = border
    style.set_border_width_all(1 if border.a > 0 else 0)
    style.corner_detail = 12
    style.anti_aliasing = true
    return style

static func card(color: Color = PAPER, radius: int = CARD_RADIUS, padding: int = 20) -> StyleBoxFlat:
    var style := box(color, radius, padding, HIGHLIGHT)
    style.border_width_top = 2
    style.border_width_bottom = 1
    style.shadow_color = WARM_SHADOW
    style.shadow_size = 5
    style.shadow_offset = Vector2(0, 4)
    return style

static func button_surface(color: Color, pressed: bool = false) -> StyleBoxFlat:
    var style := box(color, 23, 14, color.darkened(0.14))
    style.border_width_top = 1
    style.border_width_left = 1
    style.border_width_right = 1
    style.border_width_bottom = 2 if pressed else 4
    style.shadow_color = Color(WARM_SHADOW, 0.04 if pressed else 0.10)
    style.shadow_size = 2 if pressed else 6
    style.shadow_offset = Vector2(0, 1 if pressed else 4)
    if pressed:
        style.content_margin_top = 16
        style.content_margin_bottom = 12
    return style

static func make_theme() -> Theme:
    var result := Theme.new()
    result.default_font = REGULAR
    result.default_font_size = 18
    result.set_color("font_color", "Label", DARK)
    result.set_color("font_color", "Button", DARK)
    result.set_color("font_hover_color", "Button", DARK)
    result.set_color("font_pressed_color", "Button", DARK)
    result.set_color("font_focus_color", "Button", DARK)
    result.set_font("font", "Button", MEDIUM)
    result.set_font_size("font_size", "Button", 18)
    result.set_constant("icon_max_width", "Button", 21)
    result.set_constant("h_separation", "Button", 8)
    result.set_color("font_disabled_color", "Button", Color(MUTED, 0.7))
    for kind in ["Button", "SecondaryButton", "DangerButton"]:
        if kind != "Button":
            result.set_type_variation(kind, "Button")
        var color: Color = ACTION if kind == "Button" else PAPER if kind == "SecondaryButton" else CORAL
        result.set_stylebox("normal", kind, material(color, 16, 15))
        result.set_stylebox("hover", kind, material(color.lightened(0.07), 16, 15))
        result.set_stylebox("pressed", kind, material(color.darkened(0.055), 16, 15, true))
        result.set_stylebox("focus", kind, box(Color.TRANSPARENT, 16, 15, BLUE))
        result.set_stylebox("disabled", kind, material(CREAM.lerp(PAPER, 0.45), 16, 15, true))
    for kind in ["Button", "DangerButton"]:
        for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
            result.set_color(state, kind, HIGHLIGHT)
        result.set_font("font", kind, BOLD)
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        result.set_color(state,"SecondaryButton",DARK)
    result.set_stylebox("panel", "PanelContainer", material())
    result.set_constant("separation", "VBoxContainer", 12)
    result.set_constant("separation", "HBoxContainer", 12)
    for variation in ["TitleLabel", "HeadingLabel", "HudLabel"]:
        result.set_type_variation(variation, "Label")
        result.set_font("font", variation, HUD if variation == "HudLabel" else DISPLAY)
    result.set_font_size("font_size", "TitleLabel", 48)
    result.set_font_size("font_size", "HeadingLabel", 28)
    result.set_font_size("font_size", "HudLabel", 18)
    return result

static func board_bezel() -> StyleBoxTexture:
    var style := material(FRAME, 27, 16)
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style

static func board_rim() -> StyleBoxTexture:
    return surface(PAPER, 30, 8)

static func board_tray() -> StyleBoxFlat:
    var style := box(BLUE.darkened(0.23), 15, 3, BLUE.lightened(0.12))
    style.border_width_top = 3
    return style

static func icon_badge(color: Color, icon_path: String, side: int = 36) -> PanelContainer:
    var badge := PanelContainer.new()
    badge.custom_minimum_size = Vector2.ONE * side
    var style := material(color, 15, 6)
    badge.add_theme_stylebox_override("panel", style)
    badge.add_child(texture(icon_path, Vector2.ONE * (side - 10)))
    return badge

static func label(text: String, variation: String = "", size: int = 0, color: Color = DARK) -> Label:
    var node := Label.new()
    node.text = text
    if not variation.is_empty():
        node.theme_type_variation = variation
    if size > 0:
        node.add_theme_font_size_override("font_size", size)
        node.set_meta("reference_font_size", size)
    node.add_theme_color_override("font_color", color)
    return node

static func scale_type(parent: Node, factor: float) -> void:
    for child in parent.get_children():
        if child is Label and child.has_meta("reference_font_size"):
            child.add_theme_font_size_override("font_size", roundi(float(child.get_meta("reference_font_size")) * factor))
        scale_type(child, factor)

static func button(text: String, action: Callable, secondary: bool = false, icon_name: String = "") -> Button:
    var node := Button.new()
    node.text = text
    node.custom_minimum_size.y = 50
    node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    if secondary:
        node.theme_type_variation = "SecondaryButton"
    if not icon_name.is_empty():
        var icon_file := "restart_action" if icon_name == "restart" and not secondary else icon_name
        node.icon = load("res://assets/ui/icon_%s.svg" % icon_file)
    node.pressed.connect(action)
    return node

static func brand(font_size: int = 24, symbol_size: int = 36) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 10)
    row.add_child(texture("res://assets/branding/machidoku_symbol.svg", Vector2.ONE * symbol_size))
    var wordmark := label("MACHIDOKU", "TitleLabel", font_size, DARK)
    if _wordmark_font == null:
        _wordmark_font = FontVariation.new()
        _wordmark_font.base_font = WORDMARK
        _wordmark_font.spacing_glyph = 1
    wordmark.add_theme_font_override("font", _wordmark_font)
    row.add_child(wordmark)
    return row

static func background(parent: Control) -> void:
    var decoration := Control.new()
    decoration.set_script(preload("res://scripts/background.gd"))
    decoration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    decoration.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(decoration)

static func margin(amount: int = 24) -> MarginContainer:
    var node := MarginContainer.new()
    for edge in ["left", "right", "top", "bottom"]:
        node.add_theme_constant_override("margin_" + edge, amount)
    return node

static func texture(path: String, minimum: Vector2) -> TextureRect:
    var node := TextureRect.new()
    node.texture = load(path)
    node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    node.custom_minimum_size = minimum
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return node
