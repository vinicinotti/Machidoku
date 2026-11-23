extends SceneTree
const State = preload("res://scripts/game_state.gd")
const Loader = preload("res://scripts/level_loader.gd")
const Progress = preload("res://scripts/progress_store.gd")
const Rules = preload("res://scripts/scoring_rules.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
var checks := 0
var failures: Array[String] = []
var levels: Array[Dictionary]
var app
var output := ProjectSettings.globalize_path("res://../artifacts")

func _initialize() -> void:
    call_deferred("run")

func expect(condition: bool, message: String) -> void:
    checks += 1
    if condition:
        print("PASS ", message)
    else:
        failures.append(message)
        printerr("FAIL ", message)


func await_result(target) -> void:
    var deadline := Time.get_ticks_msec()+4000
    while is_instance_valid(target) and (not is_instance_valid(target.popup) or target.result_panel.modulate.a<0.99) and Time.get_ticks_msec()<deadline:
        await process_frame
    await frames(3)

func frames(count: int = 6) -> void:
    for i in range(count):
        await process_frame

func pieces(state) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for cell in state.level.solution:
        var pos := Vector2i(int(cell[0]), int(cell[1]))
        if state.can_mark(pos):
            result.append(pos)
    return result

func blanks(state) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for r in range(int(state.level.size)):
        for c in range(int(state.level.size)):
            var pos := Vector2i(r, c)
            if state.can_mark(pos) and not state.solution.has(pos):
                result.append(pos)
    return result

func test_actions() -> void:
    var state = State.new(levels[-1])
    var correct := pieces(state)
    var expected := [100, 105, 110, 115, 120, 120]
    var total := 0
    for i in range(6):
        state.toggle_specialist(correct[i])
        total += expected[i]
        expect(state.operator_score == total and state.operator_streak == i + 1, "correct operator %d scores %d with capped streak" % [i + 1, expected[i]])
    expect(Rules.operator_points(100) == 120, "streak has a hard 1.20 cap")
    state = State.new(levels[-1])
    correct = pieces(state)
    state.toggle_specialist(correct[0])
    state.toggle_specialist(correct[1])
    state.mark_x(blanks(state)[0])
    expect(state.operator_streak == 0, "X action resets operator streak")
    state.toggle_specialist(correct[2])
    expect(state.operator_score == 305 and state.operator_streak == 1, "operator after X restarts at 100")
    var prior: int = state.run_score
    state.toggle_specialist(blanks(state)[1])
    expect(state.run_score == prior and state.operator_streak == 0 and state.lives == 2, "wrong specialist adds no score, resets streak and consumes the existing one life")
    state.toggle_specialist(correct[0])
    state.toggle_specialist(correct[0])
    expect(state.operator_score == 305 and state.operator_streak == 0, "removing and replacing a specialist cannot farm points or combos")
    for count in [1, 2, 3, 4, 5, 6]:
        state = State.new(levels[0])
        var notes := blanks(state)
        state.begin_x_action()
        for i in range(count):
            state.mark_x(notes[i])
        state.end_x_action()
        expect(state.x_score == 0, "gesture with %d X records notes without evaluating the answer" % count)
        for i in range(count):
            state.mark_x(notes[i], true)
        state.begin_x_action()
        for i in range(count):
            state.mark_x(notes[i])
        state.end_x_action()
        for pos in pieces(state):
            state.toggle_specialist(pos)
        expect(state.x_score == [20, 50, 90, 140, 200, 270][count - 1], "erasing and re-marking %d X cannot farm points" % count)
    state = State.new(levels[0])
    var notes := blanks(state)
    var wrong_note := pieces(state)[0]
    state.begin_x_action()
    for pos in notes.slice(0, 4):
        state.mark_x(pos)
    state.mark_x(wrong_note)
    state.end_x_action()
    expect(state.x_score == 0 and state.lives == 3 and state.state_at(wrong_note) == State.CellState.X, "all five annotations stay unevaluated and neutral while solving")
    for pos in pieces(state):
        state.toggle_specialist(pos)
    expect(state.x_score == 140, "after victory a five-note group scores only its four correct X")
    state = State.new(levels[0])
    state.begin_x_action()
    state.mark_x(pieces(state)[0])
    state.cancel_x_action()
    state.toggle_specialist(pieces(state)[0])
    expect(state.operator_streak == 1 and state.x_score == 0, "first click converted into specialist does not score as X")
    for pos in pieces(state):
        state.toggle_specialist(pos)
    expect(state.won and not state.score_result.is_empty() and state.score_result.time_bonus == 0, "old level without reference time wins with no arbitrary time bonus")
    expect(state.run_score == roundi((state.operator_score + Rules.COMPLETION_BONUS) * 1.30), "completion and quality multiplier applied once after validation")
    var final: int = state.run_score
    state.finish_score()
    expect(state.run_score == final, "finalization is idempotent")

func test_time() -> void:
    for item in [[75.0, 500], [100.0, 350], [150.0, 200], [200.0, 100]]:
        var edge: float = item[0]
        expect(Rules.time_points(edge - 0.001, 100) == item[1], "time immediately below %.2fR" % (edge / 100))
        expect(Rules.time_points(edge, 100) == item[1], "time exactly at %.2fR" % (edge / 100))
        var next: int = {75:350, 100:200, 150:100, 200:0}[int(edge)]
        expect(Rules.time_points(edge + 0.001, 100) == next, "time immediately above %.2fR" % (edge / 100))
    expect(Rules.time_points(1, 0) == 0 and Rules.time_points(900, 100) == 0, "missing reference and slow play never produce negative bonus")
    var fixture := levels[0].duplicate(true)
    fixture.reference_time_sec = 90
    expect(Loader.validate(fixture), "optional reference time accepts existing level format")
    for invalid in [0, -1, "90", true, INF, NAN]:
        fixture.reference_time_sec = invalid
        expect(not Loader.validate(fixture), "invalid reference time is rejected: " + str(invalid))
    var state = State.new(levels[0])
    state.set_clock_active(true, 1000000)
    state.set_clock_active(false, 4000000)
    expect(is_equal_approx(state.elapsed_seconds(20000000), 3.0), "unfocused or paused interval excluded from effective time")
    state.set_clock_active(true, 20000000)
    state.set_clock_active(false, 22000000)
    expect(is_equal_approx(state.elapsed_seconds(90000000), 5.0), "effective clock resumes without counting the gap")
    for gears in [1, 2, 3]:
        state = State.new(levels[0])
        state.lives = gears
        for pos in pieces(state):
            state.toggle_specialist(pos)
        expect(state.score_result.gears == gears and is_equal_approx(state.score_result.quality_multiplier, [1.0, 1.15, 1.30][gears - 1]), "quality %d reuses the existing remaining-lives rating" % gears)
    fixture = levels[0].duplicate(true)
    fixture.reference_time_sec = 100
    state = State.new(fixture)
    state._elapsed_usec = 75000000
    for pos in pieces(state):
        state.toggle_specialist(pos)
    expect(state.score_result.time_bonus == 500 and state.run_score == roundi((state.operator_score + Rules.COMPLETION_BONUS + 500) * 1.30), "configured level reference contributes time bonus before the final quality multiplier")

func test_progress() -> void:
    var store = Progress.new("user://tests/scoring.json")
    expect(store.reset(levels), "isolated scoring save initialized")
    expect(store.complete(levels[0], levels[1], 1, {"run_score":2000,"elapsed_sec":80.0}), "first completion saved")
    expect(int(store.data.wallet_points) == 2000 and store.data.rewards["1"].claimed and store.last_completion.first_completion, "first completion credits exactly one claimed reward")
    expect(store.total_gears() == 2 and store.best_gears(1) == 2, "two gears are permanent progress")
    expect(store.complete(levels[0], levels[1], 0, {"run_score":4000,"elapsed_sec":70.0}), "better replay saved")
    expect(store.data.wallet_points == 2000 and store.total_gears() == 3 and store.last_completion.gears_gained == 1, "better replay grants only the one new gear, no wallet points")
    expect(store.data.level_stats["1"].best_score == 4000 and store.last_completion.new_record, "replay can improve personal score record")
    expect(store.complete(levels[0], levels[1], 2, {"run_score":1000}), "worse replay saved")
    expect(store.data.wallet_points == 2000 and store.total_gears() == 3 and store.data.level_stats["1"].best_score == 4000, "worse replay preserves best gears, score and wallet")
    var reopened = Progress.new(store.path)
    reopened.load_progress(levels)
    expect(reopened.data.wallet_points == 2000 and reopened.data.rewards["1"].claimed and reopened.data.level_stats["1"].best_score == 4000, "wallet, claim and personal record survive reload")
    expect(not reopened.complete(levels[1], levels[2], 3, {"run_score":9000}) and reopened.data.wallet_points == 2000, "defeat cannot mint reward")
    var legacy_path := "user://tests/scoring_legacy.json"
    FileAccess.open(legacy_path, FileAccess.WRITE).store_string(JSON.stringify({"version":1,"highest_unlocked_level":16,"current_level":16,"completed_levels":[1,15],"level_stats":{"1":{"best_errors":1}},"settings":{"sound":false}}))
    var legacy = Progress.new(legacy_path)
    legacy.load_progress(levels)
    expect(legacy.data.wallet_points == 0 and legacy.data.rewards["1"].claimed and legacy.data.rewards["15"].claimed, "legacy completions become claimed without invented retroactive currency")
    expect(legacy.best_gears(1) == 2 and legacy.best_gears(15) == -1 and legacy.data.highest_unlocked_level == 16 and not legacy.data.settings.sound, "legacy known/unknown ratings, settings and unlocks are preserved")
    legacy.complete(levels[0], levels[1], 0, {"run_score":5000})
    expect(legacy.data.wallet_points == 0 and legacy.best_gears(1) == 3, "legacy replay improves gears without a retroactive payout")
    var broken = Progress.new("user://tests/scoring_readonly.json")
    broken.data = Progress.defaults()
    broken.read_only = true
    expect(not broken.complete(levels[0], levels[1], 0, {"run_score":1000}) and broken.data.wallet_points == 0 and broken.data.completed_levels.is_empty(), "failed save rolls back wallet and completion together")

func seed_gears(store, completed_count: int, total: int) -> void:
    store.data = Progress.defaults()
    for id in range(1, completed_count + 1):
        store.data.completed_levels.append(id)
        var gears := mini(3, total - (completed_count - id))
        total -= gears
        store.data.level_stats[str(id)] = {"best_gears":gears,"completions":1}
    store.data.highest_unlocked_level = completed_count
    store.data.current_level = completed_count
    store.reconcile(levels)

func test_seasons() -> void:
    expect(Progress.required_gears_for_season("s2") == 32 and Progress.required_gears_for_season("s3") == 64 and Progress.required_gears_for_season("s4") == 96, "season quotas are rounded individually then accumulated")
    var different := [{"id":"a","level_ids":range(1,16)}, {"id":"b","level_ids":range(16,36)}, {"id":"c","level_ids":[36]}]
    expect(Progress.required_gears_for_season("c", different) == 74, "15-level and 20-level seasons require 32 + 42 gears")
    var store = Progress.new("user://tests/scoring_seasons.json")
    for item in [[15,31,16,false], [15,32,16,true], [30,63,31,false], [30,64,31,true]]:
        seed_gears(store, item[0], item[1])
        expect(store.total_gears() == item[1] and store.season_allows(item[2]) == item[3], "%d gears: phase %d season eligibility is %s" % [item[1], item[2], str(item[3])])
        expect((int(store.data.highest_unlocked_level) >= item[2]) == item[3], "campaign reconciliation respects the season gate at %d gears" % item[1])
    seed_gears(store, 15, 31)
    var replay_id := 0
    for id in range(1,16):
        if store.best_gears(id) < 3:
            replay_id = id
            break
    var original_gears: int = store.best_gears(replay_id)
    store.complete(levels[replay_id - 1], levels[replay_id], 3 - original_gears - 1, {"run_score":9999})
    expect(store.total_gears() == 32 and store.data.highest_unlocked_level == 16 and store.data.current_level == 16 and store.data.wallet_points == 0, "one improved replay gear releases pending season and Continue without minting currency")
    expect(store.total_gears() == 32, "season unlock never spends permanent gears")
    seed_gears(store, 15, 20)
    store.data.highest_unlocked_level = 42
    store.data.current_level = 42
    store.reconcile(levels)
    expect(store.data.highest_unlocked_level == 42 and store.data.current_level == 42, "existing unlocks remain grandfathered despite new quotas")
    var original := Worlds._seasons
    Worlds._seasons = [{"id":"mixed","level_ids":[1,16]}]
    expect(Worlds.season_for_level(1).id == Worlds.season_for_level(16).id, "season configuration is independent of vehicle categories")
    Worlds._seasons = original

func mouse(board, pos: Vector2i, pressed: bool) -> void:
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.position = board.cells[board.model.index(pos)].position + board.cells[board.model.index(pos)].size / 2.0
    event.pressed = pressed
    board.router.handle(event)

func double_click(board, pos: Vector2i) -> void:
    mouse(board, pos, true)
    mouse(board, pos, false)
    await create_timer(0.06).timeout
    mouse(board, pos, true)
    mouse(board, pos, false)

func snapshot(name: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        expect(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "render " + name)

func test_ui() -> void:
    app = load("res://scenes/Main.tscn").instantiate()
    app.progress_path = "user://tests/scoring_ui.json"
    Progress.new(app.progress_path).reset(levels)
    root.add_child(app)
    await frames()
    app.start_level(0)
    await frames()
    var game = app.screen
    var master_factor := minf(root.size.x/1672.0,root.size.y/941.0)
    expect(is_equal_approx(game.board.get_global_rect().size.x,584.0*master_factor) and game.specialist_strip.slots.size() == int(game.level.size), "master proportions and specialist strip preserve score integration")
    expect(game.rules_row.get_parent() == game.rules_rail and game.sidebar.visible, "rules rail and plant panel remain unchanged")
    var correct := pieces(game.model)
    await double_click(game.board, correct[0])
    await double_click(game.board, correct[1])
    expect(game.model.operator_score == 205 and game.model.operator_streak == 2 and game.model.x_score == 0, "real double-click gestures preserve consecutive operator streak without phantom X points")
    var note := blanks(game.model)[0]
    mouse(game.board, note, true)
    mouse(game.board, note, false)
    await create_timer(0.50).timeout
    expect(game.model.x_score == 0 and game.model.operator_streak == 0 and game.score_label.text == "Pontos: 205", "deliberate single X records an unevaluated note and resets the specialist streak")
    mouse(game.board, Vector2i(3,0), true)
    var motion := InputEventMouseMotion.new()
    motion.position = game.board.cells[game.model.index(Vector2i(3,4))].position + game.board.cells[game.model.index(Vector2i(3,4))].size / 2.0
    game.board.router.handle(motion)
    await create_timer(0.5).timeout
    expect(game.model.x_score == 0, "holding a drag beyond double-click interval does not split its scoring action")
    mouse(game.board, Vector2i(3,4), false)
    expect(game.model.x_score == 0 and game.model.lives == 3, "real five-cell drag stays neutral until victory")
    game.model.set_clock_active(true)
    paused = true
    var paused_time: float = game.model.elapsed_seconds()
    await create_timer(0.05).timeout
    expect(not game.model._clock_active and is_equal_approx(game.model.elapsed_seconds(), paused_time), "SceneTree pause stops effective scoring time")
    paused = false
    game.model.set_clock_active(true)
    game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    var unfocused_time: float = game.model.elapsed_seconds()
    await create_timer(0.05).timeout
    expect(not game.model._clock_active and is_equal_approx(game.model.elapsed_seconds(), unfocused_time), "application focus-out stops effective scoring time")
    for pos in pieces(game.model):
        game.model.toggle_specialist(pos)
    await await_result(game)
    await frames()
    expect(game.model.x_score == 160, "victory evaluates the single X and four-correct-X drag with unchanged final points")
    expect(game.model.run_score == 1391, "v2 changes preserve the previous final score for the same completed trace")
    expect(game.popup.find_child("ScoreSummary", true, false).text.contains("pontos") and app.progress.data.wallet_points == game.model.run_score, "first victory displays and saves actual score reward")
    var finished_time: float = game.model.elapsed_seconds()
    await create_timer(0.05).timeout
    expect(is_equal_approx(game.model.elapsed_seconds(), finished_time), "victory transition and modal add no effective time")
    await snapshot("scoring_first_win_desktop")
    root.size = Vector2i(360,700)
    await frames()
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(game.result_panel.get_global_rect()), "scoring result fits minimum mobile window")
    await snapshot("scoring_first_win_mobile")
    app.start_level(0)
    await frames()
    game = app.screen
    var wallet: int = app.progress.data.wallet_points
    for pos in pieces(game.model):
        game.model.toggle_specialist(pos)
    await await_result(game)
    await frames()
    expect(app.progress.data.wallet_points == wallet and game.popup.find_child("ScoreSummary", true, false).text.contains("já coletada"), "real replay shows collected message and never credits wallet")
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(game.result_panel.get_global_rect()), "replay result fits minimum mobile window")
    await snapshot("scoring_replay_mobile")
    seed_gears(app.progress, 14, 28)
    app.progress.data.highest_unlocked_level = 15
    app.progress.data.current_level = 15
    app.start_level(14)
    await frames()
    game = app.screen
    for pos in pieces(game.model):
        game.model.toggle_specialist(pos)
    await await_result(game)
    await frames()
    expect(app.progress.total_gears() == 31 and game.popup.find_child("NextButton", true, false).disabled and game.popup.find_child("SeasonRequirement", true, false) != null, "real boundary victory communicates 31/32 season gate")
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(game.result_panel.get_global_rect()), "blocked season result fits minimum mobile window")
    await snapshot("scoring_season_gate_mobile")
    app.start_level(15)
    expect(app.screen == game, "locked season cannot be bypassed through application API")
    app.show_menu()
    await frames()
    expect(app.screen.featured_id == 15 and app.screen.row_ids[0] == 14 and app.screen.markers[-1].get_meta("product") == "hatch", "season gate preserves Home order, replay and vehicle footers")
    app.screen.scroll.scroll_vertical = 1000
    await frames()
    expect(app.screen.scroll.scroll_vertical > 0, "history still scrolls after scoring integration")
    app.queue_free()
    await frames()

func run() -> void:
    create_timer(90).timeout.connect(func(): printerr("SCORING TEST TIMEOUT"); quit(2))
    root.size = Vector2i(1100,820)
    levels = Loader.load_levels()
    test_actions()
    test_time()
    test_progress()
    test_seasons()
    await test_ui()
    var report := {"passed":failures.is_empty(),"checks":checks,"failures":failures}
    FileAccess.open(output.path_join("scoring_tests.json"), FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
    print("SCORING RESULT: ", checks, " checks, ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)
