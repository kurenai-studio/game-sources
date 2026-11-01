class_name MonsterActionSummonEnemy extends MonsterActionData

var _spawn_prefix: String
var _create_enemy: Callable


func _init(action_name: String, spawn_prefix: String, create_enemy: Callable) -> void:
	name = action_name
	target_type = TargetType.SELF
	_spawn_prefix = spawn_prefix
	_create_enemy = create_enemy


func execute(state: BattleState, setup: BattleSetup, enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	var summoner := setup.get_enemy(enemy_id)
	if summoner == null:
		return new_state
	var es := new_state.enemies.get(enemy_id) as EnemyState
	var hp_frac := float(es.combatant.hp if es != null else 0) / float(summoner.max_hp)
	var count: int
	if hp_frac < 0.25:
		count = 3
	elif hp_frac < 0.5:
		count = 2
	else:
		count = 1
	for i in count:
		var spawn_id := "%s_%s_%d" % [_spawn_prefix, enemy_id, i]
		if new_state.enemies.has(spawn_id):
			continue
		var pos := _find_free_cell(setup, new_state)
		if pos == Vector2i(-1, -1):
			break
		_spawn(setup, new_state, pos, spawn_id)
	return new_state


func _find_free_cell(setup: BattleSetup, state: BattleState) -> Vector2i:
	var occupied := {}
	for i in setup.enemies.size():
		if not state.enemies.has(setup.enemies[i].id):
			continue
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(setup.get_enemy_pos(i, state), setup.enemies[i].grid_size):
			occupied[cell] = true
	var total := EnemyGrid.ROWS * EnemyGrid.COLS
	var start := randi() % total
	for i in range(start, total):
		var pos := Vector2i(i % EnemyGrid.COLS, i / EnemyGrid.COLS)
		if not occupied.has(pos):
			return pos
	for i in range(start - 1, -1, -1):
		var pos := Vector2i(i % EnemyGrid.COLS, i / EnemyGrid.COLS)
		if not occupied.has(pos):
			return pos
	return Vector2i(-1, -1)


func _spawn(setup: BattleSetup, state: BattleState, pos: Vector2i, spawn_id: String) -> void:
	var enemy: EnemyData = _create_enemy.call()
	enemy.id = spawn_id
	setup.spawn_enemy(enemy, pos)
	var new_es := EnemyState.new()
	new_es.combatant.hp = enemy.max_hp
	state.enemies[enemy.id] = new_es
