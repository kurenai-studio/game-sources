class_name LavaRock extends ObstacleData

func _init() -> void:
	super("lava_rock", "Lava Rock", Vector2i(1, 1), Color(0.65, 0.15, 0.05), 60)
	difficulty_rating = 12
	generation_weight = 10
