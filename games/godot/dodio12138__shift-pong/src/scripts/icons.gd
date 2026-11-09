extends RefCounted
## Pixel-art HUD icons generated at runtime (no image assets): spin badges and
## mouse buttons. Draw them with nearest filtering at 2x or 3x.

const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_INK := Color(0.040, 0.050, 0.100)
const C_BALL := Color(0.15, 0.19, 0.32)
const C_ORANGE := Color(0.980, 0.520, 0.150)
const C_SKY := Color(0.420, 0.820, 0.980)
const C_YELLOW := Color(0.980, 0.800, 0.250)
const C_VIOLET := Color(0.776, 0.478, 0.949)

const SPIN_COLORS := {"top": C_ORANGE, "back": C_SKY, "side_l": C_YELLOW, "side_r": C_VIOLET, "none": C_WHITE}

static var _cache := {}


## Spin badge on a ring. top / back: an arrow inside pointing up / down (up = the
## way the ball flies: drives on / checks up). side_l / side_r: arrowheads running
## one arrowhead on top of the ring pointing left / right (the way the ball turns
## and curls seen from above). none: empty ring with a dot.
static func spin(kind: String) -> ImageTexture:
	var key := "spin_" + kind
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(22, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col: Color = SPIN_COLORS[kind]
	var c := Vector2(11.0, 10.0)
	if kind == "side_l" or kind == "side_r":
		# one big head at the top of the ring, with a gap in the ring ahead of it
		var sense := -1.0 if kind == "side_l" else 1.0   # image y is down: +angle = clockwise
		for y in img.get_height():
			for x in img.get_width():
				var d := Vector2(x, y) - c
				if absf(d.length() - 8.25) > 1.0:
					continue
				var ang := d.angle()
				var gap := false
				var rel := wrapf((ang + PI * 0.5) * sense, -PI, PI)
				gap = rel > 0.0 and rel < 0.75
				if not gap:
					img.set_pixel(x, y, col)
		var base := c + Vector2(0.0, -8.25)
		var tangent := Vector2(sense, 0.0)
		var normal := Vector2(0.0, -1.0)
		_tri(img, base + tangent * 5.5, base + normal * 4.0 - tangent * 0.5, base - normal * 4.0 - tangent * 0.5, col)
	else:
		_ring(img, c, 8.6, col)
		_ring(img, c, 7.9, col)
		if ARROW_DIRS.has(kind):
			_arrow(img, c, ARROW_DIRS[kind], 6.0, col)
		else:
			_disc(img, c, 1.5, col)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


const ARROW_DIRS := {"top": Vector2(0, -1), "back": Vector2(0, 1)}


## Bounce ripple, laid flat on the table with the texture's up (-y) pointing the
## way the ball travels. `top_kind`: "top" = chevrons forward (the ball kicks on),
## "back" = chevrons backward (it checks up), "none". `side_kind`: "side_l" /
## "side_r" = arrowheads running round the ring anticlockwise / clockwise seen
## from above, "none".
static func ripple(top_kind: String, side_kind: String) -> ImageTexture:
	var key := "ripple_%s_%s" % [top_kind, side_kind]
	if _cache.has(key):
		return _cache[key]
	var n := 33
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(16.0, 16.0)
	var ring_col: Color = C_WHITE if side_kind == "none" else SPIN_COLORS[side_kind]
	_ring(img, c, 14.0, ring_col)
	_ring(img, c, 13.2, ring_col)
	if side_kind != "none":
		# three arrowheads chasing each other round the ring
		var sense := -1.0 if side_kind == "side_l" else 1.0   # image y is down: +angle = clockwise
		for k in 3:
			var a := k * TAU / 3.0
			var base := c + Vector2(cos(a), sin(a)) * 13.6
			var tangent := Vector2(-sin(a), cos(a)) * sense
			var normal := Vector2(cos(a), sin(a))
			_tri(img, base + tangent * 6.5, base + normal * 4.5 - tangent * 1.5, base - normal * 4.5 - tangent * 1.5, ring_col)
	if top_kind != "none":
		var col: Color = SPIN_COLORS[top_kind]
		var dir := -1.0 if top_kind == "top" else 1.0      # chevrons point along y = dir; -y is forward
		for tip_off in [6.0, -1.0]:
			var tip := c + Vector2(0.0, dir * tip_off)
			for i in range(0, 6):
				for t in 2:
					# two-pixel-thick arms trailing back from the tip
					_plot(img, tip + Vector2(i, -dir * (i + t)), col)
					_plot(img, tip + Vector2(-i, -dir * (i + t)), col)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Arrow through `c` along `dir`, reaching `r` from the centre at the tip.
static func _arrow(img: Image, c: Vector2, dir: Vector2, r: float, col: Color) -> void:
	var tip := c + dir * r
	var normal := Vector2(-dir.y, dir.x)
	for i in int(r * 2.0) - 2:
		var p := c - dir * r + dir * i
		_plot(img, p, col)
		_plot(img, p + normal * 0.9, col)
	var head := maxf(4.0, r * 0.5)
	_tri(img, tip + dir * 0.6, tip - dir * head + normal * head * 0.9, tip - dir * head - normal * head * 0.9, col)


static func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.point_is_inside_triangle(Vector2(x, y), a, b, c):
				img.set_pixel(x, y, col)


const C_RED := Color(0.900, 0.080, 0.120)


## ✓ (good answer) in yellow.
static func ok() -> ImageTexture:
	if _cache.has("ok"):
		return _cache["ok"]
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for t in 2:
		_line(img, Vector2(1, 6 + t), Vector2(4, 9 + t), C_YELLOW)
		_line(img, Vector2(4, 9 + t), Vector2(10, 2 + t), C_YELLOW)
	var tex := ImageTexture.create_from_image(img)
	_cache["ok"] = tex
	return tex


## ✗ (don't) in red.
static func no() -> ImageTexture:
	if _cache.has("no"):
		return _cache["no"]
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for t in 2:
		_line(img, Vector2(2 + t, 2), Vector2(9 + t, 9), C_RED)
		_line(img, Vector2(9 + t, 2), Vector2(2 + t, 9), C_RED)
	var tex := ImageTexture.create_from_image(img)
	_cache["no"] = tex
	return tex


## Hold, then release: a pressed key with a charge bar, an arrow, the key back up.
static func hold_release() -> ImageTexture:
	if _cache.has("hold"):
		return _cache["hold"]
	var img := Image.create(30, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(8, 15):
		for x in range(0, 11):
			img.set_pixel(x, y, C_YELLOW if y > 8 else C_WHITE)
	for x in range(1, 10):
		img.set_pixel(x, 6, C_ORANGE)                      # charge bar above the pressed key
	_line(img, Vector2(13, 10), Vector2(17, 10), C_DIM)
	_tri(img, Vector2(19.5, 10), Vector2(16.5, 7.5), Vector2(16.5, 12.5), C_DIM)
	for y in range(4, 11):
		for x in range(20, 30):
			img.set_pixel(x, y, C_WHITE)
	for y in range(11, 13):
		for x in range(20, 30):
			img.set_pixel(x, y, C_BALL)                    # key side: it has popped back up
	var tex := ImageTexture.create_from_image(img)
	_cache["hold"] = tex
	return tex


## Hold-strength bar: fill = how hard you hit (0..1), white notch = how much the
## spin needed. Yellow when close enough, red when too soft or too hard.
static func strength(given: float, need: float) -> ImageTexture:
	var key := "str_%d_%d" % [roundi(given * 20.0), roundi(need * 20.0)]
	if _cache.has(key):
		return _cache[key]
	var w := 34
	var img := Image.create(w, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var good := need > 0.0 and absf(1.0 - given / need) < 0.3
	var fill_x := int(clampf(given, 0.0, 1.0) * (w - 2))
	var mark_x := 1 + int(clampf(need, 0.0, 1.0) * (w - 3))
	for y in range(1, 9):
		for x in w:
			var edge := x == 0 or x == w - 1 or y == 1 or y == 8
			if edge:
				img.set_pixel(x, y, C_DIM)
			elif x <= fill_x:
				img.set_pixel(x, y, C_YELLOW if good else C_RED)
			else:
				img.set_pixel(x, y, C_BALL)
	for y in 10:
		img.set_pixel(mark_x, y, C_WHITE)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## "How to answer this ball" card for heavy balls: the Q W E / A S D keypad with
## the one key to press lit (row: 1 top / -1 bottom; col: +1 left, 0 middle,
## -1 right, matching the side-spin sign) and a strength bar with the notch to
## hold up to.
static func solution(row: int, col: int, need: float) -> ImageTexture:
	var key := "sol_%d_%d_%d" % [row, col, roundi(need * 20.0)]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(40, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(C_INK, 0.85))
	var lit_x := 1 - col          # col +1 (left) -> 0, 0 -> 1, -1 (right) -> 2
	var lit_y := 0 if row > 0 else 1
	for r in 2:
		for cx in 3:
			var x0 := 3 + cx * 12 + r * 2
			var y0 := 2 + r * 10
			var lit := cx == lit_x and r == lit_y
			for y in range(y0, y0 + 8):
				for x in range(x0, x0 + 10):
					var edge := x == x0 or x == x0 + 9 or y == y0 or y == y0 + 7
					img.set_pixel(x, y, (C_INK if lit else C_DIM) if edge else (C_YELLOW if lit else C_BALL))
	var bar_y := 23
	var fill := int(clampf(need, 0.0, 1.0) * 33.0)
	for x in range(3, 37):
		img.set_pixel(x, bar_y, C_DIM)
		img.set_pixel(x, bar_y + 4, C_DIM)
		for y in range(bar_y + 1, bar_y + 4):
			img.set_pixel(x, y, C_ORANGE if x - 3 <= fill else C_BALL)
	for y in range(bar_y - 2, bar_y + 7):
		img.set_pixel(3 + fill, y, C_WHITE)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Footwork / readiness bar: `full` = set feet (yellow), else drained (red).
static func ready_bar(full: bool) -> ImageTexture:
	var key := "bar_%s" % full
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(22, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 8:
		for x in 22:
			var edge := x == 0 or x == 21 or y == 0 or y == 7
			if edge:
				img.set_pixel(x, y, C_DIM)
			elif full or x < 5:
				img.set_pixel(x, y, C_YELLOW if full else C_RED)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Mouse seen from above; `button` is "left", "right", "none" or "move".
## `lit` uses the bright fill for the button (pressed / the one to press).
static func mouse(button: String, lit := true) -> ImageTexture:
	var key := "mouse_%s_%s" % [button, lit]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(14, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var fill := C_YELLOW if lit else C_DIM
	for y in range(1, 17):
		for x in range(2, 12):
			# rounded rectangle body
			var cx := clampf(x, 4.5, 9.5)
			var cy := clampf(y, 4.5, 12.5)
			var d := Vector2(x - cx, y - cy).length()
			if d > 3.2:
				continue
			var edge := d > 2.2 or x == 2 or x == 11 or y == 1 or y == 16
			var col := C_WHITE if edge else C_BALL
			if not edge and y < 7:
				if (button == "left" and x < 7) or (button == "right" and x > 7):
					col = fill
			if not edge and x == 7 and y < 7:
				col = C_WHITE
			if not edge and y == 7:
				col = C_WHITE
			img.set_pixel(x, y, col)
	if button == "move":
		for i in 2:
			img.set_pixel(0, 9 + i, fill)
			img.set_pixel(13, 9 + i, fill)
			img.set_pixel(6 + i, 0, fill)
			img.set_pixel(6 + i, 17, fill)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _disc(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if Vector2(x, y).distance_to(c) <= r:
				img.set_pixel(x, y, col)


static func _ring(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			if absf(Vector2(x, y).distance_to(c) - r) < 0.6:
				img.set_pixel(x, y, col)


static func _line(img: Image, a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b)) + 1
	for i in n + 1:
		_plot(img, a.lerp(b, float(i) / n), col)


static func _plot(img: Image, p: Vector2, col: Color) -> void:
	var q := Vector2i(roundi(p.x), roundi(p.y))
	if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
		img.set_pixelv(q, col)


## Arc from a0 to a1 (image space, y down, so increasing angle is clockwise) with
## an arrowhead at a1 when `head_at_end`, else at a0.
static func _arc_arrow(img: Image, c: Vector2, r: float, a0: float, a1: float, head_at_end: bool, col: Color) -> void:
	var steps := 40
	for i in steps + 1:
		var a := lerpf(a0, a1, float(i) / steps)
		_plot(img, c + Vector2(cos(a), sin(a)) * r, col)
		_plot(img, c + Vector2(cos(a), sin(a)) * (r - 0.8), col)
	var ta := a1 if head_at_end else a0
	var dir := 1.0 if head_at_end else -1.0
	var base := c + Vector2(cos(ta), sin(ta)) * r
	var tangent := Vector2(-sin(ta), cos(ta)) * dir
	var normal := Vector2(cos(ta), sin(ta))
	var tri := [base + tangent * 3.0, base + normal * 2.6 - tangent * 0.5, base - normal * 2.6 - tangent * 0.5]
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.point_is_inside_triangle(Vector2(x, y), tri[0], tri[1], tri[2]):
				img.set_pixel(x, y, col)
