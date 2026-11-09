extends Control
## Skill wheel (技能轮盘) for 技能乒乓球: hold Shift (or the middle mouse button)
## and a radial menu opens in the middle of the screen, like a weapon wheel; the
## slot the mouse points at is picked when it is let go, and letting go in the
## middle picks nothing. The centre shows the focus cards left and what the
## highlighted skill does.

const C_INK := Color(0.040, 0.050, 0.100)
const C_BAR := Color(0.15, 0.19, 0.32)
const C_WHITE := Color(0.960, 0.960, 0.940)
const C_DIM := Color(0.720, 0.780, 0.860)
const C_YELLOW := Color(0.980, 0.800, 0.250)
const C_RED := Color(0.900, 0.080, 0.120)
const R_IN := 58.0
const R_OUT := 158.0

var slots: Array = []       # [{id, name, desc, cost}], clockwise from the top
var cards := 0
var hover := -1
var origin := Vector2.ZERO  # where the mouse was when the wheel opened


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func open(at: Vector2) -> void:
	origin = at
	hover = -1
	visible = true


## Picks the slot in the direction the mouse has moved from where the wheel
## opened (a small dead zone in the middle cancels).
func point(at: Vector2) -> void:
	var d := at - origin
	if d.length() < 20.0 or slots.is_empty():
		hover = -1
	else:
		var a := fposmod(atan2(d.x, -d.y), TAU)   # 0 at the top, clockwise
		hover = int(floor(a / TAU * slots.size() + 0.5)) % slots.size()
	queue_redraw()


func close() -> String:
	visible = false
	return slots[hover].id if hover >= 0 else ""


func _draw() -> void:
	var c := size * 0.5
	var font := get_theme_font("font", "Label")
	draw_circle(c, R_OUT + 6.0, Color(C_INK, 0.75))
	var n := slots.size()
	for i in n:
		var a0 := -PI * 0.5 + TAU * (i - 0.5) / n
		var a1 := -PI * 0.5 + TAU * (i + 0.5) / n
		var pts := PackedVector2Array()
		for k in 13:
			var a := lerpf(a0, a1, k / 12.0)
			pts.append(c + Vector2(cos(a), sin(a)) * R_OUT)
		for k in 13:
			var a := lerpf(a1, a0, k / 12.0)
			pts.append(c + Vector2(cos(a), sin(a)) * R_IN)
		var s: Dictionary = slots[i]
		var affordable: bool = cards >= int(s.cost)
		draw_colored_polygon(pts, (C_RED if affordable else C_BAR) if i == hover else Color(C_BAR, 0.9))
		pts.append(pts[0])
		draw_polyline(pts, C_YELLOW if i == hover else C_DIM, 2.0)
		var mid := -PI * 0.5 + TAU * i / n
		var at := c + Vector2(cos(mid), sin(mid)) * (R_IN + R_OUT) * 0.5
		var label: String = "%d %s" % [i + 1, s.name]   # its number key
		var w := font.get_string_size(tr(label), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, at + Vector2(-w * 0.5, 0.0), tr(label), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE if affordable else C_DIM)
		var cost := "专注 ×%d" % s.cost if int(s.cost) > 0 else ""
		var w2 := font.get_string_size(tr(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, at + Vector2(-w2 * 0.5, 15.0), tr(cost), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_YELLOW)
	draw_circle(c, R_IN - 4.0, C_INK)
	var t := "专注 %d" % cards
	var tw := font.get_string_size(tr(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, c + Vector2(-tw * 0.5, 4.0), tr(t), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_YELLOW)
	if hover >= 0:
		var desc: String = slots[hover].desc
		var dw := font.get_string_size(tr(desc), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_rect(Rect2(c + Vector2(-dw * 0.5 - 8.0, R_OUT + 14.0), Vector2(dw + 16.0, 20.0)), Color(C_INK, 0.85))
		draw_string(font, c + Vector2(-dw * 0.5, R_OUT + 28.0), tr(desc), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_WHITE)
