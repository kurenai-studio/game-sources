# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Map drawing helpers: route lines follow the road cells with the same round
## turns as the roads, and gates know which way their road runs.

const CELL: float = 128.0
const GRID: PackedStringArray = [
	"...1...",
	".o.#.o.",
	".#####.",
	".#.o.#.",
	"oG...#o",
	".#.o.#.",
	".#####.",
	"...B...",
]


func test_route_points_start_and_end_at_cell_centers() -> void:
	var cells: Array[Vector2i] = [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(5, 3)]
	var pts: PackedVector2Array = MapArt.route_points(cells, CELL)
	assert_eq(pts[0], Vector2(3.5, 0.5) * CELL)
	assert_eq(pts[pts.size() - 1], Vector2(5.5, 3.5) * CELL)


func test_route_points_stay_on_the_road() -> void:
	var cells: Array[Vector2i] = [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(5, 3), Vector2i(5, 4)]
	var pts: PackedVector2Array = MapArt.route_points(cells, CELL)
	for p: Vector2 in pts:
		var cell: Vector2i = Vector2i(floori(p.x / CELL), floori(p.y / CELL))
		var on_road: bool = cells.has(cell)
		# A point on a cell edge belongs to both neighbors.
		if not on_road:
			for c: Vector2i in cells:
				if Rect2(Vector2(c) * CELL, Vector2(CELL, CELL)).grow(0.01).has_point(p):
					on_road = true
		assert_true(on_road, "route point %s is on a road cell" % p)


func test_turns_are_round() -> void:
	# A turn at (3, 2): from down to right. The path never cuts closer to the
	# inner corner than the road's own quarter circle of half a cell.
	var cells: Array[Vector2i] = [Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2)]
	var pts: PackedVector2Array = MapArt.route_points(cells, CELL)
	assert_true(pts.size() > 4, "the turn adds arc points")
	var corner: Vector2 = Vector2(4.0, 2.0) * CELL
	for i: int in range(1, pts.size() - 1):
		assert_near(pts[i].distance_to(corner), CELL * 0.5, 0.5, "arc point %d" % i)


func test_gates_know_their_road() -> void:
	assert_true(MapArt.road_runs_vertically(GRID, Vector2i(1, 4)), "socket on a road running down")
	var across: PackedStringArray = ["...", "#G#", "..."]
	assert_false(MapArt.road_runs_vertically(across, Vector2i(1, 1)), "socket on a road running across")


func test_gate_looks_cover_the_rules() -> void:
	# RULES.md 9.7: open socket, closed, broken (crack) and refused (crossed
	# out); plus fixed gates from twists, and gates standing open under
	# gates_open (contract 3.9).
	assert_eq(MapArt.Gate.size(), 6)
	assert_eq(MapArt.Gate.OPEN, 5, "OPEN comes last, so the older looks keep their numbers")
	assert_eq(MapArt.Route.size(), 3, "solid walkers, dashed breakers, dotted flyers")


# Gate looks. Drawn at a cell of 100 around (0, 0) and recorded by an InkPen
# with no canvas, so this runs headless.

const FLAT: Color = Color(1.0, 0.0, 1.0, 1.0)
## The middle of the road through a gate, where walkers pass. Across: a road
## running down the screen, the gate facing the viewer. Side: a road running
## across the screen.
const WALKWAY_ACROSS: Rect2 = Rect2(-15.0, -28.0, 30.0, 40.0)
const WALKWAY_SIDE: Rect2 = Rect2(-5.0, -24.0, 10.0, 40.0)
## A point on the open gate's arch, over the middle of the road.
const ARCH_TOP: Vector2 = Vector2(0.0, -59.0)
## A point on the fixed gate's padlock body, outside the gate's own outline:
## below the gate facing the viewer, beside the near post seen from the side.
const PADLOCK_ACROSS: Vector2 = Vector2(0.0, 38.0)
const PADLOCK_SIDE: Vector2 = Vector2(-36.0, 10.0)
const MASK: int = 40
## Two looks whose flat masks overlap more than this (intersection over
## union) are too alike to tell apart by shape.
const MAX_OVERLAP: float = 0.8


func test_every_gate_look_draws_inside_its_cell() -> void:
	for look: int in MapArt.Gate.size():
		for across: bool in [true, false]:
			var pen: InkPen = _gate(look as MapArt.Gate, across, false)
			var label: String = "%s %s" % [MapArt.Gate.keys()[look], _side(across)]
			assert_true(pen.shapes.size() >= 3, "%s draws its shapes" % label)
			var box: Rect2 = _solid_bounds(pen)
			# Within the cell side to side (plus the outline), at most 0.68 of
			# a cell above the socket center and half a cell below it.
			assert_true(box.position.x >= -52.0 and box.end.x <= 52.0, "%s stays within the cell width: %s" % [label, box])
			assert_true(box.position.y >= -68.0 and box.end.y <= 50.0, "%s stays within the cell height: %s" % [label, box])


func test_flat_gate_looks_use_one_color() -> void:
	for look: int in MapArt.Gate.size():
		for across: bool in [true, false]:
			var pen: InkPen = _gate(look as MapArt.Gate, across, true)
			for s: InkPen.Shape in pen.shapes:
				if s.color.r != FLAT.r or s.color.g != FLAT.g or s.color.b != FLAT.b:
					fail("%s %s: flat drawing has a second color #%s" % [MapArt.Gate.keys()[look], _side(across), s.color.to_html()])
					break


func test_open_gate_leaves_the_road_clear() -> void:
	# The open gate reads by shape: nothing stands in the middle of the road.
	# Every look that stops walkers or marks a gate that is not plainly open
	# puts something there, so the check tells them apart.
	for across: bool in [true, false]:
		var walkway: Rect2 = WALKWAY_ACROSS if across else WALKWAY_SIDE
		assert_false(_covers_any(_gate(MapArt.Gate.OPEN, across, true), walkway), "OPEN %s: the middle of the road is clear" % _side(across))
		for look: MapArt.Gate in [MapArt.Gate.CLOSED, MapArt.Gate.FIXED, MapArt.Gate.BROKEN, MapArt.Gate.REFUSED]:
			assert_true(_covers_any(_gate(look, across, true), walkway), "%s %s: something stands in the road" % [MapArt.Gate.keys()[look], _side(across)])


func test_only_the_open_gate_has_an_arch() -> void:
	# The round arch over the opening tells an open gate from a broken one,
	# whose halves also hang aside.
	for across: bool in [true, false]:
		for look: int in MapArt.Gate.size():
			var covered: bool = _covers_any(_gate(look as MapArt.Gate, across, true), Rect2(ARCH_TOP, Vector2.ZERO).grow(1.0))
			if look == MapArt.Gate.OPEN:
				assert_true(covered, "OPEN %s has its arch over the road" % _side(across))
			else:
				assert_false(covered, "%s %s has no arch" % [MapArt.Gate.keys()[look], _side(across)])


func test_every_gate_look_is_its_own_shape() -> void:
	# Color is never the only signal: in one flat color, every look's outline
	# differs from every other look's, on both road directions.
	for across: bool in [true, false]:
		var masks: Array[PackedByteArray] = []
		for look: int in MapArt.Gate.size():
			masks.append(_mask(_gate(look as MapArt.Gate, across, true)))
			assert_true(_count(masks[look]) > 40, "%s %s has a visible shape" % [MapArt.Gate.keys()[look], _side(across)])
		for i: int in masks.size():
			for j: int in range(i + 1, masks.size()):
				var o: float = _overlap(masks[i], masks[j])
				assert_true(o < MAX_OVERLAP, "%s and %s %s overlap %.2f by shape" % [MapArt.Gate.keys()[i], MapArt.Gate.keys()[j], _side(across), o])


func test_fixed_gate_padlock_hangs_outside_the_gate() -> void:
	# The padlock hangs outside the gate's own outline, where a closed gate
	# has nothing, so a fixed gate shows its lock in one flat color.
	for across: bool in [true, false]:
		var below: Rect2 = Rect2(PADLOCK_ACROSS if across else PADLOCK_SIDE, Vector2.ZERO).grow(2.0)
		assert_true(_covers_any(_gate(MapArt.Gate.FIXED, across, true), below), "FIXED %s: the padlock hangs below the gate" % _side(across))
		assert_false(_covers_any(_gate(MapArt.Gate.CLOSED, across, true), below), "CLOSED %s: nothing hangs below the gate" % _side(across))


func test_open_gate_colors_reach_contrast_on_the_road() -> void:
	# The open gate adds no new mark color. Its arch and posts are timber in an
	# ink outline over the sandy road. Both pairs are in the palette's checked
	# list (tests/theme/test_contrast.gd holds them to 3:1).
	var listed: Array[String] = []
	for pair: PackedStringArray in Palette.graphic_pairs():
		listed.append("%s/%s" % [pair[0], pair[1]])
	for key: String in ["TIMBER/ROAD", "INK_LINE/ROAD"]:
		assert_true(listed.has(key), "%s is a checked graphic pair" % key)
	for across: bool in [true, false]:
		var used: Dictionary[String, bool] = {}
		for s: InkPen.Shape in _gate(MapArt.Gate.OPEN, across, false).shapes:
			if s.color.a >= 0.5:
				used[s.color.to_html(false)] = true
		assert_true(used.has(Palette.TIMBER.to_html(false)), "OPEN %s: the arch and posts are timber" % _side(across))
		assert_true(used.has(Palette.INK_LINE.to_html(false)), "OPEN %s: its shapes have the ink outline" % _side(across))


# Gate helpers.

func _gate(look: MapArt.Gate, across: bool, flat: bool) -> InkPen:
	var pen: InkPen = InkPen.new(null, FLAT if flat else Color(0.0, 0.0, 0.0, 0.0))
	MapArt.gate_into(pen, Vector2.ZERO, 100.0, across, look)
	return pen


func _side(across: bool) -> String:
	return "across" if across else "side"


## The box around every solid shape (soft glows and ghosts left out).
func _solid_bounds(pen: InkPen) -> Rect2:
	var box: Rect2 = Rect2()
	var first: bool = true
	for s: InkPen.Shape in pen.shapes:
		if s.color.a < 0.5:
			continue
		for p: Vector2 in s.points:
			var r: Rect2 = Rect2(p, Vector2.ZERO).grow(s.width * 0.5)
			box = r if first else box.merge(r)
			first = false
	return box


## True when a solid shape covers any point of a 2 unit grid over `rect`.
func _covers_any(pen: InkPen, rect: Rect2) -> bool:
	var y: float = rect.position.y
	while y <= rect.end.y:
		var x: float = rect.position.x
		while x <= rect.end.x:
			for s: InkPen.Shape in pen.shapes:
				if s.color.a >= 0.5 and _covers(s, Vector2(x, y)):
					return true
			x += 2.0
		y += 2.0
	return false


func _covers(s: InkPen.Shape, p: Vector2) -> bool:
	if s.width <= 0.0:
		return s.points.size() >= 3 and Geometry2D.is_point_in_polygon(p, s.points)
	var half: float = s.width * 0.5
	var last: int = s.points.size() - 1
	for i: int in last:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, s.points[i], s.points[i + 1])) <= half:
			return true
	if s.closed and last > 0 and p.distance_to(Geometry2D.get_closest_point_to_segment(p, s.points[last], s.points[0])) <= half:
		return true
	return false


## A MASK x MASK coverage grid of the solid shapes over the gate's cell.
func _mask(pen: InkPen) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(MASK * MASK)
	var rect: Rect2 = Rect2(-55.0, -70.0, 110.0, 125.0)
	var step: Vector2 = rect.size / float(MASK)
	for y: int in MASK:
		for x: int in MASK:
			var p: Vector2 = rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * step
			for s: InkPen.Shape in pen.shapes:
				if s.color.a >= 0.5 and _covers(s, p):
					out[y * MASK + x] = 1
					break
	return out


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
