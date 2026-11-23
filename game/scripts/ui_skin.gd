extends RefCounted
## Rendering factories; art direction and dimensions live in ui_tokens.gd.
const T = preload("res://scripts/ui_tokens.gd")
const MOULDED = preload("res://shaders/ui_moulded.gdshader")
static var icons := {}
static var faces := {}

static func material(recipe: Dictionary, size: Vector2, radius: float = T.TILE.radius, gap: float = T.TILE.gap, lip: float = T.TILE.lip) -> ShaderMaterial:
    var result := ShaderMaterial.new()
    result.shader = MOULDED
    configure(result,recipe,size,radius,gap,lip)
    return result

static func configure(result: ShaderMaterial, recipe: Dictionary, size: Vector2, radius: float, gap: float, lip: float) -> void:
    for key in ["top","base","bottom","lip"]:
        result.set_shader_parameter("lip_color" if key=="lip" else key+"_color",recipe[key])
    result.set_shader_parameter("extent",size.max(Vector2.ONE))
    result.set_shader_parameter("radius_ratio",radius)
    result.set_shader_parameter("gap_ratio",gap)
    result.set_shader_parameter("lip_ratio",lip)
    result.set_shader_parameter("highlight_width",T.unit(T.TILE.highlight))
    result.set_shader_parameter("highlight_alpha",T.TILE.specular)
    result.set_shader_parameter("press_offset",T.unit(T.TILE.pressed_offset))
    result.set_shader_parameter("pressed_lip",T.unit(T.TILE.pressed_lip))

static func box(recipe: Dictionary, radius: float, padding: float, lip: float, glossy: bool = false, ring: float = 0.0, height: float = 0.0) -> StyleBoxTexture:
    # Render one source at H-relative resolution, with safely separated corners.
    var side := roundi(height if height>0 else T.REFERENCE_H*T.STRIP.height)
    var r := side*radius
    var depth := side*lip
    var hi := T.unit(T.TILE.highlight)
    var key := str([recipe,side,r,depth,glossy,ring])
    if not faces.has(key):
        var specular := '<path d="M%f %fQ%f 0 %f %f" fill="none" stroke="white" stroke-opacity="%f" stroke-width="%f"/>' % [r,hi*3,side*0.5,side-r,hi*3,T.TILE.specular,hi] if glossy else ""
        var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"><defs><linearGradient id="f" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="0.5" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><rect x="%f" y="%f" width="%f" height="%f" rx="%f" fill="#%s"/><rect x="%f" y="%f" width="%f" height="%f" rx="%f" fill="url(#f)" stroke="white" stroke-opacity="%f" stroke-width="%f"/>%s</svg>' % [side,side,recipe.top.to_html(false),recipe.base.to_html(false),recipe.bottom.to_html(false),hi,hi,side-hi*2,side-hi*2,r,recipe.lip.to_html(false),hi,hi,side-hi*2,side-depth-hi*2,r,1.0 if ring>0 else T.TILE.specular,maxf(hi,ring),specular]
        var image := Image.new()
        image.load_svg_from_string(svg)
        faces[key] = ImageTexture.create_from_image(image)
    var result := StyleBoxTexture.new()
    result.texture = faces[key]
    for edge in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
        result.set_texture_margin(edge,r+hi*2)
        result.set_content_margin(edge,padding)
    return result

static func colored_icon(path: String, key: String) -> Texture2D:
    if not icons.has(path):
        var color: Color = T.GLYPH_COLORS.get(key,T.FRAME.body)
        var source := FileAccess.get_file_as_string(path)
        # Existing vectors are recolored, not replaced by invented raster art.
        source = source.replace('#2F86A7','#'+color.lightened(0.20).to_html(false)).replace('#052B50','#'+color.darkened(0.18).to_html(false))
        var image := Image.new()
        image.load_svg_from_string(source,2.0)
        icons[path] = ImageTexture.create_from_image(image)
    return icons[path]
