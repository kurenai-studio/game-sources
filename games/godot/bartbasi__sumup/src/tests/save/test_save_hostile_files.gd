extends "res://tests/base_test.gd"
## Hostile save files through SaveService (docs/ARCHITECTURE.md section 10).
## A hostile run file gives no run, is discarded, and never crashes. A hostile
## profile gives defaults for every part it breaks, keeps the parts it does
## not, and is never deleted.

const F := preload("res://tests/save/save_fixtures.gd")

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()


func after_each() -> void:
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


func _profile_path() -> String:
	return _dir.path_join("profile.json")


func _control_text() -> String:
	return F.to_text(SaveCodec.run_to_data(F.control_run()))


## The control run as data with ints, ready for one change.
func _control_data() -> Dictionary:
	return SaveCodec.run_to_data(F.control_run())


func _good_profile_data() -> Dictionary:
	return {"format": 1, "settings": {"sound_on": false, "skin": "slate"}, "records": {"best_score": "5000", "best_tile": 9}}


func _assert_run_refused(bytes: PackedByteArray, label: String) -> void:
	F.write_bytes(_run_path(), bytes)
	assert_true(_service.load_run(_config) == null, "%s: no run" % label)
	assert_false(_service.has_run(), "%s: discarded" % label)


func _assert_run_text_refused(text: String, label: String) -> void:
	_assert_run_refused(text.to_utf8_buffer(), label)


## Loads the profile file holding bytes into fresh objects.
func _load_profile(bytes: PackedByteArray) -> Array:
	F.write_bytes(_profile_path(), bytes)
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	_service.load_profile(settings, records)
	return [settings, records]


func _assert_profile_defaults(bytes: PackedByteArray, label: String) -> void:
	var loaded: Array = _load_profile(bytes)
	var settings: Settings = loaded[0]
	var records: Records = loaded[1]
	assert_true(settings.sound_on, "%s: sound default" % label)
	assert_eq(settings.skin_id, &"gumdrop", "%s: skin default" % label)
	assert_eq(F.text(records.best_score), "0", "%s: Best Score default" % label)
	assert_eq(records.best_tile, 0, "%s: Best Tile default" % label)
	assert_true(FileAccess.file_exists(_profile_path()), "%s: profile file kept" % label)


func _seeded_bytes(count: int, seed_value: int) -> PackedByteArray:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count)
	for index: int in count:
		bytes[index] = rng.randi_range(0, 255)
	return bytes


# Run file: not a run at all

func test_run_empty_and_blank_files() -> void:
	_assert_run_refused(PackedByteArray(), "empty file")
	_assert_run_text_refused("   \n\t ", "only whitespace")


func test_run_top_level_values_that_are_not_an_object() -> void:
	_assert_run_text_refused("null", "only null")
	_assert_run_text_refused("[]", "an empty array")
	_assert_run_text_refused("[%s]" % _control_text(), "an array holding a valid run")
	_assert_run_text_refused("\"run\"", "a string")
	_assert_run_text_refused("1", "a number")
	_assert_run_text_refused("true", "a bool")
	_assert_run_text_refused("{}", "an empty object")


func test_run_malformed_json() -> void:
	_assert_run_text_refused(_control_text() + "x", "trailing junk")
	_assert_run_text_refused(_control_text() + _control_text(), "two objects")
	_assert_run_text_refused("{\"format\": 1 /* comment */}", "a comment")
	_assert_run_text_refused("{'format': 1}", "single quotes")
	_assert_run_text_refused("{format: 1}", "a bare key")


func test_run_deeply_nested_json() -> void:
	_assert_run_text_refused("[".repeat(60000), "60,000 open brackets")
	_assert_run_text_refused("[".repeat(1000) + "]".repeat(1000), "1,000 levels, which the parser alone would accept")
	_assert_run_text_refused("{\"a\":".repeat(10000) + "1" + "}".repeat(10000), "10,000 nested objects")
	var data: Dictionary = _control_data()
	data["score"] = F.RAW
	_assert_run_text_refused(F.raw_text(data, "[".repeat(20) + "]".repeat(20)), "deep nesting inside one field")


func test_nesting_limit_is_16_before_parsing() -> void:
	# Godot's parser has its own limit near 1,024 levels. The service stops at
	# 16 so hostile nesting never reaches the recursive parser at all.
	var ok: String = "[".repeat(16) + "]".repeat(16)
	var deep: String = "[".repeat(17) + "]".repeat(17)
	assert_true(SaveService._nesting_within(ok.to_utf8_buffer(), 16), "16 levels pass")
	assert_false(SaveService._nesting_within(deep.to_utf8_buffer(), 16), "17 levels stop")
	assert_true(SaveService._nesting_within(("\"" + "[".repeat(100) + "\"").to_utf8_buffer(), 16), "brackets in a string do not count")
	assert_true(SaveService._nesting_within(("\"\\\"" + "{".repeat(100) + "\"").to_utf8_buffer(), 16), "an escaped quote does not end the string")
	assert_true(SaveService._nesting_within(("\"\\\\\"" + "[".repeat(16) + "]".repeat(16)).to_utf8_buffer(), 16), "an escaped backslash does end it")
	assert_false(SaveService._nesting_within(("\"\\\\\"" + "[".repeat(17)).to_utf8_buffer(), 16), "so brackets after it count")
	# Through a file: the profile root and settings are 2 levels, so a skin of
	# 14 nested arrays is 16 levels and only the skin is bad, while 15 nested
	# arrays is 17 levels and the whole file is refused.
	var data: Dictionary = _good_profile_data()
	(data["settings"] as Dictionary)["skin"] = F.RAW
	var loaded: Array = _load_profile(F.raw_text(data, "[".repeat(14) + "]".repeat(14)).to_utf8_buffer())
	assert_eq(F.text((loaded[1] as Records).best_score), "5000", "16 levels: the good parts are kept")
	assert_eq((loaded[0] as Settings).skin_id, &"gumdrop", "16 levels: the skin is refused")
	_assert_profile_defaults(F.raw_text(data, "[".repeat(15) + "]".repeat(15)).to_utf8_buffer(), "17 levels")


func test_profile_brackets_inside_strings_do_not_count_as_nesting() -> void:
	# A skin id full of brackets, after an escaped quote, is one bad field. If
	# the nesting check counted them, the whole profile would be refused.
	var data: Dictionary = _good_profile_data()
	(data["settings"] as Dictionary)["skin"] = "a\"" + "[{".repeat(40)
	var loaded: Array = _load_profile(F.to_text(data).to_utf8_buffer())
	assert_eq((loaded[0] as Settings).skin_id, &"gumdrop", "the skin is refused")
	assert_false((loaded[0] as Settings).sound_on, "sound kept")
	assert_eq(F.text((loaded[1] as Records).best_score), "5000", "Best Score kept")


# Run file: bad numbers

func test_run_huge_and_non_finite_numbers() -> void:
	for raw: String in ["1e400", "-1e400", "1e308", "99999999999999999999", "4611686018427387904", "65536", "NaN", "Infinity", "-Infinity", "1e-400"]:
		var data: Dictionary = _control_data()
		(data["cells"] as Array)[3] = F.RAW
		_assert_run_text_refused(F.raw_text(data, raw), "cell %s" % raw)
		var highest: Dictionary = _control_data()
		highest["run_highest"] = F.RAW
		_assert_run_text_refused(F.raw_text(highest, raw), "run_highest %s" % raw)
		if raw == "65536":
			continue    # a valid format, score or count would differ; cells and run_highest are the point
		var format: Dictionary = _control_data()
		format["format"] = F.RAW
		_assert_run_text_refused(F.raw_text(format, raw), "format %s" % raw)
		var score: Dictionary = _control_data()
		score["score"] = F.RAW
		_assert_run_text_refused(F.raw_text(score, raw), "score as a bare number %s" % raw)
		if raw != "1e-400":    # it parses as exactly 0.0, a valid count of 0
			var used: Dictionary = _control_data()
			used["free_used"] = F.RAW
			_assert_run_text_refused(F.raw_text(used, raw), "free_used %s" % raw)
		var best: Dictionary = _control_data()
		best["best_at_start"] = F.RAW
		_assert_run_text_refused(F.raw_text(best, raw), "best_at_start as a bare number %s" % raw)


func test_run_bad_free_used_through_a_file() -> void:
	# The control run earns no free booster (run highest 2048, 1 star).
	for raw: String in ["1", "2", "-1", "0.5", "1e-300", "\"0\"", "true", "null", "[0]", "{}"]:
		var data: Dictionary = _control_data()
		data["free_used"] = F.RAW
		_assert_run_text_refused(F.raw_text(data, raw), "free_used %s" % raw)


func test_run_negative_and_float_exponents() -> void:
	for raw: String in ["-1", "-62", "-0.5", "0.5", "1.5", "10.000000001", "62.5", "1e-300", "-0"]:
		var data: Dictionary = _control_data()
		(data["cells"] as Array)[3] = F.RAW
		_assert_run_text_refused(F.raw_text(data, raw), "cell exponent %s" % raw)
		var snapshot: Dictionary = _control_data()
		((snapshot["snapshot"] as Dictionary)["cells"] as Array)[3] = F.RAW
		_assert_run_text_refused(F.raw_text(snapshot, raw), "snapshot exponent %s" % raw)


func test_run_very_long_digit_strings() -> void:
	var ceiling: String = BigNum.pow2(_config.max_score_bits).to_decimal()
	for digits: String in ["1".repeat(19749), "9".repeat(19748), ceiling, "9".repeat(60000), "1".repeat(250000)]:
		var data: Dictionary = _control_data()
		data["score"] = digits
		_assert_run_text_refused(F.to_text(data), "score of %d digits" % digits.length())
		var best: Dictionary = _control_data()
		best["best_at_start"] = digits
		_assert_run_text_refused(F.to_text(best), "best_at_start of %d digits" % digits.length())
		var points: Dictionary = _control_data()
		(points["snapshot"] as Dictionary)["points"] = digits
		_assert_run_text_refused(F.to_text(points), "snapshot points of %d digits" % digits.length())


# Run file: keys and types

func test_run_extra_and_missing_keys() -> void:
	var extra: Dictionary = _control_data()
	extra["phase"] = "targeting"
	_assert_run_text_refused(F.to_text(extra), "extra key")
	for key: String in ["format", "columns", "rows", "cells", "score", "run_highest", "free_used", "best_at_start", "snapshot"]:
		var data: Dictionary = _control_data()
		data.erase(key)
		_assert_run_text_refused(F.to_text(data), "missing %s" % key)


func test_run_format_and_keys_that_do_not_match() -> void:
	var old_keys_new_format: Dictionary = F.format_1_data(F.control_run())
	old_keys_new_format["format"] = 2
	_assert_run_text_refused(F.to_text(old_keys_new_format), "format 2 with the format 1 keys")
	var new_keys_old_format: Dictionary = _control_data()
	new_keys_old_format["format"] = 1
	_assert_run_text_refused(F.to_text(new_keys_old_format), "format 1 with the format 2 keys")
	var future: Dictionary = _control_data()
	future["format"] = 3
	_assert_run_text_refused(F.to_text(future), "format 3")


func test_run_wrong_types_through_a_file() -> void:
	var wrong: Dictionary = {"format": "2", "columns": [5], "rows": {}, "cells": "1,2,3", "score": 41286,
		"run_highest": true, "free_used": "0", "best_at_start": 38500, "snapshot": "none"}
	for key: String in wrong:
		var data: Dictionary = _control_data()
		data[key] = wrong[key]
		_assert_run_text_refused(F.to_text(data), "%s of the wrong type" % key)


func test_run_duplicate_key_with_a_bad_last_value() -> void:
	# The parser keeps the last value of a repeated key; it is still checked.
	var text: String = _control_text().replace("\"score\": \"41286\"", "\"score\": \"41286\", \"score\": \"-1\"")
	assert_true(text.contains("\"-1\""), "the duplicate is in the text")
	_assert_run_text_refused(text, "duplicate score")


# Run file: bytes and size

func test_run_nul_after_valid_json_is_refused() -> void:
	# The UTF-8 decoder stops at a NUL, so without the NUL check this file
	# would load as the valid run in front of it.
	var bytes: PackedByteArray = _control_text().to_utf8_buffer()
	var prefix_size: int = bytes.size()
	bytes.append(0)
	bytes.append_array("garbage".to_utf8_buffer())
	assert_eq(bytes.get_string_from_utf8().length(), prefix_size, "the decoder alone would drop the tail")
	_assert_run_refused(bytes, "NUL then garbage")
	var middle: PackedByteArray = _control_text().to_utf8_buffer()
	middle[middle.find(32)] = 0
	_assert_run_refused(middle, "NUL in place of a space")


func test_run_binary_garbage() -> void:
	for seed_value: int in [1, 2, 3]:
		_assert_run_refused(_seeded_bytes(4096, seed_value), "random bytes, seed %d" % seed_value)
	_assert_run_refused(_seeded_bytes(65536, 4), "64 KB of random bytes")
	_assert_run_refused(_seeded_bytes(SaveService.MAX_BYTES, 7), "256 KB of random bytes")


func test_run_invalid_utf8_in_a_string() -> void:
	var data: Dictionary = _control_data()
	data["score"] = "@@"
	var bytes: PackedByteArray = F.to_text(data).to_utf8_buffer()
	var at: int = bytes.find(64)
	bytes[at] = 0xFF
	bytes[at + 1] = 0xFE
	_assert_run_refused(bytes, "invalid UTF-8 in the score")


func test_run_file_over_256_kb() -> void:
	_assert_run_text_refused(F.padded(_control_text(), 257 * 1024), "a valid run padded to 257 KB")
	_assert_run_refused(_seeded_bytes(257 * 1024, 5), "257 KB of random bytes")
	_assert_run_text_refused(F.padded(_control_text(), 1024 * 1024), "a valid run padded to 1 MB")


func test_run_256_kb_limit_is_exact() -> void:
	F.write_text(_run_path(), F.padded(_control_text(), 262144))
	assert_eq(F.read_bytes(_run_path()).size(), 262144, "exactly 256 KB")
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null and F.control_run().equals(loaded), "256 KB exactly is allowed")
	_assert_run_text_refused(F.padded(_control_text(), 262145), "one byte more is refused")
	F.write_text(_run_path(), F.padded(_control_text(), 65537))
	assert_true(_service.load_run(_config) != null, "65 KB, over the old 64 KB cap, now loads")


func test_run_file_that_is_a_folder() -> void:
	DirAccess.make_dir_absolute(_run_path())
	assert_true(_service.load_run(_config) == null, "no run")
	assert_false(_service.save_run(F.control_run()), "saving cannot replace a folder")
	assert_true(DirAccess.dir_exists_absolute(_run_path()), "the folder is left alone")


# Profile file

func test_profile_hostile_files_give_defaults() -> void:
	_assert_profile_defaults(PackedByteArray(), "empty file")
	_assert_profile_defaults("  \n ".to_utf8_buffer(), "only whitespace")
	_assert_profile_defaults("null".to_utf8_buffer(), "only null")
	_assert_profile_defaults("[]".to_utf8_buffer(), "a top level array")
	_assert_profile_defaults(("[%s]" % F.to_text(_good_profile_data())).to_utf8_buffer(), "an array holding a valid profile")
	_assert_profile_defaults("1".to_utf8_buffer(), "a number")
	_assert_profile_defaults("{\"format\": 1".to_utf8_buffer(), "cut off")
	_assert_profile_defaults("[".repeat(60000).to_utf8_buffer(), "60,000 open brackets")
	_assert_profile_defaults(("[".repeat(1000) + "]".repeat(1000)).to_utf8_buffer(), "1,000 levels")
	_assert_profile_defaults(F.padded(F.to_text(_good_profile_data()), 257 * 1024).to_utf8_buffer(), "a valid profile padded to 257 KB")
	_assert_profile_defaults(_seeded_bytes(4096, 6), "random bytes")
	var with_nul: PackedByteArray = F.to_text(_good_profile_data()).to_utf8_buffer()
	with_nul.append(0)
	with_nul.append_array("x".to_utf8_buffer())
	_assert_profile_defaults(with_nul, "NUL after a valid profile")
	var wrong_format: Dictionary = _good_profile_data()
	wrong_format["format"] = 2
	_assert_profile_defaults(F.to_text(wrong_format).to_utf8_buffer(), "format 2")


func test_profile_256_kb_limit_is_exact() -> void:
	var loaded: Array = _load_profile(F.padded(F.to_text(_good_profile_data()), 262144).to_utf8_buffer())
	assert_eq(F.text((loaded[1] as Records).best_score), "5000", "256 KB exactly is allowed")
	_assert_profile_defaults(F.padded(F.to_text(_good_profile_data()), 262145).to_utf8_buffer(), "one byte more")


func test_profile_unicode_skin_id_keeps_the_good_parts() -> void:
	# Written as a JSON escape, the file is plain ASCII: only the skin id is
	# refused and the rest of the profile is kept.
	var escaped_text: String = F.to_text(_good_profile_data()).replace("\"slate\"", "\"sl\\" + "u0430te\"")    # Cyrillic a
	var loaded: Array = _load_profile(escaped_text.to_utf8_buffer())
	var settings: Settings = loaded[0]
	var records: Records = loaded[1]
	assert_eq(settings.skin_id, &"gumdrop", "a JSON escape: default skin")
	assert_false(settings.sound_on, "a JSON escape: sound kept")
	assert_eq(F.text(records.best_score), "5000", "a JSON escape: Best Score kept")
	assert_eq(records.best_tile, 9, "a JSON escape: Best Tile kept")


func test_profile_with_non_ascii_bytes_is_refused_whole() -> void:
	# SEC-05: the game writes plain ASCII, so any byte of 0x80 or above makes
	# the whole file invalid before it is decoded, like a NUL byte.
	var raw: Dictionary = _good_profile_data()
	(raw["settings"] as Dictionary)["skin"] = "gumdr" + String.chr(0x00F6) + "p"
	var invalid_utf8: PackedByteArray = F.to_text(_good_profile_data()).to_utf8_buffer()
	var at: int = F.to_text(_good_profile_data()).find("slate")    # the text is ASCII, so this is a byte index
	invalid_utf8[at] = 0xC3
	invalid_utf8[at + 1] = 0x28    # a lead byte without its follow byte
	_assert_profile_defaults(F.to_text(raw).to_utf8_buffer(), "raw UTF-8")
	_assert_profile_defaults(invalid_utf8, "invalid UTF-8")
	_assert_profile_defaults(F.to_text(_good_profile_data()).replace("slate", String.chr(0x1F600)).to_utf8_buffer(), "an emoji")


func test_profile_bad_numbers_keep_the_good_parts() -> void:
	for raw: String in ["1e400", "NaN", "-1", "65536", "9.5", "99999999999999999999"]:

		var data: Dictionary = _good_profile_data()
		(data["records"] as Dictionary)["best_tile"] = F.RAW
		var bytes: PackedByteArray = F.raw_text(data, raw).to_utf8_buffer()
		var loaded: Array = _load_profile(bytes)
		var records: Records = loaded[1]
		var settings: Settings = loaded[0]
		if raw == "NaN":
			# NaN is not JSON, so the whole file is malformed.
			assert_eq(F.text(records.best_score), "0", "NaN: the file does not parse")
			continue
		assert_eq(records.best_tile, 0, "best_tile %s: default" % raw)
		assert_eq(F.text(records.best_score), "5000", "best_tile %s: Best Score kept" % raw)
		assert_eq(settings.skin_id, &"slate", "best_tile %s: skin kept" % raw)
