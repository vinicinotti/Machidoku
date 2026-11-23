extends RefCounted
## Versioned local progression. A temp file + last-good backup protect writes.

const VERSION := 1
const DEFAULT_PATH := "user://progress.json"
const Scoring = preload("res://scripts/scoring_rules.gd")
const Worlds = preload("res://scripts/world_catalog.gd")
var path: String
var data: Dictionary
var last_error := OK
var recovered_backup := false
var read_only := false
var _levels: Array[Dictionary] = []
var last_completion: Dictionary = {}

func _init(save_path: String = DEFAULT_PATH) -> void:
    path = save_path
    data = defaults()

static func defaults() -> Dictionary:
    return {"version": VERSION, "highest_unlocked_level": 1, "current_level": 1,
        "completed_levels": [], "level_stats": {}, "rewards": {}, "settings": {},
        "scoring_version": 1, "wallet_points": 0}

func read_file(file_path: String) -> Dictionary:
    if not FileAccess.file_exists(file_path):
        return {}
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
        return {}
    var parsed = parser.data
    if not parsed is Dictionary:
        return {}
    for key in ["version", "highest_unlocked_level", "current_level"]:
        if not parsed.get(key) is float and not parsed.get(key) is int:
            return {}
        if parsed[key] != int(parsed[key]) or parsed[key] < 1:
            return {}
    if not parsed.get("completed_levels") is Array:
        return {}
    return parsed

func load_progress(levels: Array[Dictionary]) -> void:
    data = defaults()
    recovered_backup = false
    read_only = false
    var legacy_unlocks := false
    var loaded := read_file(path)
    if loaded.is_empty():
        loaded = read_file(path + ".bak")
        recovered_backup = not loaded.is_empty()
    if not loaded.is_empty():
        if int(loaded.version) > VERSION:
            read_only = true
            push_warning("Save de versão futura: preservado sem sobrescrever.")
        else:
            data.merge(loaded, true)
            legacy_unlocks = not loaded.has("scoring_version")
    reconcile(levels, legacy_unlocks)

func reconcile(levels: Array[Dictionary], legacy_unlocks: bool = false) -> void:
    _levels = levels
    for key in ["level_stats", "rewards", "settings"]:
        if not data.get(key) is Dictionary:
            data[key] = {}
    var wallet = data.get("wallet_points", 0)
    data.wallet_points = maxi(0, int(wallet)) if (wallet is int or wallet is float) and is_finite(float(wallet)) else 0
    if levels.is_empty():
        return
    var ids: Array[int] = []
    for level in levels:
        ids.append(int(level.id))
    var completed: Array[int] = []
    for value in data.completed_levels:
        if (value is int or value is float) and value == int(value) and int(value) > 0 and not completed.has(int(value)):
            completed.append(int(value))
    completed.sort()
    data.completed_levels = completed
    for id in completed:
        var reward = data.rewards.get(str(id), {})
        if not reward is Dictionary or reward.get("claimed", false) != true:
            # An old completion is evidence that its one-time reward is spent.
            var claim: Dictionary = reward.duplicate(true) if reward is Dictionary else {}
            claim.merge({"claimed": true, "amount": claim.get("amount", 0), "legacy": true}, true)
            data.rewards[str(id)] = claim
    var highest := ids[0]
    for i in range(ids.size()):
        if ids[i] <= int(data.highest_unlocked_level):
            highest = ids[i]
        if completed.has(ids[i]) and (legacy_unlocks or season_allows(ids[mini(i + 1, ids.size() - 1)])):
            highest = maxi(highest, ids[mini(i + 1, ids.size() - 1)])
    # A temporarily smaller catalogue must not erase an existing unlock.
    data.highest_unlocked_level = maxi(highest, int(data.highest_unlocked_level))
    if not ids.has(int(data.current_level)) or int(data.current_level) > int(data.highest_unlocked_level) or (completed.has(int(data.current_level)) and int(data.current_level) < highest):
        data.current_level = highest

func current_index(levels: Array[Dictionary]) -> int:
    for i in range(levels.size()):
        if int(levels[i].id) == int(data.current_level):
            return i
    return 0

func set_current(level: Dictionary) -> bool:
    if int(level.id) > int(data.highest_unlocked_level):
        return false
    # Replay selection is separate from the campaign Continue cursor.
    if int(level.id) < int(data.current_level) or data.completed_levels.has(int(level.id)):
        return true
    data.current_level = int(level.id)
    return save()

func complete(level: Dictionary, next_level: Dictionary, errors: int, result: Dictionary = {}) -> bool:
    var id := int(level.id)
    last_completion = {}
    if id > int(data.highest_unlocked_level) or gears_for_errors(errors) == 0:
        return false
    var before := data.duplicate(true)
    var old_total := total_gears()
    var first_completion: bool = not data.completed_levels.has(id) and not reward_claimed(id)
    var previous_score := best_gears(id)
    if not data.completed_levels.has(id):
        data.completed_levels.append(id)
        data.completed_levels.sort()
    var next_id := int(next_level.id) if not next_level.is_empty() else id
    var stored = data.level_stats.get(str(id), {})
    var previous: Dictionary = stored if stored is Dictionary else {}
    var score := gears_for_errors(errors)
    var best := maxi(previous_score, score)
    var stats := previous.duplicate(true)
    stats.merge({"completions": int(previous.get("completions", 0)) + 1,
        "last_errors": errors, "best_errors": 3 - best,
        "last_gears": score, "best_gears": best}, true)
    var earned_score := maxi(0, int(result.get("run_score", 0)))
    var previous_best := int(previous.get("best_score", 0))
    if not result.is_empty():
        stats.last_score = earned_score
        stats.best_score = maxi(previous_best, earned_score)
        stats.last_elapsed_sec = maxf(0, float(result.get("elapsed_sec", 0)))
    data.level_stats[str(id)] = stats
    var awarded := earned_score if first_completion else 0
    data.wallet_points = int(data.wallet_points) + awarded
    if first_completion:
        data.rewards[str(id)] = {"claimed": true, "amount": awarded}
    elif not data.rewards.has(str(id)):
        data.rewards[str(id)] = {"claimed": true, "amount": 0, "legacy": true}
    if season_allows(next_id):
        data.highest_unlocked_level = maxi(int(data.highest_unlocked_level), next_id)
    # Improving an older phase can release a previously blocked season boundary.
    for i in range(_levels.size() - 1):
        if data.completed_levels.has(int(_levels[i].id)) and season_allows(int(_levels[i + 1].id)):
            data.highest_unlocked_level = maxi(int(data.highest_unlocked_level), int(_levels[i + 1].id))
    if id >= int(data.current_level):
        data.current_level = next_id if next_id <= int(data.highest_unlocked_level) else id
    if data.completed_levels.has(int(data.current_level)) and int(data.current_level) < int(data.highest_unlocked_level):
        data.current_level = int(data.highest_unlocked_level)
    if not save():
        data = before
        return false
    last_completion = {"wallet_awarded": awarded, "first_completion": first_completion,
        "new_record": earned_score > previous_best, "gears_gained": total_gears() - old_total,
        "total_gears": total_gears(), "wallet_points": int(data.wallet_points)}
    return true

func reward_claimed(id: int) -> bool:
    var reward = data.rewards.get(str(id), {})
    return data.completed_levels.has(id) or (reward is Dictionary and reward.get("claimed", false) == true)

func total_gears() -> int:
    var total := 0
    for id in data.completed_levels:
        total += maxi(0, best_gears(int(id)))
    return total

static func required_gears_for_season(season_id: String, configuration: Array = []) -> int:
    var required := 0
    var entries := Worlds.seasons() if configuration.is_empty() else configuration
    for season in entries:
        if season.id == season_id:
            return required
        required += ceili(season.level_ids.size() * Scoring.GEARS_PER_LEVEL * Scoring.SEASON_GEAR_RATIO)
    return required

func season_allows(id: int) -> bool:
    if id <= int(data.highest_unlocked_level):
        return true
    var season := Worlds.season_for_level(id)
    return season.is_empty() or total_gears() >= required_gears_for_season(season.id)

static func gears_for_errors(errors: int) -> int:
    return 3 - errors if errors >= 0 and errors <= 2 else 0

func best_gears(id: int) -> int:
    if not data.completed_levels.has(id):
        return 0
    var stats = data.level_stats.get(str(id), {})
    if not stats is Dictionary:
        return -1
    var result := -1
    var saved = stats.get("best_gears")
    if (saved is int or saved is float) and saved == int(saved) and saved >= 1 and saved <= 3:
        result = int(saved)
    var errors = stats.get("best_errors")
    if (errors is int or errors is float) and errors == int(errors):
        var derived := gears_for_errors(int(errors))
        if derived > 0:
            result = maxi(result, derived)
    # Old minimal saves without performance data keep an unknown rating.
    return result

func level_status(id: int) -> String:
    if data.completed_levels.has(id):
        return "COMPLETED"
    return "UNLOCKED" if id <= int(data.highest_unlocked_level) else "LOCKED"

func product_completed(levels: Array[Dictionary], world_id: String, product_id: String) -> bool:
    var found := false
    for level in levels:
        if level.world == world_id and level.product == product_id:
            found = true
            if not data.completed_levels.has(int(level.id)):
                return false
    return found

func save() -> bool:
    if read_only:
        last_error = ERR_UNAVAILABLE
        return false
    var absolute := ProjectSettings.globalize_path(path)
    last_error = DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
    if last_error != OK:
        return false
    var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
    if file == null:
        last_error = FileAccess.get_open_error()
        return false
    file.store_string(JSON.stringify(data, "  ") + "\n")
    file.flush()
    last_error = file.get_error()
    file.close()
    if last_error != OK:
        return false
    # Never replace a good backup with a corrupt primary during recovery.
    if not read_file(path).is_empty():
        last_error = DirAccess.copy_absolute(absolute, absolute + ".bak")
        if last_error != OK:
            return false
    last_error = DirAccess.rename_absolute(absolute + ".tmp", absolute)
    return last_error == OK

func reset(levels: Array[Dictionary]) -> bool:
    if read_only:
        return false
    data = defaults()
    reconcile(levels)
    return save()
