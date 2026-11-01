# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Nothing in src/sim/, src/save/ or src/run/ stays alive after its last user lets go (QA p7).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const SCRIPT_DIRS: Array[String] = ["res://src/sim/", "res://src/save/", "res://src/run/"]


## A script that names its own class as a value (Battle.new() inside battle.gd) holds
## a reference to itself. Godot cannot free it at exit and reports leaked GDScript
## objects. Inside its own file a class uses new() and bare names instead.
## Type hints such as "-> Battle" are fine and are not flagged.
func test_no_script_names_its_own_class_as_a_value() -> void:
	var checked: int = 0
	var own_name: RegEx = RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	for dir_path: String in SCRIPT_DIRS:
		for file_name: String in DirAccess.get_files_at(dir_path):
			if file_name.get_extension() != "gd":
				continue
			var path: String = dir_path + file_name
			var text: String = FileAccess.get_file_as_string(path)
			var found: RegExMatch = own_name.search(text)
			if found == null:
				continue
			checked += 1
			var as_value: RegEx = RegEx.create_from_string("\\b%s\\s*\\." % found.get_string(1))
			var line_number: int = 0
			for line: String in text.split("\n"):
				line_number += 1
				var code: String = line.get_slice("#", 0)
				if as_value.search(code) != null:
					fail("%s:%d names its own class as a value: %s" % [path, line_number, line.strip_edges()])
	assert_true(checked >= 20, "every sim, save and run script was checked: %d" % checked)


## Battle holds plain data only. A played, saved and restored battle is freed as soon
## as the test drops it, so no RefCounted cycle keeps it alive.
func test_a_played_and_restored_battle_is_freed() -> void:
	var waves: Array = [
		{"groups": [Fx.group("scamp", 4, 0, 600), Fx.group("flitter", 2, 500, 600)]},
		{"groups": [Fx.group("grumblesack", 1), Fx.group("pip", 4, 1000, 300)]},
	]
	var b: Battle = Fx.battle(Fx.FORK_GRID, waves, {"start_gold": 4000, "gates": 1})
	b.place_tower(Vector2i(3, 3), &"sling_post")
	b.place_tower(Vector2i(3, 5), &"pumpkin_catapult")
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	Fx.steps(b, 200)
	var copy: Battle = Fx.restored(b)
	assert_not_null(copy, "the battle restores")
	Fx.run_wave(copy)
	copy.start_next_wave()
	Fx.steps(copy, 200)
	copy.take_events()
	var first: WeakRef = weakref(b)
	var second: WeakRef = weakref(copy)
	var level: WeakRef = weakref(b.level)
	b = null
	copy = null
	assert_null(first.get_ref(), "the played battle is freed")
	assert_null(second.get_ref(), "the restored battle is freed")
	assert_null(level.get_ref(), "its level data is freed")
