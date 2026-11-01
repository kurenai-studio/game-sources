class_name AncientPillar extends ObstacleData

func _init() -> void:
	super("ancient_pillar", "Ancient Pillar", Vector2i(1, 2), Color(0.65, 0.55, 0.35), 100)
	difficulty_rating = 17
	generation_weight = 7
