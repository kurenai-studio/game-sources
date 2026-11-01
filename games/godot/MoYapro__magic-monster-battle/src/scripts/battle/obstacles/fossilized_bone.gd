class_name FossilizedBone extends ObstacleData

func _init() -> void:
	super("fossilized_bone", "Fossilized Bone", Vector2i(2, 1), Color(0.85, 0.80, 0.65), 80)
	difficulty_rating = 14
	generation_weight = 8
