class_name CrystalFormation extends ObstacleData

func _init() -> void:
	super("crystal_formation", "Crystal Formation", Vector2i(1, 2), Color(0.40, 0.30, 0.75), 45)
	difficulty_rating = 11
	generation_weight = 10
