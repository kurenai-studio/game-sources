extends Node

signal collected

@onready var pickup_area: Area2D = $"../Area2D"
@onready var collision_shape_2d: CollisionShape2D = $"../Area2D/CollisionShape2D"
@onready var sprite: Sprite2D = $"../Sprite2D"
@onready var drop: Node2D = get_parent() as Node2D

var is_collecting = false


func _ready() -> void:
	pickup_area.area_entered.connect(_on_area_entered)


func _tween_collect(percent: float, start_position: Vector2) -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	drop.global_position = start_position.lerp(player.global_position, percent)
	var direction_from_start = player.global_position - start_position
	var target_rotation = direction_from_start.angle() + deg_to_rad(90)
	drop.rotation = lerp_angle(
		drop.rotation,
		target_rotation,
		1 - exp(-2 * get_process_delta_time())
	)


func _on_area_entered(_other_area: Area2D) -> void:
	if is_collecting:
		return
	is_collecting = true
	Callable(_disable_collision).call_deferred()

	var tween = create_tween()
	tween.set_parallel()
	tween.tween_method(_tween_collect.bind(drop.global_position), 0.0, 1.0, .5)\
	.set_ease(Tween.EASE_IN)\
	.set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.15).set_delay(0.35)
	tween.chain()
	tween.tween_callback(_on_collection_animation_finished)


func _disable_collision() -> void:
	collision_shape_2d.disabled = true


func _on_collection_animation_finished() -> void:
	collected.emit()
