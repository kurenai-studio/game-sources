class_name PushableBox
extends CharacterBody2D

@onready var _area: Area2D = $DetectionArea
var _hud: HUD

func _ready() -> void:
	add_to_group("pushable")
	_hud = get_tree().get_first_node_in_group("hud")
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_hud.show_prompt("Push")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_hud.hide_prompt()

func try_push(direction: Vector2, tile_size: float) -> bool:
	var motion: Vector2 = direction * tile_size
	var collision: KinematicCollision2D = move_and_collide(motion)
	if collision:
		move_and_collide(-motion)
		return false
	return true
