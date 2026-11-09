class_name WeaknessMark
extends Node2D
## Small diamond above a resistant enemy, colored like the form that
## defeats it (the form it does NOT resist).

const SIZE := 2.5
const OUTLINE := Color(0.05, 0.04, 0.08)
const UNSHADED := preload("res://assets/fx/unshaded.tres")

var color: Color = Color.WHITE


static func create(weak_to: Player.Form, at: Vector2) -> WeaknessMark:
	var mark := WeaknessMark.new()
	mark.color = Player.ui_color(weak_to)
	mark.position = at
	return mark


func set_weak_to(weak_to: Player.Form) -> void:
	color = Player.ui_color(weak_to)
	queue_redraw()


func _init() -> void:
	material = UNSHADED
	z_index = 5


func _draw() -> void:
	draw_colored_polygon(_diamond(SIZE + 1.0), OUTLINE)
	draw_colored_polygon(_diamond(SIZE), color)


func _diamond(radius: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)])
