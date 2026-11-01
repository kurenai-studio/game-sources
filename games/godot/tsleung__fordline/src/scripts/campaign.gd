class_name Campaign
extends RefCounted
## The run: five battles, a roster that carries its losses, rewards between
## battles. Pure: every function takes run state and returns new state.

const K := UnitTypes.Kind

const BATTLES := [
	{
		"name": "Millbrook Ford", "map": "fords", "persona": "balanced",
		"brief": "Three fords, one small army. Take the crossings.",
		"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.CAVALRY, 0]],
	},
	{
		"name": "Ashwood", "map": "woods", "persona": "aggressive",
		"brief": "No river, thick woods. Their horse will come early.",
		"enemy": [[K.SWORDS, 0], [K.SWORDS, 0], [K.PIKES, 0], [K.ARCHERS, 0], [K.CAVALRY, 0], [K.CAVALRY, 0]],
	},
	{
		"name": "Two Bridges", "map": "bridges", "persona": "dug_in",
		"brief": "They hold the far bank with bows and a battery. Force a bridge.",
		"enemy": [[K.SWORDS, 1], [K.PIKES, 0], [K.PIKES, 1], [K.ARCHERS, 1], [K.ARCHERS, 0], [K.CANNONS, 0], [K.CAVALRY, 0], [K.SWORDS, 0]],
	},
	{
		"name": "Saltmarsh Road", "map": "roads", "persona": "flanker",
		"brief": "A bigger army that likes to ride around the edges.",
		"enemy": [[K.SWORDS, 1], [K.SWORDS, 1], [K.SWORDS, 0], [K.PIKES, 1], [K.PIKES, 0], [K.ARCHERS, 1], [K.ARCHERS, 0], [K.CANNONS, 1], [K.CAVALRY, 1], [K.CAVALRY, 0]],
	},
	{
		"name": "Marshal's Ridge", "map": "ridge", "persona": "balanced",
		"brief": "The Marshal and his guard. Break them and the war is won.",
		"enemy": [[K.SWORDS, 3], [K.SWORDS, 2], [K.SWORDS, 1], [K.PIKES, 2], [K.PIKES, 1], [K.ARCHERS, 2], [K.ARCHERS, 1], [K.ARCHERS, 1], [K.CANNONS, 2], [K.CANNONS, 1], [K.CAVALRY, 2], [K.CAVALRY, 1]],
		"general_stars": 3,
	},
]

const START_ROSTER := [K.SWORDS, K.SWORDS, K.PIKES, K.ARCHERS, K.ARCHERS, K.CAVALRY]
const REFILL := 0.4
const FLED_SURVIVE := 0.5

const DOCTRINES := {
	"longbows": {"title": "Longbows", "text": "Archers shoot 25% farther.", "set": {"range_2": 1.25}},
	"iron_shot": {"title": "Iron shot", "text": "Cannons reload 30% faster.", "set": {"reload_4": 0.7}},
	"steel": {"title": "Steel plate", "text": "Swords and pikes shrug off 10% more damage.", "add": {"def_0": 0.1, "def_1": 0.1}},
	"warhorses": {"title": "Warhorses", "text": "Cavalry 15% faster and 15% harder hitting.", "set": {"speed_3": 1.15, "atk_3": 1.15}},
	"old_banners": {"title": "Old banners", "text": "Every regiment starts with more nerve.", "add": {"morale": 12.0}},
	"drill": {"title": "Drill", "text": "Swords and pikes hit 12% harder.", "set": {"atk_0": 1.12, "atk_1": 1.12}},
}

const ABILITIES := {
	"barrage": {"title": "Barrage", "text": "Call six shells onto any point. Long cooldown."},
	"march": {"title": "Forced march", "text": "Selected regiments move 60% faster for ten seconds."},
}


static func new_run(seed_value: int) -> Dictionary:
	var roster: Array = []
	roster.append(_regiment(K.GENERAL, 0))
	for k in START_ROSTER:
		roster.append(_regiment(k, 0))
	return {
		"seed": seed_value, "battle": 0, "roster": roster, "doctrine": {},
		"doctrines": [], "abilities": ["rally"], "score": 0, "kills": 0,
		"log": [], "over": false, "won": false,
	}


static func _regiment(kind: int, stars: int) -> Dictionary:
	return {"kind": kind, "men": UnitTypes.stat(kind, "men"), "stars": stars, "kills": 0}


static func current(run: Dictionary) -> Dictionary:
	return BATTLES[run.battle]


static func battle_seed(run: Dictionary) -> int:
	return hash([run.seed, run.battle])


## The enemy for the current battle: the battle's list, with one regiment
## swapped at random from the second battle on, so no two runs match.
static func enemy_army(run: Dictionary) -> Array:
	var spec: Dictionary = current(run)
	var rng := RandomNumberGenerator.new()
	rng.seed = battle_seed(run) + 7
	var army: Array = []
	army.append(_regiment(K.GENERAL, spec.get("general_stars", 0)))
	for e in spec.enemy:
		army.append(_regiment(e[0], e[1]))
	if run.battle >= 1:
		var i := rng.randi_range(1, army.size() - 1)
		var kind: int = UnitTypes.RECRUITABLE[rng.randi() % UnitTypes.RECRUITABLE.size()]
		army[i] = _regiment(kind, army[i].stars)
	return army


## Fold a finished battle into the run. `result`:
## {"won": bool, "time": float, "kills": int,
##  "units": [{"roster_index", "men", "kills", "fled"}]}
static func after_battle(run: Dictionary, result: Dictionary) -> Dictionary:
	var out := run.duplicate(true)
	var by_index := {}
	for u in result.units:
		by_index[u.roster_index] = u
	var roster: Array = []
	var survivors := 0
	for i in run.roster.size():
		var reg: Dictionary = run.roster[i].duplicate()
		var u: Dictionary = by_index.get(i, {})
		if u.is_empty():
			continue
		var men: int = u.men
		if u.fled:
			men = int(men * FLED_SURVIVE)
		survivors += men
		if men <= 0:
			continue
		var full: int = UnitTypes.stat(reg.kind, "men")
		reg.kills += u.kills
		reg.stars = maxi(reg.stars, Combat.stars_for_kills(reg.kills))
		reg.men = mini(full, men + int(ceil((full - men) * REFILL)))
		roster.append(reg)
	out.roster = roster
	out.kills += result.kills
	var gained: int = 2 * result.kills + survivors
	if result.won:
		gained += 1000 + int(maxf(0.0, 180.0 - result.time) * 3.0)
	out.score += gained
	out.log.append({
		"name": current(run).name, "won": result.won, "time": result.time,
		"kills": result.kills, "score": gained,
	})
	var has_general := roster.any(func(r): return r.kind == K.GENERAL)
	if not has_general:
		roster.push_front(_regiment(K.GENERAL, 0))
	if not result.won:
		out.over = true
	elif run.battle == BATTLES.size() - 1:
		out.over = true
		out.won = true
	return out


static func advance(run: Dictionary) -> Dictionary:
	var out := run.duplicate(true)
	out.battle += 1
	return out


## Three different rewards; at least one is a new regiment.
static func offer_rewards(run: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = battle_seed(run) + 31
	var pool: Array = []
	for k in UnitTypes.RECRUITABLE:
		pool.append({"id": "recruit", "kind": k, "title": "Recruit " + UnitTypes.label(k), "text": _recruit_text(k)})
	pool.append({"id": "muster", "title": "Full muster", "text": "Every regiment back to full strength."})
	for name in ABILITIES:
		if not name in run.abilities:
			pool.append({"id": "ability", "name": name, "title": ABILITIES[name].title, "text": ABILITIES[name].text})
	for name in DOCTRINES:
		if not name in run.doctrines:
			pool.append({"id": "doctrine", "name": name, "title": DOCTRINES[name].title, "text": DOCTRINES[name].text})
	var recruits := pool.filter(func(r): return r.id == "recruit")
	var first: Dictionary = recruits[rng.randi() % recruits.size()]
	var picks: Array = [first]
	pool.erase(first)
	var recruits_picked := 1
	while picks.size() < 3 and not pool.is_empty():
		var p: Dictionary = pool[rng.randi() % pool.size()]
		pool.erase(p)
		if p.id == "recruit":
			if recruits_picked >= 2:
				continue
			recruits_picked += 1
		picks.append(p)
	return picks


## A battle for the run's current fight, both armies deployed.
static func make_battle(run: Dictionary) -> Battle:
	var spec := current(run)
	var seed_value := battle_seed(run)
	var b := Battle.new(Terrain.generate(spec.map, seed_value), seed_value)
	b.abilities.assign(run.abilities)
	var mid := b.terrain.size * 0.5
	for i in run.roster.size():
		var reg: Dictionary = run.roster[i]
		b.add_regiment(0, reg.kind, reg.men, mid, -PI * 0.5, reg.stars, run.doctrine, i)
	for reg in enemy_army(run):
		b.add_regiment(1, reg.kind, reg.men, mid, PI * 0.5, reg.stars, {})
	b.apply_orders(AI.deploy_orders(b, 0))
	b.apply_orders(AI.deploy_orders(b, 1))
	return b


## What the run needs to know about a finished battle.
static func battle_result(b: Battle) -> Dictionary:
	var units: Array = []
	for r in b.regiments:
		if r.team != 0 or r.roster_index < 0:
			continue
		units.append({"roster_index": r.roster_index, "men": r.men(), "kills": r.kills, "fled": r.fled or r.state == Regiment.State.ROUTING})
	return {"won": b.winner == 0, "time": b.time, "kills": b.killed[0], "units": units}


static func _recruit_text(kind: int) -> String:
	match kind:
		K.SWORDS:
			return "Line infantry. Beats pikes."
		K.PIKES:
			return "Holds the line. Stops cavalry dead."
		K.ARCHERS:
			return "Volleys from range. Hates being caught."
		K.CAVALRY:
			return "Fast. Charges flanks, rides down archers."
		K.CANNONS:
			return "Two guns. Long range, shakes morale."
	return ""


static func apply_reward(run: Dictionary, reward: Dictionary) -> Dictionary:
	var out := run.duplicate(true)
	match reward.id:
		"recruit":
			out.roster.append(_regiment(reward.kind, 0))
		"muster":
			for reg in out.roster:
				reg.men = UnitTypes.stat(reg.kind, "men")
		"ability":
			out.abilities.append(reward.name)
		"doctrine":
			out.doctrines.append(reward.name)
			var d: Dictionary = DOCTRINES[reward.name]
			for key in d.get("set", {}):
				out.doctrine[key] = out.doctrine.get(key, 1.0) * d.set[key]
			for key in d.get("add", {}):
				out.doctrine[key] = out.doctrine.get(key, 0.0) + d.add[key]
	return out
