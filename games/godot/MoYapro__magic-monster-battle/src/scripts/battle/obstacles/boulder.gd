class_name Boulder extends ObstacleData

func _init() -> void:
	super("boulder", "Boulder", Vector2i(2, 1), Color(0.50, 0.48, 0.45), 140)
	difficulty_rating = 18
	generation_weight = 6
