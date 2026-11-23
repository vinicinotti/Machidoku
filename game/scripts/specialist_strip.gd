extends PanelContainer
const V = preload("res://scripts/visuals.gd")
const Art = preload("res://scripts/specialist_art.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
const T = preload("res://scripts/ui_tokens.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
var portraits: Array[TextureRect] = []
var slots: Array[PanelContainer] = []
var found: Array[bool] = []
var row: HBoxContainer
var model
var reduced_motion := false
var sector_colors: Array[Color]
var slot_tweens: Array[Tween] = []

func setup(state, colors: Array[Color]) -> void:
    model = state
    sector_colors = colors
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_theme_stylebox_override("panel", V.surface(V.PAPER, 25, 12))
    row = HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 10)
    add_child(row)
    var metadata := Worlds.world(model.level.world)
    for region in range(int(model.level.size)):
        var slot := PanelContainer.new()
        slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
        slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        slot.set_meta("sector_id", region)
        slot.tooltip_text = metadata.sectors[region] if region < metadata.sectors.size() else "Setor %d" % (region + 1)
        slot.add_theme_stylebox_override("panel", V.surface(colors[region], 14, 4,false))
        slot.clip_contents = true
        row.add_child(slot)
        slots.append(slot)
        var portrait := TextureRect.new()
        portrait.texture = Art.for_region(model.level, region)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
        portrait.material = Art.for_sector(portrait.texture, colors[region], false)
        slot.add_child(portrait)
        portraits.append(portrait)
        found.append(false)
        slot_tweens.append(null)
    resized.connect(fit_slots)
    fit_slots()
    refresh(false)

func fit_slots() -> void:
    var count := maxi(1, slots.size())
    var gap := 8 if size.x >= 500 else 4
    row.add_theme_constant_override("separation", gap)
    var padding := 6 if size.x < 500 else 10
    add_theme_stylebox_override("panel",V.surface(V.PAPER,14 if size.x < 500 else 25,padding))
    var desktop := get_viewport_rect().size.x >= T.DESKTOP_MIN_WIDTH
    var slot_height := maxf(16,floorf(size.y-padding*2) if desktop else size.y-padding*2)
    var slot_width := maxf(16,floorf((size.x-padding*2-gap*(count-1))/count))
    for index in range(slots.size()):
        var slot := slots[index]
        slot.custom_minimum_size = Vector2(0,slot_height)
        slot.add_theme_stylebox_override("panel",V.surface(sector_colors[index],mini(16,maxi(3,roundi(minf(slot_width,slot_height)*0.18))),3 if size.x < 500 else 4,false))
        if desktop and slot.has_meta("ui_recipe"):
            var skin := UiSkin.box(slot.get_meta("ui_recipe"),T.STRIP.radius,T.unit(T.STRIP.padding)*T.TILE.specular,T.TILE.lip,false,T.unit(T.STRIP.ring),slot_height)
            skin.content_margin_top = -slot_height*T.STRIP.overshoot
            slot.add_theme_stylebox_override("panel",skin)

func fit_available(width: float, height: float) -> void:
    for slot in slots:
        slot.custom_minimum_size = Vector2.ZERO
    custom_minimum_size = Vector2(0,height)
    size = Vector2(width,height)
    fit_slots()

func refresh(animate: bool = true) -> void:
    var discovered: Array[bool] = []
    discovered.resize(found.size())
    discovered.fill(false)
    var n := int(model.level.size)
    for r in range(n):
        for c in range(n):
            if model.state_at(Vector2i(r,c)) in [model.CellState.SPECIALIST, model.CellState.PREPLACED_SPECIALIST]:
                discovered[int(model.level.regions[r][c])] = true
    for region in range(found.size()):
        if discovered[region] == found[region]:
            continue
        found[region] = discovered[region]
        if slot_tweens[region]:
            slot_tweens[region].kill()
        portraits[region].scale = Vector2.ONE
        portraits[region].material.set_shader_parameter("revealed", found[region])
        if found[region] and animate and not reduced_motion:
            portraits[region].pivot_offset = portraits[region].size / 2.0
            portraits[region].scale = Vector2.ONE * 0.78
            var pop := create_tween().bind_node(portraits[region])
            slot_tweens[region] = pop
            pop.tween_property(portraits[region], "scale", Vector2.ONE * 1.04, 0.12)
            pop.tween_property(portraits[region], "scale", Vector2.ONE, 0.12)
