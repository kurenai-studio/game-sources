# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Determinism, save and restore of a battle, and hostile saved data
## (docs/ARCHITECTURE.md 3.1, 5.6, 6; RULES 4.8, 4.10, 8.1).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const LIMIT: int = 30000
## Creature keys that are optional on load since A12 (docs/ARCHITECTURE.md 14.7).
const OPTIONAL_KEYS: Array = ["fright_pct", "fright_ticks", "low_ticks"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


## A region 1 style level on the fork: every region 1 creature, a boss with summons,
## both towers and all four tier 3 paths, a gate that moves, early calls, mid-wave buys.
func _level() -> LevelData:
	var waves: Array = [
		{"groups": [Fx.group("scamp", 6, 0, 600)]},
		{"groups": [Fx.group("pip", 12, 0, 300), Fx.group("bubbler", 2, 1000, 1500)]},
		{"groups": [Fx.group("flitter", 5, 0, 400), Fx.group("scamp", 4, 500, 700)]},
		{"groups": [Fx.group("shellback", 3, 0, 1500), Fx.group("pip", 10, 2000, 250)]},
		{"strength": 110, "groups": [Fx.group("grumblesack", 1), Fx.group("scamp", 6, 3000, 1000), Fx.group("flitter", 3, 5000, 400)]},
	]
	return Fx.level(Fx.FORK_GRID, waves, {"start_gold": 4000, "gates": 1, "star3": {"kind": "early_calls_at_least", "value": 1}}, catalog)


## The player's commands. They depend only on the battle's state, so a restored
## battle gets the same commands at the same moments.
func _act(b: Battle) -> void:
	# Build phases come before waves 0, 2 and 3; waves 1 and 4 are called early.
	if b.phase == Battle.Phase.BUILD:
		match b.waves_started:
			0:
				b.place_tower(Vector2i(3, 3), &"sling_post")
				b.place_tower(Vector2i(3, 5), &"pumpkin_catapult")
				b.place_gate(Vector2i(1, 3))
			2:
				b.upgrade_tower(Vector2i(3, 5))
				b.upgrade_tower(Vector2i(3, 5), 1)
				b.set_aim(Vector2i(0, 1), TowerState.Aim.LAST)
				b.place_tower(Vector2i(6, 1), &"sling_post")
			3:
				b.move_gate(Vector2i(1, 3), Vector2i(5, 5))
				b.upgrade_tower(Vector2i(3, 3), 0)
				b.sell_tower(Vector2i(6, 1))
				b.place_tower(Vector2i(6, 1), &"pumpkin_catapult")
				b.upgrade_tower(Vector2i(6, 1))
				b.upgrade_tower(Vector2i(6, 1), 0)
				for cell: Vector2i in [Vector2i(3, 7), Vector2i(2, 9), Vector2i(4, 9)]:
					b.place_tower(cell, &"sling_post")
					b.upgrade_tower(cell)
					b.upgrade_tower(cell, 1)
				b.set_aim(Vector2i(3, 7), TowerState.Aim.STRONG)
		b.start_next_wave()
		return
	if b.tick == 30:
		b.place_tower(Vector2i(0, 1), &"sling_post")
	if b.tick == 60:
		b.upgrade_tower(Vector2i(3, 3))
	if (b.waves_started == 1 or b.waves_started == 4) and b.next_wave_info()["refusal"] == &"":
		b.start_next_wave()


## Plays the level to its end. save_every > 0 swaps the battle for a copy restored
## from JSON text every that many ticks. Returns the snapshots, events and end state.
func _play(save_every: int) -> Dictionary:
	var b: Battle = Battle.create(_level(), catalog, false, [])
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


func test_the_level_plays_through_every_rule_region_1_uses() -> void:
	var run: Dictionary = _play(0)
	assert_true(run["tick"] > 500, "a real level: %d ticks" % run["tick"])
	var events: PackedStringArray = run["events"]
	var text: String = "\n".join(events)
	for kind: String in ["wave_started", "spawned", "fired", "popped", "defeated", "leaked", "wave_cleared", "build_started", "built", "upgraded", "sold", "gate_placed", "gate_removed"]:
		assert_true(text.contains("&\"%s\"" % kind), "the run emits " + kind)
	assert_true(text.contains("&\"jam_pot\"") or text.contains("\"spec\": 1"), "a Jam Pot fired")
	assert_eq(run["phase"], Battle.Phase.WON, "the scripted defense wins")
	print("    sim: plain run ended at tick %d, phase %d, result %s" % [run["tick"], run["phase"], str(run["result"])])


func test_same_commands_give_byte_identical_data_rules_4_8() -> void:
	var first: Dictionary = _play(0)
	var second: Dictionary = _play(0)
	assert_eq(first["snaps"], second["snaps"])
	assert_eq(first["events"], second["events"])
	assert_eq(first["result"], second["result"])


func test_restore_gives_an_identical_battle_that_continues_identically() -> void:
	var plain: Dictionary = _play(0)
	for every: int in [1, 7, 13, 50]:
		var restored: Dictionary = _play(every)
		assert_true(restored["restores"] > 10, "restored %d times" % restored["restores"])
		assert_eq(restored["snaps"], plain["snaps"], "snapshots with a restore every %d ticks" % every)
		assert_eq(restored["events"], plain["events"], "events with a restore every %d ticks" % every)
		assert_eq(restored["result"], plain["result"])


func test_a_build_phase_round_trips_rules_4_10() -> void:
	var b: Battle = Battle.create(_level(), catalog, true, [])
	_act(b)
	Fx.run_wave(b)
	assert_eq(b.phase, Battle.Phase.BUILD)
	var copy: Battle = Fx.restored(b)
	assert_not_null(copy)
	assert_eq(Fx.snapshot(copy), Fx.snapshot(b))
	assert_true(copy.relaxed)
	assert_eq(copy.sell_value(Vector2i(3, 3)), b.sell_value(Vector2i(3, 3)))
	assert_eq(copy.routes(copy.closed_cells()), b.routes(b.closed_cells()))


func _mid_wave_data() -> Dictionary:
	var b: Battle = Battle.create(_level(), catalog, true, [])
	while b.tick < LIMIT:
		_act(b)
		b.step()
		if b.waves_started == 5 and b.enemies.size() > 4 and b._releases.size() > 0:
			break
	assert_true(b._releases.size() > 0, "a release is in flight")
	var flyers: int = 0
	for e: EnemyState in b.enemies:
		if e.flying:
			flyers += 1
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	assert_not_null(Battle.from_data(data, catalog), "the base data is valid")
	return data


func _refused(data: Variant, what: String) -> void:
	assert_null(Battle.from_data(data, catalog), what)


func test_hostile_shapes_are_refused() -> void:
	for value: Variant in [null, 1, "x", [], {}, [{}], {"format": 1}]:
		_refused(value, str(value))
	var data: Dictionary = _mid_wave_data()
	assert_null(Battle.from_data(data, null), "no catalog")
	for key: String in data.keys():
		var missing: Dictionary = data.duplicate(true)
		missing.erase(key)
		_refused(missing, "without " + key)
	var extra: Dictionary = data.duplicate(true)
	extra["cheat"] = true
	_refused(extra, "an unknown key")


func test_hostile_fields_are_refused() -> void:
	var data: Dictionary = _mid_wave_data()
	var walker: int = -1
	var flyer: int = -1
	for i: int in (data["enemies"] as Array).size():
		var item: Dictionary = data["enemies"][i]
		if item["type"] == "scamp" and walker < 0:
			walker = i
		if item.has("fly_from") and flyer < 0:
			flyer = i
	var cases: Array = [
		["format", func(d: Dictionary) -> void: d["format"] = 2],
		["tick -1", func(d: Dictionary) -> void: d["tick"] = -1],
		["tick 1.5", func(d: Dictionary) -> void: d["tick"] = 1.5],
		["phase won", func(d: Dictionary) -> void: d["phase"] = "won"],
		["phase build with creatures", func(d: Dictionary) -> void: d["phase"] = "build"],
		["gold -1", func(d: Dictionary) -> void: d["gold"] = -1],
		["gold past the ceiling", func(d: Dictionary) -> void: d["gold"] = 1000000001],
		["gold infinite", func(d: Dictionary) -> void: d["gold"] = INF],
		["gold NaN", func(d: Dictionary) -> void: d["gold"] = NAN],
		["lives 0", func(d: Dictionary) -> void: d["lives"] = 0],
		["waves_started past the level", func(d: Dictionary) -> void: d["waves_started"] = 6],
		["running out of order", func(d: Dictionary) -> void: d["running"] = [4, 3]],
		["running a wave not started", func(d: Dictionary) -> void: d["running"] = [5]],
		["three waves running", func(d: Dictionary) -> void: d["running"] = [2, 3, 4]],
		["wave_start after tick", func(d: Dictionary) -> void: d["wave_start"][4] = d["tick"] + 1],
		["wave_start short", func(d: Dictionary) -> void: d["wave_start"].pop_back()],
		["an instant effect kept", func(d: Dictionary) -> void: d["effects"] = [{"type": "add_gold", "amount": 5, "per_wave": 0}]],
		["a Twist effect kept as a card", func(d: Dictionary) -> void: d["effects"] = [{"type": "no_selling"}]],
		["a card effect waiting as a risk", func(d: Dictionary) -> void: d["risk"] = [{"type": "gates_stay"}]],
		["a risk effect as a Twist", func(d: Dictionary) -> void: d["twist"] = [{"type": "gates_open"}]],
		["level broken", func(d: Dictionary) -> void: d["level"]["grid"][0] = "xxxxxxx"],
		["level gone", func(d: Dictionary) -> void: d["level"] = {}],
		["gates in hand too many", func(d: Dictionary) -> void: d["gates_in_hand"] = 1],
		["gate off a socket", func(d: Dictionary) -> void: d["gates"][0]["cell"] = [2, 2]],
		["gate outside the map", func(d: Dictionary) -> void: d["gates"][0]["cell"] = [9, 99]],
		["gate fixed", func(d: Dictionary) -> void: d["gates"][0]["fixed"] = true],
		["gate not bool", func(d: Dictionary) -> void: d["gates"][0]["broken"] = 0],
		["two gates on one socket", func(d: Dictionary) -> void: d["gates"].append(d["gates"][0].duplicate())],
		["tower on a road", func(d: Dictionary) -> void: d["towers"][0]["cell"] = [3, 2]],
		["tower tier 4", func(d: Dictionary) -> void: d["towers"][0]["tier"] = 4],
		["tier 3 without a spec", func(d: Dictionary) -> void:
			d["towers"][0]["tier"] = 3
			d["towers"][0]["spec"] = -1],
		["spec below tier 3", func(d: Dictionary) -> void:
			d["towers"][0]["tier"] = 1
			d["towers"][0]["spec"] = 0],
		["tower not offered", func(d: Dictionary) -> void: d["towers"][0]["type"] = "bakery"],
		["tower unknown", func(d: Dictionary) -> void: d["towers"][0]["type"] = "dragon"],
		["aim unknown", func(d: Dictionary) -> void: d["towers"][0]["aim"] = "sideways"],
		["reload past its reload", func(d: Dictionary) -> void: d["towers"][0]["reload"] = 99999999],
		["reload just past its own reload", func(d: Dictionary) -> void: d["towers"][0]["reload"] = _own_reload(d, 0) + 1],
		["reload just below 0", func(d: Dictionary) -> void: d["towers"][0]["reload"] = -1],
		["reload far below 0", func(d: Dictionary) -> void: d["towers"][0]["reload"] = -1000000000],
		["spent_now during a wave", func(d: Dictionary) -> void: d["towers"][0]["spent_now"] = 10],
		["towers out of order", func(d: Dictionary) -> void: d["towers"].reverse()],
		["enemy health 0", func(d: Dictionary) -> void: d["enemies"][0]["health"] = 0],
		["enemy health above max", func(d: Dictionary) -> void: d["enemies"][0]["health"] = d["enemies"][0]["max_health"] + 1],
		["enemy type unknown", func(d: Dictionary) -> void: d["enemies"][0]["type"] = "dragon"],
		["enemy type an id of the wrong shape", func(d: Dictionary) -> void: d["enemies"][0]["type"] = "Scamp!"],
		["enemy wave not running", func(d: Dictionary) -> void: d["enemies"][0]["wave"] = 0],
		["enemy ids repeat", func(d: Dictionary) -> void: d["enemies"][1]["id"] = d["enemies"][0]["id"]],
		["enemy id at next_id", func(d: Dictionary) -> void: d["enemies"].back()["id"] = d["next_id"]],
		["next_id past the ceiling", func(d: Dictionary) -> void: d["next_id"] = 4294967296],
		["enemy bubble on a Scamp", func(d: Dictionary) -> void: d["enemies"][0]["bubble"] = true],
		["enemy slow 95", func(d: Dictionary) -> void: d["enemies"][0]["slow_pct"] = 95],
		["enemy slow without time", func(d: Dictionary) -> void:
			d["enemies"][0]["slow_pct"] = 40
			d["enemies"][0]["slow_ticks"] = 0],
		["enemy breaking", func(d: Dictionary) -> void: d["enemies"][0]["breaking"] = 100],
		["summon timer on a Scamp", func(d: Dictionary) -> void: d["enemies"][walker]["summon_at"] = d["tick"] + 5],
		["walker on scenery", func(d: Dictionary) -> void:
			d["enemies"][walker]["from"] = [0, 0]
			d["enemies"][walker]["to"] = [0, 0]],
		["walker steps two cells", func(d: Dictionary) -> void: d["enemies"][walker]["to"] = [3, 9]],
		["walker progress past a step", func(d: Dictionary) -> void: d["enemies"][walker]["progress"] = 20001],
		["walker into a closed gate", func(d: Dictionary) -> void:
			var gate: Array = d["gates"][0]["cell"]
			d["enemies"][walker]["from"] = [gate[0], gate[1] - 1]
			d["enemies"][walker]["to"] = gate],
		["walker with flyer keys", func(d: Dictionary) -> void:
			d["enemies"][walker].erase("from")
			d["enemies"][walker]["fly_from"] = [10000, 10000]],
		["flyer past its line", func(d: Dictionary) -> void: d["enemies"][flyer]["flown"] = 9999999],
		["flyer outside the map", func(d: Dictionary) -> void: d["enemies"][flyer]["fly_from"] = [-5, 900000]],
		["flyer at the base", func(d: Dictionary) -> void: d["enemies"][flyer]["fly_from"] = [70000, 190000]],
		["too many creatures", func(d: Dictionary) -> void:
			var many: Array = []
			for i: int in 4001:
				many.append({})
			d["enemies"] = many],
		["release left 0", func(d: Dictionary) -> void: d["releases"][0]["left"] = 0],
		["release in the past", func(d: Dictionary) -> void: d["releases"][0]["next"] = d["tick"] - 1],
		["release of an unknown creature", func(d: Dictionary) -> void: d["releases"][0]["enemy"] = "dragon"],
		["release walker off the road", func(d: Dictionary) -> void: d["releases"][0]["from"] = [0, 0]],
		["record without a built tower", func(d: Dictionary) -> void: d["record"]["built"] = []],
		["record built twice", func(d: Dictionary) -> void: d["record"]["built"] = ["sling_post", "sling_post", "pumpkin_catapult"]],
		["record tier below a tower", func(d: Dictionary) -> void: d["record"]["max_tier"] = 1],
		["record early calls past waves", func(d: Dictionary) -> void: d["record"]["early_calls"] = 9],
	]
	assert_true(walker >= 0 and flyer >= 0, "the data has a walker and a flyer")
	for item: Array in cases:
		var copy: Dictionary = data.duplicate(true)
		(item[1] as Callable).call(copy)
		_refused(copy, item[0])


## The reload of saved tower i, in the timer's units (1/100 ms).
func _own_reload(data: Dictionary, i: int) -> int:
	var item: Dictionary = data["towers"][i]
	return catalog.tower(StringName(item["type"])).stats(int(item["tier"]), int(item["spec"])).reload_ms * 100


func test_a_saved_reload_timer_is_0_to_the_towers_own_reload_rules_5_2() -> void:
	var data: Dictionary = _mid_wave_data()
	var own: Array[int] = []
	for i: int in (data["towers"] as Array).size():
		own.append(_own_reload(data, i))
	assert_true(own.size() >= 2 and own.min() != own.max(), "towers with different reloads: %s" % str(own))
	for i: int in own.size():
		for value: int in [0, own[i]]:
			var copy: Dictionary = data.duplicate(true)
			copy["towers"][i]["reload"] = value
			var b: Battle = Battle.from_data(copy, catalog)
			assert_not_null(b, "tower %d accepts %d" % [i, value])
			if b != null:
				assert_eq(b.towers[i].reload, value)
		for value: int in [-1, own[i] + 1]:
			var copy: Dictionary = data.duplicate(true)
			copy["towers"][i]["reload"] = value
			_refused(copy, "tower %d refuses %d" % [i, value])


func test_no_real_game_leaves_a_timer_outside_0_to_its_reload_rules_5_2() -> void:
	# The bounds the loader uses hold on every tick of the scripted level, upgrades and all.
	var b: Battle = Battle.create(_level(), catalog, false, [])
	var checked: int = 0
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < LIMIT:
		_act(b)
		if b.phase != Battle.Phase.WAVE:
			break
		b.step()
		for tower: TowerState in b.towers:
			var top: int = catalog.tower(tower.type).stats(tower.tier, tower.spec).reload_ms * 100
			if tower.reload < 0 or tower.reload > top:
				fail("tick %d: %s timer %d outside 0 to %d" % [b.tick, tower.type, tower.reload, top])
				return
			checked += 1
	assert_true(checked > 1000, "%d timers checked" % checked)


func test_every_field_survives_garbage_without_a_crash() -> void:
	# Each node of a mid-wave save (outside the level, which LevelData checks) is replaced by each hostile value. from_data must
	# never raise a script error, and anything it accepts must save and load again.
	var data: Dictionary = _mid_wave_data()
	data.erase("level")
	var paths: Array = []
	_leaves(data, [], paths)
	paths.append(["level"])
	paths.append(["level", "grid"])
	paths.append(["level", "waves"])
	var full: Dictionary = _mid_wave_data()
	var hostile: Array = [null, -1, 1.5, "x", [], {}, true, 1e18, -1e18, INF, NAN, [1, 2, 3], {"a": 1}, 2147483648]
	var accepted: int = 0
	for path: Array in paths:
		for bad: Variant in hostile:
			var copy: Dictionary = full.duplicate(true)
			_set_at(copy, path, bad)
			var battle: Battle = Battle.from_data(copy, catalog)
			if battle != null:
				accepted += 1
				assert_not_null(Battle.from_data(JSON.parse_string(JSON.stringify(battle.to_data())), catalog), "accepted %s = %s round trips" % [str(path), str(bad)])
	assert_true(paths.size() > 50, "%d leaves checked" % paths.size())
	print("    sim: %d leaves x %d hostile values; %d harmless changes accepted" % [paths.size(), hostile.size(), accepted])


## Every path in the tree: containers and leaves alike.
func _leaves(value: Variant, path: Array, out: Array) -> void:
	if not path.is_empty():
		out.append(path)
	if typeof(value) == TYPE_DICTIONARY:
		for key: Variant in (value as Dictionary).keys():
			_leaves(value[key], path + [key], out)
	elif typeof(value) == TYPE_ARRAY:
		for i: int in (value as Array).size():
			_leaves(value[i], path + [i], out)


func test_every_missing_key_is_refused_without_a_crash() -> void:
	var data: Dictionary = _mid_wave_data()
	var paths: Array = []
	_leaves(data, [], paths)
	var removed: int = 0
	for path: Array in paths:
		if typeof(path.back()) != TYPE_STRING or path.back() == "strength" and path.size() == 4:
			continue                                   # an index, or a wave's optional strength
		if path.size() == 3 and path[0] == "enemies" and OPTIONAL_KEYS.has(path.back()):
			continue                                   # optional since A12 (14.7): test_battle_tower_saves.gd
		if path.size() == 3 and path[0] == "towers" and path.back() == "doze_ticks":
			continue                                   # optional since A12 (14.7): test_battle_late_creature_saves.gd
		var copy: Dictionary = data.duplicate(true)
		var node: Variant = copy
		for i: int in path.size() - 1:
			node = node[path[i]]
		(node as Dictionary).erase(path.back())
		removed += 1
		_refused(copy, "without %s" % str(path))
	assert_true(removed > 100, "%d keys removed one at a time" % removed)


func _set_at(root: Variant, path: Array, value: Variant) -> void:
	var node: Variant = root
	for i: int in path.size() - 1:
		node = node[path[i]]
	node[path.back()] = value
