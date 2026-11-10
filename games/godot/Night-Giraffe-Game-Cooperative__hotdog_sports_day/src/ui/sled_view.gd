class_name SledView
extends Node2D
## The bobsleigh run at night: pines under the stars, strings of warm lights
## along the track, and the ice channel itself, its walls rushing past. Each
## bend coming up is painted ahead on the ice as an arrow (up for a high bend,
## down for a low one) that slides in to meet the sled on its beat. The sled is
## a bun: its back is drawn here, its front lip by `front` above the rider.

const PX := 22.0
const SLED_X := 150.0

var d := 0.0                     ## metres down the track
var v := 0.0
var lean := 0.0                  ## -1 low .. +1 high
var beat := 0.0
var time := 0.0
var cues: Array = []             ## [{in (seconds), high, grade}]
var front: Node2D
var _trees: Array = []


func _ready() -> void:
	front = Node2D.new()
	front.z_index = 50
	front.draw.connect(_draw_front)
	add_child(front)
	var r := RandomNumberGenerator.new()
	r.seed = 3
	for i in 24:
		_trees.append(Vector3(r.randf() * 600.0, r.randf_range(16.0, 34.0), r.randf()))


func size() -> Vector2:
	return get_viewport_rect().size


func floor_y() -> float:
	return size().y - 70.0


## Where the sled sits: up the wall on a high bend, down in the dip on a low one.
func sled_pos() -> Vector2:
	return Vector2(SLED_X, floor_y() - lean * 14.0)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()
	front.queue_redraw()


func _draw() -> void:
	var s := size()
	var fy := floor_y()
	var bands := [Color("0e0a24"), Color("141a4a"), Color("1e2a6a")]
	for k in bands.size():
		draw_rect(Rect2(0, s.y * k / 3.0, s.x, s.y / 3.0 + 1), bands[k])
	for i in 36:
		var sx := fposmod(i * 83.7 - d * 0.5, s.x)
		var sy := fposmod(i * 41.3, s.y * 0.45)
		draw_rect(Rect2(roundf(sx), roundf(sy), 1, 1), Color(1, 1, 0.9, 0.5 + 0.5 * sin(time * 2.0 + i)))
	# an aurora, slowly moving, and the mountains under it
	for k in 3:
		var col: Color = [Color(0.3, 1.0, 0.6, 0.10), Color(0.4, 0.8, 1.0, 0.08), Color(0.8, 0.4, 1.0, 0.06)][k]
		var pts := PackedVector2Array()
		for i in 25:
			var x := i * s.x / 24.0
			pts.append(Vector2(x, 30.0 + k * 10.0 + 12.0 * sin(x * 0.02 + time * 0.3 + k)))
		for i in range(24, -1, -1):
			var x := i * s.x / 24.0
			pts.append(Vector2(x, 60.0 + k * 10.0 + 16.0 * sin(x * 0.017 + time * 0.25 + k * 2.0)))
		draw_colored_polygon(pts, col)
	var ridge := PackedVector2Array()
	for i in int(s.x / 8.0) + 2:
		var x := i * 8.0
		var wx := x + d * PX * 0.1
		ridge.append(Vector2(x, fy - 110.0 - 30.0 * sin(wx * 0.011) - 14.0 * sin(wx * 0.03 + 1.0)))
	ridge.append(Vector2(s.x + 8, fy))
	ridge.append(Vector2(0, fy))
	draw_colored_polygon(ridge, Color("24305a"))
	# snowy ground and pines behind the track
	draw_rect(Rect2(0, fy - 70, s.x, 80), Color("2a3a6a"))
	for tr in _trees:
		var px: float = fposmod(tr.x - d * PX * 0.4, s.x + 60.0) - 30.0
		var py: float = fy - 44 - tr.z * 16.0
		var h: float = tr.y
		draw_colored_polygon(PackedVector2Array([Vector2(px, py - h), Vector2(px - h * 0.35, py), Vector2(px + h * 0.35, py)]),
			Color("12202e"))
		draw_colored_polygon(PackedVector2Array([Vector2(px, py - h), Vector2(px - h * 0.12, py - h * 0.6), Vector2(px + h * 0.12, py - h * 0.6)]),
			Color("e6eefa"))
	# the string of lights along the back of the track
	var lights_y := fy - 46.0
	var lo := fposmod(d * PX * 0.9, 24.0)
	for k in range(-1, int(s.x / 24.0) + 2):
		var x := k * 24.0 - lo
		draw_line(Vector2(x, lights_y), Vector2(x + 24.0, lights_y), Color("3a3a52"), 1.0)
		var on := (k + int(beat)) % 2 == 0
		draw_rect(Rect2(roundf(x + 10), lights_y + 1, 3, 3), Color("ffd060") if on else Color("f08a40"))
	# the ice channel: the back wall, the floor, the lip
	var back_top := fy - 38.0
	draw_rect(Rect2(0, back_top, s.x, fy - back_top + 6), Color("94c6f0"))
	draw_rect(Rect2(0, back_top, s.x, 3), Color("fffaf0"))
	var mo := fposmod(d * PX, 36.0)
	for k in range(-1, int(s.x / 36.0) + 2):
		var x2 := k * 36.0 - mo
		draw_line(Vector2(x2, back_top + 6), Vector2(x2 + 18, fy), Color("6aa2e2"), 1.0)
	draw_rect(Rect2(0, fy + 6, s.x, 8), Color("e0f6ff"))
	# the bends coming, painted on the ice
	for c in cues:
		var x3 := SLED_X + float(c.in) * maxf(v, 12.0) * PX * 0.35
		if x3 > s.x + 20:
			continue
		var high: bool = c.high
		var col := Color("2a4ad2") if high else Color("e0383a")
		var g := String(c.grade)
		if g in ["perfect", "good", "ok"]:
			col = Color("38a03a")
		elif g in ["wrong", "miss"]:
			col = Color("7a7690")
		var cy := back_top + 14.0 if high else fy + 2.0
		var tip := Vector2(x3, cy - 7) if high else Vector2(x3, cy + 7)
		var pts := PackedVector2Array([tip, Vector2(x3 - 6, cy), Vector2(x3 + 6, cy)])
		draw_colored_polygon(pts, col)
		draw_rect(Rect2(x3 - 2, cy - (0 if high else 6), 4, 6), col)
	# the sled's back: the bun's far side and its crumb inside
	var p := sled_pos()
	var tilt := lean * 0.12
	_bun(p, 30.0, 9.0, tilt, Color("b8692f"), Color("f6e6bc"), false)


func _draw_front() -> void:
	var p := sled_pos()
	var tilt := lean * 0.12
	_bun(p, 30.0, 9.0, tilt, Color("dc9547"), Color("f0c072"), true)
	# sparks on a scrape
	if absf(lean) < 0.05 and fposmod(time, 0.1) < 0.05 and v < 16.0:
		for k in 3:
			front.draw_rect(Rect2(p.x - 20 - k * 4, p.y + 4 - k, 2, 1), Color("ffd060"))


func _bun(p: Vector2, half: float, h: float, tilt: float, crust: Color, crumb: Color, is_front: bool) -> void:
	var ci: CanvasItem = front if is_front else self
	var pts := PackedVector2Array()
	var n := 24
	for k in n + 1:
		var a := PI * k / n
		var x := -cos(a) * half
		var y := sin(a) * h if is_front else -sin(a) * h * 0.6
		pts.append(p + Vector2(x, y + 2).rotated(tilt))
	if is_front:
		# the front lip: the lower half of the bun, crust with a crumb rim
		pts.append(p + Vector2(half, 2).rotated(tilt))
		ci.draw_colored_polygon(pts, crust)
		ci.draw_line(p + Vector2(-half, 2).rotated(tilt), p + Vector2(half, 2).rotated(tilt), crumb, 2.0)
		ci.draw_line(p + Vector2(-half + 4, 9).rotated(tilt), p + Vector2(half - 6, 9).rotated(tilt), crust.darkened(0.3), 1.0)
		# its runners
		ci.draw_line(p + Vector2(-half + 2, h + 3).rotated(tilt), p + Vector2(half + 4, h + 1).rotated(tilt), Color("a0a0b8"), 1.0)
	else:
		ci.draw_colored_polygon(pts, crust)
		ci.draw_rect(Rect2(p.x - half + 3, p.y - 2, half * 2 - 6, 5), crumb)
