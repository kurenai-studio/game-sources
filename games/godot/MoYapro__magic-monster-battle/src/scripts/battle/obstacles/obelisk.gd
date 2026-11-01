class_name Obelisk extends ObstacleData

func _init() -> void:
	super("obelisk", "Obelisk", Vector2i(1, 2), Color(0.70, 0.65, 0.50), 115)
	difficulty_rating = 18
	generation_weight = 6
