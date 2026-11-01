class_name SnowDrift extends ObstacleData

func _init() -> void:
	super("snow_drift", "Snow Drift", Vector2i(2, 1), Color(0.90, 0.92, 0.95), 8)
	difficulty_rating = 5
	generation_weight = 14
