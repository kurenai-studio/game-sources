# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Save, restore and determinism with every tower, creature, boss, Twist, card and risk
## effect, and hostile saved data for every field they add (docs/ARCHITECTURE.md 5.6;
## RULES 4.10, 5 to 8, 13, 14.5, 14.6).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const LIMIT: int = 40000
const ALL_TOWERS: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery"]

## Two equal branches (west by the tie break), three sockets, eleven spots.
const GRID: Array = [
	"...1...",
	".oo#oo.",
	".#####.",
	".G.o.G.",
	".#ooo#.",
	".#...#.",
	".G.o.#.",
	".#...#.",
	".#####.",
	"..oBo..",
]

## Twist effects for the second run: every kind that changes a battle in play.
const TWIST: Array = [
	{"type": "all_bubbles"},
	{"type": "break_ms", "enemy": "gatecrasher", "ms": 2000},
	{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true},
	{"type": "armor_add", "amount": 1},
	{"type": "speed_pct", "pct": 110},
	{"type": "fixed_gates", "cells": [[1, 3]]},
]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _level() -> LevelData:
	var waves: Array = [
		{"groups": [Fx.group("scamp", 6, 0, 600), Fx.group("bubbler", 2, 1000, 1500), Fx.group("flitter", 3, 2000, 400)]},
		{"groups": [Fx.group("puffball", 3, 0, 1500), Fx.group("scamp", 5, 500, 600), Fx.group("mender", 1, 2000, 1000), Fx.group("pip", 10, 3000, 200)]},
		{"strength": 500, "groups": [Fx.group("shellback", 3, 0, 1500), Fx.group("gatecrasher", 1, 500, 1000), Fx.group("dusk_moth", 2, 2000, 1500)]},
		{"strength": 60, "groups": [Fx.group("ironshell", 1), Fx.group("scamp", 6, 1000, 800), Fx.group("mender", 1, 1500, 1000)]},
		{"groups": [Fx.group("moon_moth", 1), Fx.group("flitter", 4, 1000, 400), Fx.group("mender", 2, 0, 3000), Fx.group("skitter", 4, 500, 700)]},
		{"strength": 100, "groups": [Fx.group("old_tusk", 1), Fx.group("puffball", 2, 2000, 2000), Fx.group("dusk_moth", 2, 4000, 2000)]},
	]
	return Fx.level(GRID, waves, {"start_gold": 30000, "gates": 2, "strength": 100, "towers": ALL_TOWERS,
		"star3": {"kind": "gates_whole"}}, catalog)


func _effects(list: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for effect: Dictionary in list:
		typed.append(effect)
	return typed


func _full(b: Battle, cell: Vector2i, type: StringName, spec: int) -> void:
	b.place_tower(cell, type)
	b.upgrade_tower(cell)
	b.upgrade_tower(cell, spec)


## The player's commands. They depend only on the battle's state, so a restored battle
## gets the same commands at the same moments. Build phases come before waves 0, 2, 3
## and 5; waves 1 and 4 are called early.
func _act(b: Battle) -> void:
	if b.phase == Battle.Phase.BUILD:
		match b.waves_started:
			0:
				_full(b, Vector2i(2, 1), &"sling_post", 0)
				b.place_tower(Vector2i(4, 1), &"pumpkin_catapult")
				b.upgrade_tower(Vector2i(4, 1))
				b.place_tower(Vector2i(3, 3), &"lullaby_bell")
				b.place_tower(Vector2i(3, 4), &"longbow_loft")
				b.upgrade_tower(Vector2i(3, 4))
				b.place_tower(Vector2i(2, 4), &"bakery")
				b.place_tower(Vector2i(4, 4), &"firework_tower")
				b.upgrade_tower(Vector2i(4, 4))
				_full(b, Vector2i(5, 1), &"firework_tower", 0)
				b.place_gate(Vector2i(1, 3))
				b.place_gate(Vector2i(1, 6))
			2:
				b.add_effects(_effects([{"type": "tower_add", "tower": "sling_post", "stat": "damage", "amount": 2}, {"type": "bounty_pct", "pct": 120}]), false)
				b.add_effects(_effects([{"type": "count_pct", "pct": 150, "flyers": false, "last_wave": false}, {"type": "reward_gold", "amount": 100}]), true)
				b.upgrade_tower(Vector2i(3, 3))
				b.upgrade_tower(Vector2i(3, 3), 1)
				b.upgrade_tower(Vector2i(4, 1), 1)
				b.set_aim(Vector2i(3, 4), TowerState.Aim.STRONG)
			3:
				b.upgrade_tower(Vector2i(3, 4), 0)
				b.upgrade_tower(Vector2i(2, 4))
				b.upgrade_tower(Vector2i(2, 4), 1)
				_full(b, Vector2i(3, 6), &"longbow_loft", 1)
				_full(b, Vector2i(2, 9), &"bakery", 0)
				_full(b, Vector2i(4, 9), &"longbow_loft", 0)
				b.add_effects(_effects([{"type": "gates_open"}, {"type": "reward_gold", "amount": 120}]), true)
				b.add_effects(_effects([{"type": "interest", "pct": 10, "max": 50}, {"type": "gates_stay"}, {"type": "add_gold", "amount": 100, "per_wave": 10}]), false)
			5:
				b.move_gate(Vector2i(1, 6), Vector2i(5, 3))
				b.upgrade_tower(Vector2i(4, 4), 1)
				b.add_effects(_effects([{"type": "add_group", "enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 2000, "every_ms": 400, "after_last": true}, {"type": "reward_gold", "amount": 80}]), true)
				b.add_effects(_effects([{"type": "cost_add", "build": 20, "upgrade": -20}, {"type": "add_lives", "amount": 5}]), false)
		b.start_next_wave()
		return
	if b.tick == 40:
		b.place_tower(Vector2i(1, 1), &"sling_post")
	if b.tick == 900:
		b.upgrade_tower(Vector2i(1, 1))
		b.set_aim(Vector2i(1, 1), TowerState.Aim.LAST)
	if (b.waves_started == 1 or b.waves_started == 4) and b.next_wave_info()["refusal"] == &"":
		b.start_next_wave()


## Plays the level to its end. save_every > 0 swaps the battle for a copy restored from
## JSON text every that many ticks.
func _play(save_every: int, twist: Array) -> Dictionary:
	var b: Battle = Battle.create(_level(), catalog, false, _effects(twist))
	assert_not_null(b, "the battle starts")
	var snaps: PackedStringArray = PackedStringArray()
	var events: PackedStringArray = PackedStringArray()
	var restores: int = 0
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < LIMIT:
		_act(b)
		if b.phase != Battle.Phase.WAVE:
			break
		b.step()
		for event: Dictionary in b.take_events():
			events.append(var_to_str(event))
		var live: bool = b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE
		if save_every > 0 and b.tick % save_every == 0 and live:
			var before: String = Fx.snapshot(b)
			var copy: Battle = Fx.restored(b)
			if copy == null:
				fail("restore failed at tick %d" % b.tick)
				break
			assert_eq(Fx.snapshot(copy), before, "restore at tick %d is identical" % b.tick)
			b = copy
			restores += 1
		if b.tick % 25 == 0:
			snaps.append(Fx.snapshot(b))
	snaps.append(Fx.snapshot(b))
	return {"snaps": snaps, "events": events, "result": b.result(), "tick": b.tick, "restores": restores, "phase": b.phase}


func test_the_level_plays_through_every_new_rule() -> void:
	var run: Dictionary = _play(0, [])
	var text: String = "\n".join(run["events"] as PackedStringArray)
	for kind: String in ["popped", "healed", "released", "break_started", "gate_broken", "sped_up", "interest", "fired", "defeated", "wave_cleared"]:
		assert_true(text.contains("&\"%s\"" % kind), "the run emits " + kind)
	assert_true(text.contains("&\"dusk_moth\""), "Old Tusk or the waves bring Dusk Moths")
	assert_true(text.contains("&\"puff\""), "Puffs pop out")
	print("    sim: content run ended at tick %d, phase %d, result %s" % [run["tick"], run["phase"], str(run["result"])])
	var twisted: Dictionary = _play(0, TWIST)
	assert_true(twisted["tick"] > 500, "the Twist run plays: %d ticks" % twisted["tick"])
	print("    sim: Twist run ended at tick %d, phase %d, result %s" % [twisted["tick"], twisted["phase"], str(twisted["result"])])


func test_same_commands_give_byte_identical_data_rules_4_8() -> void:
	for twist: Array in [[], TWIST]:
		var first: Dictionary = _play(0, twist)
		var second: Dictionary = _play(0, twist)
		assert_eq(first["snaps"], second["snaps"])
		assert_eq(first["events"], second["events"])


func test_restore_gives_an_identical_battle_that_continues_identically_rules_4_10() -> void:
	for twist: Array in [[], TWIST]:
		var plain: Dictionary = _play(0, twist)
		for every: int in [1, 11, 37]:
			var restored: Dictionary = _play(every, twist)
			assert_true(restored["restores"] > 10, "restored %d times" % restored["restores"])
			assert_eq(restored["snaps"], plain["snaps"], "snapshots with a restore every %d ticks" % every)
			assert_eq(restored["events"], plain["events"], "events with a restore every %d ticks" % every)
			assert_eq(restored["result"], plain["result"])


## Saved data from the first moment `wanted` holds, as a save file would give it.
func _data_when(twist: Array, wanted: Callable) -> Dictionary:
	var b: Battle = Battle.create(_level(), catalog, false, _effects(twist))
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < LIMIT:
		_act(b)
		if b.phase != Battle.Phase.WAVE:
			break
		b.step()
		if b.phase == Battle.Phase.WAVE and wanted.call(b):
			var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
			assert_not_null(Battle.from_data(data, catalog), "the base data is valid")
			return data
	fail("the moment never came")
	return {}


func _index_of(data: Dictionary, type: String) -> int:
	for i: int in (data["enemies"] as Array).size():
		if data["enemies"][i]["type"] == type:
			return i
	return -1


func _refused(data: Dictionary, cases: Array) -> void:
	for item: Array in cases:
		var copy: Dictionary = data.duplicate(true)
		(item[1] as Callable).call(copy)
		assert_null(Battle.from_data(copy, catalog), item[0])


func test_hostile_heal_and_boss_fields_are_refused() -> void:
	var data: Dictionary = _data_when([], func(b: Battle) -> bool:
		var mender: bool = false
		var scamp: bool = false
		for e: EnemyState in b.enemies:
			mender = mender or e.type == &"mender"
			scamp = scamp or e.type == &"scamp"
		return mender and scamp)
	var m: int = _index_of(data, "mender")
	var s: int = _index_of(data, "scamp")
	var heal_ticks: int = catalog.enemy(&"mender").heal_ms / Sim.MS_PER_TICK
	_refused(data, [
		["heal timer on a Scamp", func(d: Dictionary) -> void: d["enemies"][s]["heal_at"] = d["tick"] + 5],
		["heal timer in the past", func(d: Dictionary) -> void: d["enemies"][m]["heal_at"] = d["tick"] - 1],
		["heal timer past one heal", func(d: Dictionary) -> void: d["enemies"][m]["heal_at"] = d["tick"] + heal_ticks + 1],
		["heal timer 0 on a Mender", func(d: Dictionary) -> void: d["enemies"][m]["heal_at"] = 0],
		["speed ups on a Scamp", func(d: Dictionary) -> void: d["enemies"][s]["ups"] = 1],
		["released on a Scamp", func(d: Dictionary) -> void: d["enemies"][s]["released"] = true],
		["released not a bool", func(d: Dictionary) -> void: d["enemies"][s]["released"] = 0],
		["breaking on a Scamp", func(d: Dictionary) -> void: d["enemies"][s]["breaking"] = 100],
	])
	var boss: Dictionary = _data_when([], func(b: Battle) -> bool:
		for e: EnemyState in b.enemies:
			if e.type == &"ironshell" and e.ups > 0:
				return true
		return false)
	var i: int = _index_of(boss, "ironshell")
	var most: int = (catalog.enemy(&"ironshell").speed_up["at_pct"] as Array).size()
	_refused(boss, [
		["more speed ups than thresholds", func(d: Dictionary) -> void: d["enemies"][i]["ups"] = most + 1],
		["speed ups below 0", func(d: Dictionary) -> void: d["enemies"][i]["ups"] = -1],
		["released on an Ironshell", func(d: Dictionary) -> void: d["enemies"][i]["released"] = true],
	])


func test_hostile_breaker_fields_are_refused() -> void:
	var data: Dictionary = _data_when([], func(b: Battle) -> bool:
		for e: EnemyState in b.enemies:
			if e.breaking > 0:
				return true
		return false)
	var g: int = _index_of(data, "gatecrasher")
	var full: int = catalog.enemy(&"gatecrasher").break_ms * 100
	var copy: Dictionary = data.duplicate(true)
	copy["enemies"][g]["breaking"] = full
	assert_not_null(Battle.from_data(copy, catalog), "a full break timer is fine")
	_refused(data, [
		["break timer past its break time", func(d: Dictionary) -> void: d["enemies"][g]["breaking"] = full + 1],
		["break timer below 0", func(d: Dictionary) -> void: d["enemies"][g]["breaking"] = -1],
		["breaking away from a cell center", func(d: Dictionary) -> void: d["enemies"][g]["progress"] = 100],
		["a gate broken in a build phase", func(d: Dictionary) -> void:
			d["phase"] = "build"
			d["gates"][0]["broken"] = true],
	])


func test_hostile_effect_fields_are_refused() -> void:
	var data: Dictionary = _data_when([], func(b: Battle) -> bool: return b.gates_open and not b._wave_risk.is_empty())
	assert_true((data["effects"] as Array).size() > 0, "card effects kept")
	var running: Array = data["running"]
	var many: Array = []
	for k: int in Modifiers.MAX_KEPT + 1:
		many.append({"type": "gates_stay"})
	_refused(data, [
		["gates_open not a bool", func(d: Dictionary) -> void: d["gates_open"] = 1],
		["too many kept effects", func(d: Dictionary) -> void: d["effects"] = many],
		["a kept effect with a bad field", func(d: Dictionary) -> void: d["effects"][0]["amount"] = 5000],
		["a risk for a wave not running", func(d: Dictionary) -> void: d["wave_risk"][0]["wave"] = 0],
		["a risk with no effects", func(d: Dictionary) -> void: d["wave_risk"][0]["effects"] = []],
		["a card effect as a wave's risk", func(d: Dictionary) -> void: d["wave_risk"][0]["effects"] = [{"type": "gates_stay"}]],
		["a risk twice for one wave", func(d: Dictionary) -> void: d["wave_risk"].append(d["wave_risk"][0].duplicate(true))],
		["more risks than waves running", func(d: Dictionary) -> void:
			for k: int in running.size() + 1:
				d["wave_risk"].append(d["wave_risk"][0].duplicate(true))],
		["a risk with an unknown key", func(d: Dictionary) -> void: d["wave_risk"][0]["cheat"] = 1],
		["a waiting risk naming a missing entrance", func(d: Dictionary) -> void:
			d["risk"] = [{"type": "add_group", "enemy": "pip", "count": 2, "entrance": 3, "at_ms": 0, "every_ms": 300, "after_last": false}]],
		["gates added past max_gates", func(d: Dictionary) -> void: d["gates_added"] = 4],
		["gates added that do not add up", func(d: Dictionary) -> void: d["gates_added"] = 1],
		["towers the level does not offer", func(d: Dictionary) -> void:
			d["level"]["towers"] = ["sling_post"]],
	])
	# Gates fixed by Iron Gate are fine; without the card they are not.
	var fixed: Dictionary = _data_when([], func(b: Battle) -> bool: return b.waves_started == 4)
	assert_true(fixed["gates"][0]["fixed"], "Iron Gate fixed the gates")
	_refused(fixed, [
		["a fixed gate without Iron Gate", func(d: Dictionary) -> void:
			var kept: Array = []
			for effect: Dictionary in d["effects"]:
				if effect["type"] != "gates_stay":
					kept.append(effect)
			d["effects"] = kept],
	])


## Where a saved gain sits: [label, path to the effect's Dictionary, field].
func _gain_slots(data: Dictionary) -> Array:
	var slots: Array = []
	for i: int in (data["effects"] as Array).size():
		if data["effects"][i]["type"] == "interest":
			slots.append(["kept interest max", ["effects", i], "max"])
	for i: int in (data["wave_risk"][0]["effects"] as Array).size():
		if data["wave_risk"][0]["effects"][i]["type"] == "reward_gold":
			slots.append(["a wave's risk reward", ["wave_risk", 0, "effects", i], "amount"])
	slots.append(["a waiting risk reward", ["risk", 0], "amount"])
	return slots


func test_a_negative_gain_in_a_save_is_refused_contract_2_8() -> void:
	var data: Dictionary = _data_when([], func(b: Battle) -> bool: return b.gates_open and not b._wave_risk.is_empty())
	data["risk"] = [{"type": "reward_gold", "amount": 100}]
	assert_not_null(Battle.from_data(data, catalog), "the base data with a waiting risk card is valid")
	var slots: Array = _gain_slots(data)
	assert_eq(slots.size(), 3, "an interest card, a wave's reward and a waiting reward")
	for slot: Array in slots:
		for value: int in [-1, 0, 1000, 1001]:
			var copy: Dictionary = data.duplicate(true)
			var node: Variant = copy
			for key: Variant in slot[1]:
				node = node[key]
			(node as Dictionary)[slot[2]] = value
			var b: Battle = Battle.from_data(copy, catalog)
			if value >= 0 and value <= 1000:
				assert_not_null(b, "%s %d is accepted" % [slot[0], value])
			else:
				assert_null(b, "%s %d is refused" % [slot[0], value])


func test_hostile_twist_fields_are_refused() -> void:
	var data: Dictionary = _data_when(TWIST, func(b: Battle) -> bool: return b.enemies.size() > 3)
	var s: int = _index_of(data, "scamp")
	assert_true(data["enemies"][s]["bubble"] or data["enemies"][s]["bubble_ticks"] > 0, "Bubble Night gives a Scamp a bubble")
	_refused(data, [
		["a card effect as a Twist", func(d: Dictionary) -> void: d["twist"].append({"type": "gates_stay"})],
		["a Twist effect with a bad field", func(d: Dictionary) -> void: d["twist"][0]["x"] = 1],
		["a fixed gate off a socket", func(d: Dictionary) -> void: d["twist"][5]["cells"] = [[2, 2]]],
		["the Twist's fixed gate gone", func(d: Dictionary) -> void:
			d["gates"].remove_at(0)
			d["gates_in_hand"] += 1],
		["the Twist's fixed gate not fixed", func(d: Dictionary) -> void: d["gates"][0]["fixed"] = false],
		["a bubble on a Scamp without Bubble Night", func(d: Dictionary) -> void: d["twist"].remove_at(0)],
		["too many Twist effects", func(d: Dictionary) -> void:
			for k: int in Modifiers.MAX_TWIST:
				d["twist"].append({"type": "no_selling"})],
	])
	# A tier cap and a ban refuse towers past them.
	var later: Dictionary = data
	var top_tier: int = 0
	for tower: Dictionary in later["towers"]:
		top_tier = maxi(top_tier, int(tower["tier"]))
	assert_eq(top_tier, 3, "tier 3 towers stand")
	var capped: Dictionary = later.duplicate(true)
	capped["twist"].append({"type": "tier_cap", "tier": 2})
	assert_null(Battle.from_data(capped, catalog), "a tower above the tier cap")
	var banned: Dictionary = later.duplicate(true)
	banned["twist"].append({"type": "ban_tower", "tower": String(later["towers"][0]["type"])})
	assert_null(Battle.from_data(banned, catalog), "a banned tower")


func test_every_new_field_survives_garbage_without_a_crash() -> void:
	var data: Dictionary = _data_when([], func(b: Battle) -> bool:
		var breaking: bool = false
		for e: EnemyState in b.enemies:
			breaking = breaking or e.breaking > 0
		return breaking and not b.card_effects.is_empty())
	var paths: Array = []
	for key: String in ["twist", "effects", "risk", "wave_risk", "gates_open", "gates_added"]:
		_leaves(data[key], [key], paths)
	for i: int in (data["enemies"] as Array).size():
		for key: String in ["heal_at", "ups", "released", "breaking"]:
			paths.append(["enemies", i, key])
	var hostile: Array = [null, -1, 1.5, "x", [], {}, true, 1e18, -1e18, INF, NAN, [1, 2, 3], {"a": 1}, 2147483648]
	var accepted: int = 0
	for path: Array in paths:
		for bad: Variant in hostile:
			var copy: Dictionary = data.duplicate(true)
			var node: Variant = copy
			for k: int in path.size() - 1:
				node = node[path[k]]
			node[path.back()] = bad
			var battle: Battle = Battle.from_data(copy, catalog)
			if battle != null:
				accepted += 1
				assert_not_null(Battle.from_data(JSON.parse_string(JSON.stringify(battle.to_data())), catalog), "accepted %s = %s round trips" % [str(path), str(bad)])
	assert_true(paths.size() > 20, "%d paths checked" % paths.size())
	print("    sim: %d new paths x %d hostile values; %d harmless changes accepted" % [paths.size(), hostile.size(), accepted])


func _leaves(value: Variant, path: Array, out: Array) -> void:
	out.append(path)
	if typeof(value) == TYPE_DICTIONARY:
		for key: Variant in (value as Dictionary).keys():
			_leaves(value[key], path + [key], out)
	elif typeof(value) == TYPE_ARRAY:
		for i: int in (value as Array).size():
			_leaves(value[i], path + [i], out)
