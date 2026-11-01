extends Node
class_name MovementController

@export var target_to_move: Node2D
@export var move_speed: float = 16.0
@export var threshold: float = 1.0

@onready var threshold_sqrd: float = threshold * threshold

var _target_position: Vector2


func _physics_process(delta: float) -> void:
  if not target_to_move:
    return
  
  if _target_position.distance_squared_to(target_to_move.global_position) > threshold_sqrd:
    target_to_move.global_position = target_to_move.global_position.lerp(_target_position, delta * 10.0)


func move_by(amt: Vector2) -> void:
  _target_position += amt * move_speed