class_name ObstacleTree extends ObstacleData

func _init() -> void:
	super("tree", "Tree", Vector2i(1, 2), Color(0.18, 0.45, 0.15), 70)
	difficulty_rating = 15
	generation_weight = 12
