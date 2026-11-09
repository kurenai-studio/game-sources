extends Control
## Scoreboard bar across the top of the match HUD: each side's colour strip,
## name and games won, the points in the middle, a dot at whoever serves, and
## a small status line underneath (mode, tie or cup, focus, timeouts).

const C_INK := Color(0.040, 0.050, 0.100)
const C_PANEL := Color(0.070, 0.090, 0.200)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_YELLOW := Color(0.980, 0.800, 0.250)
const C_RED := Color(0.900, 0.080, 0.120)
const C_BLUE := Color(0.220, 0.460, 0.780)

var names := ["你", "AI"]
var points := [0, 0]
var games := [0, 0]
var show_games := false
var serving := 0             # 0 you, 1 the other side, -1 nobody
var status := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if modulate.a > 0.0:   # hidden behind the menus: nothing to draw
		queue_redraw()


func _draw() -> void:
	var font := get_theme_font("font", "Label")
	var w := size.x
	var bar := Rect2(Vector2.ZERO, Vector2(w, 40.0))
	draw_rect(bar, Color(C_INK, 0.85))
	draw_rect(Rect2(Vector2.ZERO, Vector2(6.0, 40.0)), C_RED)
	draw_rect(Rect2(Vector2(w - 6.0, 0.0), Vector2(6.0, 40.0)), C_BLUE)
	draw_rect(bar, C_DIM, false, 1.0)
	var mid := w * 0.5
	# points, big, in the middle
	var score := "%d  :  %d" % [points[0], points[1]]
	var sw := font.get_string_size(score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_rect(Rect2(Vector2(mid - sw * 0.5 - 12.0, 2.0), Vector2(sw + 24.0, 36.0)), C_PANEL)
	draw_string(font, Vector2(mid - sw * 0.5, 29.0), score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, C_WHITE)
	# names, games and the serve dot on each side
	for i in 2:
		var right := i == 1
		var name: String = names[i]
		var nw := font.get_string_size(tr(name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var nx: float = (w - 18.0 - nw) if right else 18.0
		draw_string(font, Vector2(nx, 25.0), tr(name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE)
		if show_games:
			var g := "局 %d" % games[i]
			var gw := font.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var gx: float = (mid + sw * 0.5 + 22.0) if right else (mid - sw * 0.5 - 22.0 - gw)
			draw_string(font, Vector2(gx, 25.0), g, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_YELLOW)
		if serving == i:
			draw_circle(Vector2((nx - 9.0) if right else (nx + nw + 9.0), 21.0), 4.0, C_YELLOW)
	if status != "":
		var stw := font.get_string_size(tr(status), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_rect(Rect2(Vector2(mid - stw * 0.5 - 8.0, 42.0), Vector2(stw + 16.0, 18.0)), Color(C_INK, 0.75))
		draw_string(font, Vector2(mid - stw * 0.5, 55.0), tr(status), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
