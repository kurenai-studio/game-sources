# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The expansion towers at their edges (RULES 5.12 to 5.15, 8.2 to 8.5, 8.8;
## docs/ARCHITECTURE.md 14.5, 14.6): Scarecrow frights, Bramble pulses, Snow Fort lines,
## Moth Lantern lures and low flyers. Edge cases place creatures exactly and run one
## step of the tick, so each boundary is hit to the sub-unit.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")

## A straight road down column 3, entrance [3, 0], base [3, 12], spots on both sides.
## Flyers fly straight down the same column.
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
const ROAD_X: int = 70000                              # the center line of column 3

var catalog: Catalog = null


func before_each() -> void:
	catalog = Tx.catalog()


## A battle on STRAIGHT whose one wave brings `walkers` of `walker` and `flyers` of
## `flyer`, one of each a tick, stepped until all are on the map.
func _crowd(walkers: int, flyers: int, walker: String = "scamp", flyer: String = "flitter", grid: Array = STRAIGHT) -> Battle:
	var groups: Array = []
	if walkers > 0:
		groups.append(Fx.group(walker, walkers, 0, 50))
	if flyers > 0:
		groups.append(Fx.group(flyer, flyers, 0, 50))
	var b: Battle = Tx.battle(grid, [{"groups": groups}], {}, catalog)
	assert_not_null(b)
	b.start_next_wave()
	while b.enemies.size() < walkers + flyers and b.tick < 100:
		b.step()
	b.take_events()
	return b


func _walkers(b: Battle) -> Array[EnemyState]:
	var out: Array[EnemyState] = []
	for e: EnemyState in b.enemies:
		if not e.flying:
			out.append(e)
	return out


func _flyers(b: Battle) -> Array[EnemyState]:
	var out: Array[EnemyState] = []
	for e: EnemyState in b.enemies:
		if e.flying:
			out.append(e)
	return out


func _index(b: Battle, e: EnemyState) -> int:
	return b.enemies.find(e)


func _fired(b: Battle) -> Array[Dictionary]:
	return Fx.events_of(b.take_events(), &"fired")


func _fired_by(events: Array[Dictionary], tower: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in events:
		if event["tower"] == tower:
			out.append(event)
	return out


func _ids(list: Array[EnemyState]) -> Array[int]:
	var out: Array[int] = []
	for e: EnemyState in list:
		out.append(e.id)
	out.sort()
	return out


# Scarecrow (RULES 5.13)

func test_a_scarecrow_frightens_walkers_in_its_ring_and_the_fright_lingers_1_s_rules_5_13() -> void:
	var b: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("scamp", 1)]}], {}, catalog)
	var crow: TowerState = Tx.build(b, Vector2i(2, 4), &"scarecrow")
	assert_not_null(crow)
	b.start_next_wave()
	var center: Vector2i = Sim.center(crow.cell)
	var reach_sq: int = crow.stats.reach * 200 * crow.stats.reach * 200
	var was: int = 0
	var inside: int = 0
	var lingered: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 1000:
		b.step()
		var e: EnemyState = b.enemy_with_id(0)
		if e == null:
			break
		# prev_pos is where it stood in the rings step, before it moved.
		var d: Vector2i = e.prev_pos - center
		if d.x * d.x + d.y * d.y <= reach_sq:
			inside += 1
			assert_eq([e.fright_pct, e.fright_ticks], [15, 20], "in the ring at tick %d" % b.tick)
		else:
			var left: int = maxi(was - 1, 0)
			assert_eq([e.fright_pct, e.fright_ticks], [15 if left > 0 else 0, left], "outside the ring at tick %d" % b.tick)
			if left > 0:
				lingered += 1
		was = e.fright_ticks
	assert_true(inside > 30, "it walked through the ring: %d ticks" % inside)
	assert_eq(lingered, 19, "the fright lingers 1.0 s after it leaves")
	assert_eq(Fx.events_of(b.take_events(), &"fired").size(), 0, "a Scarecrow never fires")


func test_the_ring_edge_is_exact_rules_5_13() -> void:
	var b: Battle = _crowd(2, 0)
	var crow: TowerState = Tx.build(b, Vector2i(2, 4), &"scarecrow")
	var walkers: Array[EnemyState] = _walkers(b)
	# Center (50000, 90000), reach 40000: (74000, 122000) is 24000 by 32000 away.
	walkers[0].pos = Vector2i(74000, 122000)
	walkers[1].pos = Vector2i(74000, 122001)
	b._ring_step()
	assert_eq(walkers[0].fright_pct, 15, "exactly at the ring's edge")
	assert_eq(walkers[1].fright_pct, 0, "one sub-unit beyond it")
	assert_eq(crow.stats.reach * 200, 40000)


func test_one_fright_at_a_time_rules_5_13_8_7() -> void:
	var b: Battle = _crowd(1, 0)
	var e: EnemyState = b.enemies[0]
	b._fright(e, 25, 10)
	assert_eq([e.fright_pct, e.fright_ticks], [25, 10])
	b._fright(e, 15, 40)
	assert_eq([e.fright_pct, e.fright_ticks], [25, 10], "a lower fright changes nothing")
	b._fright(e, 25, 30)
	assert_eq([e.fright_pct, e.fright_ticks], [25, 30], "an equal one keeps the longer time")
	b._fright(e, 25, 5)
	assert_eq([e.fright_pct, e.fright_ticks], [25, 30])
	b._fright(e, 40, 3)
	assert_eq([e.fright_pct, e.fright_ticks], [40, 3], "a higher one replaces it")
	for i: int in 2:
		b._timer_step()
	assert_eq([e.fright_pct, e.fright_ticks], [40, 1])
	b._timer_step()
	assert_eq([e.fright_pct, e.fright_ticks], [0, 0], "it ends when its time runs out")


func test_a_fright_adds_its_percent_after_armor_rules_8_3() -> void:
	var b: Battle = _crowd(3, 0, "shellback")
	var shell: Array[EnemyState] = _walkers(b)
	var stone: TowerStats = Fx.stats(catalog, &"sling_post", 3, 1)
	var bow: TowerStats = Fx.stats(catalog, &"longbow_loft", 1)
	# RULES 5.13: a Stone Sling (20) on a Shellback (armor 4) with 25% fright: 16 becomes 20.
	shell[0].fright_pct = 25
	shell[0].fright_ticks = 10
	var before: int = shell[0].health
	b._hit(_index(b, shell[0]), stone, 0)
	assert_eq(before - shell[0].health, 20)
	before = shell[1].health
	b._hit(_index(b, shell[1]), stone, 0)
	assert_eq(before - shell[1].health, 16, "no fright, no extra")
	# A Longbow ignores armor: 40 with 15% is 46. Rounding is half up: 6 with 15% is 6.9, so 7.
	shell[2].fright_pct = 15
	shell[2].fright_ticks = 10
	before = shell[2].health
	b._hit(_index(b, shell[2]), bow, 0)
	assert_eq(before - shell[2].health, 46)
	assert_eq(Sim.pct_half_up(6, 115), 7)
	# A bubble still blocks the whole hit.
	shell[0].bubble = true
	before = shell[0].health
	b._hit(_index(b, shell[0]), stone, 0)
	assert_eq(shell[0].health, before, "the bubble pops and nothing else happens")
	assert_false(shell[0].bubble)


func test_a_frightened_walker_takes_more_from_every_shot_in_play_rules_5_13() -> void:
	var b: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("shellback", 1)]}], {}, catalog)
	Tx.build(b, Vector2i(2, 4), &"scarecrow", 2)
	Tx.build(b, Vector2i(4, 4), &"sling_post", 3, 1)
	b.start_next_wave()
	var frightened: int = 0
	var plain: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		var e: EnemyState = b.enemy_with_id(0)
		var health: int = e.health if e != null else 0
		b.step()
		var shots: Array[Dictionary] = _fired(b)
		e = b.enemy_with_id(0)
		if shots.is_empty() or e == null:
			continue
		# The rings step ran before the shot: the fright at the shot is the one after this tick.
		var taken: int = health - e.health
		if e.fright_pct > 0:
			frightened += 1
			assert_eq(taken, 20, "a Stone Sling on a Shellback frightened 25%")
		else:
			plain += 1
			assert_eq(taken, 16, "a Stone Sling on a Shellback")
	assert_true(frightened > 0 and plain > 0, "shots with and without fright: %d and %d" % [frightened, plain])


func test_scarecrows_and_low_flyers_rules_5_13_5_15() -> void:
	var b: Battle = _crowd(0, 3)
	var flyers: Array[EnemyState] = _flyers(b)
	Tx.build(b, Vector2i(2, 4), &"scarecrow")
	var keeper: TowerState = Tx.build(b, Vector2i(2, 7), &"scarecrow", 3, 1)
	flyers[0].pos = Vector2i(ROAD_X, 90000)
	flyers[1].pos = Vector2i(ROAD_X, 90000)
	flyers[1].low_ticks = 5
	flyers[2].pos = Sim.center(Vector2i(3, 7))
	b._ring_step()
	assert_eq(flyers[0].fright_pct, 0, "a Scarecrow does not frighten a flyer")
	assert_eq(flyers[1].fright_pct, 15, "a low flyer counts as a walker")
	assert_eq(flyers[2].fright_pct, keeper.stats.fright_pct, "a Crow Keeper frightens flyers")


func test_a_scarecrow_never_aims_never_fires_and_no_bakery_boosts_it_rules_5_13() -> void:
	var grid: Array = [
		"...1...",
		".oo#...",
		".oo#...",
		"...#...",
		"...#...",
		"...B...",
		".......",
		".......",
	]
	var b: Battle = Tx.battle(grid, [{"groups": [Fx.group("scamp", 2)]}], {}, catalog)
	var bakery: TowerState = Tx.build(b, Vector2i(1, 1), &"bakery")
	Tx.build(b, Vector2i(2, 1), &"scarecrow")
	var bramble: TowerState = Tx.build(b, Vector2i(1, 2), &"bramble_cottage")
	assert_eq(b.set_aim(Vector2i(2, 1), TowerState.Aim.LAST), &"no_aim")
	assert_eq(b.tower_at(Vector2i(2, 1)).got_pct, 0, "no boost on a Scarecrow beside a Bakery")
	assert_eq(bakery.boosting, 1, "the Bakery boosts the Bramble Cottage only")
	assert_true(bramble.got_pct > 0, "a Bakery boosts a Bramble Cottage (8.6)")
	b.start_next_wave()
	Fx.run_wave(b)
	for event: Dictionary in Fx.events_of(b.take_events(), &"fired"):
		assert_ne(event["tower"], &"scarecrow")


func test_creatures_out_of_reach_get_no_fright_rules_8_8() -> void:
	var b: Battle = _crowd(2, 0, "scamp", "flitter", Fx.TUNNEL_GRID)
	Tx.build(b, Vector2i(2, 3), &"scarecrow", 2)
	var walkers: Array[EnemyState] = _walkers(b)
	walkers[0].pos = Sim.center(Vector2i(3, 3))                # in the tunnel
	walkers[1].pos = Sim.center(Vector2i(3, 5))                # on the road below it
	walkers[0].fright_pct = 15
	walkers[0].fright_ticks = 7
	b._ring_step()
	assert_true(walkers[0].out_of_reach)
	assert_eq([walkers[0].fright_pct, walkers[0].fright_ticks], [15, 7], "a fright it holds only runs down")
	assert_eq([walkers[1].fright_pct, walkers[1].fright_ticks], [25, 20], "the one outside is frightened")


# Bramble Cottage (RULES 5.12)

func test_a_pulse_hits_every_creature_it_can_hit_in_its_ring_exactly_rules_5_12() -> void:
	var b: Battle = _crowd(3, 2)
	var walkers: Array[EnemyState] = _walkers(b)
	var flyers: Array[EnemyState] = _flyers(b)
	var bramble: TowerState = Tx.build(b, Vector2i(2, 4), &"bramble_cottage")
	# Center (50000, 90000), ring 30000: (74000, 108000) is 24000 by 18000 away.
	walkers[0].pos = Vector2i(74000, 108000)
	walkers[1].pos = Vector2i(74000, 108001)
	walkers[2].pos = Vector2i(ROAD_X, 90000)
	flyers[0].pos = Vector2i(ROAD_X, 90000)                     # high: a Bramble cannot hit it
	flyers[1].pos = Vector2i(60000, 90000)
	flyers[1].low_ticks = 3
	var health: Array[int] = []
	for e: EnemyState in b.enemies:
		health.append(e.health)
	b._tower_step()
	var shots: Array[Dictionary] = _fired(b)
	assert_eq(shots.size(), 1, "one fired event per pulse")
	var expected: Array[int] = [walkers[0].id, walkers[2].id, flyers[1].id]
	expected.sort()
	assert_eq(shots[0]["targets"], expected, "every creature it hit, in id order")
	assert_eq((shots[0]["at"] as Array).size(), 3)
	assert_false(shots[0].has("to"), "a pulse has no line end")
	for i: int in b.enemies.size():
		var e: EnemyState = b.enemies[i]
		assert_eq(health[i] - e.health, 4 if expected.has(e.id) else 0, "creature %d" % e.id)
	assert_eq(bramble.reload, 100000 - 5000, "its reload starts")
	assert_eq(b.set_aim(bramble.cell, TowerState.Aim.LAST), &"no_aim", "a pulse aims at nothing")


func test_a_pulse_waits_at_0_with_nothing_in_its_ring_rules_5_12() -> void:
	var b: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("scamp", 1)]}], {}, catalog)
	var bramble: TowerState = Tx.build(b, Vector2i(2, 4), &"bramble_cottage")
	b.start_next_wave()
	var center: Vector2i = Sim.center(bramble.cell)
	var fired_at: Array[int] = []
	var first_inside: int = -1
	while b.phase == Battle.Phase.WAVE and b.tick < 1000:
		b.step()
		var e: EnemyState = b.enemy_with_id(0)
		var shots: Array[Dictionary] = _fired(b)
		if e == null:
			break
		var d: Vector2i = e.pos - center
		var inside: bool = d.x * d.x + d.y * d.y <= 30000 * 30000
		if inside and first_inside < 0:
			first_inside = b.tick
		if not shots.is_empty():
			assert_true(inside, "it pulses only with a walker in its ring")
			fired_at.append(b.tick)
		elif first_inside < 0:
			assert_eq(bramble.reload, 0, "its timer waits at 0")
	assert_eq(fired_at[0], first_inside, "it pulses on the first tick a walker is in its ring")
	# 5.2: the tick that finds the timer waiting at 0 also runs it down, so the next pulse
	# comes 19 ticks later, and then every 20.
	assert_eq(fired_at, [first_inside, first_inside + 19, first_inside + 39] as Array[int], "then once a second while it stays")


func test_holly_crown_ignores_armor_and_bubbles_block_pulses_rules_5_12() -> void:
	var b: Battle = _crowd(2, 0, "shellback")
	var walkers: Array[EnemyState] = _walkers(b)
	Tx.build(b, Vector2i(2, 4), &"bramble_cottage", 3, 1)
	Tx.build(b, Vector2i(2, 10), &"bramble_cottage", 3, 0)
	walkers[0].pos = Vector2i(ROAD_X, 90000)
	walkers[1].pos = Vector2i(ROAD_X, 210000)
	walkers[1].bubble = true
	var health: Array[int] = [walkers[0].health, walkers[1].health]
	b._tower_step()
	assert_eq(health[0] - walkers[0].health, 12, "Holly Crown: 12 through armor 4")
	assert_eq(walkers[1].health, health[1], "the bubble blocks the pulse")
	assert_false(walkers[1].bubble)
	b.tower_at(Vector2i(2, 10)).reload = 0
	b._tower_step()
	assert_eq(health[1] - walkers[1].health, 6, "Wild Bramble: 10 less armor 4")


func test_out_of_reach_creatures_are_skipped_by_pulses_and_lines_rules_8_8() -> void:
	var b: Battle = _crowd(2, 1, "scamp", "flitter", Fx.TUNNEL_GRID)
	Tx.build(b, Vector2i(2, 3), &"bramble_cottage")
	var walkers: Array[EnemyState] = _walkers(b)
	walkers[0].pos = Sim.center(Vector2i(3, 3))
	walkers[1].pos = Sim.center(Vector2i(3, 2))
	_flyers(b)[0].pos = Vector2i(0, 0)
	var health: Array[int] = [walkers[0].health, walkers[1].health]
	b._tower_step()
	assert_eq([walkers[0].health, walkers[1].health], health, "no pulse reaches the tunnel")
	assert_true(_fired(b).is_empty(), "with only out of reach walkers in its ring, it waits")
	# A line through the tunnel hits the low flyer it aims at and skips the walker it passes.
	var c: Battle = _crowd(1, 1, "scamp", "flitter", Fx.TUNNEL_GRID)
	var fort: TowerState = Tx.build(c, Vector2i(2, 3), &"snow_fort")
	var walker: EnemyState = _walkers(c)[0]
	var flyer: EnemyState = _flyers(c)[0]
	walker.pos = Sim.center(Vector2i(3, 3))
	flyer.pos = Sim.center(Vector2i(4, 3))
	flyer.low_ticks = 5
	c._tower_step()
	var shots: Array[Dictionary] = _fired(c)
	assert_eq(shots.size(), 1)
	assert_eq(shots[0]["targets"], [flyer.id] as Array[int], "the walker in the tunnel is not hit")
	assert_eq(fort.reload, 300000 - 5000)


# Snow Fort (RULES 5.14)

## A Snow Fort at [2, 4], A = (50000, 90000), with a low flyer target at (70000, 90000):
## the line runs east to B = (110000, 90000), 0.8 wide, so r = 8000. Each probe is a
## walker (bucketed by cell) and a low flyer at the same point; both must agree.
func test_the_line_edges_are_exact_rules_5_14() -> void:
	var probes: Array = [
		[Vector2i(90000, 98000), true, "8000 to the side"],
		[Vector2i(90000, 98001), false, "just past the side"],
		[Vector2i(90000, 82000), true, "8000 to the other side"],
		[Vector2i(90000, 81999), false, "just past the other side"],
		[Vector2i(118000, 90000), true, "8000 past the end"],
		[Vector2i(118001, 90000), false, "just past the end"],
		[Vector2i(114800, 96400), true, "8000 from the end, slanting"],
		[Vector2i(114801, 96400), false, "just past that"],
		[Vector2i(42000, 90000), true, "8000 behind the tower"],
		[Vector2i(41999, 90000), false, "just past that"],
		[Vector2i(45200, 83600), true, "8000 from the tower, slanting back"],
		[Vector2i(100000, 90000), true, "on the line"],
	]
	for as_walker: bool in [true, false]:
		var count: int = probes.size()
		var b: Battle = _crowd(count if as_walker else 0, count + 1)
		var fort: TowerState = Tx.build(b, Vector2i(2, 4), &"snow_fort")
		var flyers: Array[EnemyState] = _flyers(b)
		var target: EnemyState = flyers[0]
		target.pos = Vector2i(70000, 90000)
		target.low_ticks = 5
		var list: Array[EnemyState] = _walkers(b) if as_walker else flyers.slice(1)
		if not as_walker:
			for k: int in range(probes.size() + 1, flyers.size()):
				flyers[k].pos = Vector2i(0, 0)
		for k: int in probes.size():
			list[k].pos = probes[k][0]
			if not as_walker:
				list[k].low_ticks = 5
		b._bucket()
		b._line_shot(fort, fort.stats, _index(b, target))
		var shots: Array[Dictionary] = _fired(b)
		assert_eq(shots.size(), 1)
		var hit: Array = shots[0]["targets"]
		assert_eq(shots[0]["to"], Vector2i(110000, 90000), "B")
		assert_true(hit.has(target.id), "the target is hit")
		for k: int in probes.size():
			assert_eq(hit.has(list[k].id), probes[k][1], "%s (%s)" % [probes[k][2], "walker" if as_walker else "low flyer"])
		var sorted: Array = hit.duplicate()
		sorted.sort()
		assert_eq(hit, sorted, "in id order")


func test_high_flyers_are_not_hit_by_a_line_and_a_target_on_the_tower_is_hit_alone_rules_5_14() -> void:
	var b: Battle = _crowd(1, 2)
	var fort: TowerState = Tx.build(b, Vector2i(2, 4), &"snow_fort")
	var flyers: Array[EnemyState] = _flyers(b)
	var walker: EnemyState = _walkers(b)[0]
	walker.pos = Vector2i(70000, 90000)
	flyers[0].pos = Vector2i(90000, 90000)                      # high, on the line
	flyers[1].pos = Vector2i(0, 0)
	b._tower_step()
	var shots: Array[Dictionary] = _fired(b)
	assert_eq(shots[0]["targets"], [walker.id] as Array[int], "a Snow Fort cannot hit a high flyer")
	# Only a low flyer can be at the tower's own center: then it is hit alone.
	var c: Battle = _crowd(1, 1)
	var other: TowerState = Tx.build(c, Vector2i(2, 4), &"snow_fort")
	var low: EnemyState = _flyers(c)[0]
	low.pos = Sim.center(other.cell)
	low.low_ticks = 5
	_walkers(c)[0].pos = Sim.center(other.cell) + Vector2i(100, 0)
	c._bucket()
	c._line_shot(other, other.stats, _index(c, low))
	shots = _fired(c)
	assert_eq(shots[0]["targets"], [low.id] as Array[int], "only the target is hit")
	assert_eq(shots[0]["to"], Sim.center(other.cell), "the line ends where it starts")


func test_a_line_stops_at_the_map_edge_rules_5_14() -> void:
	var cases: Array = [
		# [target, B with reach 3.0, B with reach 1000]
		[Vector2i(70000, 90000), Vector2i(110000, 90000), Vector2i(140000, 90000)],
		[Vector2i(70000, 105000), Vector2i(98000, 126000), Vector2i(140000, 157500)],
		[Vector2i(30000, 75000), Vector2i(2000, 54000), Vector2i(0, 52500)],
		[Vector2i(50000, 70000), Vector2i(50000, 30000), Vector2i(50000, 0)],
		[Vector2i(50000, 110000), Vector2i(50000, 150000), Vector2i(50000, 260000)],
	]
	var far: Catalog = Tx.catalog_with("snow_fort", 0, {"reach": 1000})
	for item: Array in cases:
		for k: int in 2:
			var b: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("flitter", 1)]}], {}, catalog if k == 0 else far)
			b.start_next_wave()
			b.step()
			b.take_events()
			var fort: TowerState = Tx.build(b, Vector2i(2, 4), &"snow_fort")
			var low: EnemyState = b.enemies[0]
			low.pos = item[0]
			low.low_ticks = 5
			b._tower_step()
			var shots: Array[Dictionary] = _fired(b)
			assert_eq(shots.size(), 1)
			if shots.is_empty():
				continue
			assert_eq(shots[0]["to"], item[1 + k], "through %s with reach %d" % [str(item[0]), fort.stats.reach])


func test_a_snow_fort_hits_a_column_of_walkers_in_play_rules_5_14() -> void:
	# The road runs east along row 2 straight at the fort on [6, 2]: its line runs back
	# along the road through every walker within its reach.
	var grid: Array = [
		".......",
		".......",
		"1#####o",
		".....#.",
		".....#.",
		".....#.",
		".....#.",
		".....B.",
	]
	var b: Battle = Tx.battle(grid, [{"groups": [Fx.group("shellback", 6, 0, 300)]}], {}, catalog)
	var fort: TowerState = Tx.build(b, Vector2i(6, 2), &"snow_fort", 3, 0)
	b.start_next_wave()
	var best: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 600:
		b.step()
		for shot: Dictionary in _fired(b):
			best = maxi(best, (shot["targets"] as Array).size())
			var to: Vector2i = shot["to"]
			assert_true(to.x >= 0 and to.y >= 0 and to.x <= 7 * Sim.UNIT and to.y <= 8 * Sim.UNIT, "B is inside the map")
	assert_true(best >= 3, "one snowball hit %d walkers in a row" % best)
	assert_eq(fort.stats.line, 100)


func test_line_math_at_extreme_coordinates_and_the_reach_ceiling_contract_14_5() -> void:
	var length: int = Battle.MAX_TOWER_STAT * 200
	var corners: Array[Vector2i] = []
	for rows: int in [Sim.MAP_ROWS_MIN, Sim.MAP_ROWS_MAX]:
		corners = [Vector2i(10000, 10000), Vector2i(130000, 10000), Vector2i(10000, rows * Sim.UNIT - 10000),
			Vector2i(130000, rows * Sim.UNIT - 10000)]
		var high: Vector2i = Vector2i(Sim.MAP_COLUMNS * Sim.UNIT, rows * Sim.UNIT)
		var biggest: int = 0
		for a: Vector2i in corners:
			for t: Vector2i in corners + [Vector2i(70000, rows * 10000), Vector2i(10001, 10000), Vector2i(10000, 10001)]:
				var d: Vector2i = t - a
				if d == Vector2i.ZERO:
					continue
				var n: int = Sim.isqrt(d.x * d.x + d.y * d.y)
				var b: Vector2i = Battle._line_end(a, d, n, length, rows)
				assert_true(b.x >= 0 and b.y >= 0 and b.x <= high.x and b.y <= high.y, "B %s inside the map" % str(b))
				assert_true(b.x == 0 or b.y == 0 or b.x == high.x or b.y == high.y or absi(b.x - high.x) <= 1 or absi(b.y - high.y) <= 1 or b.x <= 1 or b.y <= 1,
					"B %s from %s through %s ends on the edge" % [str(b), str(a), str(t)])
				# B stays on the ray: its distance from the line through a and t is at most a sub-unit or two.
				var e: Vector2i = b - a
				assert_true(absi(e.x * d.y - e.y * d.x) <= 2 * n, "B %s on the line from %s through %s" % [str(b), str(a), str(t)])
				assert_true(e.x * d.x + e.y * d.y > 0, "B lies ahead")
				# The largest products the method forms, at the ceiling.
				var step: Vector2i = Vector2i(d.x * length / n, d.y * length / n)
				for product: int in [absi(d.x * length), absi(d.y * length), absi(step.x) * high.x, absi(step.y) * high.y,
						high.x * absi(step.y), high.y * absi(step.x), e.x * e.x + e.y * e.y, d.x * d.x + d.y * d.y]:
					biggest = maxi(biggest, product)
		assert_true(biggest < 100000000000000, "every product below 10^14: %d" % biggest)
	# Inside the map nothing is pulled back: D = (30000, 40000), n = 50000, L = 60000.
	assert_eq(Battle._line_end(Vector2i(50000, 90000), Vector2i(30000, 40000), 50000, 60000, 13), Vector2i(86000, 138000))
	# Truncation toward zero on both axes: 7 * 60000 / 9 is 46666.7, and -46666.7 becomes -46666.
	assert_eq(Battle._line_end(Vector2i(70000, 70000), Vector2i(-7, 7), 9, 60000, 13), Vector2i(70000 - 46666, 70000 + 46666))


func test_a_line_at_the_largest_reach_cards_can_give_contract_14_5() -> void:
	var effects: Array[Dictionary] = []
	for i: int in Modifiers.MAX_KEPT:
		effects.append({"type": "tower_add", "tower": "snow_fort", "stat": "reach", "amount": 1000})
	var far: Catalog = Tx.catalog_with("snow_fort", 0, {"reach": 1000})
	var b: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("scamp", 2, 0, 50)]}], {}, far)
	assert_eq(b.add_effects(effects, false), Battle.DONE, "64 reach cards are kept")
	var fort: TowerState = Tx.build(b, Vector2i(2, 4), &"snow_fort")
	assert_eq(fort.stats.reach, 1000 + 64000)
	b.start_next_wave()
	var shots: Array[Dictionary] = []
	while shots.is_empty() and b.tick < 50:
		b.step()
		shots = _fired(b)
	assert_eq(shots.size(), 1, "it fires at the first walker")
	if shots.is_empty():
		return
	var to: Vector2i = shots[0]["to"]
	assert_true(to.x == 0 or to.y == 0 or to.x == 7 * Sim.UNIT or to.y == 13 * Sim.UNIT, "the line runs to the edge: %s" % str(to))


func test_lines_agree_with_a_reference_in_a_crowd_rules_5_14() -> void:
	# A crowd of walkers and lured flyers; every snowball's hits match a float reference
	# of the segment from A to B, except within 2 sub-units of its edge.
	var b: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("scamp", 40, 0, 150), Fx.group("flitter", 20, 0, 300),
		Fx.group("shellback", 10, 200, 600)]}], {}, catalog)
	Tx.build(b, Vector2i(1, 1), &"moth_lantern", 3, 1)
	var forts: Array[TowerState] = [Tx.build(b, Vector2i(2, 4), &"snow_fort", 3, 1), Tx.build(b, Vector2i(4, 7), &"snow_fort", 3, 0)]
	b.start_next_wave()
	var checked: int = 0
	var multi: int = 0
	var low_hits: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		var before: Dictionary = {}
		for e: EnemyState in b.enemies:
			before[e.id] = e
		b.step()
		for shot: Dictionary in _fired(b):
			if shot["tower"] != &"snow_fort":
				continue
			var fort: TowerState = b.tower_at(shot["cell"])
			var a: Vector2 = Vector2(Sim.center(fort.cell))
			var to: Vector2 = Vector2(shot["to"] as Vector2i)
			var r: float = fort.stats.line * 100.0
			var hit: Array = shot["targets"]
			if hit.size() > 1:
				multi += 1
			for id: int in before:
				var e: EnemyState = before[id]
				if (e.health <= 0 or b.enemy_with_id(id) == null) and not hit.has(id):
					continue                           # gone, or down before this shot
				var p: Vector2 = Vector2(e.pos)
				var gap: float = p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, to))
				var reachable: bool = not e.flying or e.low_ticks > 0
				if not reachable or e.out_of_reach:
					assert_false(hit.has(id), "a creature it cannot hit")
					continue
				if absf(gap - r) <= 2.0:
					continue
				assert_eq(hit.has(id), gap < r, "creature %d at %.1f from the line, r %.0f" % [id, gap, r])
				checked += 1
				if hit.has(id) and e.flying:
					low_hits += 1
	assert_true(checked > 200, "%d creatures checked against the reference" % checked)
	assert_true(multi > 0, "%d snowballs hit more than one" % multi)
	assert_true(low_hits > 0, "%d low flyers hit by snowballs" % low_hits)


# Moth Lantern and low flyers (RULES 5.15)

func test_a_lure_makes_a_flyer_low_and_a_new_lure_keeps_the_longer_time_rules_5_15() -> void:
	var b: Battle = _crowd(0, 1)
	var lantern: TowerState = Tx.build(b, Vector2i(2, 4), &"moth_lantern")
	var flyer: EnemyState = b.enemies[0]
	flyer.pos = Vector2i(ROAD_X, 90000)
	var health: int = flyer.health
	b._tower_step()
	assert_eq(flyer.low_ticks, 40, "low for 2.0 s")
	assert_eq(health - flyer.health, 4)
	flyer.low_ticks = 55
	lantern.reload = 0
	b._tower_step()
	assert_eq(flyer.low_ticks, 55, "a shorter lure keeps the longer time")
	flyer.low_ticks = 3
	lantern.reload = 0
	b._tower_step()
	assert_eq(flyer.low_ticks, 40)
	flyer.bubble = true
	flyer.low_ticks = 0
	lantern.reload = 0
	health = flyer.health
	b._tower_step()
	assert_eq([flyer.low_ticks, flyer.health, flyer.bubble], [0, health, false], "a bubble blocks the hit and the lure")
	flyer.low_ticks = 2
	b._timer_step()
	b._timer_step()
	assert_eq(flyer.low_ticks, 0, "the lure runs out")


func test_a_lure_counts_at_once_for_towers_later_in_spot_order_rules_5_15() -> void:
	var b: Battle = _crowd(0, 1, "scamp", "dusk_moth")
	var early: TowerState = Tx.build(b, Vector2i(1, 1), &"longbow_loft")
	Tx.build(b, Vector2i(2, 2), &"moth_lantern")
	var late: TowerState = Tx.build(b, Vector2i(4, 2), &"longbow_loft")
	var flyer: EnemyState = b.enemies[0]
	flyer.pos = Sim.center(Vector2i(3, 2))
	b._tower_step()
	var shots: Array[Dictionary] = _fired(b)
	var order: Array = []
	for shot: Dictionary in shots:
		order.append([shot["tower"], shot["cell"]])
	assert_eq(order, [[&"moth_lantern", Vector2i(2, 2)], [&"longbow_loft", Vector2i(4, 2)]], "the Longbow after the lure hits it")
	assert_eq(early.reload, 0, "the Longbow before it had nothing to aim at")
	assert_eq(late.reload, 250000 - 5000)
	b._tower_step()
	assert_eq(_fired_by(_fired(b), &"longbow_loft").size(), 1, "next tick the first Longbow hits it too")
	assert_true(early.reload > 0)


func test_every_tower_reaches_a_low_flyer_and_none_a_high_one_rules_5_15() -> void:
	# [tower, tier, spec, what to check]
	var cases: Array = [
		[&"pumpkin_catapult", 1, -1, "health"], [&"longbow_loft", 1, -1, "health"], [&"lullaby_bell", 1, -1, "slow"],
		[&"scarecrow", 1, -1, "fright"], [&"bramble_cottage", 1, -1, "health"], [&"snow_fort", 1, -1, "health"],
		[&"sling_post", 1, -1, "health"], [&"firework_tower", 1, -1, "health"],
	]
	for item: Array in cases:
		for low: bool in [true, false]:
			var b: Battle = _crowd(0, 2)
			Tx.build(b, Vector2i(2, 4), item[0], item[1], item[2])
			var flyers: Array[EnemyState] = _flyers(b)
			flyers[0].pos = Vector2i(ROAD_X, 90000)
			flyers[1].pos = Vector2i(ROAD_X, 95000)         # in the catapult's splash
			for f: EnemyState in flyers:
				f.low_ticks = 5 if low else 0
			var health: Array[int] = [flyers[0].health, flyers[1].health]
			b._ring_step()
			b._tower_step()
			var touched: Array[bool] = []
			for k: int in 2:
				match String(item[3]):
					"health":
						touched.append(flyers[k].health < health[k])
					"slow":
						touched.append(flyers[k].slow_pct > 0)
					"fright":
						touched.append(flyers[k].fright_pct > 0)
			var air: bool = b.tower_at(Vector2i(2, 4)).stats.hits_air
			var expect: bool = low or air
			assert_eq(touched[0], expect, "%s on a %s flyer" % [item[0], "low" if low else "high"])
			if item[0] == &"pumpkin_catapult" or item[0] == &"bramble_cottage" or item[0] == &"snow_fort" or item[0] == &"lullaby_bell" \
					or item[0] == &"scarecrow":
				assert_eq(touched[1], expect, "%s reaches a second %s flyer" % [item[0], "low" if low else "high"])


func test_a_lantern_aims_at_flyers_that_are_not_low_first_rules_5_15() -> void:
	for garland: bool in [false, true]:
		var b: Battle = _crowd(0, 4)
		var lantern: TowerState = Tx.build(b, Vector2i(2, 4), &"moth_lantern", 3 if garland else 1, 1 if garland else -1)
		var flyers: Array[EnemyState] = _flyers(b)
		# First order (nearest the base first): 0, 1, 2, 3. Flyers 0 and 3 are low.
		var flown: Array[int] = [70000, 60000, 50000, 40000]
		for k: int in 4:
			flyers[k].flown = flown[k]
			b._place(flyers[k])
		flyers[0].low_ticks = 5
		flyers[3].low_ticks = 5
		b._tower_step()
		var shots: Array[Dictionary] = _fired(b)
		assert_eq(shots.size(), 1)
		var want: Array[int] = []
		want.assign([flyers[1].id, flyers[2].id, flyers[0].id] if garland else [flyers[1].id])
		assert_eq(shots[0]["targets"], want, "Garland" if garland else "Moth Lantern")
		for k: int in 4:
			var lured: bool = want.has(flyers[k].id) or k == 0 or k == 3
			assert_eq(flyers[k].low_ticks > 0, lured, "flyer %d low" % k)
		# Last aims at the farthest that is not low.
		if not garland:
			lantern.reload = 0
			for f: EnemyState in flyers:
				f.low_ticks = 5 if f == flyers[0] or f == flyers[3] else 0
			assert_eq(b.set_aim(lantern.cell, TowerState.Aim.LAST), Battle.DONE)
			b._tower_step()
			assert_eq(_fired(b)[0]["targets"], [flyers[2].id] as Array[int], "Last: the farthest flyer that is not low")


func test_a_lantern_aims_at_low_flyers_only_when_all_are_low_and_never_at_walkers_rules_5_15() -> void:
	var b: Battle = _crowd(1, 2)
	Tx.build(b, Vector2i(2, 4), &"moth_lantern")
	var flyers: Array[EnemyState] = _flyers(b)
	_walkers(b)[0].pos = Vector2i(ROAD_X, 90000)
	flyers[0].flown = 70000
	flyers[1].flown = 60000
	for f: EnemyState in flyers:
		b._place(f)
		f.low_ticks = 5
	b._tower_step()
	assert_eq(_fired(b)[0]["targets"], [flyers[0].id] as Array[int], "every flyer is low: First among them")
	var c: Battle = _crowd(1, 0)
	Tx.build(c, Vector2i(2, 4), &"moth_lantern")
	_walkers(c)[0].pos = Vector2i(ROAD_X, 90000)
	c._tower_step()
	assert_true(_fired(c).is_empty(), "a Moth Lantern cannot hit walkers")


func test_no_flyer_is_low_without_a_lure_contract_14_12() -> void:
	var b: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("flitter", 6, 0, 300), Fx.group("scamp", 6, 0, 300)]}], {}, catalog)
	Tx.build(b, Vector2i(2, 4), &"sling_post")
	Tx.build(b, Vector2i(4, 4), &"pumpkin_catapult")
	b.start_next_wave()
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		b.step()
		assert_eq(b._low_list.size(), 0, "no low flyer list to loop over")
	var c: Battle = Tx.battle(STRAIGHT, [{"groups": [Fx.group("flitter", 3, 0, 300)]}], {}, catalog)
	Tx.build(c, Vector2i(2, 4), &"moth_lantern")
	c.start_next_wave()
	var lured: int = 0
	while c.phase == Battle.Phase.WAVE and c.tick < 2000:
		c.step()
		for e: EnemyState in c.enemies:
			if e.low_ticks > 0:
				lured += 1
				assert_eq(e.pos.x, ROAD_X, "a low flyer still flies its straight line")
	assert_true(lured > 0)


# Queries (docs/ARCHITECTURE.md 14.6)

func test_numbers_show_the_new_fields_contract_14_6() -> void:
	var b: Battle = _crowd(1, 1)
	for option: Dictionary in b.build_options(Vector2i(2, 4)):
		var numbers: Dictionary = option["numbers"]
		for key: String in ["pulse", "line", "lure_ms", "fright_pct", "fright_ms"]:
			assert_true(numbers.has(key), "%s numbers hold %s" % [option["tower"], key])
		match option["tower"]:
			&"bramble_cottage":
				assert_eq(numbers["pulse"], true)
			&"snow_fort":
				assert_eq(numbers["line"], 80)
			&"moth_lantern":
				assert_eq(numbers["lure_ms"], 2000)
			&"scarecrow":
				assert_eq([numbers["fright_pct"], numbers["fright_ms"]], [15, 1000])
	Tx.build(b, Vector2i(2, 4), &"scarecrow", 2)
	assert_eq(b.tower_numbers(Vector2i(2, 4))["fright_pct"], 25)
	var options: Array[Dictionary] = b.upgrade_options(Vector2i(2, 4))
	assert_eq([options[0]["after"]["fright_pct"], options[1]["after"]["fright_pct"]], [40, 25])
	var walker: EnemyState = _walkers(b)[0]
	var flyer: EnemyState = _flyers(b)[0]
	walker.fright_pct = 25
	walker.fright_ticks = 7
	flyer.low_ticks = 9
	var w: Dictionary = b.enemy_numbers(walker.id)
	assert_eq([w["fright_pct"], w["fright_ms"], w["low_ms"], w["out_of_reach"]], [25, 350, 0, false])
	var f: Dictionary = b.enemy_numbers(flyer.id)
	assert_eq([f["fright_pct"], f["fright_ms"], f["low_ms"]], [0, 0, 450])
