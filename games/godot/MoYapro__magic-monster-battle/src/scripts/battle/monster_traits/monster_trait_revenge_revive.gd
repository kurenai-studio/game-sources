class_name MonsterTraitRevengeRevive extends MonsterTraitData

const NO_POS := Vector2i(-1, -1)


func _init() -> void:
	super("Revenge Revive", 3)


func apply_on_monster_dies(state: BattleState, setup: BattleSetup, _trait_owner_id: String, _dead_enemy_id: String) -> void:
	var best_id := _strongest_dead(state, setup)
	if best_id.is_empty():
		return
	var enemy := setup.get_enemy(best_id)
	var snapshot := state.dead_enemies[best_id] as EnemyState
	var revive_pos := _last_pos(best_id, snapshot, setup)
	if not _fits_at(revive_pos, enemy.grid_size, state, setup):
		revive_pos = _find_free_cell(enemy.grid_size, state, setup)
	if revive_pos == NO_POS:
		return
	var es := EnemyState.new()
	es.combatant.hp = enemy.max_hp
	es.combatant.statuses = snapshot.combatant.statuses.duplicate()
	es.position = revive_pos
	state.enemies[best_id] = es
	state.dead_enemies.erase(best_id)


func _strongest_dead(state: BattleState, setup: BattleSetup) -> String:
	var best_id := ""
	var best_hp := -1
	for dead_id: String in state.dead_enemies:
		var dead_enemy := setup.get_enemy(dead_id)
		if dead_enemy == null or _is_reviver(dead_enemy):
			continue
		if dead_enemy.max_hp > best_hp:
			best_hp = dead_enemy.max_hp
			best_id = dead_id
	return best_id


func _is_reviver(enemy: EnemyData) -> bool:
	return enemy.traits.any(func(t: MonsterTraitData) -> bool: return t is MonsterTraitRevengeRevive)


func _last_pos(dead_id: String, snapshot: EnemyState, setup: BattleSetup) -> Vector2i:
	if snapshot.position != NO_POS:
		return snapshot.position
	for i in setup.enemies.size():
		if setup.enemies[i].id == dead_id:
			return setup.enemy_positions[i]
	return NO_POS


func _find_free_cell(grid_size: Vector2i, state: BattleState, setup: BattleSetup) -> Vector2i:
	var total := EnemyGrid.ROWS * EnemyGrid.COLS
	var start := randi() % total
	for offset in total:
		var i := (start + offset) % total
		var pos := Vector2i(i % EnemyGrid.COLS, i / EnemyGrid.COLS)
		if _fits_at(pos, grid_size, state, setup):
			return pos
	return NO_POS


func _fits_at(pos: Vector2i, grid_size: Vector2i, state: BattleState, setup: BattleSetup) -> bool:
	if pos == NO_POS or not EnemyGrid.is_within_bounds(pos, grid_size):
		return false
	for cell: Vector2i in EnemyGrid.get_cells_for_enemy(pos, grid_size):
		if not setup.get_occupant_at(cell, state).is_empty():
			return false
	return true
