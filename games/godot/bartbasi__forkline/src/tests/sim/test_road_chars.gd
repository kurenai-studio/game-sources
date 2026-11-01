# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## One list of road characters (docs/ARCHITECTURE.md 14.2): LevelData.ROAD_CHARS,
## MapArt.ROAD_CHARS and RunSegments.ROAD_CHARS hold the same characters, and kind_at()
## gives a road kind (ROAD, SOCKET, ENTRANCE or BASE) for exactly those characters.


## A one row map holding ch in its first cell, read unchecked: only kind_at matters here.
func _kind_of(ch: String) -> LevelData.Kind:
	var level: LevelData = LevelData.new()
	level.grid = PackedStringArray([ch + "......"])
	level.rows = 1
	return level.kind_at(Vector2i(0, 0))


func test_the_three_lists_hold_the_same_characters_contract_14_2() -> void:
	assert_eq(LevelData.ROAD_CHARS, "#G1234BTX^v<>PQ")
	assert_eq(MapArt.ROAD_CHARS, LevelData.ROAD_CHARS, "MapArt")
	assert_eq(RunSegments.ROAD_CHARS, LevelData.ROAD_CHARS, "RunSegments")
	for i: int in LevelData.ROAD_CHARS.length():
		var ch: String = LevelData.ROAD_CHARS[i]
		assert_eq(LevelData.ROAD_CHARS.count(ch), 1, "%s once" % ch)
		assert_true(LevelData.GRID_CHARS.contains(ch), "%s is a grid character" % ch)


func test_kind_at_gives_a_road_kind_exactly_for_the_road_characters_contract_14_2() -> void:
	var road_kinds: Array[LevelData.Kind] = [LevelData.Kind.ROAD, LevelData.Kind.SOCKET, LevelData.Kind.ENTRANCE, LevelData.Kind.BASE]
	# Every printable ASCII character, so a character added to one list and not the
	# other, or to kind_at alone, is caught.
	for code: int in range(32, 127):
		var ch: String = String.chr(code)
		var kind: LevelData.Kind = _kind_of(ch)
		assert_eq(road_kinds.has(kind), LevelData.ROAD_CHARS.contains(ch), "kind_at of '%s'" % ch)
	# The two grid characters that are not road: scenery and a build spot.
	assert_eq(_kind_of("."), LevelData.Kind.SCENERY)
	assert_eq(_kind_of("o"), LevelData.Kind.SPOT)
	for i: int in LevelData.GRID_CHARS.length():
		var ch: String = LevelData.GRID_CHARS[i]
		assert_eq(LevelData.ROAD_CHARS.contains(ch), ch != "." and ch != "o", "%s" % ch)


func test_each_road_character_has_its_kind() -> void:
	var want: Dictionary = {
		"#": LevelData.Kind.ROAD, "G": LevelData.Kind.SOCKET, "B": LevelData.Kind.BASE,
		"1": LevelData.Kind.ENTRANCE, "2": LevelData.Kind.ENTRANCE, "3": LevelData.Kind.ENTRANCE, "4": LevelData.Kind.ENTRANCE,
	}
	for ch: String in "TX^v<>PQ":
		want[ch] = LevelData.Kind.ROAD
	assert_eq(want.size(), LevelData.ROAD_CHARS.length())
	for ch: String in want:
		assert_eq(_kind_of(ch), want[ch], ch)
