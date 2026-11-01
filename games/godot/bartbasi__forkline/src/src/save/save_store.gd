# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name SaveStore
extends RefCounted
## Every save file, in user:// only (docs/ARCHITECTURE.md 3.5, section 5).
## Reads follow the loading order of 5.4 and writes are atomic (5.3).

const SETTINGS_FILE: String = "settings.json"
const PROGRESS_FILE: String = "progress.json"
const DAILY_FILE: String = "daily.json"
const GAME_FILES: Dictionary[StringName, String] = {
	&"level": "game_level.json", &"run": "game_run.json", &"daily": "game_daily.json",
}
const SETTINGS_CAP: int = 4096
const PROGRESS_CAP: int = 65536
const DAILY_CAP: int = 4096
const GAME_CAP: int = 1048576
const ROOT: String = "user://"

var _dir: String = ROOT
## File name to the text it holds that this store last wrote or loaded as valid.
var _last: Dictionary[String, String] = {}
## File names this launch leaves alone: a copy could not be opened, or holds a newer format.
var _locked: Dictionary[String, bool] = {}
var _top_order: int = 0


## Tests pass a folder under user://tests/. Any folder outside user:// is refused.
func _init(dir: String = ROOT) -> void:
	if dir.begins_with(ROOT) and not dir.contains(".."):
		_dir = dir
	else:
		push_error("SaveStore: save folders must be inside user://")
	DirAccess.make_dir_recursive_absolute(_dir)


func load_settings() -> Settings:
	var got: Dictionary = _load_plain(SETTINGS_FILE, SETTINGS_CAP, Settings.FORMAT)
	return Settings.from_data(got.get("data", null))


func save_settings(settings: Settings) -> bool:
	if settings == null:
		return false
	return _write(SETTINGS_FILE, settings.to_data(), SETTINGS_CAP)


func load_progress() -> Progress:
	var got: Dictionary = _load_plain(PROGRESS_FILE, PROGRESS_CAP, Progress.FORMAT)
	return Progress.from_data(got.get("data", null))


func save_progress(progress: Progress) -> bool:
	if progress == null:
		return false
	return _write(PROGRESS_FILE, progress.to_data(), PROGRESS_CAP)


func load_daily() -> DailyRecord:
	var got: Dictionary = _load_plain(DAILY_FILE, DAILY_CAP, DailyRecord.FORMAT)
	return DailyRecord.from_data(got.get("data", null))


func save_daily(daily: DailyRecord) -> bool:
	if daily == null:
		return false
	return _write(DAILY_FILE, daily.to_data(), DAILY_CAP)


## Every valid saved game, most recent first. When no copy of a mode's game is valid,
## all of its copies are deleted, so a bad save never comes back.
func load_games(game: GameData) -> Array[SavedGame]:
	var found: Array[SavedGame] = []
	for mode: StringName in SavedGame.MODES:
		var saved: SavedGame = _load_game(mode, game)
		if saved != null:
			found.append(saved)
			_top_order = maxi(_top_order, saved.order)
	found.sort_custom(func(a: SavedGame, b: SavedGame) -> bool: return a.order > b.order)
	return found


## Gives the game the next order number, then writes its mode's file.
## False when the game cannot be saved or the write failed.
func save_game(saved: SavedGame) -> bool:
	if saved == null or not saved.can_save():
		return false
	_top_order = mini(maxi(_top_order, saved.order) + 1, SavedGame.ORDER_MAX)
	saved.order = _top_order
	return _write(GAME_FILES[saved.mode], saved.to_data(), GAME_CAP)


## Deletes every copy of a mode's saved game, unless its files are left alone this launch.
func delete_game(mode: StringName) -> void:
	if not GAME_FILES.has(mode):
		return
	_delete_all(GAME_FILES[mode])


## True when this launch leaves the file alone (5.2): nothing writes, renames or deletes it.
func is_locked(file_name: String) -> bool:
	return _locked.has(file_name)


func _path(file_name: String) -> String:
	return _dir.path_join(file_name)


## Loads settings, progress or the daily record (5.4). "Valid" means a JSON object with
## this build's format; the caller's from_data then checks each field. {"data": Variant},
## with no "data" for defaults.
func _load_plain(file_name: String, cap: int, format: int) -> Dictionary:
	if _find_lock(file_name):
		return {}
	var path: String = _path(file_name)
	for suffix: String in [JsonFile.TMP, "", JsonFile.BAK]:
		var got: Dictionary = JsonFile.read(path + suffix, cap)
		if got["status"] == JsonFile.MISSING:
			continue
		var known: int = _format_of(got)
		if known > format:
			# A newer build wrote this. Never overwrite it with an older one.
			_locked[file_name] = true
			return {}
		if known == format:
			_accept(file_name, suffix, got["text"])
			return {"data": got["data"]}
		if suffix == JsonFile.TMP:
			JsonFile.remove(path + suffix)
	return {}


## Loads one mode's saved game (5.4). Any invalid copy is passed over; with no valid
## copy, all of them are deleted, a newer format included.
func _load_game(mode: StringName, game: GameData) -> SavedGame:
	var file_name: String = GAME_FILES[mode]
	if _find_lock(file_name):
		return null
	var path: String = _path(file_name)
	for suffix: String in [JsonFile.TMP, "", JsonFile.BAK]:
		var got: Dictionary = JsonFile.read(path + suffix, GAME_CAP)
		if got["status"] == JsonFile.MISSING:
			continue
		var saved: SavedGame = null
		if got["status"] == JsonFile.OK_STATUS:
			saved = SavedGame.from_data(got["data"], game)
		if saved != null and saved.mode == mode:
			_accept(file_name, suffix, got["text"])
			return saved
		if suffix == JsonFile.TMP:
			JsonFile.remove(path + suffix)
	_delete_all(file_name)
	return null


## A copy passed its check. A .tmp is the newest attempt, so it moves into place.
func _accept(file_name: String, suffix: String, text: String) -> void:
	var path: String = _path(file_name)
	if suffix == "":
		_last[file_name] = text
	elif suffix == JsonFile.TMP and DirAccess.rename_absolute(path + suffix, path) == OK:
		_last[file_name] = text


## True when any copy exists but cannot be opened. The file is then left alone this launch.
func _find_lock(file_name: String) -> bool:
	if _locked.has(file_name):
		return true
	var path: String = _path(file_name)
	for suffix: String in [JsonFile.TMP, "", JsonFile.BAK]:
		if JsonFile.probe(path + suffix) == JsonFile.LOCKED:
			_locked[file_name] = true
			return true
	return false


## The whole number in a read's "format" field, or 0 when it has none.
static func _format_of(got: Dictionary) -> int:
	if got["status"] != JsonFile.OK_STATUS or typeof(got["data"]) != TYPE_DICTIONARY:
		return 0
	var value: Variant = (got["data"] as Dictionary).get("format", null)
	if not DataCheck.is_whole(value) or int(value) < 1:
		return 0
	return int(value)


## Writes one file atomically (5.3). A write whose text equals the text the file already
## holds from this store is skipped. Text over the file's cap is never written.
func _write(file_name: String, data: Dictionary, cap: int) -> bool:
	if _locked.has(file_name) or _find_lock(file_name):
		return false
	var text: String = JsonFile.to_text(data)
	if text.is_empty() or text.length() > cap:
		return false
	var path: String = _path(file_name)
	var last: String = _last.get(file_name, "")
	if text == last and not FileAccess.file_exists(path + JsonFile.TMP) and FileAccess.file_exists(path):
		return true
	if not JsonFile.write_text(path, text, last):
		return false
	_last[file_name] = text
	return true


func _delete_all(file_name: String) -> void:
	if _locked.has(file_name) or _find_lock(file_name):
		return
	var path: String = _path(file_name)
	JsonFile.remove(path + JsonFile.TMP)
	JsonFile.remove(path + JsonFile.BAK)
	JsonFile.remove(path)
	_last.erase(file_name)
