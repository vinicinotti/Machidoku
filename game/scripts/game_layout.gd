extends RefCounted
## Master coordinates: 1672x941, uniformly fitted inside a centered safe frame.
## Portrait reuses the existing flowing/scrolling Containers.
const V = preload("res://scripts/visuals.gd")
const T = preload("res://scripts/ui_tokens.gd")

static func move(node: Control, parent: Node) -> void:
    if node.get_parent() != parent:
        node.reparent(parent, false)

static func place(node: Control, rect: Rect2) -> void:
    node.custom_minimum_size = Vector2.ZERO
    node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
    node.position = rect.position
    node.size = rect.size

static func button_skin(button: Button, color: Color, radius: int, padding: int) -> void:
    if button.get_viewport_rect().size.x < T.DESKTOP_MIN_WIDTH:
        button.add_theme_stylebox_override("normal",V.surface(color,radius,padding))
        button.add_theme_stylebox_override("hover",V.surface(color.lightened(0.07),radius,padding))
        button.add_theme_stylebox_override("pressed",V.surface(color.darkened(0.055),radius,padding,false))
        return
    button.add_theme_stylebox_override("normal",V.desktop_surface(color,radius,padding))
    button.add_theme_stylebox_override("hover",V.desktop_surface(color.lightened(0.07),radius,padding))
    button.add_theme_stylebox_override("pressed",V.desktop_surface(color.darkened(0.055),radius,padding,false))

static func apply(game) -> void:
    if not is_instance_valid(game.desktop_stage):
        return
    var desktop: bool = game.size.x >= T.DESKTOP_MIN_WIDTH
    if not desktop:
        preload("res://scripts/ui_desktop_refinement.gd").restore(game)
    game.glass_backdrop.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT if desktop else BackBufferCopy.COPY_MODE_DISABLED
    game.page_margin.visible = not desktop
    game.desktop_stage.visible = desktop
    game.sidebar.visible = desktop
    game.mobile_cards.visible = not desktop
    game.rules_rail.visible = desktop
    game.title_row.visible = not desktop
    game.board.reduced_motion = game.reduced_motion()
    game.specialist_strip.reduced_motion = game.reduced_motion()
    for cell in game.board.cells:
        cell.reduce_motion = game.reduced_motion()
    if desktop:
        var factor: float = minf(game.size.x / T.canvas().x, game.size.y / T.canvas().y)
        game.desktop_stage.scale = Vector2.ONE * factor
        game.desktop_stage.size = T.canvas()
        game.desktop_stage.position = (game.size - T.canvas() * factor) / 2.0
        for node in [game.menu_button, game.restart_button, game.options_button, game.brand_center, game.rules_rail, game.specialist_strip, game.board_mount, game.sidebar, game.controls_card, game.message_card, game.score_row]:
            move(node, game.desktop_stage)
        move(game.product_heading, game.rules_rail)
        move(game.product_title, game.rules_rail)
        move(game.difficulty_badge, game.rules_rail)
        move(game.rules_row, game.rules_rail)
        move(game.lives_box, game.lives_card)
        place(game.menu_button,T.design_rect("menu_button"))
        place(game.restart_button,T.design_rect("restart_button"))
        place(game.options_button,T.design_rect("options_button"))
        place(game.brand_center,T.design_rect("brand_center"))
        place(game.rules_rail,T.design_rect("rules_rail"))
        place(game.product_heading,T.design_rect("product_heading"))
        place(game.product_title,T.design_rect("product_title"))
        place(game.difficulty_badge,T.design_rect("difficulty_badge"))
        place(game.rules_row,T.design_rect("rules_row"))
        place(game.lives_card,T.design_rect("lives_card"))
        game.lives_box.custom_minimum_size = Vector2.ZERO
        game.left_glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        game.left_glass.material.set_shader_parameter("tint_strength",0.36)
        game.left_glass.material.set_shader_parameter("radius",32.0)
        place(game.specialist_strip,T.design_rect("specialist_strip"))
        game.specialist_strip.fit_available(638,100)
        game.board_mount.ratio = 638.0/588.0
        place(game.board_mount,T.design_rect("board_mount"))
        place(game.sidebar,T.design_rect("sidebar"))
        game.right_glass.material.set_shader_parameter("tint_strength",0.42)
        game.right_glass.material.set_shader_parameter("radius",32.0)
        place(game.controls_card,T.design_rect("controls_card"))
        place(game.message_card,T.design_rect("message_card"))
        var message_skin := V.desktop_surface(V.PAPER,20,6)
        message_skin.content_margin_left = 16
        game.message_card.add_theme_stylebox_override("panel",message_skin)
        game.message_icon.custom_minimum_size = T.design_vector("message_icon_custom_minimum_size")
        game.message_icon.get_parent().add_theme_constant_override("separation",14)
        move(game.score_row,game.controls_row)
        game.score_row.custom_minimum_size = Vector2.ZERO
        game.score_row.size_flags_horizontal = Control.SIZE_SHRINK_END
        button_skin(game.menu_button,V.PAPER,26,14)
        button_skin(game.restart_button,V.ACTION,26,14)
        for state in ["normal","hover","pressed"]:
            var tint: Color = V.ACTION.lightened(0.07) if state == "hover" else V.ACTION.darkened(0.055) if state == "pressed" else V.ACTION
            game.options_button.add_theme_stylebox_override(state,V.circular_action(tint))
        game.options_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        game.options_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
        game.options_button.add_theme_constant_override("h_separation",T.length("options_button_h_separation"))
        game.options_button.add_theme_stylebox_override("focus",V.box(Color.TRANSPARENT,33,8,V.HIGHLIGHT))
        var rim := V.card(V.PAPER,32,8)
        rim.shadow_size = 5
        game.board_mount.get_child(0).add_theme_stylebox_override("panel",rim)
        var bezel := V.box(V.FRAME,26,16,V.BLUE.lightened(0.30))
        bezel.set_border_width_all(2)
        bezel.content_margin_top = 10
        bezel.content_margin_bottom = 10
        game.board_mount.get_child(0).get_child(0).add_theme_stylebox_override("panel",bezel)
        game.controls_card.add_theme_stylebox_override("panel",V.desktop_surface(V.PAPER,12,8))
        game.controls_label.add_theme_font_size_override("font_size",T.length("controls_label_font_size"))
        game.controls_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        game.controls_label.autowrap_mode = TextServer.AUTOWRAP_OFF
        game.controls_row.alignment = BoxContainer.ALIGNMENT_CENTER
        game.controls_row.add_theme_constant_override("separation",T.length("controls_row_separation"))
        game.controls_label.add_theme_font_override("font",V.HUD)
        game.controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        game.score_label.add_theme_font_size_override("font_size",T.length("score_label_font_size"))
        game.score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        game.menu_button.text = "Menu"
        game.restart_button.text = "Reiniciar"
        for button in [game.menu_button,game.restart_button]:
            button.add_theme_font_override("font",V.HUD)
            button.add_theme_font_size_override("font_size",T.length("button_font_size"))
        game.restart_button.add_theme_constant_override("icon_max_width",T.length("restart_button_icon_max_width"))
        game.menu_button.add_theme_constant_override("icon_max_width",T.length("menu_button_icon_max_width"))
        game.options_button.add_theme_constant_override("icon_max_width",T.length("options_button_icon_max_width"))
        game.brand_row.add_theme_constant_override("separation",T.length("brand_row_separation"))
        game.brand_row.get_child(0).custom_minimum_size = T.design_vector("brand_row_get_child_0_custom_minimum_size")
        var wordmark: Label = game.brand_row.get_child(1)
        wordmark.add_theme_font_size_override("font_size",T.length("wordmark_font_size"))
        wordmark.add_theme_color_override("font_color",V.BLUE)
        wordmark.add_theme_color_override("font_shadow_color",V.DARK.darkened(0.2))
        wordmark.add_theme_constant_override("shadow_offset_y",T.length("wordmark_shadow_offset_y"))
        wordmark.add_theme_color_override("font_outline_color",V.HIGHLIGHT)
        wordmark.add_theme_constant_override("outline_size",T.length("wordmark_outline_size"))
        game.phase_icon.visible = true
        game.phase_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        game.phase_icon.custom_minimum_size = T.design_vector("phase_icon_custom_minimum_size")
        game.phase_icon.get_parent().add_theme_constant_override("separation",14)
        game.phase_caption.text = "%s\nFASE %02d DE %02d" % [game.Worlds.world(game.level.world).name,int(game.level.id),game.total_levels]
        game.phase_caption.add_theme_font_size_override("font_size",T.length("phase_caption_font_size"))
        game.phase_caption.add_theme_color_override("font_color",V.DARK)
        game.product_title.add_theme_font_size_override("font_size",T.length("product_title_font_size"))
        game.product_title.text = game.level.vehicle_name.trim_suffix(" Compact")
        game.product_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        game.difficulty_badge.set_compact(false)
        game.rules_row.columns = 1
        game.rules_row.add_theme_constant_override("v_separation",T.length("rules_row_v_separation"))
        game.lives_card.add_theme_stylebox_override("panel",V.desktop_surface(V.PAPER,26,12))
        game.lives_box.alignment = BoxContainer.ALIGNMENT_CENTER
        game.lives_box.add_theme_constant_override("separation",T.length("lives_box_separation"))
        game.lives_caption.add_theme_font_size_override("font_size",T.length("lives_caption_font_size"))
        game.lives_caption.add_theme_color_override("font_color",V.DARK)
        game.lives_label.custom_minimum_size = T.design_vector("lives_label_custom_minimum_size")
        game.sidebar.add_theme_stylebox_override("panel",V.box(Color.TRANSPARENT,34,22))
        V.scale_type(game.sidebar,1.0)
        game.plant_icon.custom_minimum_size = T.design_vector("plant_icon_custom_minimum_size")
        game.plant_heading.add_theme_constant_override("separation",T.length("plant_heading_separation"))
        game.plant_captions.get_child(0).add_theme_font_size_override("font_size",T.length("plant_captions_get_child_0_font_size"))
        game.plant_captions.get_child(1).add_theme_font_size_override("font_size",T.length("plant_captions_get_child_1_font_size"))
        place(game.plant_heading,T.design_rect("plant_heading"))
        place(game.sidebar.find_child("SectorScroll",true,false),Rect2(0,100,334,362))
        place(game.production_panel,T.design_rect("production_panel"))
        var production_skin := V.desktop_surface(Color("#FFE1BD"),28,16)
        production_skin.content_margin_top = 12
        production_skin.content_margin_bottom = 20
        game.production_panel.add_theme_stylebox_override("panel",production_skin)
        var production_stage = game.sidebar.find_child("ProductionStage",true,false)
        production_stage.ratio = 2.15
        production_stage.custom_minimum_size.y = 132
        var car = production_stage.get_child(0).get_child(0)
        car.offset_left = 0
        car.offset_right = 0
        car.offset_top = -3
        car.offset_bottom = -15
        game.feedback.add_theme_font_size_override("font_size",T.length("feedback_font_size"))
        game.feedback.add_theme_font_override("font",V.HUD)
        for i in range(game.rule_cards.size()):
            game.rule_cards[i].custom_minimum_size = T.design_vector("rule_cards_i_custom_minimum_size")
            var rule_skin := V.desktop_surface(V.PAPER,24,12)
            rule_skin.content_margin_top = 5
            rule_skin.content_margin_bottom = 5
            game.rule_cards[i].add_theme_stylebox_override("panel",rule_skin)
            game.rule_cards[i].get_child(0).add_theme_constant_override("separation",30)
            game.rule_icons[i].custom_minimum_size = T.design_vector("rule_icons_i_custom_minimum_size")
            game.rule_icons[i].self_modulate = Color(1,1,1,0.88)
            game.rule_icons[i].size_flags_vertical = Control.SIZE_SHRINK_CENTER
            game.rule_labels[i].text = game.RULE_CAPTIONS[i]
            game.rule_labels[i].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            game.rule_labels[i].custom_minimum_size.x = 158
            game.rule_labels[i].add_theme_font_size_override("font_size",24)
    else:
        var top: Control = game.find_child("TopBar",true,false)
        game.board_mount.get_child(0).add_theme_stylebox_override("panel",V.board_rim())
        game.board_mount.get_child(0).get_child(0).add_theme_stylebox_override("panel",V.board_bezel())
        move(game.menu_button,game.top_actions)
        game.top_actions.move_child(game.menu_button,0)
        move(game.options_button,game.top_actions)
        move(game.restart_button,game.top_actions)
        move(game.brand_center,top)
        game.brand_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        game.brand_center.offset_left = 48
        game.brand_center.offset_right = -104
        move(game.product_heading,game.title_row)
        game.title_row.move_child(game.product_heading,0)
        move(game.product_title,game.product_heading)
        move(game.lives_box,game.title_row)
        game.board_mount.ratio = 1.0
        move(game.rules_row,game.board_column)
        game.board_column.move_child(game.rules_row,0)
        move(game.score_row,game.board_column)
        game.score_row.size_flags_horizontal = Control.SIZE_FILL
        game.score_row.custom_minimum_size = Vector2.ZERO
        game.board_column.move_child(game.score_row,1)
        move(game.difficulty_badge,game.score_row)
        game.score_row.move_child(game.difficulty_badge,0)
        move(game.specialist_strip,game.board_column)
        game.board_column.move_child(game.specialist_strip,2)
        move(game.board_mount,game.board_column)
        game.board_column.move_child(game.board_mount,3)
        move(game.controls_card,game.board_column)
        game.board_column.move_child(game.controls_card,4)
        move(game.message_card,game.board_column)
        game.board_column.move_child(game.message_card,5)
        for node in [game.menu_button,game.restart_button,game.options_button]:
            node.custom_minimum_size = Vector2(44,44)
            node.add_theme_font_size_override("font_size",18)
            node.add_theme_constant_override("icon_max_width",22)
            button_skin(node,V.PAPER if node == game.menu_button else V.ACTION,12,8)
        game.menu_button.text = "Menu" if game.size.x >= 650 else ""
        game.restart_button.text = "Reiniciar" if game.size.x >= 650 else ""
        game.brand_row.add_theme_constant_override("separation",5)
        game.brand_row.get_child(0).custom_minimum_size = Vector2(26,26)
        game.brand_row.get_child(1).add_theme_font_size_override("font_size",16 if game.size.x >= 390 else 14)
        game.brand_row.get_child(1).add_theme_constant_override("outline_size",0)
        game.brand_row.get_child(1).add_theme_constant_override("shadow_offset_y",0)
        top.custom_minimum_size.y = 44
        game.product_heading.custom_minimum_size = Vector2.ZERO
        game.phase_icon.visible = false
        game.phase_caption.text = "%s / FASE %02d" % [game.Worlds.world(game.level.world).name,int(game.level.id)]
        game.phase_caption.add_theme_font_size_override("font_size",11)
        game.product_title.add_theme_font_size_override("font_size",24)
        game.product_title.text = game.level.vehicle_name
        game.lives_box.add_theme_constant_override("separation",5)
        game.lives_caption.add_theme_font_size_override("font_size",11)
        game.lives_label.custom_minimum_size = Vector2(79,27)
        game.difficulty_badge.set_compact(true)
        game.rules_row.columns = 3
        game.rules_row.add_theme_constant_override("v_separation",8)
        game.specialist_strip.fit_available(game.size.x - 32,44)
        game.board_mount.custom_minimum_size = Vector2(0,minf(game.size.x - 32,maxf(310,game.size.y - 400)))
        game.board_column.add_theme_constant_override("separation",4)
        top.get_parent().add_theme_constant_override("separation",6)
        game.controls_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        game.controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        game.controls_label.add_theme_font_size_override("font_size",11)
        game.controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        game.controls_card.add_theme_stylebox_override("panel",V.box(Color(V.PAPER,0.65),12,2))
        game.score_label.add_theme_font_size_override("font_size",12)
        game.feedback.add_theme_font_size_override("font_size",13)
        game.message_card.add_theme_stylebox_override("panel",V.material(V.PAPER,18,8))
        game.message_icon.custom_minimum_size = Vector2(24,24)
        game.message_icon.get_parent().add_theme_constant_override("separation",10)
        for i in range(game.rule_cards.size()):
            game.rule_cards[i].custom_minimum_size = Vector2.ZERO
            game.rule_cards[i].add_theme_stylebox_override("panel",V.material(V.PAPER,15,5))
            game.rule_cards[i].get_child(0).add_theme_constant_override("separation",5)
            game.rule_icons[i].custom_minimum_size = Vector2(22,22)
            game.rule_labels[i].custom_minimum_size.x = 0
            game.rule_labels[i].autowrap_mode = TextServer.AUTOWRAP_OFF
            game.rule_labels[i].text = game.COMPACT_RULE_CAPTIONS[i]
            game.rule_labels[i].add_theme_font_size_override("font_size",11)
    game.fit_sector_rows()
    if desktop:
        preload("res://scripts/ui_desktop_refinement.gd").apply(game)
