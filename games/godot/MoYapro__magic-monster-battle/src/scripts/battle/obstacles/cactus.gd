class_name Cactus extends ObstacleData

func _init() -> void:
	super("cactus", "Cactus", Vector2i(1, 2), Color(0.20, 0.55, 0.10), 28)
	difficulty_rating = 10
	generation_weight = 12
