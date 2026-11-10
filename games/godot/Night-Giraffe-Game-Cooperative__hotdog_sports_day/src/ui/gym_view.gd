class_name GymView
extends Node2D
## The gymnastics hall for the trampoline: a sprung wooden floor, panelled
## walls under tall windows, bunting of every nation's flag, a small stand of
## fans who bounce on the beat, the trampoline in the middle (its bed gives under
## a landing), and the five judges at their table.
##
## The camera rises with a high bounce and comes back down.

const PX := 22.0
const BED_H := 1.15                ## the bed is this far off the floor (metres)

var beat := 0.0
var cam_y := 0.0
var marks: Array = []
var time := 0.0
var _bend := 0.0
var _fans: Texture2D
var _fan_meta: Dictionary = {}
var _flags: Array = []


func _ready() -> void:
	_fans = load("res://assets/art/crowd/fans.png")
	var g := FileAccess.open("res://assets/art/crowd/fans.json", FileAccess.READ)
	_fan_meta = JSON.parse_string(g.get_as_text()) if g else {}
	for n in Catalog.nations():
		_flags.append(String(n.id))


func size() -> Vector2:
	return get_viewport_rect().size


func floor_y() -> float:
	return size().y - 26.0 + cam_y


func bed_y() -> float:
	return floor_y() - BED_H * PX


func centre_x() -> float:
	return roundf(size().x * 0.42)


func place(v: AthleteView, tr: Tramp) -> void:
	var b := tr.b
	v.position = Vector2(centre_x(), bed_y() + _bend).round()
	v.lift = maxf(0.0, b.y) * PX
	v.squash = b.squash
	v.angle = b.angle
	v.twist = tr.twist
	v.mood = b.mood
	v.lean = 0.0
	v.ground_shadow = 0.0
	_bend = clampf((1.0 - b.squash) * 10.0, 0.0, 5.0) if b.y < 0.05 else 0.0


func cam_follow(tr: Tramp, delta: float) -> void:
	var top := bed_y() - cam_y - tr.b.y * PX - 70.0
	var want := maxf(0.0, 22.0 - top)
	cam_y = lerpf(cam_y, want, clampf(delta * 4.0, 0.0, 1.0))


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	var s := size()
	var fy := floor_y()
	# the upper wall and its windows
	draw_rect(Rect2(0, -400, s.x, fy + 400), Color("d4d4e0"))
	var win_top := fy - 220.0
	for wx in range(14, int(s.x), 70):
		var r := Rect2(wx, win_top, 48, 90)
		draw_rect(r.grow(2), Color("7a7690"))
		draw_rect(r, Color("94c6f0"))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 30)), Color("6aa2e2"))
		draw_rect(Rect2(r.position.x + 23, r.position.y, 2, r.size.y), Color("7a7690"))
		draw_rect(Rect2(r.position.x, r.position.y + 44, r.size.x, 2), Color("7a7690"))
		draw_rect(Rect2(r.position.x + 4, r.position.y + 6, 8, 3), Color("e6eefa"))
	# bunting: every nation's flag on a line, sagging between the windows
	var n := _flags.size()
	for i in int(s.x / 18.0) + 1:
		var x := i * 18.0
		var sag := 6.0 * sin(PI * fposmod(x, 140.0) / 140.0)
		var y := win_top - 16.0 + sag
		draw_rect(Rect2(x, y - 1, 18, 1), Color("4e4a62"))
		var tex := Kit.flag(String(_flags[i % n]), "s")
		draw_texture(tex, Vector2(roundf(x + 2), roundf(y)))
	# a big banner across the wall, and the rings hanging in the far corner
	var f := Kit.font("small")
	var txt := "HOTDOG SPORTS DAY  ·  GYMNASTICS"
	var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	var bw := maxf(190.0, roundf(tw) + 20.0)
	var bx := roundf(s.x * 0.5 - bw / 2.0)
	var by := win_top + 100.0
	draw_rect(Rect2(bx, by, bw, 22), Color("1e2a7a"))
	draw_rect(Rect2(bx, by, bw, 2), Color("3e5ac0"))
	draw_rect(Rect2(bx, by + 20, bw, 2), Color("0e1238"))
	draw_string(f, Vector2(roundf(s.x * 0.5 - tw / 2.0), by + 14), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("ffd060"))
	for rx in [s.x - 60.0, s.x - 40.0]:
		draw_line(Vector2(rx, win_top - 30), Vector2(rx, by + 40), Color("6a6a86"), 1.0)
		draw_arc(Vector2(rx, by + 46), 6.0, 0.0, TAU, 16, Color("c88a52"), 2.0)
	# the lower wall: panelled wood
	var panel_top := fy - 92.0
	draw_rect(Rect2(0, panel_top, s.x, 92), Color("9a5e3a"))
	for px in range(0, int(s.x), 24):
		draw_rect(Rect2(px, panel_top, 1, 92), Color("6a3a2a"))
		draw_rect(Rect2(px + 1, panel_top, 1, 92), Color("c88a52"))
	draw_rect(Rect2(0, panel_top, s.x, 3), Color("e8b878"))
	draw_rect(Rect2(0, panel_top + 3, s.x, 1), Color("6a3a2a"))
	# a stand of fans along the back
	_draw_fans(Rect2(8, panel_top - 6, s.x * 0.28, 40))
	_draw_fans(Rect2(s.x * 0.62, panel_top - 6, s.x * 0.36, 40))
	# the floor: sprung boards
	draw_rect(Rect2(0, fy, s.x, s.y - fy + 400), Color("e8b878"))
	for k in 5:
		draw_rect(Rect2(0, fy + 3 + k * 6, s.x, 1), Color("c88a52"))
	draw_rect(Rect2(0, fy, s.x, 2), Color("6a3a2a"))
	# the trampoline: legs, frame with blue pads, and the bed
	var cx := centre_x()
	var tb := bed_y()
	var half := 62.0
	# the far legs (lighter), then the frame, springs, bed and the near legs
	for lx in [cx - half + 10, cx + half - 12]:
		draw_rect(Rect2(lx, tb - 4, 2, fy - tb + 2), Color("6a6a86"))
	var bend := _bend
	for i in int(half * 2):
		var u := (i - half) / half
		var dy := bend * (1.0 - u * u)
		draw_rect(Rect2(cx - half + i, roundf(tb + dy), 1, 2), Color("24152e"))
		if i % 6 == 0 and absf(u) > 0.15:
			draw_line(Vector2(cx - half + i, tb + dy + 1), Vector2(cx - half + i + signf(u) * 4.0, tb + 4), Color("a0a0b8"), 1.0)
	draw_rect(Rect2(cx - half - 10, tb + 2, half * 2 + 20, 4), Color("3a3a52"))
	draw_rect(Rect2(cx - half - 10, tb + 2, half * 2 + 20, 1), Color("a0a0b8"))
	for lx in [cx - half - 6, cx + half + 2]:
		draw_rect(Rect2(lx, tb + 6, 4, fy - tb - 6), Color("3a3a52"))
		draw_rect(Rect2(lx, tb + 6, 1, fy - tb - 6), Color("a0a0b8"))
		draw_rect(Rect2(lx - 3, fy - 2, 10, 2), Color("24152e"))
	# blue safety pads over the frame ends
	for px in [cx - half - 14, cx + half - 2]:
		draw_rect(Rect2(px, tb - 1, 16, 7), Color("2a4ad2"))
		draw_rect(Rect2(px, tb - 1, 16, 2), Color("6a92e2"))
		draw_rect(Rect2(px, tb + 5, 16, 1), Color("141a4a"))
	# the judges' table on the near floor
	_draw_judges(Vector2(s.x - 150, s.y - 18 + cam_y))


func _draw_fans(r: Rect2) -> void:
	if _fans == null:
		return
	var cell: Array = _fan_meta.get("cell", [14, 22])
	var cols := int(_fan_meta.get("cols", 16))
	var bf := fposmod(beat, 1.0)
	draw_rect(Rect2(r.position + Vector2(0, 18), Vector2(r.size.x, 14)), Color("4e4a62"))
	for row in 2:
		for i in int(r.size.x / 12.0):
			var h := (i * 5 + row * 11 + int(r.position.x)) % 24
			var kind := 1 if bf < 0.12 and (i + row) % 2 == 0 else 0
			var hop := 0.0 if kind == 1 else (1.0 if bf < 0.5 and (i + row) % 3 == 0 else 0.0)
			var idx := h * 4 + kind
			var src := Rect2((idx % cols) * float(cell[0]), (idx / cols) * float(cell[1]), float(cell[0]), float(cell[1]))
			var at := Vector2(r.position.x + i * 12 + row * 6, r.position.y + row * 10 - hop)
			draw_texture_rect_region(_fans, Rect2(at.round(), Vector2(float(cell[0]), float(cell[1]))), src,
				Color(0.88, 0.88, 0.96))


func _draw_judges(at: Vector2) -> void:
	if _fans == null:
		return
	var cell: Array = _fan_meta.get("cell", [14, 22])
	var cols := int(_fan_meta.get("cols", 16))
	draw_rect(Rect2(at + Vector2(-6, -2), Vector2(140, 22)), Color("2a4ad2"))
	draw_rect(Rect2(at + Vector2(-6, -2), Vector2(140, 2)), Color("6a92e2"))
	var f := Kit.font("small")
	for i in 5:
		var idx: int = ((i * 5 + 7) % 24) * 4
		var src := Rect2((idx % cols) * float(cell[0]), (idx / cols) * float(cell[1]), float(cell[0]), float(cell[1]))
		var p := at + Vector2(i * 27, -20)
		draw_texture_rect_region(_fans, Rect2(p.round(), Vector2(float(cell[0]), float(cell[1]))), src)
		if i < marks.size():
			var card := Rect2(p + Vector2(-2, -16), Vector2(20, 12))
			draw_rect(card, Color("24152e"))
			draw_rect(card.grow(-1), Color("fffaf0"))
			var txt := "%.1f" % float(marks[i])
			var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			draw_string(f, Vector2(roundf(card.position.x + 10 - w / 2), card.position.y + 9), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("24152e"))
