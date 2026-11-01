# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## The run bot (task B2). It plays a roguelite run or a daily through RunSession and the Battle it
## wraps, with the public API only (docs/ARCHITECTURE.md 3.3). All chance in a bot comes from one
## RandomNumberGenerator seeded from the run seed and the strategy id, so a play can be repeated.
##
## A strategy is a Dictionary {"id", "pick", "build", "early"}:
##   pick:  how it chooses a card.
##     towers   a tower card first, then a perk, a spare gate, an economy card, a risk card last.
##     economy  a tower card only while the run has fewer than 2 kinds of tower, then economy, tower, perk, gate, risk last.
##     risk     a risk card whenever one is offered, then tower, perk, economy, gate.
##     random   any offered card, evenly.
##     Within a kind the card is chosen evenly by the bot's generator.
##   build: how it spends.
##     wide     builds new towers first (4 + 0.7 per wave started, up to the spots), upgrades after.
##     tall     upgrades what it has first (2 + 1 per 4 waves started towers wanted), builds after.
##   early: calls the next wave early from wave 4 on, when 6 or fewer creatures are on the map.
## A searched strategy (random_strategy) has pick "custom" with its own "order" of card kinds, and its own
## "base" and "rate" (towers wanted = base + rate per wave started), "early_from" and "early_live".
## Every strategy places gates (the socket that puts the most spots within 2.5 tiles of the walking
## route), buys during waves as gold comes in, never moves a gate and sells only to make room for a
## tower type it has never built.
##
## B4 changes (docs/design/TUNING_RUNS.md 3.5). A bot builds no Bakery until `bakery_from` waves have started
## (default 9, as the FL_BAKERY_WAIT=9 of the G3 what-ifs; 0 is the old rule). A bot passes on a sidegrade perk whose
## cost lands on the tier 3 path it will take (UNFIT). `boss_aim` points every attacker at Strong when the boss wave starts.
## `play` also takes opts "stack" (top, middle, bottom ids), "pack" (a pack id replacing the seed's pack of that band) and
## "stop_after" (stop once that many waves have started and none is on the map), for forced stacks and packs.
##
## B6 changes (docs/ARCHITECTURE.md 14.8). `play` takes opts "tier" (default 0): the run's content tier, passed to RunSession.start and to
## a forced map. The four expansion towers have bot weights of their own (NEW_WEIGHT); their tastes are drawn from a second generator,
## so a tier 0 run draws exactly what it did before. The Scarecrow is support, like the Bell. Road seen leaves out tunnel tiles.
##
## Run state ("st") is plain data and holds no Battle, so a restored battle can carry on with the same bot.

const Bot: GDScript = preload("res://tools/balance/bot.gd")

const TICK_CAP: int = 72000                       # 60 minutes of wave time: far past a run. A play that hits it is "stuck".
const BUILD_SECONDS: int = 15                     # a build phase counts 15 s in a run's length (RULES 12.5)
const REACH: int = 250                            # 2.5 tiles: the road a spot "sees", as in the plain recipe (RULES 12.6)
## Spots a Bakery must reach (within 1.5 tiles) before a bot builds one. 2 as in the plain recipe (RULES 12.6); runs.gd
## sets it from bakery_min= for the what-if with 1.
static var bakery_min: int = 2


static func set_bakery_min(n: int) -> void:
	bakery_min = n


## Waves that must have started before a bot builds a Bakery (B4: 9). 0 builds one at once, as B2's bots did.
static var bakery_from: int = 9
## 1 = the bot sets every attacking tower to Strong when the boss wave starts (a what-if, not part of the report's bars).
static var boss_aim: int = 0
## 1 = the bot passes on a sidegrade perk that does not fit the tier 3 paths it takes (UNFIT). 0 = B2's blind picks.
## 2 = it passes on every sidegrade perk of UNFIT, whatever its path (a what-if: how much of the unlock gap is the sidegrades).
static var perk_fit: int = 1
## A sidegrade perk, and the tier 3 path that carries its cost without its gain (TUNING_RUNS 3.5).
const UNFIT: Dictionary = {
	&"volley": &"giant_bow", &"twin_pebbles": &"stone_sling", &"long_fuse": &"skyrocket",
	&"frost_chime": &"night_bell", &"spice_rack": &"grand_oven",
}


static func set_options(from_bakery: int, aim: int, fit: int) -> void:
	bakery_from = from_bakery
	boss_aim = aim
	perk_fit = fit


static func get_bakery_min() -> int:
	return bakery_min


## E5.2. 1 = a bot puts a pulse tower (the Bramble Cottage) on the free spot with the most road tiles within the tower's own reach, outside
## tunnels, as a player who has read its card would. 0 (the default, and the report's bars) = it takes the best free spot by road within
## 2.5 tiles like any attacker, which is the plain recipe's rule (RULES 12.6).
static var bramble_fit: int = 0


static func set_bramble_fit(n: int) -> void:
	bramble_fit = n


## E5.2. A cap on the Bramble Cottages a bot builds (0 = no cap, the default, and the report's bars). A what-if: a player builds one or two
## at the road, not a quarter of the towers.
static var bramble_cap: int = 0


static func set_bramble_cap(n: int) -> void:
	bramble_cap = n


## E6.2. The anti-air floor, in percent (0 = off; the default at tiers 0 and 1, and 55 from tier 2 up since E5.5, see habits()). A what-if for the game designer's suggestion: when a bot would
## build an attacker that cannot hit flyers (Pumpkin Catapult, Longbow Loft, Bramble Cottage, Snow Fort) and anti-air towers (Sling Post, Firework
## Tower, Moth Lantern) would be fewer than this share of its attackers after the build, it builds an anti-air tower instead (the one with the
## lowest count over weight). The first tower of each type is not touched.
static var air_floor: int = 0
const ANTI_AIR: Array[StringName] = [&"sling_post", &"firework_tower", &"moth_lantern"]


## E6.2. Waves that must have started before a bot builds a Scarecrow (0 = no wait; the default at tiers 0 and 1, and 9 from tier 2 up since E5.5, see habits()). A what-if for the
## Scarecrow card: it deals no damage, and a bot builds the first tower of every type it has at once, so it spends its early gold on it.
static var scarecrow_from: int = 0


static func set_scarecrow_from(n: int) -> void:
	scarecrow_from = n


static func set_air_floor(n: int) -> void:
	air_floor = n


## E5.5 (the DM's call after TUNING_R67.md 1.3, RULES 14.8): from content tier 2 up the bots keep the two habits by default, a Scarecrow only after
## SCARECROW_HABIT waves and anti-air towers at AIR_HABIT percent of the attackers. Tiers 0 and 1 are unchanged. A value given on the command line wins,
## so a what-if can turn either off with 0.
const SCARECROW_HABIT: int = 9
const AIR_HABIT: int = 55


static func habits(tier: int, args: Dictionary) -> void:
	set_air_floor(int(args.get("air_floor", str(AIR_HABIT if tier >= 2 else 0))))
	set_scarecrow_from(int(args.get("scarecrow_from", str(SCARECROW_HABIT if tier >= 2 else 0))))


const PICKS: Array[StringName] = [&"towers", &"economy", &"risk", &"random"]
const BUILDS: Array[StringName] = [&"wide", &"tall"]
const BASE_WEIGHT: Dictionary = {
	&"sling_post": 1.5, &"pumpkin_catapult": 1.0, &"longbow_loft": 1.0, &"firework_tower": 0.7,
	&"lullaby_bell": 0.8, &"bakery": 0.8,
}
## The expansion towers (B6). Their weights and tier 3 paths are drawn from a second generator (new_state).
const NEW_WEIGHT: Dictionary = {
	&"bramble_cottage": 1.0, &"scarecrow": 0.8, &"snow_fort": 1.0, &"moth_lantern": 0.7,
}
const CAPS: Dictionary = {&"lullaby_bell": 2, &"bakery": 1, &"scarecrow": 2}
const PRIORITY: Dictionary = {
	&"towers": [&"tower", &"perk", &"gate", &"economy", &"risk"],
	&"economy": [&"economy", &"tower", &"perk", &"gate", &"risk"],
	&"risk": [&"risk", &"tower", &"perk", &"economy", &"gate"],
}


## The 16 strategies, in a fixed order: pick style, then build style, then early calls off and on.
static func strategies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pick: StringName in PICKS:
		for build: StringName in BUILDS:
			for early: bool in [false, true]:
				out.append({"id": "%s_%s%s" % [pick, build, "_early" if early else ""], "pick": pick, "build": build, "early": early})
	return out


## A random strategy for a search, from the generator: a card order, a build pace and an early call habit.
static func random_strategy(rng: RandomNumberGenerator, id: String) -> Dictionary:
	var order: Array[StringName] = [&"tower", &"perk", &"gate", &"economy", &"risk"]
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: StringName = order[i]
		order[i] = order[j]
		order[j] = tmp
	var early: bool = rng.randf() < 0.3
	return {"id": id, "pick": &"custom", "build": &"param", "order": order, "base": rng.randf_range(2.0, 6.0), "rate": rng.randf_range(0.1, 1.0),
		"early": early, "early_from": rng.randi_range(2, 8), "early_live": [0, 3, 6, 10, 15][rng.randi_range(0, 4)]}


## The strategy with this id, or {}.
static func strategy(id: String) -> Dictionary:
	for item: Dictionary in strategies():
		if String(item["id"]) == id:
			return item
	return {}


# State.

static func new_state(session: RunSession, strat: Dictionary, run_seed: int) -> Dictionary:
	var b: Battle = session.battle
	var level: LevelData = b.level
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = ("%d:%s:bot" % [run_seed, String(strat["id"])]).hash()
	# Per bot tastes: a jitter on each tower's weight and which tier 3 path each tower takes.
	var weight: Dictionary = {}
	var spec_of: Dictionary = {}
	for id: StringName in BASE_WEIGHT.keys():
		weight[id] = float(BASE_WEIGHT[id]) * rng.randf_range(0.7, 1.3)
		spec_of[id] = rng.randi_range(0, 1)
	# The expansion towers' tastes, from a generator of their own (B6).
	var rng2: RandomNumberGenerator = RandomNumberGenerator.new()
	rng2.seed = ("%d:%s:bot2" % [run_seed, String(strat["id"])]).hash()
	for id: StringName in NEW_WEIGHT.keys():
		weight[id] = float(NEW_WEIGHT[id]) * rng2.randf_range(0.7, 1.3)
		spec_of[id] = rng2.randi_range(0, 1)
	# Spots ranked by the road they see, most first, ties in cell order (as RULES 12.6 step 1). Tunnel tiles do not count.
	var road: Array[Vector2i] = Bot.seen_road_cells(level)
	var keyed: Array = []
	for i: int in level.spots.size():
		var seen: int = 0
		for cell: Vector2i in road:
			var dx: int = (cell.x - level.spots[i].x) * 100
			var dy: int = (cell.y - level.spots[i].y) * 100
			if dx * dx + dy * dy <= REACH * REACH:
				seen += 1
		keyed.append([-seen, i])
	keyed.sort()
	var ranked: Array[Vector2i] = []
	for item: Array in keyed:
		ranked.append(level.spots[int(item[1])])
	# For each road cell, how many spots are within 2.5 tiles: what a gate steers walkers past.
	var cover: Dictionary = {}
	for cell: Vector2i in road:
		var n: int = 0
		for spot: Vector2i in level.spots:
			var dx: int = (cell.x - spot.x) * 100
			var dy: int = (cell.y - spot.y) * 100
			if dx * dx + dy * dy <= REACH * REACH:
				n += 1
		cover[cell] = n
	# E5.2: for each spot, the road tiles within a Bramble Cottage's own reach (used only when bramble_fit is 1).
	var near_pulse: Dictionary = {}
	var cottage: TowerType = b.catalog.tower(&"bramble_cottage") if b.catalog.has_tower(&"bramble_cottage") else null
	if cottage != null:
		var pulse_reach: int = cottage.stats(1, -1).reach
		for spot: Vector2i in level.spots:
			var n_near: int = 0
			for cell: Vector2i in road:
				var ddx: int = (cell.x - spot.x) * 100
				var ddy: int = (cell.y - spot.y) * 100
				if ddx * ddx + ddy * ddy <= pulse_reach * pulse_reach:
					n_near += 1
			near_pulse[spot] = n_near
	return {"strat": strat, "rng": rng, "weight": weight, "spec_of": spec_of, "ranked": ranked, "cover": cover,
		"dead": {}, "gate_dead": {}, "swapped": {}, "near_pulse": near_pulse}


# Cards.

## The card the strategy takes from the open draft.
static func choose(st: Dictionary, session: RunSession, offers: Array[StringName]) -> StringName:
	var rng: RandomNumberGenerator = st["rng"]
	var style: StringName = st["strat"]["pick"]
	var fit: Array[StringName] = []
	for id: StringName in offers:
		if _fits(st, session, id):
			fit.append(id)
	if fit.is_empty():
		fit = offers
	if style == &"random":
		return fit[rng.randi_range(0, fit.size() - 1)]
	var order: Array = st["strat"]["order"] if style == &"custom" else PRIORITY[style]
	if style == &"economy" and _kinds_of_tower(session) < 2:
		order = [&"tower", &"economy", &"perk", &"gate", &"risk"]
	for kind: StringName in order:
		var same: Array[StringName] = []
		for id: StringName in fit:
			if session.card(id).get("kind", &"") == kind:
				same.append(id)
		if not same.is_empty():
			return _weighted(st, session, same, rng)
	return fit[0]


## False for a sidegrade perk whose cost falls on the tier 3 path this bot takes (UNFIT), when B4's perk choice is on.
static func _fits(st: Dictionary, session: RunSession, id: StringName) -> bool:
	if perk_fit == 0 or not UNFIT.has(id):
		return true
	if perk_fit == 2:
		return false
	var card: Dictionary = session.card(id)
	var tower: StringName = StringName(card.get("tower", &""))
	if not st["spec_of"].has(tower):
		return true
	var stats: TowerType = session.battle.catalog.tower(tower)
	return stats.specs[int(st["spec_of"][tower])] != UNFIT[id]


## A card among those of one kind. Tower cards and perks lean to the tower's weight (attackers over Bells and
## Bakeries); the rest are even.
static func _weighted(st: Dictionary, session: RunSession, same: Array[StringName], rng: RandomNumberGenerator) -> StringName:
	var weights: Array[float] = []
	var total: float = 0.0
	for id: StringName in same:
		var tower: StringName = StringName(session.card(id).get("tower", &""))
		var w: float = float(st["weight"].get(tower, 1.0))
		weights.append(w)
		total += w
	var roll: float = rng.randf() * total
	for i: int in same.size():
		roll -= weights[i]
		if roll <= 0.0:
			return same[i]
	return same[same.size() - 1]


## The towers the run has: the level's, plus the tower of every tower card picked.
static func run_towers(session: RunSession) -> Array[StringName]:
	var out: Array[StringName] = session.battle.level.towers.duplicate()
	for id: StringName in session.picks:
		var card: Dictionary = session.card(id)
		if card.get("kind", &"") == &"tower" and not out.has(card["tower"]):
			out.append(card["tower"])
	return out


static func _kinds_of_tower(session: RunSession) -> int:
	return run_towers(session).size()


# Gates.

## Puts the gates in hand on the sockets that raise the walking route's cover the most. A gate
## that would not raise it stays in hand. Build phases only.
static func place_gates(st: Dictionary, session: RunSession) -> void:
	var b: Battle = session.battle
	while b.phase == Battle.Phase.BUILD and b.gates_in_hand > 0:
		var closed: Array[Vector2i] = b.closed_cells()
		var now: int = _route_cover(st, b, closed)
		var best: Vector2i = Vector2i(-1, -1)
		var best_score: int = now
		for socket: Vector2i in b.level.sockets:
			if closed.has(socket) or st["gate_dead"].has(socket):
				continue
			var shut: Array[Vector2i] = closed.duplicate()
			shut.append(socket)
			if b.seals(shut):
				continue
			var score: int = _route_cover(st, b, shut)
			if score > best_score:
				best_score = score
				best = socket
		if best == Vector2i(-1, -1):
			return
		if b.place_gate(best) != Battle.DONE:
			st["gate_dead"][best] = true


static func _route_cover(st: Dictionary, b: Battle, closed: Array[Vector2i]) -> int:
	var cover: Dictionary = st["cover"]
	var total: int = 0
	for route: Dictionary in b.routes(closed):
		for cell: Vector2i in route["walk"]:
			total += int(cover.get(cell, 0))
	return total


# Buying.

## Buys while gold lasts. Returns &"waiting" (the next item costs too much), or &"nothing" (nothing
## left to buy or build).
static func buy(st: Dictionary, session: RunSession) -> StringName:
	var b: Battle = session.battle
	var guard: int = 0
	while guard < 200:
		guard += 1
		var step: Dictionary = _next_step(st, session)
		if step.is_empty():
			return &"nothing"
		var refusal: StringName
		match String(step["do"]):
			"build":
				refusal = b.place_tower(step["cell"], step["type"])
			"upgrade":
				refusal = b.upgrade_tower(step["cell"], int(step["spec"]))
			_:
				refusal = b.sell_tower(step["cell"])
				if refusal == Battle.DONE:
					st["swapped"][step["type"]] = true
		if refusal == &"too_poor":
			return &"waiting"
		if refusal != Battle.DONE:
			st["dead"][step["key"]] = true
	return &"nothing"


## The next thing to buy: {"do": "build"/"upgrade"/"sell", "cell", "type", "spec", "key"}, or {}.
static func _next_step(st: Dictionary, session: RunSession) -> Dictionary:
	var b: Battle = session.battle
	var level: LevelData = b.level
	var dead: Dictionary = st["dead"]
	var ranked: Array[Vector2i] = st["ranked"]
	var weight: Dictionary = st["weight"]
	var available: Array[StringName] = run_towers(session)
	var count: Dictionary = {}
	for id: StringName in available:
		count[id] = 0
	for tower: TowerState in b.towers:
		count[tower.type] = int(count.get(tower.type, 0)) + 1
	var free: Array[Vector2i] = []
	for spot: Vector2i in ranked:
		if b.tower_at(spot) == null:
			free.append(spot)
	var waves: int = b.waves_started
	var strat: Dictionary = st["strat"]
	var wide: bool = strat["build"] == &"wide"
	var want: int = mini(ranked.size(), (4 + int(0.7 * waves)) if wide else (2 + waves / 4))
	if strat.has("base"):
		want = mini(ranked.size(), int(float(strat["base"]) + float(strat["rate"]) * waves))
	# The Bakery waits until bakery_from waves have started (B4).
	var bakery_wait: bool = waves < bakery_from
	var scarecrow_wait: bool = waves < scarecrow_from
	# A type never built goes first. With no spot free (or no good Bakery spot free) it sells one tower to make room.
	for id: StringName in available:
		if int(count[id]) > 0 or dead.has("t:" + String(id)):
			continue
		if id == &"bakery" and bakery_wait:
			continue
		if id == &"scarecrow" and scarecrow_wait:
			continue
		var cell: Vector2i = _spot_for(id, free, ranked, st)
		if cell != Vector2i(-1, -1):
			var made: String = "b:%d,%d:%s" % [cell.x, cell.y, id]
			if dead.has(made):
				dead["t:" + String(id)] = true
				continue
			return {"do": "build", "cell": cell, "type": id, "spec": -1, "key": made}
		if id == &"bakery":
			var any: Vector2i = _spot_for(id, ranked, ranked, st)
			if any == Vector2i(-1, -1):
				dead["t:" + String(id)] = true
				continue
			if b.phase == Battle.Phase.BUILD and not st["swapped"].has(id) and b.tower_at(any) != null:
				return {"do": "sell", "cell": any, "type": id, "spec": -1, "key": "s:%d,%d" % [any.x, any.y]}
		elif free.is_empty() and b.phase == Battle.Phase.BUILD and not st["swapped"].has(id):
			var victim: TowerState = _weakest(b, count)
			if victim != null:
				return {"do": "sell", "cell": victim.cell, "type": id, "spec": -1, "key": "s:%d,%d" % [victim.cell.x, victim.cell.y]}
	var upgrade: Dictionary = _upgrade_step(st, session)
	var pickable: Array[StringName] = available.duplicate()
	if bakery_wait:
		pickable.erase(&"bakery")
	if scarecrow_wait:
		pickable.erase(&"scarecrow")
	var type: StringName = _deficit(pickable, count, weight, dead)
	if air_floor > 0 and type != &"" and not ANTI_AIR.has(type) and b.catalog.tower(type).kind == &"attack":
		type = _keep_air(type, pickable, count, weight, dead)
	if not free.is_empty() and type != &"" and (b.towers.size() < want or upgrade.is_empty()):
		var cell2: Vector2i = _spot_for(type, free, ranked, st)
		if cell2 != Vector2i(-1, -1):
			var key: String = "b:%d,%d:%s" % [cell2.x, cell2.y, type]
			if not dead.has(key):
				return {"do": "build", "cell": cell2, "type": type, "spec": -1, "key": key}
	return upgrade


## The tower to upgrade: lowest tier first, attackers before Bells and Bakeries, best spot first.
static func _upgrade_step(st: Dictionary, session: RunSession) -> Dictionary:
	var b: Battle = session.battle
	var ranked: Array[Vector2i] = st["ranked"]
	var best: TowerState = null
	var best_key: int = 0
	for tower: TowerState in b.towers:
		if tower.tier >= 3:
			continue
		var key: String = "u:%d,%d:%d" % [tower.cell.x, tower.cell.y, tower.tier]
		if st["dead"].has(key):
			continue
		var support: int = 0 if tower.kind == &"attack" else 1
		var rank_key: int = tower.tier * 1000 + support * 100 + ranked.find(tower.cell)
		if best == null or rank_key < best_key:
			best = tower
			best_key = rank_key
	if best == null:
		return {}
	var spec: int = -1
	if best.tier == 2:
		spec = int(st["spec_of"][best.type])
	return {"do": "upgrade", "cell": best.cell, "type": best.type, "spec": spec, "key": "u:%d,%d:%d" % [best.cell.x, best.cell.y, best.tier]}


## The type to build next: the one with the lowest count over weight, skipping capped types. &"" for none.
static func _deficit(available: Array[StringName], count: Dictionary, weight: Dictionary, dead: Dictionary) -> StringName:
	var best: StringName = &""
	var best_score: float = 0.0
	for id: StringName in available:
		if (CAPS.has(id) and int(count[id]) >= int(CAPS[id])) or dead.has("t:" + String(id)):
			continue
		if bramble_cap > 0 and id == &"bramble_cottage" and int(count[id]) >= bramble_cap:
			continue
		var score: float = float(count[id]) / float(weight[id])
		if best == &"" or score < best_score:
			best = id
			best_score = score
	return best


## E6.2. The anti-air floor: `type` (an attacker that cannot hit flyers) stands unless anti-air towers would fall under the floor, then the
## anti-air tower with the lowest count over weight is built instead. `type` itself when no anti-air tower can be built.
static func _keep_air(type: StringName, available: Array[StringName], count: Dictionary, weight: Dictionary, dead: Dictionary) -> StringName:
	var attackers: int = 0
	var air: int = 0
	for id: StringName in count.keys():
		var n: int = int(count[id])
		if ANTI_AIR.has(id):
			air += n
			attackers += n
		elif id != &"lullaby_bell" and id != &"bakery" and id != &"scarecrow":
			attackers += n
	if (air * 100) >= air_floor * (attackers + 1):
		return type
	var pool: Array[StringName] = []
	for id: StringName in available:
		if ANTI_AIR.has(id):
			pool.append(id)
	var pick: StringName = _deficit(pool, count, weight, dead)
	return pick if pick != &"" else type


## Where a tower of this type goes: attackers on the best free spot, a Bell on the best free spot
## after the top two, a Bakery on the free spot with the most neighboring spots (at least 2).
static func _spot_for(type: StringName, free: Array[Vector2i], ranked: Array[Vector2i], st: Dictionary) -> Vector2i:
	if free.is_empty():
		return Vector2i(-1, -1)
	if bramble_fit == 1 and type == &"bramble_cottage" and not (st["near_pulse"] as Dictionary).is_empty():
		var pick: Vector2i = free[0]
		var most_near: int = -1
		for spot: Vector2i in free:
			var n: int = int(st["near_pulse"].get(spot, 0))
			if n > most_near:
				most_near = n
				pick = spot
		return pick
	if type == &"bakery":
		var best: Vector2i = Vector2i(-1, -1)
		var most: int = bakery_min - 1
		for spot: Vector2i in free:
			var near: int = 0
			for other: Vector2i in ranked:
				if other != spot and absi(other.x - spot.x) <= 1 and absi(other.y - spot.y) <= 1:
					near += 1
			if near > most:
				most = near
				best = spot
		return best
	if type == &"lullaby_bell" or type == &"scarecrow":
		for spot: Vector2i in free:
			if ranked.find(spot) >= 2:
				return spot
	return free[0]


## The tower to sell to make room: of the commonest type (at least 2 of it), the lowest tier, then the worst spot.
static func _weakest(b: Battle, count: Dictionary) -> TowerState:
	var common: StringName = &""
	var most: int = 1
	for id: StringName in count.keys():
		if int(count[id]) > most:
			most = int(count[id])
			common = id
	if common == &"":
		return null
	var victim: TowerState = null
	for tower: TowerState in b.towers:
		if tower.type != common:
			continue
		if victim == null or tower.tier < victim.tier or (tower.tier == victim.tier and Sim.cell_before(victim.cell, tower.cell)):
			victim = tower
	return victim


# Playing.

## Plays one run to its end. The pool, seed, day and difficulty are given; `opts` may hold
##   "restore_wave": [w, k]   save and load (through JSON text) k ticks after wave w (0 based) starts
##   "restore_draft": n       save and load when the draft after n picks is open
##   "snapshots": true        keep the saved state before each wave starts (for the risk branches)
##   "draft_snapshots": true  keep the saved state (and the bot's generator) before each pick (for the card experiment)
##   "resume": Dictionary     carry on from a draft snapshot; "force" is then the card taken first
##   "stack": Array           top, middle and bottom segment ids to use instead of the seed's (B4: forced stacks)
##   "pack": String           a pack id that replaces the seed's pack of that pack's band (B4: forced packs)
##   "stop_after": n          stop at the first build phase after n waves have started (all cleared)
##   "force_risk": {"card": id, "k": n}   at the draft held after n picks, take this risk card whether or not it is offered (B5: the
##                            most crowded wave). The run is rebuilt through Battle.add_effects and RunSession.from_data, so it saves and loads.
##   "stop_before": n         stop in the build phase just before wave n starts (after the draft and the buying)
##   "return_state": true     the result also holds `end_battle` and `end_run`, the saved data of the battle and the run at the end
## Returns a plain Dictionary (see the keys at the end).
static func play(game: GameData, run_seed: int, day: String, relaxed: bool, pool: Array[StringName], strat: Dictionary, opts: Dictionary = {}) -> Dictionary:
	var session: RunSession = null
	var st: Dictionary = {}
	if opts.has("resume"):
		var saved: Dictionary = opts["resume"]
		var battle_in: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(saved["battle"])), game.catalog)
		session = RunSession.from_data(JSON.parse_string(JSON.stringify(saved["run"])), battle_in, game.run) if battle_in != null else null
		if session == null:
			return {"bad": "a draft snapshot would not load at seed %d" % run_seed}
		st = new_state(session, strat, run_seed)
		(st["rng"] as RandomNumberGenerator).state = int(saved["rng_state"])
		st["dead"] = (saved["dead"] as Dictionary).duplicate()
		st["gate_dead"] = (saved["gate_dead"] as Dictionary).duplicate()
		st["swapped"] = (saved["swapped"] as Dictionary).duplicate()
	else:
		var forced_stack: Array = opts.get("stack", [])
		var forced_pack: String = String(opts.get("pack", ""))
		if forced_stack.is_empty() and forced_pack == "":
			session = RunSession.start(run_seed, day, relaxed, pool, game.run, game.catalog, int(opts.get("tier", 0)))
		else:
			session = forced_session(game, run_seed, relaxed, pool, forced_stack, forced_pack, int(opts.get("tier", 0)))
		if session == null:
			return {"bad": "RunSession.start gave null for seed %d" % run_seed}
		st = new_state(session, strat, run_seed)
	var b: Battle = session.battle
	var leak_watch: bool = bool(opts.get("leaks", false))
	var leaks: Dictionary = {}
	b.record_events = leak_watch
	var forced: StringName = StringName(opts.get("force", ""))
	var draft_snaps: Array = []
	var wave_count: int = b.wave_count()
	var early_on: bool = bool(strat["early"])
	var calls: int = 0
	var builds: int = 0
	var peak: int = 0
	var peak_at: Array[int] = []
	var gold_at: Array[int] = []
	var gold_pre: Array[int] = []
	var lives_pre: Array[int] = []
	var lives_at: Array[int] = []
	var towers_at: Array[int] = []
	var tiers_at: Array[int] = []
	var idle_at: Array[int] = []
	var wave_ticks: Array[int] = []
	var offered: Array = []
	var snapshots: Array = []
	var restores: int = 0
	var offers_equal: bool = true
	var boss_min: int = 1000
	var boss_steps: int = -1
	var boss_seen: bool = false
	var restore_wave: Array = opts.get("restore_wave", [])
	var restore_draft: int = int(opts.get("restore_draft", -1))
	var spent_total: int = 0
	var idle: StringName = &"waiting"
	var boss_dist: PackedInt32Array = b.map.distances(b.closed_cells())
	var stop_after: int = int(opts.get("stop_after", 0))
	var stop_before: int = int(opts.get("stop_before", 0))
	var risk_force: Dictionary = opts.get("force_risk", {})
	var stopped: bool = false
	var aim_boss: bool = boss_aim == 1
	var boss_aimed: bool = false
	while b.phase == Battle.Phase.BUILD and b.tick < TICK_CAP:
		if stop_after > 0 and b.waves_started >= stop_after:
			stopped = true
			break
		gold_pre.append(b.gold)
		lives_pre.append(b.lives)
		while session.draft_open():
			if not risk_force.is_empty() and session.picks.size() == int(risk_force["k"]):
				var made: RunSession = _force_pick(game, session, StringName(String(risk_force["card"])))
				if made == null:
					return {"bad": "a forced pick would not load at seed %d" % run_seed}
				session = made
				b = session.battle
				b.record_events = leak_watch
				risk_force = {}
				continue
			if restore_draft == session.picks.size() and restores == 0:
				var before: Array[StringName] = session.offers()
				var again: Dictionary = _roundtrip(game, session)
				if again.has("refused"):
					return {"restore_failed": true, "refused": again["refused"], "at": "draft %d" % restore_draft, "won": false, "seed": run_seed}
				session = again["session"]
				b = session.battle
				b.record_events = leak_watch
				restores += 1
				if session.offers() != before:
					offers_equal = false
			var offers: Array[StringName] = session.offers()
			offered.append(offers.duplicate())
			if bool(opts.get("draft_snapshots", false)):
				draft_snaps.append({"battle": b.to_data(), "run": session.to_data(), "rng_state": (st["rng"] as RandomNumberGenerator).state,
					"dead": (st["dead"] as Dictionary).duplicate(), "gate_dead": (st["gate_dead"] as Dictionary).duplicate(),
					"swapped": (st["swapped"] as Dictionary).duplicate(), "offers": offers.duplicate(), "k": session.picks.size()})
			var choice: StringName = choose(st, session, offers) if forced == &"" else forced
			forced = &""
			if session.pick(choice) != Battle.DONE:
				choice = offers[0]
				if session.pick(choice) != Battle.DONE:
					return {"bad": "pick refused at seed %d" % run_seed}
		place_gates(st, session)
		var gold_before: int = b.gold
		idle = buy(st, session)
		spent_total += gold_before - b.gold
		builds += 1
		gold_at.append(b.gold)
		lives_at.append(b.lives)
		towers_at.append(b.towers.size())
		tiers_at.append(_tier_sum(b))
		idle_at.append(1 if idle == &"nothing" else 0)
		if bool(opts.get("snapshots", false)):
			snapshots.append({"battle": b.to_data(), "run": session.to_data(), "wave": b.waves_started})
		if stop_before > 0 and b.waves_started == stop_before - 1:
			stopped = true
			break
		var started_at: int = b.tick
		if session.start_next_wave() != Battle.DONE:
			break
		wave_ticks.append(0)
		peak_at.append(0)
		var first_tick: int = started_at
		var index: int = wave_ticks.size() - 1
		while b.phase == Battle.Phase.WAVE and b.tick < TICK_CAP:
			if aim_boss and not boss_aimed and b.waves_started == wave_count:
				boss_aimed = true
				for tower: TowerState in b.towers:
					if tower.kind == &"attack":
						b.set_aim(tower.cell, TowerState.Aim.STRONG)
			if b.tick % 4 == 0:
				idle = buy(st, session)
			if early_on and b.waves_started < wave_count and b.waves_started >= int(strat.get("early_from", 3)) and b.enemies.size() <= int(strat.get("early_live", 6)) and b.tick % 2 == 0:
				if session.start_next_wave() == Battle.DONE:
					calls += 1
					gold_at.append(b.gold)
					lives_at.append(b.lives)
					towers_at.append(b.towers.size())
					tiers_at.append(_tier_sum(b))
					idle_at.append(1 if idle == &"nothing" else 0)
					wave_ticks[index] = b.tick - first_tick
					wave_ticks.append(0)
					peak_at.append(0)
					index = wave_ticks.size() - 1
					first_tick = b.tick
			if restore_wave.size() == 2 and restores == 0 and b.waves_started == int(restore_wave[0]) + 1 and b.tick - first_tick >= int(restore_wave[1]):
				var moved: Dictionary = _roundtrip(game, session)
				if moved.has("refused"):
					return {"restore_failed": true, "refused": moved["refused"], "at": "wave %d" % int(restore_wave[0]), "won": false, "seed": run_seed}
				session = moved["session"]
				b = session.battle
				b.record_events = leak_watch
				restores += 1
			b.step()
			if leak_watch:
				for event: Dictionary in b.take_events():
					if event["kind"] == &"leaked":
						var type_key: String = String(event["enemy"])
						leaks[type_key] = int(leaks.get(type_key, 0)) + int(event["lives"])
			var live: int = b.enemies.size()
			if live > peak:
				peak = live
			if live > peak_at[index]:
				peak_at[index] = live
			if b.tick % 5 == 0:
				for enemy: EnemyState in b.enemies:
					if game.catalog.enemy(enemy.type).boss:
						boss_seen = true
						boss_min = mini(boss_min, enemy.health * 1000 / maxi(enemy.max_health, 1))
						var left: int = Bot.steps_left(b, boss_dist, enemy)
						boss_steps = left if boss_steps < 0 else mini(boss_steps, left)
		wave_ticks[index] = b.tick - first_tick
	var res: Dictionary = session.result()
	var mix: Dictionary = {}
	for tower: TowerState in b.towers:
		var key: String = String(tower.type)
		mix[key] = int(mix.get(key, 0)) + 1
		if tower.tier == 3:
			var path: String = String(game.catalog.tower(tower.type).specs[tower.spec])
			mix[path] = int(mix.get(path, 0)) + 1
	var picks: Array[String] = []
	for id: StringName in session.picks:
		picks.append(String(id))
	var out: Dictionary = {
		"seed": run_seed, "day": day, "relaxed": relaxed, "strategy": String(strat["id"]),
		"won": res["won"], "lives": res["lives"], "cleared": res["waves"], "reached": res["reached"], "risks": res["risks"],
		"ticks": b.tick, "builds": builds, "early": calls, "peak": peak, "peak_at": peak_at,
		"stuck": (b.phase == Battle.Phase.WAVE or b.phase == Battle.Phase.BUILD) and not stopped, "stopped": stopped,
		"gold_pre": gold_pre, "lives_pre": lives_pre, "gold_at": gold_at, "lives_at": lives_at, "towers_at": towers_at, "tiers_at": tiers_at, "idle_at": idle_at,
		"wave_ticks": wave_ticks, "gates_end": b.gates.size(), "end_gold": b.gold, "spent": spent_total, "mix": mix,
		"picks": picks, "offered": _names(offered),
		"boss_min": boss_min if boss_seen else -1, "boss_steps": boss_steps,
		"battle_hash": JSON.stringify(b.to_data()).hash(), "run_hash": JSON.stringify(session.to_data()).hash(),
		"restores": restores, "offers_equal": offers_equal,
	}
	if leak_watch:
		out["leaks"] = leaks
	if bool(opts.get("return_state", false)):
		out["end_battle"] = b.to_data()
		out["end_run"] = session.to_data()
		out["forced_done"] = risk_force.is_empty()
	if bool(opts.get("snapshots", false)):
		out["snapshots"] = snapshots
	if bool(opts.get("draft_snapshots", false)):
		out["draft_snaps"] = draft_snaps
	return out


## The session with a risk card taken at the open draft, whether or not the draft offers it: the battle takes the card's effects
## as Battle.add_effects does for a pick, and the run is read back with the card among its picks. Null when a check refuses it.
static func _force_pick(game: GameData, session: RunSession, card_id: StringName) -> RunSession:
	var battle: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(session.battle.to_data())), game.catalog)
	if battle == null:
		return null
	var card: Dictionary = session.card(card_id)
	if card.is_empty():
		return null
	var effects: Array[Dictionary] = []
	for effect: Dictionary in card["effects"]:
		effects.append(effect)
	if battle.add_effects(effects, card["kind"] == &"risk") != Battle.DONE:
		return null
	var data: Dictionary = JSON.parse_string(JSON.stringify(session.to_data()))
	(data["picks"] as Array).append(String(card_id))
	return RunSession.from_data(data, battle, game.run)


## Saves the session and its battle to JSON text and loads them again: the real path of a saved game.
## {"refused": why} when anything refuses to load (the save checks of RunSession.from_data included).
static func _roundtrip(game: GameData, session: RunSession) -> Dictionary:
	var text: String = JSON.stringify({"battle": session.battle.to_data(), "run": session.to_data()})
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"refused": "json"}
	var battle: Battle = Battle.from_data(parsed["battle"], game.catalog)
	if battle == null:
		return {"refused": "battle"}
	var again: RunSession = RunSession.from_data(parsed["run"], battle, game.run)
	if again == null:
		return {"refused": "run"}
	return {"session": again}


## A run on a forced stack and/or pack. The seed's own plan fills what is not forced. The session is made the public way:
## the level from MapAssembler.build, a Battle around it, and RunSession.from_data with no picks (a new run's save).
static func forced_session(game: GameData, run_seed: int, relaxed: bool, pool: Array[StringName], stack: Array, pack: String, tier: int = 0) -> RunSession:
	var plan: Dictionary = MapAssembler.plan(run_seed, game.run, tier)
	if plan.is_empty():
		return null
	var top: StringName = plan["top"]
	var middle: StringName = plan["middle"]
	var bottom: StringName = plan["bottom"]
	if stack.size() == 3:
		top = StringName(String(stack[0]))
		middle = StringName(String(stack[1]))
		bottom = StringName(String(stack[2]))
	var packs: Array[StringName] = []
	packs.assign(plan["packs"])
	if pack != "":
		for item: Dictionary in game.run.packs:
			if String(item["id"]) == pack:
				packs[int(item["band"]) - 1] = item["id"]
	var level: LevelData = MapAssembler.build(game.run, game.catalog, top, middle, bottom, packs)
	if level == null:
		return null
	var no_twist: Array[Dictionary] = []
	var made: Battle = Battle.create(level, game.catalog, relaxed, no_twist)
	if made == null:
		return null
	var ids: Array[String] = []
	for id: StringName in pool:
		ids.append(String(id))
	var saved: Dictionary = {"format": RunSession.FORMAT, "seed": run_seed, "day": "", "pool": ids, "picks": []}
	if tier > 0:
		saved["tier"] = tier
	return RunSession.from_data(saved, made, game.run)


static func _tier_sum(b: Battle) -> int:
	var total: int = 0
	for tower: TowerState in b.towers:
		total += tower.tier
	return total


static func _names(lists: Array) -> Array:
	var out: Array = []
	for list: Array in lists:
		var row: Array = []
		for id: StringName in list:
			row.append(String(id))
		out.append(row)
	return out
