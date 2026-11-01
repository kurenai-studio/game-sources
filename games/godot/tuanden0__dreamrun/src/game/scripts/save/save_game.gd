## Local save file: one JSON document in user:// with a `version` and the time it was written (`saved_at`, unix seconds).
## A missing, unreadable or unknown-version file reads as "no save": the game never fails because of it.
## Written to a temporary file first and swapped in, so a crash while saving cannot leave half a file. If the swap itself
## was interrupted, the temporary file is used.
## ponytail: one slot, and no cloud sync (the backend was dropped); add slots here when a menu needs them.
class_name SaveGame
extends RefCounted

const VERSION := 1
const FILE := "user://dreamrun_save.json"


## DREAMRUN_SAVE overrides the location (the test runner points it at a scratch file).
static func default_path() -> String:
	var override := OS.get_environment("DREAMRUN_SAVE")
	return override if override != "" else FILE


static func write(data: Dictionary, path: String = "") -> bool:
	if path == "":
		path = default_path()
	var document := data.duplicate()
	document["version"] = VERSION
	document["saved_at"] = Time.get_unix_time_from_system()
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("save: cannot write %s (error %d)" % [temporary, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var error := DirAccess.rename_absolute(temporary, path)
	if error != OK:
		push_warning("save: cannot move %s into place (error %d)" % [temporary, error])
		return false
	return true


## The saved document, or {} when there is none.
static func read(path: String = "") -> Dictionary:
	if path == "":
		path = default_path()
	var source := path if FileAccess.file_exists(path) else path + ".tmp"
	if not FileAccess.file_exists(source):
		return {}
	var json := JSON.new()  # parse() reports a bad file as a return code; parse_string() would also log an error
	if json.parse(FileAccess.get_file_as_string(source)) != OK:
		return {}
	var parsed: Variant = json.data
	if not (parsed is Dictionary) or not (parsed.get("version") is float) or int(parsed["version"]) != VERSION:
		return {}
	return parsed


static func erase(path: String = "") -> void:
	if path == "":
		path = default_path()
	for file in [path, path + ".tmp"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
