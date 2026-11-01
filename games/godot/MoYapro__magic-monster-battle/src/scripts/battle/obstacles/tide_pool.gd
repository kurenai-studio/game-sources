class_name TidePool extends ObstacleData

func _init() -> void:
	super("tide_pool", "Tide Pool", Vector2i(2, 1), Color(0.15, 0.55, 0.65), 15)
	difficulty_rating = 5
	generation_weight = 13
