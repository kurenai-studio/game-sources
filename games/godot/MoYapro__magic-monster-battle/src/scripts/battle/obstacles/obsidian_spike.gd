class_name ObsidianSpike extends ObstacleData

func _init() -> void:
	super("obsidian_spike", "Obsidian Spike", Vector2i(1, 2), Color(0.15, 0.12, 0.18), 130)
	difficulty_rating = 20
	generation_weight = 6
