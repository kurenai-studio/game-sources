class_name StageView
extends Node2D
## The breaking stage, at night: a brick wall with a big painted tag, a DJ
## booth (its decks spinning) between stacks of speakers, coloured spotlights
## sweeping on the beat, a square dance floor, and a dark front row of fans
## bouncing along.

var beat := 0.0
var time := 0.0
var excite := 0.5
var _fans: Texture2D
var _fan_meta: Dictionary = {}

const BRICK := [Color("3a1e2a"), Color("5a2a34"), Color("7a3a3e")]


func _ready() -> void:
	_fans = load("res://assets/art/crowd/fans.png")
	var g := FileAccess.open("res://assets/art/crowd/fans.json", FileAccess.READ)
	_fan_meta = JSON.parse_string(g.get_as_text()) if g else {}


func size() -> Vector2:
	return get_viewport_rect().size


func floor_y() -> float:
	return size().y - 58.0


func spot(i: int) -> float:
	## where dancer i stands: 0 the MC (left), 1 the dancer (right)
	return roundf(size().x * (0.3 if i == 0 else 0.62))


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var s := size()
	var fy := floor_y()
	# the night, and the brick wall
	draw_rect(Rect2(0, 0, s.x, s.y), Color("140a1e"))
	var top := fy - 150.0
	for row in int(150 / 6.0) + 1:
		var y := top + row * 6
		var off := 0 if row % 2 == 0 else 8
		for x in range(-16 + off, int(s.x) + 16, 16):
			draw_rect(Rect2(x, y, 15, 5), BRICK[(row * 7 + x / 16) % 2 + 1])
		draw_rect(Rect2(0, y + 5, s.x, 1), BRICK[0])
	# the tag on the wall
	var f := Kit.font("big")
	var tag := "HOT DOG!"
	var tw := f.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x * 2
	logo_tag(Vector2(roundf(s.x / 2 - tw / 2), top + 18), tag)
	# the DJ booth and the speakers
	var bx := roundf(s.x / 2 - 40)
	draw_rect(Rect2(bx, fy - 34, 80, 34), Color("24152e"))
	draw_rect(Rect2(bx, fy - 34, 80, 3), Color("4e4a62"))
	for k in 2:
		var c := Vector2(bx + 20 + k * 40, fy - 36)
		draw_rect(Rect2(c - Vector2(12, 3), Vector2(24, 5)), Color("1a1424"))
		var a := time * 6.0 + k
		draw_rect(Rect2((c + Vector2(cos(a) * 8, 0)).round() - Vector2(1, 1), Vector2(2, 2)), Color("ff9ad8"))
	for sx in [16.0, s.x - 52.0]:
		draw_rect(Rect2(sx, fy - 78, 36, 78), Color("1a1424"))
		for k in 2:
			var pump := 1.0 + (1.0 if fposmod(beat, 1.0) < 0.15 else 0.0)
			var c2 := Vector2(sx + 18, fy - 58 + k * 34)
			draw_circle(c2, 12.0 + pump, Color("3a3a52"))
			draw_circle(c2, 6.0, Color("24152e"))
	# spotlights, sweeping to the beat
	var cols := [Color(1.0, 0.35, 0.8, 0.13), Color(0.3, 0.9, 1.0, 0.13), Color(1.0, 0.85, 0.3, 0.12)]
	for k in 3:
		var sw := sin(beat * PI * 0.5 + k * 2.1) * 90.0
		var x0 := s.x * (0.2 + 0.3 * k)
		var pts := PackedVector2Array([Vector2(x0, -4), Vector2(x0 + sw - 30, fy), Vector2(x0 + sw + 30, fy)])
		draw_colored_polygon(pts, cols[k])
	# the dance floor: squares, lit in turn on the beat
	draw_rect(Rect2(0, fy, s.x, s.y - fy), Color("2a1e3e"))
	var lit := int(floor(beat)) % 4
	for row in 3:
		for k in int(s.x / 24.0) + 1:
			var x := k * 24.0 - row * 8.0
			var on := (k + row) % 4 == lit
			draw_rect(Rect2(x, fy + row * 9, 23, 8), Color("5a2e6a") if on else Color("3a2a4a"))
	draw_rect(Rect2(0, fy, s.x, 1), Color("7a3ad2"))
	# the front row, dark against the floor
	_front_row(Vector2(0, s.y - 8))


func logo_tag(at: Vector2, text: String) -> void:
	var f := Kit.font("big")
	draw_set_transform(at, 0.0, Vector2(2, 2))
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(2, 2)]:
		draw_string(f, Vector2(0, 14) + o * 0.5, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("140a1e"))
	draw_string(f, Vector2(0, 14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f04aa8"))
	draw_string(f, Vector2(0, 13), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.94, 0.48, 0.0))
	draw_set_transform(Vector2.ZERO)


func _front_row(at: Vector2) -> void:
	if _fans == null:
		return
	var cell: Array = _fan_meta.get("cell", [14, 22])
	var cols := int(_fan_meta.get("cols", 16))
	var bf := fposmod(beat, 1.0)
	for i in int(size().x / 11.0) + 1:
		var h := (i * 7 + 3) % 24
		var hop := (2.0 + excite * 3.0) * maxf(0.0, sin((bf + (i % 2) * 0.5) * TAU)) if i % 3 != 0 else 0.0
		var src := Rect2(((h * 4) % cols) * float(cell[0]), ((h * 4) / cols) * float(cell[1]), float(cell[0]), float(cell[1]))
		var p := Vector2(i * 11 - 4, at.y - float(cell[1]) + 6 - hop)
		draw_texture_rect_region(_fans, Rect2(p.round(), Vector2(float(cell[0]), float(cell[1]))), src, Color(0.32, 0.26, 0.42))
