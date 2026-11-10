extends McpTestSuite
## Keeping the world tidy (docs/ages.md B10): every prop belongs to a place and its art sits
## inside it, props do not pile on each other, a page is never crowded in any age, and an age can
## replace or retire what the last one built.

## The largest share of a prop's art another piece may cover (a hen in front of a doorstep).
const MAX_OVERLAP: float = 0.25
## Props shown on one page with everything unlocked (alternatives and overlays count once).
const PAGE_BUDGET: Dictionary = {-1: 14, 0: 9, 1: 8}
## An age may hold more on a page when it is that age's character to (docs/ages.md, flexible density per age):
## the Classical Age's east shore adds a theatre and a harbour in place of the ship.
const PAGE_BUDGET_BY_ERA: Dictionary = {4: {1: 9}}
const LAST_ERA: int = 4
## The cave's own dressing shown at once (the pennant).
const MAX_CAVE_DRESSING: int = 1


func suite_name() -> String:
	return "scene_props"


## A world in era `era_order` that holds everything a prop can wait for.
func _everything_unlocked(era_order: int) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	for id: StringName in SceneProps.ids():
		var spec: Dictionary = SceneProps.PROPS[id]
		if spec["kind"] == SceneProps.Kind.FLAG:
			world.flags[spec["key"]] = true
		elif spec["kind"] == SceneProps.Kind.ACHIEVEMENT:
			world.achievements.append(spec["key"])
		elif spec["kind"] == SceneProps.Kind.BUILDING:
			var building: BuildingState = BuildingState.new()
			building.def_id = spec["key"]
			building.complete = true
			world.buildings.append(building)
	return world


## Where a piece's drawn pixels are in camp pixels, in the newest art the age has for it. `at` is
## where its sprite's top-left corner sits.
func _used_rect(layer: StringName, era_order: int, at: Vector2) -> Rect2:
	var path: String = WorldLayout.piece_path(layer, era_order)
	if path.is_empty():
		return Rect2()
	var texture: Texture2D = load(path) as Texture2D
	assert_true(texture != null, "No art for %s" % layer)
	if texture == null:
		return Rect2()
	var used: Rect2i = texture.get_image().get_used_rect()
	return Rect2(Vector2(used.position) + at, Vector2(used.size))


func _at_of(id: StringName) -> Vector2:
	return Vector2(SceneProps.at_x_of(id), SceneProps.at_y_of(id))


func _art_rect(id: StringName, era_order: int) -> Rect2:
	return _used_rect(id, era_order, _at_of(id))


func _overlap_share(a: Rect2, b: Rect2) -> float:
	var common: Rect2 = a.intersection(b)
	if a.get_area() <= 0.0 or common.get_area() <= 0.0:
		return 0.0
	return common.get_area() / minf(a.get_area(), b.get_area())


## The share of the smaller piece's drawn pixels that the other covers: art is rarely a full
## rectangle, so this is the fair test once the rectangles overlap.
func _pixel_share(a_layer: StringName, a_at: Vector2, b_layer: StringName, b_at: Vector2, era: int) -> float:
	var a_path: String = WorldLayout.piece_path(a_layer, era)
	var b_path: String = WorldLayout.piece_path(b_layer, era)
	if a_path.is_empty() or b_path.is_empty():
		return 0.0
	var a: Image = (load(a_path) as Texture2D).get_image()
	var b: Image = (load(b_path) as Texture2D).get_image()
	var offset: Vector2i = Vector2i(a_at - b_at)
	var a_count: int = 0
	var b_count: int = 0
	var both: int = 0
	for y: int in a.get_height():
		for x: int in a.get_width():
			var a_solid: bool = a.get_pixel(x, y).a > 0.05
			var bx: int = x + offset.x
			var by: int = y + offset.y
			var b_solid: bool = (
				bx >= 0 and bx < b.get_width() and by >= 0 and by < b.get_height()
				and b.get_pixel(bx, by).a > 0.05
			)
			a_count += 1 if a_solid else 0
			both += 1 if a_solid and b_solid else 0
	for y: int in b.get_height():
		for x: int in b.get_width():
			b_count += 1 if b.get_pixel(x, y).a > 0.05 else 0
	if a_count == 0 or b_count == 0:
		return 0.0
	return float(both) / float(mini(a_count, b_count))


func _root(id: StringName) -> StringName:
	var spec: Dictionary = SceneProps.PROPS[id]
	if spec.has("alt_of"):
		return _root(spec["alt_of"])
	if spec.has("overlays"):
		return _root(spec["overlays"])
	return id


## Alternatives and overlays are meant to share ground.
func _related(a: StringName, b: StringName) -> bool:
	return _root(a) == _root(b)


func _page_of(id: StringName) -> int:
	var place: Rect2 = WorldLayout.PLACES.get(SceneProps.place_of(id), Rect2())
	return int(floor(place.position.x / 384.0))


func test_every_prop_belongs_to_a_place() -> void:
	for id: StringName in SceneProps.ids():
		assert_true(
			WorldLayout.PLACES.has(SceneProps.place_of(id)),
			"%s has no known place (%s)" % [id, SceneProps.place_of(id)]
		)


func test_places_do_not_overlap() -> void:
	var ids: Array = WorldLayout.PLACES.keys()
	for i: int in ids.size():
		for j: int in range(i + 1, ids.size()):
			var a: Rect2 = WorldLayout.PLACES[ids[i]]
			var b: Rect2 = WorldLayout.PLACES[ids[j]]
			assert_false(a.intersects(b), "%s and %s overlap" % [ids[i], ids[j]])


func test_a_props_art_sits_inside_its_place_in_every_age() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var world: WorldState = _everything_unlocked(era_order)
		for id: StringName in SceneProps.shown(world):
			var place: Rect2 = WorldLayout.PLACES.get(SceneProps.place_of(id), Rect2())
			var art: Rect2 = _art_rect(id, era_order)
			if art.get_area() <= 0.0:
				continue
			assert_true(
				place.encloses(art), "%s (age %d) is drawn at %s, outside %s %s" % [
					id, era_order, art, SceneProps.place_of(id), place
				]
			)


func test_props_shown_together_do_not_pile_on_each_other() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var shown: Array[StringName] = SceneProps.shown(_everything_unlocked(era_order))
		for i: int in shown.size():
			for j: int in range(i + 1, shown.size()):
				if _related(shown[i], shown[j]):
					continue
				var a: Dictionary = SceneProps.PROPS[shown[i]]
				var b: Dictionary = SceneProps.PROPS[shown[j]]
				if a.has("behind") or b.has("behind"):
					continue
				var share: float = _overlap_share(
					_art_rect(shown[i], era_order), _art_rect(shown[j], era_order)
				)
				if share > MAX_OVERLAP:
					share = _pixel_share(
						shown[i], _at_of(shown[i]), shown[j], _at_of(shown[j]), era_order
					)
				assert_true(
					share <= MAX_OVERLAP, "Age %d: %s and %s cover each other (%d%%)" % [
						era_order, shown[i], shown[j], int(share * 100.0)
					]
				)


func test_the_coin_tray_stands_clear_of_every_market_piece() -> void:
	var world: WorldState = _everything_unlocked(LAST_ERA)
	var tray: Rect2 = _art_rect(&"coin_tray", LAST_ERA)
	assert_true(tray.get_area() > 0.0, "The coin tray has art")
	for other: StringName in [
		&"market_stalls", &"council_ring", &"tally_post", &"writing_post", &"cart", &"donkeys",
	]:
		var share: float = _overlap_share(tray, _art_rect(other, LAST_ERA))
		assert_true(
			share <= 0.0 or not SceneProps.shown(world).has(other),
			"The coin tray lies on %s (%d%%)" % [other, int(share * 100.0)]
		)


func test_a_prop_does_not_stand_on_a_building_unless_it_is_behind_it() -> void:
	for era_order: int in range(LAST_ERA + 1):
		for id: StringName in SceneProps.shown(_everything_unlocked(era_order)):
			var art: Rect2 = _art_rect(id, era_order)
			for building_id: StringName in WorldLayout.BUILDINGS:
				if SceneProps.z_of(id) < int(WorldLayout.BUILDINGS[building_id]["z"]):
					continue
				for prefix: String in ["building_", "site_"]:
					var piece: Rect2 = _used_rect(
						StringName(prefix + building_id), era_order,
						WorldLayout.building_offset(building_id)
					)
					assert_true(
						_overlap_share(art, piece) <= MAX_OVERLAP,
						"Age %d: %s stands on %s%s" % [era_order, id, prefix, building_id]
					)


func test_no_page_is_crowded_in_any_age_once_everything_is_unlocked() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var counted: Dictionary = {}
		var dressing: int = 0
		for id: StringName in SceneProps.shown(_everything_unlocked(era_order)):
			var spec: Dictionary = SceneProps.PROPS[id]
			if spec["kind"] == SceneProps.Kind.ALWAYS:
				# The cave's own door and marks sit on the cliff's face, not on the ground the
				# budget protects; they have their own cap below.
				dressing += 1
				continue
			if spec.has("alt_of") or spec.has("overlays") or spec.get("ground", false):
				continue
			var page: int = _page_of(id)
			counted[page] = int(counted.get(page, 0)) + 1
		assert_true(dressing <= MAX_CAVE_DRESSING, "Age %d: the cave shows %d pieces" % [era_order, dressing])
		for page: int in counted:
			assert_true(
				int(counted[page]) <= _budget(era_order, page),
				"Age %d, page %d shows %d props (at most %d)" % [
					era_order, page, counted[page], _budget(era_order, page)
				]
			)


func _budget(era_order: int, page: int) -> int:
	var by_era: Dictionary = PAGE_BUDGET_BY_ERA.get(era_order, {})
	return int(by_era.get(page, PAGE_BUDGET.get(page, 0)))


func test_the_bronze_age_simplifies_what_the_settled_age_scattered() -> void:
	var settled: Array[StringName] = SceneProps.shown(_everything_unlocked(1))
	var bronze: Array[StringName] = SceneProps.shown(_everything_unlocked(2))
	for old: StringName in [
		&"pots", &"west_kiln", &"clay_pits", &"loom", &"cloth_line",
		&"hens", &"west_pen",
	]:
		assert_true(settled.has(old), "%s stands in the Settled Age" % old)
		assert_false(bronze.has(old), "%s is folded into a yard in the Bronze Age" % old)
	for tidy: StringName in [
		&"potters_yard", &"weavers_row", &"town_wall", &"crossing_planks", &"quay_boats",
		&"farmstead_herd",
	]:
		assert_false(settled.has(tidy), "%s waits for the Bronze Age" % tidy)
		assert_true(bronze.has(tidy), "%s is the Bronze Age's" % tidy)
	assert_false(bronze.has(&"low_wall"), "The town wall replaces the low wall")
	assert_false(bronze.has(&"green_stones"), "The green stone is put away in the Bronze Age")
	for afloat: StringName in [&"boat_dugout", &"boat_raft", &"river_trap", &"crossing_stones"]:
		assert_false(bronze.has(afloat), "%s gives way to the quay and the bridge" % afloat)


func test_the_iron_age_redraws_the_wall_the_tally_and_the_ship() -> void:
	var bronze: Array[StringName] = SceneProps.shown(_everything_unlocked(2))
	var iron: Array[StringName] = SceneProps.shown(_everything_unlocked(3))
	for old: StringName in [&"town_wall", &"low_wall", &"tally_post", &"east_sail"]:
		assert_false(iron.has(old), "%s gives way to the Iron Age's piece" % old)
	for tidy: StringName in [&"rampart", &"writing_post", &"east_deep_ship"]:
		assert_false(bronze.has(tidy), "%s waits for the Iron Age" % tidy)
		assert_true(iron.has(tidy), "%s is the Iron Age's" % tidy)
	for fresh: StringName in [
		&"slag_heap", &"shearing_pen", &"coin_tray", &"standing_stone",
		&"east_beacon",
	]:
		assert_false(bronze.has(fresh), "%s waits for the Iron Age" % fresh)
		assert_true(iron.has(fresh), "%s is the Iron Age's" % fresh)
	for kept: StringName in [&"market_stalls", &"council_ring", &"cart", &"donkeys", &"quay_boats"]:
		assert_true(iron.has(kept), "%s stays in the Iron Age" % kept)
	for tidy: StringName in [
		&"potters_yard", &"weavers_row", &"crossing_planks", &"farmstead_herd",
	]:
		assert_true(iron.has(tidy), "The Bronze Age's %s stays" % tidy)
	for folded: StringName in [
		&"pots", &"west_kiln", &"clay_pits", &"loom", &"cloth_line", &"hens",
		&"west_pen", &"green_stones", &"boat_dugout", &"crossing_stones",
	]:
		assert_false(iron.has(folded), "%s stays folded away in the Iron Age" % folded)


const CAVE_PENNANT: StringName = &"cave_standard_cave"
## The colour of the cave's opening in the cliff art (tools/art/lib.js cliff()).
const MOUTH_DARK: Color = Color("2a2433")
## Where the pennant's pole stands on the cliff's top edge.
const STANDARD_POLE_X: int = 26
## The signature building's footprint, the cave's own (WorldLandmarks, tools/art/signature_landmarks.js),
## and where a doorway opens in it: the group gathers there.
const SIGNATURE_FOOTPRINT: Rect2 = Rect2(0, 10, 102, 58)
const DOORWAY_X: int = 34


func _empty_world(era_order: int) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	return world


func _back(era_order: int) -> Image:
	return (load(WorldLayout.piece_path(&"static_back", era_order)) as Texture2D).get_image()


func test_the_first_age_shows_only_the_caves_own_pennant() -> void:
	assert_eq(
		SceneProps.shown(_empty_world(0)), [CAVE_PENNANT] as Array[StringName],
		"The Cave Age's cave has its pennant and nothing else"
	)


func test_the_pennant_goes_when_the_cliff_does() -> void:
	for era_order: int in range(1, LAST_ERA + 1):
		assert_true(
			SceneProps.shown(_empty_world(era_order)).is_empty(),
			"Age %d: a world with nothing earned shows no dressing on the signature building" % era_order
		)


func test_the_cave_shows_only_because_the_age_turned() -> void:
	for id: StringName in SceneProps.shown(_empty_world(0)):
		assert_eq(SceneProps.PROPS[id]["kind"], SceneProps.Kind.ALWAYS, "%s waits for nothing" % id)


func test_every_age_after_the_cave_draws_its_own_signature_building() -> void:
	var cave: Image = _back(0)
	for era_order: int in range(1, LAST_ERA + 1):
		var age: String = WorldLayout.ERA_DIRS[era_order]
		var path: String = WorldLayout.piece_path(&"static_back", era_order)
		assert_true(path.contains("/%s/" % age), "%s draws its own landmark (%s)" % [age, path])
		var back: Image = _back(era_order)
		assert_ne(back.get_data(), cave.get_data(), "%s's landmark is not the cave's cliff" % age)
		for frame: int in WorldLayout.FIRE_FRAMES:
			var fire_path: String = WorldLayout.piece_path(WorldLayout.fire_frame_name(frame), era_order)
			assert_true(fire_path.contains("/%s/" % age), "%s has its own fire pit %d" % [age, frame])


func test_each_signature_stays_in_the_caves_footprint_and_keeps_the_pine() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var back: Image = _back(era_order)
		var building: Rect2i = Rect2i()
		var x_first: int = back.get_width()
		var x_last: int = -1
		var y_first: int = back.get_height()
		for y: int in back.get_height():
			for x: int in 150:
				if back.get_pixel(x, y).a > 0.5:
					x_first = mini(x_first, x)
					x_last = maxi(x_last, x)
					y_first = mini(y_first, y)
		building = Rect2i(x_first, y_first, x_last - x_first + 1, 66 - y_first)
		assert_true(
			SIGNATURE_FOOTPRINT.encloses(Rect2(building)),
			"Age %d: the signature is drawn at %s, outside %s" % [era_order, building, SIGNATURE_FOOTPRINT]
		)
		var kept: Array[StringName] = [&"pine"]
		if era_order == 0:
			kept.append(&"mammoth")
		for landmark: StringName in kept:
			var solid: bool = false
			for rect: Rect2 in WorldLandmarks.LANDMARKS[landmark]["rects"]:
				for y: int in range(int(rect.position.y), int(rect.end.y)):
					for x: int in range(int(rect.position.x), int(rect.end.x)):
						if back.get_pixel(x, y).a > 0.5:
							solid = true
			assert_true(solid, "Age %d keeps the %s" % [era_order, landmark])


func test_the_mammoth_is_the_cave_ages_alone() -> void:
	for era_order: int in range(1, LAST_ERA + 1):
		var back: Image = _back(era_order)
		for rect: Rect2 in WorldLandmarks.LANDMARKS[&"mammoth"]["rects"]:
			for y: int in range(int(rect.position.y), int(rect.end.y)):
				for x: int in range(int(rect.position.x), int(rect.end.x)):
					assert_true(back.get_pixel(x, y).a < 0.5, "Age %d still draws the mammoth at %d,%d" % [era_order, x, y])


## The Bloomery stands against the landmark's flank from x 73, so a later age's building ends before it.
func test_the_signature_leaves_the_flank_to_the_bloomery() -> void:
	var bloomery_left: int = WorldLayout.BUILDINGS[&"bloomery"]["cx"] - 12
	for era_order: int in [3, 4]:
		var back: Image = _back(era_order)
		var right: int = 0
		for y: int in 62:
			for x: int in range(0, 150):
				if back.get_pixel(x, y).a > 0.5:
					right = maxi(right, x)
		# the lone pine stands at x 196+, so the first 150 columns are the building alone (above its shadow)
		assert_true(right < bloomery_left, "Age %d: the building reaches x %d, under the Bloomery (%d)" % [era_order, right, bloomery_left])


func test_each_signature_opens_a_doorway_where_the_group_gathers() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var back: Image = _back(era_order)
		var dark: int = 0
		for y: int in range(56, 65):
			var pixel: Color = back.get_pixel(DOORWAY_X, y)
			if pixel.a > 0.5 and pixel.v < 0.4:
				dark += 1
		assert_gt(dark, 4, "Age %d: a doorway stands open at column %d" % [era_order, DOORWAY_X])


func test_the_signature_fire_pit_has_no_firelight_in_the_wall() -> void:
	for era_order: int in range(1, LAST_ERA + 1):
		for frame: int in WorldLayout.FIRE_FRAMES:
			var fire: Image = (
				load(WorldLayout.piece_path(WorldLayout.fire_frame_name(frame), era_order)) as Texture2D
			).get_image()
			var used: Rect2i = fire.get_used_rect()
			assert_true(
				float(used.position.x) >= WorldLayout.FIRE_HIT.position.x - 4.0,
				"Age %d fire %d lights the wall at x %d" % [era_order, frame, used.position.x]
			)


func test_the_signature_is_inside_the_skyline() -> void:
	for era_order: int in range(LAST_ERA + 1):
		var skyline: Skyline = Skyline.new(384, WorldLayout.VIEW_SIZE.y)
		skyline.add(load(WorldLayout.piece_path(&"static_back", era_order)) as Texture2D, 0)
		assert_true(skyline.tops[DOORWAY_X] < 56, "Age %d: the landmark is clickable at the door" % era_order)


func test_the_pennant_stands_on_the_cliffs_top_and_stays_small() -> void:
	var cliff: Image = _back(0)
	var art: Image = (load(WorldLayout.piece_path(CAVE_PENNANT, 0)) as Texture2D).get_image()
	var used: Rect2i = art.get_used_rect()
	assert_true(used.size.x <= 12 and used.size.y <= 22, "The pennant is %s, too big" % used.size)
	var base: int = -1
	for y: int in range(art.get_height() - 1, -1, -1):
		if art.get_pixel(STANDARD_POLE_X, y).a > 0.5:
			base = y
			break
	assert_true(base >= 0, "The pennant has no pole")
	assert_true(cliff.get_pixel(STANDARD_POLE_X, base).a > 0.5, "The pennant does not stand on the rock")

func test_the_classical_age_folds_the_market_the_well_the_road_and_the_ship() -> void:
	var iron: Array[StringName] = SceneProps.shown(_everything_unlocked(3))
	var classical: Array[StringName] = SceneProps.shown(_everything_unlocked(4))
	for old: StringName in [
		&"market_stalls", &"council_ring", &"writing_post", &"coin_tray", &"west_well",
		&"road_camp", &"east_deep_ship", &"east_beacon", &"cart", &"donkeys",
	]:
		assert_true(iron.has(old), "%s stands in the Iron Age" % old)
		assert_false(classical.has(old), "%s is folded into the Classical Age's piece" % old)
	for fresh: StringName in [
		&"paved_street", &"water_court", &"market_arcade", &"east_theatre", &"east_harbour",
	]:
		assert_false(iron.has(fresh), "%s waits for the Classical Age" % fresh)
		assert_true(classical.has(fresh), "%s is the Classical Age's" % fresh)
	for kept: StringName in [&"rampart", &"standing_stone"]:
		assert_true(classical.has(kept), "%s stays in the Classical Age" % kept)


func test_the_law_pillar_stands_until_the_square_takes_it_in() -> void:
	var world: WorldState = _empty_world(4)
	world.achievements.append(&"written_law")
	assert_true(SceneProps.is_shown(&"law_pillar", world))
	assert_false(SceneProps.is_shown(&"market_arcade", world), "The square is not earned yet")
	world.achievements.append(&"the_square")
	assert_false(SceneProps.is_shown(&"law_pillar", world), "The arcade takes the pillar in")
	assert_true(SceneProps.is_shown(&"market_arcade", world))


func test_a_classical_piece_is_shown_only_for_what_was_earned() -> void:
	for row: Array in [
		[&"paved_street", &"paved_streets"], [&"water_court", &"water_from_afar"],
		[&"law_pillar", &"written_law"], [&"market_arcade", &"the_square"],
		[&"east_theatre", &"lamp_and_stage"], [&"east_harbour", &"wider_world"],
	]:
		var world: WorldState = _empty_world(4)
		assert_false(SceneProps.is_shown(row[0], world), "%s waits for %s" % [row[0], row[1]])
		world.achievements.append(row[1])
		assert_true(SceneProps.is_shown(row[0], world))
		assert_false(SceneProps.is_shown(row[0], _world_with(&"x", 3)), "...and for the age")


func test_the_granary_takes_the_racks_ground_and_never_stands_on_the_field() -> void:
	var world: WorldState = _empty_world(3)
	var rack: BuildingState = BuildingState.new()
	rack.def_id = &"drying_rack"
	rack.complete = true
	world.buildings.append(rack)
	assert_true(WorldLayout.building_shown(&"drying_rack", world))
	var granary: BuildingState = BuildingState.new()
	granary.def_id = &"granary"
	granary.complete = false
	world.buildings.append(granary)
	assert_false(WorldLayout.building_shown(&"drying_rack", world), "The site already stands on its ground")
	granary.complete = true
	assert_false(WorldLayout.building_shown(&"drying_rack", world), "The granary takes its place")
	assert_true(WorldLayout.building_shown(&"granary", world))
	var field: Rect2 = _used_rect(&"building_field", 3, WorldLayout.building_offset(&"field"))
	var store: Rect2 = _used_rect(&"building_granary", 3, WorldLayout.building_offset(&"granary"))
	assert_false(field.intersects(store), "The granary %s stands on the field %s" % [store, field])


func test_the_theatre_stands_on_the_back_lane_and_the_harbour_touches_the_shore() -> void:
	var theatre: Rect2 = _art_rect(&"east_theatre", 4)
	assert_true(absf(theatre.end.y - float(WorldLayout.BACK_LANE)) <= 2.0, "The theatre's foot is %s" % theatre.end.y)
	var harbour: Rect2 = _art_rect(&"east_harbour", 4)
	# The beach ends at about x 622 (the east page's x 238); the mole starts there and runs out to sea.
	assert_true(
		harbour.position.x >= 384.0 + 225.0 and harbour.position.x <= 384.0 + 250.0,
		"The harbour starts at %s, not at the shore" % harbour.position.x
	)


func test_the_paved_street_runs_from_the_west_edge_to_the_bridge() -> void:
	var world: WorldState = _empty_world(4)
	world.achievements.append(&"paved_streets")
	var pieces: Array[StringName] = [
		&"paved_street_market", &"paved_street_west", &"paved_street_hall", &"paved_street",
		&"paved_street_bank",
	]
	var rects: Array[Rect2] = []
	for id: StringName in pieces:
		assert_true(SceneProps.is_shown(id, world), "%s is shown with the streets" % id)
		assert_true(SceneProps.PROPS[id].get("ground", false), "%s lies flat on the ground" % id)
		rects.append(_art_rect(id, 4))
	assert_true(rects[0].position.x <= -383.0, "It starts at the west edge: %s" % rects[0].position.x)
	assert_true(rects[4].end.x >= 300.0, "It reaches the bridge: %s" % rects[4].end.x)
	for i: int in range(rects.size() - 1):
		assert_true(absf(rects[i].end.x - rects[i + 1].position.x) <= 1.0, "A gap in the street after %s" % pieces[i])


func test_the_lighthouse_takes_the_beacons_place_and_the_market_takes_the_cart() -> void:
	var world: WorldState = _empty_world(4)
	for flag: StringName in [&"beacon_lit", &"cart", &"donkeys"]:
		world.flags[flag] = true
	assert_true(SceneProps.is_shown(&"east_beacon", world), "The beacon burns until the harbour is built")
	assert_true(SceneProps.is_shown(&"cart", world))
	world.achievements.append_array([&"wider_world", &"the_square"])
	assert_false(SceneProps.is_shown(&"east_beacon", world), "The lighthouse lights the shore")
	assert_false(SceneProps.is_shown(&"cart", world), "The arcade takes in the cart")
	assert_false(SceneProps.is_shown(&"donkeys", world))
	var glow: String = WorldLayout.piece_path(WorldLayout.BEACON_GLOW, 4)
	assert_true(glow.contains("/classical/"), "The lighthouse has its own night light")
	assert_true(WorldLayout.piece_path(WorldLayout.BEACON_GLOW, 3).contains("/iron/"))

func test_the_low_wall_gives_way_to_either_wall() -> void:
	var world: WorldState = _world_with(&"low_wall", 3)
	assert_true(SceneProps.is_shown(&"low_wall", world))
	world.flags[&"town_wall"] = true
	assert_false(SceneProps.is_shown(&"low_wall", world), "The town wall replaces it")
	assert_true(SceneProps.is_shown(&"town_wall", world))
	world.flags[&"hill_fort"] = true
	assert_false(SceneProps.is_shown(&"low_wall", world), "And so does the rampart")
	assert_false(SceneProps.is_shown(&"town_wall", world), "The rampart redraws the town wall")
	assert_true(SceneProps.is_shown(&"rampart", world))


func test_every_link_between_props_points_at_a_prop() -> void:
	for id: StringName in SceneProps.ids():
		var spec: Dictionary = SceneProps.PROPS[id]
		for field: String in ["alt_of", "overlays"]:
			if spec.has(field):
				assert_true(SceneProps.PROPS.has(spec[field]), "%s: %s is not a prop" % [id, field])
				assert_true(spec[field] != id, "%s points at itself" % id)
		for replacer: StringName in SceneProps.replacements_of(spec):
			assert_true(SceneProps.PROPS.has(replacer), "%s: %s is not a prop" % [id, replacer])
			assert_true(replacer != id, "%s points at itself" % id)


func _world_with(flag: StringName, era_order: int) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	world.flags[flag] = true
	return world


func test_a_replaced_prop_is_hidden_while_its_replacement_is_shown() -> void:
	var props: Dictionary = {
		&"old": {"kind": SceneProps.Kind.FLAG, "key": &"a", "replaced_by": &"new"},
		&"new": {"kind": SceneProps.Kind.FLAG, "key": &"b"},
	}
	var world: WorldState = _world_with(&"a", 0)
	assert_true(SceneProps.is_shown_in(props, &"old", world), "Shown until replaced")
	world.flags[&"b"] = true
	assert_false(SceneProps.is_shown_in(props, &"old", world), "Hidden once replaced")
	assert_true(SceneProps.is_shown_in(props, &"new", world))


func test_a_retired_prop_is_hidden_from_its_era_on() -> void:
	var props: Dictionary = {
		&"gone": {"kind": SceneProps.Kind.FLAG, "key": &"a", "until_era": 2},
	}
	assert_true(SceneProps.is_shown_in(props, &"gone", _world_with(&"a", 1)))
	assert_false(SceneProps.is_shown_in(props, &"gone", _world_with(&"a", 2)))
	assert_false(SceneProps.is_shown_in(props, &"gone", _world_with(&"a", 3)))


func test_a_prop_waits_for_its_era() -> void:
	var props: Dictionary = {
		&"later": {"kind": SceneProps.Kind.FLAG, "key": &"a", "from_era": 2},
	}
	assert_false(SceneProps.is_shown_in(props, &"later", _world_with(&"a", 1)))
	assert_true(SceneProps.is_shown_in(props, &"later", _world_with(&"a", 2)))


const ROAD: Array[StringName] = [
	&"road_market", &"road_west", &"road_hall", &"road_camp", &"road_bank",
]
const STREET: Array[StringName] = [
	&"paved_street_market", &"paved_street_west", &"paved_street_hall", &"paved_street",
	&"paved_street_bank",
]


func test_the_road_runs_from_the_west_edge_to_the_bridge_and_the_street_takes_it_in() -> void:
	var world: WorldState = _empty_world(2)
	assert_false(SceneProps.is_shown(&"road_camp", world), "No road until it is laid")
	world.flags[&"road_laid"] = true
	var covered: Dictionary = {}
	for id: StringName in ROAD:
		assert_true(SceneProps.is_shown(id, world), "%s is laid" % id)
		var art: Rect2 = _art_rect(id, 2)
		for x: int in range(int(art.position.x), int(art.end.x)):
			covered[x] = true
	for x: int in range(WorldLayout.WORLD_LEFT, int(WorldLayout.CROSSING_X.x)):
		assert_true(covered.has(x), "The road is missing at x %d" % x)
	# Each stretch of road gives way to the Classical street over the same ground.
	world.era_order = 4
	world.achievements.append(&"paved_streets")
	for index: int in ROAD.size():
		assert_false(SceneProps.is_shown(ROAD[index], world), "%s is paved over" % ROAD[index])
		assert_true(SceneProps.is_shown(STREET[index], world))
		assert_true(
			_art_rect(ROAD[index], 2).position.x <= _art_rect(STREET[index], 4).position.x + 1.0
			and _art_rect(ROAD[index], 2).end.x >= _art_rect(STREET[index], 4).end.x - 1.0,
			"%s is under %s" % [ROAD[index], STREET[index]]
		)


func test_the_spits_trees_stand_in_a_row_behind_what_is_built_there() -> void:
	assert_true(WorldLayout.SIDE_STATIC["east_"].has(&"static_back"), "The east page has a back layer")
	assert_true(int(WorldLayout.STATIC_Z[&"static_back"]) < WorldLayout.BACK_LANE - 5)
	var back: Image = (load("res://assets/world/cave/east_static_back.png") as Texture2D).get_image()
	var mid: Image = (load("res://assets/world/cave/east_static_mid.png") as Texture2D).get_image()
	var trees: int = back.get_used_rect().size.x
	assert_gt(trees, 60, "The pines and palms are drawn")
	# Nothing in front of the buildings is taller than the reeds and bushes any more: no tree crowns.
	var tallest: int = 80
	for x: int in mid.get_width():
		for y: int in 80:
			if mid.get_pixel(x, y).a > 0.05:
				tallest = mini(tallest, y)
				break
	assert_gt(tallest, 40, "The front layer keeps only low things (its top is row %d)" % tallest)
	# The tree crowns stay clear of the building lane's feet (they are behind, not in front).
	var feet: int = 0
	for x: int in back.get_width():
		for y: int in range(WorldLayout.BACK_LANE, 80):
			feet += 1 if back.get_pixel(x, y).a > 0.05 else 0
	assert_eq(feet, 0, "No tree trunk reaches the building lane's foot row")
