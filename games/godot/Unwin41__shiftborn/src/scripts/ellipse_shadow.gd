class_name EllipseShadow
extends Node2D
## Soft oval shadow for big sprites (bosses), where scaling the 12x7 pixel
## shadow texture would turn into a hard black block.

const COLOR := Color(0.0, 0.0, 0.0, 0.32)
const SEGMENTS := 24

var radius := Vector2(16.0, 6.0)


static func create(width: float, at: Vector2) -> EllipseShadow:
	var shadow := EllipseShadow.new()
	shadow.radius = Vector2(width * 0.4, width * 0.14)
	shadow.position = at
	shadow.show_behind_parent = true
	return shadow


func _draw() -> void:
	var points := PackedVector2Array()
	for i in SEGMENTS:
		points.append(Vector2.from_angle(TAU * i / SEGMENTS) * radius)
	draw_colored_polygon(points, COLOR)
