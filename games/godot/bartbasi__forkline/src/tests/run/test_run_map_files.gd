# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## RunData: index.json, segments and wave packs, good and hostile (docs/ARCHITECTURE.md 2.9).

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


## Breaks one thing in a copy of the fixtures and expects a problem naming it.
func _expect(label: String, mutate: Callable, needle: String) -> void:
	var files: Dictionary = Fx.files_from_json()
	mutate.call(files)
	var found: PackedStringArray = RunData.check(files, catalog)
	assert_true(found.size() > 0, "%s: no problem found" % label)
	assert_true("\n".join(found).contains(needle), "%s: expected '%s' in:\n%s" % [label, needle, "\n".join(found)])
	assert_null(RunData.from_data(files, catalog), "%s: from_data must refuse" % label)


func _seg(files: Dictionary, id: String) -> Dictionary:
	return files["segments/%s.json" % id]


func _pack(files: Dictionary, id: String) -> Dictionary:
	for item: Variant in files["segments/packs.json"]["packs"]:
		if (item as Dictionary)["id"] == id:
			return item
	return {}


func _groups(files: Dictionary, pack_id: String, wave: int) -> Array:
	return _pack(files, pack_id)["waves"][wave]["groups"]


# ---- good data and accessors ----

func test_segments_are_read_with_their_ports() -> void:
	var data: RunData = Fx.run_data()
	assert_eq(data.segment_ids.size(), 10)
	assert_eq(data.segment_ids[0], &"top_one", "index order")
	var top: Dictionary = data.segment(&"top_one")
	assert_eq(top["kind"], &"top")
	assert_eq(top["bottom_ports"], [3])
	assert_eq(top["top_ports"], [])
	assert_eq(top["spots"], 4)
	var merge: Dictionary = data.segment(&"mid_merge")
	assert_eq(merge["top_ports"], [1, 5])
	assert_eq(merge["bottom_ports"], [3])
	assert_eq(merge["sockets"], 2)
	var home: Dictionary = data.segment(&"bot_home")
	assert_eq(home["bottom_ports"], [])
	assert_eq(home["grid"].size(), 4)
	assert_eq(data.segment(&"nothing"), {})


func test_segments_come_back_by_kind_in_index_order() -> void:
	var data: RunData = Fx.run_data()
	var tops: Array[Dictionary] = data.segments_of(&"top")
	var ids: Array = []
	for item: Dictionary in tops:
		ids.append(item["id"])
	assert_eq(ids, [&"top_one", &"top_pair", &"top_side", &"top_twin"])
	assert_eq(data.segments_of(&"middle").size(), 4)
	assert_eq(data.segments_of(&"bottom").size(), 2)
	assert_eq(data.segments_of(&"other").size(), 0)


func test_fitting_means_equal_port_sets() -> void:
	var data: RunData = Fx.run_data()
	var under_one: Array = _ids(data.segments_under(&"top_one"))
	assert_eq(under_one, [&"mid_split", &"mid_bend"])
	assert_eq(_ids(data.segments_under(&"top_pair")), [&"mid_split", &"mid_bend"])
	assert_eq(_ids(data.segments_under(&"top_side")), [&"mid_side"])
	assert_eq(_ids(data.segments_under(&"top_twin")), [&"mid_merge"])
	assert_eq(_ids(data.segments_under(&"mid_split")), [&"bot_home"])
	assert_eq(_ids(data.segments_under(&"mid_bend")), [&"bot_edge"])
	assert_eq(_ids(data.segments_under(&"mid_side")), [&"bot_home"])
	assert_eq(_ids(data.segments_under(&"bot_home")), [])
	assert_eq(_ids(data.segments_under(&"nothing")), [])


func _ids(list: Array[Dictionary]) -> Array:
	var out: Array = []
	for item: Dictionary in list:
		out.append(item["id"])
	return out


func test_packs_come_back_by_band_and_boss() -> void:
	var data: RunData = Fx.run_data()
	assert_eq(data.packs.size(), 4 * 5 + 6)
	assert_eq(data.packs_of(1).size(), 4)
	assert_eq(data.packs_of(1)[0]["id"], &"band1_pack0", "packs.json order")
	assert_eq(data.packs_of(6).size(), 6)
	assert_eq(_ids(data.packs_of(6, &"ironshell")), [&"band6_pack1", &"band6_pack5"])
	assert_eq(data.packs_of(7).size(), 0)
	assert_eq(data.boss_ids(), [&"grumblesack", &"ironshell", &"moon_moth", &"old_tusk"], "enemies.json order")


func test_a_pack_keeps_its_groups_in_the_file_units() -> void:
	var data: RunData = Fx.run_data()
	var pack: Dictionary = data.packs_of(1)[0]
	var group: Dictionary = pack["waves"][0]["groups"][0]
	assert_eq(group["enemy"], "scamp")
	assert_eq(typeof(group["count"]), TYPE_INT)
	assert_eq(group["entrance"], 1)
	assert_eq(group["at_ms"], 0)
	assert_eq(pack["waves"].size(), 3)


# ---- index.json ----

func test_index_hostile() -> void:
	_expect("file missing", func(f: Dictionary) -> void: f.erase("segments/index.json"), "index.json: is missing")
	_expect("not an object", func(f: Dictionary) -> void: f["segments/index.json"] = [], "index.json")
	_expect("format", func(f: Dictionary) -> void: f["segments/index.json"]["format"] = 2, "index.json: format")
	_expect("extra key", func(f: Dictionary) -> void: f["segments/index.json"]["more"] = 1, "unknown key more")
	_expect("empty list", func(f: Dictionary) -> void: f["segments/index.json"]["segments"] = [], "index.json: segments")
	_expect("not a list", func(f: Dictionary) -> void: f["segments/index.json"]["segments"] = "top_one", "must be an array")
	_expect("repeated id", func(f: Dictionary) -> void: f["segments/index.json"]["segments"].append("top_one"), "repeats top_one")
	_expect("bad id", func(f: Dictionary) -> void: f["segments/index.json"]["segments"].append("Top One"), "must be an id")
	_expect("number as id", func(f: Dictionary) -> void: f["segments/index.json"]["segments"].append(7), "must be an id")
	_expect("257 ids", func(f: Dictionary) -> void: _long_index(f), "1 to 256")
	_expect("listed file missing", func(f: Dictionary) -> void: f.erase("segments/top_one.json"), "top_one.json: is missing")
	_expect("file not listed", func(f: Dictionary) -> void: f["segments/stray.json"] = Fx.segment("top_one"), "unexpected entry segments/stray.json")
	_expect("odd key", func(f: Dictionary) -> void: f[5] = 1, "unexpected entry 5")
	_expect("no tops", func(f: Dictionary) -> void: _keep_only(f, ["mid_split", "bot_home"]), "need at least one top")
	_expect("no middles", func(f: Dictionary) -> void: _keep_only(f, ["top_one", "bot_home"]), "need at least one top")
	_expect("no bottoms", func(f: Dictionary) -> void: _keep_only(f, ["top_one", "mid_split"]), "need at least one top")


func _long_index(files: Dictionary) -> void:
	var list: Array = []
	for i: int in 257:
		list.append("seg_%d" % i)
	files["segments/index.json"]["segments"] = list


func _keep_only(files: Dictionary, ids: Array) -> void:
	files["segments/index.json"]["segments"] = ids
	for id: String in Fx.INDEX_ORDER:
		if not ids.has(id):
			files.erase("segments/%s.json" % id)


# ---- segments ----

func test_segments_hostile() -> void:
	_expect("not an object", func(f: Dictionary) -> void: f["segments/top_one.json"] = 5, "top_one.json")
	_expect("format", func(f: Dictionary) -> void: _seg(f, "top_one")["format"] = 2, "top_one.json: format")
	_expect("extra key", func(f: Dictionary) -> void: _seg(f, "top_one")["note"] = "x", "unknown key note")
	_expect("missing grid", func(f: Dictionary) -> void: _seg(f, "top_one").erase("grid"), "grid: is missing")
	_expect("id differs from the file name", func(f: Dictionary) -> void: _seg(f, "top_one")["id"] = "top_two", "must equal the file name")
	_expect("bad kind", func(f: Dictionary) -> void: _seg(f, "top_one")["kind"] = "side", "top, middle or bottom")
	_expect("kind not text", func(f: Dictionary) -> void: _seg(f, "top_one")["kind"] = 3, "top, middle or bottom")
	_expect("too few rows", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"].pop_back(), "grid")
	_expect("too many rows", func(f: Dictionary) -> void: _seg(f, "mid_split")["grid"].append("......."), "grid")
	_expect("row of 6", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][1] = ".o.#.o", "grid[1]")
	_expect("row of 8", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][1] = ".o.#.o..", "grid[1]")
	_expect("row not text", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][1] = 5, "grid[1]")
	_expect("unknown character", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][1] = ".o.#.x.", "unknown character")
	_expect("grid not a list", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"] = "abc", "must be an array")
	_expect("top without an entrance", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][0] = "o.....o", "holds entrance 1")
	_expect("top with entrance 3", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][0] = "o..3..o", "holds entrance 1")
	_expect("top with entrance 2 only", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][0] = "o..2..o", "holds entrance 1")
	_expect("top with entrance 1 twice", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][0] = "o.1.1.o", "holds entrance 1")
	_expect("entrance inside the map", func(f: Dictionary) -> void: _entrance_inside(f), "top row or column 0 or 6")
	_expect("middle with an entrance", func(f: Dictionary) -> void: _seg(f, "mid_split")["grid"][0] = "o.1#..o", "only a top segment")
	_expect("middle with a base", func(f: Dictionary) -> void: _seg(f, "mid_split")["grid"][4] = "...B...", "only a bottom segment")
	_expect("top with a base", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][2] = "...B...", "only a bottom segment")
	_expect("bottom with an entrance", func(f: Dictionary) -> void: _seg(f, "bot_home")["grid"][1] = ".o.#.1.", "only a top segment")
	_expect("bottom without a base", func(f: Dictionary) -> void: _seg(f, "bot_home")["grid"][2] = "..o#o..", "exactly one base")
	_expect("bottom with two bases", func(f: Dictionary) -> void: _seg(f, "bot_home")["grid"][1] = ".o.B.o.", "exactly one base")
	_expect("bottom last row not scenery", func(f: Dictionary) -> void: _seg(f, "bot_home")["grid"][3] = "..o....", "all scenery")
	_expect("bottom last row with a spot", func(f: Dictionary) -> void: _seg(f, "bot_edge")["grid"][3] = "o......", "all scenery")
	_expect("2 x 2 block of road", func(f: Dictionary) -> void: _block(f), "2 x 2")
	_expect("block across a gate socket", func(f: Dictionary) -> void: _seg(f, "mid_split")["grid"][2] = ".GG.o.G", "2 x 2")
	_expect("two road cells side by side at the bottom", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][3] = "...##..", "side by side")
	_expect("two road cells side by side at the top", func(f: Dictionary) -> void: _seg(f, "mid_split")["grid"][0] = "o..##.o", "side by side")
	_expect("no road in the port row", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][3] = ".......", "at least one road cell")
	_expect("no road in the top row of a middle", func(f: Dictionary) -> void: _seg(f, "mid_split")["grid"][0] = "o.....o", "at least one road cell")
	_expect("no road in the top row of a bottom", func(f: Dictionary) -> void: _seg(f, "bot_home")["grid"][0] = ".......", "at least one road cell")


func _entrance_inside(files: Dictionary) -> void:
	_seg(files, "top_one")["grid"][0] = "o.....o"
	_seg(files, "top_one")["grid"][1] = ".o.1.o."


func _block(files: Dictionary) -> void:
	_seg(files, "top_one")["grid"][2] = "..##..."
	_seg(files, "top_one")["grid"][3] = "..##..."


func test_segments_must_fit_by_exact_port_sets() -> void:
	_expect("a top that no middle fits under", func(f: Dictionary) -> void: _seg(f, "top_one")["grid"][3] = "..#....", "top_one.json: no middle segment fits")
	_expect("ports that only overlap", func(f: Dictionary) -> void: _seg(f, "mid_merge")["grid"][0] = ".#.#.#.", "top_twin.json: no middle segment fits")
	_expect("a middle that no bottom fits under", func(f: Dictionary) -> void: _seg(f, "bot_home")["grid"][0] = "..#....", "no bottom segment fits under")


func test_a_middle_that_fits_under_no_top_needs_no_bottom() -> void:
	var files: Dictionary = Fx.files_from_json()
	var loose: Dictionary = Fx.segment("mid_split")
	loose["id"] = "mid_loose"
	loose["grid"][0] = "o.#...o"
	loose["grid"][4] = ".#....."
	files["segments/mid_loose.json"] = loose
	files["segments/index.json"]["segments"].append("mid_loose")
	assert_eq(RunData.check(files, catalog), PackedStringArray(), "no top leads to it, so it is never picked")


func test_a_bottom_last_row_may_hold_scenery_only_when_the_run_is_13_rows() -> void:
	var files: Dictionary = Fx.files_from_json()
	# Rows 4, 4, 4 make 12: the bottom row rule is for 13 row maps only.
	files["runs/run.json"]["rows"] = {"top": 4, "middle": 4, "bottom": 4}
	for id: String in ["mid_split", "mid_bend", "mid_side", "mid_merge"]:
		_seg(files, id)["grid"].remove_at(1)
	_seg(files, "bot_home")["grid"][3] = "..o...."
	var found: String = "\n".join(RunData.check(files, catalog))
	assert_false(found.contains("all scenery"), found)


# ---- packs ----

func test_boss_wave_strength_limits_are_inclusive() -> void:
	for value: int in [50, 1000]:
		var files: Dictionary = Fx.files_from_json()
		_pack(files, "band6_pack0")["waves"][2]["strength"] = value
		assert_eq(RunData.check(files, catalog), PackedStringArray(), "strength %d" % value)


func test_packs_hostile() -> void:
	_expect("file missing", func(f: Dictionary) -> void: f.erase("segments/packs.json"), "packs.json: is missing")
	_expect("not an object", func(f: Dictionary) -> void: f["segments/packs.json"] = [], "packs.json")
	_expect("format", func(f: Dictionary) -> void: f["segments/packs.json"]["format"] = 2, "packs.json: format")
	_expect("extra top key", func(f: Dictionary) -> void: f["segments/packs.json"]["x"] = 1, "unknown key x")
	_expect("no packs", func(f: Dictionary) -> void: f["segments/packs.json"]["packs"] = [], "packs.json: packs")
	_expect("repeated pack id", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["id"] = "band2_pack0", "repeats band2_pack0")
	_expect("bad pack id", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["id"] = "Band Two", "must be an id")
	_expect("pack extra key", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["note"] = 1, "unknown key note")
	_expect("pack missing waves", func(f: Dictionary) -> void: _pack(f, "band2_pack1").erase("waves"), "waves: is missing")
	_expect("band 0", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["band"] = 0, "band")
	_expect("band 7", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["band"] = 7, "band")
	_expect("band as text", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["band"] = "two", "band")
	_expect("boss in band 2", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["boss"] = "grumblesack", "must be empty in bands 1 to 5")
	_expect("band 6 without a boss", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["boss"] = "", "names its boss")
	_expect("band 6 boss unknown", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["boss"] = "dragon", "names no boss")
	_expect("band 6 boss is a creature", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["boss"] = "scamp", "names no boss")
	_expect("boss not text", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["boss"] = 5, "boss id")
	_expect("two waves", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["waves"].pop_back(), "waves")
	_expect("four waves", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["waves"].append(_pack(f, "band2_pack1")["waves"][0].duplicate(true)), "waves")
	_expect("wave strength", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["waves"][0]["strength"] = 100, "unknown key strength")
	_expect("strength on a band 2 third wave", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["waves"][2]["strength"] = 100, "unknown key strength")
	_expect("strength on a band 5 third wave", func(f: Dictionary) -> void: _pack(f, "band5_pack0")["waves"][2]["strength"] = 150, "unknown key strength")
	_expect("strength on a band 6 first wave", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][0]["strength"] = 150, "waves[0]: unknown key strength")
	_expect("strength on a band 6 second wave", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][1]["strength"] = 150, "waves[1]: unknown key strength")
	_expect("band 6 boss wave without strength", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][2].erase("strength"), "waves[2].strength: is missing")
	_expect("boss strength 49", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][2]["strength"] = 49, "waves[2].strength")
	_expect("boss strength 1001", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][2]["strength"] = 1001, "waves[2].strength")
	_expect("boss strength a fraction", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][2]["strength"] = 150.5, "whole number")
	_expect("boss strength as text", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][2]["strength"] = "150", "whole number")
	_expect("boss strength huge", func(f: Dictionary) -> void: _pack(f, "band6_pack0")["waves"][2]["strength"] = 1e30, "whole number")
	_expect("wave not an object", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["waves"][0] = [], "waves[0]")
	_expect("wave without groups", func(f: Dictionary) -> void: _pack(f, "band2_pack1")["waves"][0]["groups"] = [], "groups")
	_expect("nine groups", func(f: Dictionary) -> void: _nine_groups(f), "groups")
	_expect("group extra key", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["x"] = 1, "unknown key x")
	_expect("group missing key", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0].erase("count"), "count: is missing")
	_expect("group unknown creature", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["enemy"] = "dragon", "names no creature")
	_expect("group creature bad id", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["enemy"] = "Big One", "must be an id")
	_expect("count 0", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["count"] = 0, "count")
	_expect("count 201", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["count"] = 201, "count")
	_expect("count fraction", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["count"] = 1.5, "whole number")
	_expect("entrance 3", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["entrance"] = 3, "entrance")
	_expect("entrance 0", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["entrance"] = 0, "entrance")
	_expect("at_ms not a multiple of 50", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["at_ms"] = 25, "multiple of 50")
	_expect("at_ms negative", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["at_ms"] = -50, "at_ms")
	_expect("at_ms past 600,000", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["at_ms"] = 600050, "at_ms")
	_expect("every_ms 0", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["every_ms"] = 0, "every_ms")
	_expect("every_ms 75", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["every_ms"] = 75, "multiple of 50")
	_expect("every_ms past 60,000", func(f: Dictionary) -> void: _groups(f, "band2_pack1", 0)[0]["every_ms"] = 60050, "every_ms")


func _nine_groups(files: Dictionary) -> void:
	var groups: Array = _groups(files, "band2_pack1", 0)
	for i: int in 8:
		groups.append(groups[0].duplicate(true))


func test_pack_creature_rules_hostile() -> void:
	_expect("band 1 first wave with a Pip", func(f: Dictionary) -> void: _groups(f, "band1_pack0", 0)[1]["enemy"] = "pip", "holds only scamp")
	_expect("band 1 uses a band 2 creature", func(f: Dictionary) -> void: _groups(f, "band1_pack0", 2)[1]["enemy"] = "skitter", "not added by bands 1 to 1")
	_expect("band 3 uses a band 4 creature", func(f: Dictionary) -> void: _groups(f, "band3_pack0", 1)[1]["enemy"] = "dusk_moth", "not added by bands 1 to 3")
	_expect("a boss in band 2", func(f: Dictionary) -> void: _groups(f, "band2_pack0", 2)[1]["enemy"] = "grumblesack", "only in the band 6 pack that names it")
	_expect("a Puff as a group", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 0)[1]["enemy"] = "puff", "not added")
	_expect("another boss as escort", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 2)[1]["enemy"] = "ironshell", "only in the band 6 pack that names it")
	_expect("boss in the first wave", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 0)[1]["enemy"] = "grumblesack", "third wave")
	_expect("boss in the second wave", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 1)[1]["enemy"] = "grumblesack", "third wave")
	_expect("boss as a group of 2", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 2)[0]["count"] = 2, "one group of 1")
	_expect("boss twice", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 2)[1]["enemy"] = "grumblesack", "exactly one group")
	_expect("no boss group", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 2)[0]["enemy"] = "scamp", "exactly one group")
	_expect("too few packs in a band", func(f: Dictionary) -> void: f["segments/packs.json"]["packs"].erase(_pack(f, "band1_pack3")), "band 1 needs at least 4 packs of tier 0; it has 3")
	_expect("no pack for a boss", func(f: Dictionary) -> void: _no_old_tusk(f), "no band 6 pack for the boss old_tusk")


func _no_old_tusk(files: Dictionary) -> void:
	_pack(files, "band6_pack3")["boss"] = "grumblesack"
	_groups(files, "band6_pack3", 2)[0]["enemy"] = "grumblesack"


func test_a_later_band_may_use_every_earlier_creature() -> void:
	var files: Dictionary = Fx.files_from_json()
	_groups(files, "band5_pack0", 1)[1]["enemy"] = "scamp"
	_groups(files, "band5_pack0", 1)[0]["enemy"] = "dusk_moth"
	_groups(files, "band6_pack0", 1)[1]["enemy"] = "gatecrasher"
	assert_eq(RunData.check(files, catalog), PackedStringArray())


func test_spawn_bound_hostile() -> void:
	_expect("124 creatures", func(f: Dictionary) -> void: _groups(f, "band1_pack0", 0)[0]["count"] = 121, "spawns 124 creatures; at most 120")
	_expect("a wave of 100 grows past 120 with Crowded Night", func(f: Dictionary) -> void: _groups(f, "band1_pack0", 1)[0]["count"] = 100, "with risk card crowded_night")
	_expect("a wave of 100 grows past 120 with Pip Parade", func(f: Dictionary) -> void: _only_pip_parade(f), "with risk card pip_parade")
	_expect("a boss pack second wave counts risk cards", func(f: Dictionary) -> void: _groups(f, "band6_pack0", 1)[0]["count"] = 105, "with risk card")


func _only_pip_parade(files: Dictionary) -> void:
	files["cards/cards.json"]["cards"].erase(_card(files, "crowded_night"))
	_groups(files, "band1_pack0", 1)[0]["count"] = 100


func _card(files: Dictionary, id: String) -> Dictionary:
	for item: Variant in files["cards/cards.json"]["cards"]:
		if (item as Dictionary)["id"] == id:
			return item
	return {}


func test_splitters_count_their_puffs() -> void:
	var files: Dictionary = Fx.files_from_json()
	var list: Array = files["cards/cards.json"]["cards"]
	for id: String in ["crowded_night", "flock", "pip_parade"]:
		list.erase(_card(files, id))
	# Wave 2 of this pack: Puffballs first (4 each with their Puffs), then 4 Skitters.
	_groups(files, "band3_pack0", 1)[0]["count"] = 29
	assert_eq(RunData.check(files, catalog), PackedStringArray(), "29 x 4 + 4 = 120")
	_groups(files, "band3_pack0", 1)[0]["count"] = 30
	var found: String = "
".join(RunData.check(files, catalog))
	assert_true(found.contains("spawns 124 creatures"), found)


func test_the_boss_wave_never_gets_a_risk_card() -> void:
	var files: Dictionary = Fx.files_from_json()
	# 105 + the boss + the second group (5) = 111: fine without a card, far over with one.
	_groups(files, "band6_pack0", 2)[1]["count"] = 110
	assert_eq(RunData.check(files, catalog), PackedStringArray(), "110 creatures and the boss, no risk card")
	_groups(files, "band6_pack0", 2)[1]["count"] = 120
	var found: String = "\n".join(RunData.check(files, catalog))
	assert_true(found.contains("spawns 121 creatures"), found)
	assert_false(found.contains("risk card"), "the boss wave is not checked with a risk card")


func test_an_add_group_card_counts_towards_the_bound() -> void:
	var files: Dictionary = Fx.files_from_json()
	_groups(files, "band2_pack0", 0)[0]["count"] = 97
	var found: String = "\n".join(RunData.check(files, catalog))
	assert_true(found.contains("with risk card pip_parade"), found)
	_groups(files, "band2_pack0", 0)[0]["count"] = 60
	assert_false("\n".join(RunData.check(files, catalog)).contains("pip_parade"))


func test_a_wave_of_exactly_120_is_allowed() -> void:
	var files: Dictionary = Fx.files_from_json()
	# Remove the risk cards so only the plain bound applies.
	var list: Array = files["cards/cards.json"]["cards"]
	for id: String in ["crowded_night", "flock", "pip_parade"]:
		list.erase(_card(files, id))
	_groups(files, "band1_pack0", 1)[1]["count"] = 60
	_groups(files, "band1_pack0", 1)[0]["count"] = 60
	assert_eq(RunData.check(files, catalog), PackedStringArray())
	_groups(files, "band1_pack0", 1)[0]["count"] = 61
	assert_ne(RunData.check(files, catalog), PackedStringArray())


func test_problems_are_reported_for_several_files_at_once() -> void:
	var files: Dictionary = Fx.files_from_json()
	files["runs/run.json"]["gates"] = 9
	_card(files, "spare_gate")["once"] = 7
	_seg(files, "top_one")["kind"] = "side"
	_groups(files, "band2_pack0", 0)[0]["count"] = 0
	var found: String = "\n".join(RunData.check(files, catalog))
	for name_part: String in ["run.json: gates", "cards.json: cards", "top_one.json: kind", "packs.json: packs"]:
		assert_true(found.contains(name_part), "%s in:\n%s" % [name_part, found])
