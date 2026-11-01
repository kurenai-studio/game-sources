# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Saves with the creatures of regions 5 and 6 (docs/ARCHITECTURE.md 14.7): regrow_at on
## creatures that regrow, napped and nap_ticks on creatures that nap, dig_at and dig_ticks
## on creatures that dig, each required on its kind and refused on any other; their
## ranges and hostile values; and snapshot, restore and continue with every new creature
## on a map with every feature, equal to an unbroken run.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

## The straight road of test_battle_new_creatures.gd.
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
const NEW_KEYS: Array = ["regrow_at", "napped", "nap_ticks", "dig_at", "dig_ticks"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Cx.catalog()


## Mid-wave at tick 125 with one of each new creature, a Scamp and a Flitter: the
## Sleepyhead and Old Hayrick napping, Burrowbelly dug under. Returns [data, the index of
## each creature type in data["enemies"]].
func _mid_wave() -> Array:
	var groups: Array = []
	for id: String in ["mossbud", "mistwisp", "gleamer", "sleepyhead", "burrowbelly", "old_hayrick", "scamp", "flitter"]:
		groups.append(Fx.group(id, 1))
	var b: Battle = Cx.battle(STRAIGHT, [{"groups": groups}], {}, catalog)
	b.start_next_wave()
	Fx.steps(b, 110)
	for e: EnemyState in b.enemies:
		if e.naps:
			e.health = 0
	b._downed = true
	b._defeat_step()
	Fx.steps(b, 15)
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	var at: Dictionary = {}
	for i: int in (data["enemies"] as Array).size():
		at[StringName(String(data["enemies"][i]["type"]))] = i
	assert_eq(at.size(), 8, "every creature is on the map")
	return [data, at]


func _loads(data: Dictionary) -> bool:
	return Battle.from_data(JSON.parse_string(JSON.stringify(data)), catalog) != null


func _with(data: Dictionary, index: int, changes: Dictionary) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var item: Dictionary = copy["enemies"][index]
	for key: String in changes:
		if changes[key] == null:
			item.erase(key)
		else:
			item[key] = changes[key]
	return copy


func test_the_new_keys_are_on_their_kinds_only_and_round_trip_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	var want: Dictionary = {
		&"mossbud": ["regrow_at"], &"sleepyhead": ["napped", "nap_ticks"], &"old_hayrick": ["napped", "nap_ticks"],
		&"burrowbelly": ["dig_at", "dig_ticks"],
	}
	for type: StringName in at:
		var item: Dictionary = data["enemies"][at[type]]
		for key: String in NEW_KEYS:
			assert_eq(item.has(key), (want.get(type, []) as Array).has(key), "%s on %s" % [key, type])
	var tick: int = data["tick"]
	var sleepy: Dictionary = data["enemies"][at[&"sleepyhead"]]
	assert_eq([sleepy["napped"], int(sleepy["nap_ticks"])], [true, 25], "napping, 25 ticks left")
	var belly: Dictionary = data["enemies"][at[&"burrowbelly"]]
	assert_eq([int(belly["dig_at"]), int(belly["dig_ticks"])], [280, 36], "dug under, 36 ticks left; next dig at 280")
	assert_eq(int(data["enemies"][at[&"mossbud"]]["regrow_at"]), 140, "next regrow at 140")
	assert_eq(tick, 125)
	var b: Battle = Battle.from_data(data, catalog)
	assert_not_null(b)
	if b == null:
		return
	assert_eq(JSON.parse_string(JSON.stringify(b.to_data())), data, "to_data after from_data is the same")
	var hay: EnemyState = b.enemies[at[&"old_hayrick"]]
	assert_eq([hay.napped, hay.nap_ticks], [true, 45])
	var digger: EnemyState = b.enemies[at[&"burrowbelly"]]
	assert_true(digger.out_of_reach, "a creature dug under is out of reach after load")


func test_a_new_key_is_required_on_its_kind_and_refused_on_others_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	var owner: Dictionary = {"regrow_at": &"mossbud", "napped": &"sleepyhead", "nap_ticks": &"sleepyhead", "dig_at": &"burrowbelly",
		"dig_ticks": &"burrowbelly"}
	for key: String in NEW_KEYS:
		assert_false(_loads(_with(data, at[owner[key]], {key: null})), "%s missing on %s" % [key, owner[key]])
		for type: StringName in at:
			if type == owner[key] or (key.begins_with("nap") and type == &"old_hayrick"):
				continue
			var value: Variant = false if key == "napped" else 0
			assert_false(_loads(_with(data, at[type], {key: value})), "%s on %s" % [key, type])


func test_the_new_keys_hold_their_ranges_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	var tick: int = data["tick"]
	var moss: int = at[&"mossbud"]
	var sleepy: int = at[&"sleepyhead"]
	var belly: int = at[&"burrowbelly"]
	assert_true(_loads(_with(data, moss, {"regrow_at": tick})), "regrow_at at tick")
	assert_true(_loads(_with(data, moss, {"regrow_at": tick + 20})), "regrow_at at tick + 1.0 s")
	assert_false(_loads(_with(data, moss, {"regrow_at": tick - 1})), "regrow_at before tick")
	assert_false(_loads(_with(data, moss, {"regrow_at": tick + 21})), "regrow_at past tick + 1.0 s")
	assert_true(_loads(_with(data, belly, {"dig_at": tick})), "dig_at at tick")
	assert_true(_loads(_with(data, belly, {"dig_at": tick + 160})), "dig_at at tick + the larger of 6.0 s and 8.0 s")
	assert_false(_loads(_with(data, belly, {"dig_at": tick - 1})), "dig_at before tick")
	assert_false(_loads(_with(data, belly, {"dig_at": tick + 161})), "dig_at too far")
	assert_true(_loads(_with(data, belly, {"dig_ticks": 0})), "not dug under")
	assert_true(_loads(_with(data, belly, {"dig_ticks": 40})), "dug under for the whole 2.0 s")
	assert_false(_loads(_with(data, belly, {"dig_ticks": 41})), "dig_ticks past 2.0 s")
	assert_true(_loads(_with(data, sleepy, {"nap_ticks": 40})), "the whole nap")
	assert_false(_loads(_with(data, sleepy, {"nap_ticks": 41})), "nap_ticks past 2.0 s")
	assert_true(_loads(_with(data, sleepy, {"nap_ticks": 0})), "awake after its nap")
	assert_true(_loads(_with(data, sleepy, {"napped": false, "nap_ticks": 0})), "its nap not used")
	assert_false(_loads(_with(data, sleepy, {"napped": false})), "napping with its nap not used")
	assert_true(_loads(_with(data, at[&"old_hayrick"], {"nap_ticks": 60})), "Old Hayrick naps 3.0 s")
	assert_false(_loads(_with(data, at[&"old_hayrick"], {"nap_ticks": 61})), "and no longer")


func test_hostile_values_in_the_new_keys_are_refused_without_a_crash_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	var owner: Dictionary = {"regrow_at": &"mossbud", "napped": &"sleepyhead", "nap_ticks": &"sleepyhead", "dig_at": &"burrowbelly",
		"dig_ticks": &"burrowbelly"}
	var hostile: Array = [null, -1, 1.5, "x", [], {}, true, 0.5, 1e18, -1e18, INF, NAN, [1, 2, 3], {"a": 1}, 2147483648]
	for key: String in NEW_KEYS:
		for bad: Variant in hostile:
			if key == "napped" and typeof(bad) == TYPE_BOOL:
				continue
			var copy: Dictionary = data.duplicate(true)
			(copy["enemies"][at[owner[key]]] as Dictionary)[key] = bad
			assert_false(Battle.from_data(copy, catalog) != null, "%s = %s" % [key, str(bad)])
	assert_false(_loads(_with(data, at[&"sleepyhead"], {"napped": 1})), "napped as a number")


# Snapshot, restore and continue with every new creature (docs/ARCHITECTURE.md 14.13)

func _battle() -> Battle:
	var files: Array = Cx.stats_files()
	for item: Dictionary in files[1]["enemies"]:
		match String(item["id"]):
			"old_hayrick":
				item["health"] = 300
			"burrowbelly":
				item["health"] = 900
	var weak: Catalog = Catalog.from_data(files[0], files[1], files[2])
	var waves: Array = [
		{"groups": [Fx.group("mossbud", 6, 0, 700), Fx.group("mistwisp", 3, 500, 1500, 2), Fx.group("scamp", 8, 300, 400),
			Fx.group("sleepyhead", 4, 1000, 900, 2), Fx.group("flitter", 4, 800, 700), Fx.group("gleamer", 2, 1500, 2500)]},
		{"groups": [Fx.group("burrowbelly", 1), Fx.group("old_hayrick", 1, 2000), Fx.group("mender", 2, 0, 1500, 2),
			Fx.group("pip", 10, 1000, 200, 2), Fx.group("sleepyhead", 3, 500, 800), Fx.group("dusk_moth", 2, 1500, 1500)]},
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
				Tx.build(b, Vector2i(4, 5), &"pumpkin_catapult", 3, 0)
				Tx.build(b, Vector2i(1, 8), &"longbow_loft", 2)
				Tx.build(b, Vector2i(4, 8), &"bramble_cottage", 2)
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
	var seen: Dictionary = {"napped": 0, "woke": 0, "burrowed": 0, "surfaced": 0, "hidden": 0, "regrow": 0, "dazzled": 0}
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < 20000:
		_act(b)
		if b.phase != Battle.Phase.WAVE:
			break
		var moss_health: Dictionary = {}
		for e: EnemyState in b.enemies:
			if e.type == &"mossbud":
				moss_health[e.id] = e.health
		b.step()
		var healed: bool = false
		for event: Dictionary in b.take_events():
			events.append(var_to_str(event))
			if seen.has(String(event["kind"])):
				seen[String(event["kind"])] += 1
			healed = healed or event["kind"] == &"healed"
			if event["kind"] == &"fired" and not (event["targets"] as Array).is_empty():
				var first: EnemyState = b.enemy_with_id(event["targets"][0])
				if first != null and first.dazzle:
					seen["dazzled"] += 1
		for e: EnemyState in b.enemies:
			seen["hidden"] += 1 if e.hidden else 0
			if moss_health.has(e.id) and e.health > int(moss_health[e.id]) and not healed:
				seen["regrow"] += 1
		if save_every > 0 and b.tick % save_every == 0 and (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE):
			var before: String = Fx.snapshot(b)
			var copy: Battle = Fx.restored(b)
			if copy == null:
				fail("restore failed at tick %d" % b.tick)
				break
			assert_eq(Fx.snapshot(copy), before, "restore at tick %d is identical" % b.tick)
			b = copy
		if b.tick % 25 == 0:
			snaps.append(Fx.snapshot(b))
	snaps.append(Fx.snapshot(b))
	return {"snaps": snaps, "events": events, "result": b.result(), "tick": b.tick, "seen": seen}


func test_restore_with_every_new_creature_continues_identically_contract_14_13() -> void:
	var plain: Dictionary = _play(0)
	var seen: Dictionary = plain["seen"]
	print("    sim: new creatures run ended at tick %d, result %s, seen %s" % [plain["tick"], str(plain["result"]), str(seen)])
	for key: String in seen:
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
