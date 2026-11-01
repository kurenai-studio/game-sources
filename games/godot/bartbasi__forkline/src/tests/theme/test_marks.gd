# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The status marks of the expansion (contract 14.9): the list, each mark
## inside its box, each a shape of its own, each in an ink casing or outline,
## and the colors in contrast. Recorded with InkPen and no canvas, so this
## runs headless.

const MASK: int = 40
const MAX_OVERLAP: float = 0.8
## A creature mark for a box of 100 at (0, 0): 0.6 left and right, 0.7 above,
## 0.6 below (Silhouettes.draw_mark).
const CREATURE_BOX: Rect2 = Rect2(-60.0, -70.0, 120.0, 130.0)
## The doze mark for a cell of 100: the tower's box (test_silhouettes.gd).
const TOWER_BOX: Rect2 = Rect2(-54.0, -86.0, 108.0, 128.0)
const GRAPHIC_MIN: float = 3.0


func test_marks_follow_the_contract() -> void:
	assert_eq(Silhouettes.MARKS, [&"hidden", &"napping", &"fright", &"awake", &"doze", &"low", &"dug"] as Array[StringName])


func test_every_mark_draws_inside_its_box_in_every_frame() -> void:
	for mark: StringName in Silhouettes.MARKS:
		var limit: Rect2 = TOWER_BOX if mark == &"doze" else CREATURE_BOX
		for frame: int in 4:
			var pen: InkPen = _mark(mark, frame)
			assert_true(pen.shapes.size() >= 2, "%s frame %d draws" % [mark, frame])
			var box: Rect2 = _bounds(pen)
			assert_true(limit.encloses(box), "%s frame %d stays in %s: %s" % [mark, frame, limit, box])


func test_every_mark_has_an_ink_casing() -> void:
	for mark: StringName in Silhouettes.MARKS:
		var inked: bool = false
		var colored: bool = false
		for s: InkPen.Shape in _mark(mark, 0).shapes:
			if s.color == Palette.INK_LINE:
				inked = true
			elif s.color.a >= 0.5:
				colored = true
		assert_true(inked, "%s has an ink casing or outline" % mark)
		assert_true(colored, "%s has a light color inside it" % mark)


func test_marks_are_distinct_shapes() -> void:
	var masks: Array[PackedByteArray] = []
	for mark: StringName in Silhouettes.MARKS:
		var pen: InkPen = _mark(mark, 0)
		masks.append(_mask(pen, TOWER_BOX if mark == &"doze" else CREATURE_BOX))
	for i: int in masks.size():
		assert_true(_count(masks[i]) > 4, "%s has a visible shape" % Silhouettes.MARKS[i])
		for j: int in range(i + 1, masks.size()):
			var o: float = _overlap(masks[i], masks[j])
			assert_true(o < MAX_OVERLAP, "%s and %s overlap %.2f" % [Silhouettes.MARKS[i], Silhouettes.MARKS[j], o])


## A dozing tower's one big "z" is not a slowed creature's "z z".
func test_doze_differs_from_drowsy() -> void:
	var doze: InkPen = _mark(&"doze", 0)
	var zs: int = 0
	for s: InkPen.Shape in doze.shapes:
		if s.width > 0.0 and s.color == Palette.FLOUR:
			zs += 1
	assert_eq(zs, 1, "the doze mark is one z")
	var box: Rect2 = _bounds(doze)
	assert_true(box.size.x >= 18.0, "and a big one: %s" % box)


## Every light color in a mark reaches 3:1 against the ink that cases it. The
## dug mound sits on the road, so its fill is checked against the road.
func test_mark_colors_reach_contrast() -> void:
	for mark: StringName in Silhouettes.MARKS:
		for s: InkPen.Shape in _mark(mark, 0).shapes:
			if s.color.a < 0.5 or s.color == Palette.INK_LINE:
				continue
			if mark == &"dug" and s.width <= 0.0 and s.color != Palette.BONE:
				var on_road: float = Palette.contrast(s.color, Palette.ROAD)
				if s.color == Palette.DIRT:
					assert_true(on_road >= GRAPHIC_MIN, "the dug mound on the road: %.2f:1" % on_road)
				continue
			var r: float = Palette.contrast(s.color, Palette.INK_LINE)
			assert_true(r >= GRAPHIC_MIN, "%s: #%s in its ink casing %.2f:1" % [mark, s.color.to_html(false), r])


func test_dug_moves_with_the_frame() -> void:
	var a: Rect2 = _bounds(_mark(&"dug", 0))
	var first: Array[PackedVector2Array] = _points(_mark(&"dug", 0))
	var later: Array[PackedVector2Array] = _points(_mark(&"dug", 3))
	assert_eq(first.size(), later.size())
	assert_ne(first, later, "the mound's clods and claws move")
	assert_true(a.size.x > 60.0, "the mound is about as wide as Burrowbelly: %s" % a)


func test_an_unknown_mark_draws_nothing() -> void:
	assert_eq(_mark(&"no_such_mark", 0).shapes.size(), 0)


# Helpers.

func _mark(mark: StringName, frame: int) -> InkPen:
	var pen: InkPen = InkPen.new(null)
	Silhouettes.mark_into(pen, mark, Vector2.ZERO, 100.0, frame)
	return pen


func _points(pen: InkPen) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for s: InkPen.Shape in pen.shapes:
		out.append(s.points)
	return out


func _bounds(pen: InkPen) -> Rect2:
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


func _mask(pen: InkPen, rect: Rect2) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(MASK * MASK)
	var step: Vector2 = rect.size / float(MASK)
	for y: int in MASK:
		for x: int in MASK:
			var p: Vector2 = rect.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * step
			for s: InkPen.Shape in pen.shapes:
				if s.color.a >= 0.5 and _covers(s, p):
					out[y * MASK + x] = 1
					break
	return out


func _covers(s: InkPen.Shape, p: Vector2) -> bool:
	if s.width <= 0.0:
		return Geometry2D.is_point_in_polygon(p, s.points)
	var half: float = s.width * 0.5
	for i: int in s.points.size() - 1:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, s.points[i], s.points[i + 1])) <= half:
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
