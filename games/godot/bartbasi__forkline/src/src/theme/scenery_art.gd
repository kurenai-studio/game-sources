# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name SceneryArt
extends RefCounted
## The scenery of each region's ground (docs/art/EXPANSION_LOOK.md 3), one
## ground cell at a time. Internal to src/theme/ and its tests, like InkPen:
## other areas call MapArt.draw_ground().
##
## The rules for every region: tall things (trees, bushes, walls, stones,
## ponds) only on cells with no road beside them; near roads only small, flat
## things, so creatures stay easy to see. No buildings: only towers are
## buildings. Nothing glows cool, and nothing looks like a creature's eye or
## sparkle. No moons, stars or lanterns in regions 2 to 4, and no mist in the
## fen. Water is dark with short ripple arcs, never chevrons.


## Draws the scenery of the ground cell centered on `center`. `h` is the
## cell's fixed hash, which picks the piece and its place. `near_road`: a
## road is beside the cell.
static func draw(pen: InkPen, center: Vector2, cell: float, h: int, near_road: bool, ground: StringName) -> void:
	pen.begin(center, cell / 100.0)
	var kind: int = h % 10
	var big: bool = not near_road and kind < 5
	match ground:
		&"millbrook":
			if big and kind < 2:
				_millpond(pen, h)
			elif big and kind < 4:
				_poplar(pen, Vector2(float(h % 9) - 4.0, 30), 0.7)
			elif big:
				_clump(pen, Palette.MILLBROOK_POPLAR, Palette.MILLBROOK_POPLAR_LIGHT)
			else:
				_small_things(pen, h, near_road, [Palette.MILLBROOK_KINGCUP, Palette.MILLBROOK_MEADOWSWEET, Palette.PLASTER], Palette.MILLBROOK_GROUND_DARK)
		&"willow_fen":
			if big and kind < 2:
				_willow(pen, Vector2(float(h % 9) - 4.0, 30), 0.72)
			elif big and kind < 4:
				_peat_pool(pen, h)
			elif big:
				_reeds(pen, Vector2(0, 26), 1.0)
			else:
				_small_things(pen, h, near_road, [Palette.FEN_MARIGOLD, Palette.FEN_LILY_FLOWER], Palette.FEN_GROUND_DARK)
		&"moonspire_keep":
			if big and kind < 2:
				_wall(pen, h)
			elif big and kind < 4:
				_yew(pen, Vector2(float(h % 9) - 4.0, 28), 0.7)
			elif big:
				_clump(pen, Palette.KEEP_YEW, Palette.KEEP_YEW_LIGHT)
				for k: int in 4:
					var hk: int = (h >> (k * 3)) & 63
					pen.detail_circle(Vector2(float(hk % 8) - 3.5, float(hk / 8) - 4.0) * 4.0 + Vector2(0, 8), 3.0, Palette.KEEP_ROSE)
			else:
				_flagstones(pen, h, near_road)
		&"hollow_lanes":
			if big and kind < 3:
				_hedge(pen, h)
			elif big:
				_round_tree(pen, Vector2(float(h % 9) - 4.0, 28), 0.66, Palette.LANES_HEDGE, Palette.LANES_HEDGE_LIGHT)
			else:
				_small_things(pen, h, near_road, [Palette.LANES_BLOSSOM, Palette.LANES_PRIMROSE, Palette.LANES_HAW], Palette.LANES_GROUND_DARK)
		&"russet_orchards":
			if big and kind < 3:
				_round_tree(pen, Vector2(float(h % 9) - 4.0, 28), 0.66, Palette.ORCHARD_CANOPY_DARK, Palette.ORCHARD_CANOPY)
				for k: int in 4:
					var hk: int = (h >> (k * 3)) & 63
					pen.detail_circle(Vector2(float(hk % 8) - 3.5, float(hk / 8) - 7.5) * 5.0, 3.2, Palette.ORCHARD_APPLE)
			elif big:
				_hay_bale(pen)
			else:
				_small_things(pen, h, near_road, [Palette.ORCHARD_LEAF_RUSSET, Palette.ORCHARD_LEAF_AMBER, Palette.ORCHARD_APPLE], Palette.ORCHARD_GROUND_DARK)
		&"frostpine_ridge":
			if big and kind < 3:
				_snow_pine(pen, Vector2(float(h % 9) - 4.0, 30), 0.7)
			elif big:
				pen.shadow(Vector2(0, 20), 24.0)
				pen.poly(PackedVector2Array([Vector2(-22, 18), Vector2(-14, -4), Vector2(6, -10), Vector2(22, 4), Vector2(20, 18)]), Palette.FROST_ROCK)
				pen.poly(PackedVector2Array([Vector2(-15, -2), Vector2(6, -11), Vector2(18, 0), Vector2(4, -2)]), Palette.FROST_SNOW_CAP, false)
			else:
				# Low drifts.
				for k: int in (1 if near_road else 3):
					var hk: int = (h >> (k * 3)) & 63
					var p: Vector2 = Vector2(float(hk % 8) - 3.5, float(hk / 8) - 3.5) * 9.0
					pen.detail_poly(InkPen.arc_pts(p, 16.0, 5.0, PI, TAU, 10), Color(Palette.FROST_GROUND_LIGHT, 0.9))
		&"starglen":
			if big and kind < 2:
				_standing_stone(pen)
			elif big:
				for p: Vector3 in [Vector3(-12, 16, 10), Vector3(8, 10, 13), Vector3(20, 22, 8)]:
					_toadstool(pen, Vector2(p.x, p.y), p.z)
			else:
				for k: int in (1 if near_road else 3):
					var hk: int = (h >> (k * 3)) & 63
					var p: Vector2 = Vector2(float(hk % 8) - 3.5, float(hk / 8) - 3.5) * 9.0
					if k % 2 == 0:
						for d: Vector2 in [Vector2(-5, -8), Vector2(0, -10), Vector2(5, -8)]:
							pen.detail(p, p + d, 2.0, Palette.GLEN_FERN)
					else:
						pen.detail_circle(p, 2.0, Palette.GLEN_MOTE)
				if not near_road:
					# A small warm mote: a dot, never a four point sparkle.
					var m: Vector2 = Vector2(float(h % 30) - 15.0, -20)
					pen.glow(m, 6.0, Palette.GLEN_MOTE, 0.8)
					pen.detail_circle(m, 1.8, Palette.GLEN_MOTE)
		_:
			_lantern_hill(pen, h, near_road, kind)


# Lantern Hill, as it has always been.

static func _lantern_hill(pen: InkPen, h: int, near_road: bool, kind: int) -> void:
	if not near_road and kind < 3:
		_tree(pen, Vector2(float(h % 9) - 4.0, 28), 0.62 + float(h % 3) * 0.06, kind == 0)
	elif not near_road and kind < 5:
		_clump(pen, Palette.TREE_DARK, Palette.TREE)
	else:
		# Flowers and tufts only near roads, so creatures stay easy to see.
		var n: int = 2 if near_road else 4
		var petals: Array[Color] = [Palette.PLASTER, Palette.SPARKLE_LILAC, Palette.HONEY, Palette.HEART]
		for k: int in n:
			var hk: int = (h >> (k * 3)) & 63
			var p: Vector2 = Vector2(float(hk % 8) - 3.5, float(hk / 8) - 3.5) * 9.0
			if k % 2 == 0:
				pen.detail(p, p + Vector2(-4, -7), 2.0, Palette.MEADOW_DARK)
				pen.detail(p, p + Vector2(0, -9), 2.0, Palette.MEADOW_DARK)
				pen.detail(p, p + Vector2(4, -7), 2.0, Palette.MEADOW_DARK)
			else:
				pen.detail_circle(p, 3.2, petals[(h + k) % petals.size()])
				pen.detail_circle(p, 1.3, Palette.LANTERN)


static func _tree(pen: InkPen, foot: Vector2, k: float, pine: bool) -> void:
	if pine:
		pen.shadow(foot, 22.0 * k)
		pen.box(foot.x - 4 * k, foot.y - 12 * k, foot.x + 4 * k, foot.y, Palette.TIMBER)
		pen.poly(PackedVector2Array([foot + Vector2(-24, -10) * k, foot + Vector2(24, -10) * k, foot + Vector2(0, -46) * k]), Palette.TREE_DARK)
		pen.poly(PackedVector2Array([foot + Vector2(-18, -34) * k, foot + Vector2(18, -34) * k, foot + Vector2(0, -72) * k]), Palette.TREE)
	else:
		_round_tree(pen, foot, k, Palette.TREE_DARK, Palette.TREE)


## Two round bushes side by side.
static func _clump(pen: InkPen, dark: Color, light: Color) -> void:
	pen.shadow(Vector2(0, 24), 22.0)
	pen.circle(Vector2(-9, 14), 14.0, dark)
	pen.circle(Vector2(9, 12), 15.0, light)


static func _round_tree(pen: InkPen, foot: Vector2, k: float, dark: Color, light: Color) -> void:
	pen.shadow(foot, 22.0 * k)
	pen.box(foot.x - 5 * k, foot.y - 26 * k, foot.x + 5 * k, foot.y, Palette.TIMBER)
	pen.circle(foot + Vector2(-13, -36) * k, 17.0 * k, dark)
	pen.circle(foot + Vector2(13, -38) * k, 17.0 * k, dark)
	pen.circle(foot + Vector2(0, -52) * k, 20.0 * k, light)


## Tufts of grass and small flowers.
static func _small_things(pen: InkPen, h: int, near_road: bool, petals: Array[Color], grass: Color) -> void:
	var n: int = 2 if near_road else 4
	for k: int in n:
		var hk: int = (h >> (k * 3)) & 63
		var p: Vector2 = Vector2(float(hk % 8) - 3.5, float(hk / 8) - 3.5) * 9.0
		if k % 2 == 0:
			for d: Vector2 in [Vector2(-4, -7), Vector2(0, -9), Vector2(4, -7)]:
				pen.detail(p, p + d, 2.0, grass)
		else:
			pen.detail_circle(p, 3.2, petals[(h + k) % petals.size()])


# 2 Millbrook.

## A millpond inside one ground cell: a dark pool in a darker grass bank, two
## ripple arcs (never dots, so nothing looks like an eye) and kingcups.
static func _millpond(pen: InkPen, h: int) -> void:
	var c: Vector2 = Vector2(float(h % 7) - 3.0, 6)
	pen.ellipse(c, 42.0, 26.0, Palette.MILLBROOK_GROUND_DARK, false)
	pen.ellipse(c, 36.0, 20.0, Palette.MILLBROOK_WATER)
	pen.detail_path(InkPen.arc_pts(c + Vector2(-8, -2), 14.0, 4.0, PI * 1.15, PI * 1.85, 8), 2.0, Palette.MILLBROOK_RIPPLE)
	pen.detail_path(InkPen.arc_pts(c + Vector2(12, 8), 10.0, 3.0, PI * 1.15, PI * 1.85, 8), 2.0, Palette.MILLBROOK_RIPPLE)
	for p: Vector2 in [Vector2(-34, -10), Vector2(-30, 14), Vector2(32, 16)]:
		pen.detail_circle(c + p, 3.4, Palette.MILLBROOK_KINGCUP)


## A tall, narrow poplar: one feathery spindle, unlike the round trees and the
## layered pines.
static func _poplar(pen: InkPen, foot: Vector2, k: float) -> void:
	pen.shadow(foot, 16.0 * k)
	pen.box(foot.x - 4 * k, foot.y - 14 * k, foot.x + 4 * k, foot.y, Palette.TIMBER)
	var crown: PackedVector2Array = PackedVector2Array()
	for i: int in 24:
		var a: float = TAU * float(i) / 24.0
		var wob: float = 1.0 if i % 2 == 0 else 0.9
		crown.append(foot + Vector2(cos(a) * 17.0 * wob, -52.0 + sin(a) * 44.0 * wob) * k)
	pen.poly(crown, Palette.MILLBROOK_POPLAR)
	pen.detail_poly(InkPen.ellipse_pts(foot + Vector2(-5, -60) * k, 7.0 * k, 28.0 * k, 12), Palette.MILLBROOK_POPLAR_LIGHT)


# 3 Willow Fen.

## A weeping willow: a trunk under a round crown, with long fronds hanging
## past the crown on both sides nearly to the ground. Open strands, not a solid
## dome, so it never reads as a bell.
static func _willow(pen: InkPen, foot: Vector2, k: float) -> void:
	pen.shadow(foot, 26.0 * k)
	pen.box(foot.x - 5 * k, foot.y - 40 * k, foot.x + 5 * k, foot.y, Palette.TIMBER)
	pen.circle(foot + Vector2(-14, -50) * k, 16.0 * k, Palette.FEN_WILLOW_DARK)
	pen.circle(foot + Vector2(14, -50) * k, 16.0 * k, Palette.FEN_WILLOW_DARK)
	pen.circle(foot + Vector2(0, -60) * k, 18.0 * k, Palette.FEN_WILLOW_DARK)
	for x: float in [-30.0, -22.0, 22.0, 30.0, -8.0, 8.0]:
		var top: Vector2 = foot + Vector2(x * 0.8, -50) * k
		var tip: Vector2 = foot + Vector2(x * 1.1, -10.0 + absf(x) * 0.2) * k
		pen.stroke(top, tip, 3.6 * k, Palette.FEN_WILLOW)
	pen.detail_poly(InkPen.ellipse_pts(foot + Vector2(-6, -66) * k, 12.0 * k, 6.0 * k, 12), Palette.FEN_WILLOW)


## A dark peat pool with lily pads and a few reeds at its back.
static func _peat_pool(pen: InkPen, h: int) -> void:
	var c: Vector2 = Vector2(float(h % 7) - 3.0, 10)
	_reeds(pen, c + Vector2(18, -8), 0.6)
	pen.ellipse(c, 38.0, 20.0, Palette.FEN_PEAT)
	for p: Vector3 in [Vector3(-14, 2, 7), Vector3(8, 6, 6), Vector3(-2, -8, 5)]:
		var pc: Vector2 = c + Vector2(p.x, p.y)
		var pad: PackedVector2Array = InkPen.arc_pts(pc, p.z, p.z * 0.6, 0.5, TAU - 0.1, 10)
		pad.append(pc)
		pen.detail_poly(pad, Palette.FEN_LILY)
	pen.detail_circle(c + Vector2(-14, 0), 2.6, Palette.FEN_LILY_FLOWER)


## A clump of reeds: thin stems and cattail heads.
static func _reeds(pen: InkPen, foot: Vector2, k: float) -> void:
	for i: int in 6:
		var x: float = (float(i) - 2.5) * 6.0
		var top: Vector2 = foot + Vector2(x * 1.4, -46.0 - float((i * 7) % 3) * 8.0) * k
		pen.detail(foot + Vector2(x, 0) * k, top, 2.4 * k, Palette.FEN_REED)
		if i % 2 == 1:
			pen.detail_poly(InkPen.ellipse_pts(top + Vector2(0, 10) * k, 3.4 * k, 8.0 * k, 10), Palette.FEN_REED_HEAD)


# 4 Moonspire Keep.

## A low, broken length of old wall with ivy. The top slopes where it broke:
## no merlons, which belong to the Longbow Loft and the Snow Fort.
static func _wall(pen: InkPen, h: int) -> void:
	var flip: float = 1.0 if h % 2 == 0 else -1.0
	pen.shadow(Vector2(0, 22), 36.0)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-34, 20), Vector2(-34, -6), Vector2(-12, -6), Vector2(-4, -2), Vector2(8, 4), Vector2(20, 2), Vector2(34, 10), Vector2(34, 20)])
	for i: int in pts.size():
		pts[i] = Vector2(pts[i].x * flip, pts[i].y)
	pen.poly(pts, Palette.STONE)
	for y: float in [4.0, 12.0]:
		pen.detail(Vector2(-31 * flip, y), Vector2(30 * flip, y), 1.4, Palette.STONE_DARK)
	for p: Vector2 in [Vector2(-22, -6), Vector2(-4, 4), Vector2(14, 12), Vector2(-14, 12)]:
		pen.detail(Vector2(p.x * flip, p.y), Vector2(p.x * flip, p.y + 8.0), 1.4, Palette.STONE_DARK)
	for p: Vector3 in [Vector3(-30, -4, 7), Vector3(-24, 4, 6), Vector3(-30, 12, 6), Vector3(-18, -4, 4)]:
		pen.detail_circle(Vector2(p.x * flip, p.y), p.z, Palette.KEEP_IVY)


## A clipped yew: a smooth cone with a round tip.
static func _yew(pen: InkPen, foot: Vector2, k: float) -> void:
	pen.shadow(foot, 18.0 * k)
	var cone: PackedVector2Array = PackedVector2Array([foot + Vector2(-20, -4) * k])
	cone.append_array(InkPen.arc_pts(foot + Vector2(0, -66) * k, 6.0 * k, 6.0 * k, PI, TAU, 6))
	cone.append(foot + Vector2(20, -4) * k)
	pen.poly(cone, Palette.KEEP_YEW)
	pen.detail_poly(PackedVector2Array([foot + Vector2(-14, -10) * k, foot + Vector2(-3, -62) * k, foot + Vector2(-4, -12) * k]), Palette.KEEP_YEW_LIGHT)


## Old flagstones set flat in the turf, with a few rose petals and tufts.
static func _flagstones(pen: InkPen, h: int, near_road: bool) -> void:
	for k: int in (1 if near_road else 2):
		var hk: int = (h >> (k * 4)) & 63
		var p: Vector2 = Vector2(float(hk % 8) - 3.5, float(hk / 8) - 3.5) * 8.0
		var w: float = 9.0 + float(hk % 3) * 3.0
		pen.detail_poly(PackedVector2Array([p + Vector2(-w, -6), p + Vector2(w - 2, -7), p + Vector2(w, 6), p + Vector2(-w + 2, 7)]), Palette.KEEP_FLAG)
	_small_things(pen, h >> 5, near_road, [Palette.KEEP_ROSE, Palette.PLASTER], Palette.KEEP_GROUND_DARK)


# 5 Hollow Lanes.

## A hedge clump with blackberries and red haws.
static func _hedge(pen: InkPen, h: int) -> void:
	pen.shadow(Vector2(0, 26), 34.0)
	for p: Vector3 in [Vector3(-16, 8, 18), Vector3(16, 6, 19), Vector3(0, -8, 22)]:
		pen.circle(Vector2(p.x, p.y), p.z, Palette.LANES_HEDGE if p.y > 0.0 else Palette.LANES_HEDGE_LIGHT)
	for k: int in 5:
		var hk: int = (h >> (k * 3)) & 63
		var p: Vector2 = Vector2(float(hk % 8) - 3.5, float(hk / 8) - 4.5) * 5.0
		pen.detail_circle(p, 3.0, Palette.LANES_BERRY if k % 2 == 0 else Palette.LANES_HAW)


# 6 Russet Orchards.

## A round hay bale seen from the side, its rolled end to the left.
static func _hay_bale(pen: InkPen) -> void:
	pen.shadow(Vector2(0, 24), 24.0)
	pen.box(-20, -4, 20, 22, Palette.ORCHARD_HAY)
	pen.ellipse(Vector2(-20, 9), 7.0, 13.0, Palette.ORCHARD_HAY_DARK)
	pen.detail_path(_closed(InkPen.ellipse_pts(Vector2(-20, 9), 3.5, 7.0, 10)), 1.4, Palette.ORCHARD_HAY)
	pen.detail(Vector2(-8, -4), Vector2(-8, 22), 1.4, Palette.ORCHARD_HAY_DARK)
	pen.detail(Vector2(8, -4), Vector2(8, 22), 1.4, Palette.ORCHARD_HAY_DARK)


# 7 Frostpine Ridge.

static func _snow_pine(pen: InkPen, foot: Vector2, k: float) -> void:
	pen.shadow(foot, 22.0 * k)
	pen.box(foot.x - 4 * k, foot.y - 12 * k, foot.x + 4 * k, foot.y, Palette.TIMBER)
	pen.poly(PackedVector2Array([foot + Vector2(-26, -10) * k, foot + Vector2(26, -10) * k, foot + Vector2(0, -50) * k]), Palette.FROST_PINE)
	pen.poly(PackedVector2Array([foot + Vector2(-19, -36) * k, foot + Vector2(19, -36) * k, foot + Vector2(0, -78) * k]), Palette.FROST_PINE_LIGHT)
	pen.poly(PackedVector2Array([foot + Vector2(-9, -60) * k, foot + Vector2(9, -60) * k, foot + Vector2(0, -78) * k]), Palette.FROST_SNOW_CAP, false)
	pen.detail_poly(PackedVector2Array([foot + Vector2(-20, -11) * k, foot + Vector2(-6, -19) * k, foot + Vector2(8, -14) * k,
		foot + Vector2(22, -11) * k, foot + Vector2(6, -12) * k, foot + Vector2(-6, -13) * k]), Palette.FROST_SNOW_CAP)


# 8 Starglen.

## A tall standing stone with moss at its foot.
static func _standing_stone(pen: InkPen) -> void:
	pen.shadow(Vector2(0, 28), 18.0)
	pen.poly(PackedVector2Array([Vector2(-13, 28), Vector2(-15, -10), Vector2(-6, -36), Vector2(8, -32), Vector2(14, -6), Vector2(13, 28)]), Palette.GLEN_STONE)
	pen.detail_poly(PackedVector2Array([Vector2(-13, 28), Vector2(-14, 8), Vector2(0, 14), Vector2(13, 6), Vector2(13, 28)]), Palette.GLEN_STONE_MOSS)
	pen.detail_path(PackedVector2Array([Vector2(-4, -20), Vector2(2, -12), Vector2(-3, -4)]), 1.6, Palette.STONE_DARK)


## A toadstool that glows warm peach, never cool.
static func _toadstool(pen: InkPen, foot: Vector2, r: float) -> void:
	pen.glow(foot + Vector2(0, -r), r * 2.2, Palette.GLEN_CAP_GLOW, 0.8)
	pen.box(foot.x - r * 0.25, foot.y - r * 0.9, foot.x + r * 0.25, foot.y, Palette.GLEN_STEM)
	pen.poly(InkPen.arc_pts(foot + Vector2(0, -r * 0.8), r, r * 0.75, PI, TAU, 12), Palette.GLEN_CAP)
	pen.detail_circle(foot + Vector2(-r * 0.3, -r * 1.15), r * 0.15, Palette.GLEN_CAP_GLOW)


static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	return out
