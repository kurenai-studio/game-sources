class_name BramblePatch extends ObstacleData

func _init() -> void:
	super("bramble_patch", "Bramble Patch", Vector2i(2, 1), Color(0.20, 0.30, 0.05), 20)
	difficulty_rating = 7
	generation_weight = 12
