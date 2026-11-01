# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Saves with the expansion towers (docs/ARCHITECTURE.md 14.7): fright_pct and
## fright_ticks on every creature and low_ticks on flyers, optional on load and always
## written; their ranges; and snapshot, restore and continue with every new tower on a
## map with every feature, equal to an unbroken run.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Tx.catalog()


## Mid-wave on the line map: a Scarecrow and a Moth Lantern at work, with at least one
## frightened walker and one low flyer. Returns [data, a frightened walker's index, a
## low flyer's index].
func _mid_wave() -> Array:
	var b: Battle = Tx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 6, 0, 400), Fx.group("dusk_moth", 4, 0, 500)]}], {}, catalog)
	Tx.build(b, Vector2i(2, 3), &"scarecrow")
	Tx.build(b, Vector2i(4, 3), &"moth_lantern")
	b.start_next_wave()
	var walker: int = -1
	var flyer: int = -1
	while b.phase == Battle.Phase.WAVE and b.tick < 500 and (walker < 0 or flyer < 0):
		b.step()
		walker = -1
		flyer = -1
		for i: int in b.enemies.size():
			if b.enemies[i].fright_pct > 0 and not b.enemies[i].flying:
				walker = i
			if b.enemies[i].low_ticks > 0:
				flyer = i
	assert_true(walker >= 0 and flyer >= 0, "a frightened walker and a low flyer")
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	assert_not_null(Battle.from_data(data, catalog), "the base data loads")
	return [data, walker, flyer]


func test_frights_and_lures_round_trip_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	for item: Dictionary in data["enemies"]:
		assert_true(item.has("fright_pct") and item.has("fright_ticks"), "always written")
		assert_eq(item.has("low_ticks"), item.has("fly_from"), "low_ticks on flyers only")
	var b: Battle = Battle.from_data(data, catalog)
	assert_eq(JSON.parse_string(JSON.stringify(b.to_data())), data, "to_data after from_data is the same")
	var walker: EnemyState = b.enemies[got[1]]
	var flyer: EnemyState = b.enemies[got[2]]
	assert_eq([walker.fright_pct, walker.fright_ticks], [int(data["enemies"][got[1]]["fright_pct"]), int(data["enemies"][got[1]]["fright_ticks"])])
	assert_eq(flyer.low_ticks, int(data["enemies"][got[2]]["low_ticks"]))
	assert_true(flyer.low_ticks > 0)


func test_saves_without_the_new_keys_load_with_0_contract_14_7() -> void:
	var data: Dictionary = _mid_wave()[0]
	for item: Dictionary in data["enemies"]:
		for key: String in ["fright_pct", "fright_ticks", "low_ticks"]:
			item.erase(key)
	var b: Battle = Battle.from_data(data, catalog)
	assert_not_null(b, "a save from before the expansion loads")
	if b == null:
		return
	for e: EnemyState in b.enemies:
		assert_eq([e.fright_pct, e.fright_ticks, e.low_ticks], [0, 0, 0])
	Fx.run_wave(b)
	assert_ne(b.phase, Battle.Phase.WAVE, "and plays on")


func _loads(data: Dictionary) -> bool:
	return Battle.from_data(JSON.parse_string(JSON.stringify(data)), catalog) != null


func _with(data: Dictionary, index: int, changes: Dictionary) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	(copy["enemies"][index] as Dictionary).merge(changes, true)
	return copy


func test_the_new_keys_are_checked_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var walker: int = got[1]
	var flyer: int = got[2]
	var hostile: Array = [-1, 1.5, "x", true, null, [], {}, 1e18, -1e18, INF, NAN]
	for key: String in ["fright_pct", "fright_ticks", "low_ticks"]:
		for bad: Variant in hostile:
			assert_false(_loads(_with(data, walker if key != "low_ticks" else flyer, {key: bad})), "%s = %s" % [key, str(bad)])
	assert_true(_loads(_with(data, walker, {"fright_pct": 1000, "fright_ticks": 1200})), "the highest fright")
	assert_false(_loads(_with(data, walker, {"fright_pct": 1001})), "fright_pct 1,001")
	assert_false(_loads(_with(data, walker, {"fright_ticks": 1201})), "fright_ticks 1,201")
	assert_false(_loads(_with(data, walker, {"fright_pct": 0})), "a fright time with no percent")
	assert_false(_loads(_with(data, walker, {"fright_ticks": 0})), "a fright percent with no time")
	assert_true(_loads(_with(data, walker, {"fright_pct": 0, "fright_ticks": 0})), "no fright")
	assert_true(_loads(_with(data, flyer, {"low_ticks": 1200})), "the longest lure")
	assert_true(_loads(_with(data, flyer, {"low_ticks": 0})), "not low")
	assert_false(_loads(_with(data, flyer, {"low_ticks": 1201})), "low_ticks 1,201")
	assert_false(_loads(_with(data, walker, {"low_ticks": 0})), "low_ticks on a walker")
	var extra: Dictionary = data.duplicate(true)
	(extra["enemies"][flyer] as Dictionary)["low"] = 1
	assert_false(_loads(extra), "an unknown key")


# Snapshot, restore and continue with every new tower (docs/ARCHITECTURE.md 14.13)

func _battle() -> Battle:
	var waves: Array = [
		{"groups": [Fx.group("scamp", 8, 0, 600), Fx.group("flitter", 6, 500, 400, 2), Fx.group("shellback", 3, 1000, 900),
			Fx.group("bubbler", 3, 2000, 900, 2), Fx.group("dusk_moth", 2, 3000, 1500)]},
		{"groups": [Fx.group("grumblesack", 1), Fx.group("gatecrasher", 2, 1500, 2000), Fx.group("mender", 2, 0, 1500, 2),
			Fx.group("pip", 12, 2000, 200, 2), Fx.group("puffball", 3, 3000, 800), Fx.group("flitter", 8, 1000, 250)]},
		{"groups": [Fx.group("skitter", 6, 0, 400, 2), Fx.group("moon_moth", 1, 500), Fx.group("shellback", 4, 500, 1200)]},
	]
	var b: Battle = Battle.create(Fx.level(Fx.FEATURE_GRID, waves, {"towers": Tx.ALL, "start_gold": 5000, "gates": 1}, catalog), catalog, true, [])
	assert_not_null(b)
	return b


func _act(b: Battle) -> void:
	if b.phase == Battle.Phase.BUILD:
		match b.waves_started:
			0:
				b.place_tower(Vector2i(2, 1), &"moth_lantern")
				b.place_tower(Vector2i(1, 5), &"scarecrow")
				b.place_tower(Vector2i(4, 5), &"bramble_cottage")
				b.place_tower(Vector2i(1, 8), &"longbow_loft")
				b.place_tower(Vector2i(4, 8), &"snow_fort")
				for cell: Vector2i in [Vector2i(2, 1), Vector2i(1, 5), Vector2i(4, 5), Vector2i(4, 8)]:
					b.upgrade_tower(cell)
			1:
				for cell: Vector2i in [Vector2i(2, 1), Vector2i(1, 5), Vector2i(4, 5), Vector2i(4, 8)]:
					b.upgrade_tower(cell, 1)
				b.place_gate(Vector2i(5, 10))
			2:
				b.remove_gate(Vector2i(5, 10))
		b.start_next_wave()
		return
	if b.waves_started == 2 and b.next_wave_info()["refusal"] == &"" and b.tick % 40 == 0:
		b.start_next_wave()


func _play(save_every: int) -> Dictionary:
	var b: Battle = _battle()
	var snaps: PackedStringArray = PackedStringArray()
	var events: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {"fright": 0, "low": 0, "pulse": 0, "line": 0, "low_hit": 0, "garland": 0}
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < 20000:
		_act(b)
		if b.phase != Battle.Phase.WAVE:
			break
		var flyers: Dictionary = {}
		for e: EnemyState in b.enemies:
			if e.flying:
				flyers[e.id] = true
		b.step()
		for event: Dictionary in b.take_events():
			events.append(var_to_str(event))
			if event["kind"] != &"fired":
				continue
			var hit: Array = event["targets"]
			match event["tower"]:
				&"bramble_cottage":
					seen["pulse"] += 1 if hit.size() > 1 else 0
				&"snow_fort":
					seen["line"] += 1 if hit.size() > 1 else 0
				&"moth_lantern":
					seen["garland"] += 1 if hit.size() > 1 else 0
			if event["tower"] != &"moth_lantern":
				for id: int in hit:
					if flyers.has(id) and not b.catalog.tower(event["tower"]).stats(1, -1).hits_air:
						seen["low_hit"] += 1
		for e: EnemyState in b.enemies:
			seen["fright"] += 1 if e.fright_pct > 0 else 0
			seen["low"] += 1 if e.low_ticks > 0 else 0
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


func test_restore_with_every_new_tower_continues_identically_contract_14_13() -> void:
	var plain: Dictionary = _play(0)
	var seen: Dictionary = plain["seen"]
	print("    sim: new towers run ended at tick %d, result %s, seen %s" % [plain["tick"], str(plain["result"]), str(seen)])
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
