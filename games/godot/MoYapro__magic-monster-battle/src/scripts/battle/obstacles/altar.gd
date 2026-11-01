class_name Altar extends ObstacleData

func _init() -> void:
	super("altar", "Altar", Vector2i(2, 2), Color(0.30, 0.28, 0.32), 200)
	difficulty_rating = 22
	generation_weight = 5
