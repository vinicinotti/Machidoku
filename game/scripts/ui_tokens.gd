extends RefCounted
## Desktop visual specification. Dimensions are fractions of reference H.
## Numbers tagged measured/derived/estimated follow the supplied brief.
const REFERENCE_H := 941.0
const REFERENCE_ASPECT := 1672.0 / REFERENCE_H
const DESKTOP_MIN_WIDTH := 900.0
const TILE := {"radius":0.14,"gap":0.05,"lip":0.055,"highlight":1.0/REFERENCE_H,"pressed_offset":2.5/REFERENCE_H,"pressed_lip":1.0/REFERENCE_H,"specular":0.25}
const COLORS := {
    "orange":{"base":"FD8E61","top":"FEA87E","bottom":"FE7F53","lip":"B73B26"},
    "yellow":{"base":"FEDA48","top":"FEE35C","bottom":"FDD13A","lip":"C59719"},
    "green":{"base":"7EE57A","top":"9AF38C","bottom":"74DE72","lip":"148B36"},
    "sky":{"base":"5BC3FB","top":"6CD3FD","bottom":"4CB8F6","lip":"2091D6"},
    "purple":{"base":"C486F4","top":"D59BFD","bottom":"B97CEC","lip":"804FBF"},
    "pink":{"base":"F08CB7","top":"F29AC0","bottom":"DF82AA","lip":"AD3166"},
    "teal":{"base":"6DD9BA","top":"7FDEC2","bottom":"65CAAD","lip":"209C78"},
    # Estimated indigo replaces cornflower to separate it from sky blue.
    "indigo":{"base":"6F88F2","top":"8096F4","bottom":"677EE1","lip":"364EAE"}}
const SOURCE_KEYS := ["yellow","purple","green","sky","pink","orange","indigo","teal"]
const EXTRA_BASES := [Color("#239887"),Color("#C8458E"),Color("#D6E76E"),Color("#CEAB77")]
const SETTINGS := {"size":Vector2(0.074,0.069),"height":0.069,"radius":0.28,"lip":0.06,"top":Color("#FD7808"),"base":Color("#F4500F"),"bottom":Color("#F4500F"),"edge":Color("#C23A06"),"icon":0.041,"padding":0.009,"padding_y":0.009}
const RESTART := {"top":Color("#FD9F57"),"base":Color("#FA842F"),"bottom":Color("#F46A24"),"edge":Color("#DE3501"),"radius":0.40,"lip":0.06,"icon":0.043,"padding":0.015,"padding_y":0.0106,"height":66.0/REFERENCE_H}
const STRIP := {"height":0.117,"padding":0.0106,"gap":0.0085,"ring":2.0/REFERENCE_H,"radius":0.18,"silhouette":0.65,"overshoot":0.08}
const SECTOR := {"tile":44.0/REFERENCE_H,"row":0.068,"glyph":0.64,"radius":0.25,"gap":14.0/REFERENCE_H,"padding":7.0/REFERENCE_H,"row_padding_x":14.0/REFERENCE_H,"row_padding_y":8.0/REFERENCE_H,"chevron":0.030,"chevron_stroke":3.0/REFERENCE_H,"chevron_color":Color("#0A497C")}
const FOOTER := {"height":0.066,"font":0.022,"icon":0.044,"radius":0.022,"padding":0.0106,"gap":0.015,"score_font":0.022,"help_height":0.066,"help_font":0.015}
const FRAME := {"body":Color("#054877"),"border":Color("#146592"),"groove":Color("#052B4B"),"stroke":2.0/REFERENCE_H}
const WORDMARK := {"font":"res://assets/fonts/Baloo2-Variable.ttf","weight":800.0,"weight_axis":2003265652,"font_size":0.0574,"spacing":0.015,"color":Color("#0A497C"),"width_16_9":0.184,"cap_height":0.038}
const DIFFICULTY := {"easy":Color("#39B745"),"normal_top":Color("#FCBD59"),"normal_bottom":Color("#E89E2D"),"hard":Color("#E76F51"),"very_hard":Color("#D34B45"),"filled":Color.WHITE,"empty":Color("#071928"),"track":Color("#687884"),"outline":Color("#183E52"),"dot":0.014,"border":2.0/REFERENCE_H}
const PLATFORM := {"top":Color("#D9CFC6"),"base":Color("#BFB3AA"),"rim":Color.WHITE,"rim_width":3.0/REFERENCE_H,"shadow":Color("#453A3026"),"center_y":0.84,"radius_x":0.47,"radius_y":0.13,"depth":0.025,"shadow_y":0.035}
const GLYPH_COLORS := {"stamping":Color("#E64056"),"welding":Color("#147AA9"),"painting":Color("#268D9D"),"electrical":Color("#1ED4D9"),"assembly":Color("#4479B4"),"inspection":Color("#ECA329"),"logistics":Color("#D27FAD"),"testing":Color("#199D89"),"powertrain":Color("#DA8134")}
const REFRESH_SVG := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64"><g fill="none" stroke="white" stroke-width="9" stroke-linecap="round"><path d="M13 25a20 20 0 0 1 35-9M51 39a20 20 0 0 1-35 9"/></g><path d="m38 5 16 1-2 16ZM26 59 10 58l2-16Z" fill="white"/></svg>'
const CHEVRON_SVG := '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="32"><path d="m7 7 9 9-9 9" fill="none" stroke="#0A497C" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>'
# Existing desktop geometry converted to H fractions, retaining the three blocks.
const RECTS := {"strip":Rect2(505.0/REFERENCE_H,105.0/REFERENCE_H,638.0/REFERENCE_H,0.117),"message":Rect2(505.0/REFERENCE_H,821.0/REFERENCE_H,638.0/REFERENCE_H,0.066),"help":Rect2(179.0/REFERENCE_H,710.0/REFERENCE_H,310.0/REFERENCE_H,96.0/REFERENCE_H)}
const HELP_TEXT := "Clique: X · Duplo clique: especialista\nArraste: vários X"
const LEGACY_HELP_TEXT := "Clique: X   ·   Duplo clique: especialista   ·   Arraste: vários X"
const ROW_PADDING_Y := 3.0/REFERENCE_H
const GALLERY := {"margin":0.0425,"title_y":0.0255,"title_font":0.0383,"label_font":0.0191,"tile_y":0.1275,"tile_side":0.102,"tile_gap":0.017,"caption_y":0.234,"avatar_y":0.34,"button_y":0.52,"footer_y":0.74,"label_y":0.296,"button_label_y":0.478,"footer_label_y":0.698,"section_gap":0.21}
const GALLERY_RECTS := {"frame":Rect2(1.10,0.12,0.50,0.30),"wordmark":Rect2(1.10,0.48,0.50,0.10),"difficulty":Rect2(0.70,0.74,0.29,0.077),"platform":Rect2(1.15,0.69,0.40,0.18),"hint":Rect2(0.0425,0.90,0.96,0.066)}
const SHELL := {"card_top":Color("#FFFCF7"),"card_base":Color("#FFF7ED"),"card_bottom":Color("#FFE6CF"),"card_lip":Color("#D7BC9F"),"radius":0.0298,"padding":0.0213,"gap":0.0106,"font":0.0276,"secondary_font":0.0191,"secondary_height":0.0468,"primary_height":0.0638,"lip":0.025,"hover":0.05}
const HOME := {"glass":Rect2(296.0/REFERENCE_H,116.0/REFERENCE_H,1080.0/REFERENCE_H,796.0/REFERENCE_H),"summary":Rect2(320.0/REFERENCE_H,140.0/REFERENCE_H,256.0/REFERENCE_H,270.0/REFERENCE_H),"scroll":Rect2(600.0/REFERENCE_H,140.0/REFERENCE_H,752.0/REFERENCE_H,748.0/REFERENCE_H),"exit":Rect2(1308.0/REFERENCE_H,25.0/REFERENCE_H,66.0/REFERENCE_H,66.0/REFERENCE_H),"brand":Rect2(625.0/REFERENCE_H,10.0/REFERENCE_H,423.0/REFERENCE_H,86.0/REFERENCE_H),"glass_tint":0.36,"glass_radius":0.034,"total_font":0.0584,"wallet_font":0.0276,"label_font":0.0191,"phase_font":0.0446,"product_font":0.0276,"world_font":0.017,"car_size":Vector2(0.34,0.15),"row_height":0.0808,"row_padding":0.0106,"row_font":0.0255,"rating_size":Vector2(0.094,0.0298),"marker_car":Vector2(0.089,0.047),"scroll_width":0.0053,"scroll_idle":0.23,"scroll_hover":0.48}
const RESULTS := {"width":0.6376,"padding":0.0234,"radius":0.034,"gap":0.0074,"title_font":0.0404,"eyebrow_font":0.017,"product_font":0.0319,"summary_font":0.0191,"score_font":0.0213,"award_font":0.034,"car_height":0.155,"medal":0.051,"medal_padding":0.0085,"medal_radius":0.43,"rating":Vector2(0.18,0.0553),"primary_height":0.0616,"secondary_height":0.0446,"score_padding":0.0106,"overlay_dim":0.28,"overlay_saturation":0.88,"overlay_tint":0.08,"overlay_blur":1.5,"entrance":0.18}
const COMPLETION := {"settle":0.65,"wave_end":1.40,"overlay_start":1.90,"modal":2.20,"overlay_fade":0.30,"legacy_wait":0.18,"wave_delay":0.035,"tile_duration":0.22,"tile_scale":1.035,"particles":28,"particle_size":0.0032,"particle_drift":0.051,"glow_alpha":0.32,"glow_width":0.0053,"colors":[Color("#FD8E61"),Color("#FEDA48"),Color("#5BC3FB"),Color("#FFF7ED")]}
const HOME_DECORATION := {"watermark":Rect2(360.0/REFERENCE_H,510.0/REFERENCE_H,176.0/REFERENCE_H,176.0/REFERENCE_H),"watermark_alpha":0.13}
const RESULT_PLATFORM_WIDTH := 0.42
const HOME_SCROLLBAR := {"width":8.0/REFERENCE_H,"radius":4.0/REFERENCE_H,"thumb_min":40.0/REFERENCE_H,"track_alpha":0.10,"idle_alpha":0.28,"hover_alpha":0.58,"pressed_alpha":0.75,"edge_alpha":0.22}
const OPTIONS_MODAL := {"width":490.0/REFERENCE_H,"padding":28.0/REFERENCE_H,"radius":32.0/REFERENCE_H,"gap":16.0/REFERENCE_H,"title_font":32.0/REFERENCE_H,"label_font":23.0/REFERENCE_H,"status_font":18.0/REFERENCE_H,"toggle_height":58.0/REFERENCE_H,"toggle_padding":12.0/REFERENCE_H,"toggle_gap":14.0/REFERENCE_H,"check_size":30.0/REFERENCE_H,"close_height":58.0/REFERENCE_H,"viewport_margin":16.0/REFERENCE_H,"minimum_scale":0.75}

static func unit(value: float) -> float:
    return value * REFERENCE_H

static func recipe(index: int) -> Dictionary:
    if index < SOURCE_KEYS.size():
        var data: Dictionary = COLORS[SOURCE_KEYS[index]]
        return {"base":Color(data.base),"top":Color(data.top),"bottom":Color(data.bottom),"lip":Color(data.lip)}
    var base: Color = EXTRA_BASES[(index-SOURCE_KEYS.size()) % EXTRA_BASES.size()]
    return {"base":base,"top":base.lerp(Color.WHITE,0.12),"bottom":Color(base.r*0.93,base.g*0.93,base.b*0.93),"lip":Color.from_hsv(base.h,minf(0.85,base.s+0.30),base.v*0.72)}

# Accepted desktop geometry, normalized to reference H.
const DESIGN_RECTS := {
    "menu_button":Rect2(Vector2(179,26)/REFERENCE_H,Vector2(310,66)/REFERENCE_H),
    "restart_button":Rect2(Vector2(1274,25)/REFERENCE_H,Vector2(246,66)/REFERENCE_H),
    "options_button":Rect2(Vector2(1182,25)/REFERENCE_H,Vector2(66,66)/REFERENCE_H),
    "brand_center":Rect2(Vector2(625,10)/REFERENCE_H,Vector2(423,86)/REFERENCE_H),
    "rules_rail":Rect2(Vector2(179,105)/REFERENCE_H,Vector2(310,590)/REFERENCE_H),
    "product_heading":Rect2(Vector2(19,28)/REFERENCE_H,Vector2(272,62)/REFERENCE_H),
    "product_title":Rect2(Vector2(103,91)/REFERENCE_H,Vector2(169,52)/REFERENCE_H),
    "difficulty_badge":Rect2(Vector2(19,151)/REFERENCE_H,Vector2(272,72)/REFERENCE_H),
    "rules_row":Rect2(Vector2(19,244)/REFERENCE_H,Vector2(272,242)/REFERENCE_H),
    "lives_card":Rect2(Vector2(19,499)/REFERENCE_H,Vector2(272,78)/REFERENCE_H),
    "specialist_strip":Rect2(Vector2(505,105)/REFERENCE_H,Vector2(638,100)/REFERENCE_H),
    "board_mount":Rect2(Vector2(505,218)/REFERENCE_H,Vector2(638,588)/REFERENCE_H),
    "sidebar":Rect2(Vector2(1157,105)/REFERENCE_H,Vector2(378,786)/REFERENCE_H),
    "controls_card":Rect2(Vector2(505,818)/REFERENCE_H,Vector2(638,40)/REFERENCE_H),
    "message_card":Rect2(Vector2(505,870)/REFERENCE_H,Vector2(638,54)/REFERENCE_H),
    "plant_heading":Rect2(Vector2(0,20)/REFERENCE_H,Vector2(334,62)/REFERENCE_H),
    "production_panel":Rect2(Vector2(0,476)/REFERENCE_H,Vector2(334,277)/REFERENCE_H)}
const DESIGN_VECTORS := {
    "message_icon_custom_minimum_size":Vector2(34,34) / REFERENCE_H,
    "brand_row_get_child_0_custom_minimum_size":Vector2(86,86) / REFERENCE_H,
    "phase_icon_custom_minimum_size":Vector2(70,56) / REFERENCE_H,
    "lives_label_custom_minimum_size":Vector2(170,56) / REFERENCE_H,
    "plant_icon_custom_minimum_size":Vector2(56,60) / REFERENCE_H,
    "rule_cards_i_custom_minimum_size":Vector2(272,72) / REFERENCE_H,
    "rule_icons_i_custom_minimum_size":Vector2(46,40) / REFERENCE_H}
const DESIGN_LENGTHS := {
    "options_button_h_separation":0.0 / REFERENCE_H,
    "controls_label_font_size":17.0 / REFERENCE_H,
    "controls_row_separation":16.0 / REFERENCE_H,
    "score_label_font_size":16.0 / REFERENCE_H,
    "button_font_size":32.0 / REFERENCE_H,
    "restart_button_icon_max_width":40.0 / REFERENCE_H,
    "menu_button_icon_max_width":30.0 / REFERENCE_H,
    "options_button_icon_max_width":36.0 / REFERENCE_H,
    "brand_row_separation":12.0 / REFERENCE_H,
    "wordmark_font_size":60.0 / REFERENCE_H,
    "wordmark_shadow_offset_y":3.0 / REFERENCE_H,
    "wordmark_outline_size":1.0 / REFERENCE_H,
    "phase_caption_font_size":23.0 / REFERENCE_H,
    "product_title_font_size":40.0 / REFERENCE_H,
    "rules_row_v_separation":13.0 / REFERENCE_H,
    "lives_box_separation":12.0 / REFERENCE_H,
    "lives_caption_font_size":26.0 / REFERENCE_H,
    "plant_heading_separation":16.0 / REFERENCE_H,
    "plant_captions_get_child_0_font_size":29.0 / REFERENCE_H,
    "plant_captions_get_child_1_font_size":20.0 / REFERENCE_H,
    "feedback_font_size":18.0 / REFERENCE_H}

static func canvas() -> Vector2:
    return Vector2(REFERENCE_ASPECT,1.0)*REFERENCE_H

static func design_rect(key: String) -> Rect2:
    var value: Rect2 = DESIGN_RECTS[key]
    return Rect2((value.position*REFERENCE_H).round(),(value.size*REFERENCE_H).round())

static func design_vector(key: String) -> Vector2:
    return (DESIGN_VECTORS[key]*REFERENCE_H).round()

static func length(key: String) -> int:
    return roundi(DESIGN_LENGTHS[key]*REFERENCE_H)
