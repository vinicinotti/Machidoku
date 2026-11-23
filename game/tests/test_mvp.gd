extends SceneTree
## Executes real scene controls and viewport mouse events, with no third-party plugin.

const State = preload("res://scripts/game_state.gd")
const Loader = preload("res://scripts/level_loader.gd")
const Progress = preload("res://scripts/progress_store.gd")
const Palette = preload("res://scripts/sector_palette.gd")
var failures: Array[String] = []
var checks := 0
var app
var levels: Array[Dictionary]
var images: Array[String] = []
var output := ProjectSettings.globalize_path("res://../artifacts")

func _initialize() -> void:
    call_deferred("run")

func expect(condition: bool, description: String) -> void:
    checks += 1
    if condition:
        print("PASS ", description)
    else:
        failures.append(description)
        printerr("FAIL ", description)


func await_result(target) -> void:
    var deadline := Time.get_ticks_msec()+4000
    while is_instance_valid(target) and (not is_instance_valid(target.popup) or target.result_panel.modulate.a<0.99) and Time.get_ticks_msec()<deadline:
        await process_frame
    await frames(3)

func frames(count: int = 3) -> void:
    for i in range(count):
        await process_frame

func independent_single_interval() -> void:
    # A timer created during process_frame can consume part of that frame's
    # delta. After a costly first render, 0.50 simulated seconds may end before
    # the router's 450 ms monotonic window. Keep independent test gestures apart
    # using elapsed wall time, just as the unchanged input router does.
    var deadline := Time.get_ticks_msec() + 500
    while Time.get_ticks_msec() < deadline:
        await process_frame

func snapshot(name: String) -> void:
    if DisplayServer.get_name() == "headless":
        return
    await RenderingServer.frame_post_draw
    var path := output.path_join(name + ".png")
    var error := root.get_texture().get_image().save_png(path)
    expect(error == OK, "render " + name)
    images.append(path)

func mouse_at(position: Vector2, pressed: bool, double_click: bool = false) -> void:
    var motion := InputEventMouseMotion.new()
    motion.position = position
    root.push_input(motion, true)
    var event := InputEventMouseButton.new()
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = pressed
    event.position = position
    event.double_click = double_click
    root.push_input(event, true)

func point(board, pos: Vector2i) -> Vector2:
    var cell = board.cells[board.model.index(pos)]
    return cell.get_global_rect().get_center()

func click(board, pos: Vector2i) -> void:
    var p := point(board, pos)
    mouse_at(p, true)
    mouse_at(p, false)
    await frames(1)

func double_click(board, pos: Vector2i) -> void:
    await click(board, pos)
    await create_timer(0.06).timeout
    var p := point(board, pos)
    mouse_at(p, true, true)
    mouse_at(p, false)
    await frames(2)

func drag(board, path: Array[Vector2i]) -> void:
    mouse_at(point(board, path[0]), true)
    for pos in path.slice(1):
        var motion := InputEventMouseMotion.new()
        motion.position = point(board, pos)
        motion.button_mask = MOUSE_BUTTON_MASK_LEFT
        root.push_input(motion, true)
    mouse_at(point(board, path[-1]), false)
    # Exit animations run for 55 ms; assertions below inspect committed state.
    await create_timer(0.085).timeout

func run() -> void:
    DirAccess.make_dir_recursive_absolute(output)
    # The headless display starts with a 64x64 native window, regardless of the
    # project viewport. Use the same initial window as the desktop application.
    root.size = Vector2i(1100, 820)
    # A broken asynchronous assertion must never hang a command indefinitely.
    create_timer(300.0).timeout.connect(func(): printerr("TEST TIMEOUT"); quit(2))
    levels = Loader.load_levels()
    expect(levels.size() == 60, "sixty valid JSON levels discovered in Godot")
    if levels.size() != 60:
        quit(1)
        return
    test_model()
    app = load("res://scenes/Main.tscn").instantiate()
    app.progress_path = "user://tests/integration.json"
    var fresh = Progress.new(app.progress_path)
    fresh.reset(levels)
    root.add_child(app)
    await frames()
    expect(app.find_child("PlayButton", true, false) != null, "menu has Play control")
    await snapshot("menu")
    app.find_child("PlayButton", true, false).pressed.emit()
    await frames()
    var game = app.screen
    expect(game.model.lives == 3, "phase begins with three lives")
    expect(game.board.cells.size() == 25, "dynamic 5x5 board")
    await snapshot("phase_01")
    var safe := Vector2i(0, 1)
    await click(game.board, safe)
    expect(game.model.state_at(safe) == State.CellState.X, "first press marks X immediately without waiting for a double-click timeout")
    var safe_view = game.board.cells[game.model.index(safe)]
    expect(safe_view.mark_alpha > 0.0, "X entrance has visible feedback on the first frame")
    # Only tests wait here to distinguish two independent singles from a double.
    await independent_single_interval()
    expect(game.model.state_at(safe) == State.CellState.X, "single click creates X through viewport input")
    mouse_at(point(game.board, safe), true)
    expect(safe_view.erasing and game.model.state_at(safe) == State.CellState.X, "X removal begins on press and keeps X until its 90 ms exit finishes")
    safe_view.mark_tween.custom_step(0.045)
    expect(safe_view.mark_scale < 1.0 and safe_view.mark_scale > 0.85 and safe_view.mark_alpha < 1.0 and safe_view.mark_alpha > 0.0 and game.model.state_at(safe) == State.CellState.X, "exit scales toward 0.85 and fades toward zero before committing EMPTY")
    mouse_at(point(game.board, safe), false)
    await create_timer(0.12).timeout
    expect(game.model.state_at(safe) == State.CellState.EMPTY and not safe_view.erasing, "single erase commits EMPTY within animation duration, without a 450 ms wait")
    var correct := Vector2i(1, 2)
    await double_click(game.board, correct)
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST, "double click places specialist")
    expect(game.model.lives == 3, "double click on solution never records an intermediate X error")
    await double_click(game.board, correct)
    expect(game.model.state_at(correct) == State.CellState.EMPTY, "double click removes a removable specialist")
    await double_click(game.board, Vector2i(0, 0))
    expect(game.model.state_at(Vector2i(0, 0)) == State.CellState.PREPLACED_SPECIALIST, "fixed specialist resists input")
    var unchanged_feedback: String = game.feedback.text
    await click(game.board, correct)
    await independent_single_interval()
    expect(game.model.lives == 3 and game.model.state_at(correct) == State.CellState.X and game.model.errors.is_empty(), "annotation on solution remains a normal X without life loss")
    var correct_view = game.board.cells[game.model.index(correct)]
    expect(not correct_view.locked_error and correct_view.state == State.CellState.X and is_zero_approx(correct_view.error_flash) and game.feedback.text == unchanged_feedback, "annotation on solution reveals no red marker, error flash or feedback")
    await click(game.board, correct)
    await independent_single_interval()
    expect(game.model.state_at(correct) == State.CellState.EMPTY and game.model.lives == 3, "annotation on solution can be erased")
    await click(game.board, correct)
    await independent_single_interval()
    await double_click(game.board, correct)
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST and game.model.lives == 3 and game.model.errors.is_empty(), "double click replaces a normal X with a correct specialist")
    await create_timer(0.12).timeout
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST and not correct_view.erasing, "second click cancels the pending erase callback without a ghost removal")
    await click(game.board, correct)
    await independent_single_interval()
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST, "single click never turns a specialist into X")
    await double_click(game.board, correct)

    game.model.mark_x(correct)
    await create_timer(0.12).timeout
    mouse_at(point(game.board, correct), true)
    mouse_at(point(game.board, correct), false)
    await create_timer(0.12).timeout
    expect(game.model.state_at(correct) == State.CellState.EMPTY, "first press can complete its exit before the second press")
    mouse_at(point(game.board, correct), true)
    mouse_at(point(game.board, correct), false)
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST and game.model.lives == 3, "timestamp recognizes a double click even after its optimistic X removal has completed")
    await create_timer(0.12).timeout
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST, "completed exit cannot later erase a new specialist")
    await double_click(game.board, correct)

    game.model.mark_x(Vector2i(0, 2))
    await create_timer(0.12).timeout
    mouse_at(point(game.board, Vector2i(0, 2)), true)
    mouse_at(point(game.board, Vector2i(0, 2)), false)
    expect(game.board.cells[game.model.index(Vector2i(0, 2))].erasing, "earlier click can have an exit in flight when a new MARK gesture begins")
    await drag(game.board, [Vector2i(0, 1), Vector2i(0, 3), Vector2i(0, 1)])
    await create_timer(0.04).timeout
    expect(game.model.state_at(Vector2i(0, 1)) == State.CellState.X and game.model.state_at(Vector2i(0, 2)) == State.CellState.X and game.model.state_at(Vector2i(0, 3)) == State.CellState.X, "MARK drag preserves existing X and does not toggle revisited cells")
    expect(not game.board.cells[game.model.index(Vector2i(0, 2))].erasing, "MARK cancels an earlier exit so a re-marked X cannot disappear later")
    game.model.toggle_x(Vector2i(0, 2))
    await drag(game.board, [Vector2i(0, 1), Vector2i(0, 3), Vector2i(0, 1)])
    expect(game.model.state_at(Vector2i(0, 1)) == State.CellState.EMPTY and game.model.state_at(Vector2i(0, 2)) == State.CellState.EMPTY and game.model.state_at(Vector2i(0, 3)) == State.CellState.EMPTY, "ERASE drag leaves empty cells empty and does not remark revisited cells")
    for pos in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]:
        game.model.mark_x(pos)
    await create_timer(0.12).timeout
    var drag_start := Vector2i(0, 1)
    mouse_at(point(game.board, drag_start), true)
    await create_timer(0.12).timeout
    expect(game.model.state_at(drag_start) == State.CellState.EMPTY, "holding a first erase press does not delay its completion")
    var fast_motion := InputEventMouseMotion.new()
    fast_motion.position = point(game.board, Vector2i(0, 3))
    fast_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
    root.push_input(fast_motion, true)
    var middle = game.board.cells[game.model.index(Vector2i(0, 2))]
    expect(middle.erasing and game.board.router.drag_mode == game.board.router.DragMode.ERASE, "drag retains ERASE after first cell has already become EMPTY and immediately starts other exits")
    mouse_at(fast_motion.position, false)
    await create_timer(0.075).timeout
    expect(game.model.state_at(Vector2i(0, 2)) == State.CellState.EMPTY and game.model.state_at(Vector2i(0, 3)) == State.CellState.EMPTY, "drag erases interpolated X in 55 ms without per-cell double-click waits")
    await drag(game.board, [Vector2i(1, 0), Vector2i(1, 4)])
    expect(game.model.state_at(correct) == State.CellState.X and game.model.lives == 3 and game.model.errors.is_empty(), "MARK drag across solution does not validate annotations")
    await drag(game.board, [Vector2i(1, 0), Vector2i(1, 4)])
    expect(game.model.state_at(correct) == State.CellState.EMPTY and game.model.lives == 3, "ERASE drag removes annotation on solution without penalty")

    var wrong := Vector2i(0, 2)
    await double_click(game.board, wrong)
    expect(game.model.lives == 2 and game.model.state_at(wrong) == State.CellState.ERROR_X and game.model.placed_count() == 1, "wrong specialist attempt loses exactly one life and leaves only ERROR_X")
    var error_view = game.board.cells[game.model.index(wrong)]
    expect(error_view.locked_error and error_view.state == State.CellState.ERROR_X, "wrong attempt renders a locked coral X, not a specialist")
    await create_timer(0.25).timeout
    expect(error_view.mark_scale == 1.0 and is_equal_approx(error_view.mark_alpha, 1.0), "X animation settles without changing cell geometry")
    expect(is_equal_approx(game.lives_label.scale.x, 1.0) and is_equal_approx(game.lives_label.modulate.a, 1.0), "life pulse settles")
    await click(game.board, wrong)
    await create_timer(0.50).timeout
    await double_click(game.board, wrong)
    expect(game.model.state_at(wrong) == State.CellState.ERROR_X and game.model.lives == 2 and game.model.errors.size() == 1, "ERROR_X blocks single and double click without repeated charges")
    for pos in [Vector2i(0, 1), Vector2i(0, 3)]:
        game.model.mark_x(pos)
    await drag(game.board, [Vector2i(0, 1), Vector2i(0, 4)])
    expect(game.model.state_at(wrong) == State.CellState.ERROR_X and game.model.state_at(Vector2i(0, 1)) == State.CellState.EMPTY and game.model.state_at(Vector2i(0, 3)) == State.CellState.EMPTY and game.model.state_at(Vector2i(0, 4)) == State.CellState.EMPTY, "ERASE drag crosses locked ERROR_X without removing it or marking empty cells")
    for pos in [Vector2i(0, 1), Vector2i(0, 3)]:
        game.model.mark_x(pos)
    await drag(game.board, [wrong, Vector2i(0, 4)])
    expect(game.model.state_at(wrong) == State.CellState.ERROR_X and game.model.state_at(Vector2i(0, 1)) == State.CellState.X and game.model.state_at(Vector2i(0, 3)) == State.CellState.EMPTY and game.model.state_at(Vector2i(0, 4)) == State.CellState.EMPTY, "drag starting on ERROR_X chooses ERASE at the first editable X")
    await drag(game.board, [Vector2i(0, 0), Vector2i(0, 4)])
    expect(game.model.state_at(Vector2i(0, 0)) == State.CellState.PREPLACED_SPECIALIST and game.model.state_at(Vector2i(0, 1)) == State.CellState.EMPTY and game.model.state_at(wrong) == State.CellState.ERROR_X and game.model.state_at(Vector2i(0, 4)) == State.CellState.EMPTY, "drag starting on fixed specialist ignores it and uses first editable X for ERASE")
    await drag(game.board, [wrong, Vector2i(0, 4)])
    expect(game.model.state_at(wrong) == State.CellState.ERROR_X and game.model.state_at(Vector2i(0, 3)) == State.CellState.X and game.model.state_at(Vector2i(0, 4)) == State.CellState.X, "drag starting on ERROR_X chooses MARK at the first editable empty cell")
    await double_click(game.board, correct)
    game.model.mark_x(Vector2i(1, 3))
    await drag(game.board, [correct, Vector2i(1, 4)])
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST and game.model.state_at(Vector2i(1, 3)) == State.CellState.EMPTY and game.model.state_at(Vector2i(1, 4)) == State.CellState.EMPTY, "drag starting on a normal specialist ignores it and selects ERASE at the next X")
    game.model.mark_x(Vector2i(1, 3))
    await drag(game.board, [Vector2i(1, 0), Vector2i(1, 4)])
    expect(game.model.state_at(correct) == State.CellState.SPECIALIST and game.model.state_at(Vector2i(1, 1)) == State.CellState.X and game.model.state_at(Vector2i(1, 3)) == State.CellState.X and game.model.state_at(Vector2i(1, 4)) == State.CellState.X, "MARK drag ignores specialists and preserves X throughout a mixed stroke")
    expect(game.model.lives == 2 and game.model.errors.size() == 1 and game.board.router.drag_mode == game.board.router.DragMode.UNSET and not game.board.router.down, "all drag modes end on release and never consume lives")

    await double_click(game.board, Vector2i(0, 4))
    expect(game.model.lives == 1 and game.model.state_at(Vector2i(0, 4)) == State.CellState.ERROR_X, "wrong specialist attempt on normal X replaces it with ERROR_X and consumes one life")
    await create_timer(0.12).timeout
    expect(game.model.state_at(Vector2i(0, 4)) == State.CellState.ERROR_X and game.model.lives == 1, "interrupted erase never removes a new permanent ERROR_X or charges a second life")
    await snapshot("errors")
    await double_click(game.board, Vector2i(0, 3))
    expect(game.model.over and not game.model.won and game.model.lives == 0, "third error ends the match")
    if game.popup == null:
        await conclude()
        return
    expect(game.popup.name == "DefeatPopup", "defeat panel is visible")
    await snapshot("defeat")
    game.popup.find_child("RetryButton", true, false).pressed.emit()
    await frames()
    expect(app.screen.model.lives == 3 and app.screen.model.errors.is_empty(), "restart creates a fresh match")
    expect(app.screen.model.cells.count(State.CellState.EMPTY) == 24 and app.screen.model.cells.count(State.CellState.PREPLACED_SPECIALIST) == 1, "restart removes permanent ERROR_X and every other temporary mark")
    for i in range(levels.size()):
        game = app.screen
        expect(int(game.level.id) == i + 1, "phase progression %d" % (i + 1))
        expect(game.board.cells.size() == int(game.level.size) ** 2, "board rebuilt for phase %d" % (i + 1))
        verify_board(game)
        if i in [0, 6, 10, 13, 14]:
            await snapshot("phase_%02d" % (i + 1))
        for pos in game.level.solution:
            var at := Vector2i(int(pos[0]), int(pos[1]))
            if game.model.state_at(at) != State.CellState.PREPLACED_SPECIALIST:
                if i < 15:
                    await double_click(game.board, at)
                else:
                    game.model.toggle_specialist(at)
        await await_result(game)
        expect(game.model.won and game.model.over, "phase %d wins without filling X" % (i + 1))
        if not game.model.won or game.popup == null:
            printerr("Phase failure details: ", JSON.stringify({"id": game.level.id, "cells": game.model.cells, "lives": game.model.lives, "solution": game.level.solution, "board": str(game.board.get_global_rect())}))
            await snapshot("phase_failure")
            await conclude()
            return
        expect(game.popup.name == "VictoryPopup", "victory panel for phase %d" % (i + 1))
        expect(game.model.lives == 3, "correct path preserves all lives")
        if i in [0, 14]:
            await snapshot("victory_%02d" % (i + 1))
        expect(app.progress.data.completed_levels.has(int(game.level.id)), "completion saved for phase %d" % (i + 1))
        if i < levels.size() - 1:
            game.popup.find_child("NextButton", true, false).pressed.emit()
            await frames()
    expect(app.screen.is_last and app.screen.popup.find_child("FinishButton", true, false) != null, "phase 60 completes Automotive campaign")
    app.screen.popup.find_child("FinishButton", true, false).pressed.emit()
    await frames()
    expect(app.find_child("PlayButton", true, false) != null, "finished line returns to menu")
    expect(app.progress.data.completed_levels.size() == 60, "all sixty completions persisted")
    app.start_level(levels.size() - 1)
    await frames()
    # Test actual resizing, including portrait and a short landscape viewport.
    for viewport_size in [Vector2i(620, 900), Vector2i(1100, 740), Vector2i(580, 700)]:
        root.size = viewport_size
        await frames(5)
        game = app.screen
        expect(game.sidebar.visible == (game.size.x >= 900), "responsive sidebar at %s" % viewport_size)
        var rect: Rect2 = game.board.get_global_rect()
        expect(rect.size.x > 250 and rect.size.y > 250 and Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(rect), "board fits viewport %s" % viewport_size)
        expect(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(game.feedback.get_global_rect()), "feedback stays visible at %s" % viewport_size)
        await snapshot("layout_%dx%d" % [viewport_size.x, viewport_size.y])
    app.show_menu()
    await frames()
    var play = app.find_child("PlayButton", true, false)
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(play.get_global_rect()), "menu Play fits minimum window")
    await snapshot("menu_minimum")
    app.start_level(levels.size() - 1)
    await frames()
    for pos in app.screen.level.solution:
        app.screen.model.toggle_specialist(Vector2i(int(pos[0]), int(pos[1])))
    await await_result(app.screen)
    var finish = app.screen.popup.find_child("FinishButton", true, false)
    expect(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(finish.get_global_rect()), "victory action fits minimum window")
    await snapshot("victory_minimum")
    await conclude()

func verify_board(game) -> void:
    var graph := Palette.adjacency(game.level.regions)
    var separated := true
    for region in range(graph.size()):
        for neighbor in graph[region]:
            if Palette.distance(game.board.region_colors[region], game.board.region_colors[neighbor]) < Palette.MIN_DISTANCE - 0.01:
                separated = false
    expect(separated, "neighbor colors meet CIE76 distance for phase %d" % int(game.level.id))
    var edges := 0
    var n := int(game.level.size)
    for r in range(n):
        for c in range(n):
            if r + 1 < n and game.level.regions[r][c] != game.level.regions[r + 1][c]:
                edges += 1
            if c + 1 < n and game.level.regions[r][c] != game.level.regions[r][c + 1]:
                edges += 1
    expect(game.board.lines.boundary_edge_count == edges, "shared sector edges emitted exactly once for phase %d" % int(game.level.id))

func conclude() -> void:
    var report := {"checks": checks, "failures": failures, "passed": failures.is_empty(), "display": DisplayServer.get_name(), "screenshots": images}
    var file := FileAccess.open(output.path_join("godot_tests_" + DisplayServer.get_name() + ".json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "  ") + "\n")
    print("RESULT: ", checks, " checks, ", failures.size(), " failures")
    app.queue_free()
    await frames(3)
    quit(0 if failures.is_empty() else 1)

func test_model() -> void:
    var directory := "user://tests/catalog"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
    for item in [["zeta.json", 10], ["alpha.json", 40]]:
        var fixture: Dictionary = levels[0].duplicate(true)
        fixture.id = item[1]
        var file := FileAccess.open(directory.path_join(item[0]), FileAccess.WRITE)
        file.store_string(JSON.stringify(fixture))
    var discovered := Loader.load_levels(directory)
    expect(discovered.size() == 2 and int(discovered[0].id) == 10 and int(discovered[1].id) == 40, "discovery sorts real ids independently of filenames and gaps")
    var state = State.new(levels[0])
    expect(state.placed_count() == 1, "preplaced specialist counts toward completion")
    state.toggle_specialist(Vector2i(0, 0))
    expect(state.placed_count() == 1, "fixed specialist cannot be removed in model")
    state.toggle_specialist(Vector2i(-1, 0))
    expect(state.lives == 3, "out-of-bounds action ignored")
    var bad_level: Dictionary = levels[0].duplicate(true)
    bad_level.regions[4][4] = 0
    expect(not Loader.validate(bad_level), "runtime loader rejects disconnected region")
    for pos in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)]:
        state.toggle_specialist(pos)
    var before: Array[int] = state.cells.duplicate()
    state.toggle_specialist(Vector2i(1, 2))
    state.toggle_x(Vector2i(4, 4))
    expect(state.cells == before and state.lives == 0, "defeat freezes all actions")
    state = State.new(levels[0])
    for r in range(int(levels[0].size)):
        for c in range(int(levels[0].size)):
            state.mark_x(Vector2i(r, c))
    expect(state.cells.count(State.CellState.X) == 24 and state.lives == 3 and state.errors.is_empty(), "every editable cell can be annotated without consulting the solution")
    for r in range(int(levels[0].size)):
        for c in range(int(levels[0].size)):
            state.mark_x(Vector2i(r, c), true)
    expect(state.cells.count(State.CellState.EMPTY) == 24 and state.lives == 3, "all normal annotations can be erased without penalty")
    var correct := Vector2i(1, 2)
    state.mark_x(correct)
    state.toggle_specialist(correct)
    expect(state.state_at(correct) == State.CellState.SPECIALIST and state.lives == 3, "model replaces a normal X with a correct specialist")
    state.toggle_specialist(correct)
    expect(state.state_at(correct) == State.CellState.EMPTY and state.errors.is_empty(), "removing correct specialist restores empty without any error")
    for pos in [Vector2i(0, 1), Vector2i(0, 2)]:
        state.mark_x(pos)
        state.toggle_specialist(pos)
        state.toggle_x(pos)
        state.mark_x(pos, true)
        state.mark_x(pos)
        state.toggle_specialist(pos)
        expect(state.state_at(pos) == State.CellState.ERROR_X, "confirmed error rejects every editing intention")
    expect(state.lives == 1 and state.errors.size() == 2, "only the two distinct wrong specialist attempts cost lives")
    for pos in levels[0].solution:
        var at := Vector2i(int(pos[0]), int(pos[1]))
        if state.state_at(at) != State.CellState.PREPLACED_SPECIALIST:
            state.mark_x(at)
            state.toggle_specialist(at)
    expect(state.won and state.lives == 1 and state.cells.count(State.CellState.ERROR_X) == 2, "victory tolerates confirmed error X and corrected normal annotations")
