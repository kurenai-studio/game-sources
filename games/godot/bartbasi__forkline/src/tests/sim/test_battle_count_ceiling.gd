# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The wave effect ceilings (docs/ARCHITECTURE.md 5.6): stacked count_pct, speed_pct and
## health_pct effects in a Twist and a risk card never overflow, and a battle whose group
## would pass MAX_ENEMIES, whose speed effects would pass MAX_SPEED_PCT, or whose
## creatures' max health would pass BIG is refused at load and by add_effects.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


## Two waves of one Scamp group each. 100 Scamps times 10 to the 16th would overflow.
func _level(count: int = 4) -> LevelData:
	var waves: Array = [
		{"groups": [Fx.group("scamp", count, 0, 600)]},
		{"groups": [Fx.group("scamp", count, 0, 600)]},
	]
	return Fx.level(Fx.FORK_GRID, waves, {}, catalog)


func _counts(pcts: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pct: int in pcts:
		out.append({"type": "count_pct", "pct": pct, "flyers": false, "last_wave": false})
	return out


func _many(n: int) -> Array[Dictionary]:
	var pcts: Array = []
	for i: int in n:
		pcts.append(1000)
	return _counts(pcts)


func _data(b: Battle) -> Dictionary:
	return JSON.parse_string(JSON.stringify(b.to_data()))


func test_group_count_clamps_as_it_multiplies_and_never_overflows() -> void:
	var stacked: Array[Dictionary] = _many(Modifiers.MAX_TWIST + Modifiers.MAX_WAITING)
	assert_eq(Modifiers.group_count(stacked, 200, false, false), Modifiers.COUNT_CEILING, "16 effects at 1,000 percent stop at the ceiling")
	assert_eq(Modifiers.group_count(stacked, 1, true, true), Modifiers.COUNT_CEILING, "from a count of 1 too")
	assert_eq(Modifiers.group_count(_counts([150]), 200, false, false), 300, "a real risk card is unchanged")
	assert_eq(Modifiers.group_count(_counts([200, 150]), 7, false, false), 21, "rounded up at each step, as before")
	assert_eq(Modifiers.group_count([] as Array[Dictionary], 200, false, false), 200, "no effects")


func test_the_overflow_case_is_refused_at_load() -> void:
	var b: Battle = Battle.create(_level(100), catalog, false, [])
	var data: Dictionary = _data(b)
	assert_not_null(Battle.from_data(data, catalog), "the base data is valid")
	var both: Dictionary = data.duplicate(true)
	both["twist"] = _many(Modifiers.MAX_TWIST)
	both["risk"] = _many(Modifiers.MAX_WAITING)
	assert_null(Battle.from_data(both, catalog), "8 Twist and 8 risk effects at 1,000 percent")
	var twist: Dictionary = data.duplicate(true)
	twist["twist"] = _many(Modifiers.MAX_TWIST)
	assert_null(Battle.from_data(twist, catalog), "8 Twist effects at 1,000 percent")
	var risk: Dictionary = data.duplicate(true)
	risk["risk"] = _many(Modifiers.MAX_WAITING)
	assert_null(Battle.from_data(risk, catalog), "a waiting risk card of 8 effects at 1,000 percent")


func test_a_running_waves_risk_card_is_counted_at_load() -> void:
	var b: Battle = Battle.create(_level(100), catalog, false, [])
	assert_eq(b.add_effects(_counts([150]), true), Battle.DONE)
	assert_eq(b.start_next_wave(), Battle.DONE)
	b.step()
	var data: Dictionary = _data(b)
	assert_eq((data["wave_risk"] as Array).size(), 1, "wave 0 took the risk card")
	assert_not_null(Battle.from_data(data, catalog), "the base data is valid")
	data["wave_risk"][0]["effects"] = _many(Modifiers.MAX_WAITING)
	assert_null(Battle.from_data(data, catalog), "a running wave's risk card of 8 effects at 1,000 percent")


## 4 Scamps times 10 times 10 times 10 is exactly MAX_ENEMIES; a waiting 101 percent
## passes it.
func test_the_ceiling_is_max_enemies_per_group() -> void:
	var twist: Array[Dictionary] = _counts([1000, 1000, 1000])
	var b: Battle = Battle.create(_level(), catalog, false, twist)
	assert_eq(Modifiers.group_count(twist, 4, false, false), Battle.MAX_ENEMIES)
	var data: Dictionary = _data(b)
	assert_not_null(Battle.from_data(data, catalog), "a group of exactly %d loads" % Battle.MAX_ENEMIES)
	var past: Dictionary = data.duplicate(true)
	past["risk"] = _counts([101])
	assert_null(Battle.from_data(past, catalog), "a group of %d is refused" % Modifiers.group_count(_counts([1000, 1000, 1000, 101]), 4, false, false))
	var level_risk: Dictionary = data.duplicate(true)
	level_risk["risk"] = _counts([100])
	assert_not_null(Battle.from_data(level_risk, catalog), "a risk card that keeps the count loads")


func test_add_effects_refuses_a_risk_card_past_the_ceiling() -> void:
	var b: Battle = Battle.create(_level(), catalog, false, _counts([1000, 1000, 1000]))
	assert_eq(b.add_effects(_counts([101]), true), &"bad_effect", "a group would pass %d" % Battle.MAX_ENEMIES)
	assert_true(b.risk_waiting.is_empty(), "nothing waits")
	assert_eq(b.add_effects(_counts([100]), true), Battle.DONE, "a group of exactly %d" % Battle.MAX_ENEMIES)
	var fresh: Battle = Battle.create(_level(), catalog, false, [])
	assert_eq(fresh.add_effects(_many(Modifiers.MAX_WAITING), true), &"bad_effect", "8 effects at 1,000 percent")
	assert_eq(fresh.add_effects(_counts([150]), true), Battle.DONE, "a real risk card")


func _typed(name: String, pcts: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pct: int in pcts:
		out.append({"type": name, "pct": pct})
	return out


func _repeat(pct: int, n: int) -> Array:
	var out: Array = []
	for i: int in n:
		out.append(pct)
	return out


## The largest max health the battle judges under these health effects (docs/ARCHITECTURE.md
## 14.7): every creature of the catalog, scaled by them, and a grower at its growth cap. _level()
## is at strength 100.
func _ceiling_health(pcts: Array) -> int:
	var effects: Array[Dictionary] = _typed("health_pct", pcts)
	var most: int = 1
	for id: StringName in catalog.enemy_ids():
		var type: EnemyType = catalog.enemy(id)
		var start: int = maxi(1, Modifiers.scale_all(effects, "health_pct", type.health))
		most = maxi(most, start * type.grow_cap_pct / 100 if type.grow_pct > 0 else start)
	return most


func test_speed_and_health_clamp_as_they_multiply_and_never_overflow() -> void:
	var speeds: Array[Dictionary] = _typed("speed_pct", _repeat(1000, 16))
	assert_eq(Modifiers.speed_pct(speeds), Modifiers.PCT_CEILING, "16 speed effects at 1,000 percent stop at the ceiling")
	assert_eq(Modifiers.speed_pct(_typed("speed_pct", [120, 150])), 180, "real effects are unchanged")
	var healths: Array[Dictionary] = _typed("health_pct", _repeat(1000, 16))
	assert_eq(Modifiers.scale_all(healths, "health_pct", 1000000), Modifiers.VALUE_CEILING, "16 health effects at 1,000 percent stop at the ceiling")
	assert_eq(Modifiers.scale_all(_typed("health_pct", [150]), "health_pct", 3000), 4500, "a real risk card is unchanged")


func test_speed_past_the_ceiling_is_refused_at_load_and_by_add_effects() -> void:
	var b: Battle = Battle.create(_level(), catalog, false, _typed("speed_pct", [1000]))
	var data: Dictionary = _data(b)
	assert_not_null(Battle.from_data(data, catalog), "speed at exactly %d percent loads" % Battle.MAX_SPEED_PCT)
	var past: Dictionary = data.duplicate(true)
	past["risk"] = _typed("speed_pct", [101])
	assert_null(Battle.from_data(past, catalog), "1,010 percent is refused")
	var stacked: Dictionary = data.duplicate(true)
	stacked["twist"] = _typed("speed_pct", _repeat(1000, Modifiers.MAX_TWIST))
	stacked["risk"] = _typed("speed_pct", _repeat(1000, Modifiers.MAX_WAITING))
	assert_null(Battle.from_data(stacked, catalog), "8 Twist and 8 risk speed effects at 1,000 percent")
	assert_eq(b.add_effects(_typed("speed_pct", [101]), true), &"bad_effect", "add_effects refuses 1,010 percent")
	assert_eq(b.add_effects(_typed("speed_pct", [100]), true), Battle.DONE, "and takes exactly %d" % Battle.MAX_SPEED_PCT)
	var fresh: Battle = Battle.create(_level(), catalog, false, [])
	assert_eq(fresh.add_effects(_typed("speed_pct", [150]), true), Battle.DONE, "a real risk card")
	assert_eq(fresh.start_next_wave(), Battle.DONE)
	fresh.step()
	var running: Dictionary = _data(fresh)
	assert_not_null(Battle.from_data(running, catalog), "a running wave with a real speed risk loads")
	running["wave_risk"][0]["effects"] = _typed("speed_pct", _repeat(1000, Modifiers.MAX_WAITING))
	assert_null(Battle.from_data(running, catalog), "a running wave's 8 speed effects at 1,000 percent")


## The catalog's largest max health at strength 100, a grower at its cap: five 1,000 percent
## effects keep it under BIG for real data; one more effect finds the edge.
func test_max_health_past_big_is_refused_at_load_and_by_add_effects() -> void:
	var base: Array = _repeat(1000, 5)
	var below: int = _ceiling_health(base)
	assert_true(below <= Battle.BIG, "the base stays under BIG: %d" % below)
	var fits: int = mini(Battle.BIG * 100 / below, 1000)
	while fits > 1 and _ceiling_health(base + [fits]) > Battle.BIG:
		fits -= 1
	var over: int = fits + 1
	while over <= 1000 and _ceiling_health(base + [over]) <= Battle.BIG:
		over += 1
	assert_true(over <= 1000, "the edge is within one effect: %d" % over)
	var b: Battle = Battle.create(_level(), catalog, false, [])
	var data: Dictionary = _data(b)
	var at_edge: Dictionary = data.duplicate(true)
	at_edge["risk"] = _typed("health_pct", base + [fits])
	assert_not_null(Battle.from_data(at_edge, catalog), "max health at most BIG loads")
	var past: Dictionary = data.duplicate(true)
	past["risk"] = _typed("health_pct", base + [over])
	assert_null(Battle.from_data(past, catalog), "max health past BIG is refused")
	var stacked: Dictionary = data.duplicate(true)
	stacked["risk"] = _typed("health_pct", _repeat(1000, Modifiers.MAX_WAITING))
	assert_null(Battle.from_data(stacked, catalog), "8 health effects at 1,000 percent")
	assert_eq(b.add_effects(_typed("health_pct", base + [over]), true), &"bad_effect", "add_effects refuses past BIG")
	assert_eq(b.add_effects(_typed("health_pct", base + [fits]), true), Battle.DONE, "and takes the edge")
	var fresh: Battle = Battle.create(_level(), catalog, false, [])
	assert_eq(fresh.add_effects(_typed("health_pct", [200]), true), Battle.DONE, "a real risk card")
	assert_eq(fresh.start_next_wave(), Battle.DONE)
	fresh.step()
	var running: Dictionary = _data(fresh)
	assert_not_null(Battle.from_data(running, catalog), "a running wave with a real health risk loads")
	running["wave_risk"][0]["effects"] = _typed("health_pct", _repeat(1000, Modifiers.MAX_WAITING))
	assert_null(Battle.from_data(running, catalog), "a running wave's 8 health effects at 1,000 percent")


## A Twist on its own is checked against the wave ceilings at create, so no battle starts
## that no save of could load. The level file's check passes this Twist; create refuses it.
func test_create_refuses_a_twist_past_a_wave_ceiling() -> void:
	var twist: Dictionary = {"name": "Too Fast", "text": "Far too fast.", "effects": _typed("speed_pct", [1000, 1000])}
	var waves: Array = [{"groups": [Fx.group("scamp", 4, 0, 600)]}, {"groups": [Fx.group("scamp", 4, 0, 600)]}]
	var level: LevelData = Fx.level(Fx.FORK_GRID, waves, {"twist": twist}, catalog)
	assert_not_null(level, "the level file's check passes the Twist")
	assert_null(Battle.create(level, catalog, false, level.twist_effects), "two speed effects at 1,000 percent")
	assert_null(Battle.create(level, catalog, true, level.twist_effects), "Relaxed too")
	assert_not_null(Battle.create(level, catalog, false, _typed("speed_pct", [1000])), "exactly %d percent" % Battle.MAX_SPEED_PCT)
	assert_null(Battle.create(_level(), catalog, false, _counts([1000, 1000, 1000, 101])), "a group past %d" % Battle.MAX_ENEMIES)


func test_create_checks_every_wave_with_the_twist() -> void:
	var twist: Array[Dictionary] = _counts([1000, 1000, 1000])
	assert_not_null(Battle.create(_level(), catalog, false, twist), "every group at exactly %d" % Battle.MAX_ENEMIES)
	twist.append({"type": "count_pct", "pct": 101, "flyers": false, "last_wave": true})
	assert_null(Battle.create(_level(), catalog, false, twist), "only the last wave passes the ceiling")


## Eight effects at 1,000 percent on the most starting gold a level holds would overflow
## an int. Each step is clamped, so starting gold stops at BIG and the battle saves.
func test_starting_gold_stops_at_big() -> void:
	var level: LevelData = Fx.level(Fx.FORK_GRID, [{"groups": [Fx.group("scamp", 4)]}], {"start_gold": 100000}, catalog)
	var rich: Array[Dictionary] = _typed("start_gold_pct", _repeat(1000, Modifiers.MAX_TWIST))
	for relaxed: bool in [false, true]:
		var b: Battle = Battle.create(level, catalog, relaxed, rich)
		assert_eq(b.gold, Battle.BIG, "relaxed %s" % relaxed)
		assert_not_null(Battle.from_data(_data(b), catalog), "relaxed %s saves and loads" % relaxed)
	assert_eq(Battle.create(level, catalog, false, _typed("start_gold_pct", [1000, 1000, 1000])).gold, 100000000, "under BIG is unchanged")
	assert_eq(Battle.create(level, catalog, true, _typed("start_gold_pct", [1000, 1000, 1000])).gold, 150000000, "Relaxed under BIG is unchanged")
