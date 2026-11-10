class_name Powerup
extends Node2D
## Falling pickup: R = rapid fire, T = triple shot, S = shield, + = repair.

const KIND_DATA := {
	"rapid": {"letter": "R", "color": Color(1.0, 0.72, 0.2)},
	"triple": {"letter": "T", "color": Color(0.2, 0.85, 1.0)},
	"shield": {"letter": "S", "color": Color(0.35, 0.55, 1.0)},
	"life": {"letter": "+", "color": Color(0.3, 0.95, 0.45)},
}

var kind := "rapid"
var radius := 21.0
var _t := 0.0
var _base_x := 0.0

func setup(p_kind: String, pos: Vector2) -> void:
	kind = p_kind
	position = pos
	_base_x = pos.x
	var label := Label.new()
	label.text = str(KIND_DATA[kind]["letter"])
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(-10, -17)
	add_child(label)

func _process(delta: float) -> void:
	_t += delta
	position.y += 175.0 * delta
	position.x = _base_x + sin(_t * 2.4) * 18.0
	if position.y > get_viewport_rect().size.y + 40:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var color: Color = KIND_DATA[kind]["color"]
	var pulse := 1.0 + sin(_t * 5.0) * 0.08
	draw_circle(Vector2.ZERO, radius * pulse + 6.0, Color(color, 0.25))
	draw_circle(Vector2.ZERO, radius * pulse, Color(color, 0.9))
	draw_arc(Vector2.ZERO, radius * pulse, 0, TAU, 32, Color.WHITE, 2.0)
