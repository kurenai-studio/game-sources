# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Every save key of the expansion against tampered values in one sweep (docs/ARCHITECTURE.md
## 14.7): one mid-wave save with every new creature and boss beside the new towers, and every
## new key on every creature and tower, with values of every wrong type and size, missing,
## added where it does not belong, and put at the wrong level of the save. Each is refused,
## all or nothing, without a crash, except a missing optional key, which reads as 0.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

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
const CREATURES: Array = [
	"mossbud", "mistwisp", "gleamer", "sleepyhead", "burrowbelly", "old_hayrick",
	"snowroller", "yawner", "blinker", "hootling", "snowsnore", "glimmertoad", "scamp", "flitter",
]
## Keys one kind of creature must hold and every other kind must not (14.7).
const KIND_KEYS: Dictionary = {
	"regrow_at": [&"mossbud"], "napped": [&"sleepyhead", &"old_hayrick"], "nap_ticks": [&"sleepyhead", &"old_hayrick"],
	"dig_at": [&"burrowbelly"], "dig_ticks": [&"burrowbelly"], "yawn_at": [&"yawner", &"snowsnore"],
	"blink_at": [&"blinker", &"glimmertoad"],
}
## Keys every creature may hold (fright) or every flyer may hold (low), optional on load.
const OPTIONAL_KEYS: Array = ["fright_pct", "fright_ticks", "low_ticks"]

var catalog: Catalog = null
var hostile: Array = [
	null, -1, 1.5, 0.5, -0.5, "x", "1", "", true, false, [], {}, [1, 2, 3], {"a": 1}, [0], {"0": 0},
	1e18, -1e18, 1e300, INF, -INF, NAN, 2147483648, -2147483649, 9223372036854775807, -9223372036854775807,
	Vector2i(1, 1), &"tick",
]


func before_each() -> void:
	catalog = Cx.catalog()


## Mid-wave with one of each new creature and boss, a Scamp and a Flitter, beside the four
## new towers, a Sling Post and a Bell. Returns [data, the index of each type in data["enemies"]].
func _mid_wave() -> Array:
	# A wave holds at most 8 groups, so the creatures come in two waves, the second called early.
	var first: Array = []
	var second: Array = []
	for i: int in CREATURES.size():
		(first if i < 7 else second).append(Fx.group(CREATURES[i], 1))
	var b: Battle = Cx.battle(STRAIGHT, [{"strength": 1000, "groups": first}, {"strength": 1000, "groups": second}], {}, catalog)
	assert_not_null(b, "the level loads")
	for item: Array in [[Vector2i(2, 2), &"sling_post"], [Vector2i(4, 2), &"scarecrow"], [Vector2i(2, 4), &"moth_lantern"],
			[Vector2i(4, 4), &"bramble_cottage"], [Vector2i(2, 7), &"snow_fort"], [Vector2i(4, 7), &"lullaby_bell"]]:
		assert_not_null(Tx.build(b, item[0], item[1]), String(item[1]))
	b.start_next_wave()
	Fx.steps(b, 10)
	assert_eq(b.start_next_wave(), Battle.DONE, "an early call")
	Fx.steps(b, 30)
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	var at: Dictionary = {}
	for i: int in (data["enemies"] as Array).size():
		var type: StringName = StringName(String(data["enemies"][i]["type"]))
		if not at.has(type):
			at[type] = i
	assert_eq(at.size(), CREATURES.size(), "every creature is on the map: %s" % str(at.keys()))
	assert_not_null(Battle.from_data(data.duplicate(true), catalog), "the untouched save loads")
	return [data, at]


func _refused(data: Dictionary) -> bool:
	return Battle.from_data(data, catalog) == null


func _enemy_with(data: Dictionary, index: int, key: String, value: Variant, erase: bool = false) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var item: Dictionary = copy["enemies"][index]
	if erase:
		item.erase(key)
	else:
		item[key] = value
	return copy


func _tower_with(data: Dictionary, index: int, key: String, value: Variant, erase: bool = false) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var item: Dictionary = copy["towers"][index]
	if erase:
		item.erase(key)
	else:
		item[key] = value
	return copy


func test_every_kind_key_refuses_every_hostile_value_on_every_kind_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	for key: String in KIND_KEYS:
		var owners: Array = KIND_KEYS[key]
		for type: StringName in at:
			var index: int = at[type]
			var item: Dictionary = data["enemies"][index]
			assert_eq(item.has(key), owners.has(type), "%s written on %s" % [key, type])
			if owners.has(type):
				assert_true(_refused(_enemy_with(data, index, key, null, true)), "%s missing on %s" % [key, type])
				for bad: Variant in hostile:
					if key == "napped" and typeof(bad) == TYPE_BOOL:
						continue
					assert_true(_refused(_enemy_with(data, index, key, bad)), "%s = %s on %s" % [key, str(bad), type])
			else:
				var plausible: Variant = false if key == "napped" else (0 if key.ends_with("_ticks") else int(data["tick"]))
				assert_true(_refused(_enemy_with(data, index, key, plausible)), "%s on %s" % [key, type])


func test_every_optional_key_refuses_every_hostile_value_contract_14_7() -> void:
	var got: Array = _mid_wave()
	var data: Dictionary = got[0]
	var at: Dictionary = got[1]
	for type: StringName in at:
		var index: int = at[type]
		var item: Dictionary = data["enemies"][index]
		var flyer: bool = catalog.enemy(type).flying
		for key: String in OPTIONAL_KEYS:
			var may: bool = key != "low_ticks" or flyer
			assert_eq(item.has(key), may, "%s written on %s" % [key, type])
			if not may:
				assert_true(_refused(_enemy_with(data, index, key, 0)), "%s on the walker %s" % [key, type])
				continue
			# The two fright keys go together (both 0 or both above 0), so they go missing together.
			var gone: Dictionary = _enemy_with(data, index, key, null, true)
			if key.begins_with("fright"):
				(gone["enemies"][index] as Dictionary).erase("fright_pct")
				(gone["enemies"][index] as Dictionary).erase("fright_ticks")
			assert_not_null(Battle.from_data(gone, catalog), "%s missing on %s reads as 0" % [key, type])
			for bad: Variant in hostile:
				assert_true(_refused(_enemy_with(data, index, key, bad)), "%s = %s on %s" % [key, str(bad), type])


func test_doze_ticks_refuses_every_hostile_value_on_every_tower_contract_14_7() -> void:
	var data: Dictionary = _mid_wave()[0]
	var towers: Array = data["towers"]
	assert_eq(towers.size(), 6)
	for i: int in towers.size():
		assert_true((towers[i] as Dictionary).has("doze_ticks"), "always written")
		assert_not_null(Battle.from_data(_tower_with(data, i, "doze_ticks", null, true), catalog), "missing on tower %d reads as 0" % i)
		for bad: Variant in hostile:
			assert_true(_refused(_tower_with(data, i, "doze_ticks", bad)), "doze_ticks = %s on tower %d" % [str(bad), i])


func test_new_keys_at_the_wrong_level_of_the_save_are_refused_contract_14_7() -> void:
	var data: Dictionary = _mid_wave()[0]
	var scamp: int = 0
	for i: int in (data["enemies"] as Array).size():
		if data["enemies"][i]["type"] == "scamp":
			scamp = i
	assert_true(_refused(_enemy_with(data, scamp, "doze_ticks", 0)), "a tower's key on a creature")
	for key: String in OPTIONAL_KEYS + KIND_KEYS.keys():
		assert_true(_refused(_tower_with(data, 0, key, 0)), "%s on a tower" % key)
	for key: String in ["tier", "doze_ticks", "fright_pct", "to_node", "start_health", "out_of_reach", "hidden", "awake", "misty"]:
		var top: Dictionary = data.duplicate(true)
		top[key] = 0
		assert_true(_refused(top), "%s at the top of a battle save" % key)
	# What is never saved is refused on a creature too, so a save cannot set it (14.7).
	for key: String in ["to_node", "start_health", "out_of_reach", "hidden", "awake", "grow_cap"]:
		assert_true(_refused(_enemy_with(data, scamp, key, 0)), "%s on a creature" % key)


func test_a_new_key_in_a_release_is_refused_contract_14_7() -> void:
	var data: Dictionary = _mid_wave()[0]
	var entrance: Array = [3, 0]
	var release: Dictionary = {"enemy": "scamp", "wave": 1, "left": 1, "next": data["tick"], "gap": 1,
		"from": entrance, "to": entrance.duplicate(), "progress": Sim.UNIT}
	var good: Dictionary = data.duplicate(true)
	good["releases"] = [release]
	assert_not_null(Battle.from_data(good.duplicate(true), catalog), "a plain release loads")
	for key: String in OPTIONAL_KEYS + KIND_KEYS.keys():
		var bad: Dictionary = good.duplicate(true)
		bad["releases"][0][key] = 0
		assert_true(_refused(bad), "%s on a release" % key)
