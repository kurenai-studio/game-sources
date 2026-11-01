class_name MonsterActionDrumsOfWar extends MonsterActionData


func _init() -> void:
	name = "Drums of War"
	target_type = TargetType.SELF


func execute(state: BattleState, setup: BattleSetup, enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	var my_idx := _find_idx(setup, enemy_id)
	if my_idx < 0:
		return new_state
	var my_cells := _build_cells(setup.get_enemy_pos(my_idx, new_state), setup.enemies[my_idx].grid_size)
	for i in setup.enemies.size():
		var other := setup.enemies[i]
		if other.id == enemy_id or not new_state.enemies.has(other.id):
			continue
		var other_cells := _build_cells(setup.get_enemy_pos(i, new_state), other.grid_size)
		if _are_adjacent(my_cells, other_cells):
			(new_state.enemies[other.id] as EnemyState).attack_mult = 2.0
	return new_state


static func _find_idx(setup: BattleSetup, enemy_id: String) -> int:
	for i in setup.enemies.size():
		if setup.enemies[i].id == enemy_id:
			return i
	return -1


static func _build_cells(pos: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in size.y:
		for col in size.x:
			cells.append(pos + Vector2i(col, row))
	return cells


static func _are_adjacent(a: Array[Vector2i], b: Array[Vector2i]) -> bool:
	var b_set := {}
	for cell: Vector2i in b:
		b_set[cell] = true
	for cell: Vector2i in a:
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if b_set.has(cell + offset):
				return true
	return false
