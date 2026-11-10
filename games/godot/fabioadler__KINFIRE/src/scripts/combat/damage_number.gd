class_name DamageNumber
extends Label
## Número de dano flutuante (amarelo e maior quando crítico).

var _vel := Vector2.ZERO
var _t := 0.0


static func spawn(parent: Node, pos: Vector2, amount: float, crit: bool, color := Color.WHITE) -> void:
	if not Game.settings.damage_numbers:
		return
	var n := DamageNumber.new()
	n.text = str(roundi(amount)) + ("!" if crit else "")
	n.add_theme_font_override("font", UIKit.FONT_TITLE)
	n.add_theme_font_size_override("font_size", 22 if crit else 15)
	n.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if crit else color)
	n.add_theme_color_override("font_outline_color", Color.BLACK)
	n.add_theme_constant_override("outline_size", 5)
	n.scale = Vector2.ONE * 0.25
	n.z_index = 50
	n.position = pos + Vector2(randf_range(-6, 6), -14)
	n._vel = Vector2(randf_range(-20, 20), -55 if crit else -40)
	parent.add_child(n)


## Texto flutuante (ex.: "Bloqueado!", "Esquiva!")
static func spawn_text(parent: Node, pos: Vector2, text: String, color := Color.WHITE) -> void:
	var n := DamageNumber.new()
	n.text = text
	n.add_theme_font_override("font", UIKit.FONT_TITLE)
	n.add_theme_font_size_override("font_size", 16)
	n.add_theme_color_override("font_color", color)
	n.add_theme_color_override("font_outline_color", Color.BLACK)
	n.add_theme_constant_override("outline_size", 5)
	n.scale = Vector2.ONE * 0.25
	n.z_index = 50
	n.position = pos + Vector2(-10, -6)
	n._vel = Vector2(0, -30)
	parent.add_child(n)


func _process(delta: float) -> void:
	_t += delta
	position += _vel * delta
	_vel.y += 60 * delta
	if _t > 0.6:
		modulate.a = 1.0 - (_t - 0.6) / 0.4
	if _t > 1.0:
		queue_free()
