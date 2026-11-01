class_name Bullet
extends Area2D

const SPEED := 720.0
const LIFETIME := 1.1

var direction := Vector2.RIGHT
var _life := LIFETIME

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 3.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	collision_layer = 4
	collision_mask = 2
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	position += direction * SPEED * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	_wrap()
	queue_redraw()

func _wrap() -> void:
	var s := get_viewport_rect().size
	if position.x < 0.0: position.x += s.x
	if position.x > s.x: position.x -= s.x
	if position.y < 0.0: position.y += s.y
	if position.y > s.y: position.y -= s.y

func _on_area_entered(area: Area2D) -> void:
	if area is Asteroid:
		area.hit()
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.95, 0.55))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.85, 0.3, 0.25))
