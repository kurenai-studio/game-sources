class_name MushroomCircle extends ObstacleData

func _init() -> void:
	super("mushroom_circle", "Mushroom Circle", Vector2i(2, 1), Color(0.75, 0.40, 0.70), 12)
	difficulty_rating = 8
	generation_weight = 10
