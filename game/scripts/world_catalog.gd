extends RefCounted
## Shared authoring/runtime catalogue. Puzzle rules do not depend on products.
static var _catalog: Dictionary = {}
static var _seasons: Array = []

static func seasons() -> Array:
    if _seasons.is_empty():
        _seasons = JSON.parse_string(FileAccess.get_file_as_string("res://data/seasons.json")).seasons
        for season in _seasons:
            season.level_ids = season.level_ids.map(func(value): return int(value))
    return _seasons

static func season_for_level(id: int) -> Dictionary:
    for season in seasons():
        if season.level_ids.has(id):
            return season
    return {}

static func worlds() -> Array:
    if _catalog.is_empty():
        _catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
        for entry in _catalog.worlds:
            for item in entry.products:
                # Derive runtime metadata from the shared authoring catalogue.
                item.first_level = int(item.start_id)
                item.last_level = item.first_level + int(item.level_count) - 1
                item.vehicle_asset = item.asset
    return _catalog.worlds

static func world(id: String) -> Dictionary:
    for entry in worlds():
        if entry.id == id:
            return entry
    return {"id": id, "name": id.to_upper(), "sectors": [], "icons": [], "products": []}

static func product(world_id: String, product_id: String) -> Dictionary:
    var canonical := "sport_coupe" if product_id == "sports" else product_id
    for entry in world(world_id).products:
        if entry.id == canonical:
            return entry
    return {}

static func vehicle(level: Dictionary) -> String:
    return product(level.world, level.product).get("vehicle_asset", "res://assets/vehicles/hatch_compact.png")

static func product_levels(levels: Array[Dictionary], world_id: String, product_id: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for level in levels:
        if level.world == world_id and level.product == product_id:
            result.append(level)
    return result
