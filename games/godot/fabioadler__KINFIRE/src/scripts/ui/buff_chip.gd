class_name BuffChip
extends Control
## Chip do strip de buffs da HUD moderna (Fase 6.1, MECANICAS #9.2):
## disco colorido com anel de tempo restante e contagem em segundos -
## expira com fade quando o buff acaba.

var color := Color.WHITE:
	set(v):
		color = v
		queue_redraw()
var frac := 1.0:
	set(v):
		frac = clampf(v, 0.0, 1.0)
		queue_redraw()
var label := "":
	set(v):
		label = v
		queue_redraw()

var _fading := false


func _init(p_color: Color = Color.WHITE) -> void:
	color = p_color
	custom_minimum_size = Vector2(44, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func expire() -> void:
	_fading = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)


func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5 - 4.0
	# anel de tempo: trilha + arco do restante
	draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU, 40, Color(0, 0, 0, 0.5), 2.5, true)
	if frac > 0.003:
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * frac, 40, color, 2.5, true)
	# disco + abreviação
	draw_circle(c, r - 3.0, Color(color.r * 0.22, color.g * 0.22, color.b * 0.22, 0.92))
	if label != "":
		var f := UIKit.FONT_TITLE
		draw_string_outline(f, Vector2(0, c.y + 6), label,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, 3, Color.BLACK)
		draw_string(f, Vector2(0, c.y + 6), label,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, color)
