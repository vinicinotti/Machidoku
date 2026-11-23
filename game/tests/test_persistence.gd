extends SceneTree
## This script is run in two distinct OS processes: --write then --read.
const Loader = preload("res://scripts/level_loader.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
const Progress = preload("res://scripts/progress_store.gd")
const State = preload("res://scripts/game_state.gd")
const SAVE := "user://tests/cross_process.json"
var checks := 0
var failures: Array[String] = []
var app

func _initialize() -> void:
    call_deferred("run")

func expect(condition: bool, text: String) -> void:
    checks += 1
    if condition:
        print("PASS ", text)
    else:
        printerr("FAIL ", text)
        failures.append(text)

func frames() -> void:
    for i in range(4):
        await process_frame

func run() -> void:
    root.size = Vector2i(1100, 820)
    var levels := Loader.load_levels()
    var writing := OS.get_cmdline_user_args().has("--write")
    if writing:
        var store = Progress.new(SAVE)
        expect(store.reset(levels), "isolated save can be reset")
    app = load("res://scenes/Main.tscn").instantiate()
    app.progress_path = SAVE
    root.add_child(app)
    await frames()
    app.find_child("PlayButton", true, false).pressed.emit()
    await frames()
    if writing:
        expect(int(app.screen.level.id) == 1, "new game starts at phase 1")
        for pos in app.screen.level.solution:
            if app.screen.model.state_at(Vector2i(int(pos[0]), int(pos[1]))) != State.CellState.PREPLACED_SPECIALIST:
                app.screen.model.toggle_specialist(Vector2i(int(pos[0]), int(pos[1])))
        var deadline := Time.get_ticks_msec()+4000
        while not is_instance_valid(app.screen.popup) and Time.get_ticks_msec()<deadline:
            await process_frame
        expect(app.progress.data.completed_levels == [1], "phase 1 completion recorded")
        expect(app.progress.best_gears(1) == 3, "perfect win saves three gears")
        expect(int(app.progress.data.wallet_points) > 0 and app.progress.data.rewards["1"].claimed, "first-win wallet and reward claim are persisted")
        expect(int(app.progress.data.level_stats["1"].best_score) == int(app.progress.data.wallet_points), "first score matches the one-time payout")
        expect(int(app.progress.data.highest_unlocked_level) == 2, "phase 2 unlocked immediately")
        app.screen.popup.find_child("NextButton", true, false).pressed.emit()
        await frames()
        app.screen.menu_requested.emit()
        await frames()
        app.find_child("PlayButton", true, false).pressed.emit()
        await frames()
        expect(int(app.screen.level.id) == 2, "menu Play continues phase 2")
        app.screen.model.toggle_specialist(Vector2i(0,0))
        app.screen.retry_requested.emit()
        await frames()
        expect(int(app.screen.level.id) == 2 and app.screen.model.lives == 3 and app.screen.model.errors.is_empty(), "restart resets only the match")
        expect(app.progress.data.completed_levels == [1], "restart preserves completed phases")
    else:
        expect(int(app.screen.level.id) == 2, "new OS process resumes phase 2")
        expect(app.progress.data.completed_levels == [1], "completion survives process exit")
        expect(app.progress.best_gears(1) == 3 and int(app.progress.data.level_stats["1"].best_gears) == 3, "gear rating survives process exit")
        expect(int(app.progress.data.wallet_points) > 0 and app.progress.data.rewards["1"].claimed, "wallet and reward claim survive process exit")
        expect(int(app.progress.data.highest_unlocked_level) == 2, "unlock survives process exit")
        expect(app.screen.model.lives == 3, "reopened phase starts a fresh board")
        var store = Progress.new(SAVE)
        store.load_progress(levels)
        var wallet_before: int = store.data.wallet_points
        var better_score: int = int(store.data.level_stats["1"].best_score) + 1000
        expect(store.complete(levels[0], levels[1], 0, {"run_score":better_score}) and int(store.data.wallet_points) == wallet_before, "replay after process restart cannot mint more wallet points")
        expect(int(store.data.level_stats["1"].best_score) == better_score, "personal score can improve after process restart")
        var future_path := "user://tests/future_progress.json"
        var future := FileAccess.open(future_path, FileAccess.WRITE)
        future.store_string(JSON.stringify({"version":99,"highest_unlocked_level":2,"current_level":2,"completed_levels":[1]}))
        future.close()
        var newer = Progress.new(future_path)
        newer.load_progress(levels)
        expect(newer.read_only and not newer.save(), "future-version save is preserved without overwrite")
        # Simulate a truncated primary, and recover the last-good backup.
        var file := FileAccess.open(SAVE, FileAccess.WRITE)
        file.store_string("{truncated")
        file.close()
        store.load_progress(levels)
        expect(store.recovered_backup and int(store.data.current_level) == 2, "corrupt primary recovers backup")
        expect(store.reset(levels), "debug reset persists")
        var reopened = Progress.new(SAVE)
        reopened.load_progress(levels)
        expect(reopened.data.completed_levels.is_empty() and int(reopened.data.current_level) == 1 and int(reopened.data.highest_unlocked_level) == 1, "reset removes progression without touching levels")
        # Nonconsecutive ids and removed catalogue entries reconcile safely.
        var sparse: Array[Dictionary] = [levels[0].duplicate(true), levels[1].duplicate(true)]
        sparse[0].id = 10
        sparse[1].id = 30
        var original_seasons := Worlds.seasons()
        Worlds._seasons = [{"id":"sparse","level_ids":[10,30]}]
        reopened.data = Progress.defaults()
        reopened.reconcile(sparse)
        expect(int(reopened.data.current_level) == 10, "save supports nonconsecutive level ids")
        reopened.complete(sparse[0], sparse[1], 1)
        expect(int(reopened.data.current_level) == 30 and int(reopened.data.highest_unlocked_level) == 30, "unlock follows real catalogue ids")
        Worlds._seasons = original_seasons
    var path := ProjectSettings.globalize_path("res://../artifacts/persistence_" + ("write" if writing else "read") + ".json")
    var report := FileAccess.open(path, FileAccess.WRITE)
    report.store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty(),"save_path":SAVE},"  "))
    app.queue_free()
    await frames()
    print("RESULT: ", checks, " checks, ", failures.size(), " failures")
    quit(0 if failures.is_empty() else 1)
