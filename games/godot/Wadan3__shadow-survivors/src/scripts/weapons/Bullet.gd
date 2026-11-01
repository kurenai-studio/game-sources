extends Area2D

var direction := Vector2.RIGHT
var speed: float = 920.0
var damage: float = 22.0
var lifetime: float = 1.8
var previous_position := Vector2.ZERO

const BURST := preload("res://scripts/effects/EffectBurst.gd")

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 4
	monitoring = true
	monitorable = false
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)
	previous_position = global_position
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	previous_position = global_position
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, direction)
		BURST.spawn(get_tree().current_scene, global_position, Color("65fbff"), 5, 5.0)
		queue_free()
	elif body is StaticBody2D:
		BURST.spawn(get_tree().current_scene, global_position, Color("65bde8"), 3, 3.0)
		queue_free()

func _draw() -> void:
	draw_line(Vector2(-15, 0), Vector2(4, 0), Color(0.15, 0.85, 1.0, 0.22), 9.0)
	draw_line(Vector2(-9, 0), Vector2(6, 0), Color("73faff"), 4.0)
	draw_circle(Vector2(5, 0), 3.5, Color.WHITE)

