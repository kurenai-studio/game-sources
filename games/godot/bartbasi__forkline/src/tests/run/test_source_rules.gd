# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Rules for the code in src/run/: pure, seeded, no files, no clock, and no script that
## names its own class as a value (the leak that tests/sim/test_no_leaks.gd explains).

const DIR: String = "res://src/run/"
## Words that must not appear in code. A run is a function of its seed and its data.
const FORBIDDEN: PackedStringArray = [
	"randi(", "randf", "randomize", "rand_weighted", "shuffle", "pick_random", "Time.", "OS.",
	"FileAccess", "DirAccess", "JSON", "load(", "preload(", "ResourceLoader", "Node", "Input",
]


func _code_lines(path: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		out.append(line.get_slice("#", 0))
	return out


func _scripts() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for file_name: String in DirAccess.get_files_at(DIR):
		if file_name.get_extension() == "gd":
			out.append(DIR + file_name)
	return out


func test_there_are_scripts_to_check() -> void:
	assert_true(_scripts().size() >= 7, "%d scripts in src/run/" % _scripts().size())


func test_no_script_names_its_own_class_as_a_value() -> void:
	var own_name: RegEx = RegEx.create_from_string("(?m)^class_name\\s+(\\w+)")
	for path: String in _scripts():
		var found: RegExMatch = own_name.search(FileAccess.get_file_as_string(path))
		assert_not_null(found, path + " has a class_name")
		if found == null:
			continue
		var as_value: RegEx = RegEx.create_from_string("\\b%s\\s*\\." % found.get_string(1))
		var lines: PackedStringArray = _code_lines(path)
		for i: int in lines.size():
			if as_value.search(lines[i]) != null:
				fail("%s:%d names its own class as a value: %s" % [path, i + 1, lines[i].strip_edges()])


func test_no_script_uses_a_global_random_number_the_clock_or_a_file() -> void:
	for path: String in _scripts():
		var lines: PackedStringArray = _code_lines(path)
		for i: int in lines.size():
			for word: String in FORBIDDEN:
				if lines[i].contains(word):
					fail("%s:%d uses %s" % [path, i + 1, word])


func test_the_only_generator_is_the_seeded_one() -> void:
	var count: int = 0
	for path: String in _scripts():
		var text: String = "\n".join(_code_lines(path))
		var at: int = text.find("RandomNumberGenerator.new()")
		while at >= 0:
			count += 1
			assert_true(path.ends_with("map_assembler.gd"), path + " makes a generator")
			at = text.find("RandomNumberGenerator.new()", at + 1)
	assert_eq(count, 1, "one generator is made, in MapAssembler.generator(), and it sets its seed")
	var assembler: String = FileAccess.get_file_as_string(DIR + "map_assembler.gd")
	assert_true(assembler.contains("rng.seed = RunSeeds.derive(run_seed, tag, index)"))


func test_run_packs_does_not_name_run_data_so_the_two_never_refer_to_each_other() -> void:
	for line: String in _code_lines(DIR + "run_packs.gd"):
		assert_false(line.contains("RunData"), line)
	assert_eq(RunPacks.BANDS, RunData.BANDS)


func test_files_are_plain_ascii_with_unix_line_endings() -> void:
	var paths: PackedStringArray = _scripts()
	paths.append_array(["res://data/runs/run.json", "res://data/cards/cards.json"])
	for path: String in paths:
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		for value: int in bytes:
			if value == 13 or value > 126 or (value < 32 and value != 10 and value != 9):
				fail("%s holds byte %d" % [path, value])
				break
		var text: String = bytes.get_string_from_ascii()
		assert_false(text.contains("--") and path.ends_with(".json"), path + " has a double hyphen")
		assert_true(text.ends_with("\n") and not text.ends_with("\n\n"), path + " ends with one line break")
