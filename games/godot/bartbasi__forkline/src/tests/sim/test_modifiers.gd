# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Modifiers.check covers every effect type of docs/ARCHITECTURE.md 2.8 (RULES 13, 14.5,
## 14.6), for its uses, with exact fields and ranges.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

## One valid example of every type, with its uses.
const EXAMPLES: Array = [
	[["twist"], {"type": "start_gold_pct", "pct": 50}],
	[["twist"], {"type": "set_lives", "lives": 5}],
	[["twist"], {"type": "set_gates", "count": 0}],
	[["twist"], {"type": "fixed_gates", "cells": [[5, 5], [1, 3]]}],
	[["twist"], {"type": "ban_tower", "tower": "pumpkin_catapult"}],
	[["twist"], {"type": "tier_cap", "tier": 2}],
	[["twist"], {"type": "no_selling"}],
	[["twist", "risk"], {"type": "count_pct", "pct": 150, "flyers": false, "last_wave": false}],
	[["risk"], {"type": "health_pct", "pct": 150}],
	[["twist", "risk"], {"type": "speed_pct", "pct": 120}],
	[["twist"], {"type": "armor_add", "amount": 2}],
	[["twist"], {"type": "all_bubbles"}],
	[["twist"], {"type": "break_ms", "enemy": "gatecrasher", "ms": 2000}],
	[["risk"], {"type": "gates_open"}],
	[["risk"], {"type": "add_group", "enemy": "pip", "count": 24, "entrance": 1, "at_ms": 1000, "every_ms": 300, "after_last": false}],
	[["risk"], {"type": "reward_gold", "amount": 100}],
	[["card"], {"type": "add_tower", "tower": "bakery"}],
	[["card"], {"type": "tower_add", "tower": "sling_post", "stat": "damage", "amount": -2}],
	[["card"], {"type": "tower_pct", "tower": "longbow_loft", "stat": "reload_ms", "pct": 80}],
	[["card"], {"type": "tower_hits_air", "tower": "lullaby_bell"}],
	[["card"], {"type": "bounty_pct", "pct": 120}],
	[["card"], {"type": "clear_bonus_pct", "pct": 150}],
	[["card"], {"type": "refund_pct", "pct": 90}],
	[["card"], {"type": "cost_add", "build": 20, "upgrade": -20}],
	[["card"], {"type": "interest", "pct": 10, "max": 50}],
	[["card"], {"type": "gates_stay"}],
	[["card"], {"type": "add_gates", "count": 2}],
	[["card"], {"type": "add_gold", "amount": 100, "per_wave": 10}],
	[["card"], {"type": "add_lives", "amount": 5}],
]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func test_every_type_of_2_8_is_known_and_valid_for_its_uses() -> void:
	assert_eq(EXAMPLES.size(), Modifiers.TYPES.size(), "one example per type")
	for example: Array in EXAMPLES:
		var effect: Dictionary = example[1]
		for use: String in ["twist", "card", "risk"]:
			var problems: PackedStringArray = Modifiers.check([effect], catalog, StringName(use))
			if (example[0] as Array).has(use):
				assert_eq(problems.size(), 0, "%s as %s: %s" % [effect["type"], use, "; ".join(problems)])
			else:
				assert_false(problems.is_empty(), "%s refused as %s" % [effect["type"], use])


func test_fields_must_be_exact() -> void:
	for example: Array in EXAMPLES:
		var effect: Dictionary = (example[1] as Dictionary).duplicate(true)
		var use: StringName = StringName(example[0][0])
		effect["extra"] = 1
		assert_false(Modifiers.check([effect], catalog, use).is_empty(), "%s with an extra field" % effect["type"])
		effect.erase("extra")
		for key: String in effect.keys():
			if key == "type":
				continue
			var missing: Dictionary = effect.duplicate(true)
			missing.erase(key)
			assert_false(Modifiers.check([missing], catalog, use).is_empty(), "%s without %s" % [effect["type"], key])


func test_ranges_ids_and_types_are_checked() -> void:
	var bad: Array = [
		["twist", {"type": "start_gold_pct", "pct": 0}],
		["twist", {"type": "start_gold_pct", "pct": 1001}],
		["twist", {"type": "start_gold_pct", "pct": 50.5}],
		["twist", {"type": "set_lives", "lives": 0}],
		["twist", {"type": "set_gates", "count": 4}],
		["twist", {"type": "fixed_gates", "cells": []}],
		["twist", {"type": "fixed_gates", "cells": [[7, 0]]}],
		["twist", {"type": "fixed_gates", "cells": [[1, 3], [1, 3]]}],
		["twist", {"type": "ban_tower", "tower": "dragon"}],
		["twist", {"type": "tier_cap", "tier": 3}],
		["twist", {"type": "count_pct", "pct": 200, "flyers": 1, "last_wave": false}],
		["risk", {"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
		["twist", {"type": "armor_add", "amount": 1001}],
		["twist", {"type": "break_ms", "enemy": "gatecrasher", "ms": 2010}],
		["twist", {"type": "break_ms", "enemy": "ghost", "ms": 2000}],
		["twist", {"type": "break_ms", "enemy": "scamp", "ms": 2000}],
		["twist", {"type": "break_ms", "enemy": "dusk_moth", "ms": 2000}],
		["risk", {"type": "add_group", "enemy": "pip", "count": 201, "entrance": 1, "at_ms": 0, "every_ms": 300, "after_last": false}],
		["risk", {"type": "add_group", "enemy": "pip", "count": 2, "entrance": 5, "at_ms": 0, "every_ms": 300, "after_last": false}],
		["risk", {"type": "add_group", "enemy": "pip", "count": 2, "entrance": 1, "at_ms": 0, "every_ms": 0, "after_last": false}],
		["card", {"type": "tower_add", "tower": "sling_post", "stat": "cost", "amount": 2}],
		["card", {"type": "tower_pct", "tower": "sling_post", "stat": "reach", "pct": 80}],
		["card", {"type": "add_gold", "amount": "100", "per_wave": 10}],
		["card", {"type": "refund_pct", "pct": 0}],
		["card", {"type": "refund_pct", "pct": 101}],
		["card", {"type": "refund_pct", "pct": 1000}],
		["card", {"type": "nothing"}],
		["card", {"pct": 5}],
	]
	for item: Array in bad:
		assert_false(Modifiers.check([item[1]], catalog, StringName(item[0])).is_empty(), str(item[1]))


func test_gold_and_lives_gains_are_0_to_1000_contract_2_8() -> void:
	for item: Array in Fx.GAINS:
		for value: int in [0, 1, 1000]:
			assert_eq(Modifiers.check([Fx.gain_effect(item, value)], catalog, StringName(item[0])).size(), 0, "%s accepts %d" % [str(item[1]), value])
		for value: int in [-1, -1000, 1001]:
			assert_false(Modifiers.check([Fx.gain_effect(item, value)], catalog, StringName(item[0])).is_empty(), "%s refuses %d" % [str(item[1]), value])


func test_a_refund_card_never_pays_a_profit_rules_4_6() -> void:
	for pct: int in [1, 90, 100]:
		assert_eq(Modifiers.check([{"type": "refund_pct", "pct": pct}], catalog, &"card").size(), 0, "refund %d%%" % pct)
	assert_false(Modifiers.check([{"type": "refund_pct", "pct": 101}], catalog, &"card").is_empty(), "refund 101%")


func test_hostile_shapes_never_crash() -> void:
	for value: Variant in [null, 1, "x", {}, [1], [null], [[]], [{"type": 5}], [{"type": null}]]:
		assert_false(Modifiers.check(value, catalog, &"twist").is_empty(), str(value))
	assert_false(Modifiers.check([], catalog, &"nonsense").is_empty(), "unknown use")
	assert_false(Modifiers.check([], null, &"twist").is_empty(), "no catalog")
	assert_eq(Modifiers.check([], catalog, &"card").size(), 0, "an empty list is fine")
	var many: Array = []
	for i: int in 65:
		many.append({"type": "gates_stay"})
	assert_false(Modifiers.check(many, catalog, &"card").is_empty(), "at most 64 effects")
