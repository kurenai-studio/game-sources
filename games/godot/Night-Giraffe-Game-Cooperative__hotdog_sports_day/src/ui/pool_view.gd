class_name PoolView
extends Node2D
## The aquatics hall for the high dive: tall windows onto the sky, a tiled
## wall, a small stand of fans, the diving tower with its springboard 5 metres
## up, the pool, and the five judges at their table with their score cards.
##
## The camera rises with a high dive and comes back down for the splash.

const PX := 22.0                   ## pixels per metre, both ways
const BOARD_X := 150.0             ## where the board's end is on screen

var beat := 0.0
var cam_y := 0.0                   ## how far up the camera has risen (pixels)
var marks: Array = []              ## the judges' cards, once shown
var time := 0.0
var _splash := 0.0
var _splash_t := 10.0
var _board_bend := 0.0
var _fans: Texture2D
var _fan_meta: Dictionary = {}
var _judges: Array = []


func _ready() -> void:
	_fans = load("res://assets/art/crowd/fans.png")
	var g := FileAccess.open("res://assets/art/crowd/fans.json", FileAccess.READ)
	_fan_meta = JSON.parse_string(g.get_as_text()) if g else {}
	for i in 5:
		_judges.append((i * 5 + 3) % 24)


func size() -> Vector2:
	return get_viewport_rect().size


func water_y() -> float:
	return size().y - 46.0 + cam_y


func board_y() -> float:
	return water_y() - Dive.BOARD_H * PX


## Put the diver's view where the dive says it is.
func place(v: AthleteView, d: Dive) -> void:
	var b := d.b
	v.position = Vector2(BOARD_X - 4.0 + b.x * PX, board_y()).round()
	v.lift = b.y * PX
	v.squash = b.squash
	v.angle = b.angle
	v.twist = d.twist
	v.mood = b.mood
	v.lean = 0.0
	v.ground_shadow = 1.0 if d.state == "board" or d.state == "set" else 0.0
	v.visible = d.state != "water" or d.b.y > -Dive.BOARD_H + 0.1
	if d.state == "water":
		v.visible = false
	_board_bend = (1.0 - b.squash) * 6.0 if d.state == "board" else 0.0


func cam_follow(d: Dive, delta: float) -> void:
	var top := board_y() - d.b.y * PX - 70.0
	var want := cam_y
	if top < 20.0:
		want = cam_y + (20.0 - top)
	elif d.state == "water" or d.b.y < 0.0:
		want = 0.0
	want = maxf(0.0, want)
	cam_y = lerpf(cam_y, want, clampf(delta * 4.0, 0.0, 1.0))


func splash(size_: float) -> void:
	_splash = size_
	_splash_t = 0.0


func _process(delta: float) -> void:
	time += delta
	_splash_t += delta
	queue_redraw()


func _draw() -> void:
	var s := size()
	var wy := water_y()
	# the hall: a dark roof with lamps, a band of tall windows onto the sky,
	# then the tiled wall down to the water
	var win_top := wy - 205.0
	var win_bot := wy - 125.0
	draw_rect(Rect2(0, -400, s.x, win_top + 400), Color("2e2a3e"))
	for lx in range(30, int(s.x), 90):
		draw_rect(Rect2(lx, win_top - 14, 22, 4), Color("4e4a62"))
		draw_rect(Rect2(lx + 2, win_top - 10, 18, 2), Color("fff4c0"))
	draw_rect(Rect2(0, win_top, s.x, win_bot - win_top), Color("6aa2e2"))
	draw_rect(Rect2(0, win_top, s.x, 24), Color("4e7ece"))
	draw_rect(Rect2(0, win_bot - 22, s.x, 22), Color("94c6f0"))
	for k in 5:
		var cx := fposmod(k * 117.0 + time * 4.0, s.x + 80.0) - 40.0
		var cy := win_top + 18 + (k * 13) % 30
		draw_rect(Rect2(roundf(cx), cy, 34, 6), Color("e6eefa"))
		draw_rect(Rect2(roundf(cx) + 6, cy - 4, 18, 5), Color("fffaf0"))
		draw_rect(Rect2(roundf(cx) + 2, cy + 6, 30, 1), Color("b4c6ea"))
	for wx in range(0, int(s.x) + 32, 32):
		draw_rect(Rect2(wx, win_top, 3, win_bot - win_top), Color("2e2a3e"))
		draw_rect(Rect2(wx + 3, win_top, 1, win_bot - win_top), Color("4e4a62"))
	draw_rect(Rect2(0, win_top + 40, s.x, 2), Color("2e2a3e"))
	draw_rect(Rect2(0, win_top - 2, s.x, 3), Color("7a7690"))
	draw_rect(Rect2(0, win_bot, s.x, 3), Color("7a7690"))
	var wall_top := win_bot + 3
	draw_rect(Rect2(0, wall_top, s.x, wy - wall_top), Color("c8e8f2"))
	var ty := wall_top
	var row := 0
	while ty < wy:
		draw_rect(Rect2(0, ty, s.x, 1), Color("9ad0e2"))
		var off := 4 if row % 2 == 0 else 0
		for tx in range(off, int(s.x), 8):
			draw_rect(Rect2(tx, ty, 1, 8), Color("9ad0e2"))
		ty += 8
		row += 1
	draw_rect(Rect2(0, wall_top + 24, s.x, 8), Color("2a5a7a"))
	draw_rect(Rect2(0, wy - 18, s.x, 6), Color("2a5a7a"))
	# a small stand of fans on the right
	_draw_fans(Rect2(s.x - 170, wy - 72, 160, 40))
	# the tower and the springboard
	var by := board_y()
	# a concrete diving tower, its platforms stepping up behind the board
	var tower_top := wy - 10.0 * PX
	draw_rect(Rect2(26, tower_top, 30, wy - tower_top), Color("a8a6ba"))
	draw_rect(Rect2(26, tower_top, 3, wy - tower_top), Color("d4d4e0"))
	draw_rect(Rect2(53, tower_top, 3, wy - tower_top), Color("7a7690"))
	for h in [3.0, 7.5, 10.0]:
		var py: float = wy - float(h) * PX
		var reach: float = 40.0 + float(h) * 3.0
		draw_rect(Rect2(26, py, reach, 4), Color("d4d4e0"))
		draw_rect(Rect2(26, py + 4, reach, 2), Color("7a7690"))
		draw_rect(Rect2(26 + reach - 2, py - 10, 1, 10), Color("e0e0ee"))   # a rail at the end
		draw_rect(Rect2(26, py - 10, reach - 1, 1), Color("e0e0ee"))
		var f := Kit.font("small")
		draw_string(f, Vector2(30, py + 15), "%sm" % (str(int(h)) if h == floorf(h) else str(h)), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("4e4a62"))
	for ly in range(int(tower_top) + 6, int(wy), 9):
		draw_rect(Rect2(16, ly, 6, 1), Color("a0a0b8"))       # the ladder
	draw_rect(Rect2(16, tower_top, 1, wy - tower_top), Color("a0a0b8"))
	draw_rect(Rect2(21, tower_top, 1, wy - tower_top), Color("a0a0b8"))
	# the board: it bends a little under a bounce
	var bend := _board_bend
	var x0 := 40.0
	var x1 := BOARD_X + 8.0
	var n := int(x1 - x0)
	for i in n:
		var k := float(i) / n
		var dy := bend * k * k
		var x := x0 + i
		draw_rect(Rect2(x, roundf(by + dy), 1, 1), Color("fffaf0"))
		draw_rect(Rect2(x, roundf(by + dy) + 1, 1, 2), Color("d8c2a0"))
		draw_rect(Rect2(x, roundf(by + dy) + 3, 1, 1), Color("6a3a2a"))
	draw_rect(Rect2(x0 + 22, by + 4, 10, 6), Color("3a3a52"))  # the fulcrum
	# the water
	draw_rect(Rect2(0, wy, s.x, s.y - wy + 2), Color("2e86b4"))
	draw_rect(Rect2(0, wy + 10, s.x, s.y - wy), Color("1e5e8a"))
	for k in 6:
		var yy := wy + 2 + k * 7
		var ph := time * (1.2 + k * 0.2) + k
		for x in range(0, int(s.x), 2):
			var wv := sin(x * 0.05 + ph) * 1.2
			if fposmod(x + time * 10.0 * (1 + k % 2), 23.0) < 9.0:
				draw_rect(Rect2(x, roundf(yy + wv), 2, 1), Color("56b2d8") if k < 2 else Color("2e86b4"))
	draw_rect(Rect2(0, wy, s.x, 1), Color("9ad8f0"))
	# the splash
	if _splash_t < 1.4:
		var k2 := _splash_t / 1.4
		var h := (10.0 + _splash * 40.0) * sin(k2 * PI)
		var w := 6.0 + _splash * 26.0
		var cx := BOARD_X + 30.0
		for i in int(w):
			var u := (i - w / 2.0) / (w / 2.0)
			var colh := h * (1.0 - u * u)
			draw_rect(Rect2(roundf(cx - w / 2.0 + i), roundf(wy - colh), 1, roundf(colh)), Color(0.88, 0.96, 1.0, 1.0 - k2 * 0.5))
	# the judges' table on the near deck
	_draw_judges(Vector2(s.x - 150, s.y - 22 + cam_y * 0.0))


func _draw_fans(r: Rect2) -> void:
	if _fans == null:
		return
	draw_rect(Rect2(r.position + Vector2(0, 20), Vector2(r.size.x, 22)), Color("4e4a62"))
	draw_rect(Rect2(r.position + Vector2(0, 40), Vector2(r.size.x, 4)), Color("2e2a3e"))
	var cell: Array = _fan_meta.get("cell", [14, 22])
	var cols := int(_fan_meta.get("cols", 16))
	var bf := fposmod(beat, 1.0)
	for row in 2:
		for i in int(r.size.x / 12.0):
			var h := (i * 7 + row * 13) % 24
			var kind := 1 if bf < 0.12 and (i + row) % 2 == 0 else 0
			var idx := h * 4 + kind
			var src := Rect2((idx % cols) * float(cell[0]), (idx / cols) * float(cell[1]), float(cell[0]), float(cell[1]))
			var at := Vector2(r.position.x + i * 12 + row * 6, r.position.y + row * 12)
			draw_texture_rect_region(_fans, Rect2(at.round(), Vector2(float(cell[0]), float(cell[1]))), src,
				Color(0.85, 0.87, 0.95))


func _draw_judges(at: Vector2) -> void:
	if _fans == null:
		return
	var cell: Array = _fan_meta.get("cell", [14, 22])
	var cols := int(_fan_meta.get("cols", 16))
	draw_rect(Rect2(at + Vector2(-6, -2), Vector2(140, 24)), Color("6a3a2a"))
	draw_rect(Rect2(at + Vector2(-6, -2), Vector2(140, 2)), Color("c88a52"))
	var f := Kit.font("small")
	for i in 5:
		var idx: int = int(_judges[i]) * 4
		var src := Rect2((idx % cols) * float(cell[0]), (idx / cols) * float(cell[1]), float(cell[0]), float(cell[1]))
		var p := at + Vector2(i * 27, -20)
		draw_texture_rect_region(_fans, Rect2(p.round(), Vector2(float(cell[0]), float(cell[1]))), src)
		if i < marks.size():
			var card := Rect2(p + Vector2(-1, -16), Vector2(18, 12))
			draw_rect(card, Color("24152e"))
			draw_rect(card.grow(-1), Color("fffaf0"))
			var txt := ("%.1f" % float(marks[i])).trim_suffix(".0")
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			draw_string(f, Vector2(roundf(card.position.x + 9 - w / 2), card.position.y + 9), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("24152e"))
