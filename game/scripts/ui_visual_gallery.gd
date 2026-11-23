extends Control
## Standalone visual components; no puzzle/model or gameplay script is loaded.
const T = preload("res://scripts/ui_tokens.gd")
const V = preload("res://scripts/visuals.gd")
const UiSkin = preload("res://scripts/ui_skin.gd")
const Ui = preload("res://scripts/ui_desktop_refinement.gd")
const Art = preload("res://scripts/specialist_art.gd")
var samples: Array[ColorRect] = []
var portrait_samples: Array[TextureRect] = []
var canvas: Control

func label_at(text: String, point: Vector2, font_size: float = T.GALLERY.label_font) -> Label:
    var label := V.label(text,"HudLabel",roundi(T.unit(font_size)))
    label.position = point*T.REFERENCE_H
    canvas.add_child(label)
    return label

func _ready() -> void:
    theme = V.make_theme()
    var background := ColorRect.new()
    background.color = V.PAPER
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)
    canvas = Control.new()
    add_child(canvas)
    label_at("MACHIDOKU · GALERIA VISUAL",Vector2(T.GALLERY.margin,T.GALLERY.title_y),T.GALLERY.title_font)
    for i in range(T.SOURCE_KEYS.size()):
        var key: String = T.SOURCE_KEYS[i]
        var recipe := T.recipe(i)
        var x: float = T.GALLERY.margin+i*(T.GALLERY.tile_side+T.GALLERY.tile_gap)
        var face := ColorRect.new()
        face.mouse_filter = Control.MOUSE_FILTER_IGNORE
        face.position = Vector2(x,T.GALLERY.tile_y)*T.REFERENCE_H
        face.size = Vector2.ONE*T.unit(T.GALLERY.tile_side)
        face.material = UiSkin.material(recipe,face.size)
        face.set_meta("recipe",recipe)
        canvas.add_child(face)
        samples.append(face)
        label_at(key,Vector2(x,T.GALLERY.caption_y))
        var slot := PanelContainer.new()
        slot.position = Vector2(x,T.GALLERY.avatar_y)*T.REFERENCE_H
        slot.size = Vector2.ONE*T.unit(T.GALLERY.tile_side)
        slot.add_theme_stylebox_override("panel",UiSkin.box(recipe,T.STRIP.radius,T.unit(T.ROW_PADDING_Y),T.TILE.lip,false,T.unit(T.STRIP.ring),slot.size.y))
        var view := V.texture("res://assets/specialists/%s.tres" % Art.KEYS[i],Vector2.ZERO)
        view.material = Art.for_sector(view.texture,recipe.base,i%2==0)
        view.material.set_shader_parameter("flat_pending",true)
        view.material.set_shader_parameter("pending_tint",T.STRIP.silhouette)
        portrait_samples.append(view)
        slot.add_child(view)
        canvas.add_child(slot)
        var badge := PanelContainer.new()
        badge.position = Vector2(x,T.GALLERY.button_y)*T.REFERENCE_H
        badge.size = Vector2.ONE*T.unit(T.SECTOR.tile)
        badge.add_theme_stylebox_override("panel",UiSkin.box(recipe,T.SECTOR.radius,T.unit(T.SECTOR.padding),T.TILE.lip,false,0.0,badge.size.y))
        var glyph := TextureRect.new()
        glyph.texture = UiSkin.colored_icon("res://assets/sectors/%s.svg" % Art.KEYS[i],Art.KEYS[i])
        glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        badge.add_child(glyph)
        canvas.add_child(badge)
    label_at("Retrato encontrado / silhueta pendente",Vector2(T.GALLERY.margin,T.GALLERY.label_y))
    label_at("Ícones coloridos e botões com relevo",Vector2(T.GALLERY.margin,T.GALLERY.button_label_y))
    Ui.prepare_icons()
    var settings := Button.new()
    settings.position = Vector2(T.GALLERY.margin,T.GALLERY.footer_y)*T.REFERENCE_H
    settings.size = T.SETTINGS.size*T.REFERENCE_H
    settings.icon = Ui.settings_icon
    canvas.add_child(settings)
    Ui.action_skin(settings,T.SETTINGS)
    var restart := Button.new()
    restart.text = "Reiniciar"
    restart.icon = Ui.refresh_icon
    restart.position = Vector2(T.GALLERY.margin+T.GALLERY.section_gap,T.GALLERY.footer_y)*T.REFERENCE_H
    restart.size = Vector2(T.GALLERY.section_gap,T.SETTINGS.size.y)*T.REFERENCE_H
    restart.add_theme_font_size_override("font_size",roundi(T.unit(T.FOOTER.font)))
    canvas.add_child(restart)
    Ui.action_skin(restart,T.RESTART)
    label_at("Normal / hover / pressionado: botões nativos",Vector2(T.GALLERY.margin,T.GALLERY.footer_label_y))
    var frame := PanelContainer.new()
    Ui.rect(frame,T.GALLERY_RECTS.frame)
    frame.add_theme_stylebox_override("panel",V.board_rim())
    canvas.add_child(frame)
    var bezel := PanelContainer.new()
    var border := V.box(T.FRAME.body,roundi(T.unit(T.FOOTER.radius)),roundi(T.unit(T.STRIP.padding)),T.FRAME.border)
    border.set_border_width_all(roundi(T.unit(T.FRAME.stroke)))
    bezel.add_theme_stylebox_override("panel",border)
    frame.add_child(bezel)
    var groove := ColorRect.new()
    groove.color = T.FRAME.groove
    bezel.add_child(groove)
    var wordmark := V.label("MACHIDOKU")
    Ui.rect(wordmark,T.GALLERY_RECTS.wordmark)
    Ui.style_wordmark(wordmark)
    canvas.add_child(wordmark)
    var difficulty := PanelContainer.new()
    difficulty.set_script(preload("res://scripts/difficulty_badge.gd"))
    Ui.rect(difficulty,T.GALLERY_RECTS.difficulty)
    canvas.add_child(difficulty)
    difficulty.set_compact(false)
    Ui.style_difficulty(difficulty)
    var platform := Control.new()
    platform.set_script(preload("res://scripts/production_stage.gd"))
    Ui.rect(platform,T.GALLERY_RECTS.platform)
    canvas.add_child(platform)
    var hint := PanelContainer.new()
    Ui.rect(hint,T.GALLERY_RECTS.hint)
    hint.add_theme_stylebox_override("panel",V.desktop_surface(V.PAPER,roundi(T.unit(T.FOOTER.radius)),roundi(T.unit(T.FOOTER.padding))))
    var hint_row := HBoxContainer.new()
    hint_row.add_child(V.texture("res://assets/ui/icon_error.svg",Vector2.ONE*T.unit(T.FOOTER.icon)))
    hint_row.add_child(V.label("Encontre os especialistas. Os X são suas anotações.","HudLabel",roundi(T.unit(T.FOOTER.font))))
    hint.add_child(hint_row)
    canvas.add_child(hint)
    resized.connect(fit)
    fit()

func fit() -> void:
    var factor := minf(size.y/T.REFERENCE_H,size.x/(T.REFERENCE_H*T.REFERENCE_ASPECT))
    canvas.scale = Vector2.ONE*factor
    canvas.position = (size-Vector2(T.REFERENCE_H*T.REFERENCE_ASPECT,T.REFERENCE_H)*factor)/2.0
