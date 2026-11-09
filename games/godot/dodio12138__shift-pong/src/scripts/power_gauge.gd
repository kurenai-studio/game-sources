extends Control
## HUD panel comparing you and the AI side by side: grips and difficulty, then for
## each player the wing being prepared (forehand / backhand), how set the feet are
## (到位), stroke power (力度, with a notch for how hard the incoming ball needs
## hitting) and stamina (体力, the cap on power).

const C_INK := Color(0.040, 0.050, 0.100)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_GOOD := Color(0.980, 0.800, 0.250)
const C_BAD := Color(0.900, 0.080, 0.120)
const C_BAR := Color(0.15, 0.19, 0.32)
const COL_X := [96.0, 236.0]      # left edge of the "you" and "AI" columns
const COL_W := 124.0

var grip_text := ""
var ai_grip_text := ""
var desc := ""
var level_text := ""
var names := ["你", "AI"]
var target := -1.0                # how hard your incoming ball needs hitting (0..1), -1 = none
# index 0 = you, 1 = AI
var wing := ["fh", "fh"]
var settle := [0.0, 0.0]
var power := [0.0, 0.0]
var stamina := [1.0, 1.0]
var stamina_max := [1.0, 1.0]     # permanent fatigue ceiling
var focus_cards := 0
var focus_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if modulate.a > 0.0:   # hidden behind the menus: nothing to draw
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(C_INK, 0.8))
	draw_rect(Rect2(Vector2.ZERO, size), C_DIM, false, 2.0)
	var font := get_theme_font("font", "Label")
	draw_string(font, Vector2(10.0, 18.0), tr("%s: %s   %s: %s   %s" % [names[0], grip_text, names[1], ai_grip_text, level_text]), HORIZONTAL_ALIGNMENT_LEFT, size.x - 120.0, 12, C_WHITE)
	draw_string(font, Vector2(10.0, 34.0), tr(desc), HORIZONTAL_ALIGNMENT_LEFT, size.x - 20.0, 12, C_DIM)

	# focus cards in hand (T), top right; the one in use glows
	for i in 5:
		var r := Rect2(Vector2(size.x - 16.0 - (5 - i) * 13.0, 6.0), Vector2(10.0, 14.0))
		var held := i < focus_cards
		draw_rect(r, C_GOOD if held else C_BAR)
		draw_rect(r, C_WHITE if (focus_active and i == focus_cards) else C_DIM, false, 1.0)
	draw_string(font, Vector2(size.x - 16.0 - 5 * 13.0 - 30.0, 18.0), tr("T专注"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_GOOD if focus_cards > 0 else C_DIM)

	for i in 2:
		var x: float = COL_X[i]
		var fh: bool = wing[i] == "fh"
		draw_string(font, Vector2(x, 54.0), tr(names[i]), HORIZONTAL_ALIGNMENT_LEFT, 40, 12, C_BAD if i == 0 else C_WHITE)
		draw_string(font, Vector2(x + 44.0, 54.0), tr("正手"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_GOOD if fh else C_DIM)
		draw_string(font, Vector2(x + 76.0, 54.0), tr("反手"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM if fh else C_GOOD)
		draw_bar(Vector2(x, 62.0), settle[i])
		draw_bar(Vector2(x, 78.0), power[i], target if i == 0 else -1.0)
		draw_bar(Vector2(x, 94.0), stamina[i], -1.0, true, stamina_max[i])
	for row in [["到位", 62.0], ["力度", 78.0], ["体力", 94.0]]:
		draw_string(font, Vector2(10.0, row[1] + 10.0), tr(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)


## `mark` (0..1) draws a notch where the bar should be stopped; < 0 for none.
## `is_stamina` colours it as a reserve: yellow when fresh, red when worn out.
## `cap` < 1 greys out the part of the bar lost to fatigue for good.
func draw_bar(at: Vector2, v: float, mark := -1.0, is_stamina := false, cap := 1.0) -> void:
	var r := Rect2(at, Vector2(COL_W, 10.0))
	draw_rect(r, C_BAR)
	var col := C_GOOD if v > 0.8 else (C_BAD if v < 0.4 else C_WHITE)
	if mark >= 0.0:
		col = C_GOOD if absf(v - mark) < 0.3 * mark else C_WHITE
	elif is_stamina:
		col = C_GOOD if v > 0.6 else (C_BAD if v < 0.3 else C_WHITE)
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(v, 0.0, 1.0), r.size.y)), col)
	if cap < 1.0:
		var cx := r.position.x + r.size.x * cap
		draw_rect(Rect2(Vector2(cx, r.position.y), Vector2(r.end.x - cx, r.size.y)), Color(C_BAD, 0.35))
		draw_rect(Rect2(Vector2(cx - 1.0, r.position.y - 2.0), Vector2(2.0, r.size.y + 4.0)), C_BAD)
	draw_rect(r, C_DIM, false, 1.0)
	if mark >= 0.0:
		var mx := r.position.x + r.size.x * clampf(mark, 0.0, 1.0)
		draw_rect(Rect2(Vector2(mx - 1.5, r.position.y - 4.0), Vector2(3.0, r.size.y + 8.0)), C_WHITE)
