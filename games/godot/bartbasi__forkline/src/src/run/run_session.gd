# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RunSession
extends RefCounted
## One roguelite run or daily around its Battle (docs/ARCHITECTURE.md 3.4, RULES 14 and 15).
## Pure: no clock, no files. The App passes the seed and the day key in. All chance comes
## from the generators of MapAssembler, in the order the contract lists, so the same seed,
## data and picks always give the same run.
##
## Owed drafts are worked out from the battle, so nothing extra is saved: the saved run is
## the seed, the day, the pool and the picks (5.5).

const FORMAT: int = 1
## One draft after each of waves 1 to 17 (RULES 14.1).
const DRAFTS: int = 17
const OFFER_COUNT: int = 3
const POOL_MAX: int = 256
const DAY_LENGTH: int = 10
## While the run has fewer towers than this, a draft's first card is a tower card (14.4).
const FREE_TOWER_LIMIT: int = 3
## Risk cards are offered only while fewer waves than this have started, so the boss
## wave (wave 18) is never changed, even when wave 17 was called early.
const RISK_CUTOFF: int = 17
const TAG_DRAFT: String = "draft"
const SAVE_KEYS: PackedStringArray = ["format", "seed", "day", "pool", "picks"]
## Saved by A12 builds. A save without it is a tier 0 run (14.7).
const SAVE_OPTIONAL: PackedStringArray = ["tier"]
## The card kinds in draft order (3.4).
const KINDS: Array[StringName] = [&"tower", &"perk", &"gate", &"economy", &"risk"]

var battle: Battle = null
var run_seed: int = 0
var daily: bool = false
var day: String = ""
var pool: Array[StringName] = []
var picks: Array[StringName] = []
## The run's content tier, 0 to the tier count of run.json. It is fixed at the start and saved (14.8).
var tier: int = 0

var _data: RunData = null
var _in_pool: Dictionary[StringName, bool] = {}


## A new run. day is "" for a normal run. A daily passes its day key, run_seed equal to
## RunSeeds.daily_seed(day), and relaxed false. Null when the seed is outside 0 to 2^32 - 1,
## a daily breaks any of that, the pool is not a list of 1 to 256 known cards with no
## repeats, holds a card above the tier, holds no economy card that can be taken again (so a
## draft is never empty), the tier is outside 0 to the tier count of run.json, or the map cannot
## be built. The map comes from the bosses, segments and packs of the tier and below (14.8).
static func start(seed_value: int, day_key: String, relaxed: bool, pool_ids: Array[StringName], data: RunData, catalog: Catalog, tier_value: int = 0) -> RunSession:
	if data == null or catalog == null:
		return null
	if tier_value < 0 or tier_value > data.tiers.size():
		return null
	if seed_value < 0 or seed_value > RunSeeds.SEED_MAX:
		return null
	if day_key != "":
		if not RunSeeds.is_day_key(day_key) or RunSeeds.daily_seed(day_key) != seed_value or relaxed:
			return null
	if not _pool_ok(pool_ids, data, tier_value):
		return null
	var level: LevelData = MapAssembler.assemble(seed_value, data, catalog, tier_value)
	if level == null:
		return null
	var no_twist: Array[Dictionary] = []
	var made: Battle = Battle.create(level, catalog, relaxed, no_twist)
	if made == null:
		return null
	var session: RunSession = new()
	session._set_up(made, seed_value, day_key, pool_ids, data)
	session.tier = tier_value
	return session


## Drafts owed: the cleared waves among waves 1 to 17, less the picks made (3.4).
func drafts_owed() -> int:
	return maxi(_cleared(battle) - picks.size(), 0)


## A card's data as RunData holds it (3.4); {} when the id is unknown.
func card(id: StringName) -> Dictionary:
	return _data.card(id)


## True when a draft is owed and the battle is in a build phase. A draft with no build
## phase after it never opens.
func draft_open() -> bool:
	return battle.phase == Battle.Phase.BUILD and drafts_owed() > 0


## The open draft's cards, 1 to 3, in the order they were drawn; [] when no draft is open.
## Worked out again on every call from the run seed, the picks and the battle.
func offers() -> Array[StringName]:
	var out: Array[StringName] = []
	if not draft_open():
		return out
	var eligible: Array[Dictionary] = _eligible()
	var rng: RandomNumberGenerator = MapAssembler.generator(run_seed, TAG_DRAFT, picks.size() + 1)
	var in_run: int = _run_towers().size()
	var risk_offered: bool = false
	for slot: int in OFFER_COUNT:
		var kind: StringName = &""
		if slot == 0 and in_run < FREE_TOWER_LIMIT and not _left(eligible, out, &"tower").is_empty():
			kind = &"tower"
		else:
			var live: Array[StringName] = []
			var total: int = 0
			for candidate: StringName in KINDS:
				var weight: int = _data.weights.get(candidate, 0)
				if weight <= 0 or (candidate == &"risk" and risk_offered):
					continue
				if _left(eligible, out, candidate).is_empty():
					continue
				live.append(candidate)
				total += weight
			if total <= 0:
				break
			var roll: int = rng.randi_range(1, total)
			var running: int = 0
			for candidate: StringName in live:
				running += int(_data.weights[candidate])
				if roll <= running:
					kind = candidate
					break
		var choices: Array[Dictionary] = _left(eligible, out, kind)
		if choices.is_empty():
			break
		var card: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
		out.append(card["id"])
		if kind == &"risk":
			risk_offered = true
	return out


## Takes one of the open draft's cards. Returns Battle.DONE, &"not_offered", or the
## battle's own refusal (nothing changes then).
func pick(card_id: StringName) -> StringName:
	if not offers().has(card_id):
		return &"not_offered"
	var card: Dictionary = _find(card_id)
	var effects: Array[Dictionary] = []
	for effect: Dictionary in card["effects"]:
		effects.append(effect)
	var result: StringName = battle.add_effects(effects, card["kind"] == &"risk")
	if result == Battle.DONE:
		picks.append(card_id)
	return result


## &"draft_waiting" while a draft is owed, in a build phase or during a wave. Otherwise
## the battle's own answer: the next wave starts, or an early call is made.
func start_next_wave() -> StringName:
	if (battle.phase == Battle.Phase.BUILD or battle.phase == Battle.Phase.WAVE) and drafts_owed() > 0:
		return &"draft_waiting"
	return battle.start_next_wave()


## The picked risk card still waiting for its wave; &"" for none.
func risk_card() -> StringName:
	if battle.risk_waiting.is_empty():
		return &""
	for i: int in range(picks.size() - 1, -1, -1):
		if _find(picks[i]).get("kind", &"") == &"risk":
			return picks[i]
	return &""


## {"won", "waves" (cleared), "lives" (left, at least 0), "reached" (the highest wave
## number started), "risks" (risk cards picked)}. An abandoned run counts as lost at its
## current wave (RULES 14.7).
func result() -> Dictionary:
	var risks: int = 0
	for id: StringName in picks:
		if _find(id).get("kind", &"") == &"risk":
			risks += 1
	return {
		"won": battle.phase == Battle.Phase.WON,
		"waves": int(battle.result()["waves_cleared"]),
		"lives": maxi(battle.lives, 0),
		"reached": battle.waves_started,
		"risks": risks,
	}


## The saved run without its battle (5.5).
func to_data() -> Dictionary:
	var pool_ids: Array[String] = []
	for id: StringName in pool:
		pool_ids.append(String(id))
	var pick_ids: Array[String] = []
	for id: StringName in picks:
		pick_ids.append(String(id))
	return {"format": FORMAT, "seed": run_seed, "day": day, "pool": pool_ids, "picks": pick_ids, "tier": tier}


## A run read from a save (5.6), around the battle that was saved with it. Everything is
## checked, all or nothing: null when anything is wrong.
static func from_data(raw: Variant, saved_battle: Battle, run_data: RunData) -> RunSession:
	if saved_battle == null or run_data == null:
		return null
	var chk: DataCheck = DataCheck.new("run")
	if not chk.object(raw, "", SAVE_KEYS, SAVE_OPTIONAL):
		return null
	var top: Dictionary = raw
	chk.integer(top, "format", "", FORMAT, FORMAT)
	var seed_value: int = chk.integer(top, "seed", "", 0, RunSeeds.SEED_MAX)
	# Missing means tier 0: a save from before regions 5 to 8.
	var tier_value: int = 0
	if top.has("tier"):
		tier_value = chk.integer(top, "tier", "", 0, run_data.tiers.size())
	var day_key: String = _read_day(top.get("day", null), seed_value, saved_battle, chk)
	var pool_ids: Array[StringName] = _read_pool(top.get("pool", null), run_data, tier_value, chk)
	var pick_ids: Array[StringName] = _read_picks(top.get("picks", null), pool_ids, run_data, chk)
	if pick_ids.size() > _cleared(saved_battle):
		chk.fail("picks", "more picks than cleared waves")
	if chk.ok() and not _has_repeatable_economy(pool_ids, run_data):
		chk.fail("pool", "holds no economy card that can be taken again")
	if chk.ok():
		_check_effects(pick_ids, saved_battle, run_data, chk)
	if not chk.ok():
		return null
	var session: RunSession = new()
	session._set_up(saved_battle, seed_value, day_key, pool_ids, run_data)
	session.tier = tier_value
	session.picks = pick_ids
	return session


static func _read_day(value: Variant, seed_value: int, saved_battle: Battle, chk: DataCheck) -> String:
	if not DataCheck.is_string(value) or String(value).length() > DAY_LENGTH:
		chk.fail("day", "must be empty or a day key")
		return ""
	var text: String = String(value)
	if text == "":
		return ""
	if not RunSeeds.is_day_key(text) or RunSeeds.daily_seed(text) != seed_value:
		chk.fail("day", "must be a day key that matches the seed")
		return ""
	if saved_battle.relaxed:
		chk.fail("day", "a daily is never Relaxed")
		return ""
	return text


static func _read_pool(value: Variant, run_data: RunData, tier_value: int, chk: DataCheck) -> Array[StringName]:
	var out: Array[StringName] = []
	var list: Array = chk.array_value(value, "pool", 1, POOL_MAX)
	for i: int in list.size():
		var path: String = "pool[%d]" % i
		var id: StringName = chk.ident_value(list[i], path)
		if id == &"":
			continue
		if run_data.card(id).is_empty():
			chk.fail(path, "names no card")
		elif int(run_data.card(id)["tier"]) > tier_value:
			chk.fail(path, "is a card of a higher tier than the run")
		elif out.has(id):
			chk.fail(path, "repeats %s" % id)
		else:
			out.append(id)
	return out


static func _read_picks(value: Variant, pool_ids: Array[StringName], run_data: RunData, chk: DataCheck) -> Array[StringName]:
	var out: Array[StringName] = []
	var list: Array = chk.array_value(value, "picks", 0, DRAFTS)
	for i: int in list.size():
		var path: String = "picks[%d]" % i
		var id: StringName = chk.ident_value(list[i], path)
		if id == &"":
			continue
		if not pool_ids.has(id):
			chk.fail(path, "is not in the pool")
		elif out.has(id) and bool(run_data.card(id).get("once", false)):
			chk.fail(path, "%s is taken only once" % id)
		else:
			out.append(id)
	return out


## Ties the battle's card effects to the picks (5.6). The kept effects must be exactly those
## the picks give, in pick order. Risk cards are matched in pick order too: the waiting one
## is the last risk card picked, and each running wave's card is an earlier risk pick, a
## later wave never taking an earlier card. Nothing else may carry card effects.
static func _check_effects(pick_ids: Array[StringName], saved_battle: Battle, run_data: RunData, chk: DataCheck) -> void:
	var kept: Array[Dictionary] = []
	var risks: Array[Array] = []
	for id: StringName in pick_ids:
		var card_data: Dictionary = run_data.card(id)
		var effects: Array[Dictionary] = []
		for effect: Dictionary in card_data["effects"]:
			effects.append(effect)
		var clean: Array[Dictionary] = Modifiers.normalize_all(effects)
		if card_data["kind"] == &"risk":
			risks.append(clean)
			continue
		for effect: Dictionary in clean:
			if not Modifiers.INSTANT.has(String(effect["type"])):
				kept.append(effect)
	if not _same(kept, saved_battle.card_effects):
		chk.fail("picks", "the battle's card effects are not the picks' effects")
		return
	var usable: int = risks.size()
	if not saved_battle.risk_waiting.is_empty():
		# Picked in a build phase, before the wave it waits for, and before the boss wave.
		if risks.is_empty() or saved_battle.phase != Battle.Phase.BUILD or saved_battle.waves_started >= RISK_CUTOFF:
			chk.fail("risk", "no risk card was picked that could be waiting")
			return
		usable -= 1
		if not _same(risks[usable], saved_battle.risk_waiting):
			chk.fail("risk", "is not the last risk card picked")
			return
	var next: int = 0
	var taken: Array = saved_battle.to_data()["wave_risk"]
	for item: Dictionary in taken:
		var found: bool = false
		while next < usable and not found:
			found = _same(risks[next], item["effects"])
			next += 1
		if not found:
			chk.fail("risk", "a running wave took a risk card that was not picked")
			return


## True when two lists of effects are equal in every key and value (both are normalized).
static func _same(a: Array, b: Array) -> bool:
	return a == b


static func _pool_ok(pool_ids: Array[StringName], data: RunData, tier_value: int) -> bool:
	if pool_ids.size() < 1 or pool_ids.size() > POOL_MAX:
		return false
	var seen: Dictionary[StringName, bool] = {}
	for id: StringName in pool_ids:
		if seen.has(id) or data.card(id).is_empty() or int(data.card(id)["tier"]) > tier_value:
			return false
		seen[id] = true
	return _has_repeatable_economy(pool_ids, data)


## True when the pool holds an economy card that is not once. Economy cards are always
## eligible, so such a card means a draft always has something to offer.
static func _has_repeatable_economy(pool_ids: Array[StringName], data: RunData) -> bool:
	for id: StringName in pool_ids:
		var card_data: Dictionary = data.card(id)
		if card_data.get("kind", &"") == &"economy" and not bool(card_data.get("once", false)):
			return true
	return false


## Waves 1 to 17 that have started and are no longer on the map (3.4).
static func _cleared(state: Battle) -> int:
	var count: int = 0
	for w: int in mini(state.waves_started, DRAFTS):
		if not state.running.has(w):
			count += 1
	return count


func _set_up(made: Battle, seed_value: int, day_key: String, pool_ids: Array[StringName], data: RunData) -> void:
	battle = made
	run_seed = seed_value
	day = day_key
	daily = day_key != ""
	pool = pool_ids.duplicate()
	_data = data
	for id: StringName in pool:
		_in_pool[id] = true


## The held card with this id; {} when unknown. Read only.
func _find(id: StringName) -> Dictionary:
	for card: Dictionary in _data.cards:
		if card["id"] == id:
			return card
	return {}


## The towers the run has: run.json's, plus the tower of every tower card picked.
func _run_towers() -> Array[StringName]:
	var out: Array[StringName] = _data.towers.duplicate()
	for id: StringName in picks:
		var card: Dictionary = _find(id)
		if card.get("kind", &"") == &"tower" and not out.has(card["tower"]):
			out.append(card["tower"])
	return out


## The pool's cards that may be offered now, in cards.json order (3.4).
func _eligible() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var towers: Array[StringName] = _run_towers()
	var gates: int = battle.gates.size() + battle.gates_in_hand
	var gate_room: bool = gates < battle.catalog.rules.max_gates and gates < battle.level.sockets.size()
	var risk_room: bool = battle.risk_waiting.is_empty() and battle.waves_started < RISK_CUTOFF
	for card: Dictionary in _data.cards:
		var id: StringName = card["id"]
		if not _in_pool.has(id) or (card["once"] and picks.has(id)):
			continue
		match card["kind"]:
			&"tower":
				if towers.has(card["tower"]):
					continue
			&"perk":
				if not towers.has(card["tower"]):
					continue
			&"gate":
				if not gate_room:
					continue
			&"risk":
				if not risk_room:
					continue
		out.append(card)
	# A perk with an unlock condition (RULES 14.6) only while no perk without one is eligible.
	var base_perk: bool = false
	for card: Dictionary in out:
		if card["kind"] == &"perk" and _unlock_of(card).is_empty():
			base_perk = true
			break
	if not base_perk:
		return out
	var kept: Array[Dictionary] = []
	for card: Dictionary in out:
		if card["kind"] == &"perk" and not _unlock_of(card).is_empty():
			continue
		kept.append(card)
	return kept


## A card's unlock condition: {} for a base card.
static func _unlock_of(card: Dictionary) -> Dictionary:
	var unlock: Dictionary = card["unlock"]
	return unlock


## The eligible cards of one kind that are not offered yet, in cards.json order.
func _left(eligible: Array[Dictionary], offered: Array[StringName], kind: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Dictionary in eligible:
		if card["kind"] == kind and not offered.has(card["id"]):
			out.append(card)
	return out
