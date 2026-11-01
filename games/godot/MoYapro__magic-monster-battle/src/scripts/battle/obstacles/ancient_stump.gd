class_name AncientStump extends ObstacleData

func _init() -> void:
	super("ancient_stump", "Ancient Stump", Vector2i(2, 2), Color(0.30, 0.20, 0.10), 175)
	difficulty_rating = 22
	generation_weight = 5
