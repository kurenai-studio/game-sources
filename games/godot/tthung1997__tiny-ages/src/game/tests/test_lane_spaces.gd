extends McpTestSuite
## Reserved spaces on each lane (issue #50): the number of spaces limits what the view shows, a
## piece goes in the free space nearest the hall and keeps it, restricted ground takes only what
## belongs there, a full lane hides the lowest rank, and none of it touches the simulation.

const LAST_ERA: int = 4
const SAVE_PATH: String = "user://test_lane_save.tres"
## The first age each building can stand in (the sim gates them by milestone; the view does not).
const BUILDING_ERA: Dictionary = {
	&"lookout": 0, &"drying_rack": 0, &"knapping_spot": 0, &"hut": 0, &"field": 1, &"smithy": 2,
	&"trading_post": 2, &"quay": 2, &"bloomery": 3, &"granary": 3,
}
const BACK: StringName = LaneSpaces.BACK
## Buildings are offered in pairs and the one not picked stays unbuilt (docs/ages.md B5, I5): a group
## has the Smithy or the Trading Post, the Granary or the Bloomery. The fixtures build the first of each.
const FORK_LOSERS: Array[StringName] = [&"trading_post", &"bloomery"]
const MID: StringName = LaneSpaces.MID


func suite_name() -> String:
	return "lane_spaces"


func teardown() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


# ---- Fixtures ---------------------------------------------------------------------------------

## The first age whose art has a piece: when the group can have earned it.
func _art_era(id: StringName) -> int:
	for era_order: int in range(LAST_ERA + 1):
		if not WorldLayout.piece_path(id, era_order).is_empty():
			return era_order
	return LAST_ERA + 1


## The actions that earn every piece an age can have, one per prop and building, as callables.
func _unlocks(era_order: int) -> Array[Callable]:
	var found: Array[Callable] = []
	for id: StringName in SceneProps.ids():
		if _art_era(id) > era_order:
			continue
		var spec: Dictionary = SceneProps.PROPS[id]
		if spec["kind"] == SceneProps.Kind.FLAG:
			found.append(func(world: WorldState) -> void: world.flags[spec["key"]] = true)
		elif spec["kind"] == SceneProps.Kind.ACHIEVEMENT:
			found.append(func(world: WorldState) -> void:
				if not world.achievements.has(spec["key"]):
					world.achievements.append(spec["key"])
			)
	for id: StringName in WorldLayout.BUILDINGS:
		if FORK_LOSERS.has(id):
			continue
		if int(BUILDING_ERA[id]) <= era_order:
			found.append(func(world: WorldState) -> void: _build(world, id))
	return found


func _build(world: WorldState, id: StringName, complete: bool = true) -> BuildingState:
	for existing: BuildingState in world.buildings:
		if existing.def_id == id:
			existing.complete = complete
			return existing
	var building: BuildingState = BuildingState.new()
	building.def_id = id
	building.complete = complete
	world.buildings.append(building)
	return building


func _world(era_order: int, crossed: bool = true) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	if crossed:
		world.flags[&"stepping_stones"] = true
	return world


## A world in an age that holds everything the age can have earned.
func _full_world(era_order: int, crossed: bool = true) -> WorldState:
	var world: WorldState = _world(era_order, crossed)
	for unlock: Callable in _unlocks(era_order):
		unlock.call(world)
	# The crossing flags are props' own; without a crossing they are not part of the world.
	if not crossed:
		for flag: StringName in WorldLayout.CROSSING_FLAGS:
			world.flags.erase(flag)
	return world


func _spans(layout: LaneLayout) -> Dictionary:
	var found: Dictionary = {}
	for key: StringName in layout.starts:
		found[key] = [int(layout.starts[key]), LanePieces.spaces_of(key)]
	return found


## Every space a layout uses, once: asserts no two pieces share one.
func _cells(layout: LaneLayout, label: String) -> Dictionary:
	var used: Dictionary = {}
	for key: StringName in layout.starts:
		var lane: StringName = LanePieces.lane_of(key)
		for at: int in range(int(layout.starts[key]), int(layout.starts[key]) + LanePieces.spaces_of(key)):
			var cell: String = "%s:%d" % [lane, at]
			assert_false(used.has(cell), "%s: %s and %s share a space" % [label, key, used.get(cell)])
			used[cell] = key
	return used


# ---- The grid ---------------------------------------------------------------------------------

func test_both_lanes_are_cut_in_equal_spaces_with_a_gap_and_each_prop_space_sits_in_a_gap() -> void:
	assert_eq(LaneSpaces.width(BACK), LaneSpaces.width(MID))
	assert_true(LaneSpaces.GAP >= 2, "There is a gap between spaces")
	for lane: StringName in LaneSpaces.LANES:
		var last: int = LaneSpaces.count(lane) - 1
		assert_true(
			LaneSpaces.left(lane, last) + LaneSpaces.width(lane) <= WorldLayout.WORLD_RIGHT,
			"%s ends inside the world" % lane
		)
		for index: int in last:
			assert_eq(
				LaneSpaces.left(lane, index + 1) - LaneSpaces.left(lane, index),
				LaneSpaces.width(lane) + LaneSpaces.GAP
			)
	assert_true(LaneSpaces.left(BACK, 0) >= WorldLayout.WORLD_LEFT, "The building lane starts inside")
	# A piece of n spaces spans its spaces and the gaps between them.
	assert_eq(LaneSpaces.span_px(1), LaneSpaces.WIDTH)
	assert_eq(LaneSpaces.span_px(3), 3 * LaneSpaces.WIDTH + 2 * LaneSpaces.GAP)
	# Every prop space is centred on the gap between two building spaces: props between buildings.
	for index: int in range(1, LaneSpaces.count(BACK)):
		var gap_middle: float = float(LaneSpaces.left(BACK, index)) - float(LaneSpaces.GAP) / 2.0
		assert_eq(
			LaneSpaces.center(MID, index), gap_middle,
			"Prop space %d is on the gap between building spaces %d and %d" % [index, index - 1, index]
		)
	assert_eq(LaneSpaces.index_at(BACK, 150.0), 15)
	assert_eq(LaneSpaces.index_at(MID, 150.0), 16)
	assert_eq(LaneSpaces.index_at(BACK, -500.0), -1)


func test_the_signature_footprint_and_the_pine_are_never_spaces() -> void:
	for lane: StringName in LaneSpaces.LANES:
		for index: int in LaneSpaces.count(lane):
			var from: float = float(LaneSpaces.left(lane, index))
			var to: float = from + float(LaneSpaces.width(lane))
			var on_hall: bool = from < float(LaneSpaces.HALL.y) and to > float(LaneSpaces.HALL.x)
			var on_pine: bool = from < float(LaneSpaces.PINE.y) and to > float(LaneSpaces.PINE.x)
			assert_eq(
				LaneSpaces.terrain(lane, index) == LaneSpaces.RESERVED, on_hall or on_pine,
				"%s space %d" % [lane, index]
			)
			if on_hall or on_pine:
				assert_false(LaneSpaces.is_open(lane, index, LAST_ERA, true))
	# The cave's footprint is the cliff in the building lane's art: x 0 to 100 in the Cave Age.
	assert_true(LaneSpaces.HALL.x <= 0 and LaneSpaces.HALL.y >= 100)
	assert_true(LaneSpaces.PINE.x <= 192 and LaneSpaces.PINE.y >= 205, "The trunk is x 192 to 204")


func test_baked_in_art_that_stays_is_a_piece_that_is_always_there() -> void:
	# What is still drawn into the static layers (the hall's rocks, the pine's bush, the reeds) holds the
	# prop spaces it stands in; no piece of any age stands on it, and the decor the game can take away is
	# not in the art at all (it is its own piece, below).
	for index: int in LaneSpaces.count(BACK):
		assert_false(LaneSpaces.is_fixed(BACK, index), "Buildings stand in front of the decor")
	for era_order: int in range(LAST_ERA + 1):
		var layout: LaneLayout = LanePlacer.place(_full_world(era_order))
		for key: StringName in layout.starts:
			if LanePieces.lane_of(key) != MID:
				continue
			for at: int in range(int(layout.starts[key]), int(layout.starts[key]) + LanePieces.spaces_of(key)):
				assert_false(LaneSpaces.is_fixed(MID, at), "Age %d: %s stands on art" % [era_order, key])
	var baked: Dictionary = {}
	for layer: Array in LaneSpaces.FIXED_LAYERS:
		var image: Image = (load(WorldLayout.piece_path(layer[0], 0)) as Texture2D).get_image()
		for x: int in image.get_width():
			for y: int in range(LaneSpaces.FIXED_ROWS.x, LaneSpaces.FIXED_ROWS.y):
				if image.get_pixel(x, y).a > 0.05:
					baked[x + int(layer[1])] = true
					break
	for index: int in LaneSpaces.count(MID):
		var kind: StringName = LaneSpaces.terrain(MID, index)
		if kind == LaneSpaces.NONE or kind == LaneSpaces.RESERVED:
			continue
		var middle: int = LaneSpaces.left(MID, index) + (LaneSpaces.WIDTH - LaneSpaces.FIXED_WINDOW) / 2
		for x: int in range(middle, middle + LaneSpaces.FIXED_WINDOW):
			assert_false(baked.has(x), "Space %d is free but art stands at x %d" % [index, x])


func _decor_placed(layout: LaneLayout) -> Array[StringName]:
	var found: Array[StringName] = []
	for key: StringName in layout.starts:
		if SceneProps.is_decor(key):
			found.append(key)
	return found


func test_decor_is_a_piece_of_the_lowest_rank_that_is_there_from_the_start() -> void:
	var ids: Array[StringName] = []
	for id: StringName in SceneProps.ids():
		if SceneProps.is_decor(id):
			ids.append(id)
			assert_eq(LanePieces.rank_of(id), 5, "%s ranks below every prop" % id)
			assert_eq(LanePieces.lane_of(id), MID)
			assert_true(not SceneProps.name_of(id).is_empty(), "%s has a name to hover" % id)
	assert_eq(ids.size(), 16)
	var layout: LaneLayout = LanePlacer.place(_world(0, false))
	assert_gt(_decor_placed(layout).size(), 6, "A new world is dressed with its bushes and rocks")
	for key: StringName in _decor_placed(layout):
		assert_true(SceneProps.is_shown(key, _world(0)), "%s is always shown" % key)


func test_decor_gives_way_to_props_and_never_the_other_way() -> void:
	var calm: int = _decor_placed(LanePlacer.place(_world(1))).size()
	var world: WorldState = _world(1)
	for unlock: Callable in _unlocks(1):
		unlock.call(world)
		var layout: LaneLayout = LanePlacer.place(world)
		for key: StringName in LanePlacer.wanted_keys(world):
			if not SceneProps.is_decor(key) and LanePieces.lane_of(key) == MID and not layout.is_placed(key):
				# A prop only goes without a space when no decor stands where a prop of its terrain could.
				for decor: StringName in _decor_placed(layout):
					assert_ne(LanePieces.terrain_of(decor), LanePieces.terrain_of(key),
						"%s has no space while %s stands" % [key, decor])
	var crowded: int = _decor_placed(LanePlacer.place(world)).size()
	assert_true(crowded < calm, "A busy age shows less decor (%d) than a calm one (%d)" % [crowded, calm])
	# Decor that was hidden stays out of the sim: it was never there.
	var snap: Dictionary = SimFixture.snapshot(world)
	LanePlacer.place(world)
	assert_eq(SimFixture.snapshot(world), snap)


func test_a_prop_that_needs_the_room_takes_decors_space_not_a_props() -> void:
	var table: Dictionary = {&"well": [MID, 1, LaneSpaces.GROUND, 2], &"loom": [MID, 1, LaneSpaces.GROUND, 4]}
	var ledger: Dictionary = {}
	var wanted: Array[StringName] = []
	var count: int = 0
	for index: int in LaneSpaces.count(MID):
		if LaneSpaces.span_open(MID, index, 1, LaneSpaces.GROUND, 1, false):
			var key: StringName = StringName("filler_%d" % count)
			count += 1
			table[key] = [MID, 1, LaneSpaces.GROUND, 5]
			ledger[key] = index
			wanted.append(key)
	wanted.append(&"well")
	wanted.append(&"loom")
	var order: Array[StringName] = _keys(table)
	var placed: Dictionary = LanePlacer.pack(table, wanted, ledger, order, 1, false)
	assert_true(placed.has(&"well") and placed.has(&"loom"), "Both props found a space")
	assert_eq(placed.size(), count, "...by hiding two pieces of decor, the lane staying full")


func test_the_ground_runs_from_the_west_forest_over_the_river_to_the_sea() -> void:
	assert_eq(LaneSpaces.terrain(BACK, LaneSpaces.index_at(BACK, -300.0)), LaneSpaces.GROUND)
	assert_eq(LaneSpaces.terrain(BACK, LaneSpaces.index_at(BACK, 150.0)), LaneSpaces.GROUND)
	assert_eq(LaneSpaces.terrain(BACK, LaneSpaces.index_at(BACK, 320.0)), LaneSpaces.SHALLOWS)
	assert_eq(LaneSpaces.terrain(BACK, LaneSpaces.index_at(BACK, 400.0)), LaneSpaces.DEEP)
	assert_eq(LaneSpaces.terrain(BACK, LaneSpaces.index_at(BACK, 520.0)), LaneSpaces.GROUND)
	assert_eq(LaneSpaces.terrain(BACK, LaneSpaces.index_at(BACK, 630.0)), LaneSpaces.COAST)
	assert_eq(LaneSpaces.terrain(BACK, LaneSpaces.index_at(BACK, 700.0)), LaneSpaces.SEA)
	assert_eq(LaneSpaces.terrain(MID, LaneSpaces.index_at(MID, 330.0)), LaneSpaces.SHALLOWS)
	assert_eq(LaneSpaces.terrain(MID, LaneSpaces.index_at(MID, 400.0)), LaneSpaces.DEEP)
	assert_gt(_count(MID, LaneSpaces.SHORE), 2, "The spit has room for a few of the coast's props")
	# The river's near bank runs diagonally from x 328 at the back to 302 at the front: the deep
	# spaces start well out, so a boat never has half of itself on the grass, nor on the far bank.
	for lane: StringName in LaneSpaces.LANES:
		for index: int in LaneSpaces.count(lane):
			if LaneSpaces.terrain(lane, index) == LaneSpaces.DEEP:
				assert_true(LaneSpaces.left(lane, index) >= 356)
				assert_true(LaneSpaces.left(lane, index) + LaneSpaces.width(lane) <= 444)
			if LaneSpaces.terrain(lane, index) == LaneSpaces.SEA:
				assert_true(LaneSpaces.left(lane, index) >= 692, "Ships stand out in the open sea")
	assert_eq(_count(BACK, LaneSpaces.DEEP), 2)
	assert_eq(_count(MID, LaneSpaces.DEEP), 2)
	# The river is the one WorldLayout draws the crossing over, to within a space.
	assert_true(LaneSpaces.RIVER_FROM <= int(WorldLayout.CROSSING_X.x))
	assert_true(absi(LaneSpaces.FAR_BANK_FROM - int(WorldLayout.CROSSING_X.y)) <= LaneSpaces.width(BACK))


## How many spaces of a terrain a lane has.
func _count(lane: StringName, kind: StringName) -> int:
	var found: int = 0
	for index: int in LaneSpaces.count(lane):
		found += 1 if LaneSpaces.terrain(lane, index) == kind else 0
	return found


func test_the_number_of_spaces_is_the_same_in_every_age_but_for_the_mammoth() -> void:
	for lane: StringName in LaneSpaces.LANES:
		var usable: Array[int] = []
		for era_order: int in range(LAST_ERA + 1):
			var open: int = 0
			for index: int in LaneSpaces.count(lane):
				if LaneSpaces.is_open(lane, index, era_order, true):
					open += 1
			usable.append(open)
		assert_eq(usable[1], usable[LAST_ERA], "%s: the Settled Age has every space" % lane)
		assert_eq(usable[2], usable[LAST_ERA])
		assert_true(usable[0] <= usable[1], "Only the Cave Age's mammoth holds any back")
	var mammoth: int = LaneSpaces.index_at(BACK, 230.0)
	assert_false(LaneSpaces.is_open(BACK, mammoth, 0, true), "The mammoth stands there in the Cave Age")
	assert_true(LaneSpaces.is_open(BACK, mammoth, 1, true))
	var west: int = LaneSpaces.index_at(BACK, -300.0)
	assert_true(LaneSpaces.is_open(BACK, west, 0, true), "A far west space is free from the start")


func test_the_far_bank_is_ground_only_once_a_crossing_is_laid() -> void:
	var far: int = LaneSpaces.index_at(BACK, 510.0)
	assert_eq(LaneSpaces.terrain(BACK, far), LaneSpaces.GROUND)
	assert_true(LaneSpaces.needs_crossing(BACK, far))
	assert_false(LaneSpaces.is_open(BACK, far, LAST_ERA, false))
	assert_true(LaneSpaces.is_open(BACK, far, LAST_ERA, true))
	assert_false(LaneSpaces.needs_crossing(BACK, LaneSpaces.index_at(BACK, 120.0)))
	assert_false(LaneSpaces.needs_crossing(MID, LaneSpaces.index_at(MID, 650.0)), "The sea is not walked")


func test_a_space_takes_only_what_belongs_on_its_terrain() -> void:
	var deep: int = LaneSpaces.index_at(MID, 384.0)
	assert_true(LaneSpaces.span_open(MID, deep, 1, LaneSpaces.DEEP, 0, false))
	assert_false(LaneSpaces.span_open(MID, deep, 1, LaneSpaces.GROUND, 0, true), "No house in the river")
	assert_false(LaneSpaces.span_open(MID, deep, 1, LaneSpaces.SHALLOWS, 0, true), "Not the bank's shallows")
	var shallows: int = LaneSpaces.index_at(MID, 328.0)
	assert_true(LaneSpaces.span_open(MID, shallows, 1, LaneSpaces.SHALLOWS, 0, false))
	assert_false(LaneSpaces.span_open(MID, shallows, 1, LaneSpaces.DEEP, 0, true), "No boat by the bank")
	var yard: int = LaneSpaces.index_at(MID, 160.0)
	assert_true(LaneSpaces.span_open(MID, yard, 1, LaneSpaces.GROUND, 0, false))
	assert_false(LaneSpaces.span_open(MID, yard, 1, LaneSpaces.DEEP, 0, true), "No boat on dry land")
	var join: int = LaneSpaces.index_at(BACK, 456.0)
	assert_eq(LaneSpaces.terrain(BACK, join), LaneSpaces.NONE, "Half bank, half water takes nothing")
	var coast: int = LaneSpaces.index_at(BACK, 620.0)
	assert_true(LaneSpaces.span_open(BACK, coast, 3, LaneSpaces.COAST, 0, false), "The harbour's three spaces")
	assert_false(LaneSpaces.span_open(BACK, coast, 3, LaneSpaces.SEA, 0, true), "A ship is not on the beach")
	assert_false(LaneSpaces.span_open(MID, LaneSpaces.count(MID) - 1, 2, LaneSpaces.SHORE, 0, true))


# ---- What the view needs to know about each piece ---------------------------------------------

func test_every_building_and_prop_is_in_a_space_or_is_backdrop() -> void:
	for id: StringName in WorldLayout.BUILDINGS:
		assert_true(LanePieces.TABLE.has(id), "%s has no lane" % id)
	for id: StringName in SceneProps.ids():
		assert_true(
			LanePieces.has(id) or LanePieces.BACKDROP.has(id),
			"%s is neither in a space nor backdrop" % id
		)
		assert_false(LanePieces.has(id) and LanePieces.BACKDROP.has(id), "%s is both" % id)
	for id: StringName in LanePieces.BACKDROP:
		assert_true(SceneProps.PROPS.has(id), "Backdrop %s is no prop" % id)
	for key: StringName in LanePieces.TABLE:
		assert_true(
			WorldLayout.BUILDINGS.has(key) or SceneProps.PROPS.has(key), "%s is no piece" % key
		)
		assert_eq(LanePieces.key_of(key), key, "%s is a group's root" % key)


func test_alternatives_share_spaces_and_an_overlay_follows_its_base() -> void:
	assert_eq(LanePieces.key_of(&"council_ring"), &"market_stalls")
	assert_eq(LanePieces.key_of(&"tally_post"), &"market_stalls")
	assert_eq(LanePieces.key_of(&"boat_raft"), &"boat_dugout")
	assert_eq(LanePieces.key_of(&"flax_beaten"), &"flax_beaten", "Another ground: its own spaces")
	assert_eq(LanePieces.key_of(&"cloth_dyed"), &"cloth_line")
	assert_eq(LanePieces.key_of(&"weavers_row_dyed"), &"weavers_row")
	assert_eq(LanePieces.key_of(&"hut"), &"hut")
	assert_true(LanePieces.has(&"cloth_dyed"))
	assert_false(LanePieces.has(&"low_wall"))


func test_a_piece_that_replaces_others_never_ranks_below_them() -> void:
	for replacer: StringName in LanePlacer.replaces():
		if not LanePieces.TABLE.has(replacer):
			continue
		for old: StringName in LanePlacer.replaces()[replacer]:
			if LanePieces.TABLE.has(old):
				assert_true(
					LanePieces.rank_of(replacer) <= LanePieces.rank_of(old),
					"%s (rank %d) replaces %s (rank %d)" % [
						replacer, LanePieces.rank_of(replacer), old, LanePieces.rank_of(old)
					]
				)


func test_every_pieces_art_fits_the_spaces_it_takes_in_every_age() -> void:
	var ids: Array = []
	ids.append_array(SceneProps.ids())
	ids.append_array(WorldLayout.BUILDINGS.keys())
	for id: StringName in ids:
		if not LanePieces.has(id):
			continue
		var key: StringName = LanePieces.key_of(id)
		var room: int = LaneSpaces.span_px(LanePieces.spaces_of(key))
		var layers: Array[StringName] = [id]
		if WorldLayout.BUILDINGS.has(id):
			layers = [StringName("building_%s" % id), StringName("site_%s" % id)]
		for layer: StringName in layers:
			for era_order: int in range(LAST_ERA + 1):
				var art: Rect2i = LanePieces.art_rect(layer, era_order)
				assert_true(
					art.size.x <= room, "%s (age %d) is %d px wide in %d px of spaces" % [
						layer, era_order, art.size.x, room
					]
				)


func test_a_pieces_spaces_match_its_lane() -> void:
	for key: StringName in LanePieces.TABLE:
		assert_true(LaneSpaces.LANES.has(LanePieces.lane_of(key)), key)
		assert_true(LanePieces.spaces_of(key) >= 1)
		assert_true(LanePieces.rank_of(key) >= 1 and LanePieces.rank_of(key) <= 5)
		assert_true([
			LaneSpaces.GROUND, LaneSpaces.SHALLOWS, LaneSpaces.DEEP, LaneSpaces.SHORE, LaneSpaces.FLATS,
			LaneSpaces.COAST, LaneSpaces.SEA,
		].has(LanePieces.terrain_of(key)))
		# A building stands on the building lane, a boat or a bird-sized thing on the prop lane.
		if WorldLayout.BUILDINGS.has(key) and key != &"knapping_spot":
			assert_eq(LanePieces.lane_of(key), BACK, "%s is a building" % key)


# ---- Placing ----------------------------------------------------------------------------------

func test_no_two_pieces_share_a_space_and_each_stands_on_what_it_may() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var world: WorldState = _full_world(era_order)
		var layout: LaneLayout = LanePlacer.place(world)
		_cells(layout, "Age %d" % era_order)
		for key: StringName in layout.starts:
			assert_true(
				LaneSpaces.span_open(
					LanePieces.lane_of(key), int(layout.starts[key]), LanePieces.spaces_of(key),
					LanePieces.terrain_of(key), era_order, true
				),
				"Age %d: %s stands where it may not" % [era_order, key]
			)


func test_a_piece_goes_in_the_free_space_nearest_the_hall() -> void:
	var world: WorldState = _world(0)
	_build(world, &"hut")
	var layout: LaneLayout = LanePlacer.place(world)
	var start: int = layout.starts[&"hut"]
	var best: float = LaneSpaces.hall_distance(BACK, start, 2)
	for other: int in LaneSpaces.starts_by_distance(BACK, 2):
		if LaneSpaces.span_open(BACK, other, 2, LaneSpaces.GROUND, 0, true):
			assert_true(best <= LaneSpaces.hall_distance(BACK, other, 2) + 0.001)
	assert_true(layout.span_left(&"hut") >= float(LaneSpaces.HALL.y)
			or layout.span_left(&"hut") + layout.span_width(&"hut") <= float(LaneSpaces.HALL.x),
		"Beside the hall, never on it")


func test_ranks_one_and_two_always_show_in_every_age() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var world: WorldState = _full_world(era_order)
		var layout: LaneLayout = LanePlacer.place(world)
		for key: StringName in LanePlacer.wanted_keys(world):
			if LanePieces.is_essential(key):
				assert_true(layout.is_placed(key), "Age %d hides %s" % [era_order, key])


func test_ranks_one_and_two_show_whatever_order_the_group_earned_them_in() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 50
	for era_order: int in [1, 2, 3, 4]:
		for pass_index: int in 6:
			var unlocks: Array[Callable] = _unlocks(era_order)
			for index: int in range(unlocks.size() - 1, 0, -1):
				var other: int = rng.randi_range(0, index)
				var swap: Callable = unlocks[index]
				unlocks[index] = unlocks[other]
				unlocks[other] = swap
			var world: WorldState = _world(era_order)
			for unlock: Callable in unlocks:
				unlock.call(world)
				var layout: LaneLayout = LanePlacer.place(world)
				_cells(layout, "Age %d, round %d" % [era_order, pass_index])
				_assert_between_buildings(layout, "Age %d, round %d" % [era_order, pass_index])
				for key: StringName in LanePlacer.wanted_keys(world):
					if LanePieces.is_essential(key):
						assert_true(
							layout.is_placed(key),
							"Age %d, round %d: %s is hidden" % [era_order, pass_index, key]
						)


func test_an_early_age_just_shows_what_it_has_unlocked_and_leaves_the_mammoth_alone() -> void:
	var world: WorldState = _world(0, false)
	for id: StringName in [&"hut", &"drying_rack", &"lookout"]:
		_build(world, id)
	var layout: LaneLayout = LanePlacer.place(world)
	assert_true(layout.is_placed(&"hut") and layout.is_placed(&"drying_rack"))
	assert_true(layout.is_placed(&"lookout"), "Every unlocked building is shown: there is room")
	for id: StringName in [&"hut", &"drying_rack", &"lookout"]:
		assert_true(layout.is_placed(id), "%s has a space" % id)
		var from: float = layout.span_left(id)
		var to: float = from + layout.span_width(id)
		assert_true(to <= float(LaneSpaces.HALL.x) or from >= float(LaneSpaces.HALL.y), "%s is off the hall" % id)
		assert_true(to <= float(LaneSpaces.MAMMOTH.x) or from >= float(LaneSpaces.MAMMOTH.y),
			"%s does not stand on the mammoth" % id)
		assert_true(to <= float(LaneSpaces.RIVER_FROM), "%s is on dry ground" % id)


func test_a_piece_keeps_its_space_as_the_group_earns_more() -> void:
	var world: WorldState = _world(2)
	var seen: Dictionary = {}
	var unlocks: Array[Callable] = _unlocks(2)
	for unlock: Callable in unlocks:
		unlock.call(world)
		var layout: LaneLayout = LanePlacer.place(world)
		var back: Dictionary = {}
		for key: StringName in layout.starts:
			if LanePieces.lane_of(key) == BACK:
				for at: int in range(int(layout.starts[key]), int(layout.starts[key]) + LanePieces.spaces_of(key)):
					back[at] = key
		for key: StringName in seen.keys():
			if not layout.is_placed(key):
				seen.erase(key)
			elif LanePieces.lane_of(key) == BACK:
				if layout.starts[key] != seen[key]:
					# A building only moves when a better piece took its space (a hidden piece is
					# placed again somewhere else if it can be).
					var old_back: int = int(seen[key])
					var taken: bool = false
					for other_back: StringName in layout.starts:
						if other_back != key and LanePieces.lane_of(other_back) == BACK:
							var start_back: int = int(layout.starts[other_back])
							taken = taken or (
								start_back < old_back + LanePieces.spaces_of(key)
								and old_back < start_back + LanePieces.spaces_of(other_back)
							)
					assert_true(taken, "%s moved though nothing took its space" % key)
			elif layout.starts[key] != seen[key]:
				# A prop only gives way to a building that now stands where it was (between), or to a
				# better piece that took its space.
				var old: int = int(seen[key])
				var displaced: bool = false
				for at: int in range(old, old + LanePieces.spaces_of(key)):
					displaced = displaced or (back.has(at) and back.has(at - 1) and back[at] == back[at - 1])
				for other: StringName in layout.starts:
					if other != key and LanePieces.lane_of(other) == MID:
						var from: int = int(layout.starts[other])
						displaced = displaced or (from < old + LanePieces.spaces_of(key) and old < from + LanePieces.spaces_of(other))
				assert_true(displaced, "%s moved though nothing came over it" % key)
		for key: StringName in layout.starts:
			seen[key] = layout.starts[key]
	assert_gt(seen.size(), 10, "A lot was placed")


func test_a_tidier_piece_stands_where_the_old_one_stood() -> void:
	var world: WorldState = _world(2)
	world.flags[&"kiln"] = true
	var kiln: int = LanePlacer.place(world).starts[&"west_kiln"]
	world.achievements.append(&"fired_clay")
	var layout: LaneLayout = LanePlacer.place(world)
	assert_false(layout.is_placed(&"west_kiln"), "The yard takes the kiln in")
	var yard: int = layout.starts[&"potters_yard"]
	assert_true(yard <= kiln and kiln < yard + LanePieces.spaces_of(&"potters_yard"),
		"The yard (%d) stands where the kiln stood (%d)" % [yard, kiln])


func test_the_granary_stands_on_the_racks_ground() -> void:
	var world: WorldState = _world(3)
	_build(world, &"hut")
	_build(world, &"drying_rack")
	var rack: int = LanePlacer.place(world).starts[&"drying_rack"]
	_build(world, &"granary", false)
	var layout: LaneLayout = LanePlacer.place(world)
	assert_false(layout.is_placed(&"drying_rack"))
	assert_eq(layout.starts[&"granary"], rack, "The site takes the rack's space")
	_build(world, &"granary")
	assert_eq(LanePlacer.place(world).starts[&"granary"], rack, "And the granary keeps it")


func test_a_site_stands_where_its_building_will() -> void:
	var world: WorldState = _world(1)
	_build(world, &"field", false)
	var layout: LaneLayout = LanePlacer.place(world)
	assert_true(layout.is_placed(&"field"), "A building site has a space")
	var start: int = layout.starts[&"field"]
	_build(world, &"field")
	assert_eq(LanePlacer.place(world).starts[&"field"], start)


## Asserts no prop stands in a prop space that lies inside a building (the same building on both
## sides of the join), which would put it in front of that building's middle.
func _assert_between_buildings(layout: LaneLayout, label: String) -> void:
	var back: Dictionary = {}
	for key: StringName in layout.starts:
		if LanePieces.lane_of(key) != BACK:
			continue
		for at: int in range(int(layout.starts[key]), int(layout.starts[key]) + LanePieces.spaces_of(key)):
			back[at] = key
	for key: StringName in layout.starts:
		if LanePieces.lane_of(key) != MID:
			continue
		for at: int in range(int(layout.starts[key]), int(layout.starts[key]) + LanePieces.spaces_of(key)):
			assert_false(
				back.has(at) and back.has(at - 1) and back[at] == back[at - 1],
				"%s: %s stands in front of %s" % [label, key, back.get(at)]
			)


func test_props_stand_between_buildings_never_in_front_of_one() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var layout: LaneLayout = LanePlacer.place(_full_world(era_order))
		_assert_between_buildings(layout, "Age %d" % era_order)
		var props: int = 0
		for key: StringName in layout.starts:
			props += 1 if LanePieces.lane_of(key) == MID else 0
		assert_gt(props, 0, "Age %d still shows props" % era_order)


func test_a_building_that_arrives_over_a_prop_moves_it_aside() -> void:
	var world: WorldState = _world(1)
	_build(world, &"hut")
	world.flags[&"well_dug"] = true
	var first: LaneLayout = LanePlacer.place(world)
	_assert_between_buildings(first, "Hut and well")
	for id: StringName in [&"drying_rack", &"field", &"lookout"]:
		_build(world, id)
		_assert_between_buildings(LanePlacer.place(world), "After %s" % id)
	assert_true(LanePlacer.place(world).is_placed(&"west_well"), "The well, a need, still shows")


func test_a_building_the_age_has_outgrown_is_not_drawn_but_stays_built() -> void:
	var world: WorldState = _world(1)
	_build(world, &"knapping_spot")
	assert_true(LanePlacer.place(world).is_placed(&"knapping_spot"), "Stone tools in the Settled Age")
	world.era_order = 2
	assert_false(WorldLayout.building_shown(&"knapping_spot", world), "Metal has taken its place")
	assert_false(LanePlacer.place(world).is_placed(&"knapping_spot"))
	assert_true(world.has_building(&"knapping_spot"), "The sim still has it")


func test_the_quay_and_the_harbour_run_out_from_the_shore_they_stand_on() -> void:
	var world: WorldState = _world(4)
	_build(world, &"quay")
	world.achievements.append(&"wider_world")
	var layout: LaneLayout = LanePlacer.place(world)
	for key: StringName in [&"quay", &"east_harbour"]:
		assert_true(layout.is_placed(key), "%s has its spaces" % key)
		var layer: StringName = &"building_quay" if key == &"quay" else key
		var art: Rect2i = LanePieces.art_rect(layer, 4)
		var left: float = layout.sprite_x(key, art) + float(art.position.x)
		assert_eq(left, layout.span_left(key), "%s starts at the shore end of its spaces" % key)
	# The Quay's pier starts where it was drawn to meet the bank (x 317), give or take a pixel.
	var quay_art: Rect2i = LanePieces.art_rect(&"building_quay", 4)
	assert_true(
		absf(layout.sprite_x(&"quay", quay_art) + float(quay_art.position.x) - 317.0) <= 3.0,
		"The pier meets the bank"
	)


# ---- A full lane ------------------------------------------------------------------------------

## How many one-space pieces the building lane's ground holds with no crossing, in the Settled
## Age (when the mammoth is gone): the lane the synthetic tables below fill.
func _room() -> int:
	var room: int = 0
	for index: int in LaneSpaces.count(BACK):
		room += 1 if LaneSpaces.span_open(BACK, index, 1, LaneSpaces.GROUND, 1, false) else 0
	return room


## A table of `count` one-space ground pieces on the building lane, ranks in turn.
func _ground_table(count: int, ranks: Array[int]) -> Dictionary:
	var table: Dictionary = {}
	for index: int in count:
		table[StringName("piece_%d" % index)] = [BACK, 1, LaneSpaces.GROUND, ranks[index % ranks.size()]]
	return table


func _keys(table: Dictionary) -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: StringName in table:
		keys.append(key)
	return keys


func test_a_full_lane_hides_the_oldest_of_the_lowest_rank() -> void:
	var room: int = _room()
	var table: Dictionary = _ground_table(room + 1, [4])
	var order: Array[StringName] = _keys(table)
	var placed: Dictionary = LanePlacer.pack(table, order.slice(0, room), {}, order, 1, false)
	assert_eq(placed.size(), room, "Every space is taken")
	var all: Dictionary = LanePlacer.pack(table, order, placed, order, 1, false)
	assert_eq(all.size(), room, "One more does not make another space")
	assert_false(all.has(&"piece_0"), "The oldest gives way")
	assert_true(all.has(StringName("piece_%d" % room)), "The newest stays")
	for key: StringName in placed:
		if key != &"piece_0":
			assert_eq(all[key], placed[key], "%s keeps its space" % key)


func test_a_better_rank_takes_the_place_of_a_worse_one_and_never_the_other_way() -> void:
	var room: int = _room()
	var table: Dictionary = {}
	for index: int in room:
		table[StringName("flavour_%d" % index)] = [BACK, 1, LaneSpaces.GROUND, 4]
	table[&"answer"] = [BACK, 1, LaneSpaces.GROUND, 3]
	table[&"need"] = [BACK, 1, LaneSpaces.GROUND, 2]
	table[&"headline"] = [BACK, 1, LaneSpaces.GROUND, 1]
	var order: Array[StringName] = _keys(table)
	var wanted: Array[StringName] = order.slice(0, room)
	var placed: Dictionary = LanePlacer.pack(table, wanted, {}, order, 1, false)
	assert_eq(placed.size(), room)
	wanted.append(&"answer")
	placed = LanePlacer.pack(table, wanted, placed, order, 1, false)
	assert_true(placed.has(&"answer"), "A fork's scenery outranks flavour")
	assert_eq(placed.size(), room)
	wanted.append(&"need")
	placed = LanePlacer.pack(table, wanted, placed, order, 1, false)
	assert_true(placed.has(&"need") and placed.has(&"answer"))
	wanted.append(&"headline")
	placed = LanePlacer.pack(table, wanted, placed, order, 1, false)
	assert_true(placed.has(&"headline") and placed.has(&"need") and placed.has(&"answer"))
	var flavour: int = 0
	for key: StringName in placed:
		flavour += 1 if String(key).begins_with("flavour") else 0
	assert_eq(flavour, room - 3, "Only flavour gave way")
	# A flavour piece that arrives last finds the lane full of better ones and is the one hidden.
	var late: Dictionary = {}
	for index: int in room:
		late[StringName("need_%d" % index)] = [BACK, 1, LaneSpaces.GROUND, 2]
	late[&"flavour"] = [BACK, 1, LaneSpaces.GROUND, 4]
	var late_order: Array[StringName] = _keys(late)
	var none: Dictionary = LanePlacer.pack(late, late_order, {}, late_order, 1, false)
	assert_eq(none.size(), room)
	assert_false(none.has(&"flavour"), "The newest flavour is still below every need")


func test_ranks_one_and_two_are_never_hidden_while_a_run_of_flavour_can_make_room() -> void:
	var room: int = _room()
	var table: Dictionary = {}
	for index: int in room:
		table[StringName("flavour_%d" % index)] = [BACK, 1, LaneSpaces.GROUND, 4]
	table[&"hall"] = [BACK, 3, LaneSpaces.GROUND, 1]
	var order: Array[StringName] = _keys(table)
	var wanted: Array[StringName] = order.slice(0, room)
	var placed: Dictionary = LanePlacer.pack(table, wanted, {}, order, 1, false)
	wanted.append(&"hall")
	placed = LanePlacer.pack(table, wanted, placed, order, 1, false)
	assert_true(placed.has(&"hall"), "A headline piece finds three spaces together")
	assert_eq(placed.size(), room - 2, "...by hiding three flavour pieces")
	_assert_no_overlap(table, placed)


func _assert_no_overlap(table: Dictionary, placed: Dictionary) -> void:
	var used: Dictionary = {}
	for key: StringName in placed:
		for at: int in range(int(placed[key]), int(placed[key]) + int(table[key][1])):
			assert_false(used.has(at), "%s and %s share space %d" % [key, used.get(at), at])
			used[at] = key


func test_a_fragmented_lane_is_packed_again_rather_than_hide_a_need() -> void:
	# Needs of one space stand in every other space of the west village and the camp's two stretches,
	# so no run of three is free; a need of three must still show.
	var table: Dictionary = {}
	var ledger: Dictionary = {}
	var wanted: Array[StringName] = []
	var spots: Array[int] = [0, 2, 4, 6, 8, 10, 12, 17, 19, 21, 23]
	for index: int in spots.size():
		var key: StringName = StringName("need_%d" % index)
		table[key] = [BACK, 1, LaneSpaces.GROUND, 2]
		ledger[key] = spots[index]
		wanted.append(key)
	table[&"big_need"] = [BACK, 3, LaneSpaces.GROUND, 2]
	wanted.append(&"big_need")
	var order: Array[StringName] = _keys(table)
	var placed: Dictionary = LanePlacer.pack(table, wanted, ledger, order, 1, false)
	assert_true(placed.has(&"big_need"), "Fragmented, but it fits once packed again")
	assert_eq(placed.size(), spots.size() + 1, "Nothing was hidden")
	_assert_no_overlap(table, placed)


func test_restricted_spaces_refuse_the_wrong_piece() -> void:
	var table: Dictionary = {}
	for index: int in 5:
		table[StringName("boat_%d" % index)] = [MID, 1, LaneSpaces.DEEP, 3]
	table[&"house"] = [MID, 1, LaneSpaces.GROUND, 3]
	table[&"trap"] = [MID, 1, LaneSpaces.SHALLOWS, 3]
	var order: Array[StringName] = _keys(table)
	var placed: Dictionary = LanePlacer.pack(table, order, {}, order, 4, true)
	assert_eq(LaneSpaces.terrain(MID, int(placed[&"house"])), LaneSpaces.GROUND, "The house is on dry land")
	assert_eq(LaneSpaces.terrain(MID, int(placed[&"trap"])), LaneSpaces.SHALLOWS, "The trap is by the bank")
	var boats: int = 0
	for key: StringName in placed:
		if String(key).begins_with("boat"):
			boats += 1
			assert_eq(LaneSpaces.terrain(MID, int(placed[key])), LaneSpaces.DEEP, "%s is out on the water" % key)
	assert_eq(boats, 2, "The river has room for two boats; the others are not on land or the bank")


func test_an_unreachable_space_is_not_used_until_the_crossing_is_laid() -> void:
	var table: Dictionary = {}
	for index: int in 40:
		table[StringName("house_%d" % index)] = [BACK, 1, LaneSpaces.GROUND, 4]
	var order: Array[StringName] = _keys(table)
	var walled: Dictionary = LanePlacer.pack(table, order, {}, order, LAST_ERA, false)
	var crossed: Dictionary = LanePlacer.pack(table, order, {}, order, LAST_ERA, true)
	for key: StringName in walled:
		assert_true(
			LaneSpaces.left(BACK, int(walled[key])) < LaneSpaces.FAR_BANK_FROM,
			"%s stands past the river with no crossing" % key
		)
	assert_gt(crossed.size(), walled.size(), "The far bank counts once the crossing is laid")
	var beyond: int = 0
	for key: StringName in crossed:
		beyond += 1 if LaneSpaces.left(BACK, int(crossed[key])) >= LaneSpaces.FAR_BANK_FROM else 0
	assert_gt(beyond, 0)


func test_the_view_without_a_crossing_has_nothing_past_the_river() -> void:
	var world: WorldState = _full_world(LAST_ERA, false)
	var layout: LaneLayout = LanePlacer.place(world)
	for key: StringName in layout.starts:
		var lane: StringName = LanePieces.lane_of(key)
		assert_false(
			LaneSpaces.needs_crossing(lane, int(layout.starts[key])), "%s is out of reach" % key
		)


# ---- Saves, and what the view must not touch ---------------------------------------------------

func test_a_world_with_no_ledger_is_placed_the_same_way_every_time() -> void:
	for era_order: int in [1, 3, 4]:
		var first: LaneLayout = LanePlacer.place(_full_world(era_order))
		var second: LaneLayout = LanePlacer.place(_full_world(era_order))
		assert_eq(_spans(first), _spans(second), "Age %d" % era_order)
		assert_gt(first.starts.size(), 10)


func test_load_and_place_again_give_the_same_view() -> void:
	var world: WorldState = _world(3)
	for unlock: Callable in _unlocks(3):
		unlock.call(world)
		LanePlacer.place(world)
	var before: Dictionary = _spans(LanePlacer.place(world))
	assert_eq(SaveStore.save_world(world, SAVE_PATH), OK)
	var loaded: WorldState = SaveStore.load_world(SAVE_PATH)
	assert_true(loaded != null)
	assert_eq(loaded.lane_spaces, world.lane_spaces, "The spaces are saved")
	assert_eq(loaded.lane_order, world.lane_order, "...and the order they were earned in")
	assert_eq(_spans(LanePlacer.place(loaded)), before, "Placed again, the same view")


func test_an_older_save_with_no_ledger_places_and_then_keeps_what_it_placed() -> void:
	var world: WorldState = _full_world(3)
	assert_true(world.lane_spaces.is_empty())
	var layout: LaneLayout = LanePlacer.place(world)
	assert_false(world.lane_spaces.is_empty(), "It is remembered from then on")
	assert_eq(_spans(LanePlacer.place(world)), _spans(layout))


func test_what_the_view_hides_stays_in_the_world() -> void:
	var sim: Simulation = SimFixture.new_sim(7)
	var world: WorldState = sim.world
	world.era_order = LAST_ERA
	for unlock: Callable in _unlocks(LAST_ERA):
		unlock.call(world)
	var before: Dictionary = SimFixture.snapshot(world)
	var layout: LaneLayout = LanePlacer.place(world)
	var hidden: Array[StringName] = []
	for key: StringName in LanePlacer.wanted_keys(world):
		if not layout.is_placed(key):
			hidden.append(key)
	assert_eq(SimFixture.snapshot(world), before, "Placing changes nothing the sim knows")
	for key: StringName in hidden:
		if WorldLayout.BUILDINGS.has(key):
			assert_true(world.has_building(key), "%s is hidden, not gone" % key)
	for _round: int in 3:
		LanePlacer.place(world)
	assert_eq(SimFixture.snapshot(world), before)


func test_the_sim_plays_the_same_whether_or_not_the_view_places_things() -> void:
	var seen: Simulation = SimFixture.new_sim(11)
	var unseen: Simulation = SimFixture.new_sim(11)
	var bot: DecisionBot = DecisionBot.new()
	var bot_two: DecisionBot = DecisionBot.new()
	for _day: int in 40:
		for _tick: int in SimFixture.TICKS_PER_DAY:
			seen.advance_ticks(1)
			unseen.advance_ticks(1)
		bot.answer_all(seen)
		bot_two.answer_all(unseen)
		LanePlacer.place(seen.world)
	assert_false(seen.world.lane_spaces.is_empty(), "The view placed something")
	assert_eq(SimFixture.snapshot(seen.world), SimFixture.snapshot(unseen.world))


# ---- Villagers and the view ---------------------------------------------------------------------

func _villager(profession: StringName, activity: StringName) -> VillagerState:
	var villager: VillagerState = VillagerState.new()
	villager.id = &"v"
	villager.profession = profession
	villager.activity = activity
	return villager


func test_the_smith_hammers_in_front_of_wherever_the_smithy_stands() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var world: WorldState = sim.world
	world.era_order = 2
	_build(world, &"smithy")
	var layout: LaneLayout = LanePlacer.place(world)
	var planner: VillagerPlanner = VillagerPlanner.new()
	var plan: VillagerPlan = planner.plan(
		_villager(&"smith", VillagerState.ACTIVITY_GATHER_WOOD), world, sim.config, 0, layout
	)
	var center: float = layout.center_x(&"smithy")
	assert_eq(plan.focus_x, center, "They face the smithy")
	assert_true(absf(plan.target.x - center) <= 24.0, "They stand beside it")
	assert_eq(plan.pose, &"hammer")
	var home: VillagerPlan = planner.plan(
		_villager(&"smith", VillagerState.ACTIVITY_GATHER_WOOD), world, sim.config, 0
	)
	assert_eq(home.focus_x, float(WorldLayout.BUILDINGS[&"smithy"]["cx"]), "No layout, home slot")


func test_a_smith_whose_smithy_has_no_space_cuts_wood_instead() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var world: WorldState = sim.world
	world.era_order = 2
	_build(world, &"smithy")
	var plan: VillagerPlan = VillagerPlanner.new().plan(
		_villager(&"smith", VillagerState.ACTIVITY_GATHER_WOOD), world, sim.config, 0, LaneLayout.new()
	)
	assert_eq(plan.focus_x, WorldLayout.CHOP_X, "Nobody hammers at a smithy that is not drawn")


func test_the_trader_walks_to_where_the_market_and_the_post_stand() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var world: WorldState = sim.world
	world.era_order = 2
	_build(world, &"trading_post")
	world.flags[&"market_day"] = true
	var layout: LaneLayout = LanePlacer.place(world)
	var planner: VillagerPlanner = VillagerPlanner.new()
	var seen: Dictionary = {}
	for day: int in 2:
		world.tick = sim.config.ticks_per_day * day + sim.config.tick_for_hour(12)
		var plan: VillagerPlan = planner.plan(
			_villager(&"trader", VillagerState.ACTIVITY_WANDER), world, sim.config, 0, layout
		)
		seen[plan.focus_x] = true
		assert_true(
			plan.focus_x == layout.center_x(&"trading_post")
			or plan.focus_x == layout.center_x(&"market_stalls"), "They go to a place that is drawn"
		)
	assert_eq(seen.size(), 2, "Market and post on alternate days")
	var gone: VillagerPlan = planner.plan(
		_villager(&"trader", VillagerState.ACTIVITY_WANDER), world, sim.config, 0, LaneLayout.new()
	)
	assert_true(gone.wander, "With neither drawn, the trader wanders like anyone")


func test_builders_work_at_the_site_wherever_it_stands() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var world: WorldState = sim.world
	world.era_order = 1
	_build(world, &"hut")
	_build(world, &"field", false)
	var layout: LaneLayout = LanePlacer.place(world)
	var plan: VillagerPlan = VillagerPlanner.new().plan(
		_villager(&"", VillagerState.ACTIVITY_BUILD), world, sim.config, 0, layout
	)
	var center: float = layout.center_x(&"field")
	assert_eq(plan.focus_x, center)
	assert_true(plan.target.x < center and plan.target.x > center - 28.0, "In front, to one side")


func _view(sim: Simulation) -> WorldView:
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	return view


func test_the_view_centres_each_pieces_art_in_its_spaces() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.era_order = 3
	for unlock: Callable in _unlocks(3):
		unlock.call(sim.world)
	var view: WorldView = _view(sim)
	var checked: int = 0
	for id: StringName in view._buildings:
		var sprite: Sprite2D = view._buildings[id]
		if not sprite.visible:
			continue
		var layer: StringName = sprite.get_meta(&"layer")
		var art: Rect2i = LanePieces.art_rect(layer, 3)
		var left: float = sprite.position.x + float(art.position.x)
		var key: StringName = LanePieces.key_of(id)
		assert_true(left >= view._layout.span_left(key) - 0.5, "%s starts inside its spaces" % id)
		assert_true(
			left + float(art.size.x) <= view._layout.span_left(key) + view._layout.span_width(key) + 0.5,
			"%s ends inside them" % id
		)
		checked += 1
	assert_gt(checked, 3)
	for id: StringName in view._props:
		var prop: Sprite2D = view._props[id]
		if not prop.visible or not LanePieces.has(id) or SceneProps.PROPS[id].has("overlays"):
			continue
		var art: Rect2i = LanePieces.art_rect(id, 3)
		var key: StringName = LanePieces.key_of(id)
		assert_true(
			prop.position.x + float(art.position.x) >= view._layout.span_left(key) - 0.5,
			"%s starts inside its spaces" % id
		)
		assert_true(
			prop.position.x + float(art.end.x) <= view._layout.span_left(key) + view._layout.span_width(key) + 0.5,
			"%s ends inside them" % id
		)
	view.free()


func test_props_on_the_ground_and_shore_stand_on_one_row_above_the_lane_people_walk() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.era_order = LAST_ERA
	for unlock: Callable in _unlocks(LAST_ERA):
		unlock.call(sim.world)
	var view: WorldView = _view(sim)
	var aligned: int = 0
	for id: StringName in view._props:
		var sprite: Sprite2D = view._props[id]
		var key: StringName = LanePieces.key_of(id)
		if not sprite.visible or SceneProps.PROPS[id].has("overlays") or not LanePieces.is_on_prop_foot(key):
			continue
		var art: Rect2i = LanePieces.art_rect(id, LAST_ERA)
		assert_eq(int(sprite.position.y) + art.end.y - 1, WorldLayout.PROP_FOOT, "%s is on the prop row" % id)
		assert_true(sprite.z_index < WorldLayout.PROP_FOOT, "%s draws behind the villagers' lane" % id)
		aligned += 1
	assert_gt(aligned, 5, "Props and decor were checked")
	assert_true(WorldLayout.PROP_FOOT < 75 + 1 and WorldLayout.PROP_FOOT >= WorldLayout.BACK_LANE + 5, "Above the lane people walk")
	view.free()


## Whether the ground art shows water at a world x and row (the river, the sea).
func _is_water(x: int, row: int) -> bool:
	var page: StringName = &"ground"
	var left: int = 0
	if x < 0:
		page = &"west_ground"
		left = -384
	elif x >= 384:
		page = &"east_ground"
		left = 384
	var image: Image = (load(WorldLayout.piece_path(page, 0)) as Texture2D).get_image()
	var color: Color = image.get_pixelv(Vector2i(clampi(x - left, 0, image.get_width() - 1), row))
	return color.a > 0.5 and color.b > color.r + 0.3 and color.b > color.g + 0.1


func test_nothing_meant_for_dry_land_stands_in_the_river_or_the_sea() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var layout: LaneLayout = LanePlacer.place(_full_world(era_order))
		for key: StringName in layout.starts:
			var terrain: StringName = LanePieces.terrain_of(key)
			if terrain != LaneSpaces.GROUND and terrain != LaneSpaces.SHORE:
				continue
			var row: int = WorldLayout.BACK_LANE if LanePieces.lane_of(key) == BACK else WorldLayout.PROP_FOOT
			var from: int = int(layout.span_left(key))
			for x: int in range(from, from + int(layout.span_width(key))):
				assert_false(
					_is_water(x, row), "Age %d: %s stands in the water at x %d" % [era_order, key, x]
				)


func test_a_ground_zone_is_dry_land_at_its_own_row() -> void:
	# The zones are fitted to the art; if the art moves, this says which space went into the water.
	for lane: StringName in LaneSpaces.LANES:
		var row: int = WorldLayout.BACK_LANE if lane == BACK else WorldLayout.PROP_FOOT
		for index: int in LaneSpaces.count(lane):
			var kind: StringName = LaneSpaces.terrain(lane, index)
			if kind != LaneSpaces.GROUND and kind != LaneSpaces.SHORE:
				continue
			for x: int in range(LaneSpaces.left(lane, index), LaneSpaces.left(lane, index) + LaneSpaces.WIDTH):
				assert_false(_is_water(x, row), "%s space %d (%s) is in the water at x %d" % [lane, index, kind, x])


func test_every_prop_and_building_stays_off_the_water_it_does_not_belong_in() -> void:
	# Boats and the harbour are the only pieces that stand in the water.
	for key: StringName in LanePieces.TABLE:
		var terrain: StringName = LanePieces.terrain_of(key)
		var in_water: bool = [
			LaneSpaces.SHALLOWS, LaneSpaces.DEEP, LaneSpaces.COAST, LaneSpaces.SEA, LaneSpaces.FLATS
		].has(terrain)
		if in_water:
			assert_true([
				&"quay", &"river_trap", &"flax_thread", &"boat_dugout", &"quay_boats", &"east_harbour",
				&"east_sail", &"east_deep_ship", &"east_tide_weir",
			].has(key), "%s is not a piece for the water" % key)


func test_a_piece_the_view_has_no_space_for_is_not_drawn_and_the_sim_keeps_it() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.era_order = 0
	# Five more huts than the cave's camp has ground for are not a thing the sim would build, so
	# the table gets a small lane instead: the view and the placer agree on what is drawn.
	_build(sim.world, &"hut")
	_build(sim.world, &"drying_rack")
	_build(sim.world, &"lookout")
	var view: WorldView = _view(sim)
	for id: StringName in [&"hut", &"drying_rack", &"lookout"]:
		assert_eq((view._buildings[id] as Sprite2D).visible, view._layout.is_placed(id), id)
	sim.world.era_order = 1
	for flag: StringName in [&"path_herding"]:
		sim.world.flags[flag] = true
	sim.world.achievements.append(&"a_village")
	_build(sim.world, &"field")
	view.on_world_changed()
	var drawn: int = 0
	for id: StringName in LanePlacer.wanted_keys(sim.world):
		if WorldLayout.BUILDINGS.has(id):
			drawn += 1 if (view._buildings[id] as Sprite2D).visible else 0
			assert_eq(sim.world.has_building(id), true, "%s is still built" % id)
	assert_gt(drawn, 3)
	view.free()


func test_hover_and_the_click_region_follow_a_piece_to_its_space() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(12) + 24 * 3
	_build(sim.world, &"hut")
	var view: WorldView = _view(sim)
	for id: StringName in view._actors:
		(view._actors[id] as VillagerActor).position = Vector2(-300, 78)
	var sprite: Sprite2D = view._buildings[&"hut"]
	assert_true(sprite.visible)
	var art: Rect2i = LanePieces.art_rect(&"building_hut", 0)
	var spot: Vector2 = Vector2(
		sprite.position.x + float(art.position.x) + float(art.size.x) / 2.0,
		sprite.position.y + float(art.end.y) - 2.0
	)
	view.jump_camera(clampf(spot.x - 190.0, -384.0, 384.0))
	var hit: HoverHit = view.thing_at(Vector2(spot.x - float(view.camera_x()), spot.y))
	assert_true(hit != null and hit.key == &"building:hut", "The hut is named where it stands")
	var skyline: Skyline = Skyline.new(WorldLayout.WORLD_WIDTH, WorldLayout.VIEW_SIZE.y)
	skyline.add(sprite.texture, int(sprite.position.x) - WorldLayout.WORLD_LEFT, false, int(sprite.position.y))
	assert_true(
		skyline.tops[int(spot.x) - WorldLayout.WORLD_LEFT] < WorldLayout.VIEW_SIZE.y,
		"The hut is clickable where it stands"
	)
	view.free()


func test_the_east_lights_move_with_their_piece() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	sim.world.era_order = 3
	sim.world.tick = sim.config.tick_for_hour(0)
	sim.world.flags[&"beacon_lit"] = true
	var view: WorldView = _view(sim)
	var beacon: Sprite2D = view._props[&"east_beacon"]
	assert_true(beacon.visible)
	assert_eq(
		view._beacon_glow.position.x - float(WorldLayout.SIDE_PAGES["east_"]),
		beacon.position.x - SceneProps.at_x_of(&"east_beacon"),
		"The night light is drawn with the beacon, so it moves with it"
	)
	view.free()


func test_the_desktop_light_is_cut_off_above_the_skyline() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	sim.world.era_order = 4
	sim.world.tick = sim.config.tick_for_hour(0)
	sim.world.flags[&"beacon_lit"] = true
	sim.world.achievements.append(&"wider_world")
	var view: WorldView = _view(sim)
	view.set_full_scene(false)
	view.on_world_changed()
	var image: Image = view._beacon_glow.texture.get_image()
	var origin: int = int(view._beacon_glow.position.x) - WorldLayout.WORLD_LEFT
	var lit: int = 0
	var leaked: int = 0
	for x: int in image.get_width():
		for y: int in image.get_height():
			if image.get_pixel(x, y).a <= 0.0:
				continue
			lit += 1
			if y < view._skyline_tops[origin + x]:
				leaked += 1
	assert_gt(lit, 0, "The light still shines on what is drawn")
	assert_eq(leaked, 0, "No light above the skyline, where the desktop shows through")
	view.set_full_scene(true)
	assert_true(
		view._beacon_glow.texture.resource_path.contains("/classical/"),
		"The opaque window has its sky back, so the whole light"
	)
	view.free()


func test_a_beacon_still_standing_in_the_classical_age_keeps_its_own_light() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	sim.world.era_order = 4
	sim.world.tick = sim.config.tick_for_hour(0)
	sim.world.flags[&"beacon_lit"] = true
	var view: WorldView = _view(sim)
	assert_true(view._props[&"east_beacon"].visible, "No harbour yet, so the beacon still burns")
	assert_true(
		view._beacon_glow.texture.resource_path.contains("/iron/"),
		"Its light is the one drawn round the beacon, not the lighthouse's"
	)
	sim.world.achievements.append(&"wider_world")
	view.on_world_changed()
	assert_true(view._props[&"east_harbour"].visible, "The harbour is built")
	assert_true(
		view._beacon_glow.texture.resource_path.contains("/classical/"),
		"The lighthouse takes the light with the place"
	)
	view.free()
