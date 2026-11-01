# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Saves with the creatures of regions 7 and 8 (docs/ARCHITECTURE.md 14.7): yawn_at on
## creatures that yawn and blink_at on creatures that blink, each required on its kind
## and refused on any other; doze_ticks on towers, optional and always written; a
## grower's max health between its start and its cap; MAX_WAKERS; growth in the wave
## ceiling; hostile values; statuses after load; and snapshot, restore and continue with
## every new creature on a map with every feature, equal to an unbroken run.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

## The straight road of test_battle_late_creatures.gd.
const STRAIGHT: Array = [
	"...1...",
	".o.#.o.",
	"..o#o..",
	"...#...",
	"..o#o..",
	"...#...",
	"...#...",
	"..o#o..",
	"...#...",
	"...#...",
	"..o#o..",
	"...#...",
	"...B...",
]
const KEYS: Array = ["yawn_at", "blink_at"]
const OWNER: Dictionary = {"yawn_at": &"yawner", "blink_at": &"blinker"}
const ALSO: Dictionary = {"yawn_at": &"snowsnore", "blink_at": &"glimmertoad"}
const HOSTILE: Array = [null, -1, 1.5, "x", [], {}, true, 0.5, 1e18, -1e18, INF, NAN, [1, 2, 3], {"a": 1}, 2147483648]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Cx.catalog()


## Mid-wave at tick 90 with one of each new creature, a Scamp and a Flitter, and the
## Sling Post at [2, 2] dozing since the Yawner's first yawn at tick 80, 31 ticks left;
## a Bell at [2, 4].
## Returns [data, the index of each creature type in data["enemies"]].
func _mid_wave() -> Array:
	var groups: Array = []
	for id: String in ["snowroller", "yawner", "blinker", "hootling", "snowsnore", "glimmertoad", "scamp", "flitter"]:
		groups.append(Fx.group(id, 1))
	var b: Battle = Cx.battle(STRAIGHT, [{"groups": groups}], {}, catalog)
	Tx.build(b, Vector2i(2, 4), &"lullaby_bell")
	b.start_next_wave()
	Fx.steps(b, 78)
	Tx.build(b, Vector2i(2, 2), &"sling_post")
	Fx.steps(b, 12)
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	var at: Dictionary = {}
	for i: int in (data["enemies"] as Array).size():
		at[StringName(String(data["enemies"][i]["type"]))] = i
	assert_eq(at.size(), 8, "every creature is on the map")
	assert_eq(b.tower_at(Vector2i(2, 2)).doze_ticks, 31, "the Sling Post dozes")
	return [data, at]


func _loads(data: Dictionary, stats: Catalog = null) -> bool:
	return Battle.from_data(JSON.parse_string(JSON.stringify(data)), stats if stats != null else catalog) != null


func _with(data: Dictionary, index: int, changes: Dictionary) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var item: Dictionary = copy["enemies"][index]
	for key: String in changes:
		if changes[key] == null:
			item.erase(key)
		else:
			item[key] = changes[key]
	return copy


## The tower at index `index` of data["towers"] with its doze_ticks set (null removes it).
func _doze(data: Dictionary, index: int, value: Variant) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var item: Dictionary = copy["towers"][index]
	if value == null:
		item.erase("doze_ticks")
	else:
		item["doze_ticks"] = value
	return copy


func test_the_new_keys_are_on_their_kinds_only_and_round_trip_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	var want: Dictionary = {&"yawner": ["yawn_at"], &"snowsnore": ["yawn_at"], &"blinker": ["blink_at"], &"glimmertoad": ["blink_at"]}
	for type: StringName in at:
		var item: Dictionary = data["enemies"][at[type]]
		for key: String in KEYS:
			assert_eq(item.has(key), (want.get(type, []) as Array).has(key), "%s on %s" % [key, type])
	assert_eq(data["tick"], 90)
	assert_eq(int(data["enemies"][at[&"yawner"]]["yawn_at"]), 160, "the Yawner's next yawn")
	assert_eq(int(data["enemies"][at[&"snowsnore"]]["yawn_at"]), 120)
	assert_eq(int(data["enemies"][at[&"blinker"]]["blink_at"]), 120)
	assert_eq(int(data["enemies"][at[&"glimmertoad"]]["blink_at"]), 120)
	for tower: Dictionary in data["towers"]:
		assert_true(tower.has("doze_ticks"), "doze_ticks is always written")
	assert_eq([int(data["towers"][0]["doze_ticks"]), int(data["towers"][1]["doze_ticks"])], [31, 0], "the Sling Post dozes, the Bell never")
	var b: Battle = Battle.from_data(data, catalog)
	assert_not_null(b)
	if b == null:
		return
	assert_eq(JSON.parse_string(JSON.stringify(b.to_data())), data, "to_data after from_data is the same")
	assert_eq(b.tower_at(Vector2i(2, 2)).doze_ticks, 31)
	assert_true(b._dozes_on, "the doze pass runs after load")
	var roller: EnemyState = b.enemies[at[&"snowroller"]]
	assert_eq([roller.start_health, roller.grow_cap, roller.grow_step], [40, 120, 4], "worked out again on load")
	assert_true(roller.max_health > 40, "it had grown")


func test_a_new_key_is_required_on_its_kind_and_refused_on_others_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	for key: String in KEYS:
		for owner: StringName in [OWNER[key], ALSO[key]]:
			assert_false(_loads(_with(data, at[owner], {key: null})), "%s missing on %s" % [key, owner])
		for type: StringName in at:
			if type == OWNER[key] or type == ALSO[key]:
				continue
			assert_false(_loads(_with(data, at[type], {key: int(data["tick"])})), "%s on %s" % [key, type])


func test_the_new_keys_hold_their_ranges_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	var tick: int = data["tick"]
	for item: Array in [["yawn_at", &"yawner", 80], ["yawn_at", &"snowsnore", 120], ["blink_at", &"blinker", 60], ["blink_at", &"glimmertoad", 120]]:
		var key: String = item[0]
		var index: int = at[item[1]]
		var every: int = item[2]
		assert_true(_loads(_with(data, index, {key: tick})), "%s %s at tick" % [item[1], key])
		assert_true(_loads(_with(data, index, {key: tick + every})), "%s %s at tick plus its time" % [item[1], key])
		assert_false(_loads(_with(data, index, {key: tick - 1})), "%s %s before tick" % [item[1], key])
		assert_false(_loads(_with(data, index, {key: tick + every + 1})), "%s %s too far" % [item[1], key])


func test_a_growers_max_health_is_from_its_start_to_its_cap_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	for item: Array in [[&"snowroller", 40, 120], [&"snowsnore", 3400, 5100]]:
		var index: int = at[item[0]]
		var start: int = item[1]
		var cap: int = item[2]
		assert_true(_loads(_with(data, index, {"max_health": start, "health": start})), "%s at its start" % item[0])
		assert_true(_loads(_with(data, index, {"max_health": cap, "health": 1})), "%s at its cap" % item[0])
		assert_false(_loads(_with(data, index, {"max_health": start - 1, "health": 1})), "%s below its start" % item[0])
		assert_false(_loads(_with(data, index, {"max_health": cap + 1, "health": 1})), "%s past its cap" % item[0])
	assert_true(_loads(_with(data, at[&"scamp"], {"max_health": 1000000000, "health": 1})), "a creature that does not grow keeps the far ceiling")


func test_doze_ticks_is_optional_ranged_and_only_on_attacking_towers_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var missing: Dictionary = _doze(data, 0, null)
	assert_true(_loads(missing), "missing loads, as from an older build")
	var b: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(missing)), catalog)
	assert_eq(b.tower_at(Vector2i(2, 2)).doze_ticks, 0, "missing means 0")
	assert_true(_loads(_doze(data, 0, 0)))
	assert_true(_loads(_doze(data, 0, 1200)), "60 s")
	assert_false(_loads(_doze(data, 0, 1201)), "past 60 s")
	assert_false(_loads(_doze(data, 0, -1)))
	assert_true(_loads(_doze(data, 1, 0)), "a Bell at 0")
	assert_false(_loads(_doze(data, 1, 1)), "a Bell never dozes")
	for bad: Variant in HOSTILE:
		var copy: Dictionary = data.duplicate(true)
		(copy["towers"][0] as Dictionary)["doze_ticks"] = bad
		assert_false(Battle.from_data(copy, catalog) != null, "doze_ticks = %s" % str(bad))


func test_hostile_values_in_the_new_keys_are_refused_without_a_crash_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	for key: String in KEYS:
		for bad: Variant in HOSTILE:
			var copy: Dictionary = data.duplicate(true)
			(copy["enemies"][at[OWNER[key]]] as Dictionary)[key] = bad
			assert_false(Battle.from_data(copy, catalog) != null, "%s = %s" % [key, str(bad)])
	for bad: Variant in HOSTILE:
		var copy: Dictionary = data.duplicate(true)
		(copy["enemies"][at[&"snowroller"]] as Dictionary)["max_health"] = bad
		assert_false(Battle.from_data(copy, catalog) != null, "a grower's max_health = %s" % str(bad))


# MAX_WAKERS (docs/ARCHITECTURE.md 14.7)

## Wave 0 running with one Hootling on the map; wave 1 a Scamp, to come.
func _wakers_save() -> Dictionary:
	var waves: Array = [{"groups": [Fx.group("hootling", 1)]}, {"groups": [Fx.group("scamp", 1)]}]
	var b: Battle = Cx.battle(STRAIGHT, waves, {}, catalog)
	b.start_next_wave()
	Fx.steps(b, 5)
	return JSON.parse_string(JSON.stringify(b.to_data()))


## Adds count copies of the first creature as `type`, with new ids.
func _add(data: Dictionary, type: String, count: int) -> void:
	var model: Dictionary = data["enemies"][0]
	for i: int in count:
		var enemy: Dictionary = model.duplicate(true)
		enemy["id"] = int(data["next_id"])
		data["next_id"] = int(data["next_id"]) + 1
		enemy["type"] = type
		(data["enemies"] as Array).append(enemy)


func test_at_most_max_wakers_wake_others_at_once_contract_14_7() -> void:
	var data: Dictionary = _wakers_save()
	var full: Dictionary = data.duplicate(true)
	_add(full, "hootling", Battle.MAX_WAKERS - 1)
	assert_true(_loads(full), "%d Hootlings load" % Battle.MAX_WAKERS)
	var more: Dictionary = full.duplicate(true)
	_add(more, "hootling", 1)
	assert_false(_loads(more), "one more is refused")
	var released: Dictionary = full.duplicate(true)
	var entrance: Array = [3, 0]
	released["releases"] = [{"enemy": "hootling", "wave": 0, "left": 1, "next": released["tick"], "gap": 1,
		"from": entrance, "to": entrance.duplicate(), "progress": Sim.UNIT}]
	assert_false(_loads(released), "a Hootling still to come from a release counts too")
	var coming: Dictionary = data.duplicate(true)
	coming["level"]["waves"][1]["groups"] = [Fx.group("hootling", Battle.MAX_WAKERS - 1)]
	assert_true(_loads(coming), "the next wave's wakers and the live one add up to %d" % Battle.MAX_WAKERS)
	coming["level"]["waves"][1]["groups"] = [Fx.group("hootling", Battle.MAX_WAKERS)]
	assert_false(_loads(coming), "and one more is refused")
	var third: Dictionary = data.duplicate(true)
	third["level"]["waves"][1]["groups"] = [Fx.group("glimmertoad", 1)]
	third["level"]["waves"].append({"groups": [Fx.group("hootling", Battle.MAX_WAKERS - 1)]})
	assert_true(_loads(third), "the two largest waves: %d and 1" % (Battle.MAX_WAKERS - 1))
	third["level"]["waves"][2]["groups"] = [Fx.group("hootling", Battle.MAX_WAKERS)]
	assert_false(_loads(third), "%d and 1: Glimmertoad counts as a waker" % Battle.MAX_WAKERS)
	third["level"]["waves"][1]["groups"] = [Fx.group("scamp", 1)]
	assert_false(_loads(third), "%d and the live Hootling" % Battle.MAX_WAKERS)
	third["level"]["waves"][2]["groups"] = [Fx.group("hootling", Battle.MAX_WAKERS - 1)]
	assert_true(_loads(third), "%d and the live Hootling" % (Battle.MAX_WAKERS - 1))


func test_a_summoned_creature_cannot_wake_others_contract_14_4() -> void:
	var files: Array = Cx.stats_files()
	for item: Dictionary in files[1]["enemies"]:
		if item["id"] == "grumblesack":
			item["summon"]["enemy"] = "hootling"
	assert_false(Catalog.check(files[0], files[1], files[2]).is_empty(), "a boss that summons Hootlings is refused")
	for item: Dictionary in files[1]["enemies"]:
		if item["id"] == "glimmertoad":
			item["release"]["enemy"] = "hootling"
	for item: Dictionary in files[1]["enemies"]:
		if item["id"] == "grumblesack":
			item["summon"]["enemy"] = "scamp"
	assert_true(Catalog.check(files[0], files[1], files[2]).is_empty(), "a release may bring wakers: the save counts them")


# Growth in the wave ceiling (docs/ARCHITECTURE.md 14.7)

## A Snowroller of 1,000,000 health at strength 1,000 that grows to 10 times: 10^8 at its
## cap. A risk card's health effects then decide whether a save could hold it.
func _big(grows: bool) -> Battle:
	var changes: Dictionary = {"health": 1000000}
	if grows:
		changes["grow_cap_pct"] = 1000
	else:
		changes["grow_pct"] = null
		changes["grow_cap_pct"] = null
	var stats: Catalog = Cx.catalog_with("snowroller", changes)
	var waves: Array = [{"groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("snowroller", 1)]}]
	return Cx.battle(STRAIGHT, waves, {"strength": 1000}, stats)


func test_growers_count_at_their_cap_in_the_wave_ceiling_contract_14_7() -> void:
	var at_edge: Array[Dictionary] = [{"type": "health_pct", "pct": 1000}, {"type": "health_pct", "pct": 100}]
	var past: Array[Dictionary] = [{"type": "health_pct", "pct": 1000}, {"type": "health_pct", "pct": 101}]
	var b: Battle = _big(true)
	assert_not_null(b, "the level itself fits")
	b.start_next_wave()
	assert_eq(b.add_effects(past, true), &"bad_effect", "a grower would reach 1.01 * 10^9 at its cap")
	assert_eq(b.add_effects(at_edge, true), Battle.DONE, "exactly 10^9 at its cap is allowed")
	var c: Battle = _big(false)
	c.start_next_wave()
	assert_eq(c.add_effects(past, true), Battle.DONE, "a creature that does not grow stays at 1.01 * 10^8")
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	assert_true(_loads(data, b.catalog), "the save at the edge loads")
	data["risk"][1]["pct"] = 101
	assert_false(_loads(data, b.catalog), "a save whose risk card passes the ceiling with growth is refused")
	assert_true(_loads(data, c.catalog), "with no growth it loads")
	b.step()
	assert_eq(b.start_next_wave(), Battle.DONE)
	var roller: EnemyState = null
	while b.tick < 4000 and b.phase == Battle.Phase.WAVE and roller == null:
		b.step()
		roller = b.enemy_with_id(1)
	assert_not_null(roller)
	if roller != null:
		assert_eq([roller.start_health, roller.grow_cap], [100000000, 1000000000], "its cap is exactly the ceiling")


# Statuses after load (docs/ARCHITECTURE.md 14.5)

## True when a creature's center is within a waker's reach of that waker's center.
func _should_be_awake(b: Battle, e: EnemyState) -> bool:
	for w: EnemyState in b.enemies:
		var reach: int = b.catalog.enemy(w.type).wake_reach * 200
		var d: Vector2i = e.pos - w.pos
		if reach > 0 and d.x * d.x + d.y * d.y <= reach * reach:
			return true
	return false


# Snapshot, restore and continue with every new creature (docs/ARCHITECTURE.md 14.13)

func _battle() -> Battle:
	var files: Array = Cx.stats_files()
	for item: Dictionary in files[1]["enemies"]:
		match String(item["id"]):
			"snowsnore":
				item["health"] = 100
				item["lives"] = 5
			"glimmertoad":
				item["health"] = 250
				item["armor"] = 0
				item["lives"] = 5
	var weak: Catalog = Catalog.from_data(files[0], files[1], files[2])
	var waves: Array = [
		{"groups": [Fx.group("snowroller", 6, 0, 700), Fx.group("yawner", 3, 500, 1500, 2), Fx.group("blinker", 5, 300, 900),
			Fx.group("hootling", 2, 800, 2500), Fx.group("scamp", 8, 300, 400), Fx.group("flitter", 3, 800, 900)]},
		{"groups": [Fx.group("snowsnore", 1), Fx.group("glimmertoad", 1, 2000, 1000, 2), Fx.group("hootling", 2, 0, 1500, 2),
			Fx.group("blinker", 4, 500, 800, 2), Fx.group("pip", 10, 1000, 200), Fx.group("yawner", 2, 700, 1200)]},
	]
	var b: Battle = Battle.create(Fx.level(Fx.FEATURE_GRID, waves, {"towers": Tx.ALL, "start_gold": 20000, "gates": 1}, weak), weak, true, [])
	assert_not_null(b)
	return b


func _act(b: Battle) -> void:
	if b.phase == Battle.Phase.BUILD:
		match b.waves_started:
			0:
				Tx.build(b, Vector2i(2, 1), &"sling_post", 3, 0)
				Tx.build(b, Vector2i(1, 5), &"lullaby_bell", 2)
				Tx.build(b, Vector2i(4, 5), &"pumpkin_catapult", 3, 1)
				Tx.build(b, Vector2i(1, 8), &"snow_fort", 2)
				Tx.build(b, Vector2i(4, 8), &"bramble_cottage", 2)
				# Strong finds Glimmertoad, the strongest, which Yawners otherwise shield.
				b.set_aim(Vector2i(2, 1), TowerState.Aim.STRONG)
				b.set_aim(Vector2i(4, 5), TowerState.Aim.STRONG)
			1:
				b.upgrade_tower(Vector2i(1, 8), 1)
				b.place_gate(Vector2i(5, 10))
		b.start_next_wave()
		return
	if b.waves_started == 1 and b.next_wave_info()["refusal"] == &"" and b.tick % 40 == 0:
		b.start_next_wave()


func _play(save_every: int) -> Dictionary:
	var b: Battle = _battle()
	var snaps: PackedStringArray = PackedStringArray()
	var events: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {"yawned": 0, "dozed": 0, "blinked": 0, "grew": 0, "awake": 0, "released": 0, "statuses": 0}
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < 20000:
		_act(b)
		if b.phase != Battle.Phase.WAVE:
			break
		b.step()
		for event: Dictionary in b.take_events():
			events.append(var_to_str(event))
			if seen.has(String(event["kind"])):
				seen[String(event["kind"])] += 1
			if event["kind"] == &"yawned" and not (event["cells"] as Array).is_empty():
				seen["dozed"] += 1
		for e: EnemyState in b.enemies:
			seen["grew"] += 1 if e.max_health > e.start_health else 0
			seen["awake"] += 1 if e.awake else 0
		if save_every > 0 and b.tick % save_every == 0 and (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE):
			var before: String = Fx.snapshot(b)
			var copy: Battle = Fx.restored(b)
			if copy == null:
				fail("restore failed at tick %d" % b.tick)
				break
			assert_eq(Fx.snapshot(copy), before, "restore at tick %d is identical" % b.tick)
			_same_statuses(b, copy)
			seen["statuses"] += 1
			b = copy
		if b.tick % 25 == 0:
			snaps.append(Fx.snapshot(b))
	snaps.append(Fx.snapshot(b))
	return {"snaps": snaps, "events": events, "result": b.result(), "tick": b.tick, "seen": seen}


## What is never saved comes back the same on load (docs/ARCHITECTURE.md 14.7). Awake is
## worked out from the loaded positions; until the next timers step nothing reads it.
func _same_statuses(b: Battle, copy: Battle) -> void:
	assert_eq(copy.enemies.size(), b.enemies.size())
	for i: int in mini(b.enemies.size(), copy.enemies.size()):
		var e: EnemyState = b.enemies[i]
		var c: EnemyState = copy.enemies[i]
		assert_eq([c.start_health, c.grow_cap, c.grow_step, c.yawn_at, c.blink_at, c.out_of_reach, c.hidden],
			[e.start_health, e.grow_cap, e.grow_step, e.yawn_at, e.blink_at, e.out_of_reach, e.hidden], "tick %d, %s %d" % [b.tick, e.type, e.id])
		assert_eq(c.awake, _should_be_awake(copy, c), "tick %d, %s %d: awake by the loaded positions" % [b.tick, c.type, c.id])
	for i: int in b.towers.size():
		assert_eq(copy.towers[i].doze_ticks, b.towers[i].doze_ticks)
	assert_eq(copy._dozes_on, _any_dozing(copy), "the doze pass runs after load when a tower dozes")


static func _any_dozing(b: Battle) -> bool:
	for tower: TowerState in b.towers:
		if tower.doze_ticks > 0:
			return true
	return false


func test_restore_with_every_late_creature_continues_identically_contract_14_13() -> void:
	var plain: Dictionary = _play(0)
	var seen: Dictionary = plain["seen"]
	print("    sim: late creatures run ended at tick %d, result %s, seen %s" % [plain["tick"], str(plain["result"]), str(seen)])
	for key: String in seen:
		if key != "statuses":
			assert_true(int(seen[key]) > 0, "the run saw %s: %s" % [key, str(seen)])
	for every: int in [1, 7, 13]:
		var restored: Dictionary = _play(every)
		assert_eq(restored["snaps"], plain["snaps"], "restoring every %d ticks: same states" % every)
		assert_eq(restored["events"], plain["events"], "restoring every %d ticks: same events" % every)
		assert_eq(restored["result"], plain["result"])


func test_the_same_commands_give_the_same_battle() -> void:
	var first: Dictionary = _play(0)
	var second: Dictionary = _play(0)
	assert_eq(first["snaps"], second["snaps"])
	assert_eq(first["events"], second["events"])
