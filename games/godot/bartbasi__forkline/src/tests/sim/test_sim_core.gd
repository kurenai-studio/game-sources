# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Sim constants and integer helpers (docs/ARCHITECTURE.md 3.1), and the rule that
## src/sim/ holds no float math and no randomness (RULES 8.1, contract 3.1).

const SIM_DIR: String = "res://src/sim"


func test_constants_match_the_contract() -> void:
	assert_eq(Sim.TICKS_PER_SECOND, 20)
	assert_eq(Sim.MS_PER_TICK, 50)
	assert_eq(Sim.UNIT, 20000)
	assert_eq(Sim.MAP_COLUMNS, 7)
	assert_eq(Sim.MAP_ROWS_MIN, 8)
	assert_eq(Sim.MAP_ROWS_MAX, 13)
	assert_eq(Sim.MAX_ENTRANCES, 4)


func test_isqrt_is_the_floor_of_the_root() -> void:
	assert_eq(Sim.isqrt(0), 0)
	assert_eq(Sim.isqrt(1), 1)
	assert_eq(Sim.isqrt(2), 1)
	assert_eq(Sim.isqrt(3), 1)
	assert_eq(Sim.isqrt(4), 2)
	assert_eq(Sim.isqrt(99), 9)
	assert_eq(Sim.isqrt(100), 10)
	assert_eq(Sim.isqrt(-5), 0)
	for n: int in [12345, 87654321, 140000 * 140000 + 260000 * 260000, 4611686014132420609]:
		var root: int = Sim.isqrt(n)
		assert_true(root * root <= n and (root + 1) * (root + 1) > n, "isqrt(%d)" % n)


func test_center_and_cell_of() -> void:
	assert_eq(Sim.center(Vector2i(0, 0)), Vector2i(10000, 10000))
	assert_eq(Sim.center(Vector2i(3, 9)), Vector2i(70000, 190000))
	assert_eq(Sim.cell_of(Vector2i(70000, 190000)), Vector2i(3, 9))
	assert_eq(Sim.cell_of(Vector2i(19999, 20000)), Vector2i(0, 1))
	assert_eq(Sim.cell_of(Vector2i(-1, -20001)), Vector2i(-1, -2))


func test_rounding_follows_rules_2() -> void:
	# RULES 2: half up for health and gold; up for the early call bonus.
	assert_eq(Sim.pct_half_up(5, 150), 8, "52.5 style: 7.5 becomes 8")
	assert_eq(Sim.pct_half_up(90, 150), 135)
	assert_eq(Sim.pct_half_up(12, 150), 18)
	assert_eq(Sim.pct_up(15, 50), 8)
	assert_eq(Sim.pct_up(14, 50), 7)
	assert_true(Sim.cell_before(Vector2i(6, 0), Vector2i(0, 1)), "row first")
	assert_true(Sim.cell_before(Vector2i(1, 2), Vector2i(2, 2)), "then column")


func test_no_float_math_or_randomness_in_src_sim() -> void:
	# Contract 3.1: a scan for float, sqrt(, sin(, cos(, randf, randi and float literals.
	var banned: RegEx = RegEx.create_from_string(
		"\\bfloat\\b|\\bsqrt\\(|\\bsin\\(|\\bcos\\(|\\brandf|\\brandi|RandomNumberGenerator|\\bVector2\\b|\\bVector3\\b|\\bRect2\\b|\\blerp|\\b\\d+\\.\\d*|\\b\\d+e\\d+|\\bINF\\b|\\bNAN\\b|\\bPI\\b|\\bTAU\\b")
	var strings: RegEx = RegEx.create_from_string("\"(\\\\.|[^\"\\\\])*\"")
	var files: PackedStringArray = DirAccess.get_files_at(SIM_DIR)
	var scanned: int = 0
	for file_name: String in files:
		if file_name.get_extension() != "gd":
			continue
		scanned += 1
		var lines: PackedStringArray = FileAccess.get_file_as_string(SIM_DIR.path_join(file_name)).split("\n")
		for i: int in lines.size():
			var code: String = strings.sub(lines[i], "\"\"", true)
			var hash_at: int = code.find("#")
			if hash_at >= 0:
				code = code.left(hash_at)
			var found: RegExMatch = banned.search(code)
			if found != null:
				fail("%s:%d uses %s" % [file_name, i + 1, found.get_string()])
	assert_true(scanned >= 10, "scanned the sim files")


func test_src_sim_uses_no_node_or_file_access() -> void:
	var banned: RegEx = RegEx.create_from_string("\\bNode\\b|\\bNode2D\\b|\\bInput\\b|\\bFileAccess\\b|\\bDirAccess\\b|\\bload\\(|\\bpreload\\(|\\bResourceLoader\\b|\\bTime\\b|\\bOS\\b|\\bEngine\\b")
	for file_name: String in DirAccess.get_files_at(SIM_DIR):
		if file_name.get_extension() != "gd":
			continue
		var text: String = FileAccess.get_file_as_string(SIM_DIR.path_join(file_name))
		var lines: PackedStringArray = text.split("\n")
		for i: int in lines.size():
			var code: String = lines[i]
			var hash_at: int = code.find("#")
			if hash_at >= 0:
				code = code.left(hash_at)
			var found: RegExMatch = banned.search(code)
			if found != null:
				fail("%s:%d uses %s" % [file_name, i + 1, found.get_string()])
		assert_true(text.contains("extends RefCounted"), "%s extends RefCounted" % file_name)
