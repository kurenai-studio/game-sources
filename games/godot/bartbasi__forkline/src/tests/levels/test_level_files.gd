# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Every level file and campaign.json loads and passes the sim's checks with the real
## Catalog (docs/ARCHITECTURE.md 2.4, 2.5, 2.12).

const Files: GDScript = preload("res://tests/levels/fixtures/level_files.gd")

const LEVEL_CAP_BYTES: int = 64 * 1024
const CAMPAIGN_CAP_BYTES: int = 16 * 1024
## Regions 1 to 8 in play order (RULES 12.2, 12.3).
const PLAY_ORDER: Array = [
	["lantern_hill", ["r1_l1", "r1_l2", "r1_l3", "r1_l4", "r1_l5", "r1_l6"]],
	["millbrook", ["r2_l1", "r2_l2", "r2_l3", "r2_l4", "r2_l5", "r2_l6"]],
	["willow_fen", ["r3_l1", "r3_l2", "r3_l3", "r3_l4", "r3_l5", "r3_l6"]],
	["moonspire_keep", ["r4_l1", "r4_l2", "r4_l3", "r4_l4", "r4_l5", "r4_l6"]],
	["hollow_lanes", ["r5_l1", "r5_l2", "r5_l3", "r5_l4", "r5_l5", "r5_l6"]],
	["russet_orchards", ["r6_l1", "r6_l2", "r6_l3", "r6_l4", "r6_l5", "r6_l6"]],
	["frostpine_ridge", ["r7_l1", "r7_l2", "r7_l3", "r7_l4", "r7_l5", "r7_l6"]],
	["starglen", ["r8_l1", "r8_l2", "r8_l3", "r8_l4", "r8_l5", "r8_l6"]],
]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Files.catalog()


func test_stats_load_with_no_problems() -> void:
	var files: Array = Files.stats_files()
	assert_eq(Catalog.check(files[0], files[1], files[2]), PackedStringArray(), "data/stats/ problems")
	assert_not_null(catalog)


func test_there_are_level_files() -> void:
	assert_eq(Files.level_file_ids().size(), 48, "level files in data/levels/")


func test_game_data_loads_every_file_with_no_problems() -> void:
	var game: GameData = GameData.load_from()
	assert_eq(game.problems, PackedStringArray(), "GameData problems")
	assert_eq(game.levels.size(), Files.level_file_ids().size(), "GameData loads every level file")


func test_every_level_passes_level_data_check() -> void:
	for id: String in Files.level_file_ids():
		var data: Variant = Files.level_data(id)
		assert_true(data is Dictionary, "%s.json parses to an object" % id)
		assert_eq(LevelData.check(data, catalog), PackedStringArray(), "%s.json problems" % id)
		assert_not_null(LevelData.from_data(data, catalog), "%s loads" % id)


func test_level_id_equals_file_name() -> void:
	for id: String in Files.level_file_ids():
		var data: Variant = Files.level_data(id)
		if not (data is Dictionary):
			fail("%s.json is not an object" % id)
			continue
		assert_eq(str(data.get("id", "")), id, "%s.json id" % id)
		var level: LevelData = LevelData.from_data(data, catalog)
		if level != null:
			assert_eq(level.id, StringName(id), "%s loaded id" % id)


func test_level_round_trips_through_to_data() -> void:
	for id: String in Files.level_file_ids():
		var level: LevelData = Files.level(id, catalog)
		if level == null:
			fail("%s does not load" % id)
			continue
		var again: LevelData = LevelData.from_data(level.to_data(), catalog)
		assert_not_null(again, "%s reloads from to_data()" % id)
		if again != null:
			assert_eq(JSON.stringify(again.to_data()), JSON.stringify(level.to_data()), "%s round trip" % id)


func test_files_are_ascii_and_under_size_caps() -> void:
	var paths: Dictionary = {Files.LEVELS_DIR + Files.CAMPAIGN_FILE: CAMPAIGN_CAP_BYTES}
	for id: String in Files.level_file_ids():
		paths[Files.level_path(id)] = LEVEL_CAP_BYTES
	for path: String in paths:
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		assert_true(bytes.size() > 0, "%s is not empty" % path)
		assert_true(bytes.size() <= int(paths[path]), "%s is under its size cap" % path)
		var high: int = 0
		for b: int in bytes:
			if b >= 0x80 or b == 0:
				high += 1
		assert_eq(high, 0, "%s bytes outside plain ASCII" % path)


func test_campaign_has_the_contract_shape() -> void:
	var data: Variant = Files.campaign()
	assert_true(data is Dictionary, "campaign.json parses to an object")
	if not (data is Dictionary):
		return
	var keys: Array = (data as Dictionary).keys()
	keys.sort()
	assert_eq(keys, ["format", "regions"], "campaign.json keys")
	assert_eq(data.get("format"), 1, "campaign.json format")
	assert_true(data.get("regions") is Array, "campaign.json regions is an array")
	if not (data.get("regions") is Array):
		return
	var region_ids: Array[String] = []
	for region: Variant in data["regions"]:
		assert_true(region is Dictionary, "a region is an object")
		if not (region is Dictionary):
			continue
		var region_keys: Array = (region as Dictionary).keys()
		region_keys.sort()
		assert_eq(region_keys, ["id", "levels", "name"], "region keys")
		var region_id: String = str(region.get("id", ""))
		assert_true(_is_id(region_id), "region id format: %s" % region_id)
		assert_false(region_ids.has(region_id), "region id repeated: %s" % region_id)
		region_ids.append(region_id)
		var region_name: Variant = region.get("name")
		assert_true(region_name is String and _is_text(region_name, 24), "region %s name is 1 to 24 printable characters" % region_id)
		assert_true(region.get("levels") is Array and (region["levels"] as Array).size() > 0, "region %s has levels" % region_id)


func test_campaign_lists_every_level_file_exactly_once() -> void:
	var listed: PackedStringArray = Files.campaign_order()
	var files: PackedStringArray = Files.level_file_ids()
	for id: String in listed:
		assert_true(files.has(id), "campaign.json lists %s, which has a file" % id)
		assert_eq(listed.count(id), 1, "campaign.json lists %s once" % id)
	for id: String in files:
		assert_true(listed.has(id), "%s.json is listed in campaign.json" % id)


func test_campaign_play_order_is_pinned() -> void:
	var data: Variant = Files.campaign()
	if not (data is Dictionary) or not (data.get("regions") is Array):
		fail("campaign.json has no regions")
		return
	var regions: Array = data["regions"]
	assert_eq(regions.size(), PLAY_ORDER.size(), "region count")
	for i: int in mini(regions.size(), PLAY_ORDER.size()):
		var expected: Array = PLAY_ORDER[i]
		assert_eq(str(regions[i].get("id", "")), expected[0], "region %d id" % (i + 1))
		assert_eq(regions[i].get("levels"), expected[1], "region %s level order" % expected[0])


func _is_id(text: String) -> bool:
	if text.length() < 1 or text.length() > 32:
		return false
	var first: int = text.unicode_at(0)
	if first < 97 or first > 122:
		return false
	for i: int in text.length():
		var c: int = text.unicode_at(i)
		var ok: bool = (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95
		if not ok:
			return false
	return true


func _is_text(text: String, max_length: int) -> bool:
	if text.length() < 1 or text.length() > max_length:
		return false
	for i: int in text.length():
		var c: int = text.unicode_at(i)
		if c < 32 or c > 126:
			return false
	return true
