class_name IceWall extends ObstacleData

func _init() -> void:
	super("ice_wall", "Ice Wall", Vector2i(2, 1), Color(0.70, 0.85, 0.95), 90)
	difficulty_rating = 16
	generation_weight = 8
