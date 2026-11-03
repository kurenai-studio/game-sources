extends Node2D
class_name AxeAbility

const MAX_RADIUS = 50.0

var base_rotation = Vector2.RIGHT

@onready var hitbox_component: HitboxComponent = $HitboxComponent


func _ready():
	base_rotation = Vector2.RIGHT.rotated(randf_range(0, TAU))
	var tween = create_tween()
	tween.tween_method(_axe_tween_method, 0.0, 2.0, 2.0)
	tween.tween_callback(queue_free)


func _axe_tween_method(rotations: float):
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var percent = rotations / 2.0
	var current_radius = percent * MAX_RADIUS
	var current_direction = base_rotation.rotated(rotations * TAU)
	global_position = player.global_position + (current_direction * current_radius)
