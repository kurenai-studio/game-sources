class_name Asteroid
extends Area2D

signal destroyed(asteroid: Asteroid)

const SIZE_SMALL := 0
const SIZE_MEDIUM := 1
const SIZE_LARGE := 2

const RADII := [12.0, 22.0, 40.0]

var size_tier: int = SIZE_LARGE
var velocity := Vector2.ZERO
var spin := 0.0
var _shape_points: PackedVector2Array

func _ready() -> void:
	var r: float = RADII[size_tier]
	var shape := CircleShape2D.new()
	shape.radius = r * 0.85
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	collision_layer = 2
	collision_mask = 0
	spin = randf_range(-2.0, 2.0)
	_shape_points = _make_shape(r)

func _make_shape(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 11
	for i in range(n):
		var a := (float(i) / n) * TAU
		var rr := r * randf_range(0.75, 1.1)
		pts.append(Vector2(cos(a) * rr, sin(a) * rr))
	return pts

func _process(delta: float) -> void:
	position += velocity * delta
	rotation += spin * delta
	_wrap()

func _wrap() -> void:
	var s := get_viewport_rect().size
	var r: float = RADII[size_tier] + 10.0
	if position.x < -r: position.x = s.x + r
	if position.x > s.x + r: position.x = -r
	if position.y < -r: position.y = s.y + r
	if position.y > s.y + r: position.y = -r

func hit() -> void:
	destroyed.emit(self)
	queue_free()

func _draw() -> void:
	draw_colored_polygon(_shape_points, Color(0.55, 0.5, 0.48))
	var outline := _shape_points.duplicate()
	outline.append(_shape_points[0])
	draw_polyline(outline, Color(0.95, 0.9, 0.82), 1.6)
