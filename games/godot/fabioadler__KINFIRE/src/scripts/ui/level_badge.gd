class_name LevelBadge
extends Control
## Emblema de nível com anel de XP da HUD moderna (Fase 6.1, MECANICAS
## #9.2): círculo "vidro escuro" com o número do nível ao centro e o anel
## dourado externo preenchendo com o progresso da experiência.

var level := 1:
	set(v):
		level = v
		queue_redraw()
var xp_frac := 0.0:
	set(v):
		xp_frac = clampf(v, 0.0, 1.0)
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_progress(p_level: int, xp: int, xp_next: int) -> void:
	level = p_level
	xp_frac = clampf(float(xp) / float(xp_next), 0.0, 1.0) if xp_next > 0 else 0.0


func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5 - 5.0
	# anel de XP: trilha escura + arco dourado do progresso
	draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU, 64, Color(0.08, 0.06, 0.04, 0.9), 4.5, true)
	if xp_frac > 0.003:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * xp_frac, 64, UIKit.ACCENT_GOLD, 4.5, true)
	# disco interno
	draw_circle(c, r - 4.0, Color(0.03, 0.02, 0.02, 0.92))
	draw_arc(c, r - 4.0, 0, TAU, 48, UIKit.GOLD_DIM, 1.0, true)
	# nível ao centro
	var f := UIKit.FONT_TITLE
	draw_string_outline(f, Vector2(0, c.y + 11), str(level),
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, 5, Color.BLACK)
	draw_string(f, Vector2(0, c.y + 11), str(level),
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, UIKit.ACCENT_GOLD)
