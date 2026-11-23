extends RefCounted
## Portrait identity belongs to a sector, never to discovery order.
const Worlds = preload("res://scripts/world_catalog.gd")
const KEYS := ["stamping", "welding", "painting", "electrical", "assembly", "inspection", "logistics", "testing", "powertrain", "finishing"]
static var _portraits := {}
const IDENTITY = preload("res://shaders/specialist_identity.gdshader")

static func for_sector(texture: Texture2D, color: Color, revealed: bool = true) -> ShaderMaterial:
    var result := ShaderMaterial.new()
    result.shader = IDENTITY
    result.set_shader_parameter("sector_color", color)
    result.set_shader_parameter("revealed", revealed)
    if texture is AtlasTexture:
        var region: Rect2 = texture.region
        var atlas_size: Vector2 = texture.atlas.get_size()
        result.set_shader_parameter("atlas_rect", Vector4(region.position.x / atlas_size.x, region.position.y / atlas_size.y, region.size.x / atlas_size.x, region.size.y / atlas_size.y))
    var key := texture.resource_path.get_file().get_basename()
    var hues := {"stamping":0.09, "welding":0.52, "painting":0.76, "electrical":0.25, "assembly":0.60, "inspection":0.09, "logistics":0.92, "testing":0.53, "powertrain":0.08, "finishing":0.90}
    result.set_shader_parameter("clothing_hue", float(hues.get(key, 0.60)))
    result.set_shader_parameter("warm_clothing", key in ["stamping", "inspection", "powertrain"])
    return result

static func for_region(level: Dictionary, region: int) -> Texture2D:
    var metadata := Worlds.world(level.world)
    var key: String = metadata.icons[region] if region < metadata.icons.size() else KEYS[region % KEYS.size()]
    if region < metadata.sectors.size() and metadata.sectors[region] == "Acabamento":
        key = "finishing"
    if not _portraits.has(key):
        _portraits[key] = load("res://assets/specialists/%s.tres" % key)
    return _portraits[key]
