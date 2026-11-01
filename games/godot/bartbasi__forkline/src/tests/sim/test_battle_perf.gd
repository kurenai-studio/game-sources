# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Time per tick in the most crowded cases (docs/ARCHITECTURE.md 9.1, 9.2, 14.12).
##
## A busy machine must not fail these tests, and a clearly slower tick must. So:
## 1. Each case steps COPIES identical battles in lockstep (the sim is deterministic, so
##    every copy does the same work on the same tick) and keeps, for each tick, the
##    fastest copy. Another program taking the CPU slows one copy on a tick, rarely all.
## 2. Right after each copy's step, the same fixed piece of plain GDScript work runs and
##    is timed the same way (`_reference`). A busy machine slows both about alike.
## 3. The assert reads the ratio of the two means, the tick's cost in reference units.
##    On the dev PC it moved by about 5% between an idle machine and one running four
##    more full test suites at once, while the plain means doubled.
## Each case has the ratio measured on the dev PC on 2026-10-28 and fails past SLACK times
## it, so a tick 2 times slower fails. When the tick gets faster for good, lower the base
## so the margin stays. The reference takes about 170 us on the idle dev PC, so every limit
## sits below the 2 ms mean of docs/ARCHITECTURE.md 9.2 (the highest, 8.93, is about
## 1.5 ms). The absolute means are printed for the record, not asserted, since load moves
## them.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

const COPIES: int = 3
## How far above its base a case's ratio may go before the test fails.
const SLACK: float = 1.5

## A long serpentine road, 41 steps, 11 rows and 7 spots, like the largest region 1 maps.
const SNAKE_GRID: Array = [
	"1######",
	"o..o..#",
	"#######",
	"#..o..o",
	"#######",
	"o..o..#",
	"#######",
	"#..o...",
	"#######",
	"......#",
	"......B",
]

## A serpentine road past 16 spots in pairs, so Bakeries have neighbours to boost.
const PAIRS_GRID: Array = [
	"1######",
	"oo..oo#",
	"#######",
	"#oo..oo",
	"#######",
	"oo..oo#",
	"#######",
	"#oo..oo",
	"#######",
	"......#",
	"......B",
]

## Level 2-2 (Sleepy Mill), the map of the balance analyst's most crowded case.
const MILL_GRID: Array = [
	".1.....",
	".#.o...",
	".#G###.",
	".#o#.#.",
	".G.#o#.",
	".#o#.#o",
	".###.#.",
	"....o#.",
	".#####.",
	".#oG.o.",
	".###...",
	"...B...",
]

## Every map feature with room for 23 towers: entrance 1 through the tunnel and under the
## bridge to the stumps, entrance 2 over the bridge and down the slide (Fx.FEATURE_GRID
## with more build spots).
const FEATURE_CROWD_GRID: Array = [
	"o..1...",
	"o.oT.oo",
	".o.T.o.",
	"2##X##.",
	"o.o#ov.",
	".o.#ov.",
	"o.oP.#o",
	".o.#o#.",
	"o.o#.#o",
	".o.#.P.",
	"o.o#.G.",
	"...###.",
	"....B..",
]


## Steps COPIES battles from `build` in lockstep until the lead copy's wave phase ends or
## `max_ticks`. The second wave is called as soon as it may be. On each tick that starts
## with at least `crowd` live creatures it runs `_reference` after each copy's step and
## keeps the fastest step and the fastest reference. Returns what the cases check: "best"
## and "ref" (those times), "plain" (the lead copy's times on the same ticks), "peak",
## "kinds" (event kinds seen), and over the crowded ticks "low" (most low flyers at once)
## and the sums "awake", "hidden" and "away".
func _measure(build: Callable, crowd: int, max_ticks: int) -> Dictionary:
	var copies: Array[Battle] = []
	for i: int in COPIES:
		var made: Battle = build.call()
		assert_not_null(made)
		if made == null:
			return {}
		assert_eq(made.start_next_wave(), Battle.DONE)
		copies.append(made)
	var lead: Battle = copies[0]
	var best: Array[int] = []
	var ref: Array[int] = []
	var plain: Array[int] = []
	var kinds: Dictionary = {}
	var out: Dictionary = {"peak": 0, "low": 0, "awake": 0, "hidden": 0, "away": 0}
	while lead.phase == Battle.Phase.WAVE and lead.tick < max_ticks:
		var crowded: bool = lead.enemies.size() >= crowd
		var fastest: int = 1 << 40
		var ref_fastest: int = 1 << 40
		var first: int = 0
		for b: Battle in copies:
			if b.waves_started == 1 and b.next_wave_info()["refusal"] == &"":
				b.start_next_wave()
			var start: int = Time.get_ticks_usec()
			b.step()
			var spent: int = Time.get_ticks_usec() - start
			fastest = mini(fastest, spent)
			if crowded:
				start = Time.get_ticks_usec()
				_reference()
				ref_fastest = mini(ref_fastest, Time.get_ticks_usec() - start)
			if b == lead:
				first = spent
				for event: Dictionary in b.take_events():
					kinds[event["kind"]] = true
			else:
				b.take_events()
		out["peak"] = maxi(out["peak"], lead.enemies.size())
		if not crowded:
			continue
		best.append(fastest)
		ref.append(ref_fastest)
		plain.append(first)
		out["low"] = maxi(out["low"], lead._low_list.size())
		for e: EnemyState in lead.enemies:
			out["awake"] += 1 if e.awake else 0
			out["hidden"] += 1 if e.hidden else 0
			out["away"] += 1 if e.out_of_reach else 0
	# The copies did the same work, or the fastest copy means nothing.
	for b: Battle in copies:
		assert_eq([b.tick, b.enemies.size(), b.lives, b.gold], [lead.tick, lead.enemies.size(), lead.lives, lead.gold], "copies stayed in step")
	out["best"] = best
	out["ref"] = ref
	out["plain"] = plain
	out["kinds"] = kinds
	return out


static func _mean(times: Array[int]) -> int:
	var total: int = 0
	for t: int in times:
		total += t
	return total / maxi(times.size(), 1)


static func _p99(times: Array[int]) -> int:
	if times.is_empty():
		return 0
	var sorted: Array[int] = times.duplicate()
	sorted.sort()
	return sorted[mini(sorted.size() - 1, sorted.size() * 99 / 100)]


## A fixed piece of plain GDScript work of the same kind as a tick's: 8 spots each walk
## 120 small objects, test them against a reach circle and keep the hits. Nothing in it
## depends on the sim, so a slower sim does not make it slower, while a busy machine slows
## both about alike.
class Dot extends RefCounted:
	var at: Vector2i = Vector2i.ZERO
	var hp: int = 0


var _dots: Array[Dot] = []
var _spots: Array[Vector2i] = []


func before_each() -> void:
	for i: int in 120:
		var d: Dot = Dot.new()
		d.at = Vector2i((i * 7919) % 7000, (i * 104729) % 13000)
		d.hp = 1000
		_dots.append(d)
	for i: int in 8:
		_spots.append(Vector2i(500 + (i % 4) * 2000, 1000 + (i / 4) * 3000))


func _reference() -> void:
	for spot: Vector2i in _spots:
		var picked: Array[int] = []
		for i: int in _dots.size():
			var gap: Vector2i = _dots[i].at - spot
			if gap.x * gap.x + gap.y * gap.y <= 6250000:
				picked.append(i)
		for i: int in picked:
			_dots[i].hp -= 1


## Prints the numbers and checks the ratio against SLACK times `base`, the case's ratio on
## the dev PC.
func _report(label: String, m: Dictionary, crowd: int, min_ticks: int, base: float) -> void:
	var best: Array[int] = m["best"]
	var ref: Array[int] = m["ref"]
	var plain: Array[int] = m["plain"]
	assert_true(best.size() >= min_ticks, "%s: %d ticks measured" % [label, best.size()])
	var mean: int = _mean(best)
	var ratio: float = float(mean) / float(maxi(_mean(ref), 1))
	print("    sim: %s, %d ticks with %d or more creatures, peak %d: ratio %.2f (base %.2f, limit %.2f); fastest of %d mean %d us, reference %d us; one copy mean %d us, 99th percentile %d us" % [
		label, best.size(), crowd, m["peak"], ratio, base, base * SLACK, COPIES, mean, _mean(ref), _mean(plain), _p99(plain)])
	assert_true(ratio < base * SLACK, "%s: a tick costs %.2f reference runs, more than %.1f times its base %.2f" % [label, ratio, SLACK, base])


func _build_region_1() -> Battle:
	var waves: Array = [
		{"groups": [Fx.group("pip", 60, 0, 50), Fx.group("scamp", 40, 0, 100), Fx.group("flitter", 20, 0, 150)]},
		{"groups": [Fx.group("grumblesack", 1), Fx.group("scamp", 100, 0, 50), Fx.group("pip", 19, 0, 100)]},
	]
	var b: Battle = Fx.battle(SNAKE_GRID, waves, {"start_gold": 10000, "strength": 1000}, Fx.catalog(), true)
	if b == null:
		return null
	var plan: Array = [
		[Vector2i(0, 1), &"sling_post", 0], [Vector2i(3, 1), &"pumpkin_catapult", 0],
		[Vector2i(3, 3), &"pumpkin_catapult", 1], [Vector2i(6, 3), &"sling_post", 1],
		[Vector2i(0, 5), &"sling_post", 0], [Vector2i(3, 5), &"pumpkin_catapult", 0],
		[Vector2i(3, 7), &"sling_post", 0],
	]
	for item: Array in plan:
		assert_eq(b.place_tower(item[0], item[1]), Battle.DONE)
		b.upgrade_tower(item[0])
		assert_eq(b.upgrade_tower(item[0], item[2]), Battle.DONE)
	return b


## The largest region 1 crowd: two waves of 120 on the map at once (the spawn bound and
## max_waves_running), seven tier 3 towers, a boss with summons.
func test_time_per_tick_in_the_largest_region_1_crowd() -> void:
	var m: Dictionary = _measure(_build_region_1, 150, 3000)
	if m.is_empty():
		return
	assert_true(m["peak"] >= 200, "peak %d live creatures" % m["peak"])
	_report("region 1 crowd", m, 150, 100, 2.20)


func _build_support() -> Battle:
	# Wave 0 is a sturdy crowd with Menders and flyers; wave 1, called early, brings
	# Puffballs that split. Every tower kind and path that adds work per tick stands.
	var waves: Array = [
		{"strength": 1000, "groups": [Fx.group("pip", 55, 0, 50), Fx.group("scamp", 40, 0, 50), Fx.group("mender", 15, 0, 100), Fx.group("flitter", 10, 0, 100)]},
		{"strength": 100, "groups": [Fx.group("puffball", 30, 0, 100)]},
	]
	var all: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery"]
	var b: Battle = Fx.battle(PAIRS_GRID, waves, {"start_gold": 100000, "towers": all}, Fx.catalog(), true)
	if b == null:
		return null
	var plan: Array = [
		[Vector2i(0, 1), &"sling_post", 0], [Vector2i(1, 1), &"bakery", 0],
		[Vector2i(4, 1), &"lullaby_bell", 0], [Vector2i(5, 1), &"pumpkin_catapult", 0],
		[Vector2i(1, 3), &"bakery", 1], [Vector2i(2, 3), &"pumpkin_catapult", 1],
		[Vector2i(5, 3), &"lullaby_bell", 1], [Vector2i(6, 3), &"firework_tower", 0],
		[Vector2i(0, 5), &"longbow_loft", 1], [Vector2i(1, 5), &"bakery", 0],
		[Vector2i(4, 5), &"longbow_loft", 0], [Vector2i(5, 5), &"lullaby_bell", 0],
		[Vector2i(1, 7), &"pumpkin_catapult", 0], [Vector2i(2, 7), &"bakery", 0],
		[Vector2i(5, 7), &"sling_post", 0], [Vector2i(6, 7), &"lullaby_bell", 1],
	]
	for item: Array in plan:
		assert_eq(b.place_tower(item[0], item[1]), Battle.DONE)
		# Attacking towers stay at tier 1, so the crowd lives long enough to measure.
		if b.tower_at(item[0]).kind != &"attack":
			b.upgrade_tower(item[0])
			assert_eq(b.upgrade_tower(item[0], item[2]), Battle.DONE)
	return b


func test_time_per_tick_with_bells_bakeries_menders_and_splits() -> void:
	var m: Dictionary = _measure(_build_support, 150, 4000)
	if m.is_empty():
		return
	var kinds: Dictionary = m["kinds"]
	assert_true(kinds.has(&"healed") and kinds.has(&"released"), "heals and splits happened: %s" % str(kinds.keys()))
	assert_true(m["peak"] >= 150, "peak %d live creatures" % m["peak"])
	_report("support crowd", m, 150, 100, 2.30)


## The expansion towers on the same road: pulses, lines, frights and a lured flock,
## beside today's towers (docs/ARCHITECTURE.md 14.12). Attacking towers stay at tier 1,
## so the crowd lives long enough to measure.
func _build_expansion() -> Battle:
	var waves: Array = [
		{"strength": 1000, "groups": [Fx.group("pip", 45, 0, 50), Fx.group("scamp", 30, 0, 50), Fx.group("shellback", 15, 0, 100),
			Fx.group("flitter", 30, 0, 100)]},
		{"strength": 400, "groups": [Fx.group("puffball", 30, 0, 100)]},
	]
	var b: Battle = Fx.battle(PAIRS_GRID, waves, {"start_gold": 100000, "towers": Tx.ALL}, Tx.catalog(), true)
	if b == null:
		return null
	var plan: Array = [
		[Vector2i(0, 1), &"moth_lantern"], [Vector2i(1, 1), &"bakery"],
		[Vector2i(4, 1), &"bramble_cottage"], [Vector2i(5, 1), &"snow_fort"],
		[Vector2i(1, 3), &"scarecrow"], [Vector2i(2, 3), &"bramble_cottage"],
		[Vector2i(5, 3), &"lullaby_bell"], [Vector2i(6, 3), &"snow_fort"],
		[Vector2i(0, 5), &"moth_lantern"], [Vector2i(1, 5), &"pumpkin_catapult"],
		[Vector2i(4, 5), &"scarecrow"], [Vector2i(5, 5), &"snow_fort"],
		[Vector2i(1, 7), &"bramble_cottage"], [Vector2i(2, 7), &"longbow_loft"],
		[Vector2i(5, 7), &"sling_post"], [Vector2i(6, 7), &"moth_lantern"],
	]
	for item: Array in plan:
		assert_eq(b.place_tower(item[0], item[1]), Battle.DONE)
	return b


func test_time_per_tick_with_the_expansion_towers() -> void:
	var m: Dictionary = _measure(_build_expansion, 120, 4000)
	if m.is_empty():
		return
	assert_true(m["peak"] >= 120, "peak %d live creatures" % m["peak"])
	assert_true(m["low"] > 0, "flyers were lured low in the crowd")
	_report("expansion towers", m, 120, 100, 2.15)


## Level 2-2 (Sleepy Mill) as the balance analyst's most crowded case, waves 9 and 10 with
## the bot's five towers and its gate, wave 10 called as soon as it may be: about 115 live
## creatures, the case the Fold5 measured on 2026-10-27 (docs/render/perf-fold5-2026-10-27.md).
func _build_mill() -> Battle:
	var waves: Array = [
		{"strength": 135, "groups": [Fx.group("skitter", 20, 0, 450), Fx.group("scamp", 40, 8000, 100), Fx.group("flitter", 10, 12000, 400)]},
		{"strength": 115, "groups": [Fx.group("pip", 56, 0, 50), Fx.group("skitter", 16, 5000, 500), Fx.group("flitter", 8, 9000, 400)]},
	]
	var b: Battle = Fx.battle(MILL_GRID, waves, {"start_gold": 10000, "gates": 1, "towers": ["sling_post", "pumpkin_catapult", "lullaby_bell"]})
	if b == null:
		return null
	for item: Array in [[Vector2i(3, 1), &"sling_post", 1], [Vector2i(2, 3), &"lullaby_bell", 2], [Vector2i(2, 5), &"pumpkin_catapult", 1],
			[Vector2i(4, 7), &"sling_post", 2], [Vector2i(5, 9), &"sling_post", 2]]:
		assert_eq(b.place_tower(item[0], item[1]), Battle.DONE)
		if item[2] == 2:
			assert_eq(b.upgrade_tower(item[0]), Battle.DONE)
	assert_eq(b.place_gate(Vector2i(2, 2)), Battle.DONE)
	return b


func test_time_per_tick_in_the_level_2_2_crowd() -> void:
	var m: Dictionary = _measure(_build_mill, 100, 4000)
	if m.is_empty():
		return
	assert_true(m["peak"] >= 100, "peak %d live creatures" % m["peak"])
	_report("level 2-2 crowd", m, 100, 50, 1.45)


## The creatures of regions 7 and 8 in a crowd on the same road: growers, Yawners dozing
## the towers, Blinkers, the most Hootlings a wave brings (RULES 12.5) under Bells, and
## both bosses, against the expansion towers and today's (docs/ARCHITECTURE.md 14.12).
## Attacking towers stay at tier 1, so the crowd lives long enough to measure.
func _build_late() -> Battle:
	var waves: Array = [
		{"strength": 1000, "groups": [Fx.group("snowroller", 30, 0, 50), Fx.group("blinker", 30, 0, 50), Fx.group("yawner", 14, 0, 100),
			Fx.group("hootling", 6, 0, 500), Fx.group("pip", 25, 0, 50), Fx.group("flitter", 15, 0, 100)]},
		{"strength": 400, "groups": [Fx.group("snowsnore", 1), Fx.group("glimmertoad", 1, 500), Fx.group("hootling", 6, 0, 300),
			Fx.group("snowroller", 30, 0, 100), Fx.group("blinker", 30, 0, 100)]},
	]
	var b: Battle = Fx.battle(PAIRS_GRID, waves, {"start_gold": 100000, "towers": Tx.ALL}, Cx.catalog(), true)
	if b == null:
		return null
	var plan: Array = [
		[Vector2i(0, 1), &"moth_lantern"], [Vector2i(1, 1), &"lullaby_bell"],
		[Vector2i(4, 1), &"bramble_cottage"], [Vector2i(5, 1), &"snow_fort"],
		[Vector2i(1, 3), &"scarecrow"], [Vector2i(2, 3), &"sling_post"],
		[Vector2i(5, 3), &"lullaby_bell"], [Vector2i(6, 3), &"snow_fort"],
		[Vector2i(0, 5), &"pumpkin_catapult"], [Vector2i(1, 5), &"bakery"],
		[Vector2i(4, 5), &"lullaby_bell"], [Vector2i(5, 5), &"bramble_cottage"],
		[Vector2i(1, 7), &"longbow_loft"], [Vector2i(2, 7), &"lullaby_bell"],
		[Vector2i(5, 7), &"sling_post"], [Vector2i(6, 7), &"firework_tower"],
	]
	for item: Array in plan:
		assert_eq(b.place_tower(item[0], item[1]), Battle.DONE)
	return b


func test_time_per_tick_with_the_creatures_of_regions_7_and_8() -> void:
	var m: Dictionary = _measure(_build_late, 150, 4000)
	if m.is_empty():
		return
	var kinds: Dictionary = m["kinds"]
	assert_true(kinds.has(&"yawned") and kinds.has(&"blinked"), "yawns and blinks happened: %s" % str(kinds.keys()))
	assert_true(m["awake"] > 0, "creatures were kept awake in the crowd")
	assert_true(m["peak"] >= 150, "peak %d live creatures" % m["peak"])
	_report("regions 7 and 8 crowd", m, 150, 100, 4.20)


## The crowded case of docs/ARCHITECTURE.md 14.12: about 200 live over two waves, with
## Mistwisps, Hootlings, Yawners, Mossbuds, Gleamers, a lured flock and a digging
## Burrowbelly, on a map with a tunnel, a bridge, a slide and stumps, against Bramble
## Cottages, Snow Forts, Scarecrows, Moth Lanterns and today's towers. Attacking towers
## stay at tier 1, so the crowd lives long enough to measure.
func _build_crowded_expansion() -> Battle:
	var waves: Array = [
		{"strength": 1000, "groups": [Fx.group("mossbud", 36, 0, 50), Fx.group("gleamer", 20, 0, 100, 2), Fx.group("yawner", 12, 0, 150),
			Fx.group("mistwisp", 6, 0, 300, 2), Fx.group("hootling", 6, 0, 300), Fx.group("flitter", 26, 0, 100, 2)]},
		{"strength": 600, "groups": [Fx.group("burrowbelly", 1), Fx.group("mossbud", 36, 0, 50, 2), Fx.group("gleamer", 16, 0, 100),
			Fx.group("yawner", 10, 0, 150, 2), Fx.group("mistwisp", 6, 0, 300), Fx.group("hootling", 6, 0, 300, 2), Fx.group("flitter", 26, 0, 100)]},
	]
	var b: Battle = Fx.battle(FEATURE_CROWD_GRID, waves, {"start_gold": 100000, "towers": Tx.ALL}, Cx.catalog(), true)
	if b == null:
		return null
	var plan: Array = [
		[Vector2i(2, 1), &"bramble_cottage"], [Vector2i(5, 1), &"moth_lantern"], [Vector2i(1, 2), &"snow_fort"],
		[Vector2i(5, 2), &"scarecrow"], [Vector2i(0, 1), &"lullaby_bell"], [Vector2i(6, 1), &"bakery"],
		[Vector2i(2, 4), &"bramble_cottage"], [Vector2i(4, 4), &"snow_fort"], [Vector2i(4, 5), &"moth_lantern"],
		[Vector2i(1, 5), &"pumpkin_catapult"], [Vector2i(2, 6), &"scarecrow"], [Vector2i(6, 6), &"sling_post"],
		[Vector2i(4, 7), &"bramble_cottage"], [Vector2i(2, 8), &"snow_fort"], [Vector2i(6, 8), &"moth_lantern"],
		[Vector2i(1, 9), &"longbow_loft"], [Vector2i(2, 10), &"firework_tower"], [Vector2i(0, 8), &"lullaby_bell"],
	]
	for item: Array in plan:
		assert_eq(b.place_tower(item[0], item[1]), Battle.DONE, "%s at %s" % [item[1], item[0]])
	return b


func test_time_per_tick_in_the_crowded_expansion_case() -> void:
	var m: Dictionary = _measure(_build_crowded_expansion, 150, 4000)
	if m.is_empty():
		return
	var kinds: Dictionary = m["kinds"]
	for kind: StringName in [&"burrowed", &"yawned"]:
		assert_true(kinds.has(kind), "%s happened: %s" % [kind, str(kinds.keys())])
	assert_true(m["low"] > 0, "flyers were lured low in the crowd")
	assert_true(m["hidden"] > 0, "creatures hid in the mist in the crowd")
	assert_true(m["away"] > 0, "creatures were out of reach in the crowd")
	assert_true(m["peak"] >= 180, "peak %d live creatures" % m["peak"])
	_report("crowded expansion case", m, 150, 100, 5.95)
