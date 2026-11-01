class_name Barrel extends ObstacleData

func _init() -> void:
	super("barrel", "Barrel", Vector2i(1, 1), Color(0.50, 0.35, 0.18), 15)
	difficulty_rating = 4
	generation_weight = 15
