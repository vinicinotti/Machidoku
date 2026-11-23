extends Control

signal menu_requested
signal retry_requested
signal next_requested
signal level_completed(errors: int)

const V = preload("res://scripts/visuals.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
const State = preload("res://scripts/game_state.gd")
const BoardScene = preload("res://scenes/Board.tscn")
const Gears = preload("res://scripts/gear_indicator.gd")
const Progress = preload("res://scripts/progress_store.gd")
const Layout = preload("res://scripts/game_layout.gd")
const Strip = preload("res://scripts/specialist_strip.gd")
const Badge = preload("res://scripts/difficulty_badge.gd")
const ScorePopup = preload("res://scripts/score_popup.gd")
const Glass = preload("res://scripts/glass_surface.gd")

var level: Dictionary
var is_last := false
var total_levels := 0
var product_phase := 0
var product_total := 0
var unlocked_product := ""
var model
var board
var lives_label: Control
var feedback: Label
var sidebar: PanelContainer
var mobile_cards: VBoxContainer
var mobile_details: PanelContainer
var mobile_content: VBoxContainer
var plant_button: Button
var production_button: Button
var menu_button: Button
var restart_button: Button
var mobile_open := ""
var popup: Control
var result_panel: PanelContainer
var result_title: Label
var result_column: VBoxContainer
var result_vehicle: Control
var brand_row: HBoxContainer
var product_title: Label
var phase_icon: TextureRect
var phase_caption: Label
var page_margin: MarginContainer
var rule_labels: Array[Label] = []
var rule_icons: Array[TextureRect] = []
var rule_cards: Array[PanelContainer] = []
var sector_rows: Array[PanelContainer] = []
var sector_badges: Array[PanelContainer] = []
var controls_card: PanelContainer
var controls_label: Label
var message_card: PanelContainer
var difficulty_label: Label
var lives_caption: Label
var plant_icon: TextureRect
var title_row: HBoxContainer
var board_column: VBoxContainer
var rules_row: GridContainer
var rules_rail: Control
var product_heading: VBoxContainer
var lives_box: HBoxContainer
const RULE_CAPTIONS := ["1 por setor", "1 por linha e coluna", "Sem se tocar"]
const COMPACT_RULE_CAPTIONS := ["1 por\nsetor", "1 por linha\ne coluna", "Sem se\ntocar"]
var previous_lives := State.STARTING_LIVES
var life_tween: Tween
var result_tween: Tween
var pending_save_warning := false
var completion_receipt: Dictionary = {}
var season_block_message := ""
var score_label: Label
var score_popups: Array[Control] = []
var board_mount: AspectRatioContainer
var brand_center: CenterContainer
var top_actions: HBoxContainer
var score_row: HBoxContainer
var desktop_stage: Control
var specialist_strip
var difficulty_badge
var options_button: Button
var options_overlay: Control
var progress_store
var preview_reduce_motion := false
var message_icon: TextureRect
var left_glass: ColorRect
var right_glass: ColorRect
var glass_backdrop: BackBufferCopy
var lives_card: PanelContainer
var production_panel: PanelContainer
var plant_heading: HBoxContainer
var plant_captions: VBoxContainer
var sidebar_layout: Control
var controls_row: HBoxContainer

func reduced_motion() -> bool:
    return bool(progress_store.data.settings.get("reduce_motion", false)) if progress_store != null else preview_reduce_motion

func show_options() -> void:
    if is_instance_valid(options_overlay):
        return
    board.router.cancel()
    model.set_clock_active(false)
    options_overlay = Control.new()
    options_overlay.name = "OptionsOverlay"
    options_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    options_overlay.z_index = 30
    add_child(options_overlay)
    var shade := ColorRect.new()
    shade.color = Color(V.DARK,0.55)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    options_overlay.add_child(shade)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    options_overlay.add_child(center)
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = minf(360,size.x-32)
    panel.add_theme_stylebox_override("panel",V.material(V.PAPER,24,20))
    center.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    column.add_child(V.label("Configurações","HeadingLabel",26,V.DARK))
    var effects := CheckBox.new()
    effects.text = "Efeitos reduzidos"
    for state in ["normal","hover","pressed","disabled"]:
        effects.add_theme_stylebox_override(state,V.box(Color.TRANSPARENT,8,8))
    for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
        effects.add_theme_color_override(state,V.DARK)
    effects.button_pressed = reduced_motion()
    column.add_child(effects)
    var status := V.label("Pop e movimento mais discretos.","",14,V.MUTED)
    column.add_child(status)
    effects.toggled.connect(func(value: bool):
        if progress_store == null:
            preview_reduce_motion = value
        else:
            var previous: bool = reduced_motion()
            progress_store.data.settings.reduce_motion = value
            if not progress_store.save():
                progress_store.data.settings.reduce_motion = previous
                effects.set_pressed_no_signal(previous)
                status.text = "Não foi possível salvar a opção."
        responsive_layout())
    var close := V.button("Fechar",func():
        options_overlay.queue_free()
        options_overlay = null
        sync_score_clock())
    close.name = "CloseOptions"
    column.add_child(close)
    close.grab_focus()
    preload("res://scripts/ui_options.gd").apply(self)

func _ready() -> void:
    model = State.new(level)
    build_ui()
    model.changed.connect(update_hud)
    model.finished.connect(show_result)
    model.score_changed.connect(func(_value: int): update_score_hud())
    model.operator_scored.connect(show_operator_points)
    update_hud()
    resized.connect(responsive_layout)
    responsive_layout()
    call_deferred("responsive_layout")
    sync_score_clock()

func sync_score_clock() -> void:
    if model != null and is_inside_tree():
        model.set_clock_active(not get_tree().paused and get_window().has_focus() and not is_instance_valid(options_overlay))

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED:
        if model != null:
            model.set_clock_active(false)
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_UNPAUSED:
        sync_score_clock()

func build_ui() -> void:
    V.background(self)
    glass_backdrop = BackBufferCopy.new()
    glass_backdrop.name = "GlassBackdrop"
    glass_backdrop.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
    add_child(glass_backdrop)
    var margin := V.margin(16)
    page_margin = margin
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.name = "PageScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    margin.add_child(scroll)
    var page := VBoxContainer.new()
    page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    page.size_flags_vertical = Control.SIZE_EXPAND_FILL
    page.add_theme_constant_override("separation", 10)
    scroll.add_child(page)
    var top := Control.new()
    top.name = "TopBar"
    page.add_child(top)
    brand_center = CenterContainer.new()
    brand_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    brand_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top.add_child(brand_center)
    brand_row = V.brand(19, 30)
    brand_center.add_child(brand_row)
    top_actions = HBoxContainer.new()
    top_actions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    top_actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Actions are a sibling overlay so the wordmark stays truly centered.
    top.add_child(top_actions)
    menu_button = V.button("Menu", func(): menu_requested.emit(), true, "back")
    menu_button.name = "MenuButton"
    menu_button.tooltip_text = "Voltar ao menu"
    menu_button.custom_minimum_size.y = 44
    top_actions.add_child(menu_button)
    var top_space := Control.new()
    top_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
    top_actions.add_child(top_space)
    options_button = V.button("", show_options, false, "settings")
    options_button.name = "OptionsButton"
    options_button.tooltip_text = "Configurações"
    options_button.custom_minimum_size = Vector2(44,44)
    top_actions.add_child(options_button)
    restart_button = V.button("Reiniciar", func(): retry_requested.emit(), false, "restart")
    restart_button.tooltip_text = "Reiniciar fase"
    restart_button.custom_minimum_size.y = 44
    top_actions.add_child(restart_button)
    title_row = HBoxContainer.new()
    page.add_child(title_row)
    var heading := VBoxContainer.new()
    product_heading = heading
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    heading.add_theme_constant_override("separation", 3)
    title_row.add_child(heading)
    var phase_row := HBoxContainer.new()
    phase_row.add_theme_constant_override("separation", 7)
    heading.add_child(phase_row)
    phase_icon = V.texture(Worlds.vehicle(level), Vector2(52, 30))
    phase_row.add_child(phase_icon)
    phase_caption = V.label("%s  /  FASE %02d DE %02d" % [Worlds.world(level.world).name, int(level.id), total_levels], "HudLabel", 11, V.MUTED)
    if product_total > 0:
        phase_caption.text = "%s  /  FASE %02d · %02d DE %02d" % [Worlds.world(level.world).name, int(level.id), product_phase, product_total]
    phase_row.add_child(phase_caption)
    product_title = V.label(level.vehicle_name, "HeadingLabel", 26)
    heading.add_child(product_title)
    lives_box = HBoxContainer.new()
    lives_box.alignment = BoxContainer.ALIGNMENT_CENTER
    lives_box.add_theme_constant_override("separation", 5)
    title_row.add_child(lives_box)
    lives_caption = V.label("VIDAS", "HudLabel", 11, V.MUTED)
    lives_box.add_child(lives_caption)
    lives_label = Control.new()
    lives_label.set_script(preload("res://scripts/life_indicator.gd"))
    lives_label.name = "Lives"
    lives_box.add_child(lives_label)
    var rules := GridContainer.new()
    rules.columns = 3
    rules_row = rules
    rules.name = "RuleCards"
    rules.add_theme_constant_override("h_separation", 8)
    rules.add_theme_constant_override("v_separation", 8)
    for rule in [["one_per_sector", "1 por\nsetor"], ["one_per_row_column", "1 por linha\ne coluna"], ["no_touching", "Sem se\ntocar"]]:
        var card := PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_stylebox_override("panel", V.material(V.PAPER, 16, 7))
        rules.add_child(card)
        rule_cards.append(card)
        var item := HBoxContainer.new()
        item.add_theme_constant_override("separation", 6)
        var icon := V.texture("res://assets/rules/%s.svg" % rule[0], Vector2(24, 24))
        item.add_child(icon)
        rule_icons.append(icon)
        var caption := V.label(rule[1], "HudLabel", 12, V.BLUE)
        item.add_child(caption)
        rule_labels.append(caption)
        card.add_child(item)
    var body := HBoxContainer.new()
    body.name = "GameBody"
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 20)
    page.add_child(body)
    rules_rail = Control.new()
    rules_rail.name = "RulesRail"
    body.add_child(rules_rail)
    left_glass = Glass.new()
    rules_rail.add_child(left_glass)
    left_glass.offset_left = -12
    left_glass.offset_top = -12
    left_glass.offset_right = 12
    left_glass.offset_bottom = 12
    lives_card = PanelContainer.new()
    lives_card.name = "LivesCard"
    lives_card.add_theme_stylebox_override("panel",V.surface(V.PAPER,24,12))
    rules_rail.add_child(lives_card)
    board_column = VBoxContainer.new()
    board_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    board_column.add_theme_constant_override("separation", 6)
    body.add_child(board_column)
    board_column.add_child(rules)
    var board_heading := HBoxContainer.new()
    score_row = board_heading
    board_column.add_child(board_heading)
    difficulty_badge = Badge.new()
    difficulty_badge.difficulty = level.difficulty
    board_heading.add_child(difficulty_badge)
    difficulty_label = difficulty_badge.caption
    score_label = V.label("Pontos: 0", "HudLabel", 12, V.BLUE)
    score_label.name = "RunScore"
    score_label.tooltip_text = "Pontos por especialistas. Os X entram no resultado final."
    score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    board_heading.add_child(score_label)
    var board_center := AspectRatioContainer.new()
    board_mount = board_center
    board_center.ratio = 1.0
    board_center.custom_minimum_size.y = 278
    board_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
    board_center.stretch_mode = AspectRatioContainer.STRETCH_FIT
    board_column.add_child(board_center)
    var frame := PanelContainer.new()
    frame.add_theme_stylebox_override("panel", V.board_rim())
    board_center.add_child(frame)
    var bezel := PanelContainer.new()
    bezel.add_theme_stylebox_override("panel", V.board_bezel())
    frame.add_child(bezel)
    var tray := PanelContainer.new()
    tray.add_theme_stylebox_override("panel", V.board_tray())
    bezel.add_child(tray)
    board = BoardScene.instantiate()
    var presentation := preload("res://scripts/board_presentation.gd").new()
    tray.add_child(presentation)
    board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    presentation.surface.add_child(board)
    board.setup(model)
    specialist_strip = Strip.new()
    specialist_strip.name = "SpecialistStrip"
    board_column.add_child(specialist_strip)
    board_column.move_child(specialist_strip, 2)
    specialist_strip.custom_minimum_size.y = 64
    specialist_strip.setup(model, board.region_colors)
    controls_card = PanelContainer.new()
    controls_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls_card.add_theme_stylebox_override("panel", V.box(Color(V.PAPER, 0.65), 13, 7))
    controls_label = V.label("Clique: X   ·   Duplo clique: especialista   ·   Arraste: vários X", "", 12, V.BLUE)
    controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    controls_row = HBoxContainer.new()
    controls_row.add_theme_constant_override("separation",14)
    controls_card.add_child(controls_row)
    controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    controls_row.add_child(controls_label)
    board_column.add_child(controls_card)
    build_sidebar(body)
    build_mobile_cards(page)
    var message := PanelContainer.new()
    message_card = message
    message.add_theme_stylebox_override("panel", V.material(V.PAPER, 18, 8))
    board_column.add_child(message)
    var message_row := HBoxContainer.new()
    message_row.add_theme_constant_override("separation", 10)
    message.add_child(message_row)
    message_icon = V.texture("res://assets/ui/icon_error.svg", Vector2(24,24))
    message_row.add_child(message_icon)
    feedback = V.label("Encontre os %d especialistas. Os X são suas anotações." % int(level.size), "", 13, V.BLUE)
    feedback.name = "Feedback"
    feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    feedback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    message_row.add_child(feedback)
    desktop_stage = Control.new()
    desktop_stage.name = "DesktopStage"
    desktop_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(desktop_stage)

func sector_list(columns: int = 1) -> GridContainer:
    var list := GridContainer.new()
    list.columns = columns
    list.add_theme_constant_override("h_separation", 12)
    list.add_theme_constant_override("v_separation", 8 if columns > 1 else 10)
    var metadata := Worlds.world(level.world)
    for region in range(int(level.size)):
        var row_card := PanelContainer.new()
        row_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row_card.size_flags_vertical = Control.SIZE_FILL
        row_card.add_theme_stylebox_override("panel", V.surface(V.PAPER, 14 if columns > 1 else 22, 3 if columns > 1 else 7))
        list.add_child(row_card)
        var item := HBoxContainer.new()
        item.add_theme_constant_override("separation", 6 if columns > 1 else 18)
        row_card.add_child(item)
        var icon: String = metadata.icons[region] if region < metadata.icons.size() else "assembly"
        var badge := V.icon_badge(board.region_colors[region], "res://assets/sectors/%s.svg" % icon, 32 if columns > 1 else 36)
        badge.add_theme_stylebox_override("panel",V.surface(board.region_colors[region],14,5,false))
        badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        item.add_child(badge)
        var sector_name: String = metadata.sectors[region] if region < metadata.sectors.size() else "Setor %02d" % (region + 1)
        var caption := V.label(sector_name, "", 13 if columns > 1 else 22)
        caption.add_theme_font_override("font",V.HUD)
        caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        item.add_child(caption)
        caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        var arrow := V.label("›", "", 26, V.BLUE)
        arrow.custom_minimum_size.x = 18
        arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        item.add_child(arrow)
        row_card.tooltip_text = "Destacar " + sector_name
        row_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        row_card.gui_input.connect(func(event: InputEvent):
            if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
                board.focus_region(region))
        if columns == 1:
            sector_rows.append(row_card)
            sector_badges.append(badge)
    return list

func production_card() -> VBoxContainer:
    var list := VBoxContainer.new()
    list.add_theme_constant_override("separation", 4)
    var aspect := AspectRatioContainer.new()
    aspect.name = "ProductionStage"
    aspect.ratio = 1.95
    aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
    aspect.custom_minimum_size.y = 155
    var stage := Control.new()
    stage.set_script(preload("res://scripts/production_stage.gd"))
    aspect.add_child(stage)
    var car := V.texture(Worlds.vehicle(level), Vector2.ZERO)
    car.name = "ProductionVehicle"
    car.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    car.offset_left = 3
    car.offset_right = -3
    car.offset_top = 0
    car.offset_bottom = -10
    stage.add_child(car)
    list.add_child(aspect)
    list.add_child(V.label(level.vehicle_name, "HeadingLabel", 28, V.BLUE))
    var note := V.label("Peça com cadeado: fixa.\nErros ficam marcados em coral.", "", 18, V.MUTED)
    note.name = "ProductionNote"
    note.add_theme_font_override("font",V.HUD)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    list.add_child(note)
    return list

func build_sidebar(parent: Control) -> void:
    sidebar = PanelContainer.new()
    sidebar.custom_minimum_size.x = 280
    sidebar.add_theme_stylebox_override("panel", V.box(Color.TRANSPARENT, 26, 18))
    parent.add_child(sidebar)
    var glass_mount := Control.new()
    glass_mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
    glass_mount.show_behind_parent = true
    sidebar.add_child(glass_mount)
    right_glass = Glass.new()
    glass_mount.add_child(right_glass)
    right_glass.offset_left = -22
    right_glass.offset_top = -22
    right_glass.offset_right = 22
    right_glass.offset_bottom = 22
    var list := Control.new()
    sidebar_layout = list
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 18)
    sidebar.add_child(list)
    plant_heading = HBoxContainer.new()
    plant_heading.add_theme_constant_override("separation", 20)
    plant_icon = V.texture("res://assets/ui/icon_factory.svg", Vector2(34, 34))
    plant_heading.add_child(plant_icon)
    plant_captions = VBoxContainer.new()
    plant_captions.add_theme_constant_override("separation",3)
    plant_heading.add_child(plant_captions)
    plant_captions.add_child(V.label("PLANTA INDUSTRIAL", "HeadingLabel", 24, V.DARK))
    plant_captions.add_child(V.label("%d setores · %d especialistas" % [int(level.size),int(level.size)],"",18,V.MUTED))
    list.add_child(plant_heading)
    var sector_scroll := ScrollContainer.new()
    sector_scroll.name = "SectorScroll"
    sector_scroll.custom_minimum_size.y = 64
    sector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    sector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    var scrollbar := sector_scroll.get_v_scroll_bar()
    scrollbar.add_theme_stylebox_override("scroll",V.box(Color(V.PAPER,0.3),3,0))
    for state in ["grabber","grabber_highlight","grabber_pressed"]:
        var thumb := V.box(Color(V.BLUE,0.28 if state == "grabber" else 0.48),3,0)
        thumb.set_content_margin_all(3)
        scrollbar.add_theme_stylebox_override(state,thumb)
    list.add_child(sector_scroll)
    var sectors := sector_list()
    sectors.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sectors.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    sector_scroll.add_child(sectors)
    sector_scroll.resized.connect(fit_sector_rows)
    var production := PanelContainer.new()
    production_panel = production
    production.add_theme_stylebox_override("panel", V.surface(Color("#FFE1BD"), 25, 9))
    list.add_child(production)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation",4)
    production.add_child(content)
    content.add_child(V.label("EM PRODUÇÃO", "HudLabel", 17, V.BLUE))
    content.add_child(production_card())

func fit_sector_rows() -> void:
    # Preserve card hierarchy and legibility; large plants scroll inside here.
    var badge_side := 48.0
    for i in range(sector_rows.size()):
        var skin := V.desktop_surface(V.PAPER,22,7)
        skin.content_margin_top = 7
        skin.content_margin_bottom = 7
        sector_rows[i].add_theme_stylebox_override("panel",skin)
        sector_rows[i].custom_minimum_size.y = 64
        sector_badges[i].custom_minimum_size = Vector2.ONE * badge_side
        sector_badges[i].get_child(0).custom_minimum_size = Vector2.ONE * (badge_side - 10)

func build_mobile_cards(parent: Control) -> void:
    mobile_cards = VBoxContainer.new()
    mobile_cards.add_theme_constant_override("separation", 8)
    parent.add_child(mobile_cards)
    var headers := HBoxContainer.new()
    headers.add_theme_constant_override("separation", 8)
    mobile_cards.add_child(headers)
    plant_button = V.button("PLANTA INDUSTRIAL", func(): toggle_mobile("plant"), true, "dropdown")
    production_button = V.button("EM PRODUÇÃO", func(): toggle_mobile("production"), true, "dropdown")
    plant_button.name = "PlantToggle"
    production_button.name = "ProductionToggle"
    for button in [plant_button, production_button]:
        button.custom_minimum_size.y = 40
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 11)
        button.add_theme_constant_override("icon_max_width", 16)
        button.add_theme_constant_override("h_separation", 5)
        headers.add_child(button)
    mobile_details = PanelContainer.new()
    mobile_details.add_theme_stylebox_override("panel", V.material(V.PAPER, 18, 14))
    mobile_details.visible = false
    mobile_cards.add_child(mobile_details)
    mobile_content = VBoxContainer.new()
    mobile_details.add_child(mobile_content)

func toggle_mobile(section: String) -> void:
    mobile_open = "" if mobile_open == section else section
    for child in mobile_content.get_children():
        mobile_content.remove_child(child)
        child.queue_free()
    mobile_details.visible = not mobile_open.is_empty()
    plant_button.text = "PLANTA INDUSTRIAL"
    production_button.text = "EM PRODUÇÃO"
    plant_button.tooltip_text = "Recolher planta" if mobile_open == "plant" else "Expandir planta"
    production_button.tooltip_text = "Recolher produção" if mobile_open == "production" else "Expandir produção"
    if mobile_open == "plant":
        mobile_content.add_child(V.label("%d setores · %d especialistas" % [int(level.size), int(level.size)], "HudLabel", 12, V.BLUE))
        mobile_content.add_child(sector_list(2))
    elif mobile_open == "production":
        mobile_content.add_child(production_card())

func responsive_layout() -> void:
    Layout.apply(self)
    preload("res://scripts/ui_options.gd").apply(self)
    if is_instance_valid(result_panel):
        result_panel.custom_minimum_size.x = minf(470, size.x - 36)
        result_title.add_theme_font_size_override("font_size", 26 if size.x < 520 else 29 if is_last else 32)
        result_panel.add_theme_stylebox_override("panel", V.material(V.PAPER, 24, 14 if size.y < 760 else 18))
        result_column.add_theme_constant_override("separation", 7 if size.y < 760 else 10 if size.y < 900 else 16)
        if is_instance_valid(result_vehicle):
            result_vehicle.custom_minimum_size.y = 80 if size.y < 760 else 100 if size.y < 900 else 130
        preload("res://scripts/ui_results.gd").apply(self)

func update_hud() -> void:
    lives_label.set_lives(model.lives)
    specialist_strip.refresh()
    if model.lives < previous_lives:
        if life_tween:
            life_tween.kill()
        lives_label.pivot_offset = lives_label.size / 2.0
        lives_label.scale = Vector2.ONE
        lives_label.modulate.a = 1.0
        life_tween = create_tween()
        life_tween.tween_property(lives_label, "scale", Vector2.ONE * 1.14, 0.07)
        life_tween.parallel().tween_property(lives_label, "modulate:a", 0.5, 0.07)
        life_tween.tween_property(lives_label, "scale", Vector2.ONE, 0.10)
        life_tween.parallel().tween_property(lives_label, "modulate:a", 1.0, 0.10)
        feedback.text = "Tentativa incorreta de especialista. O X vermelho permanece até reiniciar a fase."
        feedback.add_theme_color_override("font_color", V.CORAL.darkened(0.25))
    previous_lives = model.lives

func update_score_hud() -> void:
    # Showing live X points would expose solution cells through neutral notes.
    score_label.text = "Pontos: %d" % model.operator_score

func show_operator_points(points: int, streak: int, pos: Vector2i) -> void:
    var label := ScorePopup.new()
    label.points = points
    label.streak = streak
    label.reduced_motion = reduced_motion()
    label.z_index = 8
    board.add_child(label)
    var cell = board.cells[model.index(pos)]
    label.position = cell.position + (cell.size - label.size) / 2.0 + Vector2(cell.size.x * 0.4, -cell.size.y * 0.45)
    label.position.x = clampf(label.position.x, 0, maxf(0, board.size.x - label.size.x))
    label.position.y = maxf(0, label.position.y)
    score_popups = score_popups.filter(func(item): return is_instance_valid(item) and not item.is_queued_for_deletion())
    if score_popups.size() >= 3:
        score_popups.pop_front().queue_free()
    score_popups.append(label)

func show_result(won: bool) -> void:
    board.router.cancel()
    if won:
        level_completed.emit(State.STARTING_LIVES - model.lives)
        await preload("res://scripts/ui_completion.gd").play(self)
        if not is_inside_tree():
            return
    popup = Control.new()
    popup.name = "VictoryPopup" if won else "DefeatPopup"
    popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    popup.z_index = 20
    add_child(popup)
    var shade := ColorRect.new()
    shade.color = Color(V.DARK, 0.65)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    popup.add_child(shade)
    var margin := V.margin(18)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    popup.add_child(margin)
    var center := CenterContainer.new()
    margin.add_child(center)
    var panel := PanelContainer.new()
    result_panel = panel
    panel.custom_minimum_size.x = minf(470, size.x - 36)
    panel.add_theme_stylebox_override("panel", V.material(V.PAPER, 24, 18))
    center.add_child(panel)
    var column := VBoxContainer.new()
    result_column = column
    column.add_theme_constant_override("separation", 10 if size.y < 800 else 16)
    panel.add_child(column)
    var eyebrow := V.label("%s / FASE %02d" % [Worlds.world(level.world).name, int(level.id)], "HudLabel", 13, V.BLUE)
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(eyebrow)
    column.add_child(V.texture("res://assets/ui/icon_check.svg" if won else "res://assets/ui/icon_error.svg", Vector2(0, 32)))
    var title_text := "LINHA DE PRODUÇÃO\nCONCLUÍDA" if won and is_last else "PRODUÇÃO\nCONCLUÍDA" if won else "PRODUÇÃO\nINTERROMPIDA"
    var title := V.label(title_text, "HeadingLabel", 26 if size.x < 520 else 29 if is_last else 32, V.BLUE if won else V.CORAL.darkened(0.15))
    result_title = title
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(title)
    if won:
        var vehicle_area := Control.new()
        result_vehicle = vehicle_area
        vehicle_area.custom_minimum_size = Vector2(0, 100 if size.y < 800 else 130)
        vehicle_area.clip_contents = true
        column.add_child(vehicle_area)
        var celebration := V.texture("res://assets/decoration/industrial_shapes.svg", Vector2.ZERO)
        celebration.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        vehicle_area.add_child(celebration)
        var vehicle := V.texture(Worlds.vehicle(level), Vector2.ZERO)
        vehicle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        vehicle_area.add_child(vehicle)
        vehicle.position.x = -65
        vehicle.modulate.a = 0.0
        var arrival := create_tween().set_parallel(true)
        arrival.tween_property(vehicle, "position:x", 0.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        arrival.tween_property(vehicle, "modulate:a", 1.0, 0.12)
        var product := V.label(level.vehicle_name, "HeadingLabel", 25)
        product.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(product)
        var rating := Gears.new()
        rating.name = "EarnedGears"
        rating.custom_minimum_size = Vector2(112, 30)
        rating.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        rating.set_count(Progress.gears_for_errors(State.STARTING_LIVES - model.lives))
        column.add_child(rating)
        if rating.active > 1:
            rating.pivot_offset = Vector2(56, 15)
            var gear_pop := create_tween().bind_node(rating)
            gear_pop.tween_property(rating, "scale", Vector2.ONE * (1.12 if rating.active == 3 else 1.05), 0.12)
            gear_pop.tween_property(rating, "scale", Vector2.ONE, 0.16)
        var summary := V.label("%s\n%s · %d vida(s) restante(s)" % [level.name, V.DIFFICULTIES.get(level.difficulty, level.difficulty), model.lives], "", 16, V.MUTED)
        summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(summary)
        var result: Dictionary = model.score_result
        var lines := "Pontuação %d · ×%.2f" % [model.run_score, float(result.quality_multiplier)]
        if not completion_receipt.is_empty():
            lines += "\n+%d pontos" % int(completion_receipt.wallet_awarded) if completion_receipt.first_completion else "\nRecompensa da fase já coletada"
            if not completion_receipt.first_completion:
                var highlights: Array[String] = []
                if completion_receipt.new_record:
                    highlights.append("Novo recorde")
                if int(completion_receipt.gears_gained) > 0:
                    highlights.append("+%d engrenagem(ns)" % int(completion_receipt.gears_gained))
                if not highlights.is_empty():
                    lines += "\n" + " · ".join(highlights)
        var score_summary := V.label(lines, "", 14, V.BLUE)
        score_summary.name = "ScoreSummary"
        score_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        score_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        score_summary.tooltip_text = "Especialistas %d · X %d · Tempo %d · Conclusão %d" % [result.operator_score, result.x_score, result.time_bonus, result.completion_bonus]
        column.add_child(score_summary)
        if not season_block_message.is_empty():
            var season_message := V.label(season_block_message, "", 13, V.BLUE)
            season_message.name = "SeasonRequirement"
            season_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            season_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            column.add_child(season_message)
        if not unlocked_product.is_empty():
            var unlock := V.label("Novo produto desbloqueado:\n" + unlocked_product, "HudLabel", 16, V.BLUE)
            unlock.name = "ProductUnlock"
            unlock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            column.add_child(unlock)
    else:
        var message := V.label("Três erros interromperam esta linha.\nRecomece e siga as pistas dos setores.", "", 17, V.MUTED)
        message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        column.add_child(message)
    var primary: Button
    if won and not is_last:
        primary = V.button("Próxima fase   →", func(): next_requested.emit())
        primary.name = "NextButton"
        primary.disabled = pending_save_warning or not season_block_message.is_empty()
    elif won:
        primary = V.button("Voltar ao menu", func(): menu_requested.emit())
        primary.name = "FinishButton"
    else:
        primary = V.button("Reiniciar fase", func(): retry_requested.emit(), false, "restart")
        primary.name = "RetryButton"
        primary.theme_type_variation = "DangerButton"
    column.add_child(primary)
    if won:
        var replay := V.button("Repetir fase", func(): retry_requested.emit(), true, "restart")
        replay.name = "ReplayButton"
        column.add_child(replay)
    if not won or not is_last:
        column.add_child(V.button("Voltar ao menu", func(): menu_requested.emit(), true))
    primary.grab_focus()
    panel.modulate.a = 0.0
    result_tween = create_tween()
    result_tween.tween_property(panel, "modulate:a", 1.0, 0.10)
    if pending_save_warning:
        show_save_warning()
    responsive_layout()

func show_save_warning() -> void:
    pending_save_warning = true
    if not is_instance_valid(popup) or popup.find_child("SaveWarning", true, false) != null:
        return
    var warning := V.label("Falha ao salvar. Mantenha o jogo aberto e verifique a pasta de dados.", "", 13, V.CORAL.darkened(0.25))
    warning.name = "SaveWarning"
    warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    warning.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    warning.offset_top = -50
    warning.offset_left = 32
    warning.offset_right = -32
    if is_instance_valid(popup):
        popup.add_child(warning)

func _exit_tree() -> void:
    if model != null:
        model.set_clock_active(false)
    if is_instance_valid(board) and is_instance_valid(board.router):
        board.router.cancel()
