extends GutTest


func _make_setup(extras: Array[EnemyData] = [], extra_positions: Array[Vector2i] = []) -> BattleSetup:
	var enemies: Array[EnemyData] = [WarDrummer.new()]
	var positions: Array[Vector2i] = [Vector2i(1, 0)]
	enemies.append_array(extras)
	positions.append_array(extra_positions)
	return BattleSetup.new(enemies, positions, [], [], 10)


func _raise_fallen_index() -> int:
	var drummer := WarDrummer.new()
	for i in drummer.action_pool.size():
		if drummer.action_pool[i] is MonsterActionSummonSkeleton:
			return i
	return -1


func _make_state_with_drummer() -> BattleState:
	var s := BattleState.new()
	var es := EnemyState.new()
	es.combatant.hp = 65
	s.enemies["war_drummer_1"] = es
	return s


func test_forces_raise_fallen_when_no_skeletons_alive() -> void:
	var setup := _make_setup()
	var state := _make_state_with_drummer()
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var idx := WarDrummer.new().pick_action_index(state, setup, rng)
	assert_eq(idx, _raise_fallen_index())


func test_rolls_randomly_when_skeleton_alive() -> void:
	var skeleton := Skeleton.new()
	var setup := _make_setup([skeleton], [Vector2i(0, 0)])
	var state := _make_state_with_drummer()
	var ses := EnemyState.new()
	ses.combatant.hp = 30
	state.enemies["skeleton_1"] = ses
	var raise_idx := _raise_fallen_index()
	var seen_other := false
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	for i in 50:
		var idx := WarDrummer.new().pick_action_index(state, setup, rng)
		if idx != raise_idx:
			seen_other = true
			break
	assert_true(seen_other)


func test_forces_raise_fallen_when_skeleton_dead() -> void:
	var skeleton := Skeleton.new()
	var setup := _make_setup([skeleton], [Vector2i(0, 0)])
	var state := _make_state_with_drummer()
	var rng := RandomNumberGenerator.new()
	rng.seed = 0
	var idx := WarDrummer.new().pick_action_index(state, setup, rng)
	assert_eq(idx, _raise_fallen_index())
