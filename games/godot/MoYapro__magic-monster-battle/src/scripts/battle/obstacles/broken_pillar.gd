class_name BrokenPillar extends ObstacleData

func _init() -> void:
	super("broken_pillar", "Broken Pillar", Vector2i(1, 2), Color(0.55, 0.52, 0.48), 100)
	difficulty_rating = 16
	generation_weight = 8
