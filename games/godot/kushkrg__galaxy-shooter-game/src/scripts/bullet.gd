class_name Bullet
extends Node2D
## A single projectile. Drawn in code (glow + core) — no textures.

var velocity := Vector2.ZERO
var damage := 1
var from_player := true
var radius := 7.0

func setup(pos: Vector2, vel: Vector2, dmg: int, friendly: bool) -> void:
	position = pos
	velocity = vel
	damage = dmg
	from_player = friendly

func _process(delta: float) -> void:
	position += velocity * delta
	var rect := get_viewport_rect().size
	if position.x < -60 or position.x > rect.x + 60 or position.y < -60 or position.y > rect.y + 60:
		queue_free()

func _draw() -> void:
	var glow := Color(0.15, 0.9, 1.0, 0.30) if from_player else Color(1.0, 0.25, 0.6, 0.30)
	var core := Color(0.45, 0.95, 1.0) if from_player else Color(1.0, 0.4, 0.7)
	draw_circle(Vector2.ZERO, radius + 5.0, glow)
	draw_circle(Vector2.ZERO, radius, core)
	draw_circle(Vector2.ZERO, radius * 0.45, Color.WHITE)
