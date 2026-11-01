class_name WarDrummer extends EnemyData

func _init() -> void:
	super("war_drummer_1", "War Drummer", 65, Vector2i(1, 1), Color(0.70, 0.35, 0.15))
	description = "A battle drummer whose war cry emboldens nearby enemies to fight harder."
	main_role = MonsterRole.Type.BUFFER
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 30
	drop_pool = [SpellAmplify.create(), SpellEmber.create()]
	action_pool = [
		MonsterActionDrumsOfWar.new(),
		MonsterActionHeal.new("War Cry", 20),
		MonsterActionSummonSkeleton.new(),
		MonsterActionSummonGoblin.new(),
	]


func pick_action_index(state: BattleState, setup: BattleSetup, rng: RandomNumberGenerator) -> int:
	if not _any_skeleton_alive(state, setup):
		for i in action_pool.size():
			if action_pool[i] is MonsterActionSummonSkeleton and action_pool[i].check_preconditions(state, setup, id):
				return i
	var valid: Array[int] = []
	for i in action_pool.size():
		if action_pool[i].check_preconditions(state, setup, id):
			valid.append(i)
	if valid.is_empty():
		return rng.randi_range(0, action_pool.size() - 1)
	return valid[rng.randi() % valid.size()]


func _any_skeleton_alive(state: BattleState, setup: BattleSetup) -> bool:
	for enemy: EnemyData in setup.enemies:
		if enemy is Skeleton and state.enemies.has(enemy.id):
			return true
	return false
