class_name MonsterActionTakeCover extends MonsterActionData


func _init() -> void:
	name = "Take Cover"
	target_type = TargetType.SELF


func check_preconditions(state: BattleState, setup: BattleSetup, enemy_id: String) -> bool:
	return not _is_in_cover(setup, state, enemy_id)


func _is_in_cover(setup: BattleSetup, state: BattleState, enemy_id: String) -> bool:
	var my_index := _find_index(setup, enemy_id)
	if my_index == -1:
		return false
	var my_pos: Vector2i = setup.get_enemy_pos(my_index, state)
	var my_size := setup.enemies[my_index].grid_size
	var front_col := my_pos.x - 1
	if front_col < 0:
		return false
	for row in my_size.y:
		var front_cell := Vector2i(front_col, my_pos.y + row)
		for i in setup.obstacles.size():
			if not state.obstacles.has(setup.obstacles[i].id):
				continue
			if EnemyGrid.get_cells_for_enemy(setup.get_obstacle_pos(i, state), setup.obstacles[i].grid_size).has(front_cell):
				return true
		for i in setup.enemies.size():
			if setup.enemies[i].id == enemy_id or not state.enemies.has(setup.enemies[i].id):
				continue
			if EnemyGrid.get_cells_for_enemy(setup.get_enemy_pos(i, state), setup.enemies[i].grid_size).has(front_cell):
				return true
	return false


func execute(state: BattleState, setup: BattleSetup, enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	var my_index := _find_index(setup, enemy_id)
	if my_index == -1:
		return new_state
	var my_size := setup.enemies[my_index].grid_size
	var my_pos: Vector2i = setup.get_enemy_pos(my_index, new_state)
	var occupied := _occupied_cells(setup, new_state, enemy_id)
	var best_pos := _find_best_behind(setup, new_state, enemy_id, my_pos, my_size, occupied)
	if best_pos != Vector2i(-1, -1):
		(new_state.enemies[enemy_id] as EnemyState).position = best_pos
	return new_state


func _find_best_behind(
	setup: BattleSetup, state: BattleState, enemy_id: String,
	my_pos: Vector2i, my_size: Vector2i, occupied: Dictionary
) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for i in setup.obstacles.size():
		if not state.obstacles.has(setup.obstacles[i].id):
			continue
		var pos := _behind_pos(setup.get_obstacle_pos(i, state), setup.obstacles[i].grid_size)
		if _can_place(pos, my_size, occupied):
			var d := _dist(my_pos, setup.get_obstacle_pos(i, state))
			if d < best_dist:
				best_dist = d
				best = pos
	for i in setup.enemies.size():
		if setup.enemies[i].id == enemy_id or not state.enemies.has(setup.enemies[i].id):
			continue
		var cover_pos: Vector2i = setup.get_enemy_pos(i, state)
		var pos := _behind_pos(cover_pos, setup.enemies[i].grid_size)
		if _can_place(pos, my_size, occupied):
			var d := _dist(my_pos, cover_pos)
			if d < best_dist:
				best_dist = d
				best = pos
	return best


func _behind_pos(cover_pos: Vector2i, cover_size: Vector2i) -> Vector2i:
	return Vector2i(cover_pos.x + cover_size.x, cover_pos.y)


func _can_place(pos: Vector2i, size: Vector2i, occupied: Dictionary) -> bool:
	if not EnemyGrid.is_within_bounds(pos, size):
		return false
	for cell: Vector2i in EnemyGrid.get_cells_for_enemy(pos, size):
		if occupied.has(cell):
			return false
	return true


func _occupied_cells(setup: BattleSetup, state: BattleState, exclude_id: String) -> Dictionary:
	var cells := {}
	for i in setup.enemies.size():
		if setup.enemies[i].id == exclude_id or not state.enemies.has(setup.enemies[i].id):
			continue
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(setup.get_enemy_pos(i, state), setup.enemies[i].grid_size):
			cells[cell] = true
	for i in setup.obstacles.size():
		if not state.obstacles.has(setup.obstacles[i].id):
			continue
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(setup.get_obstacle_pos(i, state), setup.obstacles[i].grid_size):
			cells[cell] = true
	return cells


func _find_index(setup: BattleSetup, enemy_id: String) -> int:
	for i in setup.enemies.size():
		if setup.enemies[i].id == enemy_id:
			return i
	return -1


func _dist(a: Vector2i, b: Vector2i) -> float:
	return (Vector2(a) - Vector2(b)).length()
