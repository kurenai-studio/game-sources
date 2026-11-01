class_name Pyre extends ObstacleData

func _init() -> void:
	super("pyre", "Pyre", Vector2i(1, 1), Color(0.85, 0.40, 0.05), 18)
	difficulty_rating = 6
	generation_weight = 12
