extends RefCounted
## Styles and arranges existing Home nodes. Campaign order/data stay authored.
const T = preload("res://scripts/ui_tokens.gd")
const V = preload("res://scripts/visuals.gd")
const Ui = preload("res://scripts/ui_desktop_refinement.gd")
const Shared = preload("res://scripts/ui_shell.gd")
const Glass = preload("res://scripts/glass_surface.gd")

static func apply(home) -> void:
    if home.size.x<T.DESKTOP_MIN_WIDTH:
        if home.has_meta("ui_home_stage") and home.get_meta("ui_home_active",false):
            home.set_meta("ui_home_active",false)
            Shared.restore_controls(home.get_meta("ui_home_snapshot"))
            home.get_meta("ui_home_stage").hide()
            home.get_meta("ui_home_copy").copy_mode = BackBufferCopy.COPY_MODE_DISABLED
            if home.has_meta("ui_hero_stage"):
                home.get_meta("ui_hero_stage").hide()
            if home.has_meta("ui_home_totals_stack"):
                home.get_meta("ui_home_totals_stack").hide()
            home.responsive()
        return
    var stage: Control
    if not home.has_meta("ui_home_stage"):
        home.set_meta("ui_home_snapshot",Shared.capture_controls(home))
        # Background-only capture, as on gameplay. Exactly one glass surface.
        var copy := BackBufferCopy.new()
        copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
        home.add_child(copy)
        home.move_child(copy,1)
        home.set_meta("ui_home_copy",copy)
        stage = Control.new()
        home.add_child(stage)
        home.set_meta("ui_home_stage",stage)
        var glass := Glass.new()
        stage.add_child(glass)
        Ui.rect(glass,T.HOME.glass)
        glass.material.set_shader_parameter("tint_strength",T.HOME.glass_tint)
        glass.material.set_shader_parameter("radius",T.unit(T.HOME.glass_radius))
        var summary: PanelContainer = home.find_child("CampaignProgress",true,false)
        var brand: Control = home.brand_row.get_parent()
        home.set_meta("ui_home_original_column",home.scroll.get_parent())
        for node in [summary,brand,home.exit_button,home.scroll]:
            node.reparent(stage,false)
        home.set_meta("ui_home_summary",summary)
        home.set_meta("ui_home_brand",brand)
    else:
        stage = home.get_meta("ui_home_stage")
        for node in [home.get_meta("ui_home_summary"),home.get_meta("ui_home_brand"),home.exit_button,home.scroll]:
            if node.get_parent()!=stage:
                node.reparent(stage,false)
    stage.show()
    home.set_meta("ui_home_active",true)
    home.get_meta("ui_home_copy").copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
    var factor := minf(home.size.x/T.canvas().x,home.size.y/T.canvas().y)
    stage.scale = Vector2.ONE*factor
    stage.size = T.canvas()
    stage.position = (home.size-T.canvas()*factor)/2.0
    Ui.rect(home.get_meta("ui_home_brand"),T.HOME.brand)
    Shared.brand(home.brand_row)
    Ui.rect(home.exit_button,T.HOME.exit)
    Shared.button(home.exit_button,false,T.HOME.exit.size.y)
    var summary: PanelContainer = home.get_meta("ui_home_summary")
    Ui.rect(summary,T.HOME.summary)
    summary.add_theme_stylebox_override("panel",Shared.card(T.unit(T.HOME.summary.size.y)))
    if not home.has_meta("ui_home_totals"):
        home.set_meta("ui_home_totals",summary.get_child(0))
    var totals: HBoxContainer = home.get_meta("ui_home_totals")
    if not home.has_meta("ui_home_totals_stack"):
        var stack := VBoxContainer.new()
        stack.alignment = BoxContainer.ALIGNMENT_CENTER
        summary.add_child(stack)
        home.set_meta("ui_home_totals_stack",stack)
        home.set_meta("ui_home_wallet",totals.get_child(1))
    var stack: VBoxContainer = home.get_meta("ui_home_totals_stack")
    stack.show()
    stack.add_theme_constant_override("separation",roundi(T.unit(T.SHELL.padding)))
    if totals.get_parent()!=stack:
        totals.reparent(stack,false)
    var wallet: Label = home.get_meta("ui_home_wallet")
    if wallet.get_parent()!=stack:
        wallet.reparent(stack,false)
    totals.add_theme_constant_override("separation",roundi(T.unit(T.SHELL.padding)))
    var performance: VBoxContainer = totals.get_child(0)
    performance.get_child(0).add_theme_font_override("font",V.HUD)
    performance.get_child(0).add_theme_font_size_override("font_size",roundi(T.unit(T.HOME.label_font)))
    performance.get_child(1).add_theme_font_size_override("font_size",roundi(T.unit(T.HOME.total_font)))
    wallet.add_theme_font_override("font",V.HUD)
    wallet.add_theme_font_size_override("font_size",roundi(T.unit(T.HOME.wallet_font)))
    wallet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    wallet.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    if not home.has_meta("ui_home_watermark"):
        var watermark := V.texture("res://assets/ui/icon_factory.svg",Vector2.ZERO)
        watermark.self_modulate.a = T.HOME_DECORATION.watermark_alpha
        stage.add_child(watermark)
        home.set_meta("ui_home_watermark",watermark)
    Ui.rect(home.get_meta("ui_home_watermark"),T.HOME_DECORATION.watermark)
    Ui.rect(home.scroll,T.HOME.scroll)
    home.page.custom_minimum_size.x = T.unit(T.HOME.scroll.size.x-T.HOME.scroll_width*2)
    home.page.add_theme_constant_override("separation",roundi(T.unit(T.SHELL.gap)))
    var scrollbar: VScrollBar = home.scroll.get_v_scroll_bar()
    var width := T.unit(T.HOME_SCROLLBAR.width)
    scrollbar.custom_minimum_size.x = width
    var track := V.box(Color(V.BLUE,T.HOME_SCROLLBAR.track_alpha),roundi(T.unit(T.HOME_SCROLLBAR.radius)),0)
    track.content_margin_left = width/2.0
    track.content_margin_right = width/2.0
    scrollbar.add_theme_stylebox_override("scroll",track)
    scrollbar.add_theme_stylebox_override("scroll_focus",track)
    for state in ["grabber","grabber_highlight","grabber_pressed"]:
        var alpha: float = T.HOME_SCROLLBAR.idle_alpha if state=="grabber" else T.HOME_SCROLLBAR.hover_alpha if state=="grabber_highlight" else T.HOME_SCROLLBAR.pressed_alpha
        var thumb := V.box(Color(T.SHELL.card_base,alpha),roundi(T.unit(T.HOME_SCROLLBAR.radius)),0,Color(T.SHELL.card_top,T.HOME_SCROLLBAR.edge_alpha))
        thumb.content_margin_left = width/2.0
        thumb.content_margin_right = width/2.0
        thumb.content_margin_top = T.unit(T.HOME_SCROLLBAR.thumb_min)/2.0
        thumb.content_margin_bottom = T.unit(T.HOME_SCROLLBAR.thumb_min)/2.0
        scrollbar.add_theme_stylebox_override(state,thumb)
    var featured: PanelContainer = home.find_child("NextPhase",true,false)
    if featured:
        featured.add_theme_stylebox_override("panel",Shared.card(T.unit(T.HOME.car_size.y+T.SHELL.primary_height+T.SHELL.padding*2+T.SHELL.gap)))
        var content: VBoxContainer = featured.get_child(0)
        content.add_theme_constant_override("separation",roundi(T.unit(T.SHELL.gap)))
        var row: HBoxContainer = content.get_child(0)
        var captions: VBoxContainer = row.get_child(0)
        var sizes := [T.HOME.label_font,T.HOME.phase_font,T.HOME.product_font,T.HOME.world_font]
        for i in range(mini(sizes.size(),captions.get_child_count())):
            captions.get_child(i).add_theme_font_size_override("font_size",roundi(T.unit(sizes[i])))
            captions.get_child(i).add_theme_font_override("font",V.DISPLAY if i in [1,2] else V.HUD)
        if not home.has_meta("ui_hero_stage"):
            var platform := Control.new()
            platform.set_script(preload("res://scripts/production_stage.gd"))
            row.add_child(platform)
            home.hero_car.reparent(platform,false)
            home.hero_car.custom_minimum_size = Vector2.ZERO
            home.hero_car.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            home.hero_car.offset_bottom = -T.unit(T.SHELL.gap)
            home.set_meta("ui_hero_stage",platform)
        home.get_meta("ui_hero_stage").custom_minimum_size = T.HOME.car_size*T.REFERENCE_H
        home.get_meta("ui_hero_stage").show()
        if home.hero_car.get_parent()!=home.get_meta("ui_hero_stage"):
            home.hero_car.reparent(home.get_meta("ui_hero_stage"),false)
        home.hero_car.custom_minimum_size = Vector2.ZERO
        home.hero_car.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        home.hero_car.offset_bottom = -T.unit(T.SHELL.gap)
        Shared.button(home.find_child("PlayButton",true,false),true,T.SHELL.primary_height)
    for card in home.rows:
        card.custom_minimum_size.y = T.unit(T.HOME.row_height)
        card.add_theme_stylebox_override("panel",Shared.card(T.unit(T.HOME.row_height),T.HOME.row_padding,T.SHELL.radius))
        var row: HBoxContainer = card.get_child(0)
        row.get_child(0).get_child(0).add_theme_font_size_override("font_size",roundi(T.unit(T.HOME.row_font)))
        for child in row.get_child(0).get_children():
            if child.get_script()==preload("res://scripts/gear_indicator.gd"):
                child.custom_minimum_size = T.HOME.rating_size*T.REFERENCE_H
        Shared.button(row.get_child(1),false,T.SHELL.secondary_height)
    for card in home.markers:
        card.add_theme_stylebox_override("panel",V.desktop_surface(V.CREAM,roundi(T.unit(T.SHELL.radius)),roundi(T.unit(T.HOME.row_padding))))
