# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Numbers that play makes grow never pass their load ceilings (docs/ARCHITECTURE.md
## 5.5, 5.6; security review 2026-10-29, L8): a battle loaded at each ceiling plays on,
## and every save it makes loads again. Spent gold stops at BIG, as gold does. No
## creature appears once the next id is 2^31, or when it would take the crowd past
## MAX_ENEMIES. No release begins past MAX_RELEASES. A battle at the tick ceiling is lost.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const ENTRANCE: Array = [3, 0]                         # LINE_GRID's entrance

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _battle(waves: Array, stats: Catalog = null) -> Battle:
	return Fx.battle(Fx.LINE_GRID, waves, {"start_gold": 9000}, stats if stats != null else catalog)


func _data(b: Battle) -> Dictionary:
	return JSON.parse_string(JSON.stringify(b.to_data()))


func _load(data: Dictionary, stats: Catalog = null) -> Battle:
	return Battle.from_data(JSON.parse_string(JSON.stringify(data)), stats if stats != null else catalog)


## Releases of Scamps at the entrance, `total` creatures in all, none due for a minute.
func _fill(data: Dictionary, total: int, per_release: int = 200) -> void:
	var gap: int = 60000 / Sim.MS_PER_TICK
	var list: Array = data["releases"]
	while total > 0:
		var n: int = mini(total, per_release)
		list.append({"enemy": "scamp", "wave": data["running"][0], "left": n, "next": int(data["tick"]) + gap,
			"gap": gap, "from": ENTRANCE.duplicate(), "to": ENTRANCE.duplicate(), "progress": Sim.UNIT})
		total -= n


## Plays n ticks. After each, the battle's save must load. Returns the events.
func _play(b: Battle, n: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for i: int in n:
		b.step()
		events.append_array(b.take_events())
		if b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE:
			assert_not_null(Fx.restored(b), "the save after tick %d loads" % b.tick)
	return events


# Spent gold.

func test_spent_gold_stops_at_big_as_gold_does() -> void:
	var cell: Vector2i = Vector2i(2, 1)
	var b: Battle = _battle([{"groups": [Fx.group("scamp", 3)]}, {"groups": [Fx.group("scamp", 3)]}])
	assert_eq(b.place_tower(cell, &"sling_post"), Battle.DONE)
	var data: Dictionary = _data(b)
	data["towers"][0]["spent_now"] = Battle.BIG
	data["towers"][0]["spent_before"] = Battle.BIG
	var at: Battle = _load(data)
	assert_not_null(at, "both at BIG loads")
	assert_eq(at.upgrade_tower(cell), Battle.DONE)
	assert_eq(at.tower_at(cell).spent_now, Battle.BIG, "a build phase purchase stops at BIG")
	assert_not_null(Fx.restored(at), "and its save loads")
	assert_eq(at.start_next_wave(), Battle.DONE)
	assert_eq(at.tower_at(cell).spent_before, Battle.BIG, "this build phase's purchases join the rest, at most BIG")
	assert_eq(at.tower_at(cell).spent_now, 0)
	assert_not_null(Fx.restored(at), "and its save loads")
	assert_eq(at.upgrade_tower(cell, 0), Battle.DONE)
	assert_eq(at.tower_at(cell).spent_before, Battle.BIG, "a purchase during a wave stops at BIG")
	assert_not_null(Fx.restored(at), "and its save loads")
	assert_eq(at.sell_value(cell), Battle.BIG * catalog.rules.refund_pct / 100)


func test_real_purchases_still_add_up() -> void:
	var cell: Vector2i = Vector2i(2, 1)
	var b: Battle = _battle([{"groups": [Fx.group("scamp", 3)]}])
	b.place_tower(cell, &"sling_post")
	b.upgrade_tower(cell)
	var built: int = Fx.stats(catalog, &"sling_post", 1).cost
	var tier2: int = Fx.stats(catalog, &"sling_post", 2).cost
	assert_eq(b.tower_at(cell).spent_now, built + tier2)
	b.start_next_wave()
	assert_eq(b.tower_at(cell).spent_before, built + tier2)
	b.upgrade_tower(cell, 1)
	assert_eq(b.tower_at(cell).spent_before, built + tier2 + Fx.stats(catalog, &"sling_post", 3, 1).cost)


# The next id.

## One Scamp on the map with the id below `next_id`; two more due every second.
func _near_id_ceiling(next_id: int) -> Dictionary:
	var b: Battle = _battle([{"groups": [Fx.group("scamp", 3, 0, 1000)]}])
	b.start_next_wave()
	b.step()
	var data: Dictionary = _data(b)
	assert_eq((data["enemies"] as Array).size(), 1)
	data["enemies"][0]["id"] = next_id - 1
	data["next_id"] = next_id
	return data


func test_no_creature_appears_once_the_next_id_reaches_its_ceiling() -> void:
	var at: Battle = _load(_near_id_ceiling(Battle.ID_CEILING - 1))
	assert_not_null(at, "a next id one below 2^31 loads")
	var spawned: Array[Dictionary] = Fx.events_of(_play(at, 40), &"spawned")
	assert_eq(spawned.size(), 1, "the second Scamp takes the last id, the third is left out")
	assert_eq(spawned[0]["id"], Battle.ID_CEILING - 1)
	assert_eq(at._next_id, Battle.ID_CEILING, "the next id stops at 2^31")
	Fx.run_wave(at)
	assert_eq(at.phase, Battle.Phase.WON, "the wave still ends")


func test_a_release_goes_on_without_creatures_at_the_id_ceiling() -> void:
	var data: Dictionary = _near_id_ceiling(Battle.ID_CEILING)
	data["releases"] = [{"enemy": "scamp", "wave": 0, "left": 3, "next": data["tick"], "gap": 1,
		"from": ENTRANCE.duplicate(), "to": ENTRANCE.duplicate(), "progress": Sim.UNIT}]
	var at: Battle = _load(data)
	assert_not_null(at, "a next id of 2^31 loads")
	var events: Array[Dictionary] = _play(at, 3)
	assert_true(Fx.events_of(events, &"spawned").is_empty(), "no Scamp appears")
	assert_true(at._releases.is_empty(), "the release has run its course")
	assert_eq(at._next_id, Battle.ID_CEILING)
	assert_eq(at.enemies.size(), 1, "the Scamp on the map is still there")


func test_ids_are_never_used_twice() -> void:
	var at: Battle = _load(_near_id_ceiling(Battle.ID_CEILING - 1))
	_play(at, 40)
	var seen: Array[int] = []
	for enemy: EnemyState in at.enemies:
		assert_false(seen.has(enemy.id), "id %d once" % enemy.id)
		seen.append(enemy.id)
	assert_eq(seen, [Battle.ID_CEILING - 2, Battle.ID_CEILING - 1] as Array[int], "in id order")


# The tick.

func test_a_battle_at_the_tick_ceiling_is_lost() -> void:
	var b: Battle = _battle([{"groups": [Fx.group("scamp", 3, 0, 1000)]}, {"groups": [Fx.group("scamp", 3)]}])
	var data: Dictionary = _data(b)
	data["tick"] = Battle.BIG - 3
	var at: Battle = _load(data)
	assert_not_null(at, "a build phase three ticks below the ceiling loads")
	assert_eq(at.start_next_wave(), Battle.DONE)
	_play(at, 3)
	assert_eq(at.tick, Battle.BIG)
	assert_eq(at.phase, Battle.Phase.WAVE)
	var restored: Battle = Fx.restored(at)
	assert_not_null(restored, "a wave at the tick ceiling loads")
	for battle: Battle in [at, restored]:
		battle.take_events()
		battle.step()
		assert_eq(battle.phase, Battle.Phase.LOST, "the next tick would pass the ceiling: the battle is lost")
		assert_eq(battle.tick, Battle.BIG, "and the tick stays at its ceiling")
		assert_eq(battle.lives, 0, "with no lives left, as every lost battle")
		assert_eq(battle.take_events(), [{"kind": &"lost"}] as Array[Dictionary])
		assert_eq(battle.result()["won"], false)
		battle.step()
		assert_eq(battle.tick, Battle.BIG, "a lost battle steps no more")
	assert_eq(Fx.snapshot(at), Fx.snapshot(restored), "the same with or without a save and load")


# The crowd.

## A wave of `count` Scamps, one a second, its first on the map; the save of that moment.
func _first_scamp(count: int) -> Dictionary:
	var b: Battle = _battle([{"groups": [Fx.group("scamp", count, 0, 1000)]}])
	b.start_next_wave()
	b.step()
	return _data(b)


func test_a_group_creature_that_would_pass_the_crowd_ceiling_is_left_out() -> void:
	var data: Dictionary = _first_scamp(5)
	_fill(data, Battle.MAX_ENEMIES - 1)
	var full: Battle = _load(data)
	assert_not_null(full, "exactly MAX_ENEMIES in all loads")
	var events: Array[Dictionary] = _play(full, 40)
	assert_true(Fx.events_of(events, &"spawned").is_empty(), "two Scamps fell due and neither came")
	assert_eq(full._crowd(), Battle.MAX_ENEMIES)
	var room: Dictionary = _first_scamp(5)
	_fill(room, Battle.MAX_ENEMIES - 2)
	var one: Battle = _load(room)
	assert_eq(Fx.events_of(_play(one, 40), &"spawned").size(), 1, "with room for one, one comes")
	assert_eq(one._crowd(), Battle.MAX_ENEMIES)


func test_the_crowd_ceiling_gives_the_same_play_after_a_save_and_load() -> void:
	# Towers near the entrance defeat Scamps, so the crowd falls and rises again.
	var b: Battle = _battle([{"groups": [Fx.group("scamp", 60, 0, 250)]}])
	for cell: Vector2i in [Vector2i(2, 1), Vector2i(4, 1), Vector2i(2, 3), Vector2i(4, 3)]:
		b.place_tower(cell, &"sling_post")
	b.start_next_wave()
	b.step()
	var data: Dictionary = _data(b)
	_fill(data, Battle.MAX_ENEMIES - 3)
	data["lives"] = Battle.MAX_LIVES
	data["start_lives"] = Battle.MAX_LIVES
	var straight: Battle = _load(data)
	var saved: Battle = _load(data)
	var spawned: int = 0
	var defeated: int = 0
	for i: int in 300:
		straight.step()
		var events: Array[Dictionary] = straight.take_events()
		spawned += Fx.events_of(events, &"spawned").size()
		defeated += Fx.events_of(events, &"defeated").size()
		assert_true(straight._crowd() <= Battle.MAX_ENEMIES, "the crowd stays within its ceiling")
		saved.step()
		if i % 7 == 0:
			var restored: Battle = Fx.restored(saved)
			assert_not_null(restored, "the save after tick %d loads" % saved.tick)
			saved = restored
	assert_eq(straight.phase, Battle.Phase.WAVE)
	assert_true(defeated > 0, "Scamps were defeated: %d" % defeated)
	assert_true(spawned > 2 and spawned < 60, "some came as room opened, some were left out: %d" % spawned)
	assert_eq(Fx.snapshot(saved), Fx.snapshot(straight), "saved and loaded every 7 ticks, the battle is the same")


func test_a_boss_summon_that_would_pass_the_crowd_ceiling_is_left_out() -> void:
	var summon: Dictionary = catalog.enemy(&"grumblesack").summon
	var every: int = int(summon["every_ms"]) / Sim.MS_PER_TICK
	for room: bool in [false, true]:
		var b: Battle = _battle([{"groups": [Fx.group("grumblesack", 1)]}])
		b.start_next_wave()
		b.step()
		var data: Dictionary = _data(b)
		data["enemies"][0]["summon_at"] = data["tick"]
		_fill(data, Battle.MAX_ENEMIES - 1 - int(summon["count"]) + (0 if room else 1))
		var at: Battle = _load(data)
		assert_not_null(at, "the boss and its crowd load")
		var due: int = at.tick
		var released: Array[Dictionary] = Fx.events_of(_play(at, 1), &"released")
		assert_eq(released.size(), 1 if room else 0, "with room the boss summons, without it it does not")
		assert_eq(at.enemies[0].summon_at, due + every, "its next summon is due as usual")
		assert_true(at._crowd() <= Battle.MAX_ENEMIES)


# Releases.

func test_no_release_begins_past_max_releases() -> void:
	var weak: Catalog = Fx.catalog_with_enemy("puffball", {"health": 1})
	for room: bool in [false, true]:
		var b: Battle = _battle([{"groups": [Fx.group("puffball", 1)]}], weak)
		b.start_next_wave()
		Fx.steps(b, 40)
		assert_eq(b.place_tower(Vector2i(2, 3), &"sling_post"), Battle.DONE)
		var data: Dictionary = _data(b)
		_fill(data, Battle.MAX_RELEASES - (1 if room else 0), 1)
		var at: Battle = _load(data, weak)
		assert_not_null(at, "%d releases load" % (data["releases"] as Array).size())
		var events: Array[Dictionary] = []
		for i: int in 60:
			at.step()
			events.append_array(at.take_events())
			assert_not_null(Battle.from_data(_data(at), weak), "the save after tick %d loads" % at.tick)
			if not Fx.events_of(events, &"defeated").is_empty():
				break
		assert_eq(Fx.events_of(events, &"defeated").size(), 1, "the Puffball fell")
		assert_eq(Fx.events_of(events, &"released").size(), 1 if room else 0, "its Puffs come only with room")
		assert_true(at._releases.size() <= Battle.MAX_RELEASES)
