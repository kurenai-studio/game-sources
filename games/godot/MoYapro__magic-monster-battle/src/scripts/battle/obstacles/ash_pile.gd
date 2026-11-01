class_name AshPile extends ObstacleData

func _init() -> void:
	super("ash_pile", "Ash Pile", Vector2i(2, 1), Color(0.55, 0.53, 0.50), 8)
	difficulty_rating = 4
	generation_weight = 14
