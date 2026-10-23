extends Resource
class_name WaveEnemyRule

@export var id: StringName = &"enemy"
@export var enemy_scene: PackedScene
@export_range(0, 1000, 1) var weight: int = 100
@export_range(0, 500, 1) var min_alive: int = 0
@export_range(1, 128, 1) var group_size_min: int = 1
@export_range(1, 128, 1) var group_size_max: int = 3
@export_range(0.1, 10.0, 0.05) var hp_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var damage_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var speed_multiplier: float = 1.0


func get_safe_group_size_min() -> int:
	return maxi(group_size_min, 1)


func get_safe_group_size_max() -> int:
	return maxi(group_size_max, get_safe_group_size_min())
