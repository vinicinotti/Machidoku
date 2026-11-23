extends SceneTree
const Loader = preload("res://scripts/level_loader.gd")
const Progress = preload("res://scripts/progress_store.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
var checks := 0
var failures: Array[String] = []
var app
var levels: Array[Dictionary]
var output := ProjectSettings.globalize_path("res://../artifacts")

func _initialize() -> void:
    call_deferred("run")


func await_result(target) -> void:
    var deadline := Time.get_ticks_msec()+4000
    while is_instance_valid(target) and (not is_instance_valid(target.popup) or target.result_panel.modulate.a<0.99) and Time.get_ticks_msec()<deadline:
        await process_frame
    await frames(3)

func frames(count: int = 8) -> void:
    for i in range(count):
        await process_frame

func expect(condition: bool, message: String) -> void:
    checks += 1
    if condition:
        print("PASS ", message)
    else:
        failures.append(message)
        printerr("FAIL ", message)

func snapshot(name: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        expect(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "render " + name)

func completed_before(id: int) -> Array:
    var result: Array = []
    for value in range(1, id):
        result.append(value)
    return result

func win(game, errors: int = 0) -> void:
    var added := 0
    for r in range(int(game.level.size)):
        for c in range(int(game.level.size)):
            var candidate := Vector2i(r, c)
            if added < errors and game.model.can_mark(candidate) and not game.model.solution.has(candidate):
                game.model.toggle_specialist(candidate)
                added += 1
    for coordinate in game.level.solution:
        var pos := Vector2i(int(coordinate[0]), int(coordinate[1]))
        if game.model.can_mark(pos):
            game.model.toggle_specialist(pos)
    await await_result(game)
    await frames()

func run() -> void:
    create_timer(90).timeout.connect(func(): printerr("CAMPAIGN TEST TIMEOUT"); quit(2))
    root.size = Vector2i(1100, 820)
    levels = Loader.load_levels()
    expect(levels.size() == 60, "60 published levels load")
    if levels.size() != 60:
        quit(1)
        return
    for i in range(levels.size()):
        expect(int(levels[i].id) == i + 1 and Loader.validate(levels[i]), "ordered valid level %d" % (i + 1))
    for product in Worlds.world("automotive").products:
        var batch := Worlds.product_levels(levels, "automotive", product.id)
        expect(batch.size() == 15 and int(batch[0].id) == int(product.start_id), "catalogue batch " + product.id)
        expect(load(product.asset) is Texture2D, "product asset loads: " + product.id)
        expect(int(product.first_level) == int(batch[0].id) and int(product.last_level) == int(batch[-1].id), "product exposes campaign boundaries: " + product.id)
        expect(not product.display_name.is_empty() and product.vehicle_asset == product.asset, "product exposes separator name and vehicle: " + product.id)
    app = load("res://scenes/Main.tscn").instantiate()
    app.progress_path = "user://tests/campaign.json"
    Progress.new(app.progress_path).reset(levels)
    root.add_child(app)
    await frames()
    expect(app.screen.name == "Home" and app.find_child("SelectLevelButton", true, false) == null, "phase list is integrated in Home")
    check_home_order(1)
    expect(app.screen.find_child("Level16", true, false) == null, "future locked phases are absent from descending history")
    var selection = app.screen
    app.start_level(15)
    expect(app.screen == selection, "locked phase cannot be opened through application API")
    app.find_child("PlayButton", true, false).pressed.emit()
    await frames()
    expect(int(app.screen.level.id) == 1, "unlocked selection opens actual gameplay")
    var desktop_board: float = app.screen.board.get_global_rect().size.x
    var master_factor := minf(root.size.x/1672.0,root.size.y/941.0)
    expect(is_equal_approx(app.screen.board.get_global_rect().size.x,584.0*master_factor), "desktop board follows master frame proportions")
    expect(app.screen.rules_row.columns == 1 and app.screen.rules_row.get_parent() == app.screen.rules_rail, "desktop rules stack in left rail")
    expect(app.screen.rules_rail.get_global_rect().end.x < app.screen.board.get_global_rect().position.x, "rules stay to the left of board")
    await snapshot("campaign_game_desktop")
    for boundary in [15, 30, 45]:
        set_campaign_cursor(boundary)
        app.start_level(boundary - 1)
        await frames()
        await win(app.screen)
        expect(app.screen.popup.find_child("EarnedGears", true, false).active == 3, "perfect boundary win earns three gears")
        expect(app.progress.best_gears(boundary) == 3, "boundary rating is persisted")
        expect(int(app.progress.data.highest_unlocked_level) == boundary + 1, "unlock %d -> %d" % [boundary, boundary + 1])
        expect(int(app.progress.data.current_level) == boundary + 1, "Continue advances at product boundary %d" % boundary)
        expect(app.screen.popup.find_child("ProductUnlock", true, false).text.contains(levels[boundary].vehicle_name), "victory names newly unlocked product")
        expect(app.progress.product_completed(levels, "automotive", levels[boundary - 1].product), "product completion derived from all fifteen phases")
        if boundary == 15:
            await snapshot("campaign_product_unlock")
            root.size = Vector2i(360, 700)
            await frames()
            expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(app.screen.result_panel.get_global_rect()), "unlock popup fits minimum portrait")
            await snapshot("campaign_unlock_portrait")
            root.size = Vector2i(1100, 820)
            await frames()
        app.screen.popup.find_child("NextButton", true, false).pressed.emit()
        await frames()
        expect(int(app.screen.level.id) == boundary + 1 and app.screen.level.product == levels[boundary].product, "Next opens correct next product")
        app.show_menu()
        await frames()
        check_home_order(boundary + 1)
        if boundary == 15:
            app.show_menu()
            await frames()
            check_home_order(16)
            await snapshot("home_phase16_desktop")
            app.screen.scroll.scroll_vertical = 1000
            await frames()
            app.show_menu()
            await frames()
            expect(app.screen.scroll.scroll_vertical == 0, "Home always returns to current phase at top")
            root.size = Vector2i(390, 844)
            await frames()
            check_home_order(16)
            await snapshot("home_phase16_portrait")
            root.size = Vector2i(1100, 820)
            await frames()

    for current in [18, 32, 47]:
        set_campaign_cursor(current)
        app.show_menu()
        await frames()
        check_home_order(current)
        if current == 18:
            check_separator_boundary("sedan", 16, 15)
            await snapshot("home_phase18_desktop")

    set_campaign_cursor(42)
    app.show_menu()
    await frames()
    expect(app.screen.find_child("Level07", true, false).get_meta("level_status") == "COMPLETED", "completed selection has completed visual state")
    expect(app.screen.featured_id == 42 and app.screen.find_child("Level43", true, false) == null, "Home current phase and unlock boundary match progress")
    check_home_order(42)
    await snapshot("home_phase42_desktop")
    root.size = Vector2i(390, 844)
    await frames()
    check_home_order(42)
    await snapshot("home_phase42_portrait")
    root.size = Vector2i(360, 700)
    await frames()
    check_home_order(42)
    await snapshot("home_phase42_minimum")
    root.size = Vector2i(390, 844)
    await frames()
    var replay_button = app.screen.find_child("Level07", true, false)
    app.screen.scroll.ensure_control_visible(replay_button)
    await frames()
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(replay_button.get_global_rect()), "replay is reachable by vertical scrolling")
    app.screen.find_child("Level07", true, false).pressed.emit()
    await frames()
    expect(int(app.screen.level.id) == 7 and int(app.progress.data.current_level) == 42, "reopening completed phase preserves Continue cursor")
    await win(app.screen, 1)
    expect(app.progress.best_gears(7) == 2 and app.screen.popup.find_child("EarnedGears", true, false).active == 2, "one mistake awards two gears in real game")
    expect(int(app.progress.data.highest_unlocked_level) == 42 and int(app.progress.data.current_level) == 42, "replay completion never regresses unlock or Continue")
    app.screen.popup.find_child("ReplayButton", true, false).pressed.emit()
    await frames()
    expect(int(app.screen.level.id) == 7 and not app.screen.model.over and app.screen.model.lives == 3, "Replay starts a fresh same-phase match")
    await win(app.screen, 2)
    expect(app.progress.best_gears(7) == 2 and app.screen.popup.find_child("EarnedGears", true, false).active == 1, "worse replay shows earned one gear while preserving best two")
    app.screen.popup.find_child("ReplayButton", true, false).pressed.emit()
    await frames()
    await win(app.screen)
    expect(app.progress.best_gears(7) == 3, "perfect replay improves best score")

    app.show_menu()
    await frames()
    app.find_child("PlayButton", true, false).pressed.emit()
    await frames()
    expect(int(app.screen.level.id) == 42, "Continue returns to campaign phase after replay")
    var reopened = Progress.new(app.progress_path)
    reopened.load_progress(levels)
    expect(int(reopened.data.current_level) == 42 and int(reopened.data.highest_unlocked_level) == 42 and reopened.best_gears(7) == 3, "replay progress and score survive save reload")
    var old_path := "user://tests/campaign_legacy.json"
    var file := FileAccess.open(old_path, FileAccess.WRITE)
    file.store_string(JSON.stringify({"version":1,"highest_unlocked_level":15,"current_level":15,"completed_levels":completed_before(16),"settings":{"sound":false},"level_stats":{"1":{"completions":3,"best_errors":1}}}))
    file.close()
    var old = Progress.new(old_path)
    old.load_progress(levels)
    expect(int(old.data.highest_unlocked_level) == 16 and int(old.data.current_level) == 16, "old completed-Hatch save unlocks and continues Sedan")
    expect(old.data.settings.sound == false and int(old.data.level_stats["1"].completions) == 3, "legacy settings and statistics preserved")
    expect(old.best_gears(1) == 2 and old.best_gears(2) == -1, "legacy known scores derive from errors; missing performance remains unknown")
    expect(old.save(), "legacy save remains writable without schema migration")
    reopened.load_progress(levels.slice(0, 15))
    expect(int(reopened.data.highest_unlocked_level) == 42, "temporary smaller catalogue cannot reduce highest unlock")
    expect(reopened.data.completed_levels.size() == 41, "temporary smaller catalogue preserves completed phases")
    var rating_store = Progress.new("user://tests/gear_scores.json")
    rating_store.reset(levels)
    expect(Progress.gears_for_errors(0) == 3 and Progress.gears_for_errors(1) == 2 and Progress.gears_for_errors(2) == 1, "gear formula covers all wins")
    expect(not rating_store.complete(levels[0], levels[1], 3) and rating_store.data.completed_levels.is_empty(), "zero-gear defeat cannot record completion")
    var scores := [1, 2, 2, 3, 3]
    var errors := [2, 1, 2, 0, 1]
    for i in range(errors.size()):
        expect(rating_store.complete(levels[0], levels[1], errors[i]) and rating_store.best_gears(1) == scores[i], "best score monotonic replay %d" % i)
    var saved_rating = Progress.new("user://tests/gear_scores.json")
    saved_rating.load_progress(levels)
    expect(saved_rating.best_gears(1) == 3 and int(saved_rating.data.level_stats["1"].last_gears) == 2, "best and latest ratings survive reopening")
    root.size = Vector2i(1448, 1086)
    await frames()
    await snapshot("campaign_game_large")
    var large_board: float = app.screen.board.get_global_rect().size.x
    set_campaign_cursor(60)
    app.progress.data.completed_levels = completed_before(61)
    app.progress.data.level_stats["60"] = {"completions":1,"best_errors":0}
    app.show_menu()
    await frames()
    check_home_order(60)
    check_separator_boundary("sport_coupe", 46, 45)
    check_separator_boundary("suv", 31, 30)
    check_separator_boundary("sedan", 16, 15)
    check_separator_boundary("hatch", 1, 0)
    expect(app.screen.find_child("FeaturedGears", true, false).active == 3, "final phase rating remains visible in completed campaign")
    root.size = Vector2i(360, 700)
    await frames()
    check_home_order(60)
    await snapshot("home_completed_minimum")
    var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"desktop_board_pixels":desktop_board,"large_board_pixels":large_board}
    FileAccess.open(output.path_join("campaign_tests.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
    print("CAMPAIGN RESULT: ", checks, " checks, ", failures.size(), " failures")
    app.queue_free()
    await frames()
    quit(0 if failures.is_empty() else 1)

func check_home_order(current: int) -> void:
    var home = app.screen
    expect(home.featured_id == current and home.page.get_child(0).get_meta("level_id") == current, "featured current phase %d is first" % current)
    var expected: Array[int] = []
    for id in range(current - 1, 0, -1):
        expected.append(id)
    expect(home.row_ids == expected, "history is one descending column at %d" % current)
    expect(home.find_children("*", "GridContainer", true, false).is_empty(), "Home has no phase grids")
    expect(not home.row_ids.has(current), "featured phase is not duplicated in history at %d" % current)
    var expected_sequence: Array[String] = []
    for id in range(current, 0, -1):
        expected_sequence.append("level:%d" % id)
        var level := levels[id - 1]
        var product := Worlds.product(level.world, level.product)
        if id == int(product.first_level):
            expected_sequence.append("product:%s:%s" % [level.world, product.id])
    var actual_sequence: Array[String] = []
    for child in home.page.get_children():
        if child.has_meta("level_id"):
            actual_sequence.append("level:%d" % int(child.get_meta("level_id")))
        else:
            actual_sequence.append("product:%s:%s" % [child.get_meta("world"), child.get_meta("product")])
    expect(actual_sequence == expected_sequence, "every product footer follows its first phase, including featured, at %d" % current)
    var featured_product := Worlds.product(levels[current - 1].world, levels[current - 1].product)
    if current == int(featured_product.first_level):
        expect(home.page.get_child(1).get_meta("product", "") == featured_product.id, "first-level featured card is immediately followed by its product footer at %d" % current)
    else:
        expect(int(home.page.get_child(1).get_meta("level_id", -1)) == current - 1, "no product heading interrupts featured card and history at %d" % current)
    for marker in home.markers:
        var product := Worlds.product(marker.get_meta("world"), marker.get_meta("product"))
        var preceding = home.page.get_child(marker.get_index() - 1)
        expect(int(preceding.get_meta("level_id")) == int(product.first_level), "product separator sits below its first phase: " + product.id)
    expect(home.page.size.x <= root.size.x - 32, "Home has no horizontal overflow")
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(home.find_child("PlayButton", true, false).get_global_rect()), "current phase CTA remains visible at top")
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(home.exit_button.get_global_rect()), "exit icon stays visible at top right")

func check_separator_boundary(product_id: String, first: int, following: int) -> void:
    var home = app.screen
    var matches: Array = []
    for marker in home.markers:
        if marker.get_meta("product") == product_id:
            matches.append(marker)
    expect(matches.size() == 1, "exactly one footer for " + product_id)
    if matches.size() != 1:
        return
    var position: int = matches[0].get_index()
    expect(int(home.page.get_child(position - 1).get_meta("level_id", -1)) == first, "%s footer follows phase %d" % [product_id, first])
    if following > 0:
        expect(position + 1 < home.page.get_child_count() and int(home.page.get_child(position + 1).get_meta("level_id", -1)) == following, "%s footer precedes phase %d" % [product_id, following])
    else:
        expect(position == home.page.get_child_count() - 1, "Hatch Compact footer is the final history entry after phase 1")

func set_campaign_cursor(id: int) -> void:
    app.progress.data.highest_unlocked_level = id
    app.progress.data.current_level = id
    app.progress.data.completed_levels = completed_before(id)
    # Representative historical ratings for the synthetic campaign fixture.
    for completed in app.progress.data.completed_levels:
        if not app.progress.data.level_stats.has(str(completed)):
            # Enough permanent gears for the boundary traversal scenario.
            app.progress.data.level_stats[str(completed)] = {"completions":1,"best_errors":0 if completed in [2, 5, 8] else completed % 3}
