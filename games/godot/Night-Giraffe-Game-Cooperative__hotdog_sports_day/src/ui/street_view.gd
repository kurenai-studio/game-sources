class_name StreetView
extends Node2D
## The street course for skateboarding, at sunset: the city against an orange
## sky, warm brick buildings with lit windows, a chain-link fence and a
## painted wall, and the concrete with its cones, rails and ramps. The skater's
## board is drawn here too (the hot dog stands on it).

const PX := 22.0
const RIDER_X := 140.0           ## where the skater stays on screen

var cam := 0.0                   ## metres at the screen's left edge
var beat := 0.0
var time := 0.0
var course: Array = []
var speed := Skate.SPEED
var board := {}                  ## {x (screen), y (screen), flip 0..1, spin 0..1, tilt}
var _city: Texture2D
var _sky: Texture2D


func _ready() -> void:
	_city = load("res://assets/art/stadium/city.png")
	_sky = load("res://assets/art/stadium/sky_dusk.png")


func size() -> Vector2:
	return get_viewport_rect().size


func floor_y() -> float:
	return size().y - 58.0


func screen_x(m: float) -> float:
	return (m - cam) * PX


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var s := size()
	var fy := floor_y()
	if _sky:
		draw_texture_rect(_sky, Rect2(0, -40, s.x, fy - 40), false)
	draw_circle(Vector2(s.x * 0.7, fy - 120), 26, Color("f8b07a"))
	draw_circle(Vector2(s.x * 0.7, fy - 120), 20, Color("ffd060"))
	var camp := cam * PX
	if _city:
		var w := float(_city.get_width())
		var x := -fposmod(camp * 0.1, w)
		while x < s.x:
			draw_texture(_city, Vector2(roundf(x), roundf(fy - 120)), Color(0.75, 0.45, 0.6))
			x += w
	# warm brick buildings, nearer
	var bw := 70.0
	var first := int(floor(camp * 0.35 / bw)) - 1
	for k in range(first, first + int(s.x / bw) + 3):
		var bx := k * bw - camp * 0.35
		var h := 60.0 + float((k * 37) % 5) * 12.0
		var col := Color("7a3a3e") if k % 2 == 0 else Color("6a2e3a")
		draw_rect(Rect2(roundf(bx), fy - 30 - h, bw - 4, h + 30), col)
		draw_rect(Rect2(roundf(bx), fy - 30 - h, bw - 4, 3), col.lightened(0.2))
		for wy in range(int(fy - 24 - h), int(fy - 36), 14):
			for wx in range(int(bx) + 6, int(bx + bw - 12), 14):
				var lit := (wx * 3 + wy * 7 + k) % 5 < 2
				draw_rect(Rect2(wx, wy, 7, 8), Color("ffd060") if lit else Color("3a1e2a"))
	# the fence
	var fence_top := fy - 40.0
	var off := fposmod(camp * 0.7, 8.0)
	for fx in range(-8, int(s.x) + 8, 8):
		var x2 := fx - off
		draw_line(Vector2(x2, fence_top), Vector2(x2 + 8, fence_top + 30), Color(0.55, 0.55, 0.65, 0.5))
		draw_line(Vector2(x2 + 8, fence_top), Vector2(x2, fence_top + 30), Color(0.55, 0.55, 0.65, 0.5))
	draw_rect(Rect2(0, fence_top - 1, s.x, 2), Color("7a7690"))
	for px in range(0, int(s.x) + 60, 60):
		draw_rect(Rect2(px - fposmod(camp * 0.7, 60.0), fence_top - 2, 2, 32), Color("4e4a62"))
	# the concrete, with its joints, and the kerb
	draw_rect(Rect2(0, fy, s.x, s.y - fy), Color("a8a6ba"))
	draw_rect(Rect2(0, fy, s.x, 2), Color("d4d4e0"))
	var j := fposmod(camp, 44.0)
	for jx in range(0, int(s.x) + 44, 44):
		draw_rect(Rect2(jx - j, fy + 2, 1, 22), Color("7a7690"))
	draw_rect(Rect2(0, fy + 24, s.x, 3), Color("d4d4e0"))
	draw_rect(Rect2(0, fy + 27, s.x, s.y - fy - 27), Color("3a3a52"))
	for k2 in range(0, int(s.x) + 40, 40):
		draw_rect(Rect2(k2 - fposmod(camp, 40.0), fy + 42, 20, 2), Color("e0e0ee"))
	# the obstacles
	for f in course:
		_draw_feature(f, fy)
	# the board
	if not board.is_empty():
		_draw_board(board)


func _draw_feature(f: Dictionary, fy: float) -> void:
	var x := screen_x(float(f.at) * speed)
	if x < -200 or x > size().x + 60:
		return
	match String(f.kind):
		"cone":
			var c := Vector2(roundf(x), fy + 8)
			var pts := PackedVector2Array([c + Vector2(-5, 0), c + Vector2(5, 0), c + Vector2(1, -15), c + Vector2(-1, -15)])
			draw_colored_polygon(pts, Color("f0701e"))
			draw_rect(Rect2(c + Vector2(-3, -9), Vector2(6, 3)), Color("fffaf0"))
			draw_rect(Rect2(c + Vector2(-7, 0), Vector2(14, 2)), Color("7a2a0e"))
		"rail":
			var x1 := screen_x((float(f.at) + float(f.len)) * speed)
			var ry := fy - 0.75 * PX + 8
			draw_rect(Rect2(roundf(x), roundf(ry) - 1, roundf(x1 - x), 3), Color("e0e0ee"))
			draw_rect(Rect2(roundf(x), roundf(ry) + 1, roundf(x1 - x), 1), Color("6a6a86"))
			for px in [x + 2, (x + x1) / 2.0, x1 - 4]:
				draw_rect(Rect2(roundf(px), roundf(ry) + 2, 2, fy + 8 - ry - 2), Color("3a3a52"))
		"ramp":
			# a kicker, its lip at the beat's spot
			var back := x - 2.2 * PX
			var pts2 := PackedVector2Array([Vector2(back, fy + 8), Vector2(x, fy + 8), Vector2(x, fy - 12)])
			draw_colored_polygon(pts2, Color("c88a52"))
			draw_line(Vector2(back, fy + 8), Vector2(x, fy - 12), Color("e8b878"), 2.0)
			draw_rect(Rect2(roundf(x) - 1, fy - 12, 2, 20), Color("6a3a2a"))


func _draw_board(bd: Dictionary) -> void:
	var c := Vector2(float(bd.x), float(bd.y)).round()
	var flip := float(bd.get("flip", 0.0))
	var spin := float(bd.get("spin", 0.0))
	var sx := cos(spin * TAU)
	var sy := cos(flip * TAU)
	var w := 26.0 * maxf(absf(sx), 0.2)
	var th := 3.0 * maxf(absf(sy), 0.34)
	var deck := Color("24152e") if sy >= 0.0 else Color("e0383a")
	draw_rect(Rect2(c.x - w / 2, c.y - th, w, th), deck)
	draw_rect(Rect2(c.x - w / 2, c.y - th, w, 1), Color("4e4a62") if sy >= 0.0 else Color("ff7a6a"))
	if absf(sy) > 0.5:
		for k in [-1.0, 1.0]:
			draw_rect(Rect2(c.x + k * w * 0.32 - 2, c.y, 4, 3), Color("fffaf0"))
			draw_rect(Rect2(c.x + k * w * 0.32 - 1, c.y + 2, 2, 1), Color("a8a6ba"))
