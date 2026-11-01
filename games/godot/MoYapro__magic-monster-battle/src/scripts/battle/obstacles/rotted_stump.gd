class_name RottedStump extends ObstacleData

func _init() -> void:
	super("rotted_stump", "Rotted Stump", Vector2i(1, 1), Color(0.28, 0.22, 0.15), 22)
	difficulty_rating = 7
	generation_weight = 12
