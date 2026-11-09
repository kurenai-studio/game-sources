extends RefCounted
## The tour the cups are played on: the hand-made clubs and a
## generated set of others, each with three or more players. Your club is the
## first. Matches you don't play are simulated from the ratings.

const Roster := preload("res://scripts/roster.gd")
const People := preload("res://scripts/people.gd")
const Skills := preload("res://scripts/skills.gd")

const BEST_OF := 1              # every match in a tie is a single game to 11

var clubs: Array = []           # every club, yours first


func _init() -> void:
	var taken := []
	for c in Roster.CLUBS:
		var cc: Dictionary = c.duplicate(true)
		for p in cc.players:
			People.ensure(p)   # plain String keys: dot assignment would add StringName keys get() misses
			taken.append(p.name)
		clubs.append(cc)
	clubs.append_array(People.generate_world(taken).clubs)


func mine() -> Dictionary:
	return clubs[0]


func club(id: String) -> Dictionary:
	for c in clubs:
		if c.id == id:
			return c
	return clubs[0]


## Chance that `a` beats `b` in one game, from ratings as they stand today.
static func game_p(a: Dictionary, b: Dictionary) -> float:
	var d := Roster.overall(Roster.effective(a)) - Roster.overall(Roster.effective(b))
	d += 0.6 * (Skills.known(a).size() - Skills.known(b).size())   # techniques win the odd point
	d -= 0.5 * (Skills.flaws(a).size() - Skills.flaws(b).size())   # weak spots lose one
	return 1.0 / (1.0 + exp(-d / 6.0))


## One simulated match: [winner 1 | -1, [games a, games b], scores].
static func sim_match(a: Dictionary, b: Dictionary, bo: int) -> Array:
	var g := [0, 0]
	var scores := []
	var p := game_p(a, b)
	while g[0] <= bo / 2 and g[1] <= bo / 2:
		var a_wins := randf() < p
		var lose := randi_range(3, 9)
		var s := [11, lose]
		if randf() < 0.18:
			var x := randi_range(10, 13)
			s = [x + 2, x]
		g[0 if a_wins else 1] += 1
		scores.append("%d:%d" % ([s[0], s[1]] if a_wins else [s[1], s[0]]))
	return [1 if g[0] > g[1] else -1, g, scores]


## A match rating out of 10 for one side (`k` 0 = home) of a finished match:
## winning, the margin in games and points, and beating someone better.
static func rate(r: Dictionary, k: int, own: Dictionary, opp: Dictionary) -> float:
	var won: bool = r.winner == (1 if k == 0 else -1)
	var gf: int = r.games[k]
	var ga: int = r.games[1 - k]
	var pts := 0
	for sc in r.scores:
		var ab: PackedStringArray = str(sc).split(":")
		pts += int(ab[k]) - int(ab[1 - k])
	var x := 6.0 + (0.9 if won else -0.8) + 0.3 * (gf - ga) + 0.04 * pts + 0.03 * (Roster.overall(opp) - Roster.overall(own))
	return snappedf(clampf(x, 3.0, 10.0), 0.1)
