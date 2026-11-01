# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The support towers: Lullaby Bell slows and both Bell paths, Bakery boosts and both
## Bakery paths, what stacks, and how boosts meet the reload timer (RULES 5.2, 5.5,
## 5.8, 8.5 to 8.7).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const ALL_TOWERS: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _line(groups: Array, stats: Catalog = null) -> Battle:
	return Fx.battle(Fx.LINE_GRID, [{"groups": groups}], {"start_gold": 9000, "towers": ALL_TOWERS}, stats if stats != null else catalog)


func _cluster(groups: Array, stats: Catalog = null) -> Battle:
	return Fx.battle(Fx.CLUSTER_GRID, [{"groups": groups}], {"start_gold": 9000, "towers": ALL_TOWERS}, stats if stats != null else catalog)


## Builds a tower and upgrades it to the tier (and path at tier 3).
func _build(b: Battle, cell: Vector2i, type: StringName, tier: int = 1, spec: int = -1) -> void:
	assert_eq(b.place_tower(cell, type), Battle.DONE, "build %s" % type)
	if tier >= 2:
		assert_eq(b.upgrade_tower(cell), Battle.DONE)
	if tier >= 3:
		assert_eq(b.upgrade_tower(cell, spec), Battle.DONE)


func _in_ring(b: Battle, enemy: EnemyState, cell: Vector2i, reach: int) -> bool:
	var d: Vector2i = enemy.pos - Sim.center(cell)
	return d.x * d.x + d.y * d.y <= reach * 200 * reach * 200


func test_a_bell_slows_walkers_in_its_ring_and_the_slow_lingers_rules_5_5_and_8_5() -> void:
	var bell: TowerStats = Fx.stats(catalog, &"lullaby_bell", 1)
	var linger: int = bell.slow_ms / Sim.MS_PER_TICK
	var b: Battle = _line([Fx.group("scamp", 1)])
	_build(b, Vector2i(2, 3), &"lullaby_bell")
	b.start_next_wave()
	var scamp: EnemyState = null
	var last_in: int = -1
	var slowed_ticks: Array[int] = []
	while b.phase == Battle.Phase.WAVE and b.tick < 400:
		# The Bell acts on positions before movement (8.1 step 3).
		var was_in: bool = scamp != null and _in_ring(b, scamp, Vector2i(2, 3), bell.reach)
		var before: Vector2i = scamp.pos if scamp != null else Vector2i.ZERO
		var at: int = b.tick
		b.step()
		if scamp == null:
			scamp = b.enemy_with_id(0)
			continue
		if b.enemy_with_id(0) == null:
			break
		if was_in:
			last_in = at
			assert_eq([scamp.slow_pct, scamp.slow_ticks], [bell.slow_pct, linger], "tick %d: in the ring, the Bell's slow with 1.0 s left" % at)
		if scamp.slow_pct > 0:
			slowed_ticks.append(at)
			var speed: int = catalog.enemy(&"scamp").speed
			assert_eq((scamp.pos - before).y, speed * 10 * (100 - bell.slow_pct) / 100, "it moves at speed times (1 minus the slow)")
	assert_true(last_in > 0, "the Scamp passed the ring")
	assert_eq(slowed_ticks.back(), last_in + linger - 1, "the slow lingers 1.0 s after it leaves the ring")
	assert_eq(scamp.slow_pct, 0, "then it is gone")


func test_bells_slow_flyers_only_as_a_night_bell_rules_5_5_and_6_5() -> void:
	for spec: int in [-1, 0, 1]:
		var b: Battle = _line([Fx.group("flitter", 1)])
		_build(b, Vector2i(2, 3), &"lullaby_bell", 1 if spec < 0 else 3, spec)
		var stats: TowerStats = b.tower_at(Vector2i(2, 3)).stats
		b.start_next_wave()
		var most: int = 0
		while b.phase == Battle.Phase.WAVE and b.tick < 400:
			b.step()
			var flitter: EnemyState = b.enemy_with_id(0)
			if flitter != null:
				most = maxi(most, flitter.slow_pct)
		assert_eq(stats.hits_air, spec == 1, "spec %d hits flyers" % spec)
		assert_eq(most, stats.slow_pct if stats.hits_air else 0, "spec %d: the flyer's slow" % spec)


func test_hush_bell_is_the_strongest_slow_and_slows_never_add_up_rules_5_5_and_8_7() -> void:
	var b: Battle = _line([Fx.group("shellback", 1)])
	_build(b, Vector2i(2, 3), &"lullaby_bell", 3, 0)
	_build(b, Vector2i(4, 3), &"lullaby_bell", 2)
	b.start_next_wave()
	var most: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 300:
		b.step()
		var e: EnemyState = b.enemy_with_id(0)
		if e != null:
			most = maxi(most, e.slow_pct)
	assert_eq(most, Fx.stats(catalog, &"lullaby_bell", 3, 0).slow_pct, "two Bells: only the strongest slow")


func test_a_bell_slow_is_not_a_hit_so_a_bubble_does_not_stop_it_rules_6_2() -> void:
	var b: Battle = _line([Fx.group("bubbler", 1)])
	_build(b, Vector2i(2, 1), &"lullaby_bell")
	b.start_next_wave()
	Fx.steps(b, 10)
	var bubbler: EnemyState = b.enemy_with_id(0)
	assert_true(bubbler.slow_pct > 0, "slowed")
	assert_true(bubbler.bubble, "the bubble is still up")
	assert_eq(Fx.of_kind(Fx.log_ticks(b, 1), &"popped").size(), 0)


func test_a_jam_slow_and_a_bell_slow_share_one_slot_rules_8_5() -> void:
	# A tier 2 Bell (45%) beats the Jam (40%, 3.0 s); when the Bell's linger runs out
	# the creature is no longer slowed, because one slot held the stronger slow only.
	var bell: TowerStats = Fx.stats(catalog, &"lullaby_bell", 2)
	var jam: TowerStats = Fx.stats(catalog, &"pumpkin_catapult", 3, 1)
	assert_true(bell.slow_pct > jam.slow_pct and bell.slow_ms < jam.slow_ms, "the data makes this case")
	var b: Battle = _line([Fx.group("shellback", 1)])
	_build(b, Vector2i(2, 1), &"pumpkin_catapult", 3, 1)
	_build(b, Vector2i(4, 1), &"lullaby_bell", 2)
	b.start_next_wave()
	var seen: Array[int] = []
	while b.phase == Battle.Phase.WAVE and b.tick < 600:
		b.step()
		var e: EnemyState = b.enemy_with_id(0)
		if e != null and not seen.has(e.slow_pct):
			seen.append(e.slow_pct)
	assert_true(seen.has(bell.slow_pct), "the Bell's slow held the slot")


func test_bells_and_bakeries_never_fire_and_have_no_aim_rules_5_1() -> void:
	var b: Battle = _cluster([Fx.group("scamp", 3, 0, 300)])
	_build(b, Vector2i(2, 1), &"lullaby_bell")
	_build(b, Vector2i(4, 1), &"bakery")
	assert_eq(b.set_aim(Vector2i(2, 1), TowerState.Aim.LAST), &"no_aim")
	assert_eq(b.set_aim(Vector2i(4, 1), TowerState.Aim.LAST), &"no_aim")
	b.start_next_wave()
	b.take_events()
	assert_eq(Fx.of_kind(Fx.log_ticks(b, 200), &"fired").size(), 0)


func test_bakery_reach_covers_the_eight_tiles_around_it_rules_5_8_and_8_6() -> void:
	var b: Battle = _cluster([Fx.group("scamp", 1)])
	_build(b, Vector2i(2, 2), &"bakery")
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(4, 1), Vector2i(4, 2)]:
		_build(b, cell, &"sling_post")
	var boost: int = Fx.stats(catalog, &"bakery", 1).boost_pct
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		assert_eq(b.tower_numbers(cell)["got_pct"], boost, "%s is in reach (a diagonal is 1.41 tiles)" % cell)
	for cell: Vector2i in [Vector2i(4, 1), Vector2i(4, 2)]:
		assert_eq(b.tower_numbers(cell)["got_pct"], 0, "%s is 2 tiles or more away" % cell)
	assert_eq(b.tower_numbers(Vector2i(2, 2))["boosting"], 3)


func test_a_bakery_never_boosts_bells_bakeries_or_itself_rules_5_8() -> void:
	var b: Battle = _cluster([Fx.group("scamp", 1)])
	_build(b, Vector2i(2, 2), &"bakery")
	_build(b, Vector2i(1, 1), &"bakery")
	_build(b, Vector2i(2, 1), &"lullaby_bell")
	for cell: Vector2i in [Vector2i(2, 2), Vector2i(1, 1), Vector2i(2, 1)]:
		var numbers: Dictionary = b.tower_numbers(cell)
		assert_eq([numbers["got_pct"], numbers["got_damage"]], [0, 0], "%s gets nothing" % cell)
		if b.tower_at(cell).kind == &"boost":
			assert_eq(numbers["boosting"], 0, "%s boosts nothing" % cell)


func test_only_the_best_boost_of_each_kind_counts_rules_8_6_and_8_7() -> void:
	var oven: TowerStats = Fx.stats(catalog, &"bakery", 3, 0)
	var kitchen: TowerStats = Fx.stats(catalog, &"bakery", 3, 1)
	var b: Battle = _cluster([Fx.group("scamp", 1)])
	_build(b, Vector2i(2, 1), &"sling_post")
	_build(b, Vector2i(1, 1), &"bakery")
	_build(b, Vector2i(2, 2), &"bakery", 2)
	assert_eq(b.tower_numbers(Vector2i(2, 1))["got_pct"], Fx.stats(catalog, &"bakery", 2).boost_pct, "the best, not the sum")
	b.upgrade_tower(Vector2i(2, 2), 0)
	b.upgrade_tower(Vector2i(1, 1))
	b.upgrade_tower(Vector2i(1, 1), 1)
	var numbers: Dictionary = b.tower_numbers(Vector2i(2, 1))
	assert_eq([numbers["got_pct"], numbers["got_damage"]], [oven.boost_pct, kitchen.boost_damage], "a Grand Oven's rate and a Spice Kitchen's damage apply together")


func test_boosts_change_at_once_when_a_bakery_is_built_upgraded_or_sold_rules_8_6() -> void:
	var b: Battle = _cluster([Fx.group("scamp", 1)])
	_build(b, Vector2i(2, 1), &"sling_post")
	assert_eq(b.tower_numbers(Vector2i(2, 1))["got_pct"], 0)
	_build(b, Vector2i(2, 2), &"bakery")
	assert_eq(b.tower_numbers(Vector2i(2, 1))["got_pct"], Fx.stats(catalog, &"bakery", 1).boost_pct)
	b.upgrade_tower(Vector2i(2, 2))
	assert_eq(b.tower_numbers(Vector2i(2, 1))["got_pct"], Fx.stats(catalog, &"bakery", 2).boost_pct)
	b.sell_tower(Vector2i(2, 2))
	assert_eq(b.tower_numbers(Vector2i(2, 1))["got_pct"], 0)
	_build(b, Vector2i(2, 2), &"bakery")
	b.sell_tower(Vector2i(2, 1))
	assert_eq(b.tower_numbers(Vector2i(2, 2))["boosting"], 0)


## The ticks of the first shots of a tower that always has a target, from RULES 5.2:
## each tick takes `drain` off; a shot at 0 or below adds `reload`, keeping the leftover.
func _expected_shots(drain: int, reload: int, ticks: int) -> Array[int]:
	var out: Array[int] = []
	var timer: int = 0
	for t: int in ticks:
		timer -= drain
		if timer <= 0:
			out.append(t)
			timer += reload
	return out


func test_a_rate_boost_runs_the_reload_timer_faster_rules_5_2_and_8_6() -> void:
	# A creature that stays in reach the whole time: a slow, sturdy Shellback.
	var slow: Catalog = Fx.catalog_with_enemy("shellback", {"speed": 1, "health": 1000000})
	for tier: int in [0, 1, 2]:
		var b: Battle = _cluster([Fx.group("shellback", 1)], slow)
		_build(b, Vector2i(2, 1), &"sling_post")
		var boost: int = 0
		if tier > 0:
			_build(b, Vector2i(2, 2), &"bakery", tier)
			boost = Fx.stats(slow, &"bakery", tier).boost_pct
		b.start_next_wave()
		b.take_events()
		var shots: Array[int] = Fx.ticks(Fx.of_kind(Fx.log_ticks(b, 400), &"fired"))
		var reload: int = Fx.stats(slow, &"sling_post", 1).reload_ms * 100
		assert_eq(shots, _expected_shots(Sim.MS_PER_TICK * (100 + boost), reload, 400), "boost %d%%" % boost)
		if tier == 2:
			var plain: int = _expected_shots(Sim.MS_PER_TICK * 100, reload, 400).size()
			assert_true(shots.size() * 100 >= plain * (100 + boost) - 100, "+25%% means about 1.25 times the shots: %d against %d" % [shots.size(), plain])


func test_the_reload_floor_and_the_upgrade_cap_hold_with_a_boost_rules_5_2() -> void:
	# The shortest reload in the data (the Quickshot) next to the biggest boost (the
	# Grand Oven). Between ticks the timer stays 0 to the tower's own reload: a tick
	# drains 5000 x 1.4 = 7000, less than any reload, so a shot never leaves it below 0.
	var b: Battle = _cluster([Fx.group("scamp", 12, 2000, 400)])
	_build(b, Vector2i(2, 1), &"sling_post", 3, 0)
	_build(b, Vector2i(2, 2), &"bakery", 3, 0)
	_build(b, Vector2i(1, 1), &"sling_post", 2)
	var quick: TowerState = b.tower_at(Vector2i(2, 1))
	var tier2: TowerState = b.tower_at(Vector2i(1, 1))
	assert_eq(quick.got_pct, Fx.stats(catalog, &"bakery", 3, 0).boost_pct)
	b.start_next_wave()
	var fired: int = 0
	var idle_zero: bool = false
	var capped: bool = false
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		b.step()
		for event: Dictionary in b.take_events():
			if event["kind"] == &"fired" and event["cell"] == quick.cell:
				fired += 1
		for tower: TowerState in [quick, tier2]:
			assert_true(tower.reload >= 0 and tower.reload <= tower.stats.reload_ms * 100, "tick %d: timer %d inside 0 to its reload" % [b.tick, tower.reload])
		if b.tick < 40:
			idle_zero = idle_zero or quick.reload == 0
		if b.tick == 60 and not capped:
			# An upgrade with a boost still caps the timer at the new reload (5.2).
			var before: int = tier2.reload
			b.upgrade_tower(tier2.cell, 0)
			assert_eq(tier2.reload, mini(before, tier2.stats.reload_ms * 100))
			capped = true
	assert_true(idle_zero, "a boosted tower with no target waits at 0, never below")
	assert_true(fired > 10, "the Quickshot fired %d times" % fired)
	assert_true(capped)


func test_a_saved_timer_below_0_is_refused_with_a_boost_too_rules_5_2() -> void:
	var b: Battle = _cluster([Fx.group("shellback", 4, 0, 600)])
	_build(b, Vector2i(2, 1), &"sling_post", 3, 0)
	_build(b, Vector2i(2, 2), &"bakery", 3, 0)
	b.start_next_wave()
	Fx.steps(b, 30)
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	for value: int in [0, b.tower_at(Vector2i(2, 1)).stats.reload_ms * 100]:
		data["towers"][0]["reload"] = value
		assert_not_null(Battle.from_data(data, catalog), "accepts %d" % value)
	data["towers"][0]["reload"] = -1
	assert_null(Battle.from_data(data, catalog), "refuses -1")


func test_a_tower_fires_at_most_once_a_tick_and_never_banks_shots_rules_5_2() -> void:
	# A card brings the Quickshot to the 50 ms floor, so one boosted tick takes more
	# off the timer than the whole reload. It fires once a tick, and a timer still
	# below 0 after a shot waits at 0. A save of that state loads; -1 still does not.
	var b: Battle = _cluster([Fx.group("shellback", 6, 0, 300)])
	assert_eq(b.add_effects([{"type": "tower_add", "tower": "sling_post", "stat": "reload_ms", "amount": -1000}] as Array[Dictionary], false), Battle.DONE)
	_build(b, Vector2i(2, 1), &"sling_post", 3, 0)
	_build(b, Vector2i(2, 2), &"bakery", 3, 0)
	var quick: TowerState = b.tower_at(Vector2i(2, 1))
	var reload: int = quick.stats.reload_ms * 100
	assert_eq(quick.stats.reload_ms, 50)
	assert_true(Sim.MS_PER_TICK * (100 + quick.got_pct) > reload, "a boosted tick drains more than one reload")
	b.start_next_wave()
	var shot_ticks: int = 0
	var clamped: bool = false
	while b.phase == Battle.Phase.WAVE and b.tick < 400:
		b.step()
		var shots: int = 0
		for event: Dictionary in b.take_events():
			if event["kind"] == &"fired" and event["cell"] == quick.cell:
				shots += 1
		assert_true(shots <= 1, "tick %d: %d shots" % [b.tick, shots])
		assert_true(quick.reload >= 0 and quick.reload <= reload, "tick %d: timer %d inside 0 to %d" % [b.tick, quick.reload, reload])
		if shots == 1:
			shot_ticks += 1
			clamped = clamped or quick.reload == 0
		if b.tick == 60:
			var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
			assert_not_null(Battle.from_data(data, catalog), "a real save loads")
			data["towers"][0]["reload"] = -1
			assert_null(Battle.from_data(data, catalog), "a timer below 0 never loads, even with the card")
	assert_true(shot_ticks > 20, "it fired on %d ticks" % shot_ticks)
	assert_true(clamped, "a shot that left the timer below 0 set it to 0")


func test_spice_kitchen_damage_counts_before_armor_rules_5_8_and_8_3() -> void:
	var quick: TowerStats = Fx.stats(catalog, &"sling_post", 3, 0)
	var kitchen: TowerStats = Fx.stats(catalog, &"bakery", 3, 1)
	var armor: int = catalog.enemy(&"shellback").armor
	for with_kitchen: bool in [false, true]:
		var b: Battle = _cluster([Fx.group("shellback", 1)])
		_build(b, Vector2i(2, 1), &"sling_post", 3, 0)
		if with_kitchen:
			_build(b, Vector2i(2, 2), &"bakery", 3, 1)
		b.start_next_wave()
		b.step()
		var e: EnemyState = b.enemy_with_id(0)
		var hit: int = quick.damage + (kitchen.boost_damage if with_kitchen else 0)
		assert_eq(e.max_health - e.health, maxi(1, hit - armor), "kitchen %s" % with_kitchen)
	var b2: Battle = _cluster([Fx.group("shellback", 1)])
	_build(b2, Vector2i(2, 1), &"sling_post", 3, 0)
	_build(b2, Vector2i(2, 2), &"bakery", 3, 1)
	assert_eq(b2.tower_numbers(Vector2i(2, 1))["got_damage"], kitchen.boost_damage, "shown on the tower")
	assert_eq(b2.tower_numbers(Vector2i(2, 1))["damage"], quick.damage, "its own damage stays its own")
