extends SceneTree
const T = preload("res://scripts/ui_tokens.gd")
const V = preload("res://scripts/visuals.gd")
const Ui = preload("res://scripts/ui_desktop_refinement.gd")
const Palette = preload("res://scripts/sector_palette.gd")
const Loader = preload("res://scripts/level_loader.gd")
var checks := 0
var failures: Array[String] = []
var measurements := {}
var output := ProjectSettings.globalize_path("res://../artifacts")

func _initialize() -> void:
    call_deferred("run")

func frames(count: int = 8) -> void:
    for i in range(count):
        await process_frame

func expect(ok: bool, message: String) -> void:
    checks += 1
    if ok:
        print("PASS ",message)
    else:
        failures.append(message)
        printerr("FAIL ",message)

func delta(a: Color,b: Color) -> float:
    return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))*255.0

func snapshot(name: String) -> void:
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(output.path_join(name+".png"))

func luminance(color: Color) -> float:
    return color.srgb_to_linear().get_luminance()

func contrast(a: Color,b: Color) -> float:
    return (maxf(luminance(a),luminance(b))+0.05)/(minf(luminance(a),luminance(b))+0.05)

func gallery_checks() -> void:
    var gallery = load("res://ui/visual_gallery.tscn").instantiate()
    root.add_child(gallery)
    await frames(12)
    expect(gallery.samples.size()==8,"standalone gallery contains all eight required colors")
    if DisplayServer.get_name()!="headless":
        await RenderingServer.frame_post_draw
        var rendered := root.get_texture().get_image()
        var colors := {}
        for i in range(gallery.samples.size()):
            var face: ColorRect = gallery.samples[i]
            var bounds := face.get_global_rect()
            var recipe: Dictionary = face.get_meta("recipe")
            var center := rendered.get_pixelv(Vector2i(bounds.get_center()))
            var lip := rendered.get_pixelv(Vector2i(bounds.position+bounds.size*Vector2(0.5,0.95)))
            var top := rendered.get_pixelv(Vector2i(bounds.position+bounds.size*Vector2(0.5,0.18)))
            var bottom := rendered.get_pixelv(Vector2i(bounds.position+bounds.size*Vector2(0.5,0.82)))
            expect(delta(center,recipe.base)<=3.0,"center pixel within 3 channels: "+T.SOURCE_KEYS[i])
            expect(delta(lip,recipe.lip)<=3.0,"saturated lip pixel within 3 channels: "+T.SOURCE_KEYS[i])
            expect(delta(top,bottom)>8.0,"visible vertical gradient: "+T.SOURCE_KEYS[i])
            colors[T.SOURCE_KEYS[i]] = {"center":center.to_html(false),"lip":lip.to_html(false),"channel_error":delta(center,recipe.base)}
        measurements.colors = colors
        var silhouette_ok := true
        for i in [1,3,5,7]:
            var view: TextureRect = gallery.portrait_samples[i]
            var bounds := view.get_global_rect()
            var base: Color = T.recipe(i).base
            var target := Color(base.r*T.STRIP.silhouette,base.g*T.STRIP.silhouette,base.b*T.STRIP.silhouette)
            var matching := 0
            for y in range(roundi(bounds.position.y),roundi(bounds.end.y)):
                for x in range(roundi(bounds.position.x),roundi(bounds.end.x)):
                    if delta(rendered.get_pixel(x,y),target)<=3:
                        matching += 1
            silhouette_ok = silhouette_ok and matching>100
        expect(silhouette_ok,"pending silhouettes use flat RGB tint without face detail")
        await snapshot("reference_visual_gallery")
        var pressed: ColorRect = gallery.samples[0]
        var bounds := pressed.get_global_rect()
        var old := rendered.get_pixelv(Vector2i(bounds.position+bounds.size*Vector2(0.5,0.94)))
        pressed.material.set_shader_parameter("pressed",true)
        await frames(2)
        await RenderingServer.frame_post_draw
        var next := root.get_texture().get_image().get_pixelv(Vector2i(bounds.position+bounds.size*Vector2(0.5,0.94)))
        expect(delta(old,next)>10,"pressed body moves down and covers most of its lip")
        await snapshot("reference_visual_gallery_pressed")
    gallery.queue_free()
    await frames()

func game_checks(level: Dictionary, count: int) -> void:
    var game = load("res://scenes/Game.tscn").instantiate()
    game.theme = V.make_theme()
    game.level = level
    game.total_levels = count
    root.add_child(game)
    await frames(12)
    var before: Array = game.model.cells.duplicate()
    var names: Array = game.board.cells.map(func(cell):return cell.name)
    Ui.apply(game)
    await frames()
    expect(before==game.model.cells and game.model.lives==3,"visual reapply preserves puzzle and lives for grid %d" % int(level.size))
    expect(names==game.board.cells.map(func(cell):return cell.name),"visual reapply preserves cell node names")
    var records: Array = game.get_meta("ui_sector_records")
    expect(records.size()==int(level.size) and game.sector_rows.size()==records.size() and game.specialist_strip.slots.size()==records.size(),"registry, list, header and strip agree for %d sectors" % int(level.size))
    var shared := true
    for entry in records:
        shared = shared and entry.id==entry.order and game.specialist_strip.slots[entry.id].tooltip_text==entry.name
        shared = shared and game.sector_rows[entry.id].get_meta("ui_sector_id")==entry.id
        shared = shared and game.specialist_strip.portraits[entry.id].texture==entry.avatar
        for cell in game.board.cells:
            if cell.region_id==entry.id:
                shared = shared and cell.tile_face.material.get_shader_parameter("base_color")==entry.color
    expect(shared,"cells, icon tiles, avatars and row order consume the same sector records")
    var factor: float = game.desktop_stage.scale.x
    print("REFERENCE STRIP ",game.specialist_strip.size," global=",game.specialist_strip.get_global_rect().size," scale=",factor," expected=",T.unit(T.STRIP.height))
    expect(absf(game.specialist_strip.get_global_rect().size.y/(T.REFERENCE_H*factor)-T.STRIP.height)<0.0001,"avatar strip follows 11.7 percent of design H")
    expect(absf(game.message_card.get_global_rect().size.y/(T.REFERENCE_H*factor)-T.FOOTER.height)<0.0001,"single central hint follows 6.6 percent of design H")
    expect(game.controls_card.get_global_rect().end.x<game.board_mount.global_position.x,"controls and points stay in the left auxiliary card")
    expect(game.controls_card.get_global_rect().grow(0.1).encloses(game.score_row.get_global_rect()),"points remain visible within the controls card")
    expect(game.message_card.get_global_rect().position.y>game.board_mount.get_global_rect().end.y,"only the hint follows the board in its central column")
    var scroll: ScrollContainer = game.sidebar.find_child("SectorScroll",true,false)
    scroll.scroll_vertical = 10000
    await frames(4)
    expect(scroll.get_global_rect().grow(0.1).encloses(game.sector_rows[-1].get_global_rect()),"scroll reaches the last actual sector")
    expect(scroll.get_global_rect().end.y<game.production_panel.global_position.y,"production remains fixed outside the scroll")
    scroll.scroll_vertical = 0
    await frames(4)
    for coordinate in game.level.solution:
        var pos := Vector2i(int(coordinate[0]),int(coordinate[1]))
        if game.model.can_mark(pos):
            game.model.toggle_specialist(pos)
            break
    await create_timer(1.3).timeout
    await snapshot("reference_game_%d_sectors_1920x1080" % int(level.size))
    var width_ratio: float = game.board_mount.get_global_rect().size.x/root.size.y
    root.size = Vector2i(1600,900)
    await frames(12)
    expect(absf(game.board_mount.get_global_rect().size.x/root.size.y-width_ratio)<0.001,"16:9 layout dimensions scale with viewport H")
    root.size = Vector2i(1920,1080)
    await frames()
    game.queue_free()
    await frames()

func run() -> void:
    create_timer(70).timeout.connect(func():printerr("REFERENCE TEST TIMEOUT");quit(2))
    root.size = Vector2i(1920,1080)
    root.content_scale_size = Vector2i.ZERO
    var minimum := INF
    for i in range(T.SOURCE_KEYS.size()+T.EXTRA_BASES.size()):
        for j in range(i):
            minimum = minf(minimum,Palette.distance(T.recipe(i).base,T.recipe(j).base))
    expect(minimum>=20,"all available sector color pairs satisfy DeltaE76 >=20")
    measurements.minimum_delta_e_76 = minimum
    var ratios := [contrast(T.DIFFICULTY.filled,T.DIFFICULTY.track),contrast(T.DIFFICULTY.empty,T.DIFFICULTY.track),contrast(T.DIFFICULTY.filled,T.DIFFICULTY.empty)]
    expect(ratios.min()>=3,"filled, empty and dot track maintain at least 3:1 contrast")
    measurements.difficulty_contrast = ratios
    await gallery_checks()
    var levels := Loader.load_levels()
    for dimension in [5,8,9]:
        for level in levels:
            if int(level.size)==dimension:
                await game_checks(level,levels.size())
                break
    var result := {"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements}
    FileAccess.open(output.path_join("reference_ui_tests.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
    print("REFERENCE RESULT: ",checks," checks, ",failures.size()," failures")
    quit(0 if failures.is_empty() else 1)
