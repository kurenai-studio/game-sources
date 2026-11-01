# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Route line marks: the arrows, dashes and dots are quads of the sheet, placed where
## MapArt.draw_route placed them, and a layer of marks is one batch (docs/ARCHITECTURE.md 9.3).

const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const CELL: float = 128.0

var _nodes: Array[Node] = []


## A MapRoutes that records its quads instead of drawing them.
class Recorder:
	extends MapRoutes
	var quads: Array[Dictionary] = []

	func _quad(_canvas: Node2D, e: MapAtlas.Entry, at: Vector2, angle: float, stretch: float) -> void:
		quads.append({"piece": e.frame, "at": at, "angle": angle, "stretch": stretch})

	func _end_marks(_canvas: Node2D) -> void:
		pass


func after_each() -> void:
	for n: Node in _nodes:
		if is_instance_valid(n):
			if n.get_parent() != null:
				n.get_parent().remove_child(n)
			n.free()
	_nodes.clear()


func _atlas() -> MapAtlas:
	var atlas: MapAtlas = MapAtlas.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(atlas)
	_nodes.append(atlas)
	atlas.add_route_pieces()
	atlas.bake(1.0)
	return atlas


func _recorder(line: MapRoutes.Line, deck: bool = false) -> Recorder:
	var layer: Recorder = Recorder.new()
	layer.deck_layer = deck
	_nodes.append(layer)
	layer.use_atlas(_atlas(), null)
	layer.lines.append(line)
	return layer


## A straight line east from (100, 100), `cells` long.
func _straight(cells: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(100.0, 100.0), Vector2(100.0 + cells * CELL, 100.0)])


func _line_with(points: PackedVector2Array, kind: String) -> MapRoutes.Line:
	var line: MapRoutes.Line = MapRoutes.Line.new()
	var lengths: PackedFloat32Array = MapRoutes._lengths(points)
	match kind:
		"walk":
			line.walk.append(points)
			line.walk_lengths.append(lengths)
		"break":
			line.breaker.append(points)
			line.break_lengths.append(lengths)
		"fly":
			line.fly = points
			line.fly_lengths = lengths
	return line


func test_the_sheet_holds_the_route_pieces_once() -> void:
	var atlas: MapAtlas = _atlas()
	atlas.add_route_pieces()
	assert_eq(RoutePieces.TILES.size(), RoutePieces.Piece.size())
	assert_eq(RoutePieces.ANCHORS.size(), RoutePieces.Piece.size())
	assert_eq(atlas.entries.size(), RoutePieces.Piece.size(), "added once")
	for piece: int in RoutePieces.Piece.size():
		var e: MapAtlas.Entry = atlas.entry_for(RoutePieces.key(piece))
		assert_not_null(e, "piece %d" % piece)
		if e != null:
			assert_true(e.rect.size.x > 0.0 and e.rect.size.y > 0.0, "piece %d has room" % piece)
			assert_true(e.anchor.x <= e.tile.x and e.anchor.y <= e.tile.y, "piece %d anchor is inside its tile" % piece)


func test_a_map_view_gives_both_route_layers_two_mark_layers() -> void:
	var stats: Catalog = Sx.catalog()
	var grid: Array = Sx.get_script_constant_map()["BRIDGE_GATE_GRID"]
	var b: Battle = Sx.battle(grid, [{"groups": [Sx.group("scamp", 1)]}], {}, stats)
	var v: MapView = MapView.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(v)
	_nodes.append(v)
	v.setup(b)
	for layer: MapRoutes in [v.get("_routes"), v.get("_overpass")]:
		assert_not_null(layer, "the layer exists on a bridge map")
		assert_not_null(layer.atlas, "it has the sheet")
		assert_eq(layer.get_child_count(), 2, "one mark layer behind the lines and one over them")
		assert_true((layer.get_child(0) as Node2D).show_behind_parent, "the first is behind the polylines")
		assert_false((layer.get_child(1) as Node2D).show_behind_parent)
		assert_not_null((layer.get_child(0) as Node2D).material, "marks use the sheet's blend")


func test_lengths_come_with_every_part() -> void:
	var stats: Catalog = Sx.catalog()
	var grid: Array = Sx.get_script_constant_map()["BRIDGE_GATE_GRID"]
	var b: Battle = Sx.battle(grid, [{"groups": [Sx.group("scamp", 1)]}], {"gates": 1}, stats)
	b.place_gate(Vector2i(4, 1))
	var v: MapView = MapView.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(v)
	_nodes.append(v)
	v.setup(b)
	var routes: Array[Dictionary] = b.routes(b.closed_cells())
	for r: Dictionary in routes:
		r["break"] = r["walk"]
		r["fly"] = true
	v.show_routes(routes)
	for layer: MapRoutes in [v.get("_routes"), v.get("_overpass")]:
		for line: MapRoutes.Line in layer.lines:
			assert_eq(line.walk_lengths.size(), line.walk.size())
			assert_eq(line.break_lengths.size(), line.breaker.size())
			for i: int in line.walk.size():
				assert_eq(line.walk_lengths[i].size(), line.walk[i].size())
			if line.fly.size() >= 2:
				assert_near(line.fly_lengths[1], line.fly[0].distance_to(line.fly[1]), 0.01)
			for deck: MapRoutes.Deck in line.walk_decks + line.break_decks:
				assert_eq(deck.lengths.size(), deck.points.size())


func test_arrows_sit_where_draw_route_puts_them() -> void:
	var points: PackedVector2Array = _straight(6.0)
	var layer: Recorder = _recorder(_line_with(points, "walk"))
	for phase: float in [0.0, 0.3, 0.77]:
		layer.phase = phase
		layer.quads.clear()
		layer.draw_marks(null, true)
		var lengths: PackedFloat32Array = MapRoutes._lengths(points)
		var total: float = lengths[1]
		var expect: Array[float] = []
		var a: float = CELL * 0.7 + fposmod(phase, 1.0) * CELL * 1.25
		while a < total - CELL * 0.4:
			expect.append(a)
			a += CELL * 1.25
		assert_eq(layer.quads.size(), expect.size(), "phase %.2f: one chevron for each place" % phase)
		for i: int in mini(expect.size(), layer.quads.size()):
			var q: Dictionary = layer.quads[i]
			assert_eq(q["piece"], RoutePieces.Piece.CHEVRON)
			var want: Vector2 = MapRoutes._point_at(points, lengths, expect[i])
			assert_true((q["at"] as Vector2).distance_to(want) < 0.01, "phase %.2f arrow %d at %s, wanted %s" % [phase, i, q["at"], want])
			assert_near(float(q["angle"]), 0.0, 0.001, "it points along the line")


func test_arrows_follow_a_turn() -> void:
	var points: PackedVector2Array = PackedVector2Array([Vector2(100.0, 100.0), Vector2(100.0 + 3.0 * CELL, 100.0), Vector2(100.0 + 3.0 * CELL, 100.0 + 3.0 * CELL)])
	var layer: Recorder = _recorder(_line_with(points, "walk"))
	layer.draw_marks(null, true)
	var lengths: PackedFloat32Array = MapRoutes._lengths(points)
	var seen_south: bool = false
	for q: Dictionary in layer.quads:
		var at: Vector2 = q["at"]
		var angle: float = q["angle"]
		if at.x > 100.0 + 3.0 * CELL - 1.0 and at.y > 100.0 + 5.0:
			seen_south = true
			assert_near(angle, PI * 0.5, 0.001, "an arrow on the way down points down")
		else:
			assert_near(angle, 0.0, 0.001, "an arrow on the way across points east")
	assert_true(seen_south, "there is an arrow after the turn")
	assert_true(lengths[2] > 6.0 * CELL - 1.0)


func test_dashes_are_a_period_apart_and_the_last_one_is_cut_short() -> void:
	var points: PackedVector2Array = _straight(3.0)
	var layer: Recorder = _recorder(_line_with(points, "break"))
	layer.phase = 0.0
	layer.draw_marks(null, false)
	var dashes: Array[Dictionary] = []
	for q: Dictionary in layer.quads:
		if int(q["piece"]) == RoutePieces.Piece.DASH:
			dashes.append(q)
	var period: float = MapRoutes.DASH_PERIOD * CELL
	var total: float = 3.0 * CELL
	var expect: int = 0
	var d: float = 0.0
	while d < total:
		expect += 1
		d += period
	assert_eq(dashes.size(), expect, "one dash for each period of the line")
	assert_near(float((dashes[0]["at"] as Vector2).x), 100.0 + period * 0.55 * 0.5, 0.01, "the first dash starts at the start")
	assert_near(float((dashes[1]["at"] as Vector2).x) - float((dashes[0]["at"] as Vector2).x), period, 0.01)
	assert_near(float(dashes[0]["stretch"]), period * 0.55 / (RoutePieces.DASH_LENGTH * CELL), 0.001, "a whole dash is its piece's length")
	assert_true(float(dashes[dashes.size() - 1]["stretch"]) <= float(dashes[0]["stretch"]) + 0.0001, "the last dash is not longer")
	var arrows: int = 0
	for q: Dictionary in layer.quads:
		if int(q["piece"]) == RoutePieces.Piece.CHEVRON:
			arrows += 1
	assert_true(arrows > 0, "a breaker's line has arrows too")


func test_dots_are_a_gap_apart() -> void:
	var points: PackedVector2Array = PackedVector2Array([Vector2(100.0, 100.0), Vector2(100.0, 100.0 + 4.0 * CELL)])
	var layer: Recorder = _recorder(_line_with(points, "fly"))
	layer.phase = 0.25
	layer.draw_marks(null, false)
	var gap: float = CELL * 0.24
	var expect: int = 0
	var d: float = 0.25 * gap
	while d < 4.0 * CELL:
		expect += 1
		d += gap
	assert_eq(layer.quads.size(), expect)
	for q: Dictionary in layer.quads:
		assert_eq(q["piece"], RoutePieces.Piece.DOT)
	assert_near(float((layer.quads[1]["at"] as Vector2).y - (layer.quads[0]["at"] as Vector2).y), gap, 0.01)


func test_the_layer_over_the_lines_holds_only_walker_arrows_and_the_layer_under_the_rest() -> void:
	var line: MapRoutes.Line = _line_with(_straight(4.0), "walk")
	var broken: MapRoutes.Line = _line_with(_straight(4.0), "break")
	line.breaker = broken.breaker
	line.break_lengths = broken.break_lengths
	var flyer: MapRoutes.Line = _line_with(PackedVector2Array([Vector2(0.0, 0.0), Vector2(200.0, 200.0)]), "fly")
	line.fly = flyer.fly
	line.fly_lengths = flyer.fly_lengths
	var layer: Recorder = _recorder(line)
	layer.draw_marks(null, true)
	for q: Dictionary in layer.quads:
		assert_eq(q["piece"], RoutePieces.Piece.CHEVRON, "over the lines: walker arrows only")
	var over: int = layer.quads.size()
	assert_true(over > 0)
	layer.quads.clear()
	layer.draw_marks(null, false)
	var kinds: Dictionary = {}
	for q: Dictionary in layer.quads:
		kinds[q["piece"]] = true
	assert_true(kinds.has(RoutePieces.Piece.DOT) and kinds.has(RoutePieces.Piece.DASH) and kinds.has(RoutePieces.Piece.CHEVRON), "under the lines: dots, dashes and the breaker's arrows")
	layer.fly_above = true
	layer.quads.clear()
	layer.draw_marks(null, false)
	assert_false(_has_piece(layer.quads, RoutePieces.Piece.DOT), "the flyers' dots are left to the deck layer when it draws them")


func _has_piece(quads: Array[Dictionary], piece: int) -> bool:
	for q: Dictionary in quads:
		if int(q["piece"]) == piece:
			return true
	return false


func test_a_deck_layer_draws_marks_for_its_pieces_only() -> void:
	var line: MapRoutes.Line = MapRoutes.Line.new()
	var deck: MapRoutes.Deck = MapRoutes.Deck.new()
	deck.points = _straight(2.0)
	deck.lengths = MapRoutes._lengths(deck.points)
	deck.start = CELL * 1.0
	line.walk_decks.append(deck)
	var layer: Recorder = _recorder(line, true)
	layer.draw_marks(null, true)
	assert_true(layer.quads.size() > 0, "a walker piece over a deck has arrows")
	layer.quads.clear()
	layer.draw_marks(null, false)
	assert_eq(layer.quads.size(), 0, "nothing under the lines when there is no breaker piece or flyer line")


func test_the_marks_of_a_bad_line_do_not_break() -> void:
	var line: MapRoutes.Line = MapRoutes.Line.new()
	line.walk.append(PackedVector2Array([Vector2(1.0, 1.0)]))
	line.walk_lengths.append(PackedFloat32Array([0.0]))
	line.walk.append(PackedVector2Array([Vector2(1.0, 1.0), Vector2(1.0, 1.0)]))
	line.walk_lengths.append(PackedFloat32Array([0.0, 0.0]))
	var layer: Recorder = _recorder(line)
	layer.draw_marks(null, true)
	layer.draw_marks(null, false)
	assert_eq(layer.quads.size(), 0, "a point and a zero length line have no marks")
