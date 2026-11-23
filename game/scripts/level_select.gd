extends Control
## Integrated home: current phase first, then one descending history column.
signal level_selected(index: int)
signal exit_requested
const V = preload("res://scripts/visuals.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
const Gears = preload("res://scripts/gear_indicator.gd")
var levels: Array[Dictionary] = []
var progress
var scroll: ScrollContainer
var page: VBoxContainer
var featured_id := 0
var row_ids: Array[int] = []
var rows: Array[PanelContainer] = []
var markers: Array[PanelContainer] = []
var brand_row: HBoxContainer
var hero_car: TextureRect
var exit_button: Button

func _ready() -> void:
    V.background(self)
    var margin := V.margin(16)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    margin.add_child(column)
    var header := Control.new()
    header.custom_minimum_size.y = 52
    column.add_child(header)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    center.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.add_child(center)
    brand_row = V.brand(32, 46)
    center.add_child(brand_row)
    exit_button = V.button("", func(): exit_requested.emit(), true)
    exit_button.name = "ExitButton"
    exit_button.tooltip_text = "Sair"
    exit_button.custom_minimum_size = Vector2(44, 44)
    exit_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
    exit_button.offset_left = -44
    exit_button.offset_bottom = 44
    header.add_child(exit_button)
    exit_button.draw.connect(draw_exit)
    var summary_center := CenterContainer.new()
    column.add_child(summary_center)
    var summary := PanelContainer.new()
    summary.name = "CampaignProgress"
    summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    summary.custom_minimum_size.x = minf(760, size.x - 32)
    summary.add_theme_stylebox_override("panel", V.material(V.PAPER,20,12))
    summary_center.add_child(summary)
    var totals := HBoxContainer.new()
    summary.add_child(totals)
    var total_score := 0
    for id in progress.data.completed_levels:
        var stats = progress.data.level_stats.get(str(int(id)),{})
        if stats is Dictionary:
            total_score += maxi(0,int(stats.get("best_score",0)))
    var performance := VBoxContainer.new()
    performance.add_theme_constant_override("separation",0)
    performance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    totals.add_child(performance)
    performance.add_child(V.label("Pontuação total","HudLabel",13,V.BLUE))
    var total_label := V.label(str(total_score),"HeadingLabel",26,V.DARK)
    total_label.name = "TotalScore"
    performance.add_child(total_label)
    var wallet := V.label("Pontos disponíveis\n%d" % int(progress.data.get("wallet_points",0)),"HudLabel",14,V.BLUE)
    wallet.name = "WalletPoints"
    wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    wallet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    totals.add_child(wallet)
    scroll = ScrollContainer.new()
    scroll.name = "HomeScroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(scroll)
    var align := HBoxContainer.new()
    align.alignment = BoxContainer.ALIGNMENT_CENTER
    align.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(align)
    page = VBoxContainer.new()
    page.name = "PhaseHistory"
    page.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    page.add_theme_constant_override("separation", 10)
    align.add_child(page)
    if levels.is_empty():
        page.add_child(V.label("Não foi possível carregar as fases.", "", 16, V.CORAL))
        return
    var current: int = progress.current_index(levels)
    featured_id = int(levels[current].id)
    add_featured(current)
    add_product_boundary(levels[current])
    for index in range(current - 1, -1, -1):
        var level := levels[index]
        if int(level.id) > int(progress.data.highest_unlocked_level):
            continue
        add_phase_row(index)
        add_product_boundary(level)
    resized.connect(responsive)
    responsive()
    scroll.set_deferred("scroll_vertical", 0)

func add_featured(index: int) -> void:
    var level := levels[index]
    var card := PanelContainer.new()
    card.name = "NextPhase"
    card.set_meta("level_id", int(level.id))
    card.add_theme_stylebox_override("panel", V.material(V.PAPER, 24, 16))
    page.add_child(card)
    var content := VBoxContainer.new()
    card.add_child(content)
    var row := HBoxContainer.new()
    content.add_child(row)
    var captions := VBoxContainer.new()
    captions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    captions.add_theme_constant_override("separation", 2)
    row.add_child(captions)
    captions.add_child(V.label("Campanha concluída" if progress.product_completed(levels, level.world, level.product) and index == levels.size() - 1 else "Próxima fase", "HudLabel", 14, V.MUTED))
    captions.add_child(V.label("Fase %02d" % int(level.id), "TitleLabel", 32, V.BLUE))
    captions.add_child(V.label(level.vehicle_name, "HudLabel", 18, V.BLUE))
    captions.add_child(V.label(Worlds.world(level.world).name, "", 12, V.MUTED))
    if progress.level_status(int(level.id)) == "COMPLETED":
        add_rating(captions, int(level.id), "FeaturedGears")
    hero_car = V.texture(Worlds.vehicle(level), Vector2(160, 104))
    row.add_child(hero_car)
    var play := V.button("Jogar Fase %02d" % int(level.id), func(): level_selected.emit(index))
    play.name = "PlayButton"
    content.add_child(play)

func add_phase_row(index: int) -> void:
    var level := levels[index]
    var id := int(level.id)
    var status: String = progress.level_status(id)
    var panel := PanelContainer.new()
    panel.set_meta("level_id", id)
    panel.add_theme_stylebox_override("panel", V.material(V.PAPER, 17, 12))
    page.add_child(panel)
    rows.append(panel)
    row_ids.append(id)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    panel.add_child(row)
    var captions := VBoxContainer.new()
    captions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    captions.add_theme_constant_override("separation", 0)
    row.add_child(captions)
    captions.add_child(V.label("Fase %02d" % id, "HudLabel", 20, V.BLUE))
    add_rating(captions, id)
    var play := V.button("Jogar novamente" if status == "COMPLETED" else "Jogar", func(): level_selected.emit(index), true)
    play.name = "Level%02d" % id
    play.set_meta("level_status", status)
    play.custom_minimum_size.y = 42
    play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    play.add_theme_font_size_override("font_size", 14)
    row.add_child(play)

func add_rating(parent: Control, id: int, node_name: String = "BestGears") -> void:
    var score: int = progress.best_gears(id)
    if score < 0:
        parent.add_child(V.label("Sem nota", "", 12, V.MUTED))
    else:
        var gears := Gears.new()
        gears.name = node_name
        gears.custom_minimum_size = Vector2(72, 24)
        gears.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        gears.set_count(score)
        gears.tooltip_text = "%d de 3 engrenagens" % score
        parent.add_child(gears)

func add_product_boundary(level: Dictionary) -> void:
    var product := Worlds.product(level.world, level.product)
    if not product.is_empty() and int(level.id) == int(product.first_level):
        add_separator(product, level.world)

func add_separator(product: Dictionary, world_id: String) -> void:
    var panel := PanelContainer.new()
    panel.name = "Season_%s_%s" % [world_id, product.id]
    panel.set_meta("product", product.id)
    panel.set_meta("world", world_id)
    panel.add_theme_stylebox_override("panel", V.box(V.CREAM.lightened(0.3), 17, 10, V.HIGHLIGHT))
    page.add_child(panel)
    markers.append(panel)
    var row := HBoxContainer.new()
    panel.add_child(row)
    row.add_child(V.texture(product.vehicle_asset, Vector2(84, 44)))
    var captions := VBoxContainer.new()
    captions.add_theme_constant_override("separation", 0)
    row.add_child(captions)
    captions.add_child(V.label(product.display_name, "HudLabel", 18, V.BLUE))
    captions.add_child(V.label(Worlds.world(world_id).name, "", 11, V.MUTED))

func responsive() -> void:
    page.custom_minimum_size.x = minf(760, size.x - 32)
    var summary := find_child("CampaignProgress",true,false) as Control
    if summary != null:
        summary.custom_minimum_size.x = minf(760,size.x - 32)
    brand_row.get_child(0).custom_minimum_size = Vector2.ONE * (34 if size.x < 520 else 46)
    brand_row.get_child(1).add_theme_font_size_override("font_size", 24 if size.x < 520 else 32)
    if is_instance_valid(hero_car):
        hero_car.custom_minimum_size.x = 92 if size.x < 520 else 160
    preload("res://scripts/ui_home.gd").apply(self)

func draw_exit() -> void:
    var center := exit_button.size / 2.0
    var ink := V.BLUE
    exit_button.draw_polyline(PackedVector2Array([center + Vector2(-1, -9), center + Vector2(-8, -9), center + Vector2(-8, 9), center + Vector2(-1, 9)]), ink, 2, true)
    exit_button.draw_line(center + Vector2(-2, 0), center + Vector2(10, 0), ink, 2, true)
    exit_button.draw_polyline(PackedVector2Array([center + Vector2(5, -5), center + Vector2(10, 0), center + Vector2(5, 5)]), ink, 2, true)
