# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Grumblesack's summons (RULES 6.3) and the release rules they follow (RULES 6.2).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")


## Steps until the phase leaves WAVE, logging [tick, event] pairs and the boss's
## step at the end of each tick.
func _log(b: Battle, limit: int = 2000) -> Array:
	var out: Array = []
	var ran: int = 0
	while b.phase == Battle.Phase.WAVE and ran < limit:
		var at: int = b.tick
		b.step()
		for event: Dictionary in b.take_events():
			out.append([at, event])
		ran += 1
	return out


func _spawns(log: Array, enemy: StringName) -> Array:
	var out: Array = []
	for entry: Array in log:
		if entry[1]["kind"] == &"spawned" and entry[1]["enemy"] == enemy:
			out.append(entry)
	return out


func test_two_scamps_every_6_seconds_at_its_spot_rules_6_3() -> void:
	var catalog: Catalog = Fx.catalog()
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"strength": 110, "groups": [Fx.group("grumblesack", 1)]}], {}, catalog, true)
	b.start_next_wave()
	Fx.steps(b, 120)
	var boss: EnemyState = b.enemy_with_id(0)
	assert_eq(boss.max_health, 2200, "2000 at strength 110")
	var spot: Vector2i = boss.pos
	var step: Array = [boss.from_cell, boss.to_cell, boss.progress]
	assert_eq(b.enemies.size(), 1, "nothing before 6.0 s")
	b.take_events()
	b.step()
	var first: EnemyState = b.enemy_with_id(1)
	assert_eq(first.type, &"scamp")
	assert_eq(first.wave, 0, "a summon belongs to its boss's wave")
	assert_eq(first.max_health, 44, "and uses its strength")
	assert_eq(Fx.events_of(b.take_events(), &"spawned")[0]["pos"], spot, "it appears where the boss stood")
	assert_eq(first.from_cell, step[0], "it finishes the boss's step")
	assert_eq(first.to_cell, step[1])
	var log: Array = _log(b)
	var scamps: Array = _spawns(log, &"scamp")
	var ticks: Array[int] = []
	for entry: Array in scamps:
		ticks.append(entry[0])
	# Tick 120 is already out of the log; the second Scamp of each batch comes 0.3 s later.
	assert_eq(ticks, [126, 240, 246] as Array[int])
	assert_eq(scamps[0][1]["pos"], spot, "the second Scamp appears at the same spot, though the boss moved on")
	assert_ne(scamps[1][1]["pos"], spot)
	assert_eq(scamps[1][1]["pos"], scamps[2][1]["pos"])


func test_a_begun_release_finishes_when_the_boss_falls_rules_6_2() -> void:
	var catalog: Catalog = Fx.catalog_with_enemy("grumblesack", {"health": 1})
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("grumblesack", 1)]}], {"start_gold": 500}, catalog)
	b.start_next_wave()
	Fx.steps(b, 121)
	assert_eq(b.enemies.size(), 2, "the batch has begun")
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.set_aim(Vector2i(2, 1), TowerState.Aim.LAST)
	b.take_events()
	var log: Array = _log(b)
	var defeated_at: int = -1
	for entry: Array in log:
		if entry[1]["kind"] == &"defeated" and entry[1]["enemy"] == &"grumblesack":
			defeated_at = entry[0]
	assert_eq(defeated_at, 121, "the boss falls between its two Scamps")
	var scamps: Array = _spawns(log, &"scamp")
	assert_eq(scamps.size(), 1, "one more Scamp, and no later batch")
	assert_eq(scamps[0][0], 126, "the second Scamp still comes")
	assert_eq(scamps[0][1]["pos"], Sim.center(Vector2i(3, 0)) + Vector2i(0, 120 * 400), "at the batch's spot")


func test_a_begun_release_finishes_when_the_boss_gets_through_rules_6_2() -> void:
	# A batch every 17 s with the second Scamp 1 s later: the boss gets through on
	# tick 349, between the batch at 340 and its second Scamp at 360.
	var catalog: Catalog = Fx.catalog_with_enemy("grumblesack", {"summon": {"enemy": "scamp", "count": 2, "every_ms": 17000, "gap_ms": 1000}})
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("grumblesack", 1)]}], {}, catalog, true)
	b.start_next_wave()
	var log: Array = _log(b)
	var leaked_boss: int = -1
	for entry: Array in log:
		if entry[1]["kind"] == &"leaked" and entry[1]["enemy"] == &"grumblesack":
			leaked_boss = entry[0]
	assert_eq(leaked_boss, 349)
	var ticks: Array[int] = []
	for entry: Array in _spawns(log, &"scamp"):
		ticks.append(entry[0])
	assert_eq(ticks, [340, 360] as Array[int])
	var cleared: int = -1
	for entry: Array in log:
		if entry[1]["kind"] == &"wave_cleared":
			cleared = entry[0]
	assert_true(cleared > 360, "the wave waits for the release to finish")
	assert_eq(b.phase, Battle.Phase.WON)
	assert_eq(b.lives, 40 - 20 - 2)


func test_released_walkers_take_their_own_route_rules_6_2_and_7_3() -> void:
	# On the fork the boss walks west (tie break). A Scamp released on the boss's step
	# finishes that step, then follows the shortest open route from there.
	var catalog: Catalog = Fx.catalog()
	var b: Battle = Fx.battle(Fx.FORK_GRID, [{"groups": [Fx.group("grumblesack", 1)]}], {}, catalog, true)
	b.start_next_wave()
	Fx.steps(b, 121)
	var scamp: EnemyState = b.enemy_with_id(1)
	var seen: Array[Vector2i] = []
	while b.enemy_with_id(1) != null:
		if not seen.has(scamp.to_cell):
			seen.append(scamp.to_cell)
		b.step()
	assert_true(seen.has(Vector2i(1, 5)), "the west branch")
	assert_eq(seen.back(), Vector2i(3, 9), "to the base")


func test_summons_count_for_their_wave_rules_4_9() -> void:
	var catalog: Catalog = Fx.catalog()
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("grumblesack", 1)]}, {"groups": [Fx.group("pip", 1)]}], {}, catalog, true)
	b.start_next_wave()
	Fx.steps(b, 127)
	# Boss bounty 100 plus two Scamps at 5: half of 110.
	assert_eq(b.next_wave_info()["bonus"], 55)


func test_ironshell_speeds_up_at_each_quarter_from_the_next_tick_rules_6_3() -> void:
	var catalog: Catalog = Fx.catalog()
	var shell: EnemyType = catalog.enemy(&"ironshell")
	var add: int = shell.speed_up["add"]
	var at: Array = shell.speed_up["at_pct"]
	assert_eq(at, [75, 50, 25], "RULES 6.3: 75%, 50% and 25%")
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("ironshell", 1)]}], {}, catalog)
	b.start_next_wave()
	b.step()
	var boss: EnemyState = b.enemy_with_id(0)
	assert_eq(boss.speed, shell.speed)
	boss.health = boss.max_health * 76 / 100
	b.step()
	assert_eq(boss.speed, shell.speed, "above 75%: no change")
	boss.health = boss.max_health * 75 / 100
	b.take_events()
	var before: Vector2i = boss.pos
	b.step()
	assert_eq((boss.pos - before).y, shell.speed * 10, "this tick still moves at the old speed")
	assert_eq(boss.speed, shell.speed + add, "at 75%: faster from the next tick")
	assert_eq(Fx.events_of(b.take_events(), &"sped_up"), [{"kind": &"sped_up", "id": 0, "speed": shell.speed + add}] as Array[Dictionary])
	before = boss.pos
	b.step()
	assert_eq((boss.pos - before).y, (shell.speed + add) * 10)
	boss.health = boss.max_health
	b.step()
	assert_eq(boss.speed, shell.speed + add, "healing never undoes a speed up")
	boss.health = boss.max_health * 20 / 100
	b.step()
	assert_eq(boss.speed, shell.speed + 3 * add, "one fall past 50% and 25% counts both: 0.4, 0.5, 0.6, 0.7")
	assert_eq(b.enemy_numbers(0)["base_speed"], shell.speed + 3 * add)


func test_moon_moth_releases_flitters_that_fly_from_its_spot_rules_6_3_and_6_5() -> void:
	var catalog: Catalog = Fx.catalog()
	var moth: EnemyType = catalog.enemy(&"moon_moth")
	var every: int = int(moth.summon["every_ms"]) / Sim.MS_PER_TICK
	var gap: int = int(moth.summon["gap_ms"]) / Sim.MS_PER_TICK
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("moon_moth", 1)]}], {}, catalog, true)
	b.start_next_wave()
	Fx.steps(b, every)
	var spot: Vector2i = b.enemy_with_id(0).pos
	var log: Array = _log(b, gap * 3)
	var flitters: Array = _spawns(log, moth.summon["enemy"])
	assert_eq(flitters.size(), moth.summon["count"])
	var ticks: Array[int] = []
	for entry: Array in flitters:
		ticks.append(entry[0])
		assert_eq(entry[1]["pos"], spot, "each at the spot where the batch began")
		var flitter: EnemyState = b.enemy_with_id(int(entry[1]["id"]))
		assert_true(flitter.flying)
		assert_eq(flitter.fly_from, spot, "flying straight to the base from there")
		assert_eq(flitter.wave, 0)
	assert_eq(ticks, [every, every + gap, every + 2 * gap] as Array[int])


func test_a_night_bell_slows_the_moon_moth_rules_6_3_and_5_5() -> void:
	var catalog: Catalog = Fx.catalog()
	var night: TowerStats = catalog.tower(&"lullaby_bell").stats(3, 1)
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("moon_moth", 1)]}], {"start_gold": 2000, "towers": ["lullaby_bell"]}, catalog, true)
	b.place_tower(Vector2i(2, 1), &"lullaby_bell")
	b.upgrade_tower(Vector2i(2, 1))
	b.upgrade_tower(Vector2i(2, 1), 1)
	b.start_next_wave()
	Fx.steps(b, 5)
	assert_eq(b.enemy_with_id(0).slow_pct, night.slow_pct)


func test_old_tusk_breaks_gates_in_its_own_time_rules_6_3_and_7_7() -> void:
	var catalog: Catalog = Fx.catalog()
	var tusk: EnemyType = catalog.enemy(&"old_tusk")
	assert_true(tusk.break_ms < catalog.enemy(&"gatecrasher").break_ms)
	var b: Battle = Fx.battle(Fx.FORK_GRID, [{"groups": [Fx.group("old_tusk", 1)]}], {"gates": 1}, catalog, true)
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	var log: Array = _log(b, 4000)
	var started: int = -1
	var broken: int = -1
	for entry: Array in log:
		if entry[1]["kind"] == &"break_started":
			started = entry[0]
		if entry[1]["kind"] == &"gate_broken":
			broken = entry[0]
	var arrive: int = (4 * Sim.UNIT + tusk.speed * 10 - 1) / (tusk.speed * 10) - 1
	assert_eq(started, arrive, "at the center before the gate, 4 tiles along its own route")
	assert_eq(broken - started, tusk.break_ms / Sim.MS_PER_TICK)


func test_old_tusk_releases_dusk_moths_once_at_half_health_rules_6_3() -> void:
	var catalog: Catalog = Fx.catalog()
	var tusk: EnemyType = catalog.enemy(&"old_tusk")
	var rel: Dictionary = tusk.release
	var gap: int = int(rel["gap_ms"]) / Sim.MS_PER_TICK
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("old_tusk", 1)]}], {}, catalog, true)
	b.start_next_wave()
	Fx.steps(b, 30)
	var boss: EnemyState = b.enemy_with_id(0)
	boss.health = boss.max_health * (int(rel["at_pct"]) + 1) / 100
	b.step()
	assert_eq(b._releases.size(), 0, "above half: nothing")
	boss.health = boss.max_health * int(rel["at_pct"]) / 100
	var fell_at: int = b.tick
	var log: Array = _log(b, 1 + gap * int(rel["count"]))
	var spot: Vector2i = Vector2i.ZERO
	for entry: Array in log:
		if entry[1]["kind"] == &"released":
			spot = entry[1]["pos"]
			assert_eq(entry[0], fell_at)
	var moths: Array = _spawns(log, rel["enemy"])
	var ticks: Array[int] = []
	for entry: Array in moths:
		ticks.append(entry[0])
		assert_eq(entry[1]["pos"], spot)
	var expected: Array[int] = []
	for k: int in int(rel["count"]):
		expected.append(fell_at + 1 + k * gap)
	assert_eq(ticks, expected, "starting on the next tick, 0.3 s apart")
	boss.health = 1
	assert_eq(_spawns(_log(b, 40), rel["enemy"]).size(), 0, "only the first time")


func test_old_tusk_releases_its_moths_even_if_the_same_hit_defeats_it_rules_6_3() -> void:
	var catalog: Catalog = Fx.catalog_with_enemy("old_tusk", {"health": 100})
	var bow: TowerStats = catalog.tower(&"longbow_loft").stats(3, 0)
	assert_true(bow.damage >= 100)
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("old_tusk", 1)]}], {"start_gold": 2000, "towers": ["longbow_loft"]}, catalog, true)
	b.place_tower(Vector2i(2, 1), &"longbow_loft")
	b.upgrade_tower(Vector2i(2, 1))
	b.upgrade_tower(Vector2i(2, 1), 0)
	b.start_next_wave()
	var log: Array = _log(b, 200)
	var defeated: int = -1
	for entry: Array in log:
		if entry[1]["kind"] == &"defeated" and entry[1]["enemy"] == &"old_tusk":
			defeated = entry[0]
	assert_eq(defeated, 0, "one arrow on its first tick")
	var moths: Array = _spawns(log, catalog.enemy(&"old_tusk").release["enemy"])
	assert_eq(moths.size(), catalog.enemy(&"old_tusk").release["count"])
	assert_eq(moths[0][0], 1)
