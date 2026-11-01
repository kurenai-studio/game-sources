class_name ObstacleData

var id: String
var display_name: String
var grid_size: Vector2i
var color: Color
var hp: int
var max_hp: int
var main_role: MonsterRole.Type = MonsterRole.Type.OBSTACLE
var difficulty_rating: int = 10   # 1–100; used in encounter budget
var generation_weight: int = 10   # relative frequency in generation


func on_hit(_state: BattleState, _setup: BattleSetup, _ev: CastEvent) -> void:
	pass


func on_destroyed(_state: BattleState, _setup: BattleSetup, _ev: CastEvent) -> void:
	pass


func _init(
	p_id: String,
	p_name: String,
	p_size: Vector2i,
	p_color: Color,
	p_hp: int
) -> void:
	id = p_id
	display_name = p_name
	grid_size = p_size
	color = p_color
	hp = p_hp
	max_hp = p_hp
