class_name VitalsBar
extends Control
## Barra de vida/recurso da HUD moderna (Fase 6.1, MECANICAS #9.2):
## horizontal, segmentada com marcas a cada 25%, gradiente interno sutil,
## brilho na ponta quando cheia, flash + tremor ao tomar dano. O texto do
## valor fica no centro (contornado), legível sobre qualquer preenchimento.

var bar_color: Color = Color(0.8, 0.08, 0.08):
	set(v):
		bar_color = v
		queue_redraw()
var value := 0.0:
	set(v):
		v = clampf(v, 0.0, 1.0)
		if v < value - 0.001:
			flash_damage()
		value = v
		queue_redraw()
var text := "":
	set(v):
		text = v
		queue_redraw()

var _flash := 0.0


func _init(p_color: Color = Color(0.8, 0.08, 0.08)) -> void:
	bar_color = p_color
	custom_minimum_size = Vector2(220, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func flash_damage() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 3.0, 0.0)
	queue_redraw()


func _draw() -> void:
	# tremor sutil ao tomar dano
	var jitter: Vector2 = Vector2(randf_range(-1.5, 1.5), randf_range(-1.0, 1.0)) * _flash
	var rect: Rect2 = Rect2(jitter, size)
	# caixa: vidro escuro com contorno
	draw_rect(rect, Color(0.03, 0.02, 0.02, 0.88))
	draw_rect(rect, UIKit.GOLD_DIM, false, 1.0)
	var fill_rect := rect.grow(-3)
	var fw := fill_rect.size.x * value
	if fw > 0.5:
		# corpo do preenchimento
		draw_rect(Rect2(fill_rect.position, Vector2(fw, fill_rect.size.y)), bar_color)
		# gradiente interno: faixa clara no topo, sombra na base
		draw_rect(Rect2(fill_rect.position, Vector2(fw, fill_rect.size.y * 0.42)),
			Color(bar_color.r * 1.35 + 0.05, bar_color.g * 1.35 + 0.05, bar_color.b * 1.35 + 0.05, 0.55))
		draw_rect(Rect2(fill_rect.position + Vector2(0, fill_rect.size.y * 0.72),
			Vector2(fw, fill_rect.size.y * 0.28)), Color(0, 0, 0, 0.25))
		# brilho na ponta quando cheia
		if value >= 0.999:
			draw_circle(fill_rect.position + Vector2(fw, fill_rect.size.y * 0.5),
				fill_rect.size.y * 0.9, Color(bar_color.r + 0.25, bar_color.g + 0.25, bar_color.b + 0.25, 0.35))
	# marcas de segmento a cada 25% (daltônico-friendly: ritmo visual)
	for i in 3:
		var x := fill_rect.position.x + fill_rect.size.x * (i + 1) * 0.25
		draw_line(Vector2(x, rect.position.y + 2), Vector2(x, rect.end.y - 2), Color(0, 0, 0, 0.55), 2.0)
	# flash de dano na borda
	if _flash > 0.0:
		draw_rect(rect, Color(1, 0.15, 0.1, _flash * 0.8), false, 2.0)
	# valor no centro
	var f := UIKit.FONT_TITLE
	if text != "":
		draw_string_outline(f, Vector2(0, size.y * 0.5 + 7), text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, 4, Color.BLACK)
		draw_string(f, Vector2(0, size.y * 0.5 + 7), text,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, Color.WHITE)
