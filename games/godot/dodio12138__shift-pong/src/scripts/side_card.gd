extends Control
## One player's status card in the match HUD (yours bottom left, the
## opponent's top right, where each of you stands): name and rating, grip and
## the wing being prepared, focus-card pips, a status tag, and bars for how set
## the feet are (到位), stroke power (力度, with a notch for what the incoming
## ball needs) and stamina (体力, greyed past the permanent-fatigue ceiling).
## In a skill match the four skills that side took in sit inside it as chips
## (yours with their number keys), and a status strip (重球, a spell on that
## side) shows over them; the card is as tall as what it holds (height()).

const C_INK := Color(0.040, 0.050, 0.100)
const C_BAR := Color(0.15, 0.19, 0.32)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_GOOD := Color(0.980, 0.800, 0.250)
const C_BAD := Color(0.900, 0.080, 0.120)
const BAR_X := 40.0

var accent := C_BAD
var title := "你"
var sub := ""                # rating / level
var grip_text := ""
var wing := "fh"
var cards := 0
var cards_max := 5
var focus_active := false
var tag := ""                # 重球 / 待发的招数 / …
var settle := 0.0
var power := 0.0
var target := -1.0
var stamina := 1.0
var stamina_max := 1.0
var skills: Array = []       # names of the skills taken in (empty when skills are off)
var keyed := false           # number the chips (your side: keys 1-4)
var compact := false         # the other side: name, grip, focus pips and stamina only
var spent: Array = []        # which of them can't be afforded right now


## How tall the card wants to be for what it shows right now.
func height() -> float:
	var h := 40.0 + (1 if compact else 3) * 15.0 + 4.0
	if tag != "":
		h += 19.0
	if not skills.is_empty():
		h += ((skills.size() + 1) / 2) * 19.0 + 2.0
	return h + 6.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if modulate.a > 0.0:   # hidden behind the menus: nothing to draw
		queue_redraw()


func _draw() -> void:
	var font := get_theme_font("font", "Label")
	var w := size.x
	draw_rect(Rect2(Vector2.ZERO, size), Color(C_INK, 0.82))
	draw_rect(Rect2(Vector2.ZERO, Vector2(4.0, size.y)), accent)
	draw_rect(Rect2(Vector2.ZERO, size), C_DIM, false, 1.0)
	# name and rating
	draw_string(font, Vector2(12.0, 16.0), tr(title), HORIZONTAL_ALIGNMENT_LEFT, w * 0.5, 12, C_WHITE)
	var sw := font.get_string_size(tr(sub), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(w - 10.0 - sw, 16.0), tr(sub), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
	# grip, the wing it is set for, focus pips
	draw_string(font, Vector2(12.0, 32.0), tr(grip_text), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
	var gx := 12.0 + font.get_string_size(tr(grip_text), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10.0
	draw_string(font, Vector2(gx, 32.0), tr("正手"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_GOOD if wing == "fh" else C_BAR)
	var fw := font.get_string_size(tr("正手"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(gx + fw + 6.0, 32.0), tr("反手"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_GOOD if wing == "bh" else C_BAR)
	for i in cards_max:
		var r := Rect2(Vector2(w - 12.0 - (cards_max - i) * 11.0, 22.0), Vector2(8.0, 11.0))
		draw_rect(r, C_GOOD if i < cards else C_BAR)
		if focus_active and i == cards:
			draw_rect(r, C_WHITE, false, 1.0)
	# bars (the other side: just how tired)
	var rows := [["到位", settle, -1.0, false], ["力度", power, target, false], ["体力", stamina, -1.0, true]]
	if compact:
		rows = [rows[2]]
	# the bars start after the widest label (labels run longer in English)
	var bx := BAR_X
	for row in rows:
		bx = maxf(bx, 18.0 + font.get_string_size(tr(row[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x)
	for k in rows.size():
		var y := 40.0 + k * 15.0
		draw_string(font, Vector2(12.0, y + 10.0), tr(rows[k][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_DIM)
		_bar(Rect2(Vector2(bx, y + 1.0), Vector2(w - bx - 12.0, 9.0)), rows[k][1], rows[k][2], rows[k][3])
	var y0 := 40.0 + rows.size() * 15.0 + 4.0
	if tag != "":   # what's on this side right now, a strip across the card
		draw_rect(Rect2(Vector2(10.0, y0), Vector2(w - 20.0, 16.0)), Color(C_GOOD, 0.14))
		draw_string(font, Vector2(14.0, y0 + 12.0), tr(tag), HORIZONTAL_ALIGNMENT_LEFT, w - 28.0, 12, C_GOOD)
		y0 += 19.0
	# the skills taken in: two chips a row
	var cw := (w - 26.0) * 0.5
	for i in skills.size():
		var r := Rect2(Vector2(10.0 + (i % 2) * (cw + 6.0), y0 + (i / 2) * 19.0), Vector2(cw, 16.0))
		draw_rect(r, Color(accent, 0.16) if not spent.has(i) else Color(C_BAR, 0.4))
		var label: String = ("%d %s" % [i + 1, tr(skills[i])]) if keyed else tr(skills[i])
		draw_string(font, r.position + Vector2(6.0, 13.0), label, HORIZONTAL_ALIGNMENT_LEFT, cw - 10.0, 12,
				C_WHITE if not spent.has(i) else C_BAR)


func _bar(r: Rect2, v: float, mark: float, is_stamina: bool) -> void:
	draw_rect(r, C_BAR)
	var col := C_GOOD if v > 0.8 else (C_BAD if v < 0.4 else C_WHITE)
	if mark >= 0.0:
		col = C_GOOD if absf(v - mark) < 0.3 * mark else C_WHITE
	elif is_stamina:
		col = C_GOOD if v > 0.6 else (C_BAD if v < 0.3 else C_WHITE)
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(v, 0.0, 1.0), r.size.y)), col)
	if is_stamina and stamina_max < 1.0:
		var cx := r.position.x + r.size.x * stamina_max
		draw_rect(Rect2(Vector2(cx, r.position.y), Vector2(r.end.x - cx, r.size.y)), Color(C_BAD, 0.35))
	if mark >= 0.0:
		var mx := r.position.x + r.size.x * clampf(mark, 0.0, 1.0)
		draw_rect(Rect2(Vector2(mx - 1.0, r.position.y - 3.0), Vector2(2.0, r.size.y + 6.0)), C_WHITE)
