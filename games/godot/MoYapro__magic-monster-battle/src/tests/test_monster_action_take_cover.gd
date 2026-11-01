extends GutTest


func _make_setup_with_obstacle(
	enemy_pos: Vector2i, obs_pos: Vector2i, obs_size: Vector2i = Vector2i(1, 1)
) -> BattleSetup:
	var enemies: Array[EnemyData] = [Goblin.new()]
	enemies[0].id = "goblin_a"
	var obstacle := ObstacleData.new("rock_1", "Rock", obs_size, Color.GRAY, 30)
	return BattleSetup.new(enemies, [enemy_pos], [], [], 10, [obstacle], [obs_pos])


func _make_setup_with_ally(enemy_pos: Vector2i, ally_pos: Vector2i) -> BattleSetup:
	var enemies: Array[EnemyData] = [Goblin.new(), Goblin.new()]
	enemies[0].id = "goblin_a"
	enemies[1].id = "goblin_b"
	return BattleSetup.new(enemies, [enemy_pos, ally_pos], [], [], 10)


func _make_state(extra_ids: Array = []) -> BattleState:
	var s := BattleState.new()
	var es := EnemyState.new()
	es.combatant.hp = 30
	s.enemies["goblin_a"] = es
	for id in extra_ids:
		var xes := EnemyState.new()
		xes.combatant.hp = 30
		s.enemies[id] = xes
	return s


func _add_obstacle(state: BattleState, obstacle_id: String, hp: int) -> void:
	var os := ObstacleState.new()
	os.combatant.hp = hp
	state.obstacles[obstacle_id] = os


func test_moves_behind_obstacle() -> void:
	var setup := _make_setup_with_obstacle(Vector2i(0, 0), Vector2i(2, 2))
	var state := _make_state()
	_add_obstacle(state, "rock_1", 30)
	var result := MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.get_enemy_pos(0, result), Vector2i(3, 2))


func test_moves_behind_ally() -> void:
	var setup := _make_setup_with_ally(Vector2i(0, 0), Vector2i(1, 1))
	var state := _make_state(["goblin_b"])
	var result := MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.get_enemy_pos(0, result), Vector2i(2, 1))


func test_picks_closest_cover() -> void:
	var enemies: Array[EnemyData] = [Goblin.new()]
	enemies[0].id = "goblin_a"
	var obs1 := ObstacleData.new("rock_1", "Rock", Vector2i(1, 1), Color.GRAY, 30)
	var obs2 := ObstacleData.new("rock_2", "Rock", Vector2i(1, 1), Color.GRAY, 30)
	var setup := BattleSetup.new(
		enemies, [Vector2i(0, 0)], [], [], 10,
		[obs1, obs2], [Vector2i(1, 0), Vector2i(3, 0)]
	)
	var state := _make_state()
	_add_obstacle(state, "rock_1", 30)
	_add_obstacle(state, "rock_2", 30)
	var result := MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.get_enemy_pos(0, result), Vector2i(2, 0))


func test_does_not_move_when_behind_is_out_of_bounds() -> void:
	var setup := _make_setup_with_obstacle(Vector2i(0, 0), Vector2i(EnemyGrid.COLS - 1, 0))
	var state := _make_state()
	_add_obstacle(state, "rock_1", 30)
	var result := MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.get_enemy_pos(0, result), Vector2i(0, 0))


func test_does_not_move_when_behind_is_occupied() -> void:
	var obs_col := EnemyGrid.COLS - 2
	var ally_col := EnemyGrid.COLS - 1
	var enemies: Array[EnemyData] = [Goblin.new(), Goblin.new()]
	enemies[0].id = "goblin_a"
	enemies[1].id = "goblin_b"
	var obstacle := ObstacleData.new("rock_1", "Rock", Vector2i(1, 1), Color.GRAY, 30)
	var setup := BattleSetup.new(
		enemies, [Vector2i(0, 0), Vector2i(ally_col, 0)], [], [], 10,
		[obstacle], [Vector2i(obs_col, 0)]
	)
	var state := _make_state(["goblin_b"])
	_add_obstacle(state, "rock_1", 30)
	var result := MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.get_enemy_pos(0, result), Vector2i(0, 0))


func test_does_not_move_behind_dead_obstacle() -> void:
	var setup := _make_setup_with_obstacle(Vector2i(0, 0), Vector2i(2, 2))
	var state := _make_state()
	var result := MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.get_enemy_pos(0, result), Vector2i(0, 0))
