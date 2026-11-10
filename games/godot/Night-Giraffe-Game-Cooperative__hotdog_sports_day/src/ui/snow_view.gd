class_name SnowView
extends Node2D
## The ski jump at night: stars and a moon over the mountains, pines, the
## in-run on its floodlit tower, the landing hill with its blue distance lines,
## the red K-line and the green hill-size line, the crowd at the bottom, and
## snow falling. The camera follows the jumper down and across.

const SCALE := 3.2               ## pixels per metre for the hill
const JUMPER := Vector2(0.36, 0.42)   ## where on screen the jumper is kept

var cam := Vector2.ZERO          ## world point at the screen's top-left (metres, y up)
var beat := 0.0
var time := 0.0
var skis := {}                   ## {x, y (screen), angle, v (0..1 the V)}
var _flakes: Array = []
var _fans: Texture2D
var _fan_meta: Dictionary = {}


func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for i in 70:
		_flakes.append(Vector3(r.randf(), r.randf(), r.randf_range(0.4, 1.0)))
	_fans = load("res://assets/art/crowd/fans.png")
	var g := FileAccess.open("res://assets/art/crowd/fans.json", FileAccess.READ)
	_fan_meta = JSON.parse_string(g.get_as_text()) if g else {}


func size() -> Vector2:
	return get_viewport_rect().size


func to_screen(wx: float, wy: float) -> Vector2:
	return Vector2((wx - cam.x) * SCALE, (cam.y - wy) * SCALE)


func follow(wx: float, wy: float, delta: float) -> void:
	var s := size()
	var want := Vector2(wx - s.x * JUMPER.x / SCALE, wy + s.y * JUMPER.y / SCALE)
	cam = cam.lerp(want, clampf(delta * 4.0, 0.0, 1.0)) if cam != Vector2.ZERO else want


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var s := size()
	# the night sky
	var bands := [Color("0e0a24"), Color("141a4a"), Color("1e2a6a"), Color("2a3a8a")]
	for k in bands.size():
		draw_rect(Rect2(0, s.y * k / bands.size(), s.x, s.y / bands.size() + 1), bands[k])
	for i in 40:
		var sx := fposmod(i * 97.3 - cam.x * 0.3, s.x)
		var sy := fposmod(i * 53.1, s.y * 0.6)
		var tw := 0.5 + 0.5 * sin(time * 2.0 + i)
		draw_rect(Rect2(roundf(sx), roundf(sy), 1, 1), Color(1, 1, 0.9, 0.4 + 0.6 * tw))
	draw_circle(Vector2(s.x * 0.8, 40), 14, Color("fffaf0"))
	draw_circle(Vector2(s.x * 0.8 + 5, 37), 12, bands[0].lerp(bands[1], 0.3))
	# mountains, far and near
	_ridge(0.15, Color("2a2a5a"), 120.0, 0.012, 60.0)
	_ridge(0.3, Color("3a3a6a"), 160.0, 0.02, 40.0)
	# pines along the near ridge
	for i in 30:
		var px := fposmod(i * 41.0 - cam.x * SCALE * 0.5, s.x + 40) - 20
		var py := s.y * 0.62 + sin(i * 1.7) * 10
		var h := 18.0 + (i % 3) * 6.0
		var pts := PackedVector2Array([Vector2(px, py - h), Vector2(px - 7, py), Vector2(px + 7, py)])
		draw_colored_polygon(pts, Color("1a2a3a"))
	# the in-run and its tower
	var top := to_screen(-50.0, SkiJump.inrun(-50.0))
	var edge := to_screen(0.0, 0.0)
	var foot := Vector2(top.x, s.y + 40)
	draw_colored_polygon(PackedVector2Array([top + Vector2(-4, 0), edge, edge + Vector2(0, 10), Vector2(edge.x - 6, s.y + 40), foot + Vector2(-10, 0)]), Color("2e2a3e"))
	for k in 8:
		var a := top.lerp(edge, k / 8.0)
		draw_line(a, Vector2(a.x, s.y + 40), Color("4e4a62"), 1.0)
	draw_line(top, edge, Color("e0e0ee"), 3.0)
	draw_line(top + Vector2(0, -1), edge + Vector2(0, -1), Color("fffaf0"), 1.0)
	draw_rect(Rect2(edge.x - 2, edge.y - 1, 4, 4), Color("e0383a"))
	# floodlights on the tower
	for k in 3:
		var l := top.lerp(edge, 0.2 + 0.3 * k) + Vector2(0, -14)
		draw_rect(Rect2(l.x - 3, l.y - 2, 6, 3), Color("fff4c0"))
	# the landing hill
	var pts2 := PackedVector2Array()
	var step := 3.0
	var x := 0.0
	while x <= 210.0:
		pts2.append(to_screen(x, SkiJump.hill(x)))
		x += step
	pts2.append(to_screen(210.0, -400.0))
	pts2.append(to_screen(0.0, -400.0))
	draw_colored_polygon(pts2, Color("e6eefa"))
	var x2 := 0.0
	while x2 < 210.0:
		var a2 := to_screen(x2, SkiJump.hill(x2))
		var b2 := to_screen(x2 + step, SkiJump.hill(x2 + step))
		draw_line(a2, b2, Color("fffaf0"), 2.0)
		x2 += step
	# distance lines
	var f := Kit.font("small")
	for m in range(30, 150, 10):
		var p := to_screen(float(m), SkiJump.hill(float(m)))
		var col := Color("4aa2e8")
		if m == int(SkiJump.K):
			col = Color("e0383a")
		elif m == 130:
			col = Color("1e9a4a")
		draw_line(p + Vector2(-6, 3), p + Vector2(6, 9), col, 2.0)
		if m % 20 == 0 or m == int(SkiJump.K):
			draw_string(f, p + Vector2(4, 18), str(m), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col.darkened(0.2))
	# the crowd at the bottom
	_crowd()
	# the skis, under the jumper
	if not skis.is_empty():
		_draw_skis()
	# falling snow
	for fl in _flakes:
		var fx := fposmod(fl.x * s.x + sin(time + fl.y * 9.0) * 6.0 - cam.x * SCALE * 0.2, s.x)
		var fy := fposmod(fl.y * s.y + time * 18.0 * fl.z + cam.y * SCALE * 0.2, s.y)
		draw_rect(Rect2(roundf(fx), roundf(fy), 1, 1), Color(1, 1, 1, fl.z))


func _ridge(par: float, col: Color, height: float, freq: float, amp: float) -> void:
	var s := size()
	var pts := PackedVector2Array()
	var base := s.y * 0.55 + cam.y * SCALE * par * 0.1
	for k in int(s.x / 8.0) + 2:
		var x := k * 8.0
		var wx := x + cam.x * SCALE * par
		pts.append(Vector2(x, base - height * 0.5 - amp * sin(wx * freq) - amp * 0.5 * sin(wx * freq * 2.3 + 1.0)))
	pts.append(Vector2(s.x + 8, s.y + 10))
	pts.append(Vector2(0, s.y + 10))
	draw_colored_polygon(pts, col)


func _crowd() -> void:
	if _fans == null:
		return
	var cell: Array = _fan_meta.get("cell", [14, 22])
	var cols := int(_fan_meta.get("cols", 16))
	var bf := fposmod(beat, 1.0)
	for i in 26:
		var wx := 150.0 + i * 2.2
		var p := to_screen(wx, SkiJump.hill(wx))
		var h := (i * 7 + 5) % 24
		var hop := 2.0 * maxf(0.0, sin((bf + (i % 2) * 0.5) * TAU))
		var src := Rect2(((h * 4) % cols) * float(cell[0]), ((h * 4) / cols) * float(cell[1]), float(cell[0]), float(cell[1]))
		draw_texture_rect_region(_fans, Rect2((p + Vector2(-7, -20 - hop)).round(), Vector2(float(cell[0]), float(cell[1]))), src)


func _draw_skis() -> void:
	var c := Vector2(float(skis.x), float(skis.y))
	var a := deg_to_rad(float(skis.angle))
	var v := float(skis.get("v", 0.0))
	for side in [-1.0, 1.0]:
		var spread := deg_to_rad(side * 10.0 * v)
		var dir := Vector2(cos(a + spread), sin(a + spread))
		var p0 := c - dir * 12.0
		var p1 := c + dir * 16.0
		draw_line(p0 + Vector2(0, side * v), p1 + Vector2(0, side * v * 2.0), Color("e0383a") if side < 0 else Color("2a4ad2"), 2.0)
		draw_line(p1 + Vector2(0, side * v * 2.0), p1 + Vector2(0, side * v * 2.0) + Vector2(2, -2).rotated(a), Color("fffaf0"), 1.0)
