# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RunCards
extends RefCounted
## Checks data/cards/cards.json (docs/ARCHITECTURE.md 2.11). Internal to src/run/:
## RunData calls it. A card is read into a plain Dictionary:
## {"id": StringName, "kind": StringName, "tower": StringName (&"" for none), "name": String,
## "text": String, "once": bool, "unlock": Dictionary ({} or {"counter": String, "at": int}),
## "effects": Array[Dictionary], "tier": int}. A card's tier is its tower's tier, 0 without a
## tower (RULES 14.9).

const CARDS_MAX: int = 256
const KINDS: PackedStringArray = ["tower", "perk", "gate", "economy", "risk"]
## The five progress counters (RULES 14.6) and the two worked out from level records.
const COUNTERS: PackedStringArray = [
	"best_run_wave", "runs_won", "runs_won_normal", "dailies_finished", "risky_wins",
	"stars", "twists_cleared",
]
const UNLOCK_AT_MAX: int = 1000000
const PERK_EFFECTS: PackedStringArray = ["tower_add", "tower_pct", "tower_hits_air"]
const ECONOMY_EFFECTS: PackedStringArray = [
	"add_gold", "add_lives", "bounty_pct", "clear_bonus_pct", "refund_pct", "cost_add", "interest",
]
## A risk card's group always comes from entrance A, which every map has.
const RISK_ENTRANCE: int = 1


## start_towers: run.json's towers, or [] when run.json is unusable (the tower card
## coverage rule is then skipped). tower_tiers and creature_tiers: StringName to tier for
## what run.json's tiers list; anything not in them is tier 0.
static func read(data: Variant, catalog: Catalog, start_towers: Array[StringName], problems: PackedStringArray, tower_tiers: Dictionary = {}, creature_tiers: Dictionary = {}) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var chk: DataCheck = DataCheck.new("cards.json")
	if chk.object(data, "", ["format", "cards"]):
		var top: Dictionary = data
		chk.integer(top, "format", "", 1, 1)
		var list: Array = chk.array(top, "cards", "", 1, CARDS_MAX)
		var seen: Array[StringName] = []
		for i: int in list.size():
			var card: Dictionary = _read_card(list[i], "cards[%d]" % i, catalog, tower_tiers, creature_tiers, chk)
			if card.is_empty():
				continue
			if seen.has(card["id"]):
				chk.fail("cards[%d].id" % i, "repeats %s" % card["id"])
				continue
			seen.append(card["id"])
			cards.append(card)
		if not start_towers.is_empty():
			_check_tower_cards(cards, catalog, start_towers, chk)
	problems.append_array(chk.problems)
	return cards


static func _read_card(raw: Variant, path: String, catalog: Catalog, tower_tiers: Dictionary, creature_tiers: Dictionary, chk: DataCheck) -> Dictionary:
	var kind: String = ""
	if typeof(raw) == TYPE_DICTIONARY and DataCheck.is_string((raw as Dictionary).get("kind", null)):
		kind = String((raw as Dictionary)["kind"])
	var required: PackedStringArray = ["id", "kind", "name", "text", "once", "unlock", "effects"]
	if kind == "tower" or kind == "perk":
		required.append("tower")
	if not chk.object(raw, path, required):
		return {}
	var item: Dictionary = raw
	var id: StringName = chk.ident(item, "id", path)
	if not KINDS.has(kind):
		chk.fail(DataCheck.join(path, "kind"), "must be tower, perk, gate, economy or risk")
		return {}
	var tower: StringName = &""
	if item.has("tower"):
		tower = chk.ident(item, "tower", path)
		if tower != &"" and not catalog.has_tower(tower):
			chk.fail(DataCheck.join(path, "tower"), "names no tower")
			tower = &""
	var card: Dictionary = {
		"id": id, "kind": StringName(kind), "tower": tower,
		"name": chk.text(item, "name", path, 24), "text": chk.text(item, "text", path, 80),
		"once": chk.boolean(item, "once", path),
		"unlock": _read_unlock(item.get("unlock", null), DataCheck.join(path, "unlock"), chk),
		"effects": _read_effects(item.get("effects", null), kind, tower, DataCheck.join(path, "effects"), catalog, chk),
	}
	if id == &"":
		return {}
	var tier: int = int(tower_tiers.get(tower, 0))
	card["tier"] = tier
	_check_creature_tiers(card["effects"], tier, creature_tiers, DataCheck.join(path, "effects"), chk)
	return card


## A card never names a creature of a higher tier than its own, so no tier leaks in
## through a risk card (14.8).
static func _check_creature_tiers(effects: Array[Dictionary], tier: int, creature_tiers: Dictionary, path: String, chk: DataCheck) -> void:
	for i: int in effects.size():
		var named: StringName = StringName(String(effects[i].get("enemy", "")))
		if named != &"" and int(creature_tiers.get(named, 0)) > tier:
			chk.fail("%s[%d].enemy" % [path, i], "%s is of a higher tier than the card" % named)


static func _read_unlock(raw: Variant, path: String, chk: DataCheck) -> Dictionary:
	if typeof(raw) == TYPE_DICTIONARY and (raw as Dictionary).is_empty():
		return {}
	if not chk.object(raw, path, ["counter", "at"]):
		return {}
	var item: Dictionary = raw
	var counter: String = ""
	var counter_value: Variant = item.get("counter", null)
	if not DataCheck.is_string(counter_value) or not COUNTERS.has(String(counter_value)):
		chk.fail(DataCheck.join(path, "counter"), "must be a known counter")
	else:
		counter = String(counter_value)
	var at: int = chk.integer(item, "at", path, 1, UNLOCK_AT_MAX, 1, 1)
	if counter.is_empty():
		return {}
	return {"counter": counter, "at": at}


## The effects pass Modifiers.check for their use, then the rules of the card's kind.
static func _read_effects(raw: Variant, kind: String, tower: StringName, path: String, catalog: Catalog, chk: DataCheck) -> Array[Dictionary]:
	var none: Array[Dictionary] = []
	var found: PackedStringArray = Modifiers.check(raw, catalog, &"risk" if kind == "risk" else &"card")
	for line: String in found:
		chk.fail(path, line)
	if not found.is_empty():
		return none
	var effects: Array[Dictionary] = Modifiers.normalize_all(raw)
	var types: Array[String] = []
	for effect: Dictionary in effects:
		types.append(String(effect["type"]))
	match kind:
		"tower":
			if effects.size() != 1 or types[0] != "add_tower" or StringName(String(effects[0]["tower"])) != tower:
				chk.fail(path, "a tower card holds exactly one add_tower of its tower")
		"perk":
			if effects.size() < 1 or effects.size() > 3:
				chk.fail(path, "a perk holds 1 to 3 effects")
			for i: int in effects.size():
				_check_perk_effect(effects[i], tower, "%s[%d]" % [path, i], catalog, chk)
		"gate":
			var gates: int = types.count("add_gates")
			var stays: int = types.count("gates_stay")
			if gates != 1 or stays > 1 or types.size() != gates + stays:
				chk.fail(path, "a gate card holds one add_gates and at most one gates_stay")
		"economy":
			if effects.size() < 1 or effects.size() > 3:
				chk.fail(path, "an economy card holds 1 to 3 effects")
			for i: int in types.size():
				if not ECONOMY_EFFECTS.has(types[i]):
					chk.fail("%s[%d]" % [path, i], "%s is not an economy effect" % types[i])
		"risk":
			if types.count("reward_gold") != 1:
				chk.fail(path, "a risk card holds exactly one reward_gold")
			if effects.size() < 2 or effects.size() > 4:
				chk.fail(path, "a risk card holds 1 to 3 effects besides its reward")
			for i: int in effects.size():
				if types[i] == "add_group" and int(effects[i]["entrance"]) != RISK_ENTRANCE:
					chk.fail("%s[%d].entrance" % [path, i], "must be %d" % RISK_ENTRANCE)
	return effects


## A perk changes its own tower, and only a stat that tower has.
static func _check_perk_effect(effect: Dictionary, tower: StringName, path: String, catalog: Catalog, chk: DataCheck) -> void:
	var type: String = String(effect["type"])
	if not PERK_EFFECTS.has(type):
		chk.fail(path, "%s is not a perk effect" % type)
		return
	if StringName(String(effect["tower"])) != tower:
		chk.fail(DataCheck.join(path, "tower"), "must be the card's own tower")
		return
	var tower_type: TowerType = catalog.tower(tower)
	if tower_type == null:
		return
	if type == "tower_hits_air":
		if tower_type.kind != &"attack" and tower_type.kind != &"slow":
			chk.fail(path, "only an attacking tower or a Bell can be made to hit flyers")
	elif not has_stat(tower_type, String(effect["stat"])):
		chk.fail(DataCheck.join(path, "stat"), "%s has no %s" % [tower, effect["stat"]])


## True when the tower's kind has the stat (2.11): reach for any tower; damage and reload_ms
## for an attacking tower; splash for an attacking tower without pulse, line or lure_ms and
## targets for one without pulse or line (14.8); slow_pct for a Bell or an attacking tower with a slow on some tier or path;
## boost_pct and boost_damage for a Bakery.
static func has_stat(tower: TowerType, stat: String) -> bool:
	match stat:
		"reach":
			return true
		"damage", "reload_ms":
			return tower.kind == &"attack"
		"splash":
			return tower.kind == &"attack" and not _has_block(tower, false)
		"targets":
			return tower.kind == &"attack" and not _has_block(tower, true)
		"slow_pct":
			if tower.kind == &"slow":
				return true
			if tower.kind != &"attack":
				return false
			for tier: int in [1, 2]:
				if tower.stats(tier, -1).slow_ms > 0:
					return true
			for spec: int in [0, 1]:
				if tower.stats(3, spec).slow_ms > 0:
					return true
			return false
		"boost_pct", "boost_damage":
			return tower.kind == &"boost"
	return false


## True when some stat block of the tower has `pulse` or `line` (14.4), or, with
## `area_only` false, also `lure_ms` (a lure tower has no splash).
static func _has_block(tower: TowerType, area_only: bool) -> bool:
	var blocks: Array[TowerStats] = []
	for tier: int in [1, 2]:
		blocks.append(tower.stats(tier, -1))
	for spec: int in [0, 1]:
		blocks.append(tower.stats(3, spec))
	for block: TowerStats in blocks:
		if block == null:
			continue
		if is_area_block(block):
			return true
		if not area_only:
			var lure: Variant = block.get(&"lure_ms")
			if typeof(lure) == TYPE_INT and lure > 0:
				return true
	return false


## True when a stat block has `pulse` true or `line` above 0. A block without those fields (the
## stats before regions 5 to 8) has neither, so this reads them by name and never fails on them.
static func is_area_block(block: Object) -> bool:
	var pulse: Variant = block.get(&"pulse")
	var line: Variant = block.get(&"line")
	return (typeof(pulse) == TYPE_BOOL and pulse) or (typeof(line) == TYPE_INT and line > 0)


## Every tower not in the run's start has exactly one tower card, and no start tower has.
static func _check_tower_cards(cards: Array[Dictionary], catalog: Catalog, start_towers: Array[StringName], chk: DataCheck) -> void:
	var counts: Dictionary[StringName, int] = {}
	for card: Dictionary in cards:
		if card["kind"] == &"tower":
			counts[card["tower"]] = counts.get(card["tower"], 0) + 1
	for id: StringName in catalog.tower_ids():
		var wanted: int = 0 if start_towers.has(id) else 1
		var have: int = counts.get(id, 0)
		if have != wanted:
			chk.fail("cards", "%s needs %d tower card, it has %d" % [id, wanted, have])
