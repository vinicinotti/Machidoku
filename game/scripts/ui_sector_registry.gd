extends RefCounted
## One visual record per real sector. No generation or puzzle assignment here.
const T = preload("res://scripts/ui_tokens.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
const Palette = preload("res://scripts/sector_palette.gd")
const Art = preload("res://scripts/specialist_art.gd")

static func build(level: Dictionary, source_colors: Array[Color]) -> Array:
    var result: Array = []
    var metadata := Worlds.world(level.world)
    for id in range(int(level.size)):
        var source: Color = source_colors[id]
        var recipe := T.recipe(maxi(Palette.COLORS.find(source),0))
        result.append({"id":id,"order":id,"name":metadata.sectors[id],"icon":metadata.icons[id],"avatar":Art.for_region(level,id),"source":source,"color":recipe.base,"recipe":recipe})
    return result
