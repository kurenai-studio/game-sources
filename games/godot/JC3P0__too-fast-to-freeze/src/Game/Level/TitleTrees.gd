extends PathFollow3D

@export var tree_speed := .25

func _physics_process(delta: float) -> void:
	progress_ratio += (tree_speed * delta)
	pass
