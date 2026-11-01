# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name FeatureArt
extends RefCounted
## The four map features (docs/art/EXPANSION_LOOK.md 4): tunnel mounds, bridge
## decks, ice slide chevrons and hollow stumps. Internal to src/theme/ and its
## tests, like InkPen: other areas call MapArt.draw_ground() and
## MapArt.draw_features().
##
## Each piece reads by shape, so none depends on color: a hump with stone
## arches, a plank deck with rails, carved chevrons, a stump with a crescent or
## a five point star. Everything has the one ink outline.


## A grassy mound over a straight run of tunnel tiles from `first` to `last`.
## `vertical`: the run goes up and down the screen. Then the near mouth is a
## stone arch at the bottom and the far mouth a dark slot under the mound's top
## lip. A run going across has a dark oval mouth in a stone ring at each end.
static func tunnel(pen: InkPen, first: Vector2i, last: Vector2i, vertical: bool, cell: float) -> void:
	pen.begin(Vector2.ZERO, 1.0)
	if vertical:
		var x0: float = float(first.x) * cell + cell * 0.08
		var x1: float = float(first.x + 1) * cell - cell * 0.08
		var top: float = float(first.y) * cell
		var bottom: float = float(last.y + 1) * cell
		var mid: float = (x0 + x1) * 0.5
		pen.ellipse(Vector2(mid, top + cell * 0.14), cell * 0.27, cell * 0.11, Palette.THICKET)
		var body: PackedVector2Array = InkPen.arc_pts(Vector2(mid, top + cell * 0.36), (x1 - x0) * 0.5, cell * 0.2, PI, TAU, 14)
		body.append(Vector2(x1, bottom))
		body.append(Vector2(x0, bottom))
		pen.poly(body, Palette.MOUND)
		pen.detail_poly(InkPen.ellipse_pts(Vector2(mid - cell * 0.1, (top + bottom) * 0.5), cell * 0.12, (bottom - top) * 0.36, 16), Palette.MOUND_LIGHT)
		_tufts(pen, Vector2(mid, top + cell * 0.45), bottom - top - cell * 0.9, true, cell)
		_arch(pen, Vector2(mid, bottom), cell)
	else:
		var y0: float = float(first.y) * cell + cell * 0.04
		var y1: float = float(first.y + 1) * cell - cell * 0.1
		var left: float = float(first.x) * cell + cell * 0.1
		var right: float = float(last.x + 1) * cell - cell * 0.1
		var body: PackedVector2Array = PackedVector2Array([Vector2(left, y1)])
		body.append_array(InkPen.arc_pts(Vector2((left + right) * 0.5, y0 + cell * 0.3), (right - left) * 0.5, cell * 0.3, PI, TAU, 18))
		body.append(Vector2(right, y1))
		pen.poly(body, Palette.MOUND)
		pen.detail_poly(InkPen.ellipse_pts(Vector2((left + right) * 0.5, y0 + cell * 0.22), (right - left) * 0.36, cell * 0.08, 16), Palette.MOUND_LIGHT)
		_tufts(pen, Vector2(left + cell * 0.3, y0 + cell * 0.2), right - left - cell * 0.6, false, cell)
		for x: float in [left, right]:
			pen.ellipse(Vector2(x, (y0 + y1) * 0.5 + cell * 0.04), cell * 0.12, cell * 0.3, Palette.STONE)
			pen.ellipse(Vector2(x, (y0 + y1) * 0.5 + cell * 0.04), cell * 0.075, cell * 0.24, Palette.THICKET)


## A plank deck carrying the east-west road over the north-south one: as
## wide as the road's border, a little longer than the cell, boards across it,
## a rail with posts on both long sides and stone feet at both ends. No
## lanterns, so it never looks like a gate.
static func bridge(pen: InkPen, center: Vector2, cell: float) -> void:
	pen.begin(center, cell / 100.0)
	for side: float in [-1.0, 1.0]:
		pen.box(62.0 * side - 6.0, -26, 62.0 * side + 6.0, 34, Palette.STONE)
	pen.box(-62, -31, 62, 31, Palette.WOOD)
	for k: int in 12:
		var x: float = -55.0 + float(k) * 10.0
		pen.detail(Vector2(x, -27), Vector2(x, 27), 1.6, Palette.TIMBER)
	for y: float in [-31.0, 31.0]:
		pen.stroke(Vector2(-60, y - 6.0), Vector2(60, y - 6.0), 4.5, Palette.TIMBER)
		for x: float in [-56.0, 0.0, 56.0]:
			pen.box(x - 3.5, y - 12.0, x + 3.5, y, Palette.TIMBER)


## The soft shadow a deck casts on the road below it, drawn with the ground.
static func bridge_shadow(pen: InkPen, center: Vector2, cell: float) -> void:
	pen.begin(center, cell / 100.0)
	pen.detail_poly(PackedVector2Array([Vector2(-31, 30), Vector2(31, 30), Vector2(31, 44), Vector2(-31, 44)]), Palette.SHADOW)


## Two big carved chevrons on a slide tile, as wide as the road, pointing
## along `dir`, the slide's way out.
static func chevrons(pen: InkPen, center: Vector2, cell: float, dir: Vector2i) -> void:
	pen.begin(center, cell / 100.0)
	var d: Vector2 = Vector2(dir)
	var side: Vector2 = Vector2(-d.y, d.x)
	for off: float in [-18.0, 16.0]:
		var tip: Vector2 = d * (off + 12.0)
		pen.path(PackedVector2Array([tip - d * 16.0 + side * 21.0, tip, tip - d * 16.0 - side * 21.0]), 6.5, Palette.ICE_DEEP)
	# A glint: a short streak, never a dot, which could read as an eye.
	pen.detail(side * 13.0 - d * 33.0, side * 16.0 - d * 27.0, 2.0, Palette.BUBBLE)


## A hollow stump standing on the road: bark sides and roots, a pale ringed
## top with a dark hollow, and a carved crescent (`star` false, `P`) or five
## point star (`Q`) on its front in moon cream with a soft glow.
static func stump(pen: InkPen, center: Vector2, cell: float, star: bool) -> void:
	pen.begin(center, cell / 100.0)
	pen.shadow(Vector2(0, 30), 40.0)
	for side: float in [-1.0, 1.0]:
		pen.poly(PackedVector2Array([Vector2(28 * side, 14), Vector2(44 * side, 30), Vector2(20 * side, 28)]), Palette.TIMBER)
	var body: PackedVector2Array = PackedVector2Array([Vector2(-34, -16)])
	body.append_array(InkPen.arc_pts(Vector2(0, 22), 34.0, 10.0, PI, 0.0, 14))
	body.append(Vector2(34, -16))
	pen.poly(body, Palette.BARK)
	for x: float in [-24.0, -10.0, 12.0, 26.0]:
		pen.detail(Vector2(x, -10), Vector2(x * 1.04, 26), 1.6, Palette.TIMBER)
	pen.ellipse(Vector2(0, -16), 34.0, 11.0, Palette.BARK_TOP)
	pen.detail_path(_closed(InkPen.ellipse_pts(Vector2(0, -16), 26.0, 8.0, 20)), 1.4, Palette.WOOD)
	pen.ellipse(Vector2(0, -16), 18.0, 5.5, Palette.THICKET)
	var mark: Vector2 = Vector2(0, 6)
	pen.glow(mark, 20.0, Palette.MOON, 0.9)
	if star:
		var pts: PackedVector2Array = PackedVector2Array()
		for i: int in 10:
			var a: float = TAU * float(i) / 10.0 - PI / 2.0
			pts.append(mark + Vector2(cos(a), sin(a)) * (15.0 if i % 2 == 0 else 6.5) + Vector2(0, 1))
		pen.poly(pts, Palette.MOON)
	else:
		var moon: PackedVector2Array = InkPen.arc_pts(mark, 14.0, 14.0, 1.016, TAU - 1.016, 16)
		var inner: PackedVector2Array = InkPen.arc_pts(mark + Vector2(7, 0), 12.0, 12.0, -1.5384, -4.7448, 12)
		moon.append_array(inner.slice(1, inner.size() - 1))
		pen.poly(moon, Palette.MOON)


## The near mouth of a tunnel running up and down: a stone arch standing on
## `foot` with a dark opening.
static func _arch(pen: InkPen, foot: Vector2, cell: float) -> void:
	pen.poly(InkPen.arc_pts(foot, cell * 0.33, cell * 0.4, PI, TAU, 16), Palette.STONE)
	pen.poly(InkPen.arc_pts(foot, cell * 0.24, cell * 0.31, PI, TAU, 14), Palette.THICKET)
	for k: int in 5:
		var a: float = PI + PI * float(k + 1) / 6.0
		var p: Vector2 = foot + Vector2(cos(a) * cell * 0.285, sin(a) * cell * 0.355)
		var out: Vector2 = Vector2(cos(a), sin(a)) * cell * 0.045
		pen.detail(p - out, p + out, cell * 0.012, Palette.STONE_DARK)


## Grass tufts and a few flowers along a mound's back.
static func _tufts(pen: InkPen, from: Vector2, length: float, vertical: bool, cell: float) -> void:
	var n: int = maxi(1, int(length / (cell * 0.35)))
	for k: int in n + 1:
		var t: float = float(k) / float(n)
		var p: Vector2 = from + (Vector2(0, length * t) if vertical else Vector2(length * t, 0))
		if vertical:
			p += Vector2(cell * (0.12 if k % 2 == 0 else -0.1), 0)
		else:
			p += Vector2(0, cell * (0.05 if k % 2 == 0 else -0.02))
		for d: Vector2 in [Vector2(-0.04, -0.07), Vector2(0, -0.09), Vector2(0.04, -0.07)]:
			pen.detail(p, p + d * cell, cell * 0.018, Palette.MEADOW_DARK)
		if k % 2 == 1:
			pen.detail_circle(p + Vector2(cell * 0.06, cell * 0.02), cell * 0.025, Palette.PLASTER)


static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	return out
