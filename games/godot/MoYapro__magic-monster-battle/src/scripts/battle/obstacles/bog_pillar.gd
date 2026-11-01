class_name BogPillar extends ObstacleData

func _init() -> void:
	super("bog_pillar", "Bog Pillar", Vector2i(1, 2), Color(0.20, 0.35, 0.22), 75)
	difficulty_rating = 14
	generation_weight = 8
