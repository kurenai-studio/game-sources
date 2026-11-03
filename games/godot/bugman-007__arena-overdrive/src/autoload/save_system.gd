extends Node
## Versioned JSON save with forward migration and corrupt-file recovery.
## v1 = legacy {"high_score"} from the original prototype (also read from highscore.cfg),
## v2 = coins/meta/stats, v3 = achievements + unlocked characters + boss stats.

const CURRENT_VERSION := 3
const DEFAULT_PATH := "user://save.json"
const LEGACY_HIGHSCORE_PATH := "user://highscore.cfg"

var path: String = DEFAULT_PATH
var legacy_path: String = LEGACY_HIGHSCORE_PATH
var data: Dictionary = {}


func _ready() -> void:
	data = load_data()


static func default_data() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"coins": 0,
		"meta": {},
		"unlocked_characters": ["vanguard"],
		"achievements": [],
		"stats": {
			"best_score": 0, "best_wave": 0, "total_kills": 0, "runs": 0,
			"coins_earned": 0, "bosses_killed": 0,
		},
	}


static func migrate(raw: Dictionary) -> Dictionary:
	var d := raw.duplicate(true)
	var v := int(d.get("version", 1))
	if v < 2:
		var hs := int(d.get("high_score", 0))
		d = {"version": 2, "coins": 0, "meta": {},
			"stats": {"best_score": hs, "best_wave": 0, "total_kills": 0, "runs": 0, "coins_earned": 0}}
		v = 2
	if v < 3:
		d["achievements"] = []
		d["unlocked_characters"] = ["vanguard"]
		var stats: Dictionary = d.get("stats", {})
		stats["bosses_killed"] = 0
		d["stats"] = stats
		v = 3
	d["version"] = v
	var defaults := default_data()
	for k: String in defaults:
		if not d.has(k):
			d[k] = defaults[k]
	for k: String in defaults["stats"]:
		if not (d["stats"] as Dictionary).has(k):
			d["stats"][k] = defaults["stats"][k]
	return d


func load_data() -> Dictionary:
	if not FileAccess.file_exists(path):
		var legacy := ConfigFile.new()
		if legacy.load(legacy_path) == OK:
			return migrate({"version": 1, "high_score": int(legacy.get_value("scores", "high_score", 0))})
		return default_data()
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null
	if not (parsed is Dictionary):
		push_warning("Save file corrupt; backing up and starting fresh")
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".corrupt"))
		return default_data()
	return migrate(parsed)


func save_data() -> Error:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(abs_path)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), abs_path)


func reset() -> void:
	data = default_data()


# --- wallet ---
func get_coins() -> int:
	return int(data.get("coins", 0))


func add_coins(amount: int) -> void:
	data["coins"] = get_coins() + amount
	data["stats"]["coins_earned"] = stat("coins_earned") + maxi(amount, 0)
	_wallet_changed()


func spend_coins(amount: int) -> bool:
	if amount > get_coins():
		return false
	data["coins"] = get_coins() - amount
	_wallet_changed()
	return true


func _wallet_changed() -> void:
	var bus := get_node_or_null("/root/EventBus") if is_inside_tree() else null
	if bus:
		bus.wallet_changed.emit(get_coins())


# --- meta / unlocks / achievements ---
func get_meta_level(id: StringName) -> int:
	return int((data["meta"] as Dictionary).get(String(id), 0))


func set_meta_level(id: StringName, level: int) -> void:
	data["meta"][String(id)] = level


func meta_levels() -> Dictionary:
	return data["meta"]


func is_unlocked(character_id: StringName) -> bool:
	return (data["unlocked_characters"] as Array).has(String(character_id))


func unlock_character(character_id: StringName) -> void:
	if not is_unlocked(character_id):
		(data["unlocked_characters"] as Array).append(String(character_id))


func has_achievement(id: StringName) -> bool:
	return (data["achievements"] as Array).has(String(id))


func add_achievement(id: StringName) -> bool:
	if has_achievement(id):
		return false
	(data["achievements"] as Array).append(String(id))
	return true


func stat(key: String) -> int:
	return int((data["stats"] as Dictionary).get(key, 0))


## Folds one run's results into lifetime stats and banks coins. Returns true on a new best score.
func record_run(results: Dictionary) -> bool:
	var s: Dictionary = data["stats"]
	s["runs"] = stat("runs") + 1
	s["total_kills"] = stat("total_kills") + int(results.get("kills", 0))
	s["bosses_killed"] = stat("bosses_killed") + int(results.get("bosses", 0))
	s["best_wave"] = maxi(stat("best_wave"), int(results.get("wave", 0)))
	var score := int(results.get("score", 0))
	var new_best := score > stat("best_score")
	if new_best:
		s["best_score"] = score
	add_coins(int(results.get("coins", 0)))
	return new_best
