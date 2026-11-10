class_name ClockChip
extends Control
## Chip de relógio da HUD (Fase 7.1, MECANICAS #14.1): hora HH:MM de
## Eldara em 24h + arco de progresso do dia com sol/lua. A meia-noite
## exata o arco fecha e a hora mostra 00:00 na virada.

var hour := 0:
	set(v):
		hour = v
		queue_redraw()
var minute := 0:
	set(v):
		minute = v
		queue_redraw()
var day_frac := 0.0:
	set(v):
		day_frac = v
		queue_redraw()
var is_day := true:
	set(v):
		is_day = v
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(96, 32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "Ciclo de Eldara"


## `frac` = fmod(world_time, 1.0) - 0.0 = meia-noite, 0.5 = meio-dia
func set_time(frac: float) -> void:
	day_frac = frac
	hour = int(frac * 24.0) % 24
	minute = int(fmod(frac * 24.0, 1.0) * 60.0)
	# dia = 06:00-18:00 (REGRAS #14: o dia vira às 06:00)
	is_day = frac >= 0.25 and frac < 0.75


func time_text() -> String:
	return "%02d:%02d" % [hour, minute]


func _draw() -> void:
	# pílula escura com borda dourada (linguagem dos chips de moeda)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.03, 0.9))
	draw_rect(Rect2(Vector2.ZERO, size), UIKit.GOLD_DIM, false, 1.0)
	# arco de progresso do dia (anel: 00:00 no topo, horário)
	var c: Vector2 = Vector2(18, size.y * 0.5)
	var r := size.y * 0.5 - 5.0
	draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU, 32, Color(0.1, 0.09, 0.08), 3.0, true)
	var arc_col: Color = UIKit.ACCENT_GOLD if is_day else Color(0.55, 0.62, 0.9)
	draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * day_frac, 32, arc_col, 3.0, true)
	# sol/lua no centro do anel
	var glyph := "☀" if is_day else "☾"
	var f := UIKit.FONT_TITLE
	draw_string_outline(f, c - Vector2(8, 4), glyph, HORIZONTAL_ALIGNMENT_CENTER,
		16, 12, 3, Color.BLACK)
	draw_string(f, c - Vector2(8, 4), glyph, HORIZONTAL_ALIGNMENT_CENTER,
		16, 12, arc_col)
	# HH:MM à direita
	draw_string_outline(f, Vector2(34, size.y * 0.5 + 6), time_text(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 3, Color.BLACK)
	draw_string(f, Vector2(34, size.y * 0.5 + 6), time_text(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UIKit.TEXT_MAIN)
