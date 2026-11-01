# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The tick's shortcuts change no result (docs/ARCHITECTURE.md 14.12): a bucket kept from
## the towers step for the next tick's rings, a towers step that buckets only when a tower
## is ready, and passes skipped when they have nothing to do. Each battle is played twice,
## once by step() and once making every bucket again, and both must give the same states
## and events. Also: rules whose creatures are not on the map keep no lists.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")
const Perf: GDScript = preload("res://tests/sim/test_battle_perf.gd")


## One tick as step() runs it, but with every bucket made again.
static func _step_without_shortcuts(b: Battle) -> void:
	if b.phase != Battle.Phase.WAVE:
		return
	b._spawn_step()
	b._timer_step()
	b._ring_step(false)
	b._move_step()
	if b.phase == Battle.Phase.LOST:
		b.tick += 1
		return
	b._tower_step(false)
	b._defeat_step()
	b._wave_step()
	b.tick += 1


func _play(b: Battle, plan: Array, shortcuts: bool) -> Array:
	for item: Array in plan:
		Tx.build(b, item[0], item[1], item[2] if item.size() > 2 else 1, item[3] if item.size() > 3 else -1)
	var states: PackedStringArray = PackedStringArray()
	var events: PackedStringArray = PackedStringArray()
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < 6000:
		if b.phase == Battle.Phase.BUILD or (b.waves_started < b.wave_count() and b.next_wave_info()["refusal"] == &""):
			b.start_next_wave()
		if shortcuts:
			b.step()
		else:
			_step_without_shortcuts(b)
		for event: Dictionary in b.take_events():
			events.append(var_to_str(event))
		if b.tick % 10 == 0:
			states.append(Fx.snapshot(b))
			var marks: Array = []
			for e: EnemyState in b.enemies:
				marks.append([e.id, e.out_of_reach, e.hidden])
			states.append(str(marks))
	states.append(Fx.snapshot(b))
	return [states, events, b.result()]


func _same(make: Callable, plan: Array, what: String) -> void:
	var fast: Array = _play(make.call(), plan, true)
	var full: Array = _play(make.call(), plan, false)
	assert_true((fast[1] as PackedStringArray).size() > 100, "%s: the run did something" % what)
	assert_eq(fast[0], full[0], "%s: the same states" % what)
	assert_eq(fast[1], full[1], "%s: the same events" % what)
	assert_eq(fast[2], full[2], "%s: the same result" % what)


func test_shortcuts_change_nothing_with_every_new_creature() -> void:
	var cat: Catalog = Cx.catalog()
	var waves: Array = [
		{"groups": [Fx.group("mossbud", 8, 0, 300), Fx.group("mistwisp", 4, 200, 1200), Fx.group("gleamer", 4, 400, 900),
			Fx.group("sleepyhead", 6, 100, 500), Fx.group("flitter", 8, 0, 400), Fx.group("dusk_moth", 3, 500, 1500)]},
		{"groups": [Fx.group("burrowbelly", 1), Fx.group("old_hayrick", 1, 1500), Fx.group("pip", 30, 0, 100), Fx.group("mender", 2, 0, 2000)]},
	]
	var make: Callable = func() -> Battle:
		return Battle.create(Fx.level(Fx.FEATURE_GRID, waves, {"towers": Tx.ALL, "start_gold": 20000}, cat), cat, true, [])
	var plan: Array = [[Vector2i(2, 1), &"moth_lantern", 2], [Vector2i(1, 5), &"lullaby_bell", 2], [Vector2i(4, 5), &"scarecrow"],
		[Vector2i(1, 8), &"snow_fort", 2], [Vector2i(4, 8), &"bramble_cottage", 2]]
	_same(make, plan, "every new creature on the feature map")


func test_shortcuts_change_nothing_with_every_late_creature() -> void:
	var cat: Catalog = Cx.catalog()
	var waves: Array = [
		{"groups": [Fx.group("snowroller", 8, 0, 300), Fx.group("yawner", 4, 200, 1200), Fx.group("blinker", 6, 400, 600),
			Fx.group("hootling", 3, 100, 1500), Fx.group("flitter", 6, 0, 400), Fx.group("scamp", 10, 0, 300, 2)]},
		{"groups": [Fx.group("snowsnore", 1), Fx.group("glimmertoad", 1, 1500, 1000, 2), Fx.group("pip", 30, 0, 100),
			Fx.group("yawner", 2, 0, 2000, 2)]},
	]
	var make: Callable = func() -> Battle:
		return Battle.create(Fx.level(Fx.FEATURE_GRID, waves, {"towers": Tx.ALL, "start_gold": 20000}, cat), cat, true, [])
	var plan: Array = [[Vector2i(2, 1), &"moth_lantern", 2], [Vector2i(1, 5), &"lullaby_bell", 2], [Vector2i(4, 5), &"pumpkin_catapult", 3, 1],
		[Vector2i(1, 8), &"snow_fort", 2], [Vector2i(4, 8), &"bramble_cottage", 2]]
	_same(make, plan, "every late creature on the feature map")


func test_shortcuts_change_nothing_on_a_plain_map_with_rings() -> void:
	var cat: Catalog = Tx.catalog()
	var waves: Array = [
		{"strength": 300, "groups": [Fx.group("pip", 40, 0, 50), Fx.group("bubbler", 10, 0, 200), Fx.group("flitter", 10, 0, 300),
			Fx.group("gatecrasher", 2, 1000, 3000)]},
		{"strength": 200, "groups": [Fx.group("puffball", 15, 0, 200), Fx.group("old_tusk", 1), Fx.group("ironshell", 1, 500)]},
	]
	var make: Callable = func() -> Battle:
		return Battle.create(Fx.level(Perf.PAIRS_GRID, waves, {"towers": Tx.ALL, "start_gold": 20000}, cat), cat, false, [])
	var plan: Array = [[Vector2i(0, 1), &"moth_lantern"], [Vector2i(1, 1), &"bakery"], [Vector2i(4, 1), &"lullaby_bell"],
		[Vector2i(5, 1), &"pumpkin_catapult", 3, 1], [Vector2i(1, 3), &"scarecrow"], [Vector2i(2, 3), &"sling_post", 2],
		[Vector2i(5, 3), &"longbow_loft", 3, 1], [Vector2i(6, 3), &"firework_tower"]]
	_same(make, plan, "bells, frights, lures and bosses on a plain map")


func test_shortcuts_change_nothing_in_the_level_2_2_crowd() -> void:
	var cat: Catalog = Fx.catalog()
	var waves: Array = [
		{"strength": 135, "groups": [Fx.group("skitter", 20, 0, 450), Fx.group("scamp", 40, 8000, 100), Fx.group("flitter", 10, 12000, 400)]},
		{"strength": 115, "groups": [Fx.group("pip", 56, 0, 50), Fx.group("skitter", 16, 5000, 500), Fx.group("flitter", 8, 9000, 400)]},
	]
	var make: Callable = func() -> Battle:
		var b: Battle = Fx.battle(Perf.MILL_GRID, waves, {"start_gold": 10000, "gates": 1, "towers": ["sling_post", "pumpkin_catapult", "lullaby_bell"]}, cat)
		b.place_gate(Vector2i(2, 2))
		return b
	var plan: Array = [[Vector2i(3, 1), &"sling_post"], [Vector2i(2, 3), &"lullaby_bell", 2], [Vector2i(2, 5), &"pumpkin_catapult"],
		[Vector2i(4, 7), &"sling_post", 2], [Vector2i(5, 9), &"sling_post", 2]]
	_same(make, plan, "level 2-2")


func test_rules_with_no_creature_on_the_map_keep_nothing_contract_14_12() -> void:
	var b: Battle = Tx.battle(Perf.PAIRS_GRID, [{"groups": [Fx.group("scamp", 20, 0, 100), Fx.group("flitter", 5, 0, 300)]}], {}, Cx.catalog())
	Tx.build(b, Vector2i(2, 3), &"sling_post")
	b.start_next_wave()
	Fx.steps(b, 60)
	assert_true(b.enemies.size() > 10)
	assert_eq([b._timed.size(), b._misters.size(), b._dazzlers.size(), b._nappers, b._diggers], [0, 0, 0, 0, 0], "no lists for absent rules")
	assert_false(b._hidden_set, "nothing misty")
	for e: EnemyState in b.enemies:
		assert_false(e.hidden or e.out_of_reach)
	var c: Battle = Cx.battle(Perf.PAIRS_GRID, [{"groups": [Fx.group("mistwisp", 1), Fx.group("sleepyhead", 1), Fx.group("burrowbelly", 1),
		Fx.group("gleamer", 1), Fx.group("mossbud", 1)]}])
	c.start_next_wave()
	c.step()
	assert_eq([c._timed.size(), c._misters.size(), c._dazzlers.size(), c._nappers, c._diggers], [3, 1, 1, 1, 1], "each creature joins its lists")


func test_a_misty_flyer_on_the_far_edge_marks_only_tiles_inside_the_map_rules_6_2() -> void:
	var cat: Catalog = Cx.catalog_with("flitter", {"mist": true})
	var b: Battle = Cx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("flitter", 1), Fx.group("dusk_moth", 1), Fx.group("scamp", 2, 0, 50)]}], {}, cat)
	b.start_next_wave()
	Fx.steps(b, 3)
	var flitter: EnemyState = b.enemies[0]
	var moth: EnemyState = b.enemies[1]
	flitter.pos = Vector2i(7 * Sim.UNIT, 3 * Sim.UNIT + 100)   # on the east edge: column 7, outside the map
	moth.pos = Vector2i(7 * Sim.UNIT, 7 * Sim.UNIT + 100)      # a flyer on the edge, on no tile
	b.enemies[2].pos = Sim.center(Vector2i(6, 3))              # the edge's neighbor inside
	b.enemies[3].pos = Sim.center(Vector2i(5, 3))
	b._tower_step()
	assert_true(b.enemies[2].hidden, "the tile next to it inside the map is misty")
	assert_false(b.enemies[3].hidden, "two tiles away is not")
	assert_false(moth.hidden, "a flyer on no tile is not hidden")
	assert_false(flitter.hidden, "a Mistwisp-like flyer is never hidden")
