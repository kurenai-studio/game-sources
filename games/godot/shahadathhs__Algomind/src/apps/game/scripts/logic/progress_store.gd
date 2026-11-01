class_name ProgressStore
extends RefCounted
## Local progress and settings: one small versioned JSON file in user://.
##
## Writes go to a temporary file first and replace the real file by rename, so an interrupted
## write leaves the previous save intact. The last good save is also kept as `<path>.bak`.
## A missing or unreadable file starts fresh; an unreadable file is first copied to
## `<path>.corrupt` and the backup is tried before starting fresh, so nothing good is lost.
## Nothing here touches the network.

const VERSION := 1

var path: String
## { version, completed: { levelId: { levelVersion, bestCommands, completedAt } }, lastLevel,
## settings } where settings.updatedAt is when a synced setting last changed (Unix seconds).
var data: Dictionary = default_data()
## Typed access to data["settings"].
var settings := Settings.new(self)
## Programs waiting to be verified by the server and its answers; a separate small file.
var results: PlayerResults
## True when the main file was unreadable and the backup was used.
var recovered_from_backup := false
## True when neither file was usable (or none existed) and the data is the defaults.
var started_fresh := true


func _init(save_path: String = "user://progress.json") -> void:
	path = save_path
	results = PlayerResults.new(save_path.get_basename() + "_results.json")


static func default_data() -> Dictionary:
	return {
		"version": VERSION,
		"completed": {},
		"lastLevel": "",
		"settings":
		{
			"theme": "system",
			"reduceMotion": false,
			"sound": true,
			"music": true,
			"vibration": true,
			"runSpeed": "normal",
			"tutorialDone": false,
			"updatedAt": 0.0,
		},
	}


func load_data() -> void:
	results.load_data()
	recovered_from_backup = false
	started_fresh = true
	data = default_data()
	var main: Variant = _read(path)
	if main != null:
		data = main
		started_fresh = false
		return
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".corrupt")
	var backup: Variant = _read(path + ".bak")
	if backup != null:
		data = backup
		started_fresh = false
		recovered_from_backup = true


## Writes the data atomically. Returns false when the write failed; the previous save is then
## still in place.
func save() -> bool:
	return AtomicFile.write_json(path, data, true)


func is_completed(level_id: String) -> bool:
	return data["completed"].has(level_id)


## Fewest commands used to solve this version of the level; 0 when unsolved or when the stored
## result came from another version (a score is never reinterpreted against different content).
func best_commands(level_id: String, level_version: int) -> int:
	var entry: Variant = data["completed"].get(level_id)
	if entry == null or int(entry["levelVersion"]) != level_version:
		return 0
	return int(entry["bestCommands"])


## Records a solved run. The best is kept per level version.
func record_completion(level_id: String, level_version: int, commands: int) -> void:
	var best := best_commands(level_id, level_version)
	if best == 0 or commands < best:
		best = commands
	var previous: Variant = data["completed"].get(level_id)
	var first_at := float(previous.get("completedAt", 0.0)) if previous != null else 0.0
	if first_at <= 0.0:
		first_at = Time.get_unix_time_from_system()
	data["completed"][level_id] = {
		"levelVersion": level_version, "bestCommands": best, "completedAt": first_at
	}


func last_level() -> String:
	return data["lastLevel"]


func set_last_level(level_id: String) -> void:
	data["lastLevel"] = level_id


## Solved levels as a list for syncing: [{ levelId, levelVersion, bestCommands, completedAt }].
func completions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in data["completed"]:
		var e: Dictionary = data["completed"][id]
		(
			out
			. append(
				{
					"levelId": id,
					"levelVersion": int(e["levelVersion"]),
					"bestCommands": int(e["bestCommands"]),
					"completedAt": float(e.get("completedAt", 0.0)),
				}
			)
		)
	return out


## Merges completions from another device. Nothing is ever removed; a level solved on either
## side stays solved. For the same level the newer level version wins (a score is never read
## against different content); for the same version the fewer commands win.
func merge_completions(remote: Array) -> void:
	for raw: Variant in remote:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var id: Variant = raw.get("levelId")
		var version: int = int(raw.get("levelVersion", 0))
		var best: int = int(raw.get("bestCommands", 0))
		if typeof(id) != TYPE_STRING or version < 1 or best < 1:
			continue
		var at := float(raw.get("completedAt", 0.0))
		var local: Variant = data["completed"].get(id)
		if local == null:
			data["completed"][id] = {
				"levelVersion": version, "bestCommands": best, "completedAt": at
			}
			continue
		var local_version := int(local["levelVersion"])
		var local_at := float(local.get("completedAt", 0.0))
		var earliest := minf(at, local_at) if at > 0.0 and local_at > 0.0 else maxf(at, local_at)
		if version > local_version:
			data["completed"][id] = {
				"levelVersion": version, "bestCommands": best, "completedAt": earliest
			}
		elif version == local_version:
			data["completed"][id] = {
				"levelVersion": version,
				"bestCommands": mini(best, int(local["bestCommands"])),
				"completedAt": earliest,
			}
		else:
			local["completedAt"] = earliest


## Level state in the flattened campaign order: "done", "current", or "locked".
## A level is unlocked when every level before it is done. The first unfinished level is current.
func level_state(campaign: Campaign, index: int) -> String:
	var first_open := first_unfinished_index(campaign)
	if index < first_open:
		return "done"
	if index == first_open:
		return "current"
	# A solved level after an unsolved one (campaign reordered) stays playable as done.
	var entry: Dictionary = campaign.entries[index]
	return "done" if is_completed(entry["id"]) else "locked"


## Index of the first level that is not solved; entries.size() when all are solved.
func first_unfinished_index(campaign: Campaign) -> int:
	for i in campaign.entries.size():
		if not is_completed(campaign.entries[i]["id"]):
			return i
	return campaign.entries.size()


func is_unlocked(campaign: Campaign, index: int) -> bool:
	return level_state(campaign, index) != "locked"


## The level Play should open: the last played one if it is unlocked, else the first unfinished
## one, else the last level of the campaign.
func level_to_play(campaign: Campaign) -> int:
	if campaign.entries.is_empty():
		return -1
	var last := campaign.index_of(last_level())
	if last >= 0 and is_unlocked(campaign, last):
		return last
	return mini(first_unfinished_index(campaign), campaign.entries.size() - 1)


## Parsed, sanitized data from a file; null when the file is missing, unreadable, or from a
## newer version than this build understands.
func _read(file_path: String) -> Variant:
	return _sanitize(AtomicFile.read_json(file_path))


## Keeps only well-formed parts. Bad entries are dropped one by one instead of failing the file.
static func _sanitize(parsed: Variant) -> Variant:
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var raw: Dictionary = parsed
	if typeof(raw.get("version")) != TYPE_FLOAT or int(raw["version"]) > VERSION:
		return null
	if int(raw["version"]) < 1:
		return null
	var clean := default_data()
	var completed: Variant = raw.get("completed")
	if typeof(completed) == TYPE_DICTIONARY:
		for id: Variant in completed:
			var entry: Variant = completed[id]
			if typeof(id) != TYPE_STRING or typeof(entry) != TYPE_DICTIONARY:
				continue
			var level_version: Variant = entry.get("levelVersion")
			var best: Variant = entry.get("bestCommands")
			if typeof(level_version) != TYPE_FLOAT or typeof(best) != TYPE_FLOAT:
				continue
			if int(level_version) < 1 or int(best) < 1:
				continue
			var at: Variant = entry.get("completedAt")
			clean["completed"][id] = {
				"levelVersion": int(level_version),
				"bestCommands": int(best),
				"completedAt": float(at) if typeof(at) == TYPE_FLOAT else 0.0,
			}
	if typeof(raw.get("lastLevel")) == TYPE_STRING:
		clean["lastLevel"] = raw["lastLevel"]
	var raw_settings: Variant = raw.get("settings")
	if typeof(raw_settings) == TYPE_DICTIONARY:
		var kept := Settings.clean_synced(raw_settings)
		for key: String in kept:
			clean["settings"][key] = kept[key]
		if typeof(raw_settings.get("tutorialDone")) == TYPE_BOOL:
			clean["settings"]["tutorialDone"] = raw_settings["tutorialDone"]
		if typeof(raw_settings.get("updatedAt")) == TYPE_FLOAT:
			clean["settings"]["updatedAt"] = float(raw_settings["updatedAt"])
	return clean
