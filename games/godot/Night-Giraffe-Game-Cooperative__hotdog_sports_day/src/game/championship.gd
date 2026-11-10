class_name Championship
extends RefCounted
## The Games: a set series of events in order (data/series.json). Each event has four in it: the
## players and the best of the other nations at that event. A player who
## doesn't reach an event's qualifying mark loses a bun; with no buns left the
## championship is over. Medals go on the nations' table as they're won.

var level := "junior"
var rivals := "keen"
var players: Array = []          ## the players' athletes (looks, names, nations)
var order: Array = []
var index := 0
var buns := 3
var medals := {}                 ## nation -> {gold, silver, bronze}
var history: Array = []          ## per event: {id, standings: [{name, nation, mark, human}]}
var rng := RandomNumberGenerator.new()
var seed := 1


func setup(p_players: Array, p_level: String, p_seed := 0, p_order: Array = []) -> void:
	players = p_players
	level = p_level
	order = p_order if not p_order.is_empty() else Catalog.order()
	seed = p_seed if p_seed != 0 else int(Time.get_unix_time_from_system()) % 100000
	rng.seed = seed
	for n in Catalog.nations():
		medals[n.id] = {"gold": 0, "silver": 0, "bronze": 0}
	for p in players:
		medals[String(p.get("nation", "ngc"))] = {"gold": 0, "silver": 0, "bronze": 0}


func current() -> String:
	return String(order[index]) if index < order.size() else ""


func over() -> bool:
	return index >= order.size() or buns <= 0


const RIVALS := ["gentle", "keen", "fierce", "legendary"]


## How steady a computer athlete is at a rivals setting: gentle ones wobble a
## lot, legendary ones hardly ever.
## How good the computer is, by the age of whoever's playing (the studio's
## age bands): the players' own rules are the same at every age.
const AGES := {"gentle": "AGES 5-7", "keen": "AGES 8-10", "fierce": "AGES 11-13", "legendary": "AGES 14+"}


static func age_label(rivals: String) -> String:
	return String(AGES.get(rivals, "AGES 5-7"))


## In a race the older bands' computer also runs a little faster than its
## bouncing alone would take it, so tapping flat out (and then some) is what
## beats it: about 3 taps a second at 5-7, 4 at 8-10, 5-6 at 11-13, 7+ at 14+.
static func boost_at(rivals: String) -> float:
	return float({"gentle": 0.0, "keen": 0.0, "fierce": 0.06, "legendary": 0.12}.get(rivals, 0.0))


static func skill_at(skill: float, rivals: String) -> float:
	match rivals:
		"gentle":
			return skill * 0.12
		"keen":
			return skill * 0.45
		"fierce":
			return skill * 0.75
		"legendary":
			return minf(0.995, skill + 0.04)
	return skill


## The four for an event: the players, then the nations who shine at it, then
## others, never a player's own nation twice.
static func entrants_for(id: String, p_players: Array, rng_: RandomNumberGenerator, lanes := 4, rivals := "fierce") -> Array:
	var out: Array = []
	var taken := {}
	for i in p_players.size():
		var p: Dictionary = p_players[i]
		out.append({"name": p.get("name", "Player %d" % (i + 1)), "nation": p.get("nation", "ngc"), "cpu": false,
			"skill": 1.0, "look": p, "player": i})
		taken[String(p.get("nation", "ngc"))] = true
	var pool: Array = []
	for n in Catalog.nations():
		pool.append({"n": n, "key": (10.0 if specialist(n, id) else 0.0) + rng_.randf()})
	pool.sort_custom(func(a, b): return float(a.key) > float(b.key))
	pool = pool.map(func(p): return p.n)
	for n in pool:
		if out.size() >= lanes:
			break
		if taken.has(String(n.id)):
			continue
		taken[String(n.id)] = true
		var skill := float(n.get("skill", 0.8))
		if specialist(n, id):
			skill = minf(0.99, skill + 0.05)
		skill = skill_at(skill, rivals)
		out.append({"name": n.athlete, "nation": n.id, "cpu": true, "skill": skill, "look": look_of(n), "player": -1,
			"boost": boost_at(rivals)})
	return out


static func specialist(n: Dictionary, id: String) -> bool:
	return n.get("best", "") == id or id in n.get("also", [])


static func look_of(n: Dictionary) -> Dictionary:
	return {"name": n.get("athlete", "?"), "nation": n.get("id", "ngc"), "sausage": n.get("sausage", "frank"),
		"bun": n.get("bun", "soft"), "toppings": n.get("toppings", []), "band": n.get("band", ["red", "white"]),
		"hair": n.get("hair", "none"), "specs": n.get("specs", "none"), "tache": n.get("tache", "none")}


func entrants() -> Array:
	return entrants_for(current(), players, rng, 4, rivals)


## After an event: a bun off if no player qualified (and the event is run
## again, so its medals only go onto the table when it stands: someone
## qualified, or that was the last bun).
## Returns {qualified: [player bools], any, medals: [nation per place]}.
func finish(meet: Meet) -> Dictionary:
	var q: Array = []
	var any := false
	for h in meet.humans():
		var ok := meet.qualified(h)
		q.append(ok)
		any = any or ok
	if not any:
		buns -= 1
	else:
		index += 1
	if not any and buns > 0:
		return {"qualified": q, "any": any, "medals": []}
	var st := meet.standings()
	var places := ["gold", "silver", "bronze"]
	var row: Array = []
	var won: Array = []
	for p in st.size():
		var i: int = st[p]
		var e: Dictionary = meet.entrants[i]
		var mark := meet.best(i)
		var no_mark := (meet.kind == "race" and not meet.times.has(i)) or (meet.kind != "race" and mark <= 0.0)
		if p < 3 and not no_mark:
			var nat := String(e.get("nation", "ngc"))
			if not medals.has(nat):
				medals[nat] = {"gold": 0, "silver": 0, "bronze": 0}
			medals[nat][places[p]] += 1
			won.append(nat)
		row.append({"name": e.get("name", "?"), "nation": e.get("nation", "ngc"), "mark": mark,
			"human": int(e.get("player", -1)) >= 0})
	history.append({"id": meet.id, "standings": row})
	return {"qualified": q, "any": any, "medals": won}


## The nations, most golds first (then silvers, then bronzes).
func table() -> Array:
	var rows: Array = []
	for nat in medals:
		var m: Dictionary = medals[nat]
		if m.gold + m.silver + m.bronze > 0:
			rows.append({"nation": nat, "gold": m.gold, "silver": m.silver, "bronze": m.bronze})
	rows.sort_custom(func(a, b):
		if a.gold != b.gold:
			return a.gold > b.gold
		if a.silver != b.silver:
			return a.silver > b.silver
		return a.bronze > b.bronze)
	return rows
