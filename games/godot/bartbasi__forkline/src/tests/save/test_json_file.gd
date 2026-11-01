# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## JsonFile: reading with a cap, ASCII only, the JSON parser only, and atomic writes
## (docs/ARCHITECTURE.md 5.2, 5.3).

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")


func before_each() -> void:
	Fx.fresh()


func after_each() -> void:
	Fx.clean()


func test_read_statuses() -> void:
	assert_eq(JsonFile.read(Fx.path("none.json"), 100)["status"], JsonFile.MISSING)
	Fx.write_text("a.json", "{\"format\": 1, \"list\": [1, 2.0, \"x\"]}")
	var got: Dictionary = JsonFile.read(Fx.path("a.json"), 100)
	assert_eq(got["status"], JsonFile.OK_STATUS)
	var list: Array = got["data"]["list"]
	assert_eq(list.size(), 3)
	assert_eq(list[0], 1)
	assert_eq(list[1], 2)
	assert_eq(list[2], "x")
	assert_eq(got["text"], "{\"format\": 1, \"list\": [1, 2.0, \"x\"]}")
	# A folder where the file should be exists but cannot be opened: locked.
	DirAccess.make_dir_recursive_absolute(Fx.path("held.json/inner"))
	assert_eq(JsonFile.read(Fx.path("held.json"), 100)["status"], JsonFile.LOCKED)
	assert_eq(JsonFile.probe(Fx.path("held.json")), JsonFile.LOCKED)
	assert_eq(JsonFile.probe(Fx.path("a.json")), JsonFile.OK_STATUS)
	assert_eq(JsonFile.probe(Fx.path("none.json")), JsonFile.MISSING)


func test_cap_is_checked_before_reading() -> void:
	Fx.write_text("a.json", "{\"a\": 1}")
	assert_eq(JsonFile.read(Fx.path("a.json"), 8)["status"], JsonFile.OK_STATUS)
	assert_eq(JsonFile.read(Fx.path("a.json"), 7)["status"], JsonFile.BAD)


func test_hostile_bytes_are_bad_and_data_is_null() -> void:
	var cases: Dictionary = Fx.hostile_files("{\"format\": 1, \"sound\": false}", 4096)
	for name: String in cases:
		Fx.write_bytes("h.json", cases[name])
		var got: Dictionary = JsonFile.read(Fx.path("h.json"), 4096)
		if got["status"] == JsonFile.OK_STATUS:
			# Parsed cleanly: the data is plain JSON values, never an object.
			assert_true([TYPE_DICTIONARY, TYPE_ARRAY, TYPE_STRING, TYPE_FLOAT, TYPE_NIL].has(typeof(got["data"])), name)
		else:
			assert_eq(got["status"], JsonFile.BAD, name)
			assert_null(got["data"], name)
	for name: String in ["empty", "truncated", "corrupt", "garbage", "nul byte", "nul inside", "high bytes", "huge", "deep nesting", "deep objects", "nan", "only spaces"]:
		Fx.write_bytes("h.json", cases[name])
		assert_eq(JsonFile.read(Fx.path("h.json"), 4096)["status"], JsonFile.BAD, name)


func test_infinity_parses_to_a_number_the_checks_refuse() -> void:
	Fx.write_text("h.json", "{\"format\": 1e999, \"b\": -1e999}")
	var got: Dictionary = JsonFile.read(Fx.path("h.json"), 100)
	assert_eq(got["status"], JsonFile.OK_STATUS)
	assert_false(DataCheck.is_whole(got["data"]["format"]))
	assert_false(DataCheck.is_whole(got["data"]["b"]))


func test_write_atomic_round_trip_and_sorted_keys() -> void:
	var path: String = Fx.path("w.json")
	assert_true(JsonFile.write_atomic(path, {"b": [true, null], "a": 2, "c": {"y": "z"}}))
	assert_eq(Fx.read_text("w.json"), "{\"a\":2,\"b\":[true,null],\"c\":{\"y\":\"z\"}}")
	assert_false(Fx.exists("w.json.tmp"))
	assert_false(Fx.exists("w.json.bak"), "no backup unless the caller knows the old text")
	var got: Dictionary = JsonFile.read(path, 1000)
	assert_eq(got["data"]["a"], 2)
	assert_eq(got["data"]["b"], [true, null])
	assert_eq(got["data"]["c"], {"y": "z"})


func test_backup_only_of_known_text() -> void:
	var path: String = Fx.path("w.json")
	assert_true(JsonFile.write_atomic(path, {"v": 1}))
	var first: String = Fx.read_text("w.json")
	assert_true(JsonFile.write_atomic(path, {"v": 2}, "something else"))
	assert_false(Fx.exists("w.json.bak"), "unknown text is not kept as a backup")
	assert_true(JsonFile.write_atomic(path, {"v": 3}, "{\"v\":2}"))
	assert_eq(Fx.read_text("w.json.bak"), "{\"v\":2}")
	assert_eq(Fx.read_text("w.json"), "{\"v\":3}")
	assert_ne(first, Fx.read_text("w.json"))


func test_refuses_non_ascii_and_paths_outside_user() -> void:
	assert_false(JsonFile.write_atomic(Fx.path("w.json"), {"name": "café"}))
	assert_false(Fx.exists("w.json"))
	assert_false(Fx.exists("w.json.tmp"))
	assert_eq(JsonFile.to_text({"name": "café"}), "")
	assert_false(JsonFile.write_text("res://tests/save/w.json", "{}"))
	assert_false(FileAccess.file_exists("res://tests/save/w.json"))


func test_failed_rename_keeps_the_tmp_with_the_newest_text() -> void:
	# A folder in the way makes the final rename fail on every platform.
	DirAccess.make_dir_recursive_absolute(Fx.path("w.json/inner"))
	assert_false(JsonFile.write_atomic(Fx.path("w.json"), {"v": 9}))
	assert_eq(Fx.read_text("w.json.tmp"), "{\"v\":9}")
	assert_true(DirAccess.dir_exists_absolute(Fx.path("w.json/inner")))


func test_unwritable_tmp_writes_nothing() -> void:
	assert_true(JsonFile.write_atomic(Fx.path("w.json"), {"v": 1}))
	DirAccess.make_dir_recursive_absolute(Fx.path("w.json.tmp/inner"))
	assert_false(JsonFile.write_atomic(Fx.path("w.json"), {"v": 2}, "{\"v\":1}"))
	assert_eq(Fx.read_text("w.json"), "{\"v\":1}")
	assert_false(Fx.exists("w.json.bak"))
