extends SceneTree
## Rendered visual smoke test, with isolated progress and actual narrow windows.
const Progress = preload("res://scripts/progress_store.gd")
const Loader = preload("res://scripts/level_loader.gd")
var checks := 0
var failures: Array[String] = []
var screenshots: Array[String] = []
var output := ProjectSettings.globalize_path("res://../artifacts")
var app

func _initialize() -> void:
    call_deferred("run")

func frames(count: int = 5) -> void:
    for i in range(count):
        await process_frame

func expect(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures.append(message)
        printerr("FAIL ", message)
    else:
        print("PASS ", message)

func snapshot(name: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await RenderingServer.frame_post_draw
    var path := output.path_join(name + ".png")
    expect(root.get_texture().get_image().save_png(path) == OK, "render " + name)
    screenshots.append(path)

func fits(control: Control) -> bool:
    return Rect2(Vector2.ZERO, Vector2(root.size)).encloses(control.get_global_rect())

func run() -> void:
    create_timer(60).timeout.connect(func(): printerr("VISUAL TEST TIMEOUT"); quit(2))
    root.size = Vector2i(1280, 960)
    var preview = load("res://scenes/dev/VisualPreview.tscn").instantiate()
    root.add_child(preview)
    await frames(8)
    expect(preview.scroll.get_v_scroll_bar().max_value > 0, "preview builds a scrollable native gallery")
    # Import every file, including compatibility aliases and unused future cars.
    var svg_files: Array[String] = []
    for group in ["branding", "specialists", "vehicles", "sectors", "rules", "ui", "decoration"]:
        for file in DirAccess.get_files_at("res://assets/" + group):
            if file.ends_with(".svg"):
                svg_files.append("res://assets/" + group + "/" + file)
    var imported := true
    for path in svg_files:
        var texture = load(path)
        if not texture is Texture2D or texture.get_width() <= 0 or texture.get_height() <= 0:
            imported = false
    expect(svg_files.size() == 43 and imported, "all 43 SVGs load as Godot textures")
    for path in ["specialists/specialist_default.png", "vehicles/hatch_compact.png", "vehicles/sedan.png", "vehicles/sport_coupe.png", "decoration/factory_courtyard.png"]:
        var texture: Texture2D = load("res://assets/" + path)
        var image: Image = texture.get_image()
        expect(image.detect_alpha() != Image.ALPHA_NONE and image.get_pixel(0, 0).a < 0.01 and image.get_used_rect().has_area(), "generated art loads with real transparency: " + path)
    expect(preload("res://scripts/cell.gd").SPECIALIST is AtlasTexture, "game cells use generated sector portrait atlas")
    expect(preload("res://scripts/world_catalog.gd").vehicle(Loader.load_levels()[0]).ends_with(".png"), "production and victory use generated vehicle")
    await snapshot("visual_preview_desktop")
    for offset in [650, 1300, 1950]:
        preview.scroll.scroll_vertical = offset
        await frames()
        await snapshot("visual_preview_%d" % offset)
    root.size = Vector2i(390, 844)
    preview.scroll.scroll_vertical = 0
    await frames(8)
    expect(preview.grids[0].columns == 2, "preview adapts its columns to portrait")
    expect(preview.page.size.x <= 342, "preview has no horizontal overflow at 390 px")
    await snapshot("visual_preview_portrait")
    root.remove_child(preview)
    preview.queue_free()
    app = load("res://scenes/Main.tscn").instantiate()
    app.progress_path = "user://tests/visual.json"
    Progress.new(app.progress_path).reset(Loader.load_levels())
    root.add_child(app)
    await frames(8)
    expect(fits(app.find_child("PlayButton", true, false)), "portrait menu action fits")
    await snapshot("visual_menu_390")
    app.start_level(0)
    await frames(8)
    for window_size in [Vector2i(390, 844), Vector2i(360, 700)]:
        root.size = window_size
        await frames(8)
        var game = app.screen
        expect(not game.sidebar.visible and game.mobile_cards.visible, "portrait uses lower cards at %s" % window_size)
        expect(fits(game.board) and game.board.size.x > 250 and game.board.size.y > 250, "portrait board stays readable at %s" % window_size)
        expect(fits(game.feedback) and fits(game.production_button), "portrait feedback and card actions fit at %s" % window_size)
        await snapshot("visual_game_%dx%d" % [window_size.x, window_size.y])
    root.size = Vector2i(390, 844)
    await frames(8)
    var game = app.screen
    var original: Array = game.model.cells.duplicate()
    game.plant_button.pressed.emit()
    await frames(8)
    expect(game.mobile_details.visible and game.mobile_open == "plant", "plant card expands")
    expect(game.mobile_content.get_child_count() == 2, "expanded plant shows palette-matched sector list")
    var page_scroll = game.find_child("PageScroll", true, false)
    page_scroll.scroll_vertical = 1000
    await frames()
    expect(game.mobile_content.size.x <= 330, "two-column sector list fits narrow card")
    await snapshot("visual_plant_expanded")
    game.production_button.pressed.emit()
    await frames(8)
    page_scroll.scroll_vertical = 1000
    await frames()
    expect(game.mobile_open == "production" and game.mobile_content.get_child_count() == 1, "production card replaces expanded plant")
    await snapshot("visual_production_expanded")
    game.production_button.pressed.emit()
    await frames(8)
    page_scroll.scroll_vertical = 0
    await frames()
    expect(not game.mobile_details.visible, "production card collapses")
    expect(game.model.cells == original and game.model.lives == 3, "presentation controls never mutate puzzle or lives")
    # Both result cards must keep their action inside a real narrow viewport.
    for pos in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]:
        game.model.toggle_specialist(pos)
    await create_timer(0.15).timeout
    await frames(8)
    expect(fits(game.popup.find_child("RetryButton", true, false)), "portrait defeat action fits")
    expect(game.result_panel.modulate.a >= 0.99, "portrait defeat panel fade completes")
    await snapshot("visual_defeat_390")
    app.start_level(0)
    await frames()
    game = app.screen
    for pos in game.level.solution:
        game.model.toggle_specialist(Vector2i(int(pos[0]), int(pos[1])))
    await create_timer(0.4).timeout
    expect(fits(game.popup.find_child("NextButton", true, false)), "portrait victory action fits")
    await snapshot("visual_victory_390")
    root.size = Vector2i(1100, 820)
    await frames(8)
    expect(fits(game.result_panel), "open result card expands to desktop")
    root.size = Vector2i(360, 700)
    await frames(8)
    expect(fits(game.result_panel), "open result card reflows to minimum portrait")
    await snapshot("visual_victory_360")
    app.show_menu()
    await frames(8)
    expect(fits(app.find_child("PlayButton", true, false)), "minimum portrait menu action fits after returning")
    await snapshot("visual_menu_360")
    # A real phase-4 scene for comparison with the supplied visual reference.
    # It is independent of Main's progression and never writes a player save.
    app.visible = false
    root.size = Vector2i(1448, 1086)
    var reference_game = load("res://scenes/Game.tscn").instantiate()
    reference_game.theme = preload("res://scripts/visuals.gd").make_theme()
    reference_game.level = Loader.load_levels()[3]
    reference_game.total_levels = Loader.load_levels().size()
    root.add_child(reference_game)
    await frames(8)
    var added := 0
    for coordinate in reference_game.level.solution:
        var pos := Vector2i(int(coordinate[0]), int(coordinate[1]))
        if reference_game.model.can_mark(pos) and added < 2:
            reference_game.model.toggle_specialist(pos)
            added += 1
    var error_added := false
    for r in range(int(reference_game.level.size)):
        for c in range(int(reference_game.level.size)):
            var pos := Vector2i(r, c)
            if reference_game.model.can_mark(pos):
                if not error_added and not reference_game.model.solution.has(pos):
                    reference_game.model.toggle_specialist(pos)
                    error_added = true
                elif (r + c) % 3 == 0:
                    reference_game.model.mark_x(pos)
    await create_timer(0.3).timeout
    expect(reference_game.model.lives == 2 and reference_game.model.errors.size() == 1, "reference scene displays real specialist, annotation and error states")
    expect(fits(reference_game.board) and reference_game.sidebar.visible, "reference composition fits desktop")
    await check_desktop_sectors(reference_game)
    await snapshot("reference_desktop_1448x1086")
    root.size = Vector2i(1100, 820)
    await frames(8)
    await check_desktop_sectors(reference_game)
    await snapshot("reference_desktop_1100x820")
    reference_game.queue_free()
    var report := {"passed": failures.is_empty(), "checks": checks, "failures": failures, "display": DisplayServer.get_name(), "screenshots": screenshots}
    var file := FileAccess.open(output.path_join("visual_tests.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    print("VISUAL RESULT: ", checks, " checks, ", failures.size(), " failures")
    app.queue_free()
    await frames()
    quit(0 if failures.is_empty() else 1)

func check_desktop_sectors(game) -> void:
    var scroll := game.sidebar.find_child("SectorScroll", true, false) as ScrollContainer
    var last_row: Control = game.sector_rows[-1]
    var first_row: Control = game.sector_rows[0]
    expect(scroll.get_global_rect().grow(0.01).encloses(first_row.get_global_rect()), "first plant card is fully visible at %s" % root.size)
    var constant_height := true
    for card in game.sector_rows:
        constant_height = constant_height and is_equal_approx(card.size.y,64.0)
    expect(constant_height,"plant cards preserve their height at %s" % root.size)
    scroll.scroll_vertical = 10000
    await frames(4)
    expect(scroll.get_global_rect().grow(0.01).encloses(last_row.get_global_rect()),"plant scroll exposes its last card at %s" % root.size)
    var stage: Control = game.sidebar.find_child("ProductionStage", true, false)
    expect(last_row.get_global_rect().end.y <= stage.get_global_rect().position.y, "sector list and vehicle do not overlap at %s" % root.size)
    scroll.scroll_vertical = 0
    await frames(4)
