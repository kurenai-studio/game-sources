class_name ActionEndTurn extends BattleAction

var _rng_seed: int


func _init(rng_seed: int) -> void:
	_rng_seed = rng_seed


func apply(state: BattleState, setup: BattleSetup) -> ActionResult:
	var result := ActionResult.new()
	var new_state := state.duplicate()

	# Resolve each monster's queued intent
	for enemy_id: String in new_state.enemies.keys():
		var enemy_state := new_state.enemies.get(enemy_id) as EnemyState
		if enemy_state == null or enemy_state.intent.is_empty():
			continue
		var enemy := setup.get_enemy(enemy_id)
		if enemy == null or enemy.action_pool.is_empty():
			continue
		if enemy_state.combatant.statuses.any(func(s: StatusData) -> bool: return s.blocks_action()):
			continue
		if enemy_state.stunned_turns > 0:
			enemy_state.stunned_turns -= 1
			continue
		var intent: Dictionary = enemy_state.intent
		var action_index: int = intent.get("action_index", 0)
		var target: int = intent.get("target", -1)
		var action: MonsterActionData = enemy.action_pool[action_index]
		var execute_id: String = intent.get("target_enemy_id", enemy_id)
		new_state = action.execute(new_state, setup, execute_id, target)
		var webbed_slot_id: String = intent.get("webbed_slot_id", "")
		if not webbed_slot_id.is_empty() and target >= 0 and target < new_state.mages.size():
			(new_state.mages[target] as MageState).webbed_slots[webbed_slot_id] = true

	# Apply end-of-round traits (regen, armor refresh, etc.)
	for enemy: EnemyData in setup.enemies:
		if not new_state.enemies.has(enemy.id):
			continue
		for t: MonsterTraitData in enemy.traits:
			new_state = t.apply_end_of_round(new_state, setup, enemy.id) as BattleState

	# Puddle cells apply wet(2) to any monster standing on them
	setup.apply_puddle_wet(new_state)

	# Mage status turn-end effects
	for i in new_state.mages.size():
		var target := StatusTarget.for_mage(new_state, i)
		for status: StatusData in target.get_statuses().duplicate():
			status.on_turn_end(target, setup)

	# Enemy status turn-end effects
	for enemy_id: String in new_state.enemies.keys():
		if not new_state.enemies.has(enemy_id):
			continue
		var target := StatusTarget.for_enemy(new_state, enemy_id)
		for status: StatusData in target.get_statuses().duplicate():
			status.on_turn_end(target, setup)

	# Reset turn resources
	for enemy_id: String in new_state.enemies:
		(new_state.enemies[enemy_id] as EnemyState).attack_mult = 1.0
	for ms: MageState in new_state.mages:
		ms.webbed_slots.clear()
		ms.mana_spent = 0
	new_state.mana = setup.max_mana

	# Roll next round intents
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng_seed
	setup.roll_intents(new_state, rng)

	result.state = new_state
	return result
