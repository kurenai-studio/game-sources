extends Node2D

const SIZE := Vector2(2200.0, 1400.0)

func _ready() -> void:
	_build_walls()
	queue_redraw()

func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var half := SIZE * 0.5
	var configs := [
		[Vector2(0, -half.y - 20), Vector2(SIZE.x + 80, 40)],
		[Vector2(0, half.y + 20), Vector2(SIZE.x + 80, 40)],
		[Vector2(-half.x - 20, 0), Vector2(40, SIZE.y + 80)],
		[Vector2(half.x + 20, 0), Vector2(40, SIZE.y + 80)]
	]
	for config in configs:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = config[1]
		shape.shape = rect
		shape.position = config[0]
		body.add_child(shape)

func _draw() -> void:
	var rect := Rect2(-SIZE * 0.5, SIZE)
	draw_rect(rect, Color("091027"), true)
	for x in range(int(-SIZE.x / 2), int(SIZE.x / 2) + 1, 64):
		var major := x % 256 == 0
		draw_line(Vector2(x, -SIZE.y / 2), Vector2(x, SIZE.y / 2), Color(0.08, 0.34, 0.48, 0.24 if major else 0.09), 2.0 if major else 1.0)
	for y in range(int(-SIZE.y / 2), int(SIZE.y / 2) + 1, 64):
		var major := y % 256 == 0
		draw_line(Vector2(-SIZE.x / 2, y), Vector2(SIZE.x / 2, y), Color(0.08, 0.34, 0.48, 0.24 if major else 0.09), 2.0 if major else 1.0)
	for p in [Vector2(-760, -420), Vector2(700, 350), Vector2(0, -520), Vector2(-300, 480)]:
		draw_circle(p, 120.0, Color(0.35, 0.04, 0.34, 0.035))
		draw_arc(p, 85.0, 0.0, TAU, 32, Color(0.6, 0.1, 0.5, 0.12), 2.0)
	draw_rect(rect, Color("32d9ff"), false, 5.0)
	draw_rect(rect.grow(-14), Color(0.1, 0.65, 0.9, 0.24), false, 2.0)
