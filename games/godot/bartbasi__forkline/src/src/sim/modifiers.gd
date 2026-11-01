# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Modifiers
extends RefCounted
## Twist, card and risk effects (docs/ARCHITECTURE.md 2.8). check(), normalize_all() and
## group_count() are public to other areas (3.1). Battle applies the effects; every other
## helper below is internal to src/sim/.

const USES: PackedStringArray = ["twist", "card", "risk"]
const TOWER_ADD_STATS: PackedStringArray = [
	"damage", "reload_ms", "reach", "splash", "slow_pct", "targets", "boost_pct", "boost_damage",
]
const TOWER_PCT_STATS: PackedStringArray = ["damage", "reload_ms"]
const MAX_FIXED_CELLS: int = 8
## Card effects that change the state once and are not kept (2.8).
const INSTANT: PackedStringArray = ["add_gates", "add_gold", "add_lives"]
const MAX_KEPT: int = 64                               # kept card effects in one battle (5.6)
const MAX_WAITING: int = 8                             # effects of the one waiting risk card (5.6)
const MAX_TWIST: int = 8                               # a Twist's effects (a level file allows 2)
## group_count() never returns more, so stacked count_pct effects (up to 1,000 percent
## each) never overflow an int. Battle refuses a count far below this (5.6).
const COUNT_CEILING: int = 1000000000
## speed_pct() never returns more, so the move step (speed times 10 times this times 100)
## stays far inside an int. Battle refuses far less (5.6).
const PCT_CEILING: int = 1000000000
## scale_all() and the tower_pct steps of tower_stats() never return more, so each
## step's product (at most this times 1,000) stays inside an int. Battle refuses max
## health, gold gains and tower stats far below this (5.6).
const VALUE_CEILING: int = 1000000000000

## type: [uses, {field: rule}]. Rules: pct 1 to 1,000; refund 1 to 100 (4.6); count 1 to 200; gates 0 to
## max_gates; lives 1 to 1,000; cells; tower and enemy ids; tier 1 or 2; bool;
## time (a multiple of 50 up to 600,000); every (50 to 600,000); entrance 1 to 4;
## gain 0 to 1,000 (gold and lives a card or risk card gives, never negative);
## number -1,000 to 1,000; add_stat and pct_stat (stat names).
const TYPES: Dictionary = {
	"start_gold_pct": [["twist"], {"pct": "pct"}],
	"set_lives": [["twist"], {"lives": "lives"}],
	"set_gates": [["twist"], {"count": "gates"}],
	"fixed_gates": [["twist"], {"cells": "cells"}],
	"ban_tower": [["twist"], {"tower": "tower"}],
	"tier_cap": [["twist"], {"tier": "tier"}],
	"no_selling": [["twist"], {}],
	"count_pct": [["twist", "risk"], {"pct": "pct", "flyers": "bool", "last_wave": "bool"}],
	"health_pct": [["risk"], {"pct": "pct"}],
	"speed_pct": [["twist", "risk"], {"pct": "pct"}],
	"armor_add": [["twist"], {"amount": "number"}],
	"all_bubbles": [["twist"], {}],
	"break_ms": [["twist"], {"enemy": "enemy", "ms": "time"}],
	"gates_open": [["risk"], {}],
	"add_group": [["risk"], {"enemy": "enemy", "count": "count", "entrance": "entrance",
		"at_ms": "time", "every_ms": "every", "after_last": "bool"}],
	"reward_gold": [["risk"], {"amount": "gain"}],
	"add_tower": [["card"], {"tower": "tower"}],
	"tower_add": [["card"], {"tower": "tower", "stat": "add_stat", "amount": "number"}],
	"tower_pct": [["card"], {"tower": "tower", "stat": "pct_stat", "pct": "pct"}],
	"tower_hits_air": [["card"], {"tower": "tower"}],
	"bounty_pct": [["card"], {"pct": "pct"}],
	"clear_bonus_pct": [["card"], {"pct": "pct"}],
	"refund_pct": [["card"], {"pct": "refund"}],
	"cost_add": [["card"], {"build": "number", "upgrade": "number"}],
	"interest": [["card"], {"pct": "pct", "max": "gain"}],
	"gates_stay": [["card"], {}],
	"add_gates": [["card"], {"count": "count"}],
	"add_gold": [["card"], {"amount": "gain", "per_wave": "gain"}],
	"add_lives": [["card"], {"amount": "gain"}],
}


## Every problem in a list of effects for one use (&"twist", &"card" or &"risk").
static func check(effects: Variant, catalog: Catalog, use: StringName) -> PackedStringArray:
	var chk: DataCheck = DataCheck.new()
	if catalog == null or catalog.rules == null:
		chk.fail("effects", "needs a valid catalog")
		return chk.problems
	if not USES.has(String(use)):
		chk.fail("effects", "unknown use %s" % String(use).left(DataCheck.ID_MAX))
		return chk.problems
	var list: Array = chk.array_value(effects, "effects", 0, 64)
	for i: int in list.size():
		_check_one(list[i], "effects[%d]" % i, catalog, String(use), chk)
	return chk.problems


static func _check_one(data: Variant, path: String, catalog: Catalog, use: String, chk: DataCheck) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		chk.fail(path, "must be an object")
		return
	var effect: Dictionary = data
	var type_value: Variant = effect.get("type", null)
	if not DataCheck.is_string(type_value) or not TYPES.has(String(type_value)):
		chk.fail(DataCheck.join(path, "type"), "must be a known effect type")
		return
	var type: String = String(type_value)
	var spec: Array = TYPES[type]
	var uses: Array = spec[0]
	if not uses.has(use):
		chk.fail(DataCheck.join(path, "type"), "%s is not allowed for a %s" % [type, use])
	var fields: Dictionary = spec[1]
	var keys: PackedStringArray = ["type"]
	for key: String in fields.keys():
		keys.append(key)
	if not chk.object(effect, path, keys):
		return
	for key: String in fields.keys():
		if not effect.has(key):
			continue
		var field_path: String = DataCheck.join(path, key)
		var value: Variant = effect[key]
		match String(fields[key]):
			"pct":
				chk.whole(value, field_path, 1, 1000)
			"refund":
				chk.whole(value, field_path, 1, 100)       # 4.6: selling never makes a profit
			"count":
				chk.whole(value, field_path, 1, 200)
			"gates":
				chk.whole(value, field_path, 0, catalog.rules.max_gates)
			"lives":
				chk.whole(value, field_path, 1, 1000)
			"tier":
				chk.whole(value, field_path, 1, 2)
			"entrance":
				chk.whole(value, field_path, 1, Sim.MAX_ENTRANCES)
			"time":
				chk.whole(value, field_path, 0 if key == "at_ms" else 50, 600000, 50)
			"every":
				chk.whole(value, field_path, 50, 600000, 50)
			"gain":
				chk.whole(value, field_path, 0, 1000)      # 2.8: a negative gain is refused, not counted as 0
			"number":
				chk.whole(value, field_path, -1000, 1000)
			"bool":
				if typeof(value) != TYPE_BOOL:
					chk.fail(field_path, "must be true or false")
			"tower":
				if chk.ident_value(value, field_path) != &"" and not catalog.has_tower(StringName(String(value))):
					chk.fail(field_path, "names no tower")
			"enemy":
				if chk.ident_value(value, field_path) != &"" and not catalog.has_enemy(StringName(String(value))):
					chk.fail(field_path, "names no creature")
			"add_stat":
				if not DataCheck.is_string(value) or not TOWER_ADD_STATS.has(String(value)):
					chk.fail(field_path, "must be a stat a card can add to")
			"pct_stat":
				if not DataCheck.is_string(value) or not TOWER_PCT_STATS.has(String(value)):
					chk.fail(field_path, "must be damage or reload_ms")
			"cells":
				var cells: Array = chk.array_value(value, field_path, 1, MAX_FIXED_CELLS)
				var seen: Array[Vector2i] = []
				for k: int in cells.size():
					var cell: Vector2i = chk.cell(cells[k], "%s[%d]" % [field_path, k], Sim.MAP_ROWS_MAX)
					if seen.has(cell):
						chk.fail("%s[%d]" % [field_path, k], "repeats a cell")
					seen.append(cell)
	# 2.8: a Twist changes how fast a gate breaker breaks; it never makes a new one.
	if type == "break_ms" and DataCheck.is_id(effect.get("enemy", null)):
		var breaker: EnemyType = catalog.enemy(StringName(String(effect["enemy"])))
		if breaker != null and breaker.break_ms <= 0:
			chk.fail(DataCheck.join(path, "enemy"), "must already break gates")
	var last_wave: Variant = effect.get("last_wave", false)
	if type == "count_pct" and use != "twist" and typeof(last_wave) == TYPE_BOOL and last_wave:
		chk.fail(DataCheck.join(path, "last_wave"), "is for Twists only")


## Checked effects as plain data: ints, bools, Strings and [column, row] cells.
static func normalize_all(effects: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for data: Variant in effects:
		var effect: Dictionary = data
		var clean: Dictionary = {}
		for key: String in effect.keys():
			clean[key] = _plain(effect[key])
		out.append(clean)
	return out


static func _plain(value: Variant) -> Variant:
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return int(value)
		TYPE_STRING_NAME:
			return String(value)
		TYPE_ARRAY:
			var out: Array = []
			for item: Variant in value:
				out.append(_plain(item))
			return out
	return value


## The cells of every fixed_gates effect, in cell order, without repeats.
static func fixed_cells(effects: Array[Dictionary]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for effect: Dictionary in effects:
		if effect.get("type", "") != "fixed_gates":
			continue
		for pair: Variant in effect["cells"]:
			var cell: Vector2i = Vector2i(int(pair[0]), int(pair[1]))
			if not cells.has(cell):
				cells.append(cell)
	cells.sort_custom(Sim.cell_before)
	return cells


## A group's count with every count_pct effect applied, rounded up (2.8), at most
## COUNT_CEILING. The clamp comes after every step, so no product can overflow.
static func group_count(effects: Array[Dictionary], count: int, flying: bool, last_wave: bool) -> int:
	var result: int = mini(count, COUNT_CEILING)
	for effect: Dictionary in effects:
		if effect.get("type", "") != "count_pct":
			continue
		if effect["flyers"] and not flying:
			continue
		if effect["last_wave"] and not last_wave:
			continue
		result = mini(Sim.pct_up(result, effect["pct"]), COUNT_CEILING)
	return result


## A tower's stat block with every card effect for that tower (2.8, RULES 8.7): the
## data, then every tower_add, then every tower_pct, then tower_hits_air and cost_add.
## first_step: the price is a build price, else an upgrade price. No stat goes below
## what the data allows (2.6), so no card can make a stat the sim cannot use; a stat
## block with no slow gets no slow from a card, nor splash or more targets where 14.4
## allows none. Each tower_pct step is clamped to
## VALUE_CEILING, so no product can overflow.
static func tower_stats(base: TowerStats, tower: StringName, effects: Array[Dictionary], first_step: bool) -> TowerStats:
	var out: TowerStats = base.copy()
	var id: String = String(tower)
	for effect: Dictionary in effects:
		if effect["type"] != "tower_add" or effect["tower"] != id:
			continue
		var amount: int = effect["amount"]
		match String(effect["stat"]):
			"damage":
				out.damage += amount
			"reload_ms":
				out.reload_ms += amount
			"reach":
				out.reach += amount
			"splash":
				out.splash += amount
			"slow_pct":
				out.slow_pct += amount
			"targets":
				out.targets += amount
			"boost_pct":
				out.boost_pct += amount
			"boost_damage":
				out.boost_damage += amount
	for effect: Dictionary in effects:
		if effect["type"] != "tower_pct" or effect["tower"] != id:
			continue
		if effect["stat"] == "damage":
			out.damage = mini(Sim.pct_half_up(clampi(out.damage, 0, VALUE_CEILING), effect["pct"]), VALUE_CEILING)
		else:
			out.reload_ms = mini(Sim.pct_half_up(clampi(out.reload_ms, 0, VALUE_CEILING), effect["pct"]), VALUE_CEILING)
	for effect: Dictionary in effects:
		if effect["type"] == "tower_hits_air" and effect["tower"] == id:
			out.hits_air = true
		elif effect["type"] == "cost_add":
			out.cost += int(effect["build"]) if first_step else int(effect["upgrade"])
	out.cost = maxi(out.cost, 10)                      # 2.8: never below 10
	out.reach = maxi(out.reach, 1)
	out.reload_ms = maxi(out.reload_ms, Sim.MS_PER_TICK)
	out.damage = maxi(out.damage, 1 if base.damage > 0 else 0)
	out.splash = maxi(out.splash, 0)
	out.targets = maxi(out.targets, 1)
	out.slow_pct = clampi(out.slow_pct, 1, 90) if base.slow_ms > 0 else 0
	out.boost_pct = maxi(out.boost_pct, 0)
	out.boost_damage = maxi(out.boost_damage, 0)
	# 14.4: pulses, lines and lures have no splash, and pulses and lines one target, so no
	# card gives them a number the sim never uses.
	if base.pulse or base.line > 0 or base.lure_ms > 0:
		out.splash = 0
	if base.pulse or base.line > 0:
		out.targets = 1
	return out


## The product of every speed_pct effect, as one percent (2.8). Each step truncates,
## then is clamped to PCT_CEILING, so no product can overflow.
static func speed_pct(effects: Array[Dictionary]) -> int:
	var pct: int = 100
	for effect: Dictionary in effects:
		if effect["type"] == "speed_pct":
			pct = mini(pct * int(effect["pct"]) / 100, PCT_CEILING)
	return maxi(pct, 1)


## value with every effect of this type applied in turn, each rounded half up (RULES 2),
## at most VALUE_CEILING. The clamp comes after every step, so no product can overflow.
static func scale_all(effects: Array[Dictionary], type: String, value: int) -> int:
	var out: int = mini(value, VALUE_CEILING)
	for effect: Dictionary in effects:
		if effect["type"] == type:
			out = mini(Sim.pct_half_up(out, effect["pct"]), VALUE_CEILING)
	return out


## The last effect of this type, or {} for none.
static func last_of(effects: Array[Dictionary], type: String) -> Dictionary:
	var found: Dictionary = {}
	for effect: Dictionary in effects:
		if effect["type"] == type:
			found = effect
	return found


static func has_type(effects: Array[Dictionary], type: String) -> bool:
	for effect: Dictionary in effects:
		if effect["type"] == type:
			return true
	return false
