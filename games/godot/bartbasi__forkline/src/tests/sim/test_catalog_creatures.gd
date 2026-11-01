# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Catalog checks for the creature rules of regions 5 and 6 (docs/ARCHITECTURE.md 14.4):
## regrow, mist, dazzle, nap and dig, with their limits and combinations.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")


## Problems with one creature's fields changed; a null value removes the key.
func _problems_with(id: String, changes: Dictionary) -> PackedStringArray:
	var files: Array = Cx.stats_files()
	for item: Dictionary in files[1]["enemies"]:
		if item["id"] == id:
			for key: String in changes:
				if changes[key] == null:
					item.erase(key)
				else:
					item[key] = changes[key]
	return Catalog.check(files[0], files[1], files[2])


func _ok(id: String, changes: Dictionary, what: String) -> void:
	var problems: PackedStringArray = _problems_with(id, changes)
	assert_true(problems.is_empty(), "%s loads: %s" % [what, str(problems)])


func _bad(id: String, changes: Dictionary, what: String) -> void:
	assert_false(_problems_with(id, changes).is_empty(), "%s is refused" % what)


func test_the_creatures_load_with_their_numbers_rules_6_1_and_6_3() -> void:
	var cat: Catalog = Cx.catalog()
	assert_not_null(cat, "the test catalog loads")
	if cat == null:
		return
	var moss: EnemyType = cat.enemy(&"mossbud")
	assert_eq([moss.health, moss.speed, moss.bounty, moss.regrow, moss.regrow_ms], [80, 80, 10, 4, 1000], "Mossbud")
	assert_true(cat.enemy(&"mistwisp").mist, "Mistwisp")
	assert_true(cat.enemy(&"gleamer").dazzle, "Gleamer")
	assert_eq(cat.enemy(&"sleepyhead").nap_ms, 2000, "Sleepyhead")
	var belly: EnemyType = cat.enemy(&"burrowbelly")
	assert_eq([belly.dig_first_ms, belly.dig_every_ms, belly.dig_ms], [6000, 8000, 2000], "Burrowbelly digs")
	assert_eq(belly.summon, {"enemy": &"mistwisp", "count": 2, "every_ms": 8000, "gap_ms": 300}, "and brings Mistwisps")
	var hay: EnemyType = cat.enemy(&"old_hayrick")
	assert_true(hay.dazzle and hay.nap_ms == 3000, "Old Hayrick")
	var scamp: EnemyType = cat.enemy(&"scamp")
	assert_eq([scamp.regrow, scamp.regrow_ms, scamp.mist, scamp.dazzle, scamp.nap_ms, scamp.dig_first_ms, scamp.dig_every_ms, scamp.dig_ms],
		[0, 0, false, false, 0, 0, 0, 0], "an older creature holds none of them")
	assert_not_null(Fx.catalog(), "the real files still load")


func test_regrow_and_its_limits() -> void:
	_ok("mossbud", {"regrow": 1, "regrow_ms": 50}, "the lowest regrow")
	_ok("mossbud", {"regrow": 10000, "regrow_ms": 600000}, "the highest regrow")
	_bad("mossbud", {"regrow": 0}, "regrow 0")
	_bad("mossbud", {"regrow": 10001}, "regrow 10,001")
	_bad("mossbud", {"regrow_ms": 0}, "regrow_ms 0")
	_bad("mossbud", {"regrow_ms": 600050}, "regrow_ms 600,050")
	_bad("mossbud", {"regrow_ms": 1010}, "regrow_ms off the tick")
	_bad("mossbud", {"regrow": 1.5}, "a regrow that is not whole")
	_bad("mossbud", {"regrow_ms": null}, "regrow without regrow_ms")
	_bad("mossbud", {"regrow": null}, "regrow_ms without regrow")
	_ok("mossbud", {"regrow": null, "regrow_ms": null}, "neither")
	_ok("flitter", {"regrow": 2, "regrow_ms": 500}, "a flyer that regrows")


func test_mist_and_dazzle_are_true_or_false() -> void:
	for key: String in ["mist", "dazzle"]:
		_ok("scamp", {key: false}, "%s false" % key)
		_ok("flitter", {key: true}, "%s on a flyer" % key)
		for bad: Variant in [1, 0, "true", [], {}]:
			_bad("scamp", {key: bad}, "%s = %s" % [key, str(bad)])


func test_nap_and_its_limits() -> void:
	_ok("sleepyhead", {"nap_ms": 50}, "the shortest nap")
	_ok("sleepyhead", {"nap_ms": 60000}, "the longest nap")
	_bad("sleepyhead", {"nap_ms": 0}, "nap_ms 0")
	_bad("sleepyhead", {"nap_ms": 60050}, "nap_ms 60,050")
	_bad("sleepyhead", {"nap_ms": 1010}, "nap_ms off the tick")
	_bad("sleepyhead", {"nap_ms": "2000"}, "nap_ms as text")


func test_dig_and_its_limits() -> void:
	_ok("burrowbelly", {"dig_first_ms": 50, "dig_every_ms": 100, "dig_ms": 50}, "the lowest dig")
	_ok("burrowbelly", {"dig_first_ms": 600000, "dig_every_ms": 600000, "dig_ms": 60000}, "the highest dig")
	_bad("burrowbelly", {"dig_first_ms": 0}, "dig_first_ms 0")
	_bad("burrowbelly", {"dig_first_ms": 600050}, "dig_first_ms 600,050")
	_bad("burrowbelly", {"dig_every_ms": 0}, "dig_every_ms 0")
	_bad("burrowbelly", {"dig_every_ms": 600050}, "dig_every_ms 600,050")
	_bad("burrowbelly", {"dig_ms": 0}, "dig_ms 0")
	_bad("burrowbelly", {"dig_ms": 60050, "dig_every_ms": 600000}, "dig_ms 60,050")
	_bad("burrowbelly", {"dig_ms": 1010}, "dig_ms off the tick")
	_bad("burrowbelly", {"dig_ms": 8000}, "dig_ms equal to dig_every_ms")
	_ok("burrowbelly", {"dig_ms": 7950}, "dig_ms just below dig_every_ms")
	_bad("burrowbelly", {"dig_ms": null}, "dig without dig_ms")
	_bad("burrowbelly", {"dig_first_ms": null}, "dig without dig_first_ms")
	_bad("burrowbelly", {"dig_every_ms": null}, "dig without dig_every_ms")
	_bad("burrowbelly", {"dig_first_ms": null, "dig_every_ms": null}, "dig_ms alone")
	_ok("burrowbelly", {"dig_first_ms": null, "dig_every_ms": null, "dig_ms": null}, "no dig")
	_ok("scamp", {"dig_first_ms": 1000, "dig_every_ms": 3000, "dig_ms": 1000}, "a walker that digs")
	_bad("flitter", {"dig_first_ms": 1000, "dig_every_ms": 3000, "dig_ms": 1000}, "a flyer that digs")


func test_unknown_creature_keys_are_still_refused() -> void:
	_bad("mossbud", {"regrow_at": 20}, "a save key in the stat file")
	_bad("sleepyhead", {"napped": false}, "napped in the stat file")


# Regions 7 and 8 (docs/ARCHITECTURE.md 14.4)

func test_the_late_creatures_load_with_their_numbers_rules_6_1_and_6_3() -> void:
	var cat: Catalog = Cx.catalog()
	assert_not_null(cat, "the test catalog loads")
	if cat == null:
		return
	var roller: EnemyType = cat.enemy(&"snowroller")
	assert_eq([roller.health, roller.speed, roller.bounty, roller.grow_pct, roller.grow_cap_pct], [40, 100, 8, 10, 300], "Snowroller")
	var yawner: EnemyType = cat.enemy(&"yawner")
	assert_eq([yawner.health, yawner.armor, yawner.yawn_ms, yawner.yawn_reach, yawner.doze_ms], [110, 2, 4000, 150, 2000], "Yawner")
	var blinker: EnemyType = cat.enemy(&"blinker")
	assert_eq([blinker.health, blinker.blink_ms, blinker.blink_tiles], [60, 3000, 2], "Blinker")
	assert_eq(cat.enemy(&"hootling").wake_reach, 150, "Hootling")
	var snore: EnemyType = cat.enemy(&"snowsnore")
	assert_eq([snore.grow_pct, snore.grow_cap_pct, snore.yawn_ms, snore.yawn_reach, snore.doze_ms], [2, 150, 6000, 200, 3000], "Snowsnore")
	var toad: EnemyType = cat.enemy(&"glimmertoad")
	assert_eq([toad.blink_ms, toad.blink_tiles, toad.wake_reach], [6000, 3, 200], "Glimmertoad")
	assert_eq(toad.release, {"at_pct": 50, "enemy": &"flitter", "count": 6, "gap_ms": 300}, "and its Flitters")
	var scamp: EnemyType = cat.enemy(&"scamp")
	assert_eq([scamp.grow_pct, scamp.grow_cap_pct, scamp.yawn_ms, scamp.yawn_reach, scamp.doze_ms, scamp.blink_ms, scamp.blink_tiles, scamp.wake_reach],
		[0, 0, 0, 0, 0, 0, 0, 0], "an older creature holds none of them")


func test_grow_and_its_limits() -> void:
	_ok("snowroller", {"grow_pct": 1, "grow_cap_pct": 101}, "the lowest growth")
	_ok("snowroller", {"grow_pct": 100, "grow_cap_pct": 1000}, "the highest growth")
	_bad("snowroller", {"grow_pct": 0}, "grow_pct 0")
	_bad("snowroller", {"grow_pct": 101}, "grow_pct 101")
	_bad("snowroller", {"grow_cap_pct": 100}, "a cap of 100")
	_bad("snowroller", {"grow_cap_pct": 1001}, "a cap of 1,001")
	_bad("snowroller", {"grow_pct": 2.5}, "a grow_pct that is not whole")
	_bad("snowroller", {"grow_cap_pct": null}, "grow_pct alone")
	_bad("snowroller", {"grow_pct": null}, "grow_cap_pct alone")
	_ok("snowroller", {"grow_pct": null, "grow_cap_pct": null}, "neither")
	_bad("flitter", {"grow_pct": 10, "grow_cap_pct": 300}, "a flyer that grows")


func test_yawn_and_its_limits() -> void:
	_ok("yawner", {"yawn_ms": 50, "yawn_reach": 1, "doze_ms": 50}, "the lowest yawn")
	_ok("yawner", {"yawn_ms": 600000, "yawn_reach": 1000, "doze_ms": 60000}, "the highest yawn")
	_bad("yawner", {"yawn_ms": 0}, "yawn_ms 0")
	_bad("yawner", {"yawn_ms": 600050}, "yawn_ms 600,050")
	_bad("yawner", {"yawn_ms": 4010}, "yawn_ms off the tick")
	_bad("yawner", {"yawn_reach": 0}, "yawn_reach 0")
	_bad("yawner", {"yawn_reach": 1001}, "yawn_reach 1,001")
	_bad("yawner", {"doze_ms": 0}, "doze_ms 0")
	_bad("yawner", {"doze_ms": 60050}, "doze_ms 60,050")
	_bad("yawner", {"doze_ms": 2010}, "doze_ms off the tick")
	for key: String in ["yawn_ms", "yawn_reach", "doze_ms"]:
		_bad("yawner", {key: null}, "a yawn without %s" % key)
	_ok("yawner", {"yawn_ms": null, "yawn_reach": null, "doze_ms": null}, "no yawn")
	_ok("flitter", {"yawn_ms": 4000, "yawn_reach": 150, "doze_ms": 2000}, "a flyer that yawns")


func test_blink_and_its_limits() -> void:
	_ok("blinker", {"blink_ms": 50, "blink_tiles": 1}, "the lowest blink")
	_ok("blinker", {"blink_ms": 600000, "blink_tiles": 10}, "the highest blink")
	_bad("blinker", {"blink_ms": 0}, "blink_ms 0")
	_bad("blinker", {"blink_ms": 600050}, "blink_ms 600,050")
	_bad("blinker", {"blink_ms": 3010}, "blink_ms off the tick")
	_bad("blinker", {"blink_tiles": 0}, "blink_tiles 0")
	_bad("blinker", {"blink_tiles": 11}, "blink_tiles 11")
	_bad("blinker", {"blink_tiles": null}, "blink_ms alone")
	_bad("blinker", {"blink_ms": null}, "blink_tiles alone")
	_ok("blinker", {"blink_ms": null, "blink_tiles": null}, "no blink")
	_bad("flitter", {"blink_ms": 3000, "blink_tiles": 2}, "a flyer that blinks")


func test_wake_and_its_limits() -> void:
	_ok("hootling", {"wake_reach": 1}, "the lowest reach")
	_ok("hootling", {"wake_reach": 1000}, "the highest reach")
	_bad("hootling", {"wake_reach": 0}, "reach 0")
	_bad("hootling", {"wake_reach": 1001}, "reach 1,001")
	_bad("hootling", {"wake_reach": "150"}, "reach as text")
	_ok("dusk_moth", {"wake_reach": 150}, "a flyer that wakes others")
	_bad("grumblesack", {"summon": {"enemy": "hootling", "count": 2, "every_ms": 6000, "gap_ms": 300}}, "a summoned waker")
	_ok("glimmertoad", {"release": {"at_pct": 50, "enemy": "hootling", "count": 2, "gap_ms": 300}}, "a released waker")


func test_a_creature_that_naps_cannot_heal_or_dig_dm_2026_10_27() -> void:
	_bad("mender", {"nap_ms": 2000}, "a Mender that naps")
	_bad("sleepyhead", {"heal": 8, "heal_reach": 150, "heal_ms": 2000}, "a Sleepyhead that heals")
	_bad("burrowbelly", {"nap_ms": 3000}, "a Burrowbelly that naps")
	_bad("old_hayrick", {"dig_first_ms": 6000, "dig_every_ms": 8000, "dig_ms": 2000}, "an Old Hayrick that digs")
	_bad("old_hayrick", {"dig_ms": 2000}, "a nap with a stray dig field")
	_ok("sleepyhead", {"regrow": 4, "regrow_ms": 1000}, "a napper may regrow")
	_ok("grumblesack", {"nap_ms": 2000}, "or summon")
	_ok("gatecrasher", {"nap_ms": 2000}, "or break gates")
	_ok("yawner", {"nap_ms": 2000}, "or yawn")
	_ok("blinker", {"nap_ms": 2000, "grow_pct": 10, "grow_cap_pct": 300}, "or blink and grow")
	_ok("hootling", {"nap_ms": 2000}, "or wake others")
