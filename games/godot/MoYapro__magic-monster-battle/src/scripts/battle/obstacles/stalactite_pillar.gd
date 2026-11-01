class_name StalactitePillar extends ObstacleData

func _init() -> void:
	super("stalactite_pillar", "Stalactite Pillar", Vector2i(1, 2), Color(0.42, 0.38, 0.33), 65)
	difficulty_rating = 13
	generation_weight = 10
