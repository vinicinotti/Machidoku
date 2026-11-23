extends RefCounted
const T = preload("res://scripts/ui_tokens.gd")
const V = preload("res://scripts/visuals.gd")
const Shared = preload("res://scripts/ui_shell.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const Completion = preload("res://scripts/ui_completion.gd")

static func apply(game) -> void:
    if game.size.x<T.DESKTOP_MIN_WIDTH or not is_instance_valid(game.result_panel):
        return
    var panel: PanelContainer = game.result_panel
    var column: VBoxContainer = game.result_column
    var factor := minf(game.size.x/T.canvas().x,game.size.y/T.canvas().y)
    panel.custom_minimum_size.x = T.unit(T.RESULTS.width)
    panel.add_theme_stylebox_override("panel",Shared.card(T.unit(T.RESULTS.width),T.RESULTS.padding,T.RESULTS.radius))
    panel.scale = Vector2.ONE*factor
    panel.pivot_offset = panel.size/2.0
    column.add_theme_constant_override("separation",roundi(T.unit(T.RESULTS.gap)))
    game.result_title.add_theme_font_override("font",V.DISPLAY)
    game.result_title.add_theme_font_size_override("font_size",roundi(T.unit(T.RESULTS.title_font)))
    column.get_child(0).add_theme_font_override("font",V.HUD)
    column.get_child(0).add_theme_font_size_override("font_size",roundi(T.unit(T.RESULTS.eyebrow_font)))
    if not panel.has_meta("ui_result_styled"):
        var shade: ColorRect = game.popup.get_child(0)
        if game.has_meta("ui_completion_layer"):
            shade.color = Color.TRANSPARENT
        else:
            var copy := BackBufferCopy.new()
            copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
            game.popup.add_child(copy)
            game.popup.move_child(copy,0)
            shade.material = Completion.overlay_material()
            shade.material.set_shader_parameter("progress",1.0)
            shade.color = Color.WHITE
        var icon: TextureRect = column.get_child(1)
        var medal := PanelContainer.new()
        medal.custom_minimum_size = Vector2.ONE*T.unit(T.RESULTS.medal)
        medal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        medal.add_theme_stylebox_override("panel",UiSkin.box(T.recipe(0),T.RESULTS.medal_radius,T.unit(T.RESULTS.medal_padding),T.TILE.lip,false,0.0,T.unit(T.RESULTS.medal)))
        column.add_child(medal)
        column.move_child(medal,1)
        icon.reparent(medal,false)
        var score: Label = game.popup.find_child("ScoreSummary",true,false)
        if score:
            var card := PanelContainer.new()
            card.add_theme_stylebox_override("panel",Shared.card(T.unit(T.RESULTS.medal),T.RESULTS.score_padding,T.SHELL.radius))
            var rich := RichTextLabel.new()
            rich.bbcode_enabled = true
            rich.fit_content = true
            rich.scroll_active = false
            rich.add_theme_font_override("normal_font",V.HUD)
            rich.add_theme_font_override("bold_font",V.DISPLAY)
            rich.add_theme_color_override("default_color",V.BLUE)
            rich.tooltip_text = score.tooltip_text
            var lines := PackedStringArray()
            for line in score.text.split("\n"):
                # Only format already-calculated text. No score recomputation.
                var award := line.begins_with("+")
                var font_size := roundi(T.unit(T.RESULTS.award_font if award else T.RESULTS.score_font))
                lines.append('[center][font_size=%d]%s%s%s[/font_size][/center]' % [font_size,'[b][color=#%s]' % V.BLUE.to_html(false) if award else '',line,'[/color][/b]' if award else ''])
            rich.text = "\n".join(lines)
            card.add_child(rich)
            var index := score.get_index()
            column.add_child(card)
            column.move_child(card,index)
            score.hide()
        panel.set_meta("ui_result_styled",true)
        var fit := Node.new()
        fit.set_script(preload("res://scripts/ui_result_fit.gd"))
        fit.game = game
        panel.add_child(fit)
    if is_instance_valid(game.result_vehicle):
        game.result_vehicle.custom_minimum_size.y = T.unit(T.RESULTS.car_height)
        game.result_vehicle.clip_contents = false
        if not game.result_vehicle.has_meta("ui_result_stage"):
            game.result_vehicle.get_child(0).hide()
            var platform := Control.new()
            platform.set_script(preload("res://scripts/production_stage.gd"))
            platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
            platform.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
            platform.anchor_left = 0.5
            platform.anchor_right = 0.5
            platform.offset_left = -T.unit(T.RESULT_PLATFORM_WIDTH)/2.0
            platform.offset_right = T.unit(T.RESULT_PLATFORM_WIDTH)/2.0
            game.result_vehicle.add_child(platform)
            game.result_vehicle.move_child(platform,0)
            game.result_vehicle.set_meta("ui_result_stage",platform)
        var product: Label = game.result_vehicle.get_parent().get_child(game.result_vehicle.get_index()+1)
        product.add_theme_font_size_override("font_size",roundi(T.unit(T.RESULTS.product_font)))
    for child in column.get_children():
        if child is Button:
            var primary: bool = child.name in ["NextButton","FinishButton","RetryButton"]
            Shared.button(child,primary,T.RESULTS.primary_height if primary else T.RESULTS.secondary_height)
        elif child is Label and child!=game.result_title and child!=column.get_child(0):
            if child.name!="ScoreSummary" and child.text!=game.level.vehicle_name:
                child.add_theme_font_override("font",V.HUD)
                child.add_theme_font_size_override("font_size",roundi(T.unit(T.RESULTS.summary_font)))
    var rating: Control = game.popup.find_child("EarnedGears",true,false)
    if rating:
        rating.custom_minimum_size = T.RESULTS.rating*T.REFERENCE_H
