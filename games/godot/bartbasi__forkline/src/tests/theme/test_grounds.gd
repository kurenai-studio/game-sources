# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The 8 region grounds and the 4 map features (contract 14.9,
## docs/art/EXPANSION_LOOK.md 3 and 4): the list, a run map's ground, the road
## characters, contrast on every ground in normal vision and for a
## deuteranope, and every piece drawn inside its cells. Recorded with InkPen
## and no canvas, so this runs headless.

const GRAPHIC_MIN: float = 3.0
const TEXT_MIN: float = 4.5
const CELL: float = 100.0
## A map with every feature: a tunnel run going down and one going across, a
## bridge, a slide down and a slide right, and two stump pairs.
const FEATURES: PackedStringArray = [
	"...1...",
	".o.T.o.",
	".P.T...",
	".#.#.Q.",
	".##X##.",
	"...#.#.",
	"...v.>#",
	"...v..#",
	".###TT#",
	".#.o...",
	".P.#.Q.",
	"...B...",
]
## Plain roads with spots and a socket, and room for scenery away from roads.
const PLAIN: PackedStringArray = [
	"...1...",
	".o.#.o.",
	".##G##.",
	".#...#.",
	"o#...#o",
	".#####.",
	"...#...",
	"...B...",
]


func test_grounds_follow_the_contract() -> void:
	assert_eq(MapArt.GROUNDS, [&"lantern_hill", &"millbrook", &"willow_fen", &"moonspire_keep",
		&"hollow_lanes", &"russet_orchards", &"frostpine_ridge", &"starglen"] as Array[StringName])
	assert_eq(Palette.GROUND_PREFIX.keys(), MapArt.GROUNDS, "Palette has every ground's tokens, in the same order")
	for g: StringName in Palette.FEATURE_GROUNDS:
		assert_true(MapArt.GROUNDS.find(g) >= 4, "%s is one of regions 5 to 8" % g)


func test_grounds_match_the_campaign_regions() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/campaign.json"))
	assert_true(data is Dictionary, "campaign.json reads")
	if not data is Dictionary:
		return
	var regions: Array = (data as Dictionary).get("regions", [])
	assert_true(regions.size() >= 1 and regions.size() <= MapArt.GROUNDS.size())
	for i: int in regions.size():
		assert_eq(StringName((regions[i] as Dictionary).get("id", "")), MapArt.GROUNDS[i], "region %d has its ground" % (i + 1))


func test_road_chars_match_level_data() -> void:
	assert_eq(MapArt.ROAD_CHARS, LevelData.ROAD_CHARS)
	# Every grid character draws a road band through its cell exactly when it
	# is a road character: sand, or ice on a slide.
	for i: int in LevelData.GRID_CHARS.length():
		var ch: String = LevelData.GRID_CHARS[i]
		var grid: PackedStringArray = [".....", ".....", ".." + ch + "..", ".....", "....."]
		var pen: InkPen = _ground(grid, &"lantern_hill")
		var road: bool = false
		for s: InkPen.Shape in pen.shapes:
			if (s.color == Palette.ROAD or s.color == Palette.ICE) and _covers(s, Vector2(2.5, 2.5) * CELL):
				road = true
		assert_eq(road, LevelData.ROAD_CHARS.contains(ch), "'%s' draws a road band" % ch)


func test_a_run_maps_ground_comes_from_its_first_feature() -> void:
	for g: StringName in MapArt.GROUNDS:
		assert_eq(MapArt.ground_of(g, FEATURES), g, "a campaign region keeps its own ground")
	assert_eq(MapArt.ground_of(&"", PLAIN), &"lantern_hill", "no feature: Lantern Hill's meadow")
	assert_eq(MapArt.ground_of(&"", PackedStringArray()), &"lantern_hill")
	var firsts: Dictionary[String, StringName] = {
		"T": &"hollow_lanes", "X": &"russet_orchards", "^": &"frostpine_ridge", "v": &"frostpine_ridge",
		"<": &"frostpine_ridge", ">": &"frostpine_ridge", "P": &"starglen", "Q": &"starglen",
	}
	for ch: String in firsts:
		assert_eq(MapArt.ground_of(&"", ["...", "#" + ch + "#", "..."]), firsts[ch], "a run map with '%s'" % ch)
	# Reading order: row by row, then left to right.
	assert_eq(MapArt.ground_of(&"", [".#.", ".P.", "#X#", ".T."]), &"starglen")
	assert_eq(MapArt.ground_of(&"", ["...", "#X>", "..."]), &"russet_orchards")
	assert_eq(MapArt.ground_of(&"nowhere", ["T"]), &"hollow_lanes", "an unknown region counts as a run map")
	# Every feature character picks a ground a feature can stand on.
	for ch: String in firsts:
		assert_true(Palette.FEATURE_GROUNDS.has(firsts[ch]))


func test_every_ground_has_its_own_colors() -> void:
	var seen: Dictionary[String, StringName] = {}
	for g: StringName in MapArt.GROUNDS:
		for role: String in ["GROUND", "GROUND_LIGHT", "GROUND_DARK", "ROAD", "ROAD_EDGE", "ROAD_DOT"]:
			var token: String = Palette.ground_token(g, role)
			assert_true((Palette as Script).get_script_constant_map().has(token), "%s %s is token %s" % [g, role, token])
			assert_eq(Palette.ground_color(g, role).a, 1.0, "%s %s is opaque" % [g, role])
		var ground: String = Palette.ground_color(g, "GROUND").to_html(false)
		assert_false(seen.has(ground), "%s and %s share a ground color" % [g, seen.get(ground, &"")])
		seen[ground] = g
		# The drawing starts with the ground, then the border and the road.
		var pen: InkPen = _ground(PLAIN, g)
		assert_eq(pen.shapes[0].color, Palette.ground_color(g, "GROUND"), "%s fills its ground" % g)
		assert_true(_uses(pen, Palette.ground_color(g, "ROAD_EDGE")), "%s draws its road's border" % g)
		assert_true(_uses(pen, Palette.ground_color(g, "ROAD")), "%s draws its road" % g)
	assert_eq(Palette.ground_token(&"lantern_hill", "GROUND"), "MEADOW")
	assert_eq(Palette.ROAD_EDGE, Color("856143"), "Lantern Hill's new border")
	assert_eq(Palette.MEADOW_LIGHT, Color("507458"), "Lantern Hill's new light grass")
	assert_eq(Palette.ground_token(&"millbrook", "ROAD_EDGE"), "ROAD_EDGE", "regions 2 to 4 share Lantern Hill's road")
	assert_eq(_ground(PLAIN, &"nowhere").shapes[0].color, Palette.MEADOW, "an unknown ground draws Lantern Hill")


func test_every_ground_reaches_contrast() -> void:
	var listed: Dictionary[String, bool] = {}
	for pair: PackedStringArray in Palette.graphic_pairs():
		listed[pair[0] + "/" + pair[1]] = true
	for g: StringName in MapArt.GROUNDS:
		var ground: String = Palette.ground_token(g, "GROUND")
		var light: String = Palette.ground_token(g, "GROUND_LIGHT")
		var road: String = Palette.ground_token(g, "ROAD")
		for pair: Array in [[road, ground], [road, light], [Palette.ground_token(g, "ROAD_EDGE"), road], ["INK_LINE", road],
				["INK_LINE", light], ["PAD", ground], ["PLASTER", ground], ["ROUTE", ground], ["TIMBER", road]]:
			assert_true(listed.has("%s/%s" % pair), "%s/%s is a checked graphic pair" % pair)
			_check(pair[0], pair[1], GRAPHIC_MIN, g)
		_check("TEXT_LIGHT", ground, TEXT_MIN, g)
	var texts: Dictionary[String, bool] = {}
	for pair: PackedStringArray in Palette.text_pairs():
		texts[pair[0] + "/" + pair[1]] = true
	for g: StringName in MapArt.GROUNDS:
		assert_true(texts.has("TEXT_LIGHT/" + Palette.ground_token(g, "GROUND")), "text on %s is a checked text pair" % g)


func test_every_feature_pair_reaches_contrast() -> void:
	var listed: Dictionary[String, bool] = {}
	for pair: PackedStringArray in Palette.graphic_pairs():
		listed[pair[0] + "/" + pair[1]] = true
	for pair: PackedStringArray in Palette.feature_pairs():
		assert_true(listed.has(pair[0] + "/" + pair[1]), "%s/%s is a checked graphic pair" % [pair[0], pair[1]])
		_check(pair[0], pair[1], GRAPHIC_MIN, pair[2])
	# Slides and stumps can sit on any ground; bridges on the grounds of
	# regions 5 to 8, the only ones with features (ground_of).
	for g: StringName in MapArt.GROUNDS:
		var road: String = Palette.ground_token(g, "ROAD")
		_check("ICE", Palette.ground_token(g, "GROUND"), GRAPHIC_MIN, g)
		_check("ICE", Palette.ground_token(g, "GROUND_LIGHT"), GRAPHIC_MIN, g)
		_check("BARK", road, GRAPHIC_MIN, g)
		if Palette.FEATURE_GROUNDS.has(g):
			_check("WOOD", road, GRAPHIC_MIN, g)


func test_ground_and_feature_layers_stay_apart() -> void:
	# Mounds, decks and stumps are the feature layer, above the route lines.
	# Ice, chevrons and the road under the deck are the ground.
	for g: StringName in MapArt.GROUNDS:
		var ground: InkPen = _ground(FEATURES, g)
		for c: Color in [Palette.MOUND, Palette.BARK]:
			assert_false(_uses(ground, c), "%s ground draws no #%s" % [g, c.to_html(false)])
		assert_true(_uses(ground, Palette.ICE) and _uses(ground, Palette.ICE_DEEP), "%s ground draws the slides" % g)
	var features: InkPen = _features(FEATURES)
	for c: Color in [Palette.MOUND, Palette.WOOD, Palette.BARK, Palette.MOON]:
		assert_true(_uses(features, c), "the feature layer draws #%s" % c.to_html(false))
	assert_false(_uses(features, Palette.ICE), "the feature layer draws no ice")
	assert_eq(_features(PLAIN).shapes.size(), 0, "a map with no feature has an empty feature layer")


func test_features_draw_inside_their_cells() -> void:
	var map: Rect2 = Rect2(Vector2.ZERO, Vector2(7, FEATURES.size()) * CELL)
	for at: Vector2i in _cells_of(FEATURES, "TXPQ"):
		var grid: PackedStringArray = _only(FEATURES, at)
		var pen: InkPen = _features(grid)
		assert_true(pen.shapes.size() > 0, "the feature at %s draws" % at)
		# A tunnel tile draws its whole run's mound, so check against the run.
		var cells: Rect2 = Rect2(Vector2(at) * CELL, Vector2(CELL, CELL))
		for other: Vector2i in _cells_of(grid, "T"):
			cells = cells.merge(Rect2(Vector2(other) * CELL, Vector2(CELL, CELL)))
		# A deck is a little longer than its cell, over the road beside it.
		var limit: Rect2 = cells.grow(0.2 * CELL)
		var box: Rect2 = _bounds(pen)
		assert_true(limit.encloses(box), "the feature at %s stays in %s: %s" % [at, limit, box])
		assert_true(map.encloses(box), "the feature at %s stays on the map: %s" % [at, box])
	for at: Vector2i in _cells_of(FEATURES, "^v<>"):
		var cell: Rect2 = Rect2(Vector2(at) * CELL, Vector2(CELL, CELL))
		for s: InkPen.Shape in _ground(FEATURES, &"frostpine_ridge").shapes:
			if s.color == Palette.ICE_DEEP and cell.has_point(_mid(s)):
				assert_true(cell.encloses(_shape_box(s)), "the chevrons at %s stay in their cell" % at)


func test_tunnels_are_one_mound_per_run() -> void:
	var mounds: int = 0
	for s: InkPen.Shape in _features(FEATURES).shapes:
		if s.color == Palette.MOUND and s.width == 0.0:
			mounds += 1
	assert_eq(mounds, 2, "one mound over the run going down, one over the run going across")


func test_chevrons_point_the_slides_way() -> void:
	var dirs: Dictionary[String, Vector2] = {"^": Vector2(0, -1), "v": Vector2(0, 1), "<": Vector2(-1, 0), ">": Vector2(1, 0)}
	for ch: String in dirs:
		var grid: PackedStringArray = [".#.", "#" + ch + "#", ".#."]
		var n: int = 0
		for s: InkPen.Shape in _ground(grid, &"frostpine_ridge").shapes:
			if s.color != Palette.ICE_DEEP:
				continue
			n += 1
			assert_eq(s.points.size(), 3, "a chevron is two arms and a tip")
			var back: Vector2 = (s.points[0] + s.points[2]) * 0.5
			assert_true((s.points[1] - back).dot(dirs[ch]) > 0.0, "'%s' points its way" % ch)
		assert_eq(n, 2, "'%s' has two chevrons" % ch)


func test_stumps_differ_by_symbol_and_bridges_are_not_gates() -> void:
	var moon: PackedByteArray = _symbol(false)
	var star: PackedByteArray = _symbol(true)
	assert_true(_count(moon) > 20 and _count(star) > 20, "both symbols show")
	assert_true(_overlap(moon, star) < 0.6, "a crescent never looks like a star: %.2f" % _overlap(moon, star))
	# A gate stands between two lanterns. A deck has none.
	var deck: InkPen = InkPen.new()
	FeatureArt.bridge(deck, Vector2.ZERO, CELL)
	assert_false(_uses(deck, Palette.LANTERN), "a bridge deck carries no lanterns")


func test_scenery_stays_inside_its_cell() -> void:
	var cell: Rect2 = Rect2(0.0, 0.0, CELL, CELL)
	for g: StringName in MapArt.GROUNDS:
		for h: int in 400:
			for near_road: bool in [false, true]:
				var pen: InkPen = InkPen.new()
				pen.line_px = 3.0
				SceneryArt.draw(pen, cell.get_center(), CELL, _mix(h), near_road, g)
				if pen.shapes.is_empty():
					continue
				var box: Rect2 = _bounds(pen)
				assert_true(cell.encloses(box), "%s scenery %d stays in its cell: %s" % [g, h, box])
				if near_road:
					# Near roads only small, flat things: details with no outline.
					assert_false(_uses(pen, Palette.INK_LINE), "%s scenery %d near a road is small and flat" % [g, h])
				if failures.size() > 0:
					return


func test_millbrook_water_stays_off_the_roads() -> void:
	# Millbrook's ponds sit inside ground cells with no road beside them, so
	# no road crosses water and no bridge or ford is drawn.
	var pen: InkPen = _ground(PLAIN, &"millbrook")
	var ponds: int = 0
	for s: InkPen.Shape in pen.shapes:
		if s.color != Palette.MILLBROOK_WATER or s.width > 0.0:
			continue
		ponds += 1
		var at: Vector2i = Vector2i(floori(_mid(s).x / CELL), floori(_mid(s).y / CELL))
		assert_eq(PLAIN[at.y][at.x], ".", "a pond at %s is on a ground cell" % at)
		for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var n: Vector2i = at + d
			if n.y >= 0 and n.y < PLAIN.size() and n.x >= 0 and n.x < 7:
				assert_false(MapArt.ROAD_CHARS.contains(PLAIN[n.y][n.x]), "no road beside the pond at %s" % at)
	assert_false(_uses(pen, Palette.WOOD), "Millbrook draws no bridge")
	# Over the whole set of hashes a pond shows up somewhere.
	var any: bool = ponds > 0
	for h: int in 200:
		var p: InkPen = InkPen.new()
		SceneryArt.draw(p, Vector2(50, 50), CELL, _mix(h), false, &"millbrook")
		any = any or _uses(p, Palette.MILLBROOK_WATER)
	assert_true(any, "Millbrook draws its millponds")


# Helpers.

func _check(fg: String, bg: String, minimum: float, where: String) -> void:
	var a: Color = Palette.token(fg)
	var b: Color = Palette.token(bg)
	assert_eq(a.a, 1.0, "%s exists and is opaque" % fg)
	assert_eq(b.a, 1.0, "%s exists and is opaque" % bg)
	var ratio: float = Palette.contrast(a, b)
	assert_true(ratio >= minimum, "%s: %s on %s %.2f:1, needs %.1f:1" % [where, fg, bg, ratio, minimum])
	var deut: float = Palette.contrast(_deuteranope(a), _deuteranope(b))
	assert_true(deut >= minimum, "%s: %s on %s for a deuteranope %.2f:1, needs %.1f:1" % [where, fg, bg, deut, minimum])


## A color as a deuteranope sees it (Machado, Oliveira and Fernandes 2009,
## full strength), in linear light.
func _deuteranope(c0: Color) -> Color:
	var c: Color = c0.srgb_to_linear()
	var r: float = 0.367322 * c.r + 0.860646 * c.g - 0.227968 * c.b
	var g: float = 0.280085 * c.r + 0.672501 * c.g + 0.047413 * c.b
	var b: float = -0.011820 * c.r + 0.042940 * c.g + 0.968881 * c.b
	return Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0)).linear_to_srgb()


func _ground(grid: PackedStringArray, ground: StringName) -> InkPen:
	var pen: InkPen = InkPen.new()
	MapArt.ground_into(pen, grid, CELL, ground)
	return pen


func _features(grid: PackedStringArray) -> InkPen:
	var pen: InkPen = InkPen.new()
	MapArt.features_into(pen, grid, CELL)
	return pen


## `grid` with every feature but the one at `at` (and its tunnel run) turned
## into plain road.
func _only(grid: PackedStringArray, at: Vector2i) -> PackedStringArray:
	var keep: String = grid[at.y][at.x]
	var out: PackedStringArray = PackedStringArray()
	for r: int in grid.size():
		var line: String = grid[r]
		for c: int in line.length():
			var ch: String = line[c]
			var same_run: bool = keep == "T" and ch == "T" and (r == at.y or c == at.x)
			if "TXPQ".contains(ch) and Vector2i(c, r) != at and not same_run:
				line[c] = "#"
		out.append(line)
	return out


func _cells_of(grid: PackedStringArray, chars: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r: int in grid.size():
		for c: int in grid[r].length():
			if chars.contains(grid[r][c]):
				out.append(Vector2i(c, r))
	return out


## The moon colored symbol of a stump, as a 40 x 40 mask over its face.
func _symbol(star: bool) -> PackedByteArray:
	var pen: InkPen = InkPen.new()
	FeatureArt.stump(pen, Vector2.ZERO, CELL, star)
	var out: PackedByteArray = PackedByteArray()
	out.resize(1600)
	for y: int in 40:
		for x: int in 40:
			var p: Vector2 = Vector2(-20.0 + float(x), -14.0 + float(y))
			for s: InkPen.Shape in pen.shapes:
				if s.color == Palette.MOON and s.width == 0.0 and _covers(s, p):
					out[y * 40 + x] = 1
					break
	return out


## Spreads small numbers over the hash range, as cell hashes are.
func _mix(i: int) -> int:
	var h: int = (i * 1274126177) ^ 0x5bd1
	return (h ^ (h >> 13)) & 0x7fffffff


func _uses(pen: InkPen, c: Color) -> bool:
	for s: InkPen.Shape in pen.shapes:
		if s.color.r == c.r and s.color.g == c.g and s.color.b == c.b and s.color.a >= 0.5:
			return true
	return false


func _mid(s: InkPen.Shape) -> Vector2:
	return _shape_box(s).get_center()


func _shape_box(s: InkPen.Shape) -> Rect2:
	var box: Rect2 = Rect2(s.points[0], Vector2.ZERO)
	for p: Vector2 in s.points:
		box = box.expand(p)
	return box.grow(s.width * 0.5)


func _bounds(pen: InkPen) -> Rect2:
	var box: Rect2 = _shape_box(pen.shapes[0])
	for s: InkPen.Shape in pen.shapes:
		box = box.merge(_shape_box(s))
	return box


func _covers(s: InkPen.Shape, p: Vector2) -> bool:
	if s.width <= 0.0:
		return s.points.size() >= 3 and Geometry2D.is_point_in_polygon(p, s.points)
	for i: int in s.points.size() - 1:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, s.points[i], s.points[i + 1])) <= s.width * 0.5:
			return true
	return false


func _overlap(a: PackedByteArray, b: PackedByteArray) -> float:
	var both: int = 0
	var either: int = 0
	for i: int in a.size():
		if a[i] == 1 and b[i] == 1:
			both += 1
		if a[i] == 1 or b[i] == 1:
			either += 1
	return 0.0 if either == 0 else float(both) / float(either)


func _count(m: PackedByteArray) -> int:
	var n: int = 0
	for v: int in m:
		n += v
	return n
