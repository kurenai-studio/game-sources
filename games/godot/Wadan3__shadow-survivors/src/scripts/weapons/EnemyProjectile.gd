extends Area2D

var direction := Vector2.LEFT
var speed: float = 360.0
var damage: float = 16.0
var lifetime: float = 5.0
var radius: float = 9.0

const BURST := preload("res://scripts/effects/EffectBurst.gd")

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1 | 2
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_hit)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation += delta * 4.0
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _hit(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)
		BURST.spawn(get_tree().current_scene, global_position, Color("ff45b5"), 7, radius)
		queue_free()
	elif body is StaticBody2D:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 1.7, Color(0.9, 0.1, 0.65, 0.12))
	draw_circle(Vector2.ZERO, radius, Color("a51a80"))
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 12, Color("ff75d8"), 2.0)

