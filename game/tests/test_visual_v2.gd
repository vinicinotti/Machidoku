extends SceneTree
const Loader = preload("res://scripts/level_loader.gd")
const V = preload("res://scripts/visuals.gd")
const Progress = preload("res://scripts/progress_store.gd")
const Art = preload("res://scripts/specialist_art.gd")
const Palette = preload("res://scripts/sector_palette.gd")
const T = preload("res://scripts/ui_tokens.gd")
var game
var checks := 0
var failures: Array[String] = []
var output := ProjectSettings.globalize_path("res://../artifacts")
var desktop_bounds := {}

func rectangle(node: Control) -> Array:
    var rect := node.get_global_rect()
    return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _initialize() -> void:
    call_deferred("run")

func frames(count: int = 8) -> void:
    for i in range(count):
        await process_frame

func expect(condition: bool, message: String) -> void:
    checks += 1
    if condition:
        print("PASS ",message)
    else:
        failures.append(message)
        printerr("FAIL ",message)

func snapshot(name: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(output.path_join(name+".png"))

func verify_identity(sample) -> void:
    var consistent := true
    for cell in sample.board.cells:
        var region: int = cell.region_id
        var slot = sample.specialist_strip.portraits[region]
        var material: ShaderMaterial = cell.portrait_view.material
        consistent = consistent and cell.region_color == sample.board.region_colors[region]
        consistent = consistent and material.get_shader_parameter("sector_color") == cell.region_color
        consistent = consistent and slot.material.get_shader_parameter("sector_color") == cell.region_color
        consistent = consistent and slot.texture == cell.portrait_view.texture
        consistent = consistent and sample.specialist_strip.slots[region].get_meta("sector_id") == region
    expect(consistent,"cell, portrait and slot share real sector identity for size %d" % int(sample.level.size))

func verify_structure(sample) -> void:
    var left: Rect2 = sample.left_glass.get_global_rect()
    var frame: Rect2 = sample.board_mount.get_global_rect()
    var right: Rect2 = sample.right_glass.get_global_rect()
    var strip: Rect2 = sample.specialist_strip.get_global_rect()
    expect(left.end.x < frame.position.x and frame.end.x < right.position.x,"side panels and playable frame have distinct non-overlapping limits")
    expect(is_equal_approx(left.position.y,strip.position.y) and is_equal_approx(strip.position.y,right.position.y),"three structural tops share the same baseline")
    expect(is_equal_approx(strip.position.x,frame.position.x) and is_equal_approx(strip.size.x,frame.size.x) and strip.end.y<frame.position.y,"specialist bar aligns with frame and retains a clear vertical gap")
    expect(sample.score_row.get_parent()==sample.get_meta("ui_help_stack") and sample.controls_card.get_global_rect().grow(0.01).encloses(sample.score_row.get_global_rect()),"score belongs to the instruction component")
    expect(sample.controls_card.get_global_rect().end.y<sample.message_card.global_position.y,"instructions precede the main message without collision")
    var consistent := true
    for card in sample.sector_rows:
        consistent = consistent and is_equal_approx(card.size.y,64.0)
    expect(consistent,"sector cards retain a consistent 64px height without compression")

func verify_portrait_fit(sample) -> void:
    var bounds_ok := true
    var checked := 0
    for cell in sample.board.cells:
        if cell.portrait_view.visible:
            if cell.mark_tween:
                cell.mark_tween.kill()
            cell.mark_scale = 1.10
            checked += 1
    await frames(2)
    for cell in sample.board.cells:
        if cell.portrait_view.visible:
            bounds_ok = bounds_ok and cell.portrait_mount.clip_contents
            bounds_ok = bounds_ok and cell.portrait_mount.get_global_rect().grow(0.01).encloses(cell.portrait_view.get_global_rect())
            bounds_ok = bounds_ok and cell.get_global_rect().grow(-2).encloses(cell.portrait_mount.get_global_rect())
            cell.mark_scale = 1.0
    expect(checked>0 and bounds_ok,"portraits fit tile interior at maximum overshoot for grid %d" % int(sample.level.size))

func verify_desktop_polish(sample) -> void:
    var commands: Rect2 = sample.controls_label.get_global_rect()
    var score: Rect2 = sample.score_row.get_global_rect()
    expect(score.position.y>=commands.end.y and score.position.y-commands.end.y<=T.unit(T.FOOTER.padding),"score follows controls inside the compact left card")
    expect(sample.controls_card.get_global_rect().end.x<sample.board_mount.global_position.x and commands.size.y<50,"controls clear the central column and fit two compact lines")
    var note: Control = sample.production_panel.find_child("ProductionNote",true,false)
    expect(sample.production_panel.get_global_rect().end.y-note.get_global_rect().end.y >= 18,"production text clears rounded bottom edge by at least 18px")
    var car: Control = sample.production_panel.find_child("ProductionVehicle",true,false)
    expect(absf(car.get_global_rect().get_center().x-car.get_parent().get_global_rect().get_center().x)<0.1,"production car and platform share their horizontal center")
    var settings: Button = sample.options_button
    expect(settings.size.is_equal_approx(T.SETTINGS.size*T.REFERENCE_H) and settings.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER and settings.vertical_icon_alignment == VERTICAL_ALIGNMENT_CENTER,"settings follows the rounded-rectangle proportions with centered icon")
    var skin: StyleBoxTexture = settings.get_theme_stylebox("normal")
    var pixels := skin.texture.get_image()
    var coverage := pixels.get_used_rect()
    expect(pixels.get_width()==roundi(T.unit(T.SETTINGS.size.y)) and skin.get_texture_margin(SIDE_TOP)>0,"settings uses a moulded skin with reserved rounded corners")
    var patches_ok := true
    var surfaces: Array[Control] = []
    for card in sample.rule_cards:
        surfaces.append(card)
    surfaces.append_array([sample.lives_card,sample.difficulty_badge,sample.controls_card,sample.message_card,sample.production_panel,sample.menu_button,sample.restart_button])
    for control in surfaces:
        var face: StyleBoxTexture = control.get_theme_stylebox("normal" if control is Button else "panel")
        patches_ok = patches_ok and face.get_texture_margin(SIDE_TOP)+face.get_texture_margin(SIDE_BOTTOM)<=control.size.y
        patches_ok = patches_ok and face.get_texture_margin(SIDE_LEFT)+face.get_texture_margin(SIDE_RIGHT)<=control.size.x
    expect(patches_ok,"desktop nine-patch corner slices never overlap within their containers")
    var visible_portraits := 0
    var fill_ok := true
    for cell in sample.board.cells:
        if cell.portrait_view.visible:
            visible_portraits += 1
            fill_ok = fill_ok and cell.portrait_view.size.y / cell.size.y > 0.82
    expect(visible_portraits>0 and fill_ok,"desktop portraits occupy more than 82 percent of tile height before animation")

func identity_gallery() -> void:
    if DisplayServer.get_name() == "headless":
        return
    root.size = Vector2i(1422,1106)
    await frames()
    var gallery := Control.new()
    gallery.z_index = 50
    root.add_child(gallery)
    var background := ColorRect.new()
    background.color = V.PAPER
    background.size = Vector2(root.size)
    gallery.add_child(background)
    var brand := V.brand(50,72)
    brand.position = Vector2(420,20)
    gallery.add_child(brand)
    var colors := [Palette.COLORS[0],Palette.COLORS[2],Palette.COLORS[6],Palette.COLORS[1]]
    var views: Array[TextureRect] = []
    for row in range(colors.size()):
        for column in range(Art.KEYS.size()):
            var panel := Panel.new()
            panel.position = Vector2(16+column*139,160+row*215)
            panel.size = Vector2(132,190)
            panel.add_theme_stylebox_override("panel",V.box(colors[row],14,0))
            gallery.add_child(panel)
            var view := V.texture("res://assets/specialists/%s.tres" % Art.KEYS[column],Vector2.ZERO)
            view.stretch_mode = TextureRect.STRETCH_SCALE
            view.position = Vector2(8,6)
            view.size = Vector2(116,145)
            view.material = Art.for_sector(view.texture,colors[row])
            panel.add_child(view)
            views.append(view)
            var label := V.label(Art.KEYS[column],"HudLabel",17)
            label.position = Vector2(5,158)
            panel.add_child(label)
    await frames()
    await RenderingServer.frame_post_draw
    var rendered := root.get_texture().get_image()
    rendered.save_png(output.path_join("consolidated_specialist_colors.png"))
    var skin_preserved := true
    for index in range(views.size()):
        var view := views[index]
        var row := index / Art.KEYS.size()
        var expected: Color = colors[row]
        var matching := 0
        var chromatic := 0
        for y in range(18,40):
            for x in range(40,76):
                var pixel := rendered.get_pixelv(Vector2i(view.global_position)+Vector2i(x,y))
                if pixel.s > 0.30 and pixel.v > 0.30:
                    chromatic += 1
                    var delta := absf(pixel.h-expected.h)
                    if minf(delta,1.0-delta) < 0.075:
                        matching += 1
        expect(chromatic > 20 and float(matching)/maxi(1,chromatic) > 0.75,"rendered PPE matches sector %d: %s" % [row,Art.KEYS[index % Art.KEYS.size()]])
        var face := rendered.get_pixelv(Vector2i(view.global_position)+Vector2i(58,80))
        var original := rendered.get_pixelv(Vector2i(views[index % Art.KEYS.size()].global_position)+Vector2i(58,80))
        # The original PNG has slightly translucent face pixels; background
        # compositing can differ by up to 3/255 without changing the skin dye.
        skin_preserved = skin_preserved and absf(face.r-original.r) <= 3.0/255.0 and absf(face.g-original.g) <= 3.0/255.0 and absf(face.b-original.b) <= 3.0/255.0
    expect(skin_preserved,"sector dye preserves face colors within source-alpha tolerance")
    gallery.queue_free()
    await frames()

func master_preview(levels: Array[Dictionary]) -> void:
    root.size = Vector2i(1672,941)
    var sample = load("res://scenes/Game.tscn").instantiate()
    sample.theme = V.make_theme()
    sample.level = levels[0]
    sample.total_levels = levels.size()
    root.add_child(sample)
    await frames(12)
    var placed := 0
    for coordinate in sample.level.solution:
        var pos := Vector2i(int(coordinate[0]),int(coordinate[1]))
        if sample.model.can_mark(pos) and placed < 2:
            sample.model.toggle_specialist(pos)
            placed += 1
    await create_timer(1.35).timeout
    expect(not sample.model.over and sample.model.lives == 3,"master capture uses a real unfinished phase without invalid pieces")
    expect(sample.specialist_strip.slots.size() == 5,"five-sector phase keeps five logical slots despite six in illustration")
    expect(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(sample.sidebar.get_global_rect()),"master plant fits the reference viewport")
    var last: Control = sample.sector_rows[-1]
    var sector_scroll: ScrollContainer = sample.sidebar.find_child("SectorScroll",true,false)
    expect(sector_scroll.get_global_rect().encloses(last.get_global_rect()),"all five master sector cards fit without scrolling")
    expect(rectangle(sample.left_glass) == [179.0,105.0,310.0,590.0],"left glass reserves a 16px separation from the frame")
    expect(rectangle(sample.right_glass) == [1157.0,105.0,378.0,786.0],"right glass aligns with the other structural tops")
    expect(rectangle(sample.rule_cards[0]) == [198.0,349.0,272.0,72.0],"rule card uses balanced inner margins")
    verify_structure(sample)
    await verify_portrait_fit(sample)
    verify_desktop_polish(sample)
    var measured := {"reference_size":[1672,941],"menu":rectangle(sample.menu_button),"brand":rectangle(sample.brand_center),"settings":rectangle(sample.options_button),"restart":rectangle(sample.restart_button),"left_glass":rectangle(sample.left_glass),"difficulty":rectangle(sample.difficulty_badge),"rules":[],"lives":rectangle(sample.lives_card),"strip":rectangle(sample.specialist_strip),"frame":rectangle(sample.board_mount),"board":rectangle(sample.board),"right_glass":rectangle(sample.right_glass),"plant_heading":rectangle(sample.plant_heading),"sector_cards":[],"production":rectangle(sample.production_panel),"message":rectangle(sample.message_card),"instructions":rectangle(sample.controls_card)}
    for card in sample.rule_cards:
        measured.rules.append(rectangle(card))
    for card in sample.sector_rows:
        measured.sector_cards.append(rectangle(card))
    FileAccess.open(output.path_join("master_geometry.json"),FileAccess.WRITE).store_string(JSON.stringify(measured,"  "))
    await snapshot("master_desktop_1672x941")
    root.size = Vector2i(1920,1020)
    await frames(12)
    expect(absf(sample.desktop_stage.position.x-53.7938)<0.1 and absf(sample.desktop_stage.position.y)<0.1,"1920x1020 uses centered safe frame with 53.8px side margins")
    await snapshot("master_desktop_1920x1020")
    root.size = Vector2i(2560,1080)
    await frames(12)
    expect(is_equal_approx(sample.desktop_stage.scale.x,sample.desktop_stage.scale.y) and sample.desktop_stage.position.x>300,"ultrawide preserves uniform safe frame scale")
    await snapshot("master_desktop_ultrawide")
    sample.queue_free()
    await frames()

func run() -> void:
    create_timer(70).timeout.connect(func():printerr("V2 TEST TIMEOUT");quit(2))
    root.size = Vector2i(1672,941)
    root.content_scale_size = Vector2i.ZERO
    var levels := Loader.load_levels()
    game = load("res://scenes/Game.tscn").instantiate()
    game.theme = V.make_theme()
    game.level = levels[20]
    game.total_levels = levels.size()
    game.product_phase = 6
    game.product_total = 15
    root.add_child(game)
    await frames(14)
    print("V2 GEOMETRY ",JSON.stringify({"sidebar":str(game.sidebar.get_global_rect()),"scroll":str(game.sidebar.find_child("SectorScroll",true,false).size),"row":str(game.sector_rows[0].size),"rules":str(game.rules_row.size),"rule_card":str(game.rule_cards[0].size),"strip":str(game.specialist_strip.size)}))
    desktop_bounds = {"frame":rectangle(game.board_mount),"strip":rectangle(game.specialist_strip),"plant":rectangle(game.sidebar),"menu":rectangle(game.menu_button),"restart":rectangle(game.restart_button)}
    expect(desktop_bounds.frame == [505.0,218.0,638.0,588.0],"board frame follows measured master bounds")
    expect(absf(float(desktop_bounds.strip[3])-T.unit(T.STRIP.height))<0.1 and desktop_bounds.strip.slice(0,3)==[505.0,105.0,638.0],"specialist strip shares the frame's horizontal alignment")
    expect(desktop_bounds.plant == [1157.0,105.0,378.0,786.0],"plant aligns with the other main blocks")
    verify_structure(game)
    await verify_portrait_fit(game)
    verify_desktop_polish(game)
    expect(game.rules_row.get_global_rect().end.y < game.lives_box.global_position.y,"rules and lives remain separated")
    expect(game.left_glass.get_parent() == game.rules_rail and game.right_glass.get_parent().get_parent() == game.sidebar,"one structural glass per desktop side panel")
    expect(game.find_children("GlassSurface","ColorRect",true,false).size() == 2,"no nested or per-card glass surfaces")
    expect(game.glass_backdrop.copy_mode == BackBufferCopy.COPY_MODE_VIEWPORT and game.get_child(1) == game.glass_backdrop,"single shared glass capture precedes UI")
    expect(game.brand_row.get_child(1).get_theme_font("font").base_font.resource_path == T.WORDMARK.font,"wordmark alone uses Baloo 2 ExtraBold")
    expect(game.product_title.get_theme_font("font") == V.DISPLAY,"main titles use Barlow Semi Condensed ExtraBold")
    verify_identity(game)
    var visible_terms := ""
    for label in game.find_children("*","Label",true,false):
        visible_terms += label.text.to_lower()+"\n"
    expect(not visible_terms.contains("operador") and not visible_terms.contains("/ 7 especialistas"),"player terminology is specialist and there is no numerical discovery counter")
    await snapshot("visual_v2_desktop")
    await snapshot("master_desktop_7_sectors")
    var initial: Array[bool] = game.specialist_strip.found.duplicate()
    var target := Vector2i(-1,-1)
    for coordinate in game.level.solution:
        var pos := Vector2i(int(coordinate[0]),int(coordinate[1]))
        if game.model.can_mark(pos):
            target = pos
            break
    var region := int(game.level.regions[target.x][target.y])
    for r in range(int(game.level.size)):
        for c in range(int(game.level.size)):
            var pos := Vector2i(r,c)
            if game.model.can_mark(pos) and pos != target and (r+c)%3 != 0:
                game.model.mark_x(pos)
    game.model.toggle_specialist(target)
    await create_timer(0.25).timeout
    await frames(2)
    expect(game.specialist_strip.found[region],"correct sector slot reveals its own specialist")
    for i in range(initial.size()):
        if i != region:
            expect(game.specialist_strip.found[i] == initial[i],"unrelated slot unchanged: %d"%i)
    expect(game.score_popups.size() == 1 and game.score_popups[0].modulate.a > 0.95,"score popup remains readable after 250ms")
    await snapshot("visual_v2_feedback")
    await create_timer(0.35).timeout
    expect(game.score_popups[0].modulate.a > 0.95,"score popup remains fully readable at 600ms")
    await create_timer(0.65).timeout
    expect(not is_instance_valid(game.score_popups[0]),"score popup cleans up after approximately 1.2 seconds")
    await snapshot("consolidated_revealed_desktop")
    game.model.toggle_specialist(target)
    expect(not game.specialist_strip.found[region],"removing specialist restores matching silhouette")
    for coordinate in game.level.solution:
        var other := Vector2i(int(coordinate[0]),int(coordinate[1]))
        var other_region := int(game.level.regions[other.x][other.y])
        if other_region > 0 and not initial[other_region] and game.model.can_mark(other):
            game.model.toggle_specialist(other)
            expect(game.specialist_strip.found[other_region] and not game.specialist_strip.found[0],"discovery can reveal a later slot without filling the first missing slot")
            game.model.toggle_specialist(other)
            break
    for viewport in [Vector2i(1100,820),Vector2i(1920,1080),Vector2i(390,844),Vector2i(360,700)]:
        root.size = viewport
        await frames(12)
        expect(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(game.board.get_global_rect()),"board fits "+str(viewport))
        expect(game.board.get_global_rect().size.x > 250,"readable board at "+str(viewport))
        expect(game.glass_backdrop.copy_mode == (BackBufferCopy.COPY_MODE_VIEWPORT if viewport.x >= 900 else BackBufferCopy.COPY_MODE_DISABLED),"glass capture follows desktop visibility at "+str(viewport))
        await snapshot("visual_v2_%dx%d"%[viewport.x,viewport.y])
    game.show_options()
    await frames()
    expect(is_instance_valid(game.options_overlay) and not game.model._clock_active,"options modal exists and suspends effective time")
    await snapshot("visual_v2_options_mobile")
    game.options_overlay.find_child("CloseOptions",true,false).pressed.emit()
    await frames()
    expect(not is_instance_valid(game.options_overlay),"options close without modifying puzzle")
    game.queue_free()
    await frames()
    for dimension in [5,6,8,9]:
        for level in levels:
            if int(level.size) == dimension:
                var sample = load("res://scenes/Game.tscn").instantiate()
                sample.theme = V.make_theme()
                sample.level = level
                sample.total_levels = levels.size()
                root.add_child(sample)
                await frames()
                expect(sample.specialist_strip.slots.size() == dimension,"dynamic specialist strip for %d sectors"%dimension)
                verify_identity(sample)
                expect(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(sample.specialist_strip.get_global_rect()),"strip fits mobile at %d sectors"%dimension)
                for coordinate in sample.level.solution:
                    var pos := Vector2i(int(coordinate[0]),int(coordinate[1]))
                    if sample.model.can_mark(pos):
                        sample.model.toggle_specialist(pos)
                        break
                await frames(2)
                await verify_portrait_fit(sample)
                sample.queue_free()
                await frames()
                break
    var main = load("res://scenes/Main.tscn").instantiate()
    main.progress_path = "user://tests/visual_v2.json"
    var store = Progress.new(main.progress_path)
    store.reset(levels)
    store.data.completed_levels = [1,2]
    store.data.current_level = 3
    store.data.highest_unlocked_level = 3
    store.data.wallet_points = 500
    store.data.level_stats = {"1":{"best_score":100,"best_gears":3},"2":{"best_score":200,"best_gears":2}}
    store.save()
    root.add_child(main)
    await frames()
    expect(main.find_child("TotalScore",true,false).text == "300","Home derives overall performance from best scores once per phase")
    expect(main.find_child("WalletPoints",true,false).text.contains("500"),"Home distinguishes available wallet from performance total")
    await snapshot("visual_v2_home_mobile")
    main.start_level(0)
    await frames()
    var before: Array = main.screen.model.cells.duplicate()
    main.screen.options_button.pressed.emit()
    await frames()
    main.screen.options_overlay.find_children("*","CheckBox",true,false)[0].button_pressed = true
    await frames()
    var reopened = Progress.new(main.progress_path)
    reopened.load_progress(levels)
    expect(reopened.data.settings.reduce_motion and reopened.data.wallet_points == 500,"options use existing save while preserving wallet")
    expect(main.screen.model.cells == before and main.screen.board.reduced_motion,"reduced effects change presentation without changing puzzle")
    main.queue_free()
    await frames()
    await identity_gallery()
    await master_preview(levels)
    FileAccess.open(output.path_join("visual_v2_tests.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"desktop_bounds":desktop_bounds},"  "))
    print("V2 RESULT: ",checks," checks, ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
