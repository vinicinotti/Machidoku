extends Control

const V = preload("res://scripts/visuals.gd")
const Loader = preload("res://scripts/level_loader.gd")
const GameScene = preload("res://scenes/Game.tscn")
const Progress = preload("res://scripts/progress_store.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
const LevelSelect = preload("res://scripts/level_select.gd")

@export var progress_path: String = Progress.DEFAULT_PATH
var levels: Array[Dictionary] = []
var progress
var level_index := 0
var screen: Control

func _ready() -> void:
    # Let Containers respond to the native viewport, including portrait windows.
    # A fixed desktop canvas would shrink typography on narrow displays.
    get_window().content_scale_size = Vector2i.ZERO
    theme = V.make_theme()
    RenderingServer.set_default_clear_color(V.CREAM)
    levels = Loader.load_levels()
    progress = Progress.new(progress_path)
    progress.load_progress(levels)
    show_menu()

func clear_screen() -> void:
    if is_instance_valid(screen):
        remove_child(screen)
        screen.queue_free()

func show_menu() -> void:
    clear_screen()
    var home := LevelSelect.new()
    home.name = "Home"
    home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    home.levels = levels
    home.progress = progress
    home.level_selected.connect(start_level)
    home.exit_requested.connect(func(): get_tree().quit())
    screen = home
    add_child(screen)

func start_level(index: int) -> void:
    if index < 0 or index >= levels.size():
        show_menu()
        return
    if int(levels[index].id) > int(progress.data.highest_unlocked_level):
        return
    var saved: bool = progress.set_current(levels[index])
    clear_screen()
    level_index = index
    var game = GameScene.instantiate()
    game.level = levels[index]
    game.progress_store = progress
    game.is_last = index == levels.size() - 1
    game.total_levels = levels.size()
    var batch := Worlds.product_levels(levels, game.level.world, game.level.product)
    game.product_phase = batch.find(game.level) + 1
    game.product_total = batch.size()
    game.menu_requested.connect(show_menu)
    game.retry_requested.connect(func(): start_level(level_index))
    game.next_requested.connect(func(): start_level(level_index + 1))
    game.level_completed.connect(on_level_completed.bind(index))
    screen = game
    add_child(screen)
    if not saved:
        game.feedback.text = "Não foi possível salvar o progresso. Verifique o acesso à pasta de dados."

func on_level_completed(errors: int, index: int) -> void:
    var next: Dictionary = levels[index + 1] if index + 1 < levels.size() else {}
    var unlocking: bool = not next.is_empty() and int(next.id) > int(progress.data.highest_unlocked_level) and (next.product != levels[index].product or next.world != levels[index].world)
    if not progress.complete(levels[index], next, errors, screen.model.score_result):
        push_warning("Não foi possível salvar o progresso: " + error_string(progress.last_error))
        screen.show_save_warning()
    else:
        screen.completion_receipt = progress.last_completion
        if unlocking and int(next.id) <= int(progress.data.highest_unlocked_level):
            screen.unlocked_product = next.vehicle_name
        if not next.is_empty() and int(next.id) > int(progress.data.highest_unlocked_level):
            var season := Worlds.season_for_level(int(next.id))
            screen.season_block_message = "%s: %d / %d engrenagens.\nMelhore suas notas em replay." % [season.display_name, progress.total_gears(), Progress.required_gears_for_season(season.id)]

func _unhandled_key_input(event: InputEvent) -> void:
    if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_R and event.ctrl_pressed and event.shift_pressed:
            var dialog := ConfirmationDialog.new()
            dialog.title = "Restaurar progresso local?"
            dialog.dialog_text = "Todas as fases concluídas serão removidas deste save."
            add_child(dialog)
            dialog.confirmed.connect(func():
                if progress.reset(levels):
                    show_menu()
                dialog.queue_free())
            dialog.canceled.connect(dialog.queue_free)
            dialog.popup_centered()
            get_viewport().set_input_as_handled()
