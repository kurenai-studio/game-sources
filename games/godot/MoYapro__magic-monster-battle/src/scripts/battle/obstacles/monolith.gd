class_name Monolith extends ObstacleData

func _init() -> void:
	super("monolith", "Monolith", Vector2i(1, 2), Color(0.38, 0.35, 0.42), 300)
	difficulty_rating = 25
	generation_weight = 6
