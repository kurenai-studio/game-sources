# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapShots
extends Node2D
## Drawn projectiles and the short one-shot marks (muzzle puffs, hit flashes, splashes, pop rings,
## firework bursts, heal pluses, coin glints, speed lines, pulses), in one overlay redrawn every
## frame while something is flying (docs/ARCHITECTURE.md 9.3). The sim has no shots: a hit lands
## the tick a tower fires, and these are only the picture. They fly fast so they arrive at about
## the same time. Every mark has a shape of its own, so none of them is only a color. Each shot
## has three parts: a mark where it leaves, a body with a short trail in flight, and a mark where
## it lands. A lobbed shot (the catapult) also shows its true splash area on the ground while it
## flies. Internal to src/render/.

const CELL: float = 128.0
const MAX_SHOTS: int = 96
const MAX_FLASHES: int = 90

## The pictures of the shots. The Longbow Loft fires ARROW (its Triple Bow fires three at three
## targets) or GIANT_ARROW; the Firework Tower fires ROCKET with a small burst, BLOOM with a
## wide burst, or one heavy SKYROCKET. The Pumpkin Catapult lobs PUMPKIN, JAM (the jam pot) or
## PRIZE (the huge pumpkin). The Bramble Cottage sends one ring of THORNS out to its reach, the Snow
## Fort rolls one SNOWBALL (BIG_SNOWBALL for the Big Snowball path) from its center to the end of its
## line, and the Moth Lantern sends a BEAM of light to each flyer it lures.
enum Look { PEBBLE, STONE, PUMPKIN, JAM, ARROW, GIANT_ARROW, ROCKET, BLOOM, SKYROCKET, PRIZE, THORNS, SNOWBALL, BIG_SNOWBALL, BEAM }
## The short marks, in the order of their lifetimes below.
enum Fx { HIT, RING, BURST, PLUS, COIN, WHOOSH, PULSE, MUZZLE, SPLASH }
## PULSE colors: a heal ring, a release ring, a gate ring, a yawn ring.
enum Hue { HEAL, RELEASE, GATE, YAWN }

## Per look: speed in cells a second, the shortest and longest flight in seconds, the arc height
## in cells.
## A thorn ring has no length: it takes SHORTEST (= LONGEST) to open out to its reach.
const SPEED: Array[float] = [22.0, 18.0, 18.0, 18.0, 34.0, 30.0, 28.0, 28.0, 24.0, 16.0, 1.0, 14.0, 12.0, 40.0]
const SHORTEST: Array[float] = [0.05, 0.05, 0.11, 0.11, 0.05, 0.05, 0.05, 0.05, 0.05, 0.12, 0.3, 0.14, 0.16, 0.06]
const LONGEST: Array[float] = [0.16, 0.18, 0.16, 0.16, 0.14, 0.16, 0.13, 0.13, 0.2, 0.17, 0.3, 0.36, 0.4, 0.14]
const ARC: Array[float] = [0.08, 0.1, 0.9, 0.9, 0.0, 0.0, 0.1, 0.15, 0.05, 1.1, 0.0, 0.0, 0.0, 0.0]
## Per Fx: how long it lasts, in seconds.
const LIFE: Array[float] = [0.18, 0.28, 0.5, 0.6, 0.55, 0.35, 0.45, 0.26, 0.75]
const BURST_COLORS: Array[Color] = [Palette.HONEY, Palette.ROOF_CLAY, Palette.SPARKLE, Palette.SPARKLE_LILAC]
const HUES: Array[Color] = [Palette.HP_FILL, Palette.SPARKLE_LILAC, Palette.SPARKLE, Palette.BUBBLE]
## The most hit marks one pulse or one line makes, so a crowd stays calm and the cap of MAX_FLASHES holds.
const MAX_MARKED: int = 12
## A snowball is drawn this much smaller than the line it hits, which is as wide as the sim's.
const SNOW_FIT: float = 0.8
## How far the picture of a pumpkin or rocket landing may slide toward its creature, which walks on
## while the shot flies, as a fraction of the true splash radius. The splash area itself never moves.
const AIM_REACH: float = 0.35
## The farthest a single-target hit mark reaches from the creature's center at its peak, in cells.
## A heavy hit (Giant Bow, Skyrocket) reaches a little more. Twice the heavy reach is still less than
## the smallest creature (a Pip or a Puff, 0.4 of a cell), so a mark never hides one or its health bar.
const HIT_REACH: float = 0.15
const HIT_REACH_HEAVY: float = 0.19
## The ink edge makes a ring this much wider than the radius it is drawn at.
const RING_INK: float = 1.07


class Shot:
	extends RefCounted
	var look: int = 0
	var from: Vector2 = Vector2.ZERO
	## Where the picture of the shot ends. It follows its creature while the creature is on the map.
	var to: Vector2 = Vector2.ZERO
	## Where the sim hit, for the shots that land on a spot. The splash area stays centered here.
	var spot: Vector2 = Vector2.ZERO
	var t0: float = 0.0
	var t1: float = 0.0
	var target: int = -1
	## A shot that lands on a spot: the splash radius in pixels. A lobbed shot draws it on the ground
	## while it flies.
	var radius: float = 0.0


class Flash:
	extends RefCounted
	var kind: int = 0
	var at: Vector2 = Vector2.ZERO
	var t0: float = 0.0
	var life: float = 0.14
	## HIT: a size multiplier. BURST, PULSE, SPLASH: the radius in pixels. COIN: a size
	## multiplier. WHOOSH: the creature's size in pixels.
	var size: float = 1.0
	## BURST: 1 for the wide Star Bloom burst. PULSE: a Hue. HIT, MUZZLE: the Look.
	## SPLASH: 0 pumpkin, 1 jam, 2 prize pumpkin.
	var hue: int = 0
	## WHOOSH: 1.0 when the creature faces right, -1.0 when it faces left.
	var dir: float = 1.0
	## HIT, MUZZLE: the direction the shot flew, in radians.
	var ang: float = 0.0
	## SPLASH, BURST: where the shot's picture landed, on the creature. It stays within AIM_REACH of
	## `at`, which is the center of the true splash area.
	var aim: Vector2 = Vector2.ZERO


## The sheet the pictures are cut from (set by MapView). Nothing draws without it.
var atlas: MapAtlas
var shots: Array[Shot] = []
var flashes: Array[Flash] = []
var now: float = 0.0
## For tests: how many shots of each look were launched, and how many marks of each Fx.
var launched: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var marked: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0])
var _drawn_last: bool = false
var _tex: Texture2D
var _pieces: Array[MapAtlas.Entry] = []


## Which look a tower's shot has. Bells and Bakeries never fire.
static func look_for(tower: StringName, spec: int) -> int:
	match tower:
		&"bramble_cottage":
			return Look.THORNS
		&"snow_fort":
			return Look.BIG_SNOWBALL if spec == 0 else Look.SNOWBALL
		&"moth_lantern":
			return Look.BEAM
		&"sling_post":
			return Look.STONE if spec == 1 else Look.PEBBLE
		&"pumpkin_catapult":
			if spec == 0:
				return Look.PRIZE
			return Look.JAM if spec == 1 else Look.PUMPKIN
		&"longbow_loft":
			return Look.GIANT_ARROW if spec == 0 else Look.ARROW
		&"firework_tower":
			if spec == 0:
				return Look.BLOOM
			return Look.SKYROCKET if spec == 1 else Look.ROCKET
	return Look.PEBBLE


## True for the Snow Fort's looks: one ball along the sim's line.
static func is_line(look: int) -> bool:
	return look == Look.SNOWBALL or look == Look.BIG_SNOWBALL


## True for the looks whose picture has a true size, kept in Shot.radius: a thorn ring's reach and a
## snowball's half width.
static func has_extent(look: int) -> bool:
	return look == Look.THORNS or is_line(look)


## True for the looks that make their hit marks when they are launched, on each target at the moment
## the picture passes it: the thorn ring and the rolling snowball.
static func look_is_placed(look: int) -> bool:
	return look == Look.THORNS or is_line(look)


## True for the catapult's looks: they fly high, show their splash area and land with a splash.
static func is_lobbed(look: int) -> bool:
	return look == Look.PUMPKIN or look == Look.JAM or look == Look.PRIZE


## True for the looks that end in a burst or a splash at the spot the sim hit (the lobbed shots, the
## Rocket and the Bloom). Their picture follows the creature, which walks on, but only a short way
## (AIM_REACH of the splash radius), so the area itself stays centered on the spot the sim hit.
static func lands_on_spot(look: int) -> bool:
	return is_lobbed(look) or look == Look.ROCKET or look == Look.BLOOM


## Where a tower's shot leaves from, in map pixels. A tower stands higher on each tier (one stone
## step, 0.08 of a cell), so its top moves up. A Triple Bow (spec 1) sends shot `index` from its own
## bow: left, middle (a little higher), right.
static func muzzle(tower: StringName, cell: Vector2i, tier: int = 3, spec: int = -1, index: int = 0) -> Vector2:
	var at_full: Vector2 = _muzzle_full(tower, cell, tier, spec, index)
	# Towers are drawn at MapAtlas.TOWER_SCALE about their ground line, so the muzzle moves with them.
	var ground: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5 + Silhouettes.TOWER_GROUND)) * CELL
	return ground + (at_full - ground) * MapAtlas.TOWER_SCALE


static func _muzzle_full(tower: StringName, cell: Vector2i, tier: int, spec: int, index: int) -> Vector2:
	var c: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * CELL
	var lift: float = 0.08 * float(clampi(tier, 1, 3) - 1)
	match tower:
		&"pumpkin_catapult":
			return c + Vector2(0.14, -0.42 - lift) * CELL
		&"longbow_loft":
			var x: float = 0.0
			var rise: float = 0.0
			if spec == 1 and tier == 3:
				x = (float(index % 3) - 1.0) * 0.3
				rise = 0.06 if index % 3 == 1 else 0.0
			return c + Vector2(x, -0.56 - lift - rise) * CELL
		&"firework_tower":
			return c + Vector2(0.0, -0.58 - lift) * CELL
		&"moth_lantern":
			# Where the lantern hangs: one big one, or one of the three of the Garland.
			if tier == 3 and spec == 0:
				return c + Vector2(0.08, -0.49 - lift) * CELL
			if tier == 3 and spec == 1:
				var lamps: Array[Vector2] = [Vector2(0.30, -0.34), Vector2(0.35, -0.16), Vector2(0.44, 0.02)]
				return c + (lamps[index % 3] + Vector2(0.0, -lift)) * CELL
			return c + Vector2(0.30, -0.31 - lift) * CELL
	return c + Vector2(0.0, -0.5) * CELL


## Starts a shot and returns the time it arrives. `splash` is the splash radius in pixels of a shot
## that lands on a spot (a lobbed shot, a Rocket, a Bloom). A lobbed shot draws it on the ground while
## it flies, and the landing splash or burst has it. 0 draws no area. A mark is made where it leaves.
func launch(look: int, from: Vector2, to: Vector2, target: int, at_time: float, splash: float = 0.0) -> float:
	var length_cells: float = from.distance_to(to) / CELL
	var flight: float = clampf(length_cells / SPEED[look], SHORTEST[look], LONGEST[look])
	if shots.size() >= MAX_SHOTS:
		shots.remove_at(0)
	var s: Shot = Shot.new()
	s.look = look
	s.from = from
	s.to = to
	s.spot = to
	s.t0 = at_time
	s.t1 = at_time + flight
	s.target = target
	s.radius = splash if (lands_on_spot(look) or has_extent(look)) else 0.0
	shots.append(s)
	launched[look] += 1
	_add_flash(Fx.MUZZLE, from, at_time, 1.0, look, 1.0, (to - from).angle())
	_wake()
	return s.t1


## A bubble pop ring.
func add_ring(at: Vector2, at_time: float) -> void:
	_add_flash(Fx.RING, at, at_time, 1.0, 0, 1.0)


## A "+" that rises from a creature that was healed.
func add_plus(at: Vector2, at_time: float) -> void:
	_add_flash(Fx.PLUS, at, at_time, 1.0, 0, 1.0)


## A small coin that rises and twinkles. `scale` 1.0 is the glint of one creature.
func add_coin(at: Vector2, at_time: float, scale: float = 1.0) -> void:
	_add_flash(Fx.COIN, at, at_time, scale, 0, 1.0)


## Speed lines trailing a creature of `size` pixels that just got faster.
func add_whoosh(at: Vector2, at_time: float, size: float, facing_left: bool) -> void:
	_add_flash(Fx.WHOOSH, at, at_time, size, 0, -1.0 if facing_left else 1.0)


## A ring that spreads to `radius` pixels.
func add_pulse(at: Vector2, at_time: float, radius: float, hue: Hue) -> void:
	_add_flash(Fx.PULSE, at, at_time, radius, hue, 1.0)


## A hit mark. `big` makes it larger (the Giant Bow, the Skyrocket). `look` and `angle` (the
## direction the shot flew) pick its shape.
func add_hit(at: Vector2, at_time: float, big: float = 1.0, look: int = Look.PEBBLE, angle: float = 0.0) -> void:
	_add_flash(Fx.HIT, at, at_time, big, look, 1.0, angle)


## Points the picture of a shot at where its creature is now. A shot that lands on a spot slides at
## most AIM_REACH of its splash radius from the spot the sim hit, so the splash area stays honest.
func aim_at(s: Shot, p: Vector2) -> void:
	if lands_on_spot(s.look):
		s.to = s.spot + (p - s.spot).limit_length(s.radius * AIM_REACH)
	else:
		s.to = p


## Moves the clock on, ends the shots that arrived and starts their landing marks.
func advance(time_now: float) -> void:
	now = time_now
	var i: int = 0
	while i < shots.size():
		var s: Shot = shots[i]
		if now >= s.t1:
			_land(s)
			shots.remove_at(i)
		else:
			i += 1
	i = 0
	while i < flashes.size():
		if now - flashes[i].t0 > flashes[i].life:
			flashes.remove_at(i)
		else:
			i += 1
	if not shots.is_empty() or not flashes.is_empty():
		queue_redraw()
		_drawn_last = true
	elif _drawn_last:
		_drawn_last = false
		queue_redraw()


func is_busy() -> bool:
	return not shots.is_empty() or not flashes.is_empty()


func _wake() -> void:
	queue_redraw()
	_drawn_last = true


## The mark a shot makes where it lands: a splash for the catapult, a burst and a hit mark for the
## small fireworks, else a hit mark. The splash and the burst are centered on the spot the sim hit
## and show its true radius. What flies out of them lands on the creature.
func _land(s: Shot) -> void:
	if look_is_placed(s.look):
		return
	var radius: float = s.radius if s.radius > 0.0 else CELL * 0.75
	if is_lobbed(s.look):
		var hue: int = 1 if s.look == Look.JAM else (2 if s.look == Look.PRIZE else 0)
		_add_flash(Fx.SPLASH, s.spot, s.t1, radius, hue, 1.0).aim = s.to
		return
	if s.look == Look.ROCKET or s.look == Look.BLOOM:
		_add_flash(Fx.BURST, s.spot, s.t1, radius, 1 if s.look == Look.BLOOM else 0, 1.0).aim = s.to
	var heavy: float = 1.8 if (s.look == Look.GIANT_ARROW or s.look == Look.SKYROCKET) else 1.0
	_add_flash(Fx.HIT, s.to, s.t1, heavy, s.look, 1.0, (s.to - s.from).angle())


func _add_flash(kind: int, at: Vector2, t0: float, size: float, hue: int, dir: float, ang: float = 0.0) -> Flash:
	if flashes.size() >= MAX_FLASHES:
		flashes.remove_at(0)
	var f: Flash = Flash.new()
	f.kind = kind
	f.at = at
	f.t0 = t0
	f.life = LIFE[kind]
	f.size = size
	f.hue = hue
	f.dir = dir
	f.ang = ang
	f.aim = at
	flashes.append(f)
	marked[kind] += 1
	_wake()
	return f


func _point(s: Shot, u: float) -> Vector2:
	var arc: float = ARC[s.look] * CELL * 4.0 * u * (1.0 - u)
	return s.from.lerp(s.to, u) + Vector2(0.0, -arc)


func _draw() -> void:
	if not _prepare():
		return
	for s: Shot in shots:
		var u: float = clampf((now - s.t0) / maxf(s.t1 - s.t0, 0.001), 0.0, 1.0)
		var p: Vector2 = _point(s, u)
		var ahead: Vector2 = _point(s, minf(u + 0.05, 1.0))
		var dir: Vector2 = (ahead - p).normalized() if ahead != p else Vector2.RIGHT
		_draw_shot(s, p, dir, u)
	for f: Flash in flashes:
		if now < f.t0:
			continue
		var k: float = clampf((now - f.t0) / f.life, 0.0, 1.0)
		match f.kind:
			Fx.HIT:
				_draw_hit(f, k)
			Fx.RING:
				_ring(f.at, CELL * (0.12 + 0.3 * k), Color(Palette.BUBBLE, 1.0 - k))
			Fx.BURST:
				_draw_burst(f, k)
			Fx.PLUS:
				_draw_plus(f, k)
			Fx.COIN:
				_draw_coin(f, k)
			Fx.WHOOSH:
				_draw_whoosh(f, k)
			Fx.PULSE:
				_draw_pulse(f, k)
			Fx.MUZZLE:
				_draw_muzzle(f, k)
			Fx.SPLASH:
				_draw_splash(f, k)


# Drawing. Every part is a quad of the MapAtlas sheet (ShotPieces), so a whole frame of shots and
# marks batches into a very few draw calls.

## Looks up the pieces on the sheet. False while the view has not given this overlay its sheet.
func _prepare() -> bool:
	if atlas == null:
		return false
	if _pieces.is_empty():
		for i: int in ShotPieces.Piece.size():
			var e: MapAtlas.Entry = atlas.entry_for(ShotPieces.key(i))
			if e == null:
				_pieces.clear()
				return false
			_pieces.append(e)
		_tex = atlas.get_texture()
	return true


## One piece with its anchor at `at`, `sx` and `sy` times its natural size, tinted by `col`, turned
## by `rot` radians about the anchor.
func _q(piece: int, at: Vector2, sx: float, sy: float, col: Color, rot: float = 0.0) -> void:
	var e: MapAtlas.Entry = _pieces[piece]
	var size: Vector2 = Vector2(e.tile.x * sx, e.tile.y * sy)
	var origin: Vector2 = Vector2(e.anchor.x * sx, e.anchor.y * sy)
	# The sheet is premultiplied and drawn with the premultiplied blend, so the tint is too.
	var tint: Color = Color(col.r * col.a, col.g * col.a, col.b * col.a, col.a)
	if rot != 0.0:
		draw_set_transform(at, rot, Vector2.ONE)
		draw_texture_rect_region(_tex, Rect2(-origin, size), e.rect, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect_region(_tex, Rect2(at - origin, size), e.rect, tint)


## A soft filled disc of radius `r` pixels.
func _disc(at: Vector2, r: float, col: Color) -> void:
	var s: float = r / (ShotPieces.DISC_R * CELL)
	_q(ShotPieces.Piece.DISC, at, s, s, col)


## A ring of radius `r` pixels, edged in ink. Its thickness grows with its radius.
func _ring(at: Vector2, r: float, col: Color) -> void:
	var s: float = r / (ShotPieces.RING_R * CELL)
	_q(ShotPieces.Piece.RING, at, s, s, col)


## A ring of eight dashes, turned by `rot`.
func _dashes(at: Vector2, r: float, rot: float, col: Color) -> void:
	var s: float = r / (ShotPieces.RING_R * CELL)
	_q(ShotPieces.Piece.DASH, at, s, s, col, rot)


## A bead of visible radius `r` pixels with an ink edge.
func _bead(at: Vector2, r: float, col: Color) -> void:
	var s: float = r / (0.17 * CELL)
	_q(ShotPieces.Piece.BEAD, at, s, s, col)


## A line from `a` to `b`, `width` pixels thick with ink along its sides.
func _bar(a: Vector2, b: Vector2, width: float, col: Color) -> void:
	var length: float = a.distance_to(b)
	if length < 0.5:
		return
	_q(ShotPieces.Piece.BAR, a, length / CELL, width / (0.11 * CELL), col, (b - a).angle())


## A star whose tips reach `r` pixels, turned by `rot`. `wide` picks the eight point star.
func _star(at: Vector2, r: float, wide: bool, rot: float, col: Color) -> void:
	var s: float = r / (0.45 * CELL)
	_q(ShotPieces.Piece.STAR8 if wide else ShotPieces.Piece.STAR4, at, s, s, col, rot)


## A fading streak that ends at `head` and runs back `length` pixels along `angle`.
func _streak(head: Vector2, angle: float, length: float, width: float, col: Color) -> void:
	_q(ShotPieces.Piece.TRAIL, head, length / CELL, width / (0.3 * CELL), col, angle)


## A puff of smoke of radius `r` pixels.
func _puff(at: Vector2, r: float, a: float) -> void:
	var s: float = r / (0.4 * CELL)
	_q(ShotPieces.Piece.PUFF, at, s, s, Color(1, 1, 1, a))


# Where a shot leaves.

## Per look, what shows at the tower when it fires: a flick and dust for the sling, a swung arm and
## dust for the catapult, a twang for the bows, smoke and sparks for the fireworks.
func _draw_muzzle(f: Flash, k: float) -> void:
	var d: Vector2 = Vector2.from_angle(f.ang)
	var a: float = 1.0 - k
	var e: float = 1.0 - (1.0 - k) * (1.0 - k)
	match f.hue:
		Look.PEBBLE, Look.STONE:
			var big: float = 1.0 if f.hue == Look.PEBBLE else 1.5
			_disc(f.at, CELL * 0.1 * big * (1.0 + 0.5 * k), Color(Palette.PLASTER, 0.75 * a))
			for j: int in 3:
				var dd: Vector2 = d.rotated((float(j) - 1.0) * 0.6)
				_bar(f.at + dd * CELL * (0.07 + 0.05 * e) * big, f.at + dd * CELL * (0.15 + 0.17 * e) * big, CELL * 0.045 * big, Color(Palette.SPARKLE, a))
		Look.PUMPKIN, Look.JAM, Look.PRIZE:
			var big: float = 1.35 if f.hue == Look.PRIZE else 1.0
			var r: float = CELL * (0.2 + 0.14 * e) * big
			_q(ShotPieces.Piece.ARC, f.at, r / (0.8 * CELL), r / (0.8 * CELL), Color(Palette.SPARKLE, a), f.ang + PI - 0.3)
			for j: int in 3:
				var off: Vector2 = Vector2((float(j) - 1.0) * 0.13, -0.05 - 0.22 * e - 0.04 * float(j % 2)) * CELL * big
				_puff(f.at + off, CELL * (0.05 + 0.07 * k) * big, 0.9 * a)
			var fleck: Color = Palette.JAM if f.hue == Look.JAM else Palette.PUMPKIN
			for j: int in 3:
				var fp: Vector2 = f.at + d.rotated((float(j) - 1.0) * 0.5) * CELL * (0.1 + 0.22 * e) * big
				_bead(fp, CELL * 0.03 * big, Color(fleck, a))
		Look.ARROW, Look.GIANT_ARROW:
			var big: float = 1.7 if f.hue == Look.GIANT_ARROW else 1.0
			var back: Vector2 = f.at - d * CELL * 0.06 * big
			for j: int in 2:
				var r: float = CELL * (0.12 + 0.16 * e + 0.1 * float(j)) * big
				_q(ShotPieces.Piece.ARC, back, r / (0.8 * CELL), r / (0.8 * CELL), Color(Palette.BONE, a * (1.0 - 0.3 * float(j))), f.ang)
			var side: Vector2 = Vector2(-d.y, d.x)
			for j: int in 2:
				var o: Vector2 = side * (float(j) * 2.0 - 1.0) * CELL * 0.06 * big
				_streak(f.at + o, f.ang + PI, CELL * (0.16 + 0.2 * e) * big, CELL * 0.05 * big, Color(Palette.SPARKLE, 0.8 * a))
		Look.THORNS:
			# Four thorns pop up from the ground round the cottage and a puff of leaf dust.
			for j: int in 4:
				var up: float = TAU * (float(j) + 0.5) / 4.0
				var o: Vector2 = f.at + Vector2.from_angle(up) * CELL * (0.1 + 0.1 * e)
				_q(ShotPieces.Piece.THORN, o, 0.5, 0.5, Color(Palette.HOLLY.lightened(0.3), a), up)
			_puff(f.at, CELL * (0.12 + 0.1 * k), 0.6 * a)
		Look.SNOWBALL, Look.BIG_SNOWBALL:
			var big: float = 1.4 if f.hue == Look.BIG_SNOWBALL else 1.0
			for j: int in 3:
				var off: Vector2 = Vector2((float(j) - 1.0) * 0.14, -0.04 - 0.14 * e - 0.04 * float(j % 2)) * CELL * big
				_disc(f.at + off, CELL * (0.07 + 0.07 * k) * big, Color(Palette.SNOW_WARM, 0.85 * a))
			for j: int in 3:
				var fp: Vector2 = f.at + d.rotated((float(j) - 1.0) * 0.5) * CELL * (0.1 + 0.22 * e) * big
				_bead(fp, CELL * 0.03 * big, Color(Palette.SNOW_WARM, a))
		Look.BEAM:
			# The lantern flares: a soft glow and a four point twinkle.
			_disc(f.at, CELL * 0.2 * (1.0 - 0.4 * k), Color(Palette.GLOW, 0.55 * a))
			_disc(f.at, CELL * 0.08 * (1.0 - 0.4 * k), Color(Palette.LANTERN_CORE, a))
			_star(f.at, CELL * 0.16 * (0.6 + 0.4 * e), false, k * 1.2, Color(Palette.LANTERN_CORE, a))
		_:
			var big: float = 1.0
			if f.hue == Look.SKYROCKET:
				big = 1.5
			elif f.hue == Look.BLOOM:
				big = 1.2
			var glow: Color = Palette.HONEY if f.hue == Look.BLOOM else Palette.GLOW
			_disc(f.at, CELL * 0.2 * big * (1.0 - 0.5 * k), Color(glow, 0.6 * a))
			_disc(f.at, CELL * 0.09 * big * (1.0 - 0.5 * k), Color(Palette.LANTERN_CORE, a))
			for j: int in 7:
				var dd: Vector2 = Vector2.from_angle(PI * 0.5 + (float(j) - 3.0) * 0.38)
				_bar(f.at + dd * CELL * 0.1 * big, f.at + dd * CELL * (0.16 + 0.2 * e) * big, CELL * 0.035 * big, Color(Palette.SPARKLE if j % 2 == 0 else glow, a))
			for j: int in 3:
				var off: Vector2 = Vector2((float(j) - 1.0) * 0.1 * big, -0.1 - (0.12 + 0.1 * float(j)) * e * big) * CELL
				_puff(f.at + off, CELL * (0.05 + 0.07 * k) * big, 0.85 * a)


# Where it lands.

## How far a single-target hit mark reaches from the creature's center, in pixels, `k` of the way
## through its life (0 to 1). Every part of it (flash, star, ring, chips, puffs) stays inside this
## radius, ink edge included.
static func hit_reach(heavy: bool, k: float) -> float:
	var e: float = 1.0 - (1.0 - k) * (1.0 - k)
	return CELL * (HIT_REACH_HEAVY if heavy else HIT_REACH) * (0.6 + 0.4 * e)


## Per look, a hit mark: a small flash on the creature, a star, and chips, a ring, a stuck arrow or
## a bang to suit the shot. It is smaller than the smallest creature and quick, so it never hides a
## creature or its health bar for long.
func _draw_hit(f: Flash, k: float) -> void:
	var a: float = 1.0 - k
	var e: float = 1.0 - (1.0 - k) * (1.0 - k)
	var heavy: bool = f.hue == Look.GIANT_ARROW or f.hue == Look.SKYROCKET
	var r: float = hit_reach(heavy, k)
	_disc(f.at, r * 0.8, Color(Palette.SPARKLE, 0.55 * a))
	var col: Color = Palette.LANTERN if f.hue == Look.SKYROCKET else Palette.SPARKLE
	if f.hue == Look.BEAM:
		col = Palette.GLOW
	elif f.hue == Look.SNOWBALL or f.hue == Look.BIG_SNOWBALL:
		col = Palette.SNOW_WARM
	# A star's drawn tips reach 1.11 times the size given.
	_star(f.at, r / 1.11, heavy or f.hue == Look.STONE, PI / 4.0, Color(col, a))
	match f.hue:
		Look.PEBBLE:
			for j: int in 4:
				var d: Vector2 = Vector2.from_angle(TAU * float(j) / 4.0 + 0.2)
				var cp: Vector2 = f.at + d * (r - CELL * 0.045) + Vector2(0.0, -sin(PI * k) * CELL * 0.04)
				_bead(cp, CELL * 0.022, Color(Palette.PLASTER, a))
		Look.STONE:
			for j: int in 4:
				var d: Vector2 = Vector2.from_angle(TAU * float(j) / 4.0 + 0.5)
				var cp: Vector2 = f.at + d * maxf(r - CELL * 0.075, 0.0) + Vector2(0.0, -sin(PI * k) * CELL * 0.03)
				_bead(cp, CELL * 0.035, Color(Palette.STONE, a))
			_ring(f.at, r / RING_INK, Color(Palette.STONE, 0.9 * a))
		Look.ARROW, Look.GIANT_ARROW:
			var wob: float = sin(k * 38.0) * 0.14 * a
			var big: float = 1.15 if f.hue == Look.GIANT_ARROW else 1.0
			var fade: float = 1.0 if k < 0.65 else 1.0 - (k - 0.65) / 0.35
			_q(ShotPieces.Piece.ARROW, f.at, big, big, Color(1, 1, 1, fade), f.ang + wob)
			if heavy:
				_ring(f.at, r / RING_INK, Color(Palette.SPARKLE, a))
		Look.SKYROCKET:
			_disc(f.at, r * 0.5 * (1.0 - 0.6 * k), Color(Palette.LANTERN_CORE, a))
			_ring(f.at, r / RING_INK, Color(Palette.GLOW, a))
			for j: int in 3:
				var off: Vector2 = Vector2((float(j) - 1.0) * 0.4 * r, -(0.35 + 0.2 * e) * r)
				_puff(f.at + off, r * 0.26, 0.7 * a)
		Look.THORNS:
			# Four thorns round the creature, tips inward, all inside the reach r.
			var len_k: float = r * 0.6 / (ShotPieces.THORN_LENGTH * CELL)
			for j: int in 4:
				var up: float = TAU * float(j) / 4.0 + 0.4
				_q(ShotPieces.Piece.THORN, f.at + Vector2.from_angle(up) * r * 0.92, len_k, len_k, Color(Palette.HOLLY.lightened(0.3), a), up + PI)
		Look.SNOWBALL, Look.BIG_SNOWBALL:
			for j: int in 4:
				var d: Vector2 = Vector2.from_angle(TAU * float(j) / 4.0 + 0.2)
				var cp: Vector2 = f.at + d * (r - CELL * 0.045) + Vector2(0.0, -sin(PI * k) * CELL * 0.04)
				_bead(cp, CELL * 0.026, Color(Palette.SNOW_WARM, a))
			_ring(f.at, r / RING_INK, Color(Palette.SNOW_WARM, 0.9 * a))
		Look.BEAM:
			# The flyer is pulled down: a ring closes in on it.
			_ring(f.at, r / RING_INK * (1.0 - 0.35 * e), Color(Palette.BUBBLE, a))
			_disc(f.at, r * 0.45 * (1.0 - 0.6 * k), Color(Palette.LANTERN_CORE, a))


## A lobbed shot lands: the splash area spreads out to its true radius around the spot the sim hit
## (a filled disc with a ring on its edge). The splat, the chunks and the sparkles are centered on
## where the pumpkin came down on its creature (`aim`, inside the area), so it reads as a hit even
## though the creature walked on while the pumpkin flew. A jam splash leaves a sticky puddle that
## fades slowly, as its jam slows what it touches.
func _draw_splash(f: Flash, k: float) -> void:
	var radius: float = f.size
	var jam: bool = f.hue == 1
	var main: Color = Palette.JAM if jam else Palette.PUMPKIN
	var light: Color = Palette.SPARKLE_LILAC if jam else Palette.HONEY
	var grow: float = 1.0 - pow(1.0 - minf(k / 0.13, 1.0), 3.0)
	var r: float = radius * (0.2 + 0.8 * grow)
	var fade: float = 1.0 - maxf((k - 0.5) / 0.5, 0.0)
	_disc(f.at, r, Color(main, 0.3 * fade))
	_disc(f.at, r * 0.6, Color(light, 0.2 * fade))
	_ring(f.at, r, Color(light, fade))
	# The splat where the pumpkin came down. It stays inside the area.
	var centre: Vector2 = f.aim
	var room: float = maxf(radius - f.at.distance_to(centre), 0.0)
	var splat: float = minf(radius * 0.34, room * 0.9) * (0.4 + 0.6 * grow)
	var puddle: float = 1.0 if jam else maxf(1.0 - k * 1.8, 0.0)
	if puddle > 0.0:
		var s: float = splat / (0.34 * CELL)
		_q(ShotPieces.Piece.SPLAT, centre, s, s, Color(main, puddle * fade))
	# Chunks fly out and fall.
	if k < 0.62:
		var kc: float = k / 0.62
		var n: int = 14 if f.hue == 2 else 10
		for j: int in n:
			var ang: float = TAU * float(j) / float(n) + 0.35 * float(j % 3)
			var reach: float = room * (0.5 + 0.4 * float(j % 3) / 2.0) * (1.0 - pow(1.0 - kc, 2.0))
			var up: float = sin(PI * kc) * CELL * (0.3 + 0.14 * float(j % 2))
			var pos: Vector2 = centre + Vector2.from_angle(ang) * reach + Vector2(0.0, -up)
			var cr: float = CELL * (0.055 + 0.025 * float(j % 2)) * (1.0 - 0.4 * kc)
			var col: Color = main if j % 2 == 0 else (light if jam else Palette.BONE)
			_bead(pos, cr, Color(col, 1.0 - kc * kc))
	# Sparkles.
	if k > 0.08 and k < 0.6:
		var tw: float = sin(PI * (k - 0.08) / 0.52)
		for j: int in 5:
			var v: Vector2 = Vector2.from_angle(TAU * float(j) / 5.0 + 0.9)
			var pos: Vector2 = centre + v * room * (0.5 + 0.1 * float(j)) + Vector2(0.0, -CELL * 0.2 * k)
			_star(pos, CELL * 0.1 * tw, false, PI / 4.0, Color(Palette.SPARKLE, tw))


## Spokes that reach the splash radius at the end, with a bead on each tip, and a faint disc of the
## true splash area, all around the spot the sim hit. The bright flash is where the rocket came down
## on its creature (`aim`). The Star Bloom has more spokes and a second ring.
func _draw_burst(f: Flash, k: float) -> void:
	var fade: float = 1.0 - k * k
	var reach: float = f.size * (0.5 + 0.5 * (1.0 - pow(1.0 - minf(k / 0.5, 1.0), 2.0)))
	var spokes: int = 12 if f.hue == 1 else 8
	_disc(f.at, reach, Color(Palette.SPARKLE, 0.16 * fade))
	if k < 0.4:
		_disc(f.aim, CELL * 0.22 * (1.0 - k / 0.4), Color(Palette.LANTERN_CORE, 1.0 - k / 0.4))
	for j: int in spokes:
		var d: Vector2 = Vector2.from_angle(TAU * float(j) / float(spokes) + 0.2)
		var col: Color = BURST_COLORS[j % BURST_COLORS.size()]
		var inner: float = reach * (0.3 + 0.4 * k)
		_bar(f.at + d * inner, f.at + d * reach, CELL * 0.055, Color(col, fade))
		_bead(f.at + d * reach, CELL * 0.042, Color(col, fade))
	_ring(f.at, reach, Color(Palette.SPARKLE, 0.8 * fade))
	if f.hue == 1:
		_ring(f.at, reach * 0.55, Color(Palette.HONEY, 0.6 * fade))


func _draw_plus(f: Flash, k: float) -> void:
	var p: Vector2 = f.at + Vector2(0.0, -CELL * (0.28 + 0.3 * k))
	var a: float = 1.0 if k < 0.5 else 1.0 - (k - 0.5) * 2.0
	var arm: float = CELL * 0.09 * (0.7 + 0.5 * minf(k * 4.0, 1.0))
	_bar(p + Vector2(-arm, 0.0), p + Vector2(arm, 0.0), CELL * 0.05, Color(Palette.HP_FILL, a))
	_bar(p + Vector2(0.0, -arm), p + Vector2(0.0, arm), CELL * 0.05, Color(Palette.HP_FILL, a))


## A small coin that rises, with a four point twinkle at the start. It is round with a mark in
## the middle, so it reads without its color.
func _draw_coin(f: Flash, k: float) -> void:
	var rise: float = 1.0 - (1.0 - k) * (1.0 - k)
	var p: Vector2 = f.at + Vector2(0.0, -CELL * (0.12 + 0.34 * rise * f.size))
	var a: float = 1.0 if k < 0.6 else 1.0 - (k - 0.6) / 0.4
	var r: float = CELL * 0.07 * f.size
	_bead(p, r, Color(Palette.COIN, a))
	_bead(p, r * 0.45, Color(Palette.ROOF_CLAY, a))
	if k < 0.45:
		var tw: float = sin(PI * k / 0.45)
		_star(p + Vector2(r * 0.9, -r * 0.9), r * (1.2 + 0.6 * tw), false, 0.0, Color(Palette.SPARKLE, a))


## Three speed lines behind the creature.
func _draw_whoosh(f: Flash, k: float) -> void:
	var a: float = 1.0 - k
	var s: float = f.size
	for j: int in 3:
		var y: float = (float(j) - 1.0) * 0.2 * s
		var start: Vector2 = f.at + Vector2(-f.dir * (0.4 + 0.2 * k) * s, y)
		var end: Vector2 = start + Vector2(-f.dir * s * (0.35 + 0.25 * float(1 - absi(j - 1))), 0.0)
		_bar(start, end, CELL * 0.04, Color(Palette.SPARKLE, a))


func _draw_pulse(f: Flash, k: float) -> void:
	var e: float = 1.0 - (1.0 - k) * (1.0 - k)
	_ring(f.at, f.size * (0.25 + 0.75 * e), Color(HUES[f.hue], 1.0 - k))


# Shots in flight.

func _draw_shot(s: Shot, p: Vector2, dir: Vector2, u: float) -> void:
	var white: Color = Color.WHITE
	var angle: float = dir.angle()
	if is_lobbed(s.look):
		_draw_landing_mark(s, u)
		# The shadow stays on the ground under the arc and shrinks as the shot climbs.
		var lift: float = 4.0 * u * (1.0 - u)
		var sr: float = (0.17 if s.look == Look.PRIZE else 0.12) * (1.0 - 0.3 * lift) / ShotPieces.DISC_R
		_q(ShotPieces.Piece.DISC, s.from.lerp(s.to, u), sr, sr * 0.45, Color(Palette.INK_LINE, 0.4))
	match s.look:
		Look.PEBBLE:
			_streak(p, angle + PI, CELL * 0.35, CELL * 0.05, Color(Palette.PLASTER, 0.7))
			var k: float = 0.09 / ShotPieces.PEBBLE_R
			_q(ShotPieces.Piece.PEBBLE, p, k, k, white)
		Look.STONE:
			_streak(p, angle + PI, CELL * 0.4, CELL * 0.09, Color(Palette.STONE, 0.7))
			var k: float = 0.115 / ShotPieces.STONE_R
			_q(ShotPieces.Piece.STONE, p, k, k, white)
		Look.PUMPKIN:
			_streak(p, angle + PI, CELL * 0.3, CELL * 0.08, Color(Palette.HONEY, 0.5))
			var k: float = 0.17 / ShotPieces.PUMPKIN_R
			_q(ShotPieces.Piece.PUMPKIN, p, k, k, white, u * TAU * 1.5)
		Look.PRIZE:
			_streak(p, angle + PI, CELL * 0.3, CELL * 0.12, Color(Palette.HONEY, 0.55))
			var k: float = 0.26 / ShotPieces.PUMPKIN_R
			_q(ShotPieces.Piece.PUMPKIN, p, k, k, white, u * TAU * 1.5)
		Look.JAM:
			_streak(p, angle + PI, CELL * 0.3, CELL * 0.08, Color(Palette.SPARKLE_LILAC, 0.5))
			var k: float = 0.15 / ShotPieces.JAR_R
			_q(ShotPieces.Piece.JAR, p, k, k, white, u * TAU * 1.5)
			# Jam drops fly behind it.
			var side: Vector2 = Vector2(-dir.y, dir.x)
			for i: int in 3:
				var back: Vector2 = p - dir * CELL * 0.15 * (1.8 + 1.0 * float(i)) + side * sin(u * 30.0 + float(i) * 2.0) * CELL * 0.075
				_bead(back, CELL * 0.15 * (0.4 - 0.08 * float(i)), Palette.JAM)
		Look.ARROW:
			_draw_arrow(p, dir, 1.0)
		Look.GIANT_ARROW:
			_draw_arrow(p, dir, 2.0)
		Look.THORNS:
			_draw_thorns(s, u)
		Look.SNOWBALL, Look.BIG_SNOWBALL:
			_draw_snowball(s, p, dir, u)
		Look.BEAM:
			_draw_beam(s, p, dir, u)
		Look.SKYROCKET:
			_draw_rocket(p, dir, u, 1.9, false)
		Look.BLOOM:
			_draw_rocket(p, dir, u, 1.4, true)
		_:
			_draw_rocket(p, dir, u, 1.2, false)


## The Bramble Cottage's pulse: a ring of thorns opens out from the cottage to its true reach. The
## thorns point inward, so the ring's outer edge is exactly where the sim stops.
func _draw_thorns(s: Shot, u: float) -> void:
	var e: float = 1.0 - (1.0 - u) * (1.0 - u)
	var r: float = s.radius * (0.2 + 0.8 * e)
	var fade: float = 1.0 - maxf(u - 0.6, 0.0) / 0.4
	var color: Color = Palette.HOLLY.lightened(0.3)
	_disc(s.from, r, Color(Palette.HOLLY, 0.2 * fade))
	_ring(s.from, r / RING_INK, Color(color, fade))
	var n: int = 14
	var len_k: float = minf(0.55, r * 0.5 / (ShotPieces.THORN_LENGTH * CELL))
	for j: int in n:
		var a: float = TAU * float(j) / float(n) + 0.5 * u
		_q(ShotPieces.Piece.THORN, s.from + Vector2.from_angle(a) * r / RING_INK, len_k, len_k, Color(color, fade), a + PI)


## The Snow Fort's line: a faint band as wide as the line the sim used, and one snowball rolling along
## it from the fort to the end, with a spray of snow behind it.
func _draw_snowball(s: Shot, p: Vector2, dir: Vector2, u: float) -> void:
	var angle: float = dir.angle()
	var length: float = s.from.distance_to(s.to)
	var half: float = s.radius
	var band_alpha: float = 0.2 * (1.0 - 0.5 * u)
	var width_k: float = half / (ShotPieces.DISC_R * CELL)
	_q(ShotPieces.Piece.DISC, s.from.lerp(s.to, 0.5), length / (2.0 * ShotPieces.DISC_R * CELL), width_k, Color(Palette.SNOW_WARM, band_alpha), angle)
	var ball: float = half * SNOW_FIT
	var k: float = ball / (ShotPieces.SNOW_R * CELL)
	_streak(p, angle + PI, CELL * 0.6, ball * 1.5, Color(Palette.SNOW_WARM, 0.45))
	for j: int in 3:
		var back: Vector2 = p - dir * (ball * (1.2 + 0.9 * float(j))) + Vector2(-dir.y, dir.x) * sin(u * 24.0 + float(j) * 2.0) * ball * 0.5
		_disc(back, ball * (0.4 - 0.08 * float(j)), Color(Palette.SNOW_WARM, 0.7 - 0.15 * float(j)))
	var fade: float = 1.0 - maxf(u - 0.85, 0.0) / 0.15
	_q(ShotPieces.Piece.SNOWBALL, p, k, k, Color(1, 1, 1, fade), (u * length) / maxf(ball, 1.0))


## The Moth Lantern's light: a soft beam from the lantern to the flyer, with a bright head.
func _draw_beam(s: Shot, p: Vector2, dir: Vector2, u: float) -> void:
	var angle: float = dir.angle()
	var length: float = s.from.distance_to(p)
	_streak(p, angle + PI, length, CELL * 0.16, Color(Palette.GLOW, 0.5))
	_streak(p, angle + PI, length, CELL * 0.055, Color(Palette.LANTERN_CORE, 0.95))
	_disc(p, CELL * 0.11, Color(Palette.GLOW, 0.8))
	_star(p, CELL * 0.1, false, u * TAU, Color(Palette.LANTERN_CORE, 1.0))


## The splash area of a lobbed shot, on the ground where it will land (the spot the sim hit): a dashed ring of the true
## splash radius that closes in a little and turns as the shot comes down.
func _draw_landing_mark(s: Shot, u: float) -> void:
	if s.radius <= 0.0:
		return
	var r: float = s.radius * (1.1 - 0.1 * u)
	var at: Vector2 = landing_mark_center(s)
	_disc(at, r, Color(Palette.SPARKLE, 0.1))
	_dashes(at, r, u * 1.5, Color(1, 1, 1, 0.95))


## Where the ground mark of a lobbed shot is centered: on the spot the sim hit, where the splash will
## be. It never slides with the picture of the shot (`s.to`), which follows the creature.
static func landing_mark_center(s: Shot) -> Vector2:
	return s.spot


## An arrow whose head is at `p`. The Giant Bow's is twice as long and thick. Speed streaks run
## behind it.
func _draw_arrow(p: Vector2, dir: Vector2, k: float) -> void:
	var angle: float = dir.angle()
	var tail: Vector2 = p - dir * CELL * 0.46 * k
	var side: Vector2 = Vector2(-dir.y, dir.x)
	for j: int in 2:
		var o: Vector2 = side * (float(j) * 2.0 - 1.0) * CELL * 0.055 * k
		_streak(tail + o, angle + PI, CELL * 0.3 * k, CELL * 0.03 * k, Color(Palette.SPARKLE, 0.6))
	_q(ShotPieces.Piece.ARROW, p, k, k, Color.WHITE, angle)


## A rocket whose head is at `p`, `big` times the normal size, with a flame and three puffs of
## smoke behind it.
func _draw_rocket(p: Vector2, dir: Vector2, u: float, big: float, honey: bool) -> void:
	var angle: float = dir.angle()
	for j: int in 3:
		var back: Vector2 = p - dir * CELL * (0.34 + 0.15 * float(j)) * big
		_puff(back, CELL * (0.05 + 0.02 * float(j)) * big, 0.8 - 0.22 * float(j))
	var tail: Vector2 = p - dir * CELL * 0.18 * big
	var flick: float = 0.8 + 0.2 * sin(u * 60.0)
	_q(ShotPieces.Piece.FLAME, tail, big * flick, big, Color.WHITE, angle)
	_q(ShotPieces.Piece.ROCKET_HONEY if honey else ShotPieces.Piece.ROCKET, p, big, big, Color.WHITE, angle)
