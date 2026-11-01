class_name SandDune extends ObstacleData

func _init() -> void:
	super("sand_dune", "Sand Dune", Vector2i(2, 1), Color(0.85, 0.75, 0.45), 10)
	difficulty_rating = 5
	generation_weight = 14
