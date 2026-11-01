class_name BonePile extends ObstacleData

func _init() -> void:
	super("bone_pile", "Bone Pile", Vector2i(2, 1), Color(0.85, 0.82, 0.75), 18)
	difficulty_rating = 5
	generation_weight = 12


func on_hit(state: BattleState, setup: BattleSetup, _ev: CastEvent) -> void:
	var pos := setup.get_obstacle_pos_by_id(id, state)
	if pos.x < 0:
		return
	var cloud: Dictionary = {}
	for cell: Vector2i in EnemyGrid.get_cells_for_enemy(pos, grid_size):
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				cloud[cell + Vector2i(dx, dy)] = true
	for cell: Vector2i in cloud.keys():
		var occupant := setup.get_occupant_at(cell, state)
		if not occupant.is_empty() and state.enemies.has(occupant):
			state.add_enemy_status(occupant, StatusBlind.new())
			(state.enemies[occupant] as EnemyState).intent = {}

