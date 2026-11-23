extends RefCounted
## Presentation adapter only. Model/state, node names and signals stay intact.
const T = preload("res://scripts/ui_tokens.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const V = preload("res://scripts/visuals.gd")
const Registry = preload("res://scripts/ui_sector_registry.gd")
const Press = preload("res://scripts/ui_tile_press.gd")
static var refresh_icon: Texture2D
static var settings_icon: Texture2D
static var chevron: Texture2D

static func image(svg: String) -> Texture2D:
    var data := Image.new()
    data.load_svg_from_string(svg,2.0)
    return ImageTexture.create_from_image(data)

static func prepare_icons() -> void:
    if refresh_icon!=null:
        return
    refresh_icon = image(T.REFRESH_SVG)
    var source := FileAccess.get_file_as_string("res://assets/ui/icon_settings.svg")
    source = source.replace('url(#light)','#FFFFFF').replace('#8C3B1B','#FFFFFF').replace('#B1471E','#FDB563').replace('#FFD593','#FDB563')
    settings_icon = image(source)
    chevron = image(T.CHEVRON_SVG)

static func rect(node: Control, value: Rect2) -> void:
    node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    node.custom_minimum_size = Vector2.ZERO
    node.position = value.position*T.REFERENCE_H
    node.size = value.size*T.REFERENCE_H

static func records(game) -> Array:
    if game.has_meta("ui_sector_records"):
        return game.get_meta("ui_sector_records")
    var result := Registry.build(game.level,game.board.region_colors)
    game.set_meta("ui_sector_records",result)
    return result

static func action_skin(button: Button, specification: Dictionary) -> void:
    button.expand_icon = true
    var height := T.unit(specification.height)
    var recipe := {"top":specification.top,"base":specification.base,"bottom":specification.bottom,"lip":specification.edge}
    for state in ["normal","hover","pressed"]:
        var active := recipe.duplicate()
        if state=="hover":
            for key in ["top","base","bottom"]:
                active[key] = active[key].lightened(T.TILE.specular*T.TILE.lip)
        var style := UiSkin.box(active,specification.radius,T.unit(specification.padding),T.TILE.pressed_lip*T.REFERENCE_H/height if state=="pressed" else specification.lip,true,0.0,height)
        style.content_margin_top = T.unit(specification.padding_y)
        style.content_margin_bottom = T.unit(specification.padding_y)
        button.add_theme_stylebox_override(state,style)
    button.size.y = height
    button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER if button.text.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
    button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
    button.add_theme_constant_override("icon_max_width",roundi(T.unit(specification.icon)))
    button.add_theme_stylebox_override("focus",V.box(Color.TRANSPARENT,roundi(height*specification.radius),0,V.HIGHLIGHT))

static func apply_p1(game) -> void:
    var sectors := records(game)
    # P1.1 changes only the visual quad inside the unchanged input rectangle.
    for entry in sectors:
        game.board.region_colors[entry.id] = entry.color
    for cell in game.board.cells:
        var entry: Dictionary = sectors[cell.region_id]
        cell.region_color = entry.color
        if not cell.tile_face.has_meta("ui_moulded"):
            cell.tile_face.material = UiSkin.material(entry.recipe,cell.size)
            var press := Node.new()
            press.set_script(Press)
            press.face = cell.tile_face
            cell.tile_face.add_child(press)
            cell.tile_face.set_meta("ui_moulded",true)
        else:
            UiSkin.configure(cell.tile_face.material,entry.recipe,cell.size,T.TILE.radius,T.TILE.gap,T.TILE.lip)
        cell.portrait_view.material.set_shader_parameter("sector_color",entry.color)
        cell.queue_redraw()
    # P1.2/P1.3: shared volume, native buttons and existing callbacks.
    game.options_button.size = T.SETTINGS.size*T.REFERENCE_H
    game.options_button.position.y = game.restart_button.position.y
    action_skin(game.options_button,T.SETTINGS)
    action_skin(game.restart_button,T.RESTART)
    prepare_icons()
    game.options_button.icon = settings_icon
    game.restart_button.icon = refresh_icon
    # P1.4: all rows already exist; the fixed viewport intentionally scrolls.
    for entry in sectors:
        var badge: PanelContainer = game.sector_badges[entry.id]
        badge.custom_minimum_size = Vector2.ONE*roundi(T.unit(T.SECTOR.tile))
        badge.add_theme_stylebox_override("panel",UiSkin.box(entry.recipe,T.SECTOR.radius,T.unit(T.SECTOR.padding),T.TILE.lip,false,0.0,roundi(T.unit(T.SECTOR.tile))))
        var glyph: TextureRect = badge.get_child(0)
        glyph.texture = UiSkin.colored_icon("res://assets/sectors/%s.svg" % entry.icon,entry.icon)
        glyph.custom_minimum_size = Vector2.ONE*T.unit(T.SECTOR.tile)*T.SECTOR.glyph
        glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        var row: PanelContainer = game.sector_rows[entry.id]
        row.set_meta("ui_sector_id",entry.id)
        row.get_child(0).get_child(1).text = entry.name
        var row_skin: StyleBox = row.get_theme_stylebox("panel").duplicate()
        row_skin.content_margin_top = T.unit(T.SECTOR.row_padding_y)
        row_skin.content_margin_bottom = T.unit(T.SECTOR.row_padding_y)
        row_skin.content_margin_left = T.unit(T.SECTOR.row_padding_x)
        row_skin.content_margin_right = T.unit(T.SECTOR.row_padding_x)
        row.add_theme_stylebox_override("panel",row_skin)
        row.get_child(0).add_theme_constant_override("separation",roundi(T.unit(T.SECTOR.gap)))
        row.custom_minimum_size.y = roundi(T.unit(T.SECTOR.row))
        var arrow: Label = row.get_child(0).get_child(2)
        arrow.text = ""
        arrow.custom_minimum_size.x = T.unit(T.SECTOR.chevron)
        if arrow.get_child_count()==0:
            var view := TextureRect.new()
            view.texture = chevron
            view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            view.mouse_filter = Control.MOUSE_FILTER_IGNORE
            view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            arrow.add_child(view)
    # P1.5: flat pending alpha silhouette, clean saturated tile below it.
    rect(game.specialist_strip,T.RECTS.strip)
    game.specialist_strip.fit_available(T.unit(T.RECTS.strip.size.x),T.unit(T.STRIP.height))
    for entry in sectors:
        var slot: PanelContainer = game.specialist_strip.slots[entry.id]
        slot.set_meta("ui_recipe",entry.recipe)
        slot.custom_minimum_size.y = floorf(T.unit(T.STRIP.height)-roundi(T.unit(T.STRIP.padding))*2)
        var skin := UiSkin.box(entry.recipe,T.STRIP.radius,T.unit(T.STRIP.padding)*T.TILE.specular,T.TILE.lip,false,T.unit(T.STRIP.ring),T.unit(T.STRIP.height-T.STRIP.padding*2))
        skin.content_margin_top = -slot.custom_minimum_size.y*T.STRIP.overshoot
        slot.add_theme_stylebox_override("panel",skin)
        slot.clip_contents = false
        slot.tooltip_text = entry.name
        game.specialist_strip.portraits[entry.id].texture = entry.avatar
        game.specialist_strip.portraits[entry.id].material.set_shader_parameter("sector_color",entry.color)
        game.specialist_strip.portraits[entry.id].material.set_shader_parameter("flat_pending",true)
        game.specialist_strip.portraits[entry.id].material.set_shader_parameter("pending_tint",T.STRIP.silhouette)
    game.specialist_strip.size.y = T.unit(T.STRIP.height)
    game.specialist_strip.custom_minimum_size.y = floorf(T.unit(T.STRIP.height))
    # P1.6: preserve the actual controls/score nodes in the left rail.
    if game.controls_card.get_parent()!=game.desktop_stage:
        game.controls_card.reparent(game.desktop_stage,false)
    game.controls_label.text = T.HELP_TEXT
    game.controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    game.controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    game.controls_label.add_theme_font_size_override("font_size",roundi(T.unit(T.FOOTER.help_font)))
    game.controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game.controls_row.alignment = BoxContainer.ALIGNMENT_CENTER
    if not game.has_meta("ui_help_stack"):
        var stack := VBoxContainer.new()
        stack.add_theme_constant_override("separation",roundi(T.unit(T.ROW_PADDING_Y)))
        game.controls_card.add_child(stack)
        game.controls_row.reparent(stack,false)
        game.set_meta("ui_help_stack",stack)
    var stack: VBoxContainer = game.get_meta("ui_help_stack")
    if game.score_row.get_parent()!=stack:
        game.score_row.reparent(stack,false)
    rect(game.controls_card,T.RECTS.help)
    game.controls_card.add_theme_stylebox_override("panel",V.desktop_surface(V.PAPER,roundi(T.unit(T.FOOTER.radius)),roundi(T.unit(T.FOOTER.padding))))
    game.score_row.custom_minimum_size = Vector2.ZERO
    game.score_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    game.score_label.add_theme_font_size_override("font_size",roundi(T.unit(T.FOOTER.score_font)))
    game.score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game.score_row.alignment = BoxContainer.ALIGNMENT_CENTER
    rect(game.message_card,T.RECTS.message)
    game.message_icon.custom_minimum_size = Vector2.ONE*T.unit(T.FOOTER.icon)
    game.feedback.add_theme_font_size_override("font_size",roundi(T.unit(T.FOOTER.font)))
    game.message_card.add_theme_stylebox_override("panel",V.desktop_surface(V.PAPER,roundi(T.unit(T.FOOTER.radius)),roundi(T.unit(T.FOOTER.padding))))

static func apply(game) -> void:
    apply_p1(game)
    apply_p2(game)

static func apply_p2(game) -> void:
    # P2.1 changes only the blue panels; preserve the accepted cream rim.
    var bezel: StyleBoxFlat = game.board_mount.get_child(0).get_child(0).get_theme_stylebox("panel").duplicate()
    bezel.bg_color = T.FRAME.body
    bezel.border_color = T.FRAME.border
    bezel.set_border_width_all(roundi(T.unit(T.FRAME.stroke)))
    game.board_mount.get_child(0).get_child(0).add_theme_stylebox_override("panel",bezel)
    var tray: StyleBoxFlat = game.board_mount.get_child(0).get_child(0).get_child(0).get_theme_stylebox("panel").duplicate()
    tray.bg_color = T.FRAME.groove
    game.board_mount.get_child(0).get_child(0).get_child(0).add_theme_stylebox_override("panel",tray)
    # P2.2: only the wordmark changes font; all other labels retain Barlow.
    var wordmark: Label = game.brand_row.get_child(1)
    if not game.has_meta("ui_previous_wordmark"):
        game.set_meta("ui_previous_wordmark",wordmark.get_theme_font("font"))
    style_wordmark(wordmark)
    # P2.3: a neutral inset track gives both white and dark dots >=3:1.
    style_difficulty(game.difficulty_badge)
    # P2.4 is drawn by the existing presentation-only ProductionStage view.

static func restore(game) -> void:
    if not game.has_meta("ui_sector_records"):
        return
    var sectors: Array = game.get_meta("ui_sector_records")
    for entry in sectors:
        game.board.region_colors[entry.id] = entry.source
        game.specialist_strip.slots[entry.id].clip_contents = true
        game.specialist_strip.portraits[entry.id].material.set_shader_parameter("sector_color",entry.source)
        game.specialist_strip.portraits[entry.id].material.set_shader_parameter("flat_pending",false)
    for cell in game.board.cells:
        cell.region_color = sectors[cell.region_id].source
        if cell.tile_face.has_meta("ui_moulded"):
            var original := ShaderMaterial.new()
            original.shader = preload("res://shaders/tile_surface.gdshader")
            cell.tile_face.material = original
            cell.tile_face.remove_meta("ui_moulded")
            for feedback in cell.tile_face.get_children():
                feedback.set_process(false)
                feedback.queue_free()
        cell.portrait_view.material.set_shader_parameter("sector_color",cell.region_color)
        cell.update_surface()
    if game.has_meta("ui_help_stack"):
        game.score_row.reparent(game.desktop_stage,false)
        game.controls_row.reparent(game.controls_card,false)
        game.get_meta("ui_help_stack").queue_free()
        game.remove_meta("ui_help_stack")
    game.controls_label.text = T.LEGACY_HELP_TEXT
    game.options_button.icon = load("res://assets/ui/icon_settings.svg")
    game.restart_button.icon = load("res://assets/ui/icon_restart_action.svg")
    game.options_button.remove_theme_stylebox_override("focus")
    game.restart_button.remove_theme_stylebox_override("focus")
    game.brand_row.get_child(1).add_theme_font_override("font",game.get_meta("ui_previous_wordmark"))
    game.board_mount.get_child(0).get_child(0).get_child(0).add_theme_stylebox_override("panel",V.board_tray())
    if game.difficulty_badge.has_meta("ui_dot_track"):
        game.difficulty_badge.get_meta("ui_dot_track").add_theme_stylebox_override("panel",StyleBoxEmpty.new())

static func style_wordmark(wordmark: Label) -> void:
    var font := FontVariation.new()
    font.base_font = load(T.WORDMARK.font)
    font.variation_opentype = {T.WORDMARK.weight_axis:T.WORDMARK.weight}
    font.spacing_glyph = roundi(T.unit(T.WORDMARK.font_size)*T.WORDMARK.spacing)
    wordmark.add_theme_font_override("font",font)
    wordmark.add_theme_font_size_override("font_size",roundi(T.unit(T.WORDMARK.font_size)))
    wordmark.add_theme_color_override("font_color",T.WORDMARK.color)

static func style_difficulty(badge) -> void:
    var tint: Color = T.DIFFICULTY.get(badge.difficulty,T.DIFFICULTY.hard)
    var top: Color = T.DIFFICULTY.normal_top if badge.difficulty=="normal" else tint.lightened(T.TILE.specular)
    var bottom: Color = T.DIFFICULTY.normal_bottom if badge.difficulty=="normal" else tint
    var skin := UiSkin.box({"top":top,"base":top.lerp(bottom,0.5),"bottom":bottom,"lip":bottom.darkened(T.TILE.specular)},T.SETTINGS.radius,T.unit(T.STRIP.padding),T.TILE.lip,false,0.0,badge.size.y)
    badge.add_theme_stylebox_override("panel",skin)
    if not badge.has_meta("ui_dot_track"):
        var parent: Control = badge.dots.get_parent()
        var track := PanelContainer.new()
        track.add_theme_stylebox_override("panel",V.box(T.DIFFICULTY.track,roundi(T.unit(T.DIFFICULTY.dot)),0))
        parent.add_child(track)
        badge.dots.reparent(track,false)
        badge.set_meta("ui_dot_track",track)
    badge.get_meta("ui_dot_track").add_theme_stylebox_override("panel",V.box(T.DIFFICULTY.track,roundi(T.unit(T.DIFFICULTY.dot)),0))
    for i in range(badge.dots.get_child_count()):
        var dot: PanelContainer = badge.dots.get_child(i)
        dot.add_theme_stylebox_override("panel",V.box(T.DIFFICULTY.filled if i<badge.tier else T.DIFFICULTY.empty,roundi(T.unit(T.DIFFICULTY.dot)),0))
