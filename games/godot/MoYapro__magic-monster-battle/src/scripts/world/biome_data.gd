class_name BiomeData

# Axes: x = hot/dry (0) <-> wet/cold (10), y = real (0) <-> fantasy (10)
var name: String
var tagline: String
var color: Color
var grid_pos: Vector2i
var layer: int                    # 1 = starter, 2 = mid, 3 = endgame, 4 = The Source
var unlocked_by: Array[String]    # biome names whose boss unlocks this one (empty = always available)
var monster_pool: Array = []      # Array of EnemyData subclass scripts; call .new() to spawn
var obstacle_pool: Array = []     # Array of ObstacleData subclass scripts; call .new() to spawn


func _init(p_name: String, p_tagline: String, p_color: Color, p_grid_pos: Vector2i, p_layer: int, p_unlocked_by: Array[String]) -> void:
	name = p_name
	tagline = p_tagline
	color = p_color
	grid_pos = p_grid_pos
	layer = p_layer
	unlocked_by = p_unlocked_by


static func stray_weight(from: BiomeData, to: BiomeData) -> float:
	var dist := (from.grid_pos - to.grid_pos).abs()
	var manhattan := dist.x + dist.y
	return pow(0.1, manhattan)
