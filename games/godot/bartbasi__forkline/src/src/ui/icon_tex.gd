# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name IconTex
extends RefCounted
## Small white icons for buttons, drawn in code (no image files). A button tints
## them with its icon colors. Kinds: cup, gear, back, lock, check, arrow, close,
## pause, play, speaker (sound), speaker_off (the same speaker crossed out).
##
## Each kind is a distance function on the unit square (negative inside). A pixel's
## coverage is read from its distance, one sample per pixel. Blocks that are clearly
## outside or inside are skipped or filled in one call, so an icon costs a few
## milliseconds, not tens. `prewarm` builds every icon the app uses when it starts, so
## none is built in the middle of a wave.

const BLOCK: int = 8
const SUB: int = 4
## Slack, in pixels, when deciding that a whole block is outside or inside. A few of
## the distances below are close estimates, not exact, so a block is only skipped or
## filled when it is clearly clear of the edge.
const SLACK: float = 1.0

## Every kind and size the screens and panels ask for. `prewarm` builds them all when the
## app starts. A test checks that no `IconTex.make` call in src/ui/ asks for one that is not here.
const USED_ICONS: Array[Array] = [
	[&"cup", 56], [&"gear", 72], [&"back", 72], [&"lock", 56], [&"lock", 64], [&"lock", 72],
	[&"check", 56], [&"check", 64], [&"arrow", 64], [&"close", 64], [&"close", 72],
	[&"pause", 72], [&"play", 72], [&"speaker", 72], [&"speaker_off", 72],
]

static var _cache: Dictionary[String, ImageTexture] = {}


## Builds every icon the screens use, at a calm moment, so none is built mid wave.
static func prewarm() -> void:
	for pair: Array in USED_ICONS:
		make(pair[0] as StringName, int(pair[1]))


## Has this icon been built already?
static func is_built(kind: StringName, px: int) -> bool:
	return _cache.has("%s:%d" % [kind, px])


## The icon `kind` as a square texture of `px` pixels. Cached.
static func make(kind: StringName, px: int) -> ImageTexture:
	var key: String = "%s:%d" % [kind, px]
	if _cache.has(key):
		return _cache[key]
	var sdf: Callable = _distance_of(kind)
	var image: Image = Image.create_empty(px, px, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	if sdf.is_valid():
		var scale: float = float(px)
		var by: int = 0
		while by < px:
			var bx: int = 0
			while bx < px:
				_block(image, sdf, scale, bx, by, mini(BLOCK, px - bx), mini(BLOCK, px - by), true)
				bx += BLOCK
			by += BLOCK
	var tex: ImageTexture = ImageTexture.create_from_image(image)
	_cache[key] = tex
	return tex


## Draws one block of the image: skipped when clearly outside, filled when clearly
## inside, split once into smaller blocks, else sampled pixel by pixel.
static func _block(image: Image, sdf: Callable, scale: float, x0: int, y0: int, w: int, h: int, split: bool) -> void:
	var cx: float = float(x0) + float(w) * 0.5
	var cy: float = float(y0) + float(h) * 0.5
	var d: float = float(sdf.call(cx / scale, cy / scale)) * scale
	var reach: float = 0.5 * sqrt(float(w * w + h * h)) + SLACK
	if d > reach:
		return
	if d < -reach:
		image.fill_rect(Rect2i(x0, y0, w, h), Color.WHITE)
		return
	if split and (w > SUB or h > SUB):
		var hw: int = (w + 1) / 2
		var hh: int = (h + 1) / 2
		for qy: int in 2:
			for qx: int in 2:
				var sw: int = hw if qx == 0 else w - hw
				var sh: int = hh if qy == 0 else h - hh
				if sw > 0 and sh > 0:
					_block(image, sdf, scale, x0 + qx * hw, y0 + qy * hh, sw, sh, false)
		return
	for y: int in range(y0, y0 + h):
		var v: float = (float(y) + 0.5) / scale
		for x: int in range(x0, x0 + w):
			var u: float = (float(x) + 0.5) / scale
			var coverage: float = clampf(0.5 - float(sdf.call(u, v)) * scale, 0.0, 1.0)
			if coverage > 0.0:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, coverage))


static func _distance_of(kind: StringName) -> Callable:
	match kind:
		&"cup":
			return Callable(IconTex, &"_cup")
		&"gear":
			return Callable(IconTex, &"_gear")
		&"back":
			return Callable(IconTex, &"_back")
		&"lock":
			return Callable(IconTex, &"_lock")
		&"check":
			return Callable(IconTex, &"_check")
		&"arrow":
			return Callable(IconTex, &"_arrow")
		&"close":
			return Callable(IconTex, &"_close")
		&"pause":
			return Callable(IconTex, &"_pause")
		&"play":
			return Callable(IconTex, &"_play")
		&"speaker":
			return Callable(IconTex, &"_speaker")
		&"speaker_off":
			return Callable(IconTex, &"_speaker_off")
	return Callable()


## The cup: a tapering body with a round bottom, a handle, a saucer and steam.
static func _cup(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var half: float = 0.27 - 0.07 * (v - 0.34) / 0.46
	var body: float = maxf(maxf(absf(u - 0.40) - half, 0.34 - v), v - 0.68) * 0.9887
	var radii: Vector2 = Vector2(0.2183, 0.12)
	var q: Vector2 = Vector2(u - 0.40, v - 0.68)
	var k0: float = (q / radii).length()
	var k1: float = (q / (radii * radii)).length()
	var round_bottom: float = 1.0e3
	if k1 > 0.000001:
		round_bottom = k0 * (k0 - 1.0) / k1
	var d: float = minf(body, round_bottom)
	var handle: float = maxf(absf(p.distance_to(Vector2(0.70, 0.50)) - 0.1275) - 0.0425, 0.62 - u)
	d = minf(d, handle)
	d = minf(d, _box(p, Vector2(0.40, 0.88), Vector2(0.34, 0.04)))
	d = minf(d, _box(p, Vector2(0.30, 0.17), Vector2(0.025, 0.09)))
	return minf(d, _box(p, Vector2(0.50, 0.17), Vector2(0.025, 0.09)))


## The gear: a ring with eight teeth around a hole.
static func _gear(u: float, v: float) -> float:
	var d: Vector2 = Vector2(u - 0.5, v - 0.5)
	var r: float = d.length()
	var ring: float = absf(r - 0.235) - 0.095
	var step: float = TAU / 8.0
	var a: float = fposmod(d.angle() + step * 0.5, step) - step * 0.5
	var side: float = r * sin(absf(a) - 0.20)
	var tooth: float = maxf(maxf(side, 0.28 - r), r - 0.47)
	return minf(ring, tooth)


static func _back(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var top: Vector2 = Vector2(0.64, 0.20)
	var mid: Vector2 = Vector2(0.34, 0.50)
	var bottom: Vector2 = Vector2(0.64, 0.80)
	return minf(_segment(p, top, mid, 0.075), _segment(p, mid, bottom, 0.075))


## The lock: a body with a keyhole, and a shackle.
static func _lock(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var body: float = _box(p, Vector2(0.5, 0.68), Vector2(0.3, 0.22))
	var shackle: float = maxf(absf(p.distance_to(Vector2(0.5, 0.40)) - 0.19) - 0.06, v - 0.50)
	var keyhole: float = p.distance_to(Vector2(0.5, 0.64)) - 0.07
	return maxf(minf(body, shackle), -keyhole)


static func _check(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var a: Vector2 = Vector2(0.20, 0.54)
	var b: Vector2 = Vector2(0.42, 0.76)
	var c: Vector2 = Vector2(0.82, 0.28)
	return minf(_segment(p, a, b, 0.075), _segment(p, b, c, 0.075))


## A right pointing arrow: a shaft and an open head.
static func _arrow(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var tip: Vector2 = Vector2(0.86, 0.5)
	var d: float = _segment(p, Vector2(0.10, 0.5), tip, 0.065)
	d = minf(d, _segment(p, Vector2(0.56, 0.22), tip, 0.065))
	return minf(d, _segment(p, Vector2(0.56, 0.78), tip, 0.065))


static func _close(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var one: float = _segment(p, Vector2(0.26, 0.26), Vector2(0.74, 0.74), 0.07)
	return minf(one, _segment(p, Vector2(0.74, 0.26), Vector2(0.26, 0.74), 0.07))


static func _pause(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	return minf(_box(p, Vector2(0.35, 0.50), Vector2(0.08, 0.28)), _box(p, Vector2(0.65, 0.50), Vector2(0.08, 0.28)))


## A triangle pointing right.
static func _play(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var up_side: Vector2 = Vector2(0.30, -0.50).normalized()
	var low_side: Vector2 = Vector2(0.30, 0.50).normalized()
	var d_up: float = (p - Vector2(0.30, 0.20)).dot(up_side)
	var d_low: float = (p - Vector2(0.30, 0.80)).dot(low_side)
	return maxf(maxf(0.30 - u, d_up), d_low)


## A speaker: a small box, a cone that opens to the right, and a curved sound wave.
static func _speaker(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var box: float = _box(p, Vector2(0.22, 0.50), Vector2(0.08, 0.12))
	var up_side: Vector2 = Vector2(-0.20, -0.22).normalized()
	var low_side: Vector2 = Vector2(-0.20, 0.22).normalized()
	var d_up: float = (p - Vector2(0.30, 0.40)).dot(up_side)
	var d_low: float = (p - Vector2(0.30, 0.60)).dot(low_side)
	var cone: float = maxf(maxf(0.30 - u, u - 0.52), maxf(d_up, d_low))
	var wave: float = maxf(absf(p.distance_to(Vector2(0.48, 0.50)) - 0.27) - 0.045, 0.62 - u)
	return minf(box, minf(cone, wave))


## The speaker with a slash across it. A clear gap on both sides of the slash keeps the two
## apart, so the slash reads even where it crosses the speaker. The shape differs from the
## plain speaker, so the state is never shown by color alone.
static func _speaker_off(u: float, v: float) -> float:
	var p: Vector2 = Vector2(u, v)
	var slash: float = _segment(p, Vector2(0.14, 0.14), Vector2(0.86, 0.86), 0.0)
	return minf(maxf(_speaker(u, v), 0.10 - slash), slash - 0.045)


## Distance to a box (negative inside).
static func _box(p: Vector2, center: Vector2, half: Vector2) -> float:
	var q: Vector2 = (p - center).abs() - half
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)


## Distance to a line segment with round ends, less the radius (negative inside).
static func _segment(p: Vector2, a: Vector2, b: Vector2, radius: float) -> float:
	var ab: Vector2 = b - a
	var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t) - radius
