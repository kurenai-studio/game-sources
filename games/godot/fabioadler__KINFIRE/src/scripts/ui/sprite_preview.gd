class_name SpritePreview
extends Control
## Desenha um personagem animado (SpriteFrames 0x72) dentro de um Control, em pixel art nítido.

var frames: SpriteFrames
var animation := "idle"
var tint := Color.WHITE
var flip := false
var weapon: Texture2D
var bob := true
var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func set_sprite(base: String, p_tint := Color.WHITE) -> void:
	frames = DB.frames(base)
	tint = p_tint
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if frames == null or not frames.has_animation(animation):
		return
	var count := frames.get_frame_count(animation)
	if count == 0:
		return
	var fps := frames.get_animation_speed(animation)
	var tex := frames.get_frame_texture(animation, int(_t * fps) % count)
	var ts := tex.get_size()
	# Escala inteira para manter os pixels nítidos
	var sc := maxf(floorf(minf(size.x / ts.x, size.y / ts.y)), 1.0)
	var draw_size := ts * sc
	var pos := (size - draw_size) * 0.5
	# Sombra
	draw_set_transform(Vector2(size.x * 0.5, pos.y + draw_size.y - sc * 2.0), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, draw_size.x * 0.35, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO)
	if weapon:
		var ws := weapon.get_size() * sc * 0.75
		var wp: Vector2 = Vector2(size.x * 0.5 + (-draw_size.x * 0.45 if flip else draw_size.x * 0.12), pos.y + draw_size.y * 0.25)
		draw_texture_rect(weapon, Rect2(wp, ws), false)
	var r: Rect2 = Rect2(pos, draw_size)
	if flip:
		r = Rect2(pos + Vector2(draw_size.x, 0), Vector2(-draw_size.x, draw_size.y))
	draw_texture_rect(tex, r, false, tint, false)
