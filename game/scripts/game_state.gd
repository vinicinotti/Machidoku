extends RefCounted
## Pure match state. No mouse, rendering, scenes or world-specific behavior.

signal changed
signal finished(won: bool)
signal score_changed(value: int)
signal operator_scored(points: int, streak: int, position: Vector2i)

const Loader = preload("res://scripts/level_loader.gd")
const Scoring = preload("res://scripts/scoring_rules.gd")
const Progress = preload("res://scripts/progress_store.gd")
enum CellState { EMPTY, X, SPECIALIST, ERROR_X, PREPLACED_SPECIALIST }
const STARTING_LIVES := 3

var level: Dictionary
var cells: Array[int] = []
var errors := {} # Wrong specialist attempts only; locked until this match restarts.
var solution := {}
var lives := STARTING_LIVES
var over := false
var won := false
var run_score := 0
var operator_score := 0
var x_score := 0
var operator_streak := 0
var score_result: Dictionary = {}
var _scored_operators := {}
var _scored_x := {}
var _x_groups: Array = []
var _pending_x := {}
var _x_action_open := false
var _x_action_used := false
var _clock_active := false
var _clock_started_usec := 0
var _elapsed_usec := 0

func _init(data: Dictionary) -> void:
    level = data
    cells.resize(int(level.size) * int(level.size))
    cells.fill(CellState.EMPTY)
    for pos in level.solution:
        solution[Vector2i(int(pos[0]), int(pos[1]))] = true
    for pos in level.preplaced_specialists:
        cells[index(Vector2i(int(pos[0]), int(pos[1])))] = CellState.PREPLACED_SPECIALIST

func index(pos: Vector2i) -> int:
    return pos.x * int(level.size) + pos.y

func inside(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.y >= 0 and pos.x < int(level.size) and pos.y < int(level.size)

func state_at(pos: Vector2i) -> int:
    return cells[index(pos)]

func can_mark(pos: Vector2i) -> bool:
    return inside(pos) and not over and state_at(pos) in [CellState.EMPTY, CellState.X]

func mark_x(pos: Vector2i, erase: bool = false) -> void:
    if not can_mark(pos):
        return
    if erase:
        if state_at(pos) == CellState.X:
            cells[index(pos)] = CellState.EMPTY
            if _x_action_open:
                _x_action_used = true
            else:
                operator_streak = 0
            changed.emit()
        return
    if state_at(pos) == CellState.X:
        return
    # Annotations stay neutral; their score is private until the completed result.
    cells[index(pos)] = CellState.X
    if _x_action_open:
        _pending_x[pos] = true
        _x_action_used = true
    else:
        begin_x_action()
        _pending_x[pos] = true
        _x_action_used = true
        end_x_action()
    changed.emit()

func toggle_x(pos: Vector2i) -> void:
    if can_mark(pos):
        mark_x(pos, state_at(pos) == CellState.X)

func toggle_specialist(pos: Vector2i) -> void:
    if over or not inside(pos):
        return
    var state := state_at(pos)
    if state in [CellState.PREPLACED_SPECIALIST, CellState.ERROR_X]:
        return
    end_x_action()
    if state == CellState.SPECIALIST:
        cells[index(pos)] = CellState.EMPTY
        operator_streak = 0
    elif solution.has(pos):
        cells[index(pos)] = CellState.SPECIALIST
        if not _scored_operators.has(pos):
            _scored_operators[pos] = true
            operator_streak += 1
            var points := Scoring.operator_points(operator_streak)
            operator_score += points
            run_score += points
            score_changed.emit(run_score)
            operator_scored.emit(points, operator_streak, pos)
        else:
            # Removing/replacing a piece cannot farm points or extend a combo.
            operator_streak = 0
    else:
        cells[index(pos)] = CellState.ERROR_X
        record_error(pos)
        return
    check_victory()
    if won:
        finish_score()
    changed.emit()
    if won:
        finished.emit(true)

func record_error(pos: Vector2i) -> void:
    operator_streak = 0
    if not errors.has(pos):
        errors[pos] = true
        lives -= 1
    if lives == 0:
        over = true
        set_clock_active(false)
    changed.emit()
    if over:
        finished.emit(false)

func begin_x_action() -> void:
    end_x_action()
    _x_action_open = true

func cancel_x_action() -> void:
    _pending_x.clear()
    _x_action_open = false
    _x_action_used = false

func end_x_action() -> void:
    if not _x_action_open:
        return
    if _x_action_used:
        operator_streak = 0
    var group: Array[Vector2i] = []
    if not over:
        for pos in _pending_x:
            # Record annotations only. Do not query the answer during a gesture.
            if state_at(pos) == CellState.X and not _scored_x.has(pos):
                _scored_x[pos] = true
                group.append(pos)
        if not group.is_empty():
            _x_groups.append(group)
    cancel_x_action()

func set_clock_active(active: bool, now_usec: int = -1) -> void:
    var now := Time.get_ticks_usec() if now_usec < 0 else now_usec
    if _clock_active:
        _elapsed_usec += maxi(0, now - _clock_started_usec)
    _clock_active = active and not over
    _clock_started_usec = now

func elapsed_seconds(now_usec: int = -1) -> float:
    var now := Time.get_ticks_usec() if now_usec < 0 else now_usec
    return (_elapsed_usec + (maxi(0, now - _clock_started_usec) if _clock_active else 0)) / 1000000.0

func finish_score() -> void:
    if not score_result.is_empty():
        return
    set_clock_active(false)
    # The puzzle has been solved: evaluate committed groups with the same answer
    # source and the same formula. No correctness information exists before win.
    for group in _x_groups:
        var correct := 0
        for pos in group:
            if not solution.has(pos):
                correct += 1
        x_score += Scoring.x_points(correct)
    var elapsed := elapsed_seconds()
    var gears := Progress.gears_for_errors(STARTING_LIVES - lives)
    var time_bonus := Scoring.time_points(elapsed, float(level.get("reference_time_sec", 0)))
    var raw := operator_score + x_score + time_bonus + Scoring.COMPLETION_BONUS
    var multiplier := Scoring.quality_multiplier(gears)
    run_score = roundi(raw * multiplier)
    score_result = {"run_score": run_score, "operator_score": operator_score, "x_score": x_score,
        "time_bonus": time_bonus, "completion_bonus": Scoring.COMPLETION_BONUS,
        "raw_score": raw, "quality_multiplier": multiplier, "gears": gears, "elapsed_sec": elapsed}
    score_changed.emit(run_score)

func placed_count() -> int:
    return cells.count(CellState.SPECIALIST) + cells.count(CellState.PREPLACED_SPECIALIST)

func check_victory() -> void:
    if placed_count() != int(level.size):
        return
    var placed: Array = []
    for r in range(int(level.size)):
        for c in range(int(level.size)):
            if state_at(Vector2i(r, c)) in [CellState.SPECIALIST, CellState.PREPLACED_SPECIALIST]:
                placed.append([r, c])
    won = Loader.valid_placement(level, placed)
    over = won
