class_name SporeVent extends ObstacleData

func _init() -> void:
	super("spore_vent", "Spore Vent", Vector2i(1, 1), Color(0.45, 0.55, 0.20), 10)
	difficulty_rating = 4
	generation_weight = 11
