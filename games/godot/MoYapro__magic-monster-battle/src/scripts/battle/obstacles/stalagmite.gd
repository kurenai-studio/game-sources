class_name Stalagmite extends ObstacleData

func _init() -> void:
	super("stalagmite", "Stalagmite", Vector2i(1, 2), Color(0.50, 0.48, 0.43), 55)
	difficulty_rating = 12
	generation_weight = 10
