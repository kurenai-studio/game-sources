extends "res://tests/base_test.gd"
## SaveCodec, profile half (docs/ARCHITECTURE.md section 10, GDD 15.1).
## A profile with a bad part keeps its good parts: each of the four fields is
## checked on its own.

const F := preload("res://tests/save/save_fixtures.gd")
const INT64_MAX: int = 9223372036854775807

var _settings: Settings = Settings.new()
var _records: Records = Records.new()
var _sound_events: Array[bool] = []
var _skin_events: Array[StringName] = []


func before_each() -> void:
	_settings = Settings.new()
	_records = Records.new()
	_sound_events = []
	_skin_events = []
	# Method callables, not lambdas: a lambda would hold this test alive
	# through _settings and leak it.
	_settings.sound_changed.connect(_on_sound)
	_settings.skin_changed.connect(_on_skin)


func _on_sound(on: bool) -> void:
	_sound_events.append(on)


func _on_skin(skin_id: StringName) -> void:
	_skin_events.append(skin_id)


## A valid profile as parsed file data: sound off, Slate, Best Score 96,520,
## Best Tile 4096. A fresh copy every call.
func _good_data() -> Dictionary:
	return JSON.parse_string(F.to_text({
		"format": 1,
		"settings": {"sound_on": false, "skin": "slate"},
		"records": {"best_score": "96520", "best_tile": 12},
	}))


func _apply(data: Variant) -> PackedStringArray:
	return SaveCodec.data_to_profile(data, _settings, _records)


func _assert_defaults(message: String) -> void:
	assert_true(_settings.sound_on, "%s: sound default" % message)
	assert_eq(_settings.skin_id, &"gumdrop", "%s: skin default" % message)
	assert_eq(F.text(_records.best_score), "0", "%s: best score default" % message)
	assert_eq(_records.best_tile, 0, "%s: best tile default" % message)


func _assert_good_values(message: String) -> void:
	assert_false(_settings.sound_on, "%s: sound kept" % message)
	assert_eq(_settings.skin_id, &"slate", "%s: skin kept" % message)
	assert_eq(F.text(_records.best_score), "96520", "%s: best score kept" % message)
	assert_eq(_records.best_tile, 12, "%s: best tile kept" % message)


# Writing and round trips

func test_profile_to_data_uses_the_documented_format() -> void:
	var settings: Settings = Settings.new()
	settings.set_sound_on(false)
	settings.set_skin_id(&"nova")
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(96520)
	records.best_tile = 12
	var data: Dictionary = SaveCodec.profile_to_data(settings, records)
	assert_eq(data.keys(), ["format", "settings", "records"], "top level keys")
	assert_eq(data["format"], 1, "format")
	assert_eq(data["settings"], {"sound_on": false, "skin": "nova"}, "settings")
	assert_eq(data["records"], {"best_score": "96520", "best_tile": 12}, "records")


func test_profile_to_data_writes_best_tile_0_for_no_tile() -> void:
	var data: Dictionary = SaveCodec.profile_to_data(Settings.new(), Records.new())
	assert_eq(data["records"], {"best_score": "0", "best_tile": 0}, "fresh records")
	assert_eq(data["settings"], {"sound_on": true, "skin": "gumdrop"}, "fresh settings")


func test_round_trip_profile() -> void:
	var problems: PackedStringArray = _apply(_good_data())
	assert_eq(problems.size(), 0, "a valid profile has no problems: %s" % ", ".join(problems))
	_assert_good_values("loaded")
	var again: Dictionary = JSON.parse_string(F.to_text(SaveCodec.profile_to_data(_settings, _records)))
	assert_eq(again, _good_data(), "writes back the same data")


func test_round_trip_profile_extremes() -> void:
	var records: Records = Records.new()
	var config: GameConfig = GameConfig.new()
	var top: BigNum = F.pow2_plus(config.max_score_bits, -1)
	records.best_score = top
	records.best_tile = config.max_exponent
	var data: Variant = JSON.parse_string(F.to_text(SaveCodec.profile_to_data(Settings.new(), records)))
	assert_eq(_apply(data).size(), 0, "valid at the ceiling (AT-169 (g))")
	assert_true(_records.best_score.equals(top), "Best Score 2^65600 minus 1 exactly")
	assert_eq(_records.best_tile, 65535, "Best Tile 2^65535")
	before_each()
	records.best_score = BigNum.from_int(INT64_MAX).add(BigNum.from_int(1))
	records.best_tile = 63
	_apply(JSON.parse_string(F.to_text(SaveCodec.profile_to_data(Settings.new(), records))))
	assert_eq(F.text(_records.best_score), "9223372036854775808", "Best Score 2^63, past the old limit")
	assert_eq(_records.best_tile, 63, "Best Tile 2^63, past the old limit")


func test_documented_example_loads() -> void:
	# Written by hand from docs/ARCHITECTURE.md section 10.
	var text: String = "{\"format\": 1, \"settings\": {\"sound_on\": true, \"skin\": \"gumdrop\"}, \"records\": {\"best_score\": \"96520\", \"best_tile\": 12}}"
	var problems: PackedStringArray = _apply(JSON.parse_string(text))
	assert_eq(problems.size(), 0, "no problems")
	assert_true(_settings.sound_on, "sound on")
	assert_eq(_settings.skin_id, &"gumdrop", "skin")
	assert_eq(F.text(_records.best_score), "96520", "Best Score")
	assert_eq(_records.best_tile, 12, "Best Tile")


# Whole profile refused

func test_non_object_applies_nothing() -> void:
	for value: Variant in [null, [], ["format", 1], "profile", 1, 1.0, true, PackedStringArray(["a"])]:
		var problems: PackedStringArray = _apply(value)
		assert_false(problems.is_empty(), "a problem for %s" % type_string(typeof(value)))
		_assert_defaults(type_string(typeof(value)))


func test_format_must_be_1() -> void:
	for value: Variant in [0, 2, -1, 1.5, "1", true, null, [], {}, INF, NAN]:
		var data: Dictionary = _good_data()
		data["format"] = value
		assert_false(_apply(data).is_empty(), "format %s reported" % str(value))
		_assert_defaults("format %s" % str(value))
	var missing: Dictionary = _good_data()
	missing.erase("format")
	assert_false(_apply(missing).is_empty(), "missing format reported")
	_assert_defaults("missing format")


# A bad part keeps the good parts

func test_bad_skin_keeps_the_other_parts() -> void:
	var data: Dictionary = _good_data()
	(data["settings"] as Dictionary)["skin"] = "Slate!"
	var problems: PackedStringArray = _apply(data)
	assert_eq(problems.size(), 1, "one problem")
	assert_false(_settings.sound_on, "sound kept")
	assert_eq(_settings.skin_id, &"gumdrop", "skin falls back to the default")
	assert_eq(F.text(_records.best_score), "96520", "Best Score kept")
	assert_eq(_records.best_tile, 12, "Best Tile kept")


func test_bad_sound_keeps_the_other_parts() -> void:
	for value: Variant in ["true", 1, 0, 1.0, null, [], {}]:
		before_each()
		var data: Dictionary = _good_data()
		(data["settings"] as Dictionary)["sound_on"] = value
		assert_eq(_apply(data).size(), 1, "one problem for %s" % str(value))
		assert_true(_settings.sound_on, "sound falls back to on for %s" % str(value))
		assert_eq(_settings.skin_id, &"slate", "skin kept")
		assert_eq(F.text(_records.best_score), "96520", "Best Score kept")
		assert_eq(_records.best_tile, 12, "Best Tile kept")


func test_bad_best_score_keeps_the_other_parts() -> void:
	var config: GameConfig = GameConfig.new()
	var at_ceiling: String = BigNum.pow2(config.max_score_bits).to_decimal()
	for value: Variant in ["-1", "007", "12a", "", at_ceiling, "1".repeat(19749), 96520, 96520.0, null, true, []]:
		before_each()
		var data: Dictionary = _good_data()
		(data["records"] as Dictionary)["best_score"] = value
		assert_eq(_apply(data).size(), 1, "one problem for %s" % str(value).left(30))
		assert_eq(F.text(_records.best_score), "0", "Best Score falls back to 0 for %s" % str(value).left(30))
		assert_eq(_records.best_tile, 12, "Best Tile kept")
		assert_false(_settings.sound_on, "sound kept")
		assert_eq(_settings.skin_id, &"slate", "skin kept")


func test_bad_best_tile_keeps_the_other_parts() -> void:
	for value: Variant in [65536, 65537, -1, 1.5, INF, NAN, 1e20, "12", true, null, [], {}]:
		before_each()
		var data: Dictionary = _good_data()
		(data["records"] as Dictionary)["best_tile"] = value
		assert_eq(_apply(data).size(), 1, "one problem for %s" % str(value))
		assert_eq(_records.best_tile, 0, "Best Tile falls back to 0 for %s" % str(value))
		assert_eq(F.text(_records.best_score), "96520", "Best Score kept")
		assert_false(_settings.sound_on, "sound kept")


func test_best_tile_range() -> void:
	for exponent: int in [0, 1, 9, 17, 56, 62, 63, 64, 1000, 65535]:
		before_each()
		var data: Dictionary = _good_data()
		(data["records"] as Dictionary)["best_tile"] = exponent
		assert_eq(_apply(data).size(), 0, "exponent %d is valid" % exponent)
		assert_eq(_records.best_tile, exponent, "exponent %d" % exponent)



func test_missing_or_wrong_typed_settings_keeps_records() -> void:
	for value: Variant in [null, [], "settings", 1, true]:
		before_each()
		var data: Dictionary = _good_data()
		data["settings"] = value
		assert_false(_apply(data).is_empty(), "reported for %s" % str(value))
		assert_true(_settings.sound_on, "sound default")
		assert_eq(_settings.skin_id, &"gumdrop", "skin default")
		assert_eq(F.text(_records.best_score), "96520", "Best Score kept")
		assert_eq(_records.best_tile, 12, "Best Tile kept")
	before_each()
	var missing: Dictionary = _good_data()
	missing.erase("settings")
	assert_false(_apply(missing).is_empty(), "missing settings reported")
	assert_eq(F.text(_records.best_score), "96520", "Best Score kept without settings")


func test_missing_or_wrong_typed_records_keeps_settings() -> void:
	for value: Variant in [null, [], "records", 1, true]:
		before_each()
		var data: Dictionary = _good_data()
		data["records"] = value
		assert_false(_apply(data).is_empty(), "reported for %s" % str(value))
		assert_eq(F.text(_records.best_score), "0", "Best Score default")
		assert_eq(_records.best_tile, 0, "Best Tile default")
		assert_false(_settings.sound_on, "sound kept")
		assert_eq(_settings.skin_id, &"slate", "skin kept")


func test_missing_single_fields_keep_the_rest() -> void:
	var data: Dictionary = _good_data()
	(data["settings"] as Dictionary).erase("skin")
	(data["records"] as Dictionary).erase("best_tile")
	assert_eq(_apply(data).size(), 2, "two problems")
	assert_false(_settings.sound_on, "sound kept")
	assert_eq(_settings.skin_id, &"gumdrop", "skin default")
	assert_eq(F.text(_records.best_score), "96520", "Best Score kept")
	assert_eq(_records.best_tile, 0, "Best Tile default")


func test_unknown_keys_are_reported_and_never_read() -> void:
	var data: Dictionary = _good_data()
	data["cloud"] = {"token": "x"}
	(data["settings"] as Dictionary)["volume"] = 5
	(data["records"] as Dictionary)["best_tile_cheat"] = 62
	var problems: PackedStringArray = _apply(data)
	assert_eq(problems.size(), 3, "one problem per object with an unknown key")
	_assert_good_values("known fields")


# Field rules

func test_skin_id_rules() -> void:
	var good: Array[String] = ["gumdrop", "slate", "nova", "a", "_", "my_skin", "a".repeat(32)]
	for skin: String in good:
		before_each()
		var data: Dictionary = _good_data()
		(data["settings"] as Dictionary)["skin"] = skin
		assert_eq(_apply(data).size(), 0, "\"%s\" is a valid id" % skin)
		assert_eq(_settings.skin_id, StringName(skin), "\"%s\" applied" % skin)
	var bad: Array = ["", "a".repeat(33), "a".repeat(10000), "Gumdrop", "GUMDROP", "gum drop", "gum-drop", "gumdrop2", "2", "gum.drop",
		"../gumdrop", "res://gumdrop", "gumdrop\n", " gumdrop", "\tgumdrop",
		"gumdr" + String.chr(0x00F6) + "p",            # o with diaeresis
		"gumdr" + String.chr(0x043E) + "p",            # Cyrillic o that looks like a Latin o
		String.chr(0xFF47) + "umdrop",                 # full width g
		"gumdrop" + String.chr(0x200B),                # zero width space
		"gumdrop" + String.chr(0x1F600),               # emoji outside the basic plane
		5, 1.0, true, null, [], {}, ["gumdrop"]]
	for skin: Variant in bad:
		before_each()
		var data: Dictionary = _good_data()
		(data["settings"] as Dictionary)["skin"] = skin
		assert_eq(_apply(data).size(), 1, "\"%s\" refused" % str(skin).left(40))
		assert_eq(_settings.skin_id, &"gumdrop", "\"%s\" leaves the default" % str(skin).left(40))
		assert_false(_settings.sound_on, "sound still kept")


func test_unicode_skin_id_from_json_escape_is_refused() -> void:
	# The JSON text spells the o with diaeresis as a backslash u 00f6 escape.
	var text: String = F.to_text(_good_data()).replace("\"slate\"", "\"gumdr\\" + "u00f6p\"")
	assert_true(text.contains("\\u00f6"), "the escape is in the text")
	var data: Variant = JSON.parse_string(text)
	assert_eq(typeof(data), TYPE_DICTIONARY, "parses")
	assert_eq(_apply(data).size(), 1, "one problem")
	assert_eq(_settings.skin_id, &"gumdrop", "default skin")
	assert_eq(F.text(_records.best_score), "96520", "Best Score kept")


# Applying

func test_invalid_parts_keep_values_already_held() -> void:
	_settings.set_sound_on(false)
	_settings.set_skin_id(&"nova")
	_records.best_score = BigNum.from_int(7)
	_records.best_tile = 3
	_apply({"format": 1, "settings": {}, "records": {}})
	assert_false(_settings.sound_on, "sound untouched")
	assert_eq(_settings.skin_id, &"nova", "skin untouched")
	assert_eq(F.text(_records.best_score), "7", "Best Score untouched")
	assert_eq(_records.best_tile, 3, "Best Tile untouched")


func test_settings_signals_fire_only_for_real_changes() -> void:
	_apply(_good_data())
	assert_eq(_sound_events, [false] as Array[bool], "sound changed once")
	assert_eq(_skin_events, [&"slate"] as Array[StringName], "skin changed once")
	_apply(_good_data())
	assert_eq(_sound_events.size(), 1, "loading the same values again emits nothing")
	assert_eq(_skin_events.size(), 1, "same for the skin")


func test_null_objects_do_not_crash() -> void:
	var problems: PackedStringArray = SaveCodec.data_to_profile(_good_data(), null, null)
	assert_eq(problems.size(), 0, "valid data, nothing to apply it to")
	var data: Dictionary = SaveCodec.profile_to_data(null, null)
	assert_eq(data["records"], {"best_score": "0", "best_tile": 0}, "null objects write defaults")
