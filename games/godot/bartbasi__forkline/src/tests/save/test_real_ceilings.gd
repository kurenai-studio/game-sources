# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The save ceilings of docs/ARCHITECTURE.md 14.7 are far ceilings: real levels, Twists,
## runs and dailies stay far below MAX_WAKERS, and far below the max health ceiling with
## growers counted at their cap. So a real player never meets a refused save. "Far below"
## here is at most half of MAX_WAKERS and at most a thousandth of the health ceiling.

const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")
const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

const SEEDS: int = 40
const DAYS: Array[String] = ["2026-10-28", "2026-12-31", "2027-06-15"]

var game: GameData = null


func before_each() -> void:
	game = GameData.load_from()


## The most creatures with wake_reach the waves on the map at once can hold, as the save
## check counts them (Battle._check_crowd), each wave taking the risk card that brings the
## most. risks: the normalized effects of each risk card that may come.
func _wakers_at_once(b: Battle, risks: Array) -> int:
	var tallies: Array[Array] = []
	for w: int in b.level.waves.size():
		var best: Array[int] = [0, 0, 0, 0]
		for risk: Array in [[]] + risks:
			var tally: Array[int] = [0, 0, 0, 0]
			for group: WaveGroup in b._make_mods(w, risk).groups:
				b._tally(tally, group.enemy, group.count, true)
			if tally[3] > best[3]:
				best = tally
		tallies.append(best)
	return b._at_once(tallies, 3)


## The largest max health wave w can give any creature of the catalog, a grower at its
## cap, as Battle._wave_effects_problem judges it, with the Twist and each risk card.
func _most_health(b: Battle, w: int, risks: Array) -> int:
	var most: int = 0
	for risk: Array in [[]] + risks:
		var effects: Array[Dictionary] = b.twist_effects.duplicate()
		for effect: Dictionary in risk:
			effects.append(effect)
		for id: StringName in b.catalog.enemy_ids():
			var type: EnemyType = b.catalog.enemy(id)
			var health: int = Modifiers.scale_all(effects, "health_pct", b._scaled(type.health, w))
			if type.grow_pct > 0:
				health = health * type.grow_cap_pct / 100
			most = maxi(most, health)
	return most


func _check(b: Battle, label: String, risks: Array) -> void:
	var wakers: int = _wakers_at_once(b, risks)
	assert_true(wakers <= Battle.MAX_WAKERS / 2, "%s: %d wakers at once" % [label, wakers])
	for w: int in b.level.waves.size():
		var health: int = _most_health(b, w, risks)
		assert_true(health <= Battle.BIG / 1000, "%s wave %d: max health %d" % [label, w + 1, health])


func test_real_levels_and_twists_stay_far_below_the_ceilings() -> void:
	assert_eq(game.problems, PackedStringArray())
	assert_true(game.levels.size() > 0)
	for id: StringName in game.levels:
		var level: LevelData = game.levels[id]
		var plain: Battle = Battle.create(level, game.catalog, false, [] as Array[Dictionary])
		assert_not_null(plain, String(id))
		if plain != null:
			_check(plain, String(id), [])
		if not level.twist_effects.is_empty():
			var twist: Battle = Battle.create(level, game.catalog, false, level.twist_effects)
			assert_not_null(twist, "%s Twist" % id)
			if twist != null:
				_check(twist, "%s Twist" % id, [])


func test_real_runs_and_dailies_stay_far_below_the_ceilings_at_every_tier() -> void:
	assert_not_null(game.run)
	if game.run == null:
		return
	var seeds: Array[int] = []
	for run_seed: int in range(1, SEEDS + 1):
		seeds.append(run_seed)
	for day: String in DAYS:
		seeds.append(RunSeeds.daily_seed(day))
	for tier: int in game.run.tiers.size() + 1:
		var risks: Array = []
		for card: Dictionary in game.run.cards:
			if card["kind"] == &"risk" and int(card["tier"]) <= tier:
				risks.append(card["effects"])
		assert_true(risks.size() > 0, "tier %d has risk cards to weigh" % tier)
		for run_seed: int in seeds:
			var level: LevelData = MapAssembler.assemble(run_seed, game.run, game.catalog, tier)
			assert_not_null(level, "seed %d tier %d" % [run_seed, tier])
			if level == null:
				continue
			var b: Battle = Battle.create(level, game.catalog, false, [] as Array[Dictionary])
			assert_not_null(b, "seed %d tier %d" % [run_seed, tier])
			if b != null:
				_check(b, "seed %d tier %d" % [run_seed, tier], risks)


func test_the_counts_match_the_save_check() -> void:
	# The helper counts as the save check does: a wave of MAX_WAKERS Hootlings on the
	# fixture catalog gives MAX_WAKERS.
	var b: Battle = Cx.battle(["...1...", "...#...", "...#...", "...#...", "...#...", "...#...", "...#...", "...B..."],
		[{"groups": [Sx.group("hootling", Battle.MAX_WAKERS)]}, {"groups": [Sx.group("glimmertoad", 1)]}])
	assert_not_null(b)
	if b != null:
		assert_eq(_wakers_at_once(b, []), Battle.MAX_WAKERS + 1, "the two largest waves")
