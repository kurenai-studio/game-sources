## Every file under game/assets must have a row in ASSETS.md (skips .import, .gitkeep, _incoming).
extends "res://tests/test_case.gd"

const ASSET_DIR := "res://assets"
const SKIP_SUFFIXES: Array[String] = [".import", ".gitkeep", ".uid"]


func test_every_asset_is_in_ledger() -> void:
	var ledger_path := ProjectSettings.globalize_path("res://").path_join("../ASSETS.md").simplify_path()
	var ledger := FileAccess.get_file_as_string(ledger_path)
	check(not ledger.is_empty(), "cannot read %s" % ledger_path)
	for path in _list_files(ASSET_DIR):
		check(ledger.contains(path.trim_prefix("res://")), "%s has no ASSETS.md row" % path)


func _list_files(dir: String) -> Array[String]:
	var found: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		if sub != "_incoming":
			found.append_array(_list_files(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		if not SKIP_SUFFIXES.any(func(s: String) -> bool: return file.ends_with(s)):
			found.append(dir.path_join(file))
	return found
