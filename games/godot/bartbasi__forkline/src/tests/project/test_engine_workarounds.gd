# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Guards against code shapes that set off known bugs in Godot 4.7.2.

## Godot 4.7.2 can read freed memory when it unloads scripts at quit if a
## screen that App holds names App as a type, so the two scripts refer to each
## other. It crashed about one quit in seven. Screens talk to App through
## signals instead, and only app.gd itself may name App as a type.
const APP_FILE: String = "res://src/ui/app.gd"


func test_only_app_names_app_as_a_type() -> void:
	# `x: App`, `-> App`, `[App]`, `as App` and `is App`.
	var regex: RegEx = RegEx.create_from_string("(:\\s*App\\b|->\\s*App\\b|\\[App\\]|\\bas\\s+App\\b|\\bis\\s+App\\b)")
	var checked: int = 0
	for path: String in _scripts("res://src"):
		checked += 1
		if path == APP_FILE:
			continue
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for i: int in lines.size():
			if regex.search(lines[i]) != null:
				fail("%s:%d names App as a type; send a signal to App instead" % [path, i + 1])
	assert_true(checked > 50, "the game's scripts were scanned")


func _scripts(dir_path: String) -> PackedStringArray:
	var files: PackedStringArray = PackedStringArray()
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		files.append_array(_scripts(dir_path.path_join(sub_dir)))
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.get_extension() == "gd":
			files.append(dir_path.path_join(file_name))
	return files
