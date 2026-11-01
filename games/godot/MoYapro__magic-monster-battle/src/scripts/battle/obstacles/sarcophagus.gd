class_name Sarcophagus extends ObstacleData

func _init() -> void:
	super("sarcophagus", "Sarcophagus", Vector2i(1, 2), Color(0.40, 0.35, 0.38), 160)
	difficulty_rating = 19
	generation_weight = 6
