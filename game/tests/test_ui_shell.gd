extends SceneTree
const T = preload("res://scripts/ui_tokens.gd")
const Progress = preload("res://scripts/progress_store.gd")
const Loader = preload("res://scripts/level_loader.gd")
var checks := 0
var failures: Array[String] = []
var app
var levels: Array[Dictionary]
var output := ProjectSettings.globalize_path("res://../artifacts")
var timing := {}

func _initialize() -> void:
    call_deferred("run")

func frames(count: int = 10) -> void:
    for i in range(count): await process_frame

func expect(condition: bool,message: String) -> void:
    checks += 1
    if condition: print("PASS ",message)
    else:
        failures.append(message)
        printerr("FAIL ",message)

func snapshot(name: String) -> void:
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(output.path_join(name+".png"))

func until(start: int,seconds: float) -> void:
    var deadline := start+roundi(seconds*1000.0)
    while Time.get_ticks_msec()<deadline:
        await process_frame

func solve(game) -> void:
    for coordinate in game.level.solution:
        var pos := Vector2i(int(coordinate[0]),int(coordinate[1]))
        if game.model.can_mark(pos): game.model.toggle_specialist(pos)

func solve_last(game) -> void:
    var remaining: Array[Vector2i] = []
    for coordinate in game.level.solution:
        var pos := Vector2i(int(coordinate[0]),int(coordinate[1]))
        if game.model.can_mark(pos): remaining.append(pos)
    for i in range(remaining.size()-1): game.model.toggle_specialist(remaining[i])
    await create_timer(1.35).timeout
    game.model.toggle_specialist(remaining[-1])

func wait_result(game) -> void:
    var deadline := Time.get_ticks_msec()+4000
    while not is_instance_valid(game.popup) and Time.get_ticks_msec()<deadline:
        await process_frame
    await frames()

func run() -> void:
    create_timer(75).timeout.connect(func():printerr("SHELL TEST TIMEOUT");quit(2))
    root.size = Vector2i(1920,1080)
    root.content_scale_size = Vector2i.ZERO
    levels = Loader.load_levels()
    var store = Progress.new("user://tests/ui-shell.json")
    store.reset(levels)
    store.data.current_level = 23
    store.data.highest_unlocked_level = 23
    store.data.wallet_points = 17565
    for id in range(1,23):
        store.data.completed_levels.append(id)
        store.data.level_stats[str(id)] = {"best_score":1369 if id==1 else 1352,"best_gears":3}
    store.save()
    app = load("res://scenes/Main.tscn").instantiate()
    app.progress_path = store.path
    root.add_child(app)
    await frames(16)
    var home = app.screen
    expect(home.find_child("TotalScore",true,false).text=="29761","Home preserves sum of existing best scores")
    expect(home.find_child("WalletPoints",true,false).text.contains("17565"),"Home preserves wallet without mixing it with performance")
    expect(home.find_children("GlassSurface","ColorRect",true,false).size()==1,"Home has exactly one structural glass")
    expect(home.featured_id==23 and home.row_ids[0]==22 and not home.row_ids.has(23),"featured phase is not duplicated in descending history")
    expect(home.page.get_child(0).name=="NextPhase","featured and descending history keep their original node order")
    var viewport := Rect2(Vector2.ZERO,Vector2(root.size))
    expect(viewport.encloses(home.find_child("PlayButton",true,false).get_global_rect()),"Home primary CTA fits 16:9 viewport")
    expect(viewport.encloses(home.exit_button.get_global_rect()),"exit button retains a centered framed control in viewport")
    expect(home.brand_row.get_child(1).get_theme_font("font").base_font.resource_path==T.WORDMARK.font,"Home reuses the approved gameplay wordmark")
    expect(home.scroll.get_v_scroll_bar().get_theme_stylebox("grabber").bg_color.a<0.3,"Home scrollbar uses a low-opacity thumb")
    var scroll_pos: Vector2 = home.scroll.global_position
    var next_rect: Rect2 = home.find_child("NextPhase",true,false).get_global_rect()
    expect(next_rect.size.y>home.rows[0].get_global_rect().size.y*2,"featured card dominates dense replay rows")
    await snapshot("shell_home_1920x1080")
    home.scroll.scroll_vertical = 100000
    await frames()
    expect(home.scroll.get_global_rect().grow(0.1).encloses(home.markers[-1].get_global_rect()),"scroll reaches Hatch footer after phase 1")
    expect(home.find_child("TotalScore",true,false).text=="29761" and home.scroll.global_position==scroll_pos,"scrolling does not move totals or mutate their values")
    home.scroll.scroll_vertical = 0
    root.size = Vector2i(390,844)
    await frames(16)
    expect(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(home.find_child("PlayButton",true,false).get_global_rect()),"legacy Home fallback remains reachable after desktop resize")
    root.size = Vector2i(1920,1080)
    await frames(16)
    expect(home.find_children("GlassSurface","ColorRect",true,false).size()==1 and home.get_meta("ui_home_active"),"desktop Home restores its single structural surface")
    home.find_child("PlayButton",true,false).pressed.emit()
    await frames(16)
    var game = app.screen
    expect(int(game.level.id)==23,"existing Home CTA starts the exact selected phase")
    await snapshot("shell_gameplay_1920x1080")
    await solve_last(game)
    var start: int = game.get_meta("ui_completion_started_ms")
    var final_cells: Array = game.model.cells.duplicate()
    var result: Dictionary = game.model.score_result.duplicate(true)
    var time: float = game.model.elapsed_seconds()
    var wallet: int = app.progress.data.wallet_points
    expect(game.model.won and game.model.over and not result.is_empty(),"victory and final score commit immediately")
    expect(app.progress.data.completed_levels.has(23) and wallet==17565+int(result.run_score),"save and wallet commit before the visual celebration")
    expect(not is_instance_valid(game.popup),"result modal is absent at victory time")
    await until(start,0.4)
    expect(not is_instance_valid(game.popup) and game.score_popups.size()>0,"normal operator feedback precedes the modal")
    await until(start,1.05)
    var wave := false
    for cell in game.board.cells: wave = wave or cell.tile_face.scale.x>1.001
    expect(wave,"tile faces perform a micro-pop wave without moving cell nodes")
    await until(start,1.65)
    expect(not is_instance_valid(game.popup),"completed board remains visible during the final hold")
    var settled := true
    for cell in game.board.cells: settled = settled and cell.tile_face.scale.is_equal_approx(Vector2.ONE)
    expect(settled,"all tile faces return to their original scale before overlay")
    await until(start,2.02)
    # Observe Node._process after it runs, without a GPU image readback.
    if DisplayServer.get_name()=="headless":
        await create_timer(0.001).timeout
    else:
        await RenderingServer.frame_post_draw
    var layer = game.get_meta("ui_completion_layer")
    timing.overlay_seconds = float(Time.get_ticks_msec()-start)/1000.0
    expect(is_instance_valid(layer.backdrop) and layer.backdrop.material.get_shader_parameter("progress")>0,"blurred navy overlay transitions progressively after 1.9 seconds")
    while not is_instance_valid(game.popup) and Time.get_ticks_msec()-start<3000:
        await process_frame
    var elapsed := float(Time.get_ticks_msec()-start)/1000.0
    timing.modal_seconds = elapsed
    expect(elapsed>=2.0 and elapsed<=2.6 and is_instance_valid(game.popup),"result modal opens between 2.0 and 2.6 seconds")
    await frames(16)
    expect(game.model.cells==final_cells and game.model.score_result==result,"celebration leaves final cells and calculated result unchanged")
    expect(is_equal_approx(game.model.elapsed_seconds(),time) and app.progress.data.wallet_points==wallet,"celebration adds no scoring time or duplicate wallet credit")
    expect(viewport.grow(0.1).encloses(game.result_panel.get_global_rect()),"result card fits 1920x1080")
    expect(game.popup.find_child("EarnedGears",true,false).active==int(result.gears),"rating retains the exact number of earned gears")
    var source: Label = game.popup.find_child("ScoreSummary",true,false)
    expect(source.text.contains(str(int(result.run_score))) and source.text.contains("+%d pontos" % int(result.run_score)),"original score summary text and node remain available")
    var rich: RichTextLabel = game.popup.find_children("*","RichTextLabel",true,false)[0]
    expect(rich.get_parsed_text()==source.text,"hierarchy formats original result text without recalculating numbers")
    var controls_fit := true
    for button in game.result_column.get_children():
        if button is Button: controls_fit = controls_fit and game.result_panel.get_global_rect().grow(0.1).encloses(button.get_global_rect())
    expect(controls_fit,"result actions fit within the result card")
    await snapshot("shell_results_1920x1080")
    game.popup.find_child("ReplayButton",true,false).pressed.emit()
    await frames(12)
    expect(int(app.screen.level.id)==23 and app.screen.model.lives==3,"existing replay action still restarts the same phase")
    expect(app.progress.data.wallet_points==wallet,"replay navigation does not change wallet")
    # Capture a separate replay: GPU readbacks can stall the very animation
    # deadline being measured above on slower integrated graphics.
    if DisplayServer.get_name()!="headless":
        await solve_last(app.screen)
        var capture_start: int = app.screen.get_meta("ui_completion_started_ms")
        await until(capture_start,0.4)
        await snapshot("shell_completion_0400")
        await until(capture_start,1.05)
        await snapshot("shell_completion_1050")
        await until(capture_start,1.65)
        await snapshot("shell_completion_1650")
        await wait_result(app.screen)
    app.show_menu()
    await frames()
    expect(app.screen.name=="Home" and app.screen.row_ids.size()>0,"return to Home retains campaign history")
    app.progress.data.current_level = 16
    app.show_menu()
    await frames()
    expect(app.screen.page.get_child(1).get_meta("product","")=="sedan","featured product boundary remains immediately after phase 16")
    app.progress.data.settings.reduce_motion = true
    app.start_level(0)
    await frames()
    game = app.screen
    solve(game)
    await create_timer(1.05).timeout
    var still := true
    for cell in game.board.cells: still = still and cell.tile_face.scale.is_equal_approx(Vector2.ONE)
    expect(still and game.get_meta("ui_completion_layer").reduced,"reduced-motion setting suppresses wave and particles")
    app.show_menu()
    await create_timer(1.4).timeout
    expect(app.screen.name=="Home" and app.find_child("VictoryPopup",true,false)==null,"leaving during celebration does not open a stale modal")
    app.queue_free()
    await frames()
    FileAccess.open(output.path_join("shell_ui_tests.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"timing":timing},"  "))
    print("SHELL RESULT: ",checks," checks, ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
