# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The kept card effect ceilings (docs/ARCHITECTURE.md 5.6): stacked tower_pct effects
## never overflow, and kept effects that would take a tower stat past MAX_TOWER_STAT or
## a gold gain past MAX_GAIN are refused at load and by add_effects. Gold is held at most
## BIG, so play never makes a save that will not load.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _battle() -> Battle:
	var waves: Array = [
		{"groups": [Fx.group("pip", 6, 0, 600)]},
		{"groups": [Fx.group("pip", 6, 0, 600)]},
	]
	return Fx.battle(Fx.FORK_GRID, waves, {"start_gold": 1000}, catalog)


func _data(b: Battle) -> Dictionary:
	return JSON.parse_string(JSON.stringify(b.to_data()))


func _with(data: Dictionary, effects: Array[Dictionary]) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	copy["effects"] = effects
	return copy


func _pcts(effect: Dictionary, n: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in n:
		out.append(effect.duplicate())
	return out


## The largest damage of any Sling Post stat block with the effects.
func _sling_damage(effects: Array[Dictionary]) -> int:
	var most: int = 0
	var type: TowerType = catalog.tower(&"sling_post")
	for step: Array in [[1, -1], [2, -1], [3, 0], [3, 1]]:
		var base: TowerStats = type.stats(step[0], step[1])
		most = maxi(most, Modifiers.tower_stats(base, &"sling_post", effects, true).damage)
	return most


## The fewest copies of effect that take value past ceiling.
func _fewest_past(effect: Dictionary, value: Callable, ceiling: int) -> int:
	var n: int = 1
	while n <= Modifiers.MAX_KEPT and value.call(_pcts(effect, n)) <= ceiling:
		n += 1
	return n


func _most_bounty() -> int:
	var most: int = 1
	for id: StringName in catalog.enemy_ids():
		most = maxi(most, catalog.enemy(id).bounty)
	return most


func test_tower_pct_clamps_as_it_multiplies_and_never_overflows() -> void:
	var base: TowerStats = catalog.tower(&"sling_post").stats(1, -1)
	var damage: Array[Dictionary] = _pcts({"type": "tower_pct", "tower": "sling_post", "stat": "damage", "pct": 1000}, Modifiers.MAX_KEPT)
	assert_eq(Modifiers.tower_stats(base, &"sling_post", damage, true).damage, Modifiers.VALUE_CEILING, "64 damage effects at 1,000 percent stop at the ceiling")
	var reload: Array[Dictionary] = _pcts({"type": "tower_pct", "tower": "sling_post", "stat": "reload_ms", "pct": 1000}, Modifiers.MAX_KEPT)
	assert_eq(Modifiers.tower_stats(base, &"sling_post", reload, true).reload_ms, Modifiers.VALUE_CEILING, "and reload")
	var real: Array[Dictionary] = _pcts({"type": "tower_pct", "tower": "sling_post", "stat": "reload_ms", "pct": 80}, 1)
	assert_eq(Modifiers.tower_stats(base, &"sling_post", real, true).reload_ms, Sim.pct_half_up(base.reload_ms, 80), "a real card is unchanged")


func test_the_overflow_case_is_refused_at_load() -> void:
	var data: Dictionary = _data(_battle())
	assert_not_null(Battle.from_data(data, catalog), "the base data is valid")
	for stat: String in ["damage", "reload_ms"]:
		var effects: Array[Dictionary] = _pcts({"type": "tower_pct", "tower": "sling_post", "stat": stat, "pct": 1000}, Modifiers.MAX_KEPT)
		assert_null(Battle.from_data(_with(data, effects), catalog), "64 %s effects at 1,000 percent" % stat)
	for type: String in ["bounty_pct", "clear_bonus_pct"]:
		assert_null(Battle.from_data(_with(data, _pcts({"type": type, "pct": 1000}, Modifiers.MAX_KEPT)), catalog), "64 %s at 1,000 percent" % type)


func test_only_stacked_tower_pct_can_pass_the_stat_ceiling() -> void:
	var data: Dictionary = _data(_battle())
	for stat: String in Modifiers.TOWER_ADD_STATS:
		var effects: Array[Dictionary] = _pcts({"type": "tower_add", "tower": "sling_post", "stat": stat, "amount": 1000}, Modifiers.MAX_KEPT)
		assert_not_null(Battle.from_data(_with(data, effects), catalog), "64 tower_add %s at 1,000 load" % stat)
	var cost: Array[Dictionary] = _pcts({"type": "cost_add", "build": 1000, "upgrade": 1000}, Modifiers.MAX_KEPT)
	assert_not_null(Battle.from_data(_with(data, cost), catalog), "64 cost_add at 1,000 load")
	var damage: Dictionary = {"type": "tower_pct", "tower": "sling_post", "stat": "damage", "pct": 1000}
	var past: int = _fewest_past(damage, _sling_damage, Battle.MAX_TOWER_STAT)
	assert_true(past >= 2 and past <= Modifiers.MAX_KEPT, "some count passes: %d" % past)
	assert_not_null(Battle.from_data(_with(data, _pcts(damage, past - 1)), catalog), "%d damage effects stay inside" % (past - 1))
	assert_null(Battle.from_data(_with(data, _pcts(damage, past)), catalog), "%d damage effects pass %d" % [past, Battle.MAX_TOWER_STAT])


func test_a_gold_gain_past_the_ceiling_is_refused() -> void:
	var data: Dictionary = _data(_battle())
	var most: int = _most_bounty()
	var bounty: Dictionary = {"type": "bounty_pct", "pct": 1000}
	var past: int = _fewest_past(bounty, func(e: Array[Dictionary]) -> int: return Modifiers.scale_all(e, "bounty_pct", most), Battle.MAX_GAIN)
	assert_true(past >= 2 and past <= Modifiers.MAX_KEPT, "some count passes: %d" % past)
	assert_not_null(Battle.from_data(_with(data, _pcts(bounty, past - 1)), catalog), "%d bounty effects stay inside" % (past - 1))
	assert_null(Battle.from_data(_with(data, _pcts(bounty, past)), catalog), "%d bounty effects pass %d" % [past, Battle.MAX_GAIN])
	var rules: GameRules = catalog.rules
	var last_bonus: int = rules.clear_bonus + rules.clear_bonus_per_wave * 2
	var feast: Dictionary = {"type": "clear_bonus_pct", "pct": 1000}
	var bonus_past: int = _fewest_past(feast, func(e: Array[Dictionary]) -> int: return Modifiers.scale_all(e, "clear_bonus_pct", last_bonus), Battle.MAX_GAIN)
	assert_not_null(Battle.from_data(_with(data, _pcts(feast, bonus_past - 1)), catalog), "%d clear bonus effects stay inside" % (bonus_past - 1))
	assert_null(Battle.from_data(_with(data, _pcts(feast, bonus_past)), catalog), "%d clear bonus effects pass %d" % [bonus_past, Battle.MAX_GAIN])


func test_add_effects_refuses_kept_effects_past_a_ceiling() -> void:
	var b: Battle = _battle()
	var damage: Dictionary = {"type": "tower_pct", "tower": "sling_post", "stat": "damage", "pct": 1000}
	var past: int = _fewest_past(damage, _sling_damage, Battle.MAX_TOWER_STAT)
	assert_eq(b.add_effects(_pcts(damage, past - 1), false), Battle.DONE, "up to the edge")
	var gold_before: int = b.gold
	var with_gold: Array[Dictionary] = _pcts(damage, 1)
	with_gold.append({"type": "add_gold", "amount": 100, "per_wave": 0})
	assert_eq(b.add_effects(with_gold, false), &"bad_effect", "one more passes %d" % Battle.MAX_TOWER_STAT)
	assert_eq(b.card_effects.size(), past - 1, "nothing more is kept")
	assert_eq(b.gold, gold_before, "and the instant gold is not given")
	var fresh: Battle = _battle()
	assert_eq(fresh.add_effects(_pcts({"type": "bounty_pct", "pct": 1000}, Modifiers.MAX_TWIST), false), &"bad_effect", "8 bounty effects at 1,000 percent")
	assert_eq(fresh.add_effects(_pcts({"type": "bounty_pct", "pct": 120}, 1), false), Battle.DONE, "a real card")


func test_gold_is_held_at_big_so_the_save_still_loads() -> void:
	var b: Battle = _battle()
	assert_eq(b.place_tower(Vector2i(3, 3), &"sling_post"), Battle.DONE)
	assert_eq(b.place_tower(Vector2i(3, 5), &"sling_post"), Battle.DONE)
	b.gold = Battle.BIG - 1
	assert_eq(b.start_next_wave(), Battle.DONE)
	var defeated: int = 0
	var ran: int = 0
	while b.phase == Battle.Phase.WAVE and ran < 20000:
		b.step()
		defeated += Fx.events_of(b.take_events(), &"defeated").size()
		ran += 1
	assert_true(defeated >= 2, "creatures were defeated: %d" % defeated)
	assert_eq(b.gold, Battle.BIG, "gold stops at %d" % Battle.BIG)
	assert_not_null(Battle.from_data(_data(b), catalog), "and the save loads")
	assert_eq(b.sell_tower(Vector2i(3, 3)), Battle.DONE)
	assert_eq(b.gold, Battle.BIG, "a refund too")
