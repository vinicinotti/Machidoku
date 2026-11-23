extends Control
## Development-only gallery. No Main, save, puzzle generation or input router.
const V = preload("res://scripts/visuals.gd")
const State = preload("res://scripts/game_state.gd")
const CellScene = preload("res://scenes/Cell.tscn")
const SECTORS := ["stamping", "welding", "painting", "electrical", "assembly", "inspection", "logistics", "testing", "powertrain"]
const UI := ["back", "restart", "life", "error", "check", "lock", "factory", "car", "dropdown"]
var scroll: ScrollContainer
var page: VBoxContainer
var grids: Array[GridContainer] = []

func _ready() -> void:
    get_window().content_scale_size = Vector2i.ZERO
    theme = V.make_theme()
    RenderingServer.set_default_clear_color(V.CREAM)
    V.background(self)
    var margin := V.margin(24)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    scroll = ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    margin.add_child(scroll)
    page = VBoxContainer.new()
    page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page.add_theme_constant_override("separation", 20)
    scroll.add_child(page)
    page.add_child(V.brand(34, 48))
    page.add_child(V.label("IDENTIDADE VISUAL · GALERIA DE DESENVOLVIMENTO", "HudLabel", 12, V.MUTED))
    var intro := V.label("Arte gerada com transparência, ícones SVG e UI nativa. Role para comparar os estados.", "", 15, V.MUTED)
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    page.add_child(intro)
    var art := section("Marca, especialista e linha automotiva")
    art.add_child(asset_card("branding/machidoku_logo.svg", "Emblema · wordmark nativo acima", 112))
    art.add_child(asset_card("specialists/stamping.tres", "Especialista · PNG com alpha", 156))
    for vehicle in ["hatch_compact", "sedan", "suv", "sport_coupe"]:
        art.add_child(asset_card("vehicles/%s.png" % vehicle, vehicle.replace("_", " ").capitalize(), 130))
    var portraits := section("Especialistas por setor")
    for key in preload("res://scripts/specialist_art.gd").KEYS:
        portraits.add_child(asset_card("specialists/%s.tres"%key,key.capitalize(),120))
    var palette := section("Paleta oficial e 12 cores de setores")
    for color in [V.CREAM, V.ORANGE, V.CORAL, V.BLUE, V.DARK]:
        palette.add_child(swatch(color))
    for color in V.SECTORS:
        palette.add_child(swatch(color))
    var cells := section("Células nativas · volume, anotações e estados")
    var names := ["Vazia", "X normal", "X de erro", "Especialista", "Especialista fixo"]
    var states := [State.CellState.EMPTY, State.CellState.X, State.CellState.ERROR_X, State.CellState.SPECIALIST, State.CellState.PREPLACED_SPECIALIST]
    for i in range(states.size()):
        var content := VBoxContainer.new()
        var center := CenterContainer.new()
        content.add_child(center)
        var cell = CellScene.instantiate()
        cell.region_color = V.SECTORS[i]
        cell.custom_minimum_size = Vector2(72, 72)
        cell.state = states[i]
        cell.locked_error = states[i] == State.CellState.ERROR_X
        center.add_child(cell)
        var caption := V.label(names[i], "HudLabel", 12, V.BLUE)
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        content.add_child(caption)
        cells.add_child(wrap_card(content))
    var icons := section("Ícones industriais · 24 / 48 px")
    for sector in SECTORS:
        icons.add_child(asset_card("sectors/%s.svg" % sector, sector.capitalize(), 48, true))
    var rules := section("Regras · mesma família de ícones")
    for rule in ["one_per_sector", "one_per_row_column", "no_touching"]:
        rules.add_child(asset_card("rules/%s.svg" % rule, rule.replace("_", " "), 48, true))
    var ui := section("Ícones de interface · 24 / 40 px")
    for icon in UI:
        ui.add_child(asset_card("ui/icon_%s.svg" % icon, icon.capitalize(), 40, true))
    var buttons := section("Botões · normal, hover, pressed, disabled e foco")
    for kind in ["Button", "SecondaryButton", "DangerButton"]:
        for state in ["normal", "hover", "pressed", "disabled", "focus"]:
            var button := Button.new()
            button.text = state.capitalize()
            button.custom_minimum_size.y = 48
            button.theme_type_variation = kind
            button.disabled = state == "disabled"
            if state == "focus":
                var focused: StyleBox = theme.get_stylebox("normal", kind).duplicate()
                button.add_theme_stylebox_override("normal", focused)
            elif state not in ["normal", "disabled"]:
                button.add_theme_stylebox_override("normal", theme.get_stylebox(state, kind))
            button.tooltip_text = "%s / %s" % [kind, state]
            buttons.add_child(button)
    var lives := section("Cards e vidas · preenchido / contorno")
    for count in [3, 2, 1, 0]:
        var content := VBoxContainer.new()
        content.add_child(V.label("%d vida(s)" % count, "HudLabel", 13))
        var indicator := Control.new()
        indicator.set_script(preload("res://scripts/life_indicator.gd"))
        indicator.set_lives(count)
        content.add_child(indicator)
        lives.add_child(wrap_card(content))
    var decor := section("Ambiente ilustrado e decoração vetorial")
    decor.add_child(asset_card("decoration/factory_courtyard_v2.png", "Pátio industrial · PNG com alpha", 120))
    decor.add_child(asset_card("decoration/industrial_shapes.svg", "Formas de celebração · SVG", 100))
    resized.connect(responsive)
    responsive()

func section(title: String) -> GridContainer:
    var label := V.label(title, "HeadingLabel", 20, V.BLUE)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    page.add_child(label)
    var grid := GridContainer.new()
    grid.columns = 5
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    page.add_child(grid)
    grids.append(grid)
    return grid

func wrap_card(content: Control) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", V.material(V.PAPER, 18, 12))
    panel.add_child(content)
    return panel

func asset_card(path: String, caption: String, height: int, small: bool = false) -> PanelContainer:
    var content := VBoxContainer.new()
    content.add_child(V.texture("res://assets/" + path, Vector2(0, height)))
    if small:
        content.add_child(V.texture("res://assets/" + path, Vector2(0, 24)))
    var label := V.label(caption, "HudLabel", 12, V.BLUE)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    content.add_child(label)
    return wrap_card(content)

func swatch(color: Color) -> PanelContainer:
    var content := VBoxContainer.new()
    var chip := Panel.new()
    chip.custom_minimum_size.y = 34
    chip.add_theme_stylebox_override("panel", V.box(color, 10, 0))
    content.add_child(chip)
    content.add_child(V.label("#" + color.to_html(false).to_upper(), "HudLabel", 12, V.BLUE))
    return wrap_card(content)

func responsive() -> void:
    for grid in grids:
        grid.columns = 5 if size.x >= 1050 else 3 if size.x >= 660 else 2
