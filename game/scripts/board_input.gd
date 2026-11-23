extends Node
## Mouse gestures are intentionally independent of the puzzle rules.
## Apply the first press immediately; timestamps recognize the second press.
## Annotations are neutral, so there is no need to delay or validate a single.

const DOUBLE_CLICK_MSEC := 450
const DRAG_THRESHOLD := 8.0
enum DragMode { UNSET, MARK, ERASE }

var board: Control
var last_click := Vector2i(-1, -1)
var last_click_msec := -1
var press_cell := Vector2i(-1, -1)
var down := false
var dragging := false
var press_position := Vector2.ZERO
var drag_mode := DragMode.UNSET
var visited := {}
var previous := Vector2i(-1, -1)
var score_timer: Timer

func _ready() -> void:
    # Scoring waits for gesture disambiguation; the visible X remains immediate.
    score_timer = Timer.new()
    score_timer.one_shot = true
    score_timer.wait_time = DOUBLE_CLICK_MSEC / 1000.0
    add_child(score_timer)
    score_timer.timeout.connect(func():
        if not down:
            board.model.end_x_action())

func cancel(commit_x: bool = true) -> void:
    if is_instance_valid(score_timer):
        score_timer.stop()
    if board != null and board.model != null:
        if commit_x:
            board.model.end_x_action()
        else:
            board.model.cancel_x_action()
    last_click = Vector2i(-1, -1)
    last_click_msec = -1
    press_cell = Vector2i(-1, -1)
    down = false
    dragging = false
    drag_mode = DragMode.UNSET
    visited.clear()

func handle(event: InputEvent) -> void:
    if board.model == null or board.model.over:
        cancel()
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var pos: Vector2i = board.cell_at(event.position)
        if event.pressed:
            if not board.model.inside(pos):
                return
            var now := Time.get_ticks_msec()
            if last_click == pos and last_click_msec >= 0 and now - last_click_msec <= DOUBLE_CLICK_MSEC:
                cancel(false)
                # The first press may still be fading a normal X out. Cancel
                # its completion before placing a piece or a permanent ERROR_X.
                board.cancel_x_removal(pos)
                board.model.toggle_specialist(pos)
                return
            last_click = pos
            last_click_msec = now
            press_cell = pos
            down = true
            dragging = false
            drag_mode = DragMode.UNSET
            choose_drag_mode(pos)
            visited.clear()
            press_position = event.position
            previous = pos
            board.model.begin_x_action()
            # Select the gesture mode BEFORE an immediate first press changes X.
            # A drag that starts on EMPTY must remain MARK, even after it is X.
            if board.model.can_mark(pos):
                if drag_mode == DragMode.ERASE:
                    board.remove_x(pos, board.CLICK_ERASE_SECONDS)
                else:
                    board.model.mark_x(pos)
        else:
            if not down:
                return
            down = false
            if dragging:
                cancel()
            else:
                score_timer.start(maxf(0.001, (DOUBLE_CLICK_MSEC - (Time.get_ticks_msec() - last_click_msec)) / 1000.0))
    elif event is InputEventMouseMotion and down:
        if not dragging and event.position.distance_to(press_position) >= DRAG_THRESHOLD:
            dragging = true
            last_click = Vector2i(-1, -1)
            last_click_msec = -1
            # Reissue an ongoing first-cell removal at the shorter drag speed.
            mark_drag(press_cell)
        if dragging:
            var pos: Vector2i = board.cell_at(event.position)
            if board.model.inside(pos):
                # Interpolate sparse mouse events so a fast stroke does not skip cells.
                var steps := maxi(absi(pos.x - previous.x), absi(pos.y - previous.y))
                for i in range(1, steps + 1):
                    var at := Vector2(previous).lerp(Vector2(pos), float(i) / steps)
                    mark_drag(Vector2i(roundi(at.x), roundi(at.y)))
                mark_drag(pos)
                previous = pos

func mark_drag(pos: Vector2i) -> void:
    if not board.model.can_mark(pos) or visited.has(pos):
        return
    choose_drag_mode(pos)
    visited[pos] = true
    if drag_mode == DragMode.ERASE:
        board.remove_x(pos, board.DRAG_ERASE_SECONDS)
    else:
        # A new MARK stroke supersedes an older click's in-flight removal.
        board.cancel_x_removal(pos)
        board.model.mark_x(pos)

func choose_drag_mode(pos: Vector2i) -> void:
    # Specialists and confirmed errors cannot select a mode. Starting on one
    # waits for the first editable EMPTY/X, then keeps that mode until release.
    if drag_mode == DragMode.UNSET and board.model.can_mark(pos):
        drag_mode = DragMode.ERASE if board.model.state_at(pos) == board.model.CellState.X else DragMode.MARK
