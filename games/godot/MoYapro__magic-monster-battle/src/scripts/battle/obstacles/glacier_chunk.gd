class_name GlacierChunk extends ObstacleData

func _init() -> void:
	super("glacier_chunk", "Glacier Chunk", Vector2i(2, 2), Color(0.45, 0.65, 0.90), 220)
	difficulty_rating = 24
	generation_weight = 5
