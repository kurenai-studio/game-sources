extends Resource
class_name WaveEvent

@export_range(0.0, 600.0, 0.1) var time: float = 0.0
@export var id: StringName = &"mini_horde"
@export var enemy_rule: Resource
@export_range(1, 512, 1) var count: int = 10


func get_safe_count() -> int:
	return maxi(count, 1)
