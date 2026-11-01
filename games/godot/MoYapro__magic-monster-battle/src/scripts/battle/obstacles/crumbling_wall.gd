class_name CrumblingWall extends ObstacleData

func _init() -> void:
	super("crumbling_wall", "Crumbling Wall", Vector2i(2, 1), Color(0.50, 0.44, 0.38), 70)
	difficulty_rating = 13
	generation_weight = 9
