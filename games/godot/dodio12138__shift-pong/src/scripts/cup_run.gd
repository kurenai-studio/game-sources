extends RefCounted
## A knockout cup (杯赛): either
## singles (个人赛: you pick a player, bosses included, and go through a draw of
## 8 or 16) or teams (团体赛: you pick a club, or the legends team of the four
## bosses, in a draw of 8 playing Swaythling-style team ties). Its own freshly
## generated world; nothing is saved.

const Tour := preload("res://scripts/tour.gd")
const Roster := preload("res://scripts/roster.gd")
const People := preload("res://scripts/people.gd")
const Tie := preload("res://scripts/team_tie.gd")

const STAGE_NAMES := {16: "1/8 决赛", 8: "1/4 决赛", 4: "半决赛", 2: "决赛"}

var kind := "solo"          # "solo" | "team"
var world: Object           # a Tour holding the cup's own clubs
var entrants: Array = []    # player dicts (solo) or club dicts (team)
var mine := 0               # index of your entrant
var ties: Array = []        # this round: [[i, j], ...] into entrants
var alive: Array = []       # entrants still in, in draw order
var log: Array = []         # per round: lines
var hist: Array = []        # per round played: [{a, b, score, w}] (entrant indexes; w = the winner)
var bo := 5                 # games per match
var champion := -1


func _init() -> void:
	world = Tour.new()


## Singles candidates: the four bosses and the best thirty of the world.
func solo_pool() -> Array:
	var ps := []
	for c in world.clubs:
		ps.append_array(c.players)
	ps.sort_custom(func(x, y): return Roster.overall(x) > Roster.overall(y))
	return Roster.BOSSES.map(_boss) + ps.slice(0, 30)


static func _boss(b: Dictionary) -> Dictionary:
	var d: Dictionary = b.duplicate(true)
	People.ensure(d)
	return d


## Team candidates: the legends and the top eight clubs.
func team_pool() -> Array:
	var cs: Array = world.clubs.duplicate()
	cs.sort_custom(func(x, y): return _top3(x) > _top3(y))
	var legends := {"id": "legend", "name": "传奇明星队", "short": "传奇", "div": 1,
			"players": Roster.BOSSES.map(_boss)}
	return [legends] + cs.slice(0, 8)


static func _top3(c: Dictionary) -> float:
	var o: Array = c.players.map(func(p): return Roster.overall(p))
	o.sort()
	o.reverse()
	return float(o[0] + o[1] + o[2]) / 3.0


## Seeds the draw: the strongest entrants kept apart, you placed by strength.
func setup_solo(pool: Array, chosen: Dictionary, size: int, games: int) -> void:
	kind = "solo"
	bo = games
	var field := [chosen]
	for p in pool:
		if p.name != chosen.name and field.size() < size:
			field.append(p)
	_draw(field, chosen, func(p): return Roster.overall(p))


func setup_team(pool: Array, chosen: Dictionary) -> void:
	kind = "team"
	bo = 1
	var field := [chosen]
	for c in pool:
		if c.id != chosen.id and field.size() < 8:
			field.append(c)
	_draw(field, chosen, _top3)


## Standard seeding (1 v 8, 4 v 5, 2 v 7, 3 v 6 for eight), so the best two can
## only meet in the final.
func _draw(field: Array, chosen: Dictionary, strength: Callable) -> void:
	field.sort_custom(func(x, y): return strength.call(x) > strength.call(y))
	entrants = field
	mine = entrants.find(chosen)
	var order := _seed_order(field.size())
	alive = order
	ties = []
	for i in range(0, alive.size(), 2):
		ties.append([alive[i], alive[i + 1]])
	log = []
	hist = []
	champion = -1


static func _seed_order(n: int) -> Array:
	var o := [0, 1]
	while o.size() < n:
		var m := o.size() * 2
		var nx := []
		for s in o:
			nx.append(s)
			nx.append(m - 1 - s)
		o = nx
	return o


func stage_name() -> String:
	return STAGE_NAMES.get(ties.size() * 2, "决赛")


func is_over() -> bool:
	return champion >= 0


## Your tie this round, or -1 when you are out.
func my_tie() -> int:
	for i in ties.size():
		if ties[i].has(mine):
			return i
	return -1


func opponent() -> Dictionary:
	var t: Array = ties[my_tie()]
	return entrants[t[1] if t[0] == mine else t[0]]


func label(i: int) -> String:
	var e: Dictionary = entrants[i]
	if kind == "solo":
		return "%s（%d）" % [e.name, Roster.overall(e)]
	return "%s（%.0f）" % [e.name, _top3(e)]


## Plays the round: your result (`won`, games or ties for and against) when you
## are still in; the rest simulated. Winners go on to the next round.
func resolve(won: bool, mine_for: int, mine_against: int) -> void:
	var lines := []
	var winners := []
	var played := []
	var mi := my_tie()
	for i in ties.size():
		var t: Array = ties[i]
		var a_wins: bool
		var txt: String
		if i == mi:
			a_wins = won == (t[0] == mine)
			txt = "%d : %d" % ([mine_for, mine_against] if t[0] == mine else [mine_against, mine_for])
		elif kind == "solo":
			var r := Tour.sim_match(entrants[t[0]], entrants[t[1]], bo)
			a_wins = r[0] == 1
			txt = "%d : %d" % [r[1][0], r[1][1]]
		else:
			var tie: Object = world.sim_tie(entrants[t[0]], entrants[t[1]])
			a_wins = tie.wins[1] > tie.wins[-1]
			txt = "%d : %d" % [tie.wins[1], tie.wins[-1]]
		winners.append(t[0] if a_wins else t[1])
		played.append({"a": t[0], "b": t[1], "score": txt, "w": t[0] if a_wins else t[1]})
		lines.append("%s  %s  %s" % [label(t[0]), txt, label(t[1])])
	log.append([stage_name(), lines])
	hist.append(played)
	if winners.size() == 1:
		champion = winners[0]
		ties = []
		return
	ties = []
	for i in range(0, winners.size(), 2):
		ties.append([winners[i], winners[i + 1]])


## Simulates your own match of the round.
func sim_mine() -> void:
	var opp := opponent()
	var me: Dictionary = entrants[mine]
	if kind == "solo":
		var r := Tour.sim_match(me, opp, bo)
		resolve(r[0] == 1, r[1][0], r[1][1])
	else:
		var t: Object = world.sim_tie(me, opp)
		resolve(t.wins[1] > t.wins[-1], t.wins[1], t.wins[-1])
