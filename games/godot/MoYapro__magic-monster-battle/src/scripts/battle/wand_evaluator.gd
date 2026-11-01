class_name WandEvaluator

# Evaluates a wand's body spell sequence at cast time.
#
# Modifiers apply their effect to the immediately next spell.
#
# Alchemy fusion happens at wand-build time (loot screen), not here.
# Catalyst spells that were not fused fire as plain projectiles.
#
# Input:  Array[SpellData] — charged body spells in column order (no tip spells).
# Output: Array[CastEvent] — resolved events to apply to the battle.


static func evaluate(spells: Array[SpellData], zap_mana_cost: int = 0) -> Array[CastEvent]:
	var events: Array[CastEvent] = []
	var pending_mods: Array[Dictionary] = []
	var last_spell: SpellData = null
	var last_count := 0
	var last_pre_mods: Array[Dictionary] = []
	var i := 0
	while i < spells.size():
		var spell: SpellData = spells[i]
		if spell.spell_type == "modifier":
			pending_mods.append(spell.modifier_effect)
			i += 1
		else:
			var count := 1
			while i + count < spells.size() and spells[i + count].spell_id == spell.spell_id:
				count += 1
			last_spell = spell
			last_count = count
			last_pre_mods = pending_mods.duplicate()
			events.append(_make_projectile(spell, pending_mods, count, zap_mana_cost))
			pending_mods = []
			i += count
	# Trailing modifiers (after the last spell group) apply back to that group
	if not pending_mods.is_empty() and last_spell != null:
		var combined: Array[Dictionary] = last_pre_mods + pending_mods
		events[events.size() - 1] = _make_projectile(last_spell, combined, last_count, zap_mana_cost)
	return events


static func _make_projectile(spell: SpellData, mods: Array[Dictionary], count: int = 1, zap_mana_cost: int = 0) -> CastEvent:
	var ev := CastEvent.new()
	ev.type = CastEvent.Type.PROJECTILE
	ev.spell = spell
	var total := 1
	for _k in count:
		total *= spell.damage
	ev.total_damage = total
	ev.on_hit_effects = spell.on_hit_effects.duplicate(true)
	ev.on_kill_effects = spell.on_kill_effects.duplicate(true)
	ev.mana_refund = 0
	ev.zap_mana_cost = zap_mana_cost
	for mod in mods:
		_apply_mod(ev, mod)
	var resolved_effects: Array[Dictionary] = []
	for effect: Dictionary in ev.on_hit_effects:
		var effect_type: String = effect.get("type", "")
		if effect.has("distance_per_cast"):
			if ev.corrupted:
				pass  # push consumed; no damage since collision damage is unknown at this stage
			else:
				effect["distance"] = count * effect.get("distance_per_cast", 1)
				effect["damage"] = ev.total_damage
				effect.erase("distance_per_cast")
				resolved_effects.append(effect)
		elif effect_type == "bounce":
			var per_cast: int = effect.get("per_cast", 1)
			if ev.corrupted:
				ev.total_damage += per_cast * count * ev.total_damage
			else:
				ev.bounces += per_cast * count
		elif effect_type == "push":
			if ev.corrupted:
				ev.total_damage += effect.get("damage", 0)
			else:
				resolved_effects.append(effect)
		elif effect_type == "shield" and count > 1:
			var scaled := 1
			var base: int = effect.get("amount", 10)
			for _k in count:
				scaled *= base
			effect["amount"] = scaled
			resolved_effects.append(effect)
		else:
			resolved_effects.append(effect)
	ev.on_hit_effects = resolved_effects
	return ev


static func _apply_mod(ev: CastEvent, mod: Dictionary) -> void:
	match mod.get("type", ""):
		"damage_mult":
			ev.total_damage = roundi(ev.total_damage * float(mod.get("factor", 1.0)))
		"add_on_hit":
			ev.on_hit_effects.append(mod.get("effect", {}))
		"mana_refund":
			ev.mana_refund += mod.get("amount", 0)
		"reactive":
			ev.reactive = true
		"distillation":
			var bonus := ev.total_damage
			for effect: Dictionary in ev.on_hit_effects:
				if effect.get("stacks_from_damage", false):
					effect["stacks"] = bonus * 2
					effect.erase("stacks_from_damage")
				elif effect.has("stacks"):
					effect["stacks"] = effect.get("stacks", 0) + bonus
				elif effect.get("type", "") == "bounce":
					effect["per_cast"] = effect.get("per_cast", 1) + bonus
				elif effect.has("distance_per_cast"):
					effect["distance_per_cast"] = effect.get("distance_per_cast", 1) + bonus
			ev.total_damage = 0
		"corrupted":
			ev.corrupted = true
			var bonus := 0
			var kept: Array[Dictionary] = []
			for effect: Dictionary in ev.on_hit_effects:
				if effect.get("stacks_from_damage", false):
					bonus += ev.total_damage
				elif effect.has("stacks"):
					bonus += effect.get("stacks", 0)
				else:
					kept.append(effect)
			ev.total_damage += bonus
			ev.on_hit_effects = kept
