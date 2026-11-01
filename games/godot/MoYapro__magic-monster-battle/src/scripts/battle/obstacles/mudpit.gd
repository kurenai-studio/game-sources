class_name Mudpit extends ObstacleData

func _init() -> void:
	super("mudpit", "Mudpit", Vector2i(2, 1), Color(0.30, 0.22, 0.12), 10)
	difficulty_rating = 5
	generation_weight = 14
