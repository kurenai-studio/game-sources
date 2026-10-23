extends SceneTree

const ROOT_DIRS := ["res://addons", "res://scenes", "res://scripts"]
const SELF_PATH := "res://scripts/typecheck.gd"

var _checked_files := 0
var _failures: PackedStringArray = PackedStringArray()


func _init() -> void:
	_walk_roots()
	_report_and_quit()


func _walk_roots() -> void:
	for root_dir in ROOT_DIRS:
		_walk_dir(root_dir)


func _walk_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		_failures.append("Failed to open %s" % path)
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry.begins_with(".") or entry.ends_with(".uid"):
			entry = dir.get_next()
			continue

		var child_path := path.path_join(entry)
		if dir.current_is_dir():
			_walk_dir(child_path)
		elif child_path == SELF_PATH:
			pass
		elif _should_load(entry):
			_checked_files += 1
			var resource := ResourceLoader.load(child_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if resource == null:
				_failures.append("Failed to load %s" % child_path)

		entry = dir.get_next()
	dir.list_dir_end()


func _should_load(file_name: String) -> bool:
	return file_name.ends_with(".gd") or file_name.ends_with(".tscn")


func _report_and_quit() -> void:
	if _failures.is_empty():
		print("Typecheck passed: %d file(s) loaded." % _checked_files)
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	push_error("Typecheck failed: %d file(s) checked, %d failure(s)." % [_checked_files, _failures.size()])
	quit(1)
