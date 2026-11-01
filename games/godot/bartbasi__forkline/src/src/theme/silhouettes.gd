# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Silhouettes
extends RefCounted
## Draws every tower and creature in the dusk storybook look (docs/art/THEME.md).
## Ids and names are in docs/art/NAMES.md.
##
## Towers: `center` is the cell center and `size` the cell side, in canvas
## pixels. The building stands on the build spot with its ground line at
## center.y + 0.30 * size. It stays within 0.52 * size left and right of the
## center and reaches at most 0.85 * size above it, so a tall tower may cover
## the lower part of the cell above. Tiers and specs follow one rule:
## - Tier 1 is the plain building.
## - Each tier above 1 adds one stone step under the building (tier 2: one,
##   tier 3: two), so the building stands higher and its base gets wider.
## - At tier 3 the spec replaces the tower's signature piece (roof, arm, bell
##   top, bow, rockets, chimney). The building below it never changes.
##
## Creatures: `center` is the creature's position and `size` the side of its
## drawing box (enemy_size() gives the box for a map cell). Walkers stand with
## their feet at center.y + 0.36 * size, facing right; flip the node to face
## left. Flyers hover above a separate shadow, so flying never shows by color
## alone. `frame` steps the walk or flap cycle (4 frames, any int works).
##
## Every draw function takes an optional `flat` color. With it, the whole
## drawing is that one color: the silhouette.
##
## Status marks (draw_mark) are drawn over a creature or tower by the render,
## each a shape of its own, so no status shows by color alone.

## Every tower, creature and boss with a drawing, each list in campaign order:
## the first four regions' cast, then the expansion's (contract 14.1). What the
## game shows comes from the catalog (data/stats/), not from these lists.
const TOWERS: Array[StringName] = [&"sling_post", &"pumpkin_catapult", &"lullaby_bell", &"longbow_loft", &"firework_tower", &"bakery", &"bramble_cottage", &"scarecrow", &"snow_fort", &"moth_lantern"]
## Spec ids per tower: index 0 and 1 are the `spec` argument at tier 3.
const SPECS: Dictionary[StringName, Array] = {
	&"sling_post": [&"quickshot", &"stone_sling"],
	&"pumpkin_catapult": [&"prize_pumpkin", &"jam_pot"],
	&"lullaby_bell": [&"hush_bell", &"night_bell"],
	&"longbow_loft": [&"giant_bow", &"triple_bow"],
	&"firework_tower": [&"star_bloom", &"skyrocket"],
	&"bakery": [&"grand_oven", &"spice_kitchen"],
	&"bramble_cottage": [&"wild_bramble", &"holly_crown"],
	&"scarecrow": [&"tall_scarecrow", &"crow_keeper"],
	&"snow_fort": [&"big_snowball", &"flurry"],
	&"moth_lantern": [&"beacon_lantern", &"lantern_garland"],
}
const CREATURES: Array[StringName] = [
	&"scamp", &"pip", &"skitter", &"flitter", &"shellback", &"bubbler", &"puffball", &"puff", &"mender", &"gatecrasher", &"dusk_moth",
	&"mossbud", &"mistwisp", &"gleamer", &"sleepyhead", &"snowroller", &"yawner", &"blinker", &"hootling",
]
const BOSSES: Array[StringName] = [&"grumblesack", &"ironshell", &"moon_moth", &"old_tusk", &"burrowbelly", &"old_hayrick", &"snowsnore", &"glimmertoad"]
const FLYERS: Array[StringName] = [&"flitter", &"dusk_moth", &"moon_moth"]
## Drawing box per creature, as a fraction of the map cell. On the Fold5 cover
## screen a cell is about 49 dp, so a Scamp is about 28 dp and a boss about 57 dp.
## A Snowroller or Snowsnore that grows is drawn up to 1.5 times this (the render scales it).
const ENEMY_SIZE: Dictionary[StringName, float] = {
	&"scamp": 0.58, &"pip": 0.4, &"skitter": 0.6, &"flitter": 0.56, &"shellback": 0.72,
	&"bubbler": 0.6, &"puffball": 0.68, &"puff": 0.4, &"mender": 0.62, &"gatecrasher": 0.76,
	&"dusk_moth": 0.68, &"grumblesack": 1.16, &"ironshell": 1.16, &"moon_moth": 1.2, &"old_tusk": 1.2,
	&"mossbud": 0.6, &"mistwisp": 0.56, &"gleamer": 0.66, &"sleepyhead": 0.6, &"snowroller": 0.6,
	&"yawner": 0.7, &"blinker": 0.56, &"hootling": 0.6,
	&"burrowbelly": 1.16, &"old_hayrick": 1.16, &"snowsnore": 1.2, &"glimmertoad": 1.2,
}
## The status marks of the expansion (contract 14.9, docs/art/EXPANSION_LOOK.md 5).
const MARKS: Array[StringName] = [&"hidden", &"napping", &"fright", &"awake", &"doze", &"low", &"dug"]
## Tower ground line below the cell center, as a fraction of the cell.
const TOWER_GROUND: float = 0.30
## Creature feet below the creature center, as a fraction of its box.
const FEET: float = 0.36
const STEP_HEIGHT: float = 8.0

const NO_FLAT: Color = Color(0.0, 0.0, 0.0, 0.0)


# Public API (contract 3.9).

static func draw_tower(canvas: CanvasItem, type: StringName, tier: int, spec: int, center: Vector2, size: float, flat: Color = NO_FLAT) -> void:
	tower_into(InkPen.new(canvas, flat), type, tier, spec, center, size)


static func draw_enemy(canvas: CanvasItem, type: StringName, center: Vector2, size: float, frame: int, flat: Color = NO_FLAT) -> void:
	enemy_into(InkPen.new(canvas, flat), type, center, size, frame)


## The drawing box side for a creature on a map with cells of `cell` pixels.
static func enemy_size(type: StringName, cell: float) -> float:
	var k: float = ENEMY_SIZE.get(type, 0.6)
	return k * cell


static func has_tower(type: StringName) -> bool:
	return TOWERS.has(type)


static func has_enemy(type: StringName) -> bool:
	return CREATURES.has(type) or BOSSES.has(type)


static func is_flyer(type: StringName) -> bool:
	return FLYERS.has(type)


## The bubble ring around a Bubbler while its bubble is up.
static func draw_bubble(canvas: CanvasItem, center: Vector2, size: float) -> void:
	var pen: InkPen = InkPen.new(canvas)
	pen.line_px = clampf(size * 0.03, 1.5, 4.0)
	pen.begin(center, size / 100.0)
	pen.path(_closed(InkPen.ellipse_pts(Vector2(0, 0), 50.0, 50.0, 40)), 4.0, Palette.BUBBLE)
	pen.detail_path(InkPen.arc_pts(Vector2(0, 0), 40.0, 40.0, -2.6, -1.9, 6), 4.0, Palette.BUBBLE)


## The drowsy "z z" mark over a slowed creature.
static func draw_drowsy(canvas: CanvasItem, center: Vector2, size: float, frame: int) -> void:
	var pen: InkPen = InkPen.new(canvas)
	pen.line_px = clampf(size * 0.035, 1.5, 4.0)
	pen.begin(center, size / 100.0)
	var lift: float = float(frame % 4) * 2.0
	for i: int in 2:
		var s: float = 13.0 - float(i) * 4.0
		var o: Vector2 = Vector2(6.0 + float(i) * 18.0, -62.0 - float(i) * 14.0 - lift)
		pen.path(PackedVector2Array([o, o + Vector2(s, 0), o + Vector2(0, s), o + Vector2(s, s)]), 4.0, Palette.FLOUR)


## The double chevron beside a tower that a Bakery boosts.
static func draw_boost(canvas: CanvasItem, center: Vector2, size: float) -> void:
	var pen: InkPen = InkPen.new(canvas)
	pen.line_px = clampf(size * 0.025, 1.5, 4.0)
	pen.begin(center, size / 100.0)
	for i: int in 2:
		var y: float = -8.0 - float(i) * 10.0
		pen.path(PackedVector2Array([Vector2(36, y + 6), Vector2(43, y), Vector2(50, y + 6)]), 4.0, Palette.LANTERN)


## A status mark from MARKS (contract 14.9). The render picks which marks a
## creature or tower wears.
##
## Every mark but &"doze" goes over a creature: `center` and `size` are its
## position and box, as for draw_enemy(). Each stays within 0.6 * size left and
## right of the center, 0.7 * size above it and 0.6 * size below it.
## - &"hidden": the Mistwisp's curl, small, above the head.
## - &"napping": a small crescent moon above the head. The render lays the
##   creature on its side.
## - &"fright": two zigzag shiver lines on each side.
## - &"awake": a small open eye above the head.
## - &"low": a pale ring on the shadow line, center.y + 0.40 * size. The render
##   draws the lured flyer just above it.
## - &"dug": a dirt mound with claw tips standing on the feet line, drawn in
##   place of the creature. `frame` (4 frames) moves its clods and claws.
## &"doze" goes over a tower: `center` and `size` are the cell center and side,
## as for draw_tower(). It is one big "z" at the top right, inside the
## tower's box.
static func draw_mark(canvas: CanvasItem, mark: StringName, center: Vector2, size: float, frame: int = 0) -> void:
	mark_into(InkPen.new(canvas), mark, center, size, frame)


## Small icons for the HUD and cards: &"heart", &"coin", &"moon", &"star",
## &"gate". `size` is the icon's box side.
static func draw_glyph(canvas: CanvasItem, glyph: StringName, center: Vector2, size: float, flat: Color = NO_FLAT) -> void:
	var pen: InkPen = InkPen.new(canvas, flat)
	pen.line_px = clampf(size * 0.06, 1.0, 4.0)
	pen.begin(center, size / 100.0)
	match glyph:
		&"heart":
			var pts: PackedVector2Array = PackedVector2Array()
			for i: int in 32:
				var a: float = TAU * float(i) / 32.0
				pts.append(Vector2(16.0 * pow(sin(a), 3.0), -(13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a))) * 2.6 + Vector2(0, -4))
			pen.poly(pts, Palette.HEART)
		&"coin":
			pen.circle(Vector2.ZERO, 40.0, Palette.COIN)
			pen.detail_path(_closed(InkPen.ellipse_pts(Vector2.ZERO, 28.0, 28.0, 24)), 5.0, Palette.ROOF_CLAY)
			pen.star(Vector2.ZERO, 17.0, Palette.ROOF_CLAY)
		&"moon":
			var outer: PackedVector2Array = InkPen.arc_pts(Vector2.ZERO, 40.0, 40.0, 1.016, TAU - 1.016, 24)
			var inner: PackedVector2Array = InkPen.arc_pts(Vector2(20.0, 0.0), 34.0, 34.0, -1.5384, -4.7448, 18)
			outer.append_array(inner.slice(1, inner.size() - 1))
			pen.poly(outer, Palette.MOON)
		&"star":
			var pts: PackedVector2Array = PackedVector2Array()
			for i: int in 10:
				var a: float = TAU * float(i) / 10.0 - PI / 2.0
				var r: float = 44.0 if i % 2 == 0 else 19.0
				pts.append(Vector2(cos(a), sin(a)) * r + Vector2(0, 3))
			pen.poly(pts, Palette.HONEY)
		&"gate":
			pen.box(-34, -18, 34, 18, Palette.WOOD)
			for x: float in [-17.0, 0.0, 17.0]:
				pen.detail(Vector2(x, -15), Vector2(x, 15), 3.0, Palette.TIMBER)
			pen.stroke(Vector2(-40, 30), Vector2(-40, -34), 8.0, Palette.TIMBER)
			pen.stroke(Vector2(40, 30), Vector2(40, -34), 8.0, Palette.TIMBER)
			pen.circle(Vector2(-40, -40), 7.0, Palette.LANTERN)
			pen.circle(Vector2(40, -40), 7.0, Palette.LANTERN)
		_:
			pen.circle(Vector2.ZERO, 30.0, Palette.STONE)


# Drawing into a pen. Used by the public functions above and by the tests.

static func tower_into(pen: InkPen, type: StringName, tier: int, spec: int, center: Vector2, size: float) -> void:
	var t: int = clampi(tier, 1, 3)
	var s: int = spec if t == 3 else -1
	var scale: float = size / 100.0
	var ground: Vector2 = center + Vector2(0.0, TOWER_GROUND * size)
	pen.line_px = clampf(size * 0.03, 1.2, 5.0)
	pen.begin(ground, scale)
	pen.shadow(Vector2(0, -1), 44.0)
	# Stone steps: one per tier above 1, each narrower than the one below.
	for i: int in t - 1:
		var half: float = 45.0 - float(i) * 6.0
		var y0: float = -STEP_HEIGHT * float(i)
		pen.box(-half, y0 - STEP_HEIGHT, half, y0, Palette.STONE)
		pen.detail(Vector2(-half + 4.0, y0 - STEP_HEIGHT * 0.5), Vector2(half - 4.0, y0 - STEP_HEIGHT * 0.5), 1.2, Palette.STONE_DARK)
	pen.begin(ground + Vector2(0.0, -STEP_HEIGHT * float(t - 1) * scale), scale)
	match type:
		&"sling_post":
			_sling_post(pen, s)
		&"pumpkin_catapult":
			_pumpkin_catapult(pen, s)
		&"lullaby_bell":
			_lullaby_bell(pen, s)
		&"longbow_loft":
			_longbow_loft(pen, s)
		&"firework_tower":
			_firework_tower(pen, s)
		&"bakery":
			_bakery(pen, s)
		&"bramble_cottage":
			_bramble_cottage(pen, s)
		&"scarecrow":
			_scarecrow(pen, s)
		&"snow_fort":
			_snow_fort(pen, s)
		&"moth_lantern":
			_moth_lantern(pen, s)
		_:
			pen.box(-30, -60, 30, 0, Palette.STONE)


static func enemy_into(pen: InkPen, type: StringName, center: Vector2, size: float, frame: int) -> void:
	var f: int = posmod(frame, 4)
	pen.line_px = clampf(size * 0.045, 1.2, 5.0)
	pen.begin(center, size / 100.0)
	match type:
		&"scamp":
			_scamp(pen, f)
		&"pip":
			_pip(pen, f)
		&"skitter":
			_skitter(pen, f)
		&"flitter":
			_flitter(pen, f)
		&"shellback":
			_shellback(pen, f, false)
		&"bubbler":
			_bubbler(pen, f)
		&"puffball":
			_puffball(pen, f)
		&"puff":
			_puff(pen, f)
		&"mender":
			_mender(pen, f)
		&"gatecrasher":
			_gatecrasher(pen, f)
		&"dusk_moth":
			_moth(pen, f, false)
		&"grumblesack":
			_grumblesack(pen, f)
		&"ironshell":
			_shellback(pen, f, true)
		&"moon_moth":
			_moth(pen, f, true)
		&"old_tusk":
			_old_tusk(pen, f)
		&"mossbud":
			_mossbud(pen, f)
		&"mistwisp":
			_mistwisp(pen, f)
		&"gleamer":
			_gleamer(pen, f)
		&"sleepyhead":
			_sleepyhead(pen, f)
		&"snowroller":
			_snowroller(pen, f)
		&"yawner":
			_yawner(pen, f)
		&"blinker":
			_blinker(pen, f)
		&"hootling":
			_hootling(pen, f)
		&"burrowbelly":
			_burrowbelly(pen, f)
		&"old_hayrick":
			_old_hayrick(pen, f)
		&"snowsnore":
			_snowsnore(pen, f)
		&"glimmertoad":
			_glimmertoad(pen, f)
		_:
			pen.circle(Vector2(0, 6), 28.0, Palette.CREATURE_BASIC)


## A status mark into a pen. See draw_mark().
static func mark_into(pen: InkPen, mark: StringName, center: Vector2, size: float, frame: int) -> void:
	var f: int = posmod(frame, 4)
	pen.line_px = clampf(size * 0.035, 1.5, 4.0)
	pen.begin(center, size / 100.0)
	match mark:
		&"hidden":
			# The Mistwisp's own curl, small, above the head: it teaches the link.
			pen.path(PackedVector2Array([Vector2(-8, -48), Vector2(-4, -60), Vector2(6, -64), Vector2(12, -57), Vector2(6, -51), Vector2(2, -56)]), 4.0, Palette.CREATURE_MIST_CURL)
		&"napping":
			# A small crescent moon above the head.
			var moon: PackedVector2Array = InkPen.arc_pts(Vector2(10, -50), 9.0, 9.0, 1.016, TAU - 1.016, 12)
			var inner: PackedVector2Array = InkPen.arc_pts(Vector2(14.5, -50), 7.7, 7.7, -1.5384, -4.7448, 10)
			moon.append_array(inner.slice(1, inner.size() - 1))
			pen.poly(moon, Palette.MOON)
		&"fright":
			# Two small zigzag shiver lines on each side.
			for side: float in [-1.0, 1.0]:
				for k: int in 2:
					var x: float = (40.0 + 8.0 * float(k)) * side
					pen.path(PackedVector2Array([Vector2(x, -16), Vector2(x + 4 * side, -10), Vector2(x, -4), Vector2(x + 4 * side, 2)]), 3.5, Palette.FLOUR)
		&"awake":
			# A small open eye above the head.
			var lid: PackedVector2Array = InkPen.arc_pts(Vector2(0, -54), 14.0, 8.0, PI, TAU, 10)
			lid.append_array(InkPen.arc_pts(Vector2(0, -54), 14.0, 8.0, 0.0, PI, 10))
			pen.poly(lid, Palette.FLOUR)
			pen.detail_circle(Vector2(0, -54), 4.5, Palette.INK_LINE)
		&"doze":
			# One big "z" at the tower's top right, unlike a slowed creature's
			# smaller "z z". It stays inside the tower's box.
			var o: Vector2 = Vector2(22, -80)
			var s: float = 18.0
			pen.path(PackedVector2Array([o, o + Vector2(s, 0), o + Vector2(0, s), o + Vector2(s, s)]), 5.0, Palette.FLOUR)
		&"low":
			# A pale ring at the shadow line, under a flyer pulled low.
			pen.path(_closed(InkPen.ellipse_pts(Vector2(0, 40), 26.0, 8.0, 24)), 3.5, Palette.BUBBLE)
		&"dug":
			# A dirt mound with claw tips, in place of the creature. The clods
			# and claws shift as it moves.
			var hop: float = -3.0 if f % 2 == 1 else 0.0
			var dig: float = 2.0 if f >= 2 else 0.0
			pen.poly(InkPen.arc_pts(Vector2(0, 34), 34.0, 22.0, PI, TAU, 16), Palette.DIRT)
			var clods: PackedVector2Array = PackedVector2Array([Vector2(-30, 30), Vector2(30, 32), Vector2(-14, 18), Vector2(12, 16)])
			for k: int in clods.size():
				pen.circle(clods[k] + Vector2(0, hop if k % 2 == 0 else 0.0), 5.0, Palette.DIRT.darkened(0.2))
			for k: int in 3:
				var x: float = 16.0 + float(k) * 6.0 + dig
				pen.poly(PackedVector2Array([Vector2(x, 14), Vector2(x + 5, 14), Vector2(x + 4, 4)]), Palette.BONE)
		_:
			pass


# Towers. Local units: 100 is one cell, ground at y 0, up is negative.

static func _sling_post(pen: InkPen, spec: int) -> void:
	pen.poly(PackedVector2Array([Vector2(-38, 0), Vector2(-28, 0), Vector2(-16, -46), Vector2(-25, -46)]), Palette.WOOD)
	pen.poly(PackedVector2Array([Vector2(28, 0), Vector2(38, 0), Vector2(25, -46), Vector2(16, -46)]), Palette.WOOD)
	pen.stroke(Vector2(-29, -8), Vector2(18, -40), 4.0, Palette.TIMBER)
	pen.stroke(Vector2(29, -8), Vector2(-18, -40), 4.0, Palette.TIMBER)
	pen.box(-33, -52, 33, -45, Palette.WOOD)
	pen.box(-23, -70, 23, -52, Palette.PLASTER)
	pen.window(-8, -67, 8, -55)
	if spec == 0:
		# Quickshot: two cabins side by side, a double peak.
		pen.poly(PackedVector2Array([Vector2(-34, -68), Vector2(4, -68), Vector2(-15, -92)]), Palette.ROOF_CLAY)
		pen.poly(PackedVector2Array([Vector2(-4, -68), Vector2(34, -68), Vector2(15, -92)]), Palette.ROOF_CLAY)
		pen.stroke(Vector2(-23, -58), Vector2(-33, -58), 3.0, Palette.TIMBER, false)
		pen.lantern(Vector2(-36, -48), 4.5)
		pen.stroke(Vector2(23, -58), Vector2(33, -58), 3.0, Palette.TIMBER, false)
		pen.lantern(Vector2(36, -48), 4.5)
	elif spec == 1:
		# Stone Sling: a boulder in a net hangs from a beam off the roof.
		pen.poly(PackedVector2Array([Vector2(-31, -68), Vector2(31, -68), Vector2(0, -92)]), Palette.ROOF_CLAY)
		pen.stroke(Vector2(-6, -86), Vector2(38, -76), 4.0, Palette.TIMBER)
		pen.stroke(Vector2(36, -76), Vector2(36, -66), 1.5, Palette.TIMBER, false)
		pen.circle(Vector2(36, -56), 11.0, Palette.STONE)
		pen.detail_path(PackedVector2Array([Vector2(26, -60), Vector2(36, -50), Vector2(46, -60)]), 1.4, Palette.TIMBER)
		pen.detail(Vector2(36, -67), Vector2(36, -45), 1.4, Palette.TIMBER)
		pen.stroke(Vector2(-23, -58), Vector2(-33, -58), 3.0, Palette.TIMBER, false)
		pen.lantern(Vector2(-36, -48), 4.5)
	else:
		pen.poly(PackedVector2Array([Vector2(-31, -68), Vector2(31, -68), Vector2(0, -92)]), Palette.ROOF_CLAY)
		pen.stroke(Vector2(23, -58), Vector2(33, -58), 3.0, Palette.TIMBER, false)
		pen.lantern(Vector2(36, -48), 4.5)


static func _pumpkin_catapult(pen: InkPen, spec: int) -> void:
	# The arm first, so the shed sits in front of its lower end.
	var cup: Vector2 = Vector2(30, -58)
	pen.stroke(Vector2(28, 0), Vector2(20, -30), 5.0, Palette.WOOD)
	pen.stroke(Vector2(44, 0), Vector2(22, -30), 5.0, Palette.WOOD)
	pen.stroke(Vector2(2, -20), cup, 6.0, Palette.WOOD)
	pen.circle(Vector2(21, -31), 4.0, Palette.TIMBER)
	if spec == 0:
		# Prize Pumpkin: a huge pumpkin in a bigger cup.
		_pumpkin(pen, cup + Vector2(0, -15), 17.0, 14.0)
	elif spec == 1:
		# Jam Pot: a jar with a tied cloth lid.
		var c: Vector2 = cup + Vector2(0, -12)
		pen.poly(PackedVector2Array([c + Vector2(-11, -9), c + Vector2(11, -9), c + Vector2(13, 4), c + Vector2(8, 12), c + Vector2(-8, 12), c + Vector2(-13, 4)]), Palette.JAM)
		pen.poly(PackedVector2Array([c + Vector2(-16, -9), c + Vector2(16, -9), c + Vector2(11, -17), c + Vector2(-11, -17)]), Palette.PLASTER)
		pen.circle(c + Vector2(0, -21), 4.5, Palette.PLASTER)
		pen.detail_circle(c + Vector2(-4, 1), 2.6, Palette.LANTERN_CORE)
		pen.detail_circle(c + Vector2(9, 14), 2.0, Palette.JAM)
	else:
		_pumpkin(pen, cup + Vector2(0, -10), 12.0, 10.0)
	pen.box(-44, -30, 10, 0, Palette.PLASTER)
	pen.detail(Vector2(-44, -15), Vector2(10, -15), 2.0, Palette.TIMBER)
	pen.box(-24, -15, -12, 0, Palette.TIMBER)
	pen.window(-38, -26, -28, -17)
	pen.window(-8, -26, 2, -17)
	pen.poly(PackedVector2Array([Vector2(-50, -27), Vector2(16, -27), Vector2(-17, -54)]), Palette.ROOF_MOSS)


static func _pumpkin(pen: InkPen, c: Vector2, rx: float, ry: float) -> void:
	pen.stroke(c + Vector2(0, -ry), c + Vector2(3, -ry - 6.0), 3.0, Palette.ROOF_MOSS)
	pen.ellipse(c, rx, ry, Palette.PUMPKIN)
	pen.detail_path(InkPen.arc_pts(c, rx * 0.45, ry * 0.95, -PI * 0.5, PI * 0.5, 8), 1.5, Palette.ROOF_CLAY)
	pen.detail_path(InkPen.arc_pts(c, rx * 0.45, ry * 0.95, PI * 0.5, PI * 1.5, 8), 1.5, Palette.ROOF_CLAY)


static func _lullaby_bell(pen: InkPen, spec: int) -> void:
	pen.box(-26, -32, 26, 0, Palette.PLASTER)
	pen.door(Vector2(0, 0), 7.0, 18.0, Palette.TIMBER)
	pen.window(-20, -26, -11, -17)
	pen.window(11, -26, 20, -17)
	pen.box(-31, -39, 31, -32, Palette.TIMBER)
	var bell_lip: float = 15.0 if spec == 0 else 12.0
	if spec == 0:
		# Hush Bell: a wide onion dome over posts and a bigger bell.
		pen.stroke(Vector2(-24, -39), Vector2(-24, -60), 5.0, Palette.WOOD)
		pen.stroke(Vector2(24, -39), Vector2(24, -60), 5.0, Palette.WOOD)
		_bell(pen, Vector2(0, -62), bell_lip, 22.0)
		var dome: PackedVector2Array = PackedVector2Array([Vector2(-33, -60), Vector2(33, -60)])
		dome.append_array(InkPen.arc_pts(Vector2(0, -60), 33.0, 26.0, 0.0, -PI, 14))
		pen.poly(dome, Palette.ROOF_PLUM)
		pen.poly(PackedVector2Array([Vector2(-6, -84), Vector2(6, -84), Vector2(0, -96)]), Palette.ROOF_PLUM)
	elif spec == 1:
		# Night Bell: a tall pointed spire with a star on the tip.
		pen.stroke(Vector2(-20, -39), Vector2(-20, -60), 5.0, Palette.WOOD)
		pen.stroke(Vector2(20, -39), Vector2(20, -60), 5.0, Palette.WOOD)
		_bell(pen, Vector2(0, -60), bell_lip, 18.0)
		pen.poly(PackedVector2Array([Vector2(-27, -58), Vector2(27, -58), Vector2(0, -86)]), Palette.ROOF_SLATE)
		pen.glow(Vector2(0, -90), 12.0, Palette.MOON)
		pen.star(Vector2(0, -90), 7.0, Palette.MOON)
	else:
		# Tier 1 and 2: an open round arch with the bell inside, a moon on top.
		pen.stroke(Vector2(-22, -39), Vector2(-22, -58), 5.0, Palette.WOOD)
		pen.stroke(Vector2(22, -39), Vector2(22, -58), 5.0, Palette.WOOD)
		pen.path(InkPen.arc_pts(Vector2(0, -58), 22.0, 20.0, 0.0, -PI, 12), 5.0, Palette.WOOD)
		_bell(pen, Vector2(0, -74), bell_lip, 30.0)
		var moon: PackedVector2Array = InkPen.arc_pts(Vector2(0, -86), 7.0, 7.0, 1.016, TAU - 1.016, 12)
		var inner: PackedVector2Array = InkPen.arc_pts(Vector2(3.5, -86), 6.0, 6.0, -1.5384, -4.7448, 10)
		moon.append_array(inner.slice(1, inner.size() - 1))
		pen.poly(moon, Palette.MOON)


## A bell hanging from `top`, its lip `half` units each side, `height` tall.
static func _bell(pen: InkPen, top: Vector2, half: float, height: float) -> void:
	var lip: float = top.y + height
	var pts: PackedVector2Array = InkPen.arc_pts(Vector2(0, top.y + half * 0.55), half * 0.55, half * 0.55, PI, TAU, 8)
	pts.append(Vector2(half * 0.7, lip - height * 0.35))
	pts.append(Vector2(half, lip))
	pts.append(Vector2(-half, lip))
	pts.append(Vector2(-half * 0.7, lip - height * 0.35))
	pen.poly(pts, Palette.HONEY)
	pen.detail(Vector2(-half * 0.8, lip - 3.0), Vector2(half * 0.8, lip - 3.0), 1.6, Palette.GLOW)
	pen.circle(Vector2(0, lip + 2.5), 3.0, Palette.TIMBER)


static func _longbow_loft(pen: InkPen, spec: int) -> void:
	pen.poly(PackedVector2Array([Vector2(-19, 0), Vector2(19, 0), Vector2(15, -58), Vector2(-15, -58)]), Palette.STONE)
	for row: int in 4:
		var y: float = -12.0 - float(row) * 12.0
		var off: float = 6.0 if row % 2 == 0 else -5.0
		pen.detail(Vector2(-10 + off, y), Vector2(2 + off, y), 1.6, Palette.STONE_DARK)
	pen.door(Vector2(0, 0), 6.5, 15.0, Palette.TIMBER)
	pen.glow(Vector2(0, -38), 14.0, Palette.GLOW)
	pen.box(-3, -46, 3, -30, Palette.LANTERN)
	pen.box(-21, -66, 21, -57, Palette.STONE)
	pen.box(-21, -72, -14, -66, Palette.STONE)
	pen.box(-3.5, -72, 3.5, -66, Palette.STONE)
	pen.box(14, -72, 21, -66, Palette.STONE)
	if spec == 0:
		# Giant Bow: one huge bow, wider than the tower.
		_bow(pen, Vector2(0, -76), 46.0, 10.0, 6.5)
	elif spec == 1:
		# Triple Bow: three small bows side by side, the middle one higher.
		_bow(pen, Vector2(-30, -74), 16.0, 6.0, 4.0)
		_bow(pen, Vector2(30, -74), 16.0, 6.0, 4.0)
		_bow(pen, Vector2(0, -80), 16.0, 6.0, 4.0)
	else:
		_bow(pen, Vector2(0, -76), 42.0, 10.0, 5.5)


## A bow lying across at `mid`, `half` units each side, bending `bend` up,
## with an arrow standing up from its middle.
static func _bow(pen: InkPen, mid: Vector2, half: float, bend: float, width: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		mid + Vector2(-half, 0), mid + Vector2(-half * 0.6, -bend * 0.8), mid + Vector2(0, -bend),
		mid + Vector2(half * 0.6, -bend * 0.8), mid + Vector2(half, 0)])
	pen.detail(mid + Vector2(-half, 0), mid + Vector2(0, -bend * 0.3), 1.2, Palette.PLASTER)
	pen.detail(mid + Vector2(half, 0), mid + Vector2(0, -bend * 0.3), 1.2, Palette.PLASTER)
	pen.path(pts, width, Palette.WOOD)
	var tip: float = mid.y - bend - 2.0
	pen.stroke(mid + Vector2(0, 2), Vector2(mid.x, tip), width * 0.45, Palette.TIMBER)
	pen.poly(PackedVector2Array([Vector2(mid.x - width * 0.8, tip), Vector2(mid.x + width * 0.8, tip), Vector2(mid.x, tip - width * 1.4)]), Palette.LANTERN_CORE)


static func _firework_tower(pen: InkPen, spec: int) -> void:
	var colors: Array[Color] = [Palette.ROOF_CLAY, Palette.HONEY, Palette.ROOF_SLATE, Palette.HONEY, Palette.ROOF_CLAY]
	if spec == 0:
		# Star Bloom: five small rockets in a wide fan.
		for i: int in 5:
			pen.rotate_about(Vector2(0, -44), (float(i) - 2.0) * 0.36)
			_rocket(pen, Vector2(0, -64), 0.8, colors[i])
			pen.unrotate()
	elif spec == 1:
		# Skyrocket: one big rocket upright in a launch frame.
		pen.stroke(Vector2(-20, -44), Vector2(-9, -74), 4.0, Palette.TIMBER)
		pen.stroke(Vector2(20, -44), Vector2(9, -74), 4.0, Palette.TIMBER)
		_rocket(pen, Vector2(0, -66), 1.2, Palette.ROOF_CLAY)
	else:
		for i: int in 3:
			pen.rotate_about(Vector2(0, -44), (float(i) - 1.0) * 0.5)
			_rocket(pen, Vector2(0, -66), 1.0, colors[i + 1])
			pen.unrotate()
	pen.box(-36, -38, 36, 0, Palette.PLASTER)
	pen.detail(Vector2(-36, -19), Vector2(36, -19), 2.0, Palette.TIMBER)
	pen.box(-7, -18, 7, 0, Palette.TIMBER)
	pen.window(-29, -32, -18, -22)
	pen.window(18, -32, 29, -22)
	pen.poly(PackedVector2Array([Vector2(-43, -35), Vector2(43, -35), Vector2(37, -48), Vector2(-37, -48)]), Palette.ROOF_PLUM)


## One rocket centered on `c`, standing up, `k` times the normal size.
static func _rocket(pen: InkPen, c: Vector2, k: float, body: Color) -> void:
	var w: float = 6.0 * k
	var h: float = 15.0 * k
	pen.poly(PackedVector2Array([c + Vector2(-w, h * 0.3), c + Vector2(-w * 2.0, h + 4.0 * k), c + Vector2(-w, h)]), Palette.TIMBER)
	pen.poly(PackedVector2Array([c + Vector2(w, h * 0.3), c + Vector2(w * 2.0, h + 4.0 * k), c + Vector2(w, h)]), Palette.TIMBER)
	pen.box(c.x - w, c.y - h, c.x + w, c.y + h, body)
	pen.poly(PackedVector2Array([c + Vector2(-w, -h), c + Vector2(w, -h), c + Vector2(0, -h - w * 1.9)]), Palette.ROOF_PLUM)
	pen.star(c + Vector2(0, -h * 0.2), w * 0.7, Palette.PLASTER)


static func _bakery(pen: InkPen, spec: int) -> void:
	if spec == 0:
		# Grand Oven: two tall chimneys.
		_chimney(pen, 4.0, 16.0, -80.0)
		_chimney(pen, 22.0, 33.0, -66.0)
	elif spec == 1:
		# Spice Kitchen: a pepper mill turret with a round knob.
		pen.box(10, -64, 32, -24, Palette.ROOF_CLAY)
		pen.detail(Vector2(10, -44), Vector2(32, -44), 2.0, Palette.TIMBER)
		pen.ellipse(Vector2(21, -66), 15.0, 8.0, Palette.TIMBER)
		pen.circle(Vector2(21, -79), 5.5, Palette.TIMBER)
	else:
		_chimney(pen, 16.0, 29.0, -76.0)
	var dome: PackedVector2Array = InkPen.arc_pts(Vector2(-4, 0), 42.0, 54.0, PI, TAU, 22)
	pen.poly(dome, Palette.PLASTER_SHADE)
	for row: int in 3:
		var y: float = -14.0 - float(row) * 13.0
		var half: float = 42.0 * sqrt(maxf(0.0, 1.0 - pow(y / 54.0, 2.0)))
		pen.detail(Vector2(-4.0 - half + 4.0, y), Vector2(-4.0 + half - 4.0, y), 1.4, Palette.STONE_DARK)
	var mouth: PackedVector2Array = InkPen.arc_pts(Vector2(-4, -12), 14.0, 14.0, PI, TAU, 10)
	mouth.append(Vector2(10, 0))
	mouth.append(Vector2(-18, 0))
	pen.poly(mouth, Palette.INK_LINE)
	pen.glow(Vector2(-4, -7), 24.0, Palette.GLOW, 1.4)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(-4, -5), 9.0, 5.0, 12), Palette.GLOW)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(-4, -4), 5.0, 3.0, 10), Palette.LANTERN_CORE)
	pen.window(-34, -30, -23, -20)


static func _chimney(pen: InkPen, x0: float, x1: float, top: float) -> void:
	pen.box(x0, top + 6.0, x1, -24, Palette.ROOF_CLAY)
	pen.box(x0 - 3.0, top, x1 + 3.0, top + 6.0, Palette.STONE_DARK)
	if not pen.is_flat():
		for i: int in 2:
			var k: float = float(i) * 0.5 + 0.25
			pen.detail_circle(Vector2((x0 + x1) * 0.5 + 4.0 * float(i), top - 7.0 - 9.0 * float(i)), 4.0 + 3.0 * k, Color(Palette.SMOKE, 0.45 - 0.15 * float(i)))


# Creatures. Local units: the box is 100 across, centered on the position,
# feet at y 36, facing right.

static func _bob(frame: int, amount: float) -> float:
	return -amount if frame % 2 == 1 else 0.0


static func _feet(pen: InkPen, xs: Array[float], col: Color, frame: int, rx: float) -> void:
	for i: int in xs.size():
		var lift: float = -4.0 if (i + frame) % 2 == 0 and frame % 2 == 1 else 0.0
		pen.ellipse(Vector2(xs[i], 33.0 + lift), rx, rx * 0.55, col)


static func _scamp(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 28.0)
	var b: float = _bob(frame, 4.0)
	_feet(pen, [-12.0, 12.0], Palette.CREATURE_BASIC.darkened(0.2), frame, 10.0)
	pen.poly(PackedVector2Array([Vector2(-24, -14 + b), Vector2(-14, -46 + b), Vector2(-3, -20 + b)]), Palette.CREATURE_BASIC)
	pen.poly(PackedVector2Array([Vector2(5, -21 + b), Vector2(19, -47 + b), Vector2(25, -12 + b)]), Palette.CREATURE_BASIC)
	pen.poly(_fuzzy(Vector2(0, 6 + b), 30.0, 28.0, 24, 3.5), Palette.CREATURE_BASIC)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(3, 18 + b), 16.0, 9.0, 14), Palette.CREATURE_BASIC.lightened(0.25))
	pen.eye(Vector2(7, 0 + b), 6.5)
	pen.eye(Vector2(21, 0 + b), 5.8)
	pen.detail_path(InkPen.arc_pts(Vector2(15, 11 + b), 5.0, 4.0, 0.3, PI - 0.3, 6), 2.0, Palette.INK_LINE)


static func _pip(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 20.0)
	var b: float = _bob(frame, 8.0)
	pen.stroke(Vector2(-8, 26 + b), Vector2(-12, 36), 3.0, Palette.CREATURE_SWARM.darkened(0.3), false)
	pen.stroke(Vector2(8, 26 + b), Vector2(12, 36), 3.0, Palette.CREATURE_SWARM.darkened(0.3), false)
	pen.stroke(Vector2(-6, -6 + b), Vector2(-16, -36 + b), 3.5, Palette.INK_LINE, false)
	pen.stroke(Vector2(6, -6 + b), Vector2(16, -38 + b), 3.5, Palette.INK_LINE, false)
	pen.glow(Vector2(0, -38 + b), 18.0, Palette.SPARKLE_LILAC, 0.8)
	pen.circle(Vector2(-16, -38 + b), 6.5, Palette.SPARKLE_LILAC)
	pen.circle(Vector2(16, -40 + b), 6.5, Palette.SPARKLE_LILAC)
	pen.circle(Vector2(0, 12 + b), 21.0, Palette.CREATURE_SWARM)
	pen.eye(Vector2(8, 8 + b), 7.0)


static func _skitter(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 34.0)
	var reach: float = 1.0 if frame % 2 == 0 else 0.0
	var leg: Color = Palette.CREATURE_FAST.darkened(0.25)
	pen.stroke(Vector2(-22, 12), Vector2(-40 - 8.0 * reach, 33), 6.0, leg)
	pen.stroke(Vector2(-10, 14), Vector2(-22 + 8.0 * reach, 35), 6.0, leg)
	pen.stroke(Vector2(14, 12), Vector2(30 + 9.0 * reach, 30), 6.0, leg)
	pen.stroke(Vector2(22, 10), Vector2(42 + 5.0 * reach, 24), 6.0, leg)
	pen.circle(Vector2(-38, -2), 10.0, Palette.CREATURE_FAST.lightened(0.3))
	pen.ellipse(Vector2(-4, 4), 34.0, 18.0, Palette.CREATURE_FAST)
	pen.poly(PackedVector2Array([Vector2(16, -14), Vector2(-16, -48), Vector2(-7, -48), Vector2(26, -16)]), Palette.CREATURE_FAST)
	pen.poly(PackedVector2Array([Vector2(24, -16), Vector2(4, -52), Vector2(13, -52), Vector2(33, -16)]), Palette.CREATURE_FAST)
	pen.poly(PackedVector2Array([Vector2(12, -14), Vector2(36, -18), Vector2(49, -2), Vector2(36, 8), Vector2(14, 6)]), Palette.CREATURE_FAST)
	pen.detail_circle(Vector2(48, -2), 3.0, Palette.INK_LINE)
	pen.eye(Vector2(30, -6), 6.0)


static func _flitter(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 40), 20.0)
	var up: bool = frame % 2 == 0
	var tip_y: float = -38.0 if up else -10.0
	var b: float = -6.0 if up else 0.0
	for side: float in [-1.0, 1.0]:
		# The lower edge runs from the tip back to the body, with two finger
		# tips pushed out, so the edge between them reads as scallops.
		var shoulder: Vector2 = Vector2(10 * side, -14 + b)
		var tip: Vector2 = Vector2(48 * side, tip_y + b)
		var root: Vector2 = Vector2(12 * side, 2 + b)
		var out: Vector2 = Vector2(0, 1).rotated(-0.5 * side) * 7.0
		var w: PackedVector2Array = PackedVector2Array([shoulder, tip])
		for k: int in 5:
			var p: Vector2 = tip.lerp(root, float(k + 1) / 6.0)
			w.append(p + out if k % 2 == 1 else p)
		w.append(root)
		pen.poly(w, Palette.CREATURE_FLY.darkened(0.2))
	pen.poly(PackedVector2Array([Vector2(-14, -18 + b), Vector2(-12, -36 + b), Vector2(-3, -24 + b)]), Palette.CREATURE_FLY)
	pen.poly(PackedVector2Array([Vector2(3, -24 + b), Vector2(12, -36 + b), Vector2(14, -18 + b)]), Palette.CREATURE_FLY)
	pen.poly(_fuzzy(Vector2(0, -6 + b), 19.0, 19.0, 16, 2.0), Palette.CREATURE_FLY)
	pen.eye(Vector2(-6, -8 + b), 5.0)
	pen.eye(Vector2(7, -8 + b), 5.0)


static func _shellback(pen: InkPen, frame: int, boss: bool) -> void:
	var shell_col: Color = Palette.BOSS_SHELL if boss else Palette.CREATURE_ARMOR_SHELL
	var skin: Color = Palette.CREATURE_ARMOR
	pen.shadow(Vector2(0, 37), 46.0)
	for i: int in 4:
		var x: float = -30.0 + float(i) * 19.0
		var lift: float = -4.0 if (i + frame) % 2 == 0 and frame % 2 == 1 else 0.0
		pen.ellipse(Vector2(x, 31 + lift), 8.0, 6.0, skin.darkened(0.25))
	pen.poly(PackedVector2Array([Vector2(44, 6), Vector2(50, -2), Vector2(48, 10)]), skin)
	pen.circle(Vector2(38, 14), 13.0, skin)
	pen.eye(Vector2(42, 11), 4.5)
	if boss:
		# Ironshell: three tall plates along its back.
		for k: int in 3:
			var x: float = -24.0 + float(k) * 22.0
			var h: float = 34.0 if k == 1 else 26.0
			pen.poly(PackedVector2Array([Vector2(x - 11, -2), Vector2(x + 11, -2), Vector2(x + 2, -2 - h - 8.0)]), Palette.IRON)
	var shell: PackedVector2Array = InkPen.arc_pts(Vector2(-4, 22), 44.0, 40.0, PI, TAU, 22)
	pen.poly(shell, shell_col)
	pen.detail_path(InkPen.arc_pts(Vector2(-40, 22), 34.0, 34.0, -0.95, -0.05, 8), 2.4, Color(Palette.INK_LINE, 0.7))
	pen.detail_path(InkPen.arc_pts(Vector2(32, 22), 34.0, 34.0, PI + 0.05, PI + 0.95, 8), 2.4, Color(Palette.INK_LINE, 0.7))
	pen.detail(Vector2(-4, -16), Vector2(-4, 20), 2.4, Color(Palette.INK_LINE, 0.7))
	pen.box(-48, 18, 40, 26, skin)
	if not boss:
		pen.circle(Vector2(-10, -16), 6.0, Palette.MEADOW_LIGHT)
		pen.circle(Vector2(0, -18), 5.0, Palette.MEADOW_LIGHT)


static func _bubbler(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 28.0)
	var b: float = _bob(frame, 3.0)
	_feet(pen, [-12.0, 12.0], Palette.CREATURE_BUBBLE.darkened(0.25), frame, 9.0)
	# A bubble wand held up: the ring is open, so it reads as a ring.
	pen.stroke(Vector2(18, 4 + b), Vector2(26, -26 + b), 4.0, Palette.TIMBER)
	pen.path(_closed(InkPen.ellipse_pts(Vector2(28, -38 + b), 11.0, 11.0, 18)), 4.5, Palette.WOOD)
	pen.ellipse(Vector2(-2, 12 + b), 28.0, 23.0, Palette.CREATURE_BUBBLE)
	pen.ellipse(Vector2(20, 6 + b), 7.0, 6.0, Palette.CREATURE_BUBBLE)
	pen.eye(Vector2(-6, 2 + b), 6.0)
	pen.eye(Vector2(8, 2 + b), 5.5)
	pen.detail_path(_closed(InkPen.ellipse_pts(Vector2(2, 16 + b), 4.0, 3.5, 10)), 2.0, Palette.INK_LINE)
	pen.detail_path(_closed(InkPen.ellipse_pts(Vector2(16, -48 + b), 4.0, 4.0, 10)), 1.6, Palette.BUBBLE)
	pen.detail_path(_closed(InkPen.ellipse_pts(Vector2(8, -40 + b), 2.6, 2.6, 8)), 1.4, Palette.BUBBLE)


static func _puffball(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 32.0)
	var b: float = _bob(frame, 3.0)
	_feet(pen, [-14.0, 14.0], Palette.CREATURE_PUFF.darkened(0.25), frame, 8.0)
	pen.stroke(Vector2(0, -26 + b), Vector2(4, -42 + b), 3.0, Palette.ROOF_MOSS)
	pen.ellipse(Vector2(12, -44 + b), 9.0, 5.0, Palette.ROOF_MOSS)
	pen.poly(_scalloped(Vector2(0, 4 + b), 36.0, 32.0, 11, 0.12), Palette.CREATURE_PUFF)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(-4, 14 + b), 20.0, 10.0, 14), Palette.CREATURE_PUFF.lightened(0.3))
	pen.detail_path(InkPen.arc_pts(Vector2(4, 0 + b), 5.0, 3.0, 0.2, PI - 0.2, 6), 2.4, Palette.INK_LINE)
	pen.detail_path(InkPen.arc_pts(Vector2(18, 0 + b), 5.0, 3.0, 0.2, PI - 0.2, 6), 2.4, Palette.INK_LINE)


static func _puff(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 20.0)
	var b: float = _bob(frame, 7.0)
	# A small round fluff with seven soft bumps and tiny feet: a Puffball's
	# child, without its sprout.
	_feet(pen, [-9.0, 9.0], Palette.CREATURE_PUFF.darkened(0.25), frame, 6.0)
	pen.poly(_scalloped(Vector2(0, 10 + b), 25.0, 23.0, 7, 0.16), Palette.CREATURE_PUFF)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(-3, 18 + b), 12.0, 6.0, 12), Palette.CREATURE_PUFF.lightened(0.3))
	pen.eye(Vector2(-3, 6 + b), 5.0)
	pen.eye(Vector2(10, 6 + b), 4.6)


static func _mender(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 30.0)
	var b: float = _bob(frame, 3.0)
	_feet(pen, [-10.0, 10.0], Palette.CREATURE_MEND.darkened(0.25), frame, 8.0)
	# A leafy staff in front.
	pen.stroke(Vector2(38, 34), Vector2(40, -24 + b), 3.5, Palette.TIMBER)
	pen.ellipse(Vector2(34, -30 + b), 7.0, 4.0, Palette.ROOF_MOSS)
	pen.ellipse(Vector2(46, -32 + b), 7.0, 4.0, Palette.ROOF_MOSS)
	pen.poly(PackedVector2Array([Vector2(-16, -4 + b), Vector2(16, -4 + b), Vector2(18, 30), Vector2(-18, 30)]), Palette.CREATURE_MEND)
	pen.stroke(Vector2(14, 10 + b), Vector2(36, 6 + b), 4.0, Palette.CREATURE_MEND)
	pen.eye(Vector2(-3, 4 + b), 5.0)
	pen.eye(Vector2(9, 4 + b), 4.6)
	# The wide mushroom cap.
	var cap: PackedVector2Array = InkPen.arc_pts(Vector2(0, -6 + b), 38.0, 34.0, PI, TAU, 18)
	cap.append(Vector2(30, -2 + b))
	cap.append(Vector2(-30, -2 + b))
	pen.poly(cap, Palette.CREATURE_MEND_CAP)
	for spot: Vector2 in [Vector2(-16, -22), Vector2(4, -30), Vector2(20, -16)]:
		pen.detail_circle(spot + Vector2(0, b), 4.5, Palette.FLOUR)


static func _gatecrasher(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 42.0)
	var dark: Color = Palette.CREATURE_BRUTE.darkened(0.25)
	for i: int in 4:
		var x: float = -30.0 + float(i) * 17.0
		var lift: float = -4.0 if (i + frame) % 2 == 0 and frame % 2 == 1 else 0.0
		pen.box(x - 6.0, 18 + lift, x + 6.0, 34 + lift, dark)
	pen.poly(_fuzzy(Vector2(-8, 4), 36.0, 26.0, 22, 3.0), Palette.CREATURE_BRUTE)
	pen.circle(Vector2(28, 12), 16.0, Palette.CREATURE_BRUTE)
	pen.ellipse(Vector2(40, 18), 8.0, 6.0, Palette.CREATURE_BRUTE.lightened(0.2))
	pen.eye(Vector2(32, 6), 4.6)
	# Two big horns curving up from the head: a "U" above it.
	pen.path(PackedVector2Array([Vector2(32, -2), Vector2(42, -10), Vector2(46, -24), Vector2(42, -36)]), 7.0, Palette.BONE)
	pen.path(PackedVector2Array([Vector2(20, -2), Vector2(12, -14), Vector2(12, -28), Vector2(18, -38)]), 7.0, Palette.BONE)
	pen.detail(Vector2(-28, -14), Vector2(-14, -18), 2.0, dark)
	pen.detail(Vector2(-22, -6), Vector2(-6, -10), 2.0, dark)


static func _moth(pen: InkPen, frame: int, boss: bool) -> void:
	var col: Color = Palette.BOSS_MOON if boss else Palette.CREATURE_MOTH
	pen.shadow(Vector2(0, 42), 26.0)
	var spread: float = 1.0 if frame % 2 == 0 else 0.82
	for side: float in [-1.0, 1.0]:
		if boss:
			# Long tail streamers from the hind wings.
			pen.path(PackedVector2Array([Vector2(16 * side, 12), Vector2(26 * side, 26), Vector2(22 * side, 40), Vector2(30 * side, 48)]), 6.0, col.darkened(0.15))
		var fore: PackedVector2Array = PackedVector2Array([Vector2(5 * side, -20), Vector2(30 * side * spread, -40), Vector2(48 * side * spread, -32), Vector2(42 * side * spread, -6), Vector2(6 * side, -4)])
		var hind: PackedVector2Array = PackedVector2Array([Vector2(5 * side, -4), Vector2(36 * side * spread, 4), Vector2(30 * side * spread, 22), Vector2(10 * side, 16)])
		if side < 0.0:
			fore.reverse()
			hind.reverse()
		pen.poly(hind, col.darkened(0.12))
		pen.poly(fore, col)
		if boss:
			var c: Vector2 = Vector2(28 * side * spread, -22)
			pen.detail_poly(InkPen.arc_pts(c, 7.0, 7.0, PI * 0.3, PI * 1.7, 8), Palette.MOON)
		else:
			# Plated wings: the armor shows as ridge lines.
			pen.detail(Vector2(10 * side, -14), Vector2(40 * side * spread, -30), 2.0, Color(Palette.INK_LINE, 0.6))
			pen.detail(Vector2(10 * side, -9), Vector2(40 * side * spread, -12), 2.0, Color(Palette.INK_LINE, 0.6))
	pen.ellipse(Vector2(0, -2), 8.0, 20.0, col.darkened(0.3))
	pen.circle(Vector2(0, -24), 8.0, col.darkened(0.3))
	for side: float in [-1.0, 1.0]:
		pen.path(PackedVector2Array([Vector2(3 * side, -30), Vector2(10 * side, -42), Vector2(20 * side, -48)]), 3.0, col.darkened(0.3))
		for k: int in 3:
			var p: Vector2 = Vector2(3 * side, -30).lerp(Vector2(20 * side, -48), float(k + 1) / 4.0)
			pen.detail(p, p + Vector2(4 * side, 4), 1.6, col.darkened(0.3))
	pen.eye(Vector2(-4, -25), 3.2)
	pen.eye(Vector2(4, -25), 3.2)


static func _grumblesack(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 42.0)
	var b: float = _bob(frame, 3.0)
	_feet(pen, [-18.0, 18.0], Palette.BOSS_SACK.darkened(0.3), frame, 11.0)
	# A lumpy sack, wide below and tied at the neck.
	var body: PackedVector2Array = PackedVector2Array()
	for i: int in 28:
		var a: float = TAU * float(i) / 28.0
		var r: float = 1.0 + 0.05 * sin(a * 5.0)
		var p: Vector2 = Vector2(cos(a) * 42.0 * r, sin(a) * 32.0 * r)
		if p.y < 0.0:
			p.x *= 1.0 + p.y / 50.0
			p.y *= 1.35
		body.append(p + Vector2(0, 6 + b))
	pen.poly(body, Palette.BOSS_SACK)
	pen.poly(PackedVector2Array([Vector2(-8, -34 + b), Vector2(8, -34 + b), Vector2(18, -50 + b), Vector2(6, -44 + b), Vector2(0, -52 + b), Vector2(-6, -44 + b), Vector2(-18, -50 + b)]), Palette.BOSS_SACK.darkened(0.15))
	pen.box(-10, -38 + b, 10, -31 + b, Palette.TIMBER)
	pen.detail_poly(PackedVector2Array([Vector2(-30, 14 + b), Vector2(-16, 12 + b), Vector2(-17, 26 + b), Vector2(-31, 26 + b)]), Palette.BOSS_SACK.darkened(0.2))
	pen.eye(Vector2(2, -4 + b), 6.5)
	pen.eye(Vector2(20, -4 + b), 6.0)
	pen.detail(Vector2(-6, -16 + b), Vector2(8, -11 + b), 3.0, Palette.INK_LINE)
	pen.detail(Vector2(28, -16 + b), Vector2(15, -11 + b), 3.0, Palette.INK_LINE)
	pen.detail_path(InkPen.arc_pts(Vector2(12, 14 + b), 7.0, 4.0, PI + 0.4, TAU - 0.4, 6), 2.4, Palette.INK_LINE)


static func _old_tusk(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(-4, 37), 46.0)
	var dark: Color = Palette.BOSS_TUSK.darkened(0.3)
	for i: int in 4:
		var x: float = -36.0 + float(i) * 18.0
		var lift: float = -4.0 if (i + frame) % 2 == 0 and frame % 2 == 1 else 0.0
		pen.box(x - 7.0, 16 + lift, x + 7.0, 34 + lift, dark)
	pen.poly(_fuzzy(Vector2(-12, 0), 38.0, 30.0, 26, 4.5), Palette.BOSS_TUSK)
	pen.poly(PackedVector2Array([Vector2(14, -12), Vector2(34, -6), Vector2(42, 12), Vector2(30, 20), Vector2(16, 16)]), Palette.BOSS_TUSK)
	pen.eye(Vector2(26, -2), 4.0)
	# Two long tusks curving up from the snout, clear of the head.
	for k: int in 2:
		var o: Vector2 = Vector2(-8.0 * float(k), 3.0 * float(k))
		var pts: PackedVector2Array = PackedVector2Array([Vector2(34, 16) + o, Vector2(44, 12) + o, Vector2(50, -2) + o, Vector2(47, -22) + o])
		pen.path(pts, 7.0 - float(k), Palette.BONE)
	pen.detail(Vector2(-38, -18), Vector2(-24, -26), 2.4, dark)
	pen.detail(Vector2(-22, -22), Vector2(-8, -28), 2.4, dark)


# Expansion towers (docs/art/EXPANSION_LOOK.md 2). Local units as above.

## A cottage whose whole roof is a great tangle of thorny bramble, with canes
## drooping to the ground on both sides: a wide, bristly crown over a small
## house. Tier 3 replaces the tangle: wilder and wider (Wild Bramble), or a
## holly bush crowned with holly leaves and berries (Holly Crown).
static func _bramble_cottage(pen: InkPen, spec: int) -> void:
	var cane: Color = Palette.ROOF_MOSS.darkened(0.3)
	var reach: float = 48.0 if spec == 0 else 46.0
	if spec != 1:
		for side: float in [-1.0, 1.0]:
			var pts: PackedVector2Array = PackedVector2Array([Vector2(26 * side, -42), Vector2(reach * side, -28), Vector2((reach - 1.0) * side, -12), Vector2((reach - 7.0) * side, 0)])
			pen.path(pts, 4.0, cane)
			for k: int in 3:
				var p: Vector2 = pts[k].lerp(pts[k + 1], 0.5)
				pen.detail_poly(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(2, 0), p + Vector2(4 * side, -4)]), Palette.PLASTER_SHADE)
	pen.box(-20, -32, 20, 0, Palette.PLASTER)
	pen.detail(Vector2(-20, -16), Vector2(20, -16), 1.6, Palette.TIMBER)
	pen.door(Vector2(-8, 0), 6.0, 17.0, Palette.TIMBER)
	pen.window(3, -27, 14, -17)
	if spec == 0:
		# Wild Bramble: a wider, spikier tangle with canes looping over the top.
		for side: float in [-1.0, 1.0]:
			pen.path(PackedVector2Array([Vector2(8 * side, -78), Vector2(16 * side, -92), Vector2(32 * side, -93), Vector2(38 * side, -83), Vector2(30 * side, -76)]), 4.0, cane)
		_tangle(pen, Vector2(0, -64), 24.0, 6.5)
		_tangle(pen, Vector2(-27, -46), 21.0, 6.5)
		_tangle(pen, Vector2(27, -46), 21.0, 6.5)
	elif spec == 1:
		# Holly Crown: a rounder holly bush with a crown of spiky leaves.
		for i: int in 5:
			var a: float = deg_to_rad(-150.0 + 30.0 * float(i))
			_holly_leaf(pen, Vector2(0, -62), a, 28.0, 7.0)
		pen.ellipse(Vector2(0, -50), 30.0, 20.0, Palette.HOLLY)
		pen.ellipse(Vector2(-24, -38), 16.0, 12.0, Palette.HOLLY)
		pen.ellipse(Vector2(24, -38), 16.0, 12.0, Palette.HOLLY)
		for p: Vector2 in [Vector2(-5, -66), Vector2(5, -66), Vector2(0, -73)]:
			pen.circle(p, 5.0, Palette.JAM)
		pen.detail_circle(Vector2(-6, -67), 1.6, Palette.LANTERN_CORE)
		for p: Vector2 in [Vector2(-16, -50), Vector2(12, -44), Vector2(26, -40), Vector2(-28, -38)]:
			pen.detail_circle(p, 2.6, Palette.JAM)
	else:
		_tangle(pen, Vector2(0, -60), 22.0, 4.5)
		_tangle(pen, Vector2(-24, -44), 19.0, 4.5)
		_tangle(pen, Vector2(24, -44), 19.0, 4.5)


static func _tangle(pen: InkPen, c: Vector2, r: float, depth: float) -> void:
	pen.poly(_fuzzy(c, r, r * 0.92, 24, depth), Palette.ROOF_MOSS)
	pen.detail_path(InkPen.arc_pts(c + Vector2(-2, 2), r * 0.6, r * 0.5, PI * 0.9, PI * 1.9, 8), 1.6, Palette.ROOF_MOSS.darkened(0.3))
	pen.detail_path(InkPen.arc_pts(c + Vector2(3, -1), r * 0.45, r * 0.4, 0.2, PI * 1.1, 8), 1.6, Palette.ROOF_MOSS.darkened(0.3))
	for k: int in 3:
		var a: float = 1.1 + 1.9 * float(k)
		var p: Vector2 = c + Vector2(cos(a), sin(a)) * r * 0.55
		pen.detail_circle(p, r * 0.13, Palette.JAM if k != 1 else Palette.PLASTER)


static func _holly_leaf(pen: InkPen, base: Vector2, angle: float, length: float, width: float) -> void:
	var l: float = length
	var w: float = width
	var local: Array[Vector2] = [
		Vector2(0, 0), Vector2(l * 0.2, -w * 0.95), Vector2(l * 0.35, -w * 0.55), Vector2(l * 0.5, -w * 1.15),
		Vector2(l * 0.65, -w * 0.55), Vector2(l * 0.8, -w * 0.95), Vector2(l, 0), Vector2(l * 0.8, w * 0.95),
		Vector2(l * 0.65, w * 0.55), Vector2(l * 0.5, w * 1.15), Vector2(l * 0.35, w * 0.55), Vector2(l * 0.2, w * 0.95)]
	var pts: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in local:
		pts.append(base + p.rotated(angle))
	pen.poly(pts, Palette.HOLLY.lightened(0.08))
	pen.detail(base, base + Vector2(l * 0.9, 0).rotated(angle), 1.4, Palette.HOLLY.darkened(0.35))


## A straw scarecrow standing on its post behind a small hut, arms spread in a
## patched coat, a lantern hanging from one hand: a cross over a house. Tier 3
## replaces the figure: taller with a wide hat (Tall Scarecrow), or with a
## crow on each arm, one flapping (Crow Keeper).
static func _scarecrow(pen: InkPen, spec: int) -> void:
	var y: float = -2.0 if spec == 0 else 0.0
	var coat: Color = Palette.ROOF_PLUM
	pen.stroke(Vector2(0, -30), Vector2(0, -60 + y), 5.0, Palette.TIMBER)
	pen.box(-30, -24, 30, 0, Palette.PLASTER)
	pen.detail(Vector2(-30, -12), Vector2(30, -12), 1.6, Palette.TIMBER)
	pen.door(Vector2(-13, 0), 6.0, 16.0, Palette.TIMBER)
	pen.window(6, -20, 17, -11)
	pen.poly(PackedVector2Array([Vector2(-36, -22), Vector2(36, -22), Vector2(0, -42)]), Palette.ROOF_CLAY)
	for side: float in [-1.0, 1.0]:
		var sleeve: PackedVector2Array = PackedVector2Array([Vector2(4 * side, -66 + y), Vector2(38 * side, -62 + y), Vector2(38 * side, -52 + y), Vector2(4 * side, -55 + y)])
		if side < 0.0:
			sleeve.reverse()
		pen.poly(sleeve, coat)
		var cuff: PackedVector2Array = PackedVector2Array([Vector2(37 * side, -63 + y), Vector2(47 * side, -64 + y), Vector2(44 * side, -58 + y), Vector2(48 * side, -53 + y), Vector2(37 * side, -51 + y)])
		if side < 0.0:
			cuff.reverse()
		pen.poly(cuff, Palette.THATCH)
	pen.poly(PackedVector2Array([Vector2(-12, -67 + y), Vector2(12, -67 + y), Vector2(15, -41 + y), Vector2(-15, -41 + y)]), coat)
	pen.detail_poly(PackedVector2Array([Vector2(-8, -56 + y), Vector2(0, -56 + y), Vector2(0, -48 + y), Vector2(-8, -48 + y)]), Palette.HONEY)
	pen.detail(Vector2(-15, -44 + y), Vector2(15, -44 + y), 2.0, Palette.THATCH)
	pen.circle(Vector2(0, -75 + y), 9.0, Palette.PLASTER_SHADE)
	pen.detail_circle(Vector2(-3, -76 + y), 1.6, Palette.INK_LINE)
	pen.detail_circle(Vector2(4, -76 + y), 1.6, Palette.INK_LINE)
	pen.detail_path(InkPen.arc_pts(Vector2(0, -73 + y), 4.0, 2.5, 0.3, PI - 0.3, 6), 1.2, Palette.INK_LINE)
	var brim: float = 30.0 if spec == 0 else 20.0
	var crown: float = 12.0 if spec == 0 else 10.0
	pen.poly(PackedVector2Array([Vector2(-9, -82 + y), Vector2(9, -82 + y), Vector2(7, -82 - crown + y), Vector2(-6, -84 - crown + y)]), Palette.WOOD)
	pen.ellipse(Vector2(0, -82 + y), brim, 4.5, Palette.WOOD)
	pen.detail(Vector2(-8, -86 + y), Vector2(8, -86 + y), 2.4, Palette.HONEY)
	pen.stroke(Vector2(42, -52 + y), Vector2(42, -46 + y), 1.5, Palette.TIMBER, false)
	pen.lantern(Vector2(42, -40 + y), 5.0)
	if spec == 1:
		# Crow Keeper: a crow on each arm; the right one flaps.
		for side: float in [-1.0, 1.0]:
			var c: Vector2 = Vector2(28 * side, -69 + y)
			pen.poly(PackedVector2Array([c + Vector2(-9 * side, 1), c + Vector2(-15 * side, 4), c + Vector2(-8 * side, -2)]), Palette.CROW)
			pen.ellipse(c, 8.0, 5.5, Palette.CROW)
			pen.circle(c + Vector2(6 * side, -5), 4.5, Palette.CROW)
			pen.poly(PackedVector2Array([c + Vector2(9 * side, -6), c + Vector2(15 * side, -4), c + Vector2(9 * side, -3)]), Palette.HONEY)
			pen.detail_circle(c + Vector2(7 * side, -6), 1.2, Palette.LANTERN_CORE)
			if side > 0.0:
				pen.poly(PackedVector2Array([c + Vector2(-4, -3), c + Vector2(-2, -18), c + Vector2(6, -12), c + Vector2(4, -3)]), Palette.CROW)


## A wide wall of snow bricks with round merlons, a glowing door and a flag,
## and a big snowball resting in the gap on top. Tier 3 replaces the snowball:
## one huge snowball (Big Snowball), or a stack of six small ones (Flurry).
static func _snow_fort(pen: InkPen, spec: int) -> void:
	pen.stroke(Vector2(-34, -36), Vector2(-34, -82), 3.0, Palette.TIMBER)
	pen.poly(PackedVector2Array([Vector2(-34, -82), Vector2(-10, -76), Vector2(-34, -68)]), Palette.ROOF_CLAY)
	if spec == 0:
		_snowball(pen, Vector2(0, -50), 22.0)
	elif spec == 1:
		for p: Vector2 in [Vector2(-15, -37), Vector2(0, -37), Vector2(15, -37), Vector2(-7.5, -50), Vector2(7.5, -50), Vector2(0, -63)]:
			_snowball(pen, p, 7.5)
	else:
		_snowball(pen, Vector2(0, -42), 14.0)
	pen.box(-40, -30, 40, 0, Palette.SNOW_WARM)
	for x: float in [-34.0, -18.0, 18.0, 34.0]:
		pen.poly(_round_top(x, -30.0, 7.0, 10.0), Palette.SNOW_WARM)
	for row: int in 2:
		var yy: float = -10.0 - float(row) * 10.0
		pen.detail(Vector2(-38, yy), Vector2(38, yy), 1.4, Palette.SNOW_WARM_SHADE)
		for k: int in 5:
			var xx: float = -32.0 + float(k) * 16.0 + (8.0 if row == 1 else 0.0)
			pen.detail(Vector2(xx, yy), Vector2(xx, yy + 10.0), 1.4, Palette.SNOW_WARM_SHADE)
	pen.glow(Vector2(0, -8), 20.0, Palette.GLOW, 1.2)
	pen.door(Vector2(0, 0), 9.0, 20.0, Palette.LANTERN)
	pen.detail(Vector2(0, -18), Vector2(0, 0), 1.6, Palette.TIMBER)


static func _snowball(pen: InkPen, c: Vector2, r: float) -> void:
	pen.circle(c, r, Palette.SNOW_WARM)
	pen.detail_path(InkPen.arc_pts(c, r * 0.6, r * 0.6, PI * 0.2, PI * 1.1, 8), 1.6, Palette.SNOW_WARM_SHADE)
	pen.detail_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.18, Color.WHITE)


static func _round_top(x: float, base: float, half: float, h: float) -> PackedVector2Array:
	var pts: PackedVector2Array = InkPen.arc_pts(Vector2(x, base - h + half), half, half, PI, TAU, 8)
	pts.append(Vector2(x + half, base))
	pts.append(Vector2(x - half, base))
	return pts


## A lamplighter's booth with a tall post that curls over at the top, a big
## lantern hanging from the curl and two small cream moths in its light: a
## question mark over a hut. Tier 3 replaces the curl and lantern: one big
## lantern standing on a straight post (Beacon Lantern), or a string of three
## small lanterns draped from the curl to a short post (Lantern Garland).
static func _moth_lantern(pen: InkPen, spec: int) -> void:
	if spec == 0:
		pen.stroke(Vector2(8, -32), Vector2(8, -70), 6.0, Palette.TIMBER)
		# Centered a little below the lantern and kept small enough that the
		# whole glow stays under MapAtlas.TOWER_REACH (tests/render/tower_extent.gd).
		pen.glow(Vector2(8, -72), 29.0, Palette.GLOW, 1.6)
		pen.box(-6, -70, 22, -66, Palette.TIMBER)
		pen.box(-3, -88, 19, -70, Palette.LANTERN)
		pen.detail_circle(Vector2(8, -79), 6.0, Palette.LANTERN_CORE)
		pen.detail(Vector2(8, -87), Vector2(8, -71), 1.6, Palette.TIMBER)
		pen.poly(PackedVector2Array([Vector2(-7, -88), Vector2(23, -88), Vector2(8, -97)]), Palette.ROOF_SLATE)
	else:
		pen.stroke(Vector2(8, -32), Vector2(8, -80), 5.0, Palette.TIMBER)
		pen.path(InkPen.arc_pts(Vector2(19, -80), 11.0, 11.0, PI, TAU, 10), 5.0, Palette.TIMBER)
		if spec == 1:
			pen.stroke(Vector2(46, 0), Vector2(46, -40), 4.0, Palette.TIMBER)
			var rope: PackedVector2Array = PackedVector2Array([Vector2(30, -80), Vector2(31, -66), Vector2(36, -54), Vector2(42, -46), Vector2(46, -40)])
			pen.path(rope, 1.6, Palette.TIMBER, false)
			for c: Vector2 in [Vector2(30, -70), Vector2(35, -52), Vector2(44, -34)]:
				pen.lantern(c + Vector2(0, 6), 4.2)
		else:
			pen.stroke(Vector2(30, -80), Vector2(30, -74), 2.0, Palette.TIMBER, false)
			pen.lantern(Vector2(30, -61), 7.0, 1.3)
			for m: Vector2 in [Vector2(18, -64), Vector2(42, -72)]:
				pen.detail_poly(PackedVector2Array([m, m + Vector2(-4, -3), m + Vector2(-4, 2)]), Palette.LANTERN_CORE)
				pen.detail_poly(PackedVector2Array([m, m + Vector2(4, -3), m + Vector2(4, 2)]), Palette.LANTERN_CORE)
	pen.box(-24, -32, 12, 0, Palette.PLASTER)
	pen.detail(Vector2(-24, -16), Vector2(12, -16), 1.6, Palette.TIMBER)
	pen.door(Vector2(2, 0), 5.0, 15.0, Palette.TIMBER)
	pen.window(-18, -26, -8, -17)
	pen.poly(PackedVector2Array([Vector2(-30, -30), Vector2(18, -30), Vector2(-6, -48)]), Palette.ROOF_SLATE)


# Expansion creatures. Local units as for the creatures above.

## A walking flower bud: round below, pointed and curled at the tip, a frill
## of leaves around its middle, moss on its lower half.
static func _mossbud(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 26.0)
	var b: float = _bob(frame, 3.0)
	_feet(pen, [-10.0, 10.0], Palette.CREATURE_MOSS.darkened(0.3), frame, 7.0)
	var body: PackedVector2Array = PackedVector2Array()
	for i: int in 33:
		var a: float = TAU * float(i) / 32.0
		var s: float = sin(a)
		var y: float = s * (20.0 if s > 0.0 else 30.0 + 14.0 * pow(absf(s), 8.0))
		var x: float = cos(a) * 23.0 * (1.0 - (0.25 * pow(absf(s), 2.0) if s < 0.0 else 0.0))
		body.append(Vector2(x, 14.0 + y + b))
	body.remove_at(body.size() - 1)
	for side: float in [-1.0, 1.0]:
		_leaf(pen, Vector2(10 * side, 10 + b), Vector2(36 * side, -2 + b), 9.0, Palette.ROOF_MOSS.darkened(0.05).lerp(Palette.CREATURE_MOSS, 0.6))
	pen.poly(body, Palette.CREATURE_MOSS)
	pen.detail_poly(PackedVector2Array([Vector2(-12, -6 + b), Vector2(0, -26 + b), Vector2(12, -6 + b), Vector2(0, 0 + b)]), Palette.CREATURE_MOSS_BUD)
	pen.path(PackedVector2Array([Vector2(1, -28 + b), Vector2(6, -36 + b), Vector2(12, -34 + b)]), 3.0, Palette.CREATURE_MOSS)
	for p: Vector2 in [Vector2(-14, 22), Vector2(-4, 28), Vector2(10, 26), Vector2(-18, 12)]:
		pen.detail_circle(p + Vector2(0, b), 3.2, Palette.CREATURE_MOSS.darkened(0.2))
	pen.eye(Vector2(4, 10 + b), 5.0)
	pen.eye(Vector2(15, 10 + b), 4.5)


static func _leaf(pen: InkPen, base: Vector2, tip: Vector2, width: float, c: Color) -> void:
	var d: Vector2 = (tip - base)
	var n: Vector2 = Vector2(-d.y, d.x).normalized() * width
	pen.poly(PackedVector2Array([base, base + d * 0.5 + n, tip, base + d * 0.5 - n * 0.6]), c)
	pen.detail(base, tip, 1.2, c.darkened(0.3))


## A small bean of a creature with a tall curl of mist rising from its head.
## The curl is its shape; the same curl, small, marks the creatures it hides.
static func _mistwisp(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 22.0)
	var b: float = _bob(frame, 3.0)
	var sway: float = 2.0 if frame >= 2 else -2.0
	_feet(pen, [-8.0, 8.0], Palette.CREATURE_MIST.darkened(0.25), frame, 6.0)
	pen.ellipse(Vector2(0, 19 + b), 18.0, 15.0, Palette.CREATURE_MIST)
	var curl: PackedVector2Array = PackedVector2Array([Vector2(-1, 6 + b), Vector2(-6, -6 + b)])
	var hub: Vector2 = Vector2(5 + sway, -22 + b)
	for i: int in 15:
		var t: float = float(i) / 14.0
		var a: float = PI * 0.95 + t * PI * 1.75
		curl.append(hub + Vector2(cos(a), sin(a)) * lerpf(13.0, 4.5, t))
	pen.path(curl.slice(0, 9), 10.0, Palette.CREATURE_MIST_CURL)
	pen.path(curl.slice(8), 6.5, Palette.CREATURE_MIST_CURL)
	pen.eye(Vector2(4, 17 + b), 5.0)
	pen.eye(Vector2(14, 17 + b), 4.4)


## A plump creature with a fan of five shimmering feathers raised behind it,
## each tipped with a round gleam.
static func _gleamer(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 30.0)
	var b: float = _bob(frame, 3.0)
	var pivot: Vector2 = Vector2(-8, 6 + b)
	var spread: float = 0.0 if frame % 2 == 0 else 0.05
	for i: int in 5:
		var a: float = deg_to_rad(195.0 + 27.0 * float(i)) + spread * (float(i) - 2.0)
		var tip: Vector2 = pivot + Vector2(cos(a), sin(a)) * 34.0
		pen.stroke(pivot, tip, 4.5, Palette.CREATURE_GLEAM_FAN)
		pen.glow(tip, 12.0, Palette.BUBBLE, 0.7)
		pen.circle(tip, 7.5, Palette.CREATURE_GLEAM_FAN)
		pen.detail_circle(tip, 3.6, Palette.BUBBLE)
	_feet(pen, [-11.0, 11.0], Palette.CREATURE_GLEAM.darkened(0.25), frame, 8.0)
	pen.ellipse(Vector2(2, 15 + b), 26.0, 21.0, Palette.CREATURE_GLEAM)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(4, 22 + b), 15.0, 8.0, 12), Palette.CREATURE_GLEAM.lightened(0.3))
	pen.eye(Vector2(10, 9 + b), 5.5)
	pen.eye(Vector2(22, 9 + b), 5.0)
	pen.star(Vector2(-30, -26 + b), 4.0, Palette.SPARKLE)


## A round creature in a long floppy nightcap that bends back, a pompom on
## its tip. Its eyes are half shut.
static func _sleepyhead(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 28.0)
	var b: float = _bob(frame, 2.0)
	_feet(pen, [-11.0, 11.0], Palette.CREATURE_SLEEPY.darkened(0.25), frame, 8.5)
	pen.ellipse(Vector2(0, 12 + b), 26.0, 23.0, Palette.CREATURE_SLEEPY)
	var cap: PackedVector2Array = PackedVector2Array([Vector2(-22, -2 + b), Vector2(20, -5 + b), Vector2(12, -24 + b), Vector2(0, -36 + b), Vector2(-14, -40 + b), Vector2(-28, -34 + b), Vector2(-36, -22 + b), Vector2(-27, -25 + b), Vector2(-15, -26 + b), Vector2(-12, -14 + b)])
	pen.poly(cap, Palette.CREATURE_SLEEPY_CAP)
	pen.detail(Vector2(4, -26 + b), Vector2(-8, -14 + b), 2.4, Palette.CREATURE_SLEEPY_CAP.darkened(0.15))
	pen.poly(PackedVector2Array([Vector2(-25, -7 + b), Vector2(23, -10 + b), Vector2(23, -1 + b), Vector2(-25, 2 + b)]), Palette.CREATURE_SLEEPY_CAP.lightened(0.2))
	pen.circle(Vector2(-36, -17 + b), 7.0, Palette.FLOUR)
	for e: Vector2 in [Vector2(4, 10), Vector2(16, 10)]:
		pen.ellipse(e + Vector2(0, b), 5.0, 5.5, Palette.EYE)
		pen.detail_circle(e + Vector2(1.5, 2 + b), 2.4, Palette.INK_LINE)
		pen.detail_poly(InkPen.arc_pts(e + Vector2(0, b), 6.0, 6.0, PI, TAU, 8), Palette.CREATURE_SLEEPY.darkened(0.15))
		pen.detail(e + Vector2(-6, b), e + Vector2(6, b), 1.6, Palette.INK_LINE)


## A little creature running on top of a snowball it rolls along. The render
## scales the whole drawing up to 1.5 times as it grows.
static func _snowroller(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 26.0)
	var r: float = 21.0
	var bc: Vector2 = Vector2(0, 36 - r)
	for p: Vector3 in [Vector3(-26, 30, 6.0), Vector3(-36, 32, 4.5), Vector3(-44, 33, 3.0)]:
		pen.circle(Vector2(p.x, p.y), p.z, Palette.CREATURE_SNOWBALL)
	pen.circle(bc, r, Palette.CREATURE_SNOWBALL)
	var turn: float = float(frame) * 0.6
	for k: int in 3:
		var a: float = turn + TAU * float(k) / 3.0
		pen.detail_path(InkPen.arc_pts(bc, r * 0.62, r * 0.62, a, a + 1.2, 6), 1.8, Palette.CREATURE_SNOWBALL.darkened(0.15))
	var top: float = bc.y - r
	var lean: float = 3.0 if frame % 2 == 0 else 1.0
	pen.ellipse(Vector2(-5, top - 1), 4.5, 3.0, Palette.CREATURE_ROLLER.darkened(0.25))
	pen.ellipse(Vector2(6, top), 4.5, 3.0, Palette.CREATURE_ROLLER.darkened(0.25))
	pen.path(PackedVector2Array([Vector2(-8, top - 12), Vector2(-16, top - 10), Vector2(-20, top - 16)]), 3.0, Palette.CREATURE_ROLLER)
	pen.stroke(Vector2(-4 + lean, top - 14), Vector2(-27, top - 18), 3.5, Palette.CREATURE_ROLLER)
	pen.stroke(Vector2(6 + lean, top - 14), Vector2(29, top - 20), 3.5, Palette.CREATURE_ROLLER)
	pen.circle(Vector2(-27, top - 18), 3.8, Palette.CREATURE_ROLLER.lightened(0.25))
	pen.circle(Vector2(29, top - 20), 3.8, Palette.CREATURE_ROLLER.lightened(0.25))
	pen.circle(Vector2(-4 + lean, top - 24), 4.5, Palette.CREATURE_ROLLER)
	pen.circle(Vector2(9 + lean, top - 25), 4.5, Palette.CREATURE_ROLLER)
	pen.ellipse(Vector2(2 + lean, top - 14), 11.0, 10.0, Palette.CREATURE_ROLLER)
	pen.eye(Vector2(7 + lean, top - 16), 3.6)


## A droopy creature with long hanging ears, a thick patched quilt over its
## back trailing to the ground, its mouth open in a big yawn.
static func _yawner(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(-6, 37), 40.0)
	var b: float = _bob(frame, 2.0)
	_feet(pen, [-14.0, 10.0], Palette.CREATURE_YAWN.darkened(0.3), frame, 9.0)
	pen.ellipse(Vector2(-2, 18 + b), 26.0, 15.0, Palette.CREATURE_YAWN)
	var quilt: PackedVector2Array = PackedVector2Array([Vector2(14, -8 + b), Vector2(0, -10 + b), Vector2(-20, -2 + b), Vector2(-36, 12 + b), Vector2(-46, 26), Vector2(-49, 35), Vector2(-26, 35), Vector2(-18, 24 + b), Vector2(-4, 14 + b), Vector2(10, 8 + b)])
	for k: int in 4:
		var tx: float = -47.0 + float(k) * 6.5
		pen.poly(PackedVector2Array([Vector2(tx - 2.5, 34), Vector2(tx + 2.5, 34), Vector2(tx, 39)]), Palette.CREATURE_QUILT.darkened(0.15))
	pen.poly(quilt, Palette.CREATURE_QUILT)
	pen.detail_path(PackedVector2Array([Vector2(-6, -18 + b), Vector2(-16, 14 + b)]), 1.6, Palette.FLOUR)
	pen.detail_path(PackedVector2Array([Vector2(-30, -2 + b), Vector2(-36, 30)]), 1.6, Palette.FLOUR)
	pen.detail_path(PackedVector2Array([Vector2(-14, -16 + b), Vector2(-42, 18)]), 1.6, Palette.FLOUR)
	pen.circle(Vector2(24, -10 + b), 14.0, Palette.CREATURE_YAWN)
	for side: float in [-1.0, 1.0]:
		var x: float = 24.0 + 12.0 * side
		var ear: PackedVector2Array = PackedVector2Array([Vector2(x - 4.0 * side, -20 + b), Vector2(x + 4.0 * side, -16 + b), Vector2(x + 5.0 * side, 10 + b), Vector2(x + 0.0 * side, 14 + b), Vector2(x - 3.0 * side, 0 + b)])
		if side < 0.0:
			ear.reverse()
		pen.poly(ear, Palette.CREATURE_YAWN.darkened(0.12))
	pen.detail_poly(InkPen.ellipse_pts(Vector2(27, -3 + b), 5.0, 6.5, 12), Palette.INK_LINE)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(27, 1 + b), 3.0, 2.0, 8), Palette.HEART.darkened(0.2))
	pen.detail_path(InkPen.arc_pts(Vector2(19, -14 + b), 3.5, 2.5, 0.2, PI - 0.2, 5), 1.6, Palette.INK_LINE)
	pen.detail_path(InkPen.arc_pts(Vector2(30, -14 + b), 3.5, 2.5, 0.2, PI - 0.2, 5), 1.6, Palette.INK_LINE)


## A small upright hopper with a big round head, two huge eyes bulging from
## its brow, long feet and a thin tail ending in a sparkle.
static func _blinker(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 22.0)
	var b: float = -6.0 if frame % 2 == 1 else 0.0
	pen.path(PackedVector2Array([Vector2(-8, 24 + b), Vector2(-24, 22 + b), Vector2(-34, 10 + b), Vector2(-32, -6 + b), Vector2(-26, -12 + b)]), 3.5, Palette.CREATURE_BLINK.darkened(0.15))
	pen.poly(_four_star(Vector2(-24, -20 + b), 10.0), Palette.SPARKLE)
	pen.ellipse(Vector2(-6, 34), 9.0, 3.5, Palette.CREATURE_BLINK.darkened(0.3))
	pen.ellipse(Vector2(10, 34), 9.0, 3.5, Palette.CREATURE_BLINK.darkened(0.3))
	pen.stroke(Vector2(-4, 24 + b), Vector2(-4, 32), 4.0, Palette.CREATURE_BLINK.darkened(0.3))
	pen.stroke(Vector2(10, 24 + b), Vector2(10, 32), 4.0, Palette.CREATURE_BLINK.darkened(0.3))
	pen.ellipse(Vector2(2, 18 + b), 14.0, 13.0, Palette.CREATURE_BLINK)
	pen.circle(Vector2(6, -3 + b), 17.0, Palette.CREATURE_BLINK)
	for e: Vector2 in [Vector2(-1, -15), Vector2(16, -13)]:
		pen.glow(e + Vector2(0, b), 14.0, Palette.EYE, 0.6)
		pen.ellipse(e + Vector2(0, b), 8.5, 9.5, Palette.EYE)
		pen.detail_circle(e + Vector2(2.5, 1 + b), 4.2, Palette.INK_LINE)
		pen.detail_circle(e + Vector2(0.5, -2 + b), 1.4, Palette.EYE)
	pen.detail_path(InkPen.arc_pts(Vector2(10, 4 + b), 4.0, 3.0, 0.3, PI - 0.3, 5), 1.6, Palette.INK_LINE)


## A small owlish creature standing upright: a tall egg of a body, wings
## folded at its sides, a heart-shaped top and a pale round face.
static func _hootling(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 22.0)
	var b: float = _bob(frame, 2.0)
	for x: float in [-7.0, 7.0]:
		pen.poly(PackedVector2Array([Vector2(x - 6, 36), Vector2(x + 6, 36), Vector2(x, 28)]), Palette.BONE.darkened(0.25))
	pen.poly(PackedVector2Array([Vector2(-6, 26 + b), Vector2(6, 26 + b), Vector2(0, 36 + b)]), Palette.CREATURE_HOOT.darkened(0.2))
	pen.circle(Vector2(-8, -21 + b), 7.5, Palette.CREATURE_HOOT)
	pen.circle(Vector2(8, -21 + b), 7.5, Palette.CREATURE_HOOT)
	pen.ellipse(Vector2(0, 4 + b), 17.0, 29.0, Palette.CREATURE_HOOT)
	for side: float in [-1.0, 1.0]:
		pen.ellipse(Vector2(14 * side, 9 + b), 6.5, 18.0, Palette.CREATURE_HOOT.darkened(0.15))
	var face: PackedVector2Array = PackedVector2Array()
	for i: int in 24:
		var t: float = TAU * float(i) / 24.0
		face.append(Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * 0.9 + Vector2(0, -8 + b))
	pen.detail_poly(face, Palette.CREATURE_HOOT_FACE)
	pen.eye(Vector2(-5, -10 + b), 5.0)
	pen.eye(Vector2(6, -10 + b), 5.0)
	pen.poly(PackedVector2Array([Vector2(-2, -4 + b), Vector2(3, -4 + b), Vector2(0.5, 2 + b)]), Palette.BONE.darkened(0.15))
	for k: int in 3:
		pen.detail_path(PackedVector2Array([Vector2(-6 + 6 * k, 18 + b), Vector2(-3 + 6 * k, 21 + b), Vector2(0 + 6 * k, 18 + b)]), 1.4, Palette.CREATURE_HOOT.darkened(0.25))


static func _four_star(c: Vector2, r: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0 - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.4))
	return pts



# Expansion bosses.

## A big round digger with a pot belly, a pointed snout and two huge spade
## paws held out wide, claws first.
static func _burrowbelly(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 44.0)
	var b: float = _bob(frame, 2.0)
	var dark: Color = Palette.BOSS_BURROW.darkened(0.3)
	_feet(pen, [-16.0, 14.0], dark, frame, 10.0)
	_paw(pen, Vector2(-36, 2 + b), -1.0)
	pen.circle(Vector2(-14, -22 + b), 6.0, Palette.BOSS_BURROW)
	pen.circle(Vector2(8, -24 + b), 6.0, Palette.BOSS_BURROW)
	pen.ellipse(Vector2(-2, 6 + b), 32.0, 29.0, Palette.BOSS_BURROW)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(2, 15 + b), 19.0, 15.0, 16), Palette.BOSS_BURROW.lightened(0.25))
	pen.poly(PackedVector2Array([Vector2(20, -12 + b), Vector2(44, -2 + b), Vector2(42, 5 + b), Vector2(22, 8 + b)]), Palette.BOSS_BURROW.lightened(0.1))
	pen.circle(Vector2(44, 1 + b), 5.0, Palette.BOSS_BURROW_NOSE)
	pen.eye(Vector2(20, -9 + b), 3.6)
	_paw(pen, Vector2(30, 20 + b), 1.0)


static func _paw(pen: InkPen, c: Vector2, side: float) -> void:
	for k: int in 3:
		var a: float = deg_to_rad(-35.0 + 35.0 * float(k))
		var d: Vector2 = Vector2(cos(a) * side, sin(a))
		var base: Vector2 = c + d * 9.0
		pen.poly(PackedVector2Array([base + Vector2(-d.y, d.x) * 3.5, base + d * 11.0, base - Vector2(-d.y, d.x) * 3.5]), Palette.BONE)
	pen.ellipse(c, 12.0, 11.0, Palette.BOSS_BURROW.darkened(0.1))


## A walking haystack with two twisted straw arms raised high, two glowing
## eyes peeking under a straw fringe, and a small sheaf of seed heads on top
## (its dazzle, like the Gleamer's fan).
static func _old_hayrick(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 38.0)
	var b: float = _bob(frame, 2.0)
	var wave: float = 3.0 if frame % 2 == 0 else -3.0
	_feet(pen, [-11.0, 11.0], Palette.BOSS_HAY_DARK.darkened(0.25), frame, 9.0)
	for side: float in [-1.0, 1.0]:
		var hand: Vector2 = Vector2(42 * side, -32 + b + wave * side)
		pen.path(PackedVector2Array([Vector2(22 * side, -2 + b), Vector2(34 * side, -12 + b), hand]), 6.0, Palette.BOSS_HAY_DARK)
		pen.poly(_fuzzy(hand + Vector2(2 * side, -4), 8.0, 7.0, 12, 3.0), Palette.BOSS_HAY)
	for i: int in 3:
		var ang: float = deg_to_rad(-90.0 + 22.0 * (float(i) - 1.0))
		var root: Vector2 = Vector2(0, -24 + b)
		var tip: Vector2 = root + Vector2(cos(ang), sin(ang)) * 18.0
		pen.stroke(root, tip, 2.6, Palette.BOSS_HAY_DARK)
		pen.rotate_about(tip, ang + PI / 2.0)
		pen.ellipse(tip, 3.4, 6.5, Palette.BOSS_HAY)
		pen.unrotate()
		pen.glow(tip, 8.0, Palette.BUBBLE, 0.6)
	var hay: PackedVector2Array = PackedVector2Array()
	for i: int in 9:
		hay.append(Vector2(-29.0 + float(i) * 7.25, (31.0 if i % 2 == 0 else 26.0) + b))
	for p: Vector2 in [Vector2(29, 16), Vector2(31, 4), Vector2(27, -4), Vector2(28, -10), Vector2(18, -20), Vector2(6, -27), Vector2(-6, -27), Vector2(-18, -20), Vector2(-28, -10), Vector2(-27, -4), Vector2(-31, 4), Vector2(-29, 16)]:
		hay.append(p + Vector2(0, b))
	pen.poly(hay, Palette.BOSS_HAY)
	for k: int in 6:
		var x: float = -22.0 + float(k) * 9.0
		pen.detail(Vector2(x, 26 + b), Vector2(x * 0.7, 8 + b), 1.4, Palette.BOSS_HAY_DARK)
	pen.detail(Vector2(-29, 14 + b), Vector2(29, 14 + b), 2.4, Palette.BOSS_HAY_DARK)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(2, -4 + b), 17.0, 8.0, 14), Palette.BOSS_HAY_DARK)
	pen.eye(Vector2(-5, -4 + b), 4.6)
	pen.eye(Vector2(9, -4 + b), 4.6)
	for k: int in 7:
		var x: float = -16.0 + float(k) * 5.5
		pen.detail(Vector2(x, -18 + b), Vector2(x + 1.0, -9 + b), 1.6, Palette.BOSS_HAY.darkened(0.08))


## A huge, slow, droopy-eared beast walking low, a big snowball riding on
## its back like a snail's shell. The render scales it up to 1.5 times as it
## grows.
static func _snowsnore(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 46.0)
	var dark: Color = Palette.BOSS_SNORE.darkened(0.3)
	for i: int in 4:
		var x: float = -28.0 + float(i) * 17.0
		var lift: float = -3.0 if (i + frame) % 2 == 0 and frame % 2 == 1 else 0.0
		pen.box(x - 6.0, 26 + lift, x + 6.0, 35 + lift, dark)
	pen.poly(_fuzzy(Vector2(0, 21), 40.0, 13.0, 26, 3.0), Palette.BOSS_SNORE)
	pen.circle(Vector2(-18, -6), 23.0, Palette.CREATURE_SNOWBALL)
	pen.detail_path(InkPen.arc_pts(Vector2(-18, -6), 14.0, 14.0, 0.4 + float(frame) * 0.4, 2.2 + float(frame) * 0.4, 8), 2.0, Palette.CREATURE_SNOWBALL.darkened(0.15))
	pen.detail_path(InkPen.arc_pts(Vector2(-18, -6), 7.0, 7.0, 3.2, 5.0, 6), 2.0, Palette.CREATURE_SNOWBALL.darkened(0.15))
	pen.circle(Vector2(34, 14), 13.0, Palette.BOSS_SNORE)
	for side: float in [-1.0, 1.0]:
		var ex: float = 34.0 + 11.0 * side
		var ear: PackedVector2Array = PackedVector2Array([Vector2(ex - 3.0 * side, 4), Vector2(ex + 4.0 * side, 6), Vector2(ex + 5.0 * side, 26), Vector2(ex + 1.0 * side, 31), Vector2(ex - 2.0 * side, 18)])
		if side < 0.0:
			ear.reverse()
		pen.poly(ear, dark)
	pen.detail_path(InkPen.arc_pts(Vector2(30, 11), 3.0, 2.2, 0.2, PI - 0.2, 5), 1.8, Palette.INK_LINE)
	pen.detail_path(InkPen.arc_pts(Vector2(38, 11), 3.0, 2.2, 0.2, PI - 0.2, 5), 1.8, Palette.INK_LINE)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(36, 20), 3.6, 2.8, 10), Palette.INK_LINE)
	for x: float in [-6.0, 2.0]:
		pen.detail_poly(PackedVector2Array([Vector2(x - 2.5, 8), Vector2(x + 2.5, 8), Vector2(x, 14)]), Palette.BUBBLE)


## A huge, low, squat toad: two tall eye bumps on top, big folded haunches,
## and glowing spots on its back.
static func _glimmertoad(pen: InkPen, frame: int) -> void:
	pen.shadow(Vector2(0, 37), 48.0)
	var b: float = -4.0 if frame % 2 == 1 else 0.0
	var dark: Color = Palette.BOSS_TOAD.darkened(0.25)
	pen.ellipse(Vector2(-36, 24 + b), 15.0, 11.0, dark)
	pen.ellipse(Vector2(26, 32), 9.0, 4.0, dark)
	pen.ellipse(Vector2(-6, 18 + b), 44.0, 17.0, Palette.BOSS_TOAD)
	pen.ellipse(Vector2(26, 13 + b), 20.0, 13.0, Palette.BOSS_TOAD)
	pen.circle(Vector2(16, -2 + b), 10.0, Palette.BOSS_TOAD)
	pen.circle(Vector2(35, 0 + b), 9.0, Palette.BOSS_TOAD)
	pen.eye(Vector2(17, -3 + b), 5.0)
	pen.eye(Vector2(36, -1 + b), 4.6)
	pen.detail_path(InkPen.arc_pts(Vector2(30, 11 + b), 15.0, 7.0, 0.2, 1.4, 8), 2.0, Palette.INK_LINE)
	pen.detail_poly(InkPen.ellipse_pts(Vector2(26, 23 + b), 13.0, 5.0, 12), Palette.BOSS_TOAD.lightened(0.25))
	for p: Vector2 in [Vector2(-28, 10), Vector2(-12, 6), Vector2(-34, 20), Vector2(2, 10), Vector2(-18, 18)]:
		pen.glow(p + Vector2(0, b), 9.0, Palette.BOSS_TOAD_SPOT, 0.9)
		pen.detail_circle(p + Vector2(0, b), 3.6, Palette.BOSS_TOAD_SPOT)


# Shape helpers.

static func _fuzzy(c: Vector2, rx: float, ry: float, n: int, depth: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		var k: float = 1.0 if i % 2 == 0 else 1.0 - depth / maxf(rx, ry)
		pts.append(c + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	return pts


## An ellipse with `bumps` round bumps around it.
static func _scalloped(c: Vector2, rx: float, ry: float, bumps: int, depth: float) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = bumps * 6
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		var k: float = 1.0 - depth + depth * absf(sin(a * float(bumps) * 0.5))
		pts.append(c + Vector2(cos(a) * rx * k, sin(a) * ry * k))
	return pts


static func _closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = pts.duplicate()
	out.append(pts[0])
	return out
