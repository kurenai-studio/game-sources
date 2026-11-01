class_name ActionZapWand extends BattleAction

var mage_index: int
var target_cell: Vector2i
var target_mage_index: int = -1  # >= 0 when targeting a mage instead of an enemy cell


func _init(p_mage_index: int, p_target_cell: Vector2i, p_target_mage: int = -1) -> void:
	mage_index = p_mage_index
	target_cell = p_target_cell
	target_mage_index = p_target_mage


func apply(state: BattleState, setup: BattleSetup) -> ActionResult:
	var result := ActionResult.new()
	var new_state := state.duplicate()
	var ms := new_state.mages[mage_index] as MageState
	if ms.combatant.statuses.any(func(s: StatusData) -> bool: return s.blocks_action()):
		result.state = new_state
		return result
	var zap_target := StatusTarget.for_mage(new_state, mage_index)
	for status: StatusData in ms.combatant.statuses.duplicate():
		status.on_zap(zap_target, setup)
	if ms.mana_spent > setup.mages[mage_index].mana_allowance:
		result.state = new_state
		return result
	var wand := setup.wands[mage_index]
	var pattern := _get_hit_pattern(wand, new_state)
	var zap_mana_cost := _sum_slot_charges(wand, new_state)
	var cast_events := WandEvaluator.evaluate(_get_charged_body_spells(wand, new_state), zap_mana_cost)
	for ev: CastEvent in cast_events:
		match ev.type:
			CastEvent.Type.PROJECTILE:
				if target_mage_index >= 0:
					_apply_projectile_to_mage(new_state, ev, target_mage_index, pattern)
				else:
					var push_dir := pattern[1] if pattern.size() > 1 else Vector2i(1, 0)
					var bounce_dir := pattern[1] if pattern.size() > 1 else Vector2i.ZERO
					_apply_projectile(new_state, setup, ev, pattern, push_dir, bounce_dir)
			CastEvent.Type.BACKFIRE:
				_apply_backfire(new_state, mage_index, ev)
			CastEvent.Type.FIZZLE:
				pass
	result.cast_events = cast_events
	for slot: SpellSlotData in wand.slots:
		(new_state.mages[mage_index] as MageState).slot_charges.erase(slot.id)
	result.state = new_state
	return result


func _get_hit_pattern(wand: WandData, state: BattleState) -> Array[Vector2i]:
	var tip_slot := wand.get_tip_slot()
	if tip_slot == null or tip_slot.spell == null:
		return [Vector2i(0, 0)]
	var ms := state.mages[mage_index] as MageState
	var tip_charges: int = ms.slot_charges.get(tip_slot.id, 0)
	if tip_charges >= tip_slot.spell.mana_cost and not tip_slot.spell.hit_pattern.is_empty():
		return tip_slot.spell.hit_pattern
	return [Vector2i(0, 0)]


func _get_charged_body_spells(wand: WandData, state: BattleState) -> Array[SpellData]:
	var ms := state.mages[mage_index] as MageState
	var body_slots: Array[SpellSlotData] = []
	for slot: SpellSlotData in wand.slots:
		if slot.is_tip or slot.spell == null:
			continue
		if ms.webbed_slots.has(slot.id) or ms.slot_charges.get(slot.id, 0) < slot.spell.mana_cost:
			continue
		body_slots.append(slot)
	body_slots.sort_custom(func(a: SpellSlotData, b: SpellSlotData) -> bool:
		return a.grid_col < b.grid_col if a.grid_col != b.grid_col else a.grid_row < b.grid_row)
	var spells: Array[SpellData] = []
	for slot: SpellSlotData in body_slots:
		spells.append(slot.spell)
	return spells


func _sum_slot_charges(wand: WandData, state: BattleState) -> int:
	var ms := state.mages[mage_index] as MageState
	var total := 0
	for slot: SpellSlotData in wand.slots:
		total += ms.slot_charges.get(slot.id, 0)
	return total


func _apply_on_kill_effects(state: BattleState, setup: BattleSetup, ev: CastEvent) -> void:
	for effect: Dictionary in ev.on_kill_effects:
		match effect.get("type", ""):
			"refund_zap_mana":
				var refund := ev.zap_mana_cost
				ev.zap_mana_cost = 0
				var ms := state.mages[mage_index] as MageState
				state.mana = mini(state.mana + refund, setup.max_mana)
				ms.mana_spent = maxi(ms.mana_spent - refund, 0)


func _apply_projectile(
		state: BattleState, setup: BattleSetup, ev: CastEvent, pattern: Array[Vector2i],
		push_dir: Vector2i = Vector2i(1, 0), bounce_dir: Vector2i = Vector2i.ZERO) -> void:
	var hit_ids: Dictionary = {}
	var hit_cells: Array[Vector2i] = []
	if ev.corrupted and pattern.size() > 1:
		hit_cells.append(target_cell)
	else:
		hit_cells = EnemyGrid.get_hit_cells(target_cell, pattern)
	for cell: Vector2i in hit_cells:
		var eid: String = setup.get_occupant_at(cell, state)
		if eid.is_empty() or hit_ids.has(eid):
			continue
		if state.obstacles.has(eid):
			_apply_damage_to_obstacle(state, setup, eid, ev, push_dir)
			hit_ids[eid] = true
			continue
		if not state.enemies.has(eid):
			continue
		hit_ids[eid] = true
		if _try_consume_block(state, eid):
			continue
		_apply_damage_to_enemy(state, setup, eid, ev, push_dir)
	if ev.bounces > 0:
		_apply_bounces(state, setup, ev, hit_ids, push_dir, bounce_dir)


func _try_consume_block(state: BattleState, eid: String) -> bool:
	var es := state.enemies.get(eid) as EnemyState
	if es == null or es.block <= 0:
		return false
	es.block -= 1
	return true


func _apply_damage_to_obstacle(
		state: BattleState, setup: BattleSetup, eid: String,
		ev: CastEvent, push_dir: Vector2i) -> void:
	var os := state.obstacles[eid] as ObstacleState
	os.combatant.hp -= ev.total_damage
	var obstacle := setup.get_obstacle(eid)
	if obstacle:
		obstacle.on_hit(state, setup, ev)
	if os.combatant.hp <= 0:
		state.obstacles.erase(eid)
		if obstacle:
			obstacle.on_destroyed(state, setup, ev)
		return
	for effect: Dictionary in ev.on_hit_effects:
		if effect.get("type", "") == "push":
			_push_occupant(state, setup, eid,
					effect.get("distance", 1), effect.get("damage", 0), push_dir)


func _consume_status_stacks(state: BattleState, eid: String) -> int:
	var es := state.enemies.get(eid) as EnemyState
	if es == null:
		return 0
	var bonus := 0
	var kept: Array[StatusData] = []
	for status: StatusData in es.combatant.statuses:
		if (status is StatusFire or status is StatusPoison or status is StatusWet) and status.stacks > 0:
			bonus += status.stacks
		else:
			kept.append(status)
	es.combatant.statuses = kept
	return bonus


func _resolve_reactive(state: BattleState, eid: String, ev: CastEvent) -> Dictionary:
	var es := state.enemies.get(eid) as EnemyState
	var statuses: Array = es.combatant.statuses if es != null else []
	match ev.spell.spell_id:
		"ember":
			for status: StatusData in statuses:
				if status is StatusFire:
					return {"bonus": status.stacks, "effects": ev.on_hit_effects}
		"frost":
			for status: StatusData in statuses:
				if status is StatusWet:
					return {"bonus": status.stacks, "effects": ev.on_hit_effects}
		"venom":
			for status: StatusData in statuses:
				if status is StatusPoison:
					var burst := status.stacks
					es.combatant.statuses = es.combatant.statuses.filter(
							func(s: StatusData) -> bool: return not (s is StatusPoison))
					var kept_e: Array[Dictionary] = []
					for e: Dictionary in ev.on_hit_effects:
						if e.get("type", "") != "poison":
							kept_e.append(e)
					return {"bonus": burst, "effects": kept_e}
	return {"bonus": 0, "effects": ev.on_hit_effects}


func _apply_damage_to_enemy(
		state: BattleState, setup: BattleSetup, eid: String,
		ev: CastEvent, push_dir: Vector2i) -> void:
	var es := state.enemies[eid] as EnemyState
	var corruption_bonus := _consume_status_stacks(state, eid) if ev.corrupted else 0
	var reactive_result := _resolve_reactive(state, eid, ev) if ev.reactive else {"bonus": 0, "effects": ev.on_hit_effects}
	var total := ev.total_damage + corruption_bonus + reactive_result.get("bonus", 0) as int
	var remaining := _absorb_armor(es, total)
	remaining = es.combatant.absorb_shield(remaining)
	es.combatant.hp -= remaining
	if es.combatant.hp <= 0:
		state.kill_enemy(eid, setup)
		_apply_on_kill_effects(state, setup, ev)
	else:
		var effects: Array[Dictionary] = reactive_result.get("effects", ev.on_hit_effects)
		_apply_on_hit_effects(state, setup, eid, effects, total, push_dir)


func _score_bounce_candidate(target: Vector2i, from: Vector2i, bounce_dir: Vector2i) -> int:
	var diff := target - from
	if bounce_dir == Vector2i.ZERO:
		return -(abs(diff.x) + abs(diff.y))
	return diff.x * bounce_dir.x + diff.y * bounce_dir.y


func _apply_bounces(
		state: BattleState, setup: BattleSetup, ev: CastEvent,
		hit_ids: Dictionary, push_dir: Vector2i,
		bounce_dir: Vector2i = Vector2i.ZERO) -> void:
	if ev.reactive and ev.spell.spell_id == "lightning":
		for enemy: EnemyData in setup.enemies:
			if not state.enemies.has(enemy.id) or hit_ids.has(enemy.id):
				continue
			var wet := false
			for s: StatusData in (state.enemies[enemy.id] as EnemyState).combatant.statuses:
				if s is StatusWet:
					wet = true
					break
			if not wet:
				continue
			hit_ids[enemy.id] = true
			if not _try_consume_block(state, enemy.id):
				_apply_damage_to_enemy(state, setup, enemy.id, ev, push_dir)
		return
	var last_pos := target_cell
	for _bounce in range(ev.bounces):
		var candidates: Array[String] = []
		for enemy: EnemyData in setup.enemies:
			if state.enemies.has(enemy.id) and not hit_ids.has(enemy.id):
				candidates.append(enemy.id)
		for obstacle: ObstacleData in setup.obstacles:
			if state.obstacles.has(obstacle.id) and not hit_ids.has(obstacle.id):
				candidates.append(obstacle.id)
		if candidates.is_empty():
			break
		var next_id := candidates[0]
		var next_pos: Vector2i = _get_occupant_push_info(setup, state, next_id)["pos"]
		var best_score: int = _score_bounce_candidate(next_pos, last_pos, bounce_dir)
		for j in range(1, candidates.size()):
			var cid: String = candidates[j]
			var cpos: Vector2i = _get_occupant_push_info(setup, state, cid)["pos"]
			var score: int = _score_bounce_candidate(cpos, last_pos, bounce_dir)
			if score > best_score:
				best_score = score
				next_id = cid
				next_pos = cpos
		last_pos = next_pos
		hit_ids[next_id] = true
		if state.obstacles.has(next_id):
			_apply_damage_to_obstacle(state, setup, next_id, ev, push_dir)
		elif not _try_consume_block(state, next_id):
			_apply_damage_to_enemy(state, setup, next_id, ev, push_dir)


func _absorb_armor(es: EnemyState, damage: int) -> int:
	if es.armor <= 0:
		return damage
	var absorbed := mini(es.armor, damage)
	es.armor -= absorbed
	return damage - absorbed


func _apply_on_hit_effects(
		state: BattleState, setup: BattleSetup, eid: String,
		effects: Array[Dictionary], total_damage: int,
		push_dir: Vector2i = Vector2i(1, 0)) -> void:
	for effect: Dictionary in effects:
		var stacks: int = total_damage if effect.get("stacks_from_damage", false) \
				else effect.get("stacks", 1)
		match effect.get("type", ""):
			"fire":
				state.add_enemy_status(eid, StatusFire.new(stacks))
			"wet":
				state.add_enemy_status(eid, StatusWet.new(stacks))
			"poison":
				var enemy := setup.get_enemy(eid)
				var immune := enemy != null and enemy.traits.any(
						func(t: MonsterTraitData) -> bool: return t is MonsterTraitPoisonImmunity)
				if not immune:
					state.add_enemy_status(eid, StatusPoison.new(stacks))
			"freeze":
				state.add_enemy_status(eid, StatusFrozen.new())
			"stun":
				(state.enemies[eid] as EnemyState).stunned_turns = effect.get("turns", 1)
			"blind":
				state.add_enemy_status(eid, StatusBlind.new())
				(state.enemies[eid] as EnemyState).intent = {}
			"push":
				_push_occupant(state, setup, eid,
						effect.get("distance", 1), effect.get("damage", 0), push_dir)
			"shield":
				(state.enemies[eid] as EnemyState).combatant.shield += effect.get("amount", 10)
			"cleanse_poison":
				var es := state.enemies.get(eid) as EnemyState
				if es != null:
					es.combatant.statuses.assign(es.combatant.statuses.filter(
							func(s: StatusData) -> bool: return not (s is StatusPoison)))


func _apply_projectile_to_mage(
		state: BattleState, ev: CastEvent, target_idx: int,
		pattern: Array[Vector2i] = [Vector2i(0, 0)]) -> void:
	var hit_indices: Dictionary = {}
	for offset: Vector2i in pattern:
		hit_indices[target_idx + offset.y] = true
	for idx: int in hit_indices:
		if idx < 0 or idx >= state.mages.size():
			continue
		var ms := state.mages[idx] as MageState
		if not ms.combatant.is_alive():
			continue
		var remaining := ev.total_damage
		if remaining > 0:
			remaining = ms.combatant.absorb_shield(remaining)
		if remaining > 0:
			ms.combatant.hp = max(0, ms.combatant.hp - remaining)
		if ms.combatant.hp > 0:
			_apply_on_hit_effects_to_mage(state, idx, ev.on_hit_effects, ev.total_damage)


func _apply_on_hit_effects_to_mage(
		state: BattleState, target_idx: int,
		effects: Array[Dictionary], total_damage: int) -> void:
	for effect: Dictionary in effects:
		var stacks: int = total_damage if effect.get("stacks_from_damage", false) \
				else effect.get("stacks", 1)
		match effect.get("type", ""):
			"fire":
				state.add_mage_status(target_idx, StatusFire.new(stacks))
			"wet":
				state.add_mage_status(target_idx, StatusWet.new(stacks))
			"poison":
				state.add_mage_status(target_idx, StatusPoison.new(stacks))
			"freeze":
				state.add_mage_status(target_idx, StatusFrozen.new())
			"stun":
				state.add_mage_status(target_idx, StatusFrozen.new())
			"shield":
				(state.mages[target_idx] as MageState).combatant.shield += effect.get("amount", 10)
			"blind":
				pass
			"cleanse_poison":
				var ms := state.mages[target_idx] as MageState
				ms.combatant.statuses.assign(ms.combatant.statuses.filter(
						func(s: StatusData) -> bool: return not (s is StatusPoison)))


func _get_occupant_push_info(setup: BattleSetup, state: BattleState, id: String) -> Dictionary:
	for i in setup.enemies.size():
		if setup.enemies[i].id == id:
			return {"grid_size": setup.enemies[i].grid_size, "pos": setup.get_enemy_pos(i, state), "is_enemy": true}
	for i in setup.obstacles.size():
		if setup.obstacles[i].id == id:
			return {"grid_size": setup.obstacles[i].grid_size, "pos": setup.get_obstacle_pos(i, state), "is_enemy": false}
	return {}


func _push_occupant(
		state: BattleState, setup: BattleSetup, id: String,
		distance: int, collision_damage: int,
		push_dir: Vector2i = Vector2i(1, 0)) -> void:
	var info := _get_occupant_push_info(setup, state, id)
	if info.is_empty():
		return
	var pos: Vector2i = info["pos"]
	var grid_size: Vector2i = info["grid_size"]
	var is_enemy: bool = info["is_enemy"]
	for _step in distance:
		var new_pos := pos + push_dir
		if not EnemyGrid.is_within_bounds(new_pos, grid_size):
			break
		var blocker_id := ""
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(new_pos, grid_size):
			var occupant := setup.get_occupant_at(cell, state)
			if occupant != "" and occupant != id:
				blocker_id = occupant
				break
		if blocker_id != "":
			_deal_collision_damage(state, setup, id, collision_damage)
			_deal_collision_damage(state, setup, blocker_id, collision_damage)
			break
		pos = new_pos
		if is_enemy:
			(state.enemies[id] as EnemyState).position = pos
		else:
			(state.obstacles[id] as ObstacleState).position = pos


func _deal_collision_damage(state: BattleState, setup: BattleSetup, target_id: String, damage: int) -> void:
	if state.enemies.has(target_id):
		var es := state.enemies[target_id] as EnemyState
		var remaining := es.combatant.absorb_shield(damage)
		es.combatant.hp -= remaining
		if es.combatant.hp <= 0:
			state.kill_enemy(target_id, setup)
	elif state.obstacles.has(target_id):
		var os := state.obstacles[target_id] as ObstacleState
		os.combatant.hp -= damage
		if os.combatant.hp <= 0:
			state.obstacles.erase(target_id)


func _apply_backfire(state: BattleState, mage_idx: int, ev: CastEvent) -> void:
	var ms := state.mages[mage_idx] as MageState
	ms.combatant.hp = max(0, ms.combatant.hp - ev.backfire_damage)
	for effect: Dictionary in ev.backfire_effects:
		match effect.get("type", ""):
			"stun":
				state.add_mage_status(mage_idx, StatusFrozen.new())
			"fire":
				state.add_mage_status(mage_idx, StatusFire.new(effect.get("stacks", 1)))
			"poison":
				state.add_mage_status(mage_idx, StatusPoison.new(effect.get("stacks", 1)))
