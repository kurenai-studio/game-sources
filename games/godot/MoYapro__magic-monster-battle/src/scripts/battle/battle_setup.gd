class_name BattleSetup

# Immutable battle configuration — does not change during a battle.

var enemies: Array[EnemyData] = []
var enemy_positions: Array[Vector2i] = []
var obstacles: Array[ObstacleData] = []
var obstacle_positions: Array[Vector2i] = []
var mages: Array[MageData] = []
var wands: Array[WandData] = []
var max_mana: int = 10

# cell -> enemy_id (precomputed for fast lookup)
var _cell_to_enemy: Dictionary = {}


func _init(
	p_enemies: Array[EnemyData],
	p_positions: Array[Vector2i],
	p_mages: Array[MageData],
	p_wands: Array[WandData],
	p_max_mana: int,
	p_obstacles: Array[ObstacleData] = [],
	p_obstacle_positions: Array[Vector2i] = []
) -> void:
	enemies = p_enemies
	enemy_positions = p_positions
	obstacles = p_obstacles
	obstacle_positions = p_obstacle_positions
	mages = p_mages
	wands = p_wands
	max_mana = p_max_mana
	_build_cell_map()


func make_initial_state() -> BattleState:
	var state := BattleState.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_fill_obstacles(state)
	_fill_monsters(state)
	_copy_mages(state)
	_fill_ground(state, rng)
	state.mana = max_mana
	apply_puddle_wet(state)
	roll_intents(state, rng)
	return state


func _fill_monsters(state: BattleState) -> void:
	for enemy: EnemyData in enemies:
		var es := EnemyState.new()
		es.combatant.hp = enemy.max_hp
		for t: MonsterTraitData in enemy.traits:
			if t is MonsterTraitArmor:
				es.armor = (t as MonsterTraitArmor).armor_amount
			elif t is MonsterTraitBlock:
				es.block = (t as MonsterTraitBlock).block_charges
		state.enemies[enemy.id] = es


func _fill_ground(state: BattleState, rng: RandomNumberGenerator) -> void:
	for row in EnemyGrid.ROWS:
		for col in EnemyGrid.COLS:
			var cs := CellState.new()
			cs.ground = GroundType.Type.PUDDLE if rng.randf() < 0.5 else GroundType.Type.SOIL
			state.cells[Vector2i(col, row)] = cs


func _fill_obstacles(state: BattleState) -> void:
	for obstacle: ObstacleData in obstacles:
		var os := ObstacleState.new()
		os.combatant.hp = obstacle.max_hp
		state.obstacles[obstacle.id] = os


func _copy_mages(state: BattleState) -> void:
	for mage: MageData in mages:
		var ms := MageState.new()
		ms.combatant.hp = maxi(1, mage.max_hp - mage.hp_penalty)
		ms.mana_spent = mage.mana_debt
		state.mages.append(ms)
		mage.hp_penalty = 0
		mage.mana_debt = 0


func get_enemy_pos(index: int, state: BattleState) -> Vector2i:
	var eid := enemies[index].id
	if state.enemies.has(eid):
		var pos := (state.enemies[eid] as EnemyState).position
		if pos != Vector2i(-1, -1):
			return pos
	return enemy_positions[index]


func get_obstacle_pos(index: int, state: BattleState) -> Vector2i:
	var oid := obstacles[index].id
	if state.obstacles.has(oid):
		var pos := (state.obstacles[oid] as ObstacleState).position
		if pos != Vector2i(-1, -1):
			return pos
	return obstacle_positions[index]


func get_occupant_at(cell: Vector2i, state: BattleState) -> String:
	for i in enemies.size():
		if not state.enemies.has(enemies[i].id):
			continue
		for c: Vector2i in EnemyGrid.get_cells_for_enemy(get_enemy_pos(i, state), enemies[i].grid_size):
			if c == cell:
				return enemies[i].id
	for i in obstacles.size():
		if not state.obstacles.has(obstacles[i].id):
			continue
		for c: Vector2i in EnemyGrid.get_cells_for_enemy(get_obstacle_pos(i, state), obstacles[i].grid_size):
			if c == cell:
				return obstacles[i].id
	return ""


func get_enemy(p_id: String) -> EnemyData:
	for enemy: EnemyData in enemies:
		if enemy.id == p_id:
			return enemy
	return null


func get_obstacle(p_id: String) -> ObstacleData:
	for obstacle: ObstacleData in obstacles:
		if obstacle.id == p_id:
			return obstacle
	return null


func get_obstacle_pos_by_id(p_id: String, state: BattleState) -> Vector2i:
	for i in obstacles.size():
		if obstacles[i].id == p_id:
			return get_obstacle_pos(i, state)
	return Vector2i(-1, -1)


func roll_intents(state: BattleState, rng: RandomNumberGenerator) -> void:
	for enemy: EnemyData in enemies:
		if not state.enemies.has(enemy.id) or enemy.action_pool.is_empty():
			continue
		var enemy_state := state.enemies[enemy.id] as EnemyState
		var action_index := enemy.pick_action_index(state, self, rng)
		var action: MonsterActionData = enemy.action_pool[action_index]
		var target := -1
		var target_name := ""
		var target_enemy_id := ""
		if action.target_type == MonsterActionData.TargetType.MAGE:
			var living: Array[int] = []
			for i in mages.size():
				if i < state.mages.size() and (state.mages[i] as MageState).combatant.hp > 0:
					living.append(i)
			if living.is_empty():
				continue
			if enemy is Banshee and not enemy_state.intent.is_empty():
				var locked: int = enemy_state.intent.get("locked_target", -1)
				target = locked if locked in living else living[rng.randi() % living.size()]
			else:
				target = living[rng.randi() % living.size()]
			target_name = mages[target].name
		elif action.target_type == MonsterActionData.TargetType.ALL_MAGES:
			target_name = "All"
		elif action.target_type == MonsterActionData.TargetType.MONSTER:
			var lowest_hp := INF
			for e: EnemyData in enemies:
				if state.enemies.has(e.id):
					var hp := (state.enemies[e.id] as EnemyState).combatant.hp
					if hp < lowest_hp:
						lowest_hp = hp
						target_enemy_id = e.id
						target_name = e.display_name
		var intent := {
			"action_index": action_index,
			"action_name": action.name,
			"target": target,
			"target_name": target_name,
		}
		if action.target_type == MonsterActionData.TargetType.ALL_MAGES:
			intent["all_mages"] = true
		if not target_enemy_id.is_empty():
			intent["target_enemy_id"] = target_enemy_id
		if enemy is Banshee and target >= 0:
			intent["locked_target"] = target
		if action is MonsterActionAttack and (action as MonsterActionAttack).applies_web \
				and target >= 0 and target < wands.size():
			var candidates: Array[SpellSlotData] = []
			for slot: SpellSlotData in wands[target].slots:
				if slot.spell != null:
					candidates.append(slot)
			if not candidates.is_empty():
				intent["webbed_slot_id"] = candidates[rng.randi_range(0, candidates.size() - 1)].id
		enemy_state.intent = intent


func apply_puddle_wet(state: BattleState) -> void:
	for i in enemies.size():
		var enemy := enemies[i]
		if not state.enemies.has(enemy.id):
			continue
		var pos := get_enemy_pos(i, state)
		for cell in EnemyGrid.get_cells_for_enemy(pos, enemy.grid_size):
			if state.get_cell(cell).ground == GroundType.Type.PUDDLE:
				state.add_enemy_status(enemy.id, StatusWet.new(2))


func spawn_enemy(enemy: EnemyData, pos: Vector2i) -> void:
	for existing: EnemyData in enemies:
		if existing.id == enemy.id:
			return
	enemies.append(enemy)
	enemy_positions.append(pos)
	for cell: Vector2i in EnemyGrid.get_cells_for_enemy(pos, enemy.grid_size):
		_cell_to_enemy[cell] = enemy.id


func _build_cell_map() -> void:
	for i in enemies.size():
		var cells := EnemyGrid.get_cells_for_enemy(enemy_positions[i], enemies[i].grid_size)
		for cell: Vector2i in cells:
			_cell_to_enemy[cell] = enemies[i].id
	for i in obstacles.size():
		var cells := EnemyGrid.get_cells_for_enemy(obstacle_positions[i], obstacles[i].grid_size)
		for cell: Vector2i in cells:
			_cell_to_enemy[cell] = obstacles[i].id
