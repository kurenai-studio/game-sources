extends RefCounted
## A team tie (团体赛): three singles players a side, five singles in the
## Swaythling order A-X, B-Y, C-Z, A-Y, B-X, each a single game, first club to
## three wins — so even a 3:0 has all six players on the table once. Line-ups
## are handed in blind (田忌赛马); a good assistant coach finds out some of the
## other side's slots beforehand. Also the coach's instructions and how the AI
## coach picks them.

const Roster := preload("res://scripts/roster.gd")

const ORDER := [[0, 0], [1, 1], [2, 2], [0, 1], [1, 0]]
const SLOTS_HOME := ["A", "B", "C"]
const SLOTS_AWAY := ["X", "Y", "Z"]
const ORDERS := {
	"": {"name": "自由发挥", "desc": "按自己的习惯打"},
	"press_bh": {"name": "压反手", "desc": "落点集中对方反手位"},
	"wide_fh": {"name": "调动正手大角", "desc": "先压反手再变正手大角"},
	"attack": {"name": "积极上手", "desc": "多拉多冲，敢发力；失误也会多一些"},
	"steady": {"name": "稳住少失误", "desc": "降一点速度，控制落点"},
	"serve_attack": {"name": "发短下旋抢攻", "desc": "发短下旋，第三板抢攻"},
}
const ORDER_KEYS := ["", "press_bh", "wide_fh", "attack", "steady", "serve_attack"]

var home: Dictionary
var away: Dictionary
var home_line: Array = []     # three player dicts, A B C
var away_line: Array = []     # X Y Z
var best_of := 3
var results: Array = []       # per finished match: {"winner": 1 | -1, "games": [h, a], "scores": [...]}
var wins := {1: 0, -1: 0}     # 1 = home (your club), -1 = away


func setup(home_club: Dictionary, away_club: Dictionary, line: Array, bo: int, their_line: Array = []) -> void:
	home = home_club
	away = away_club
	home_line = line
	away_line = their_line if their_line.size() == 3 else ai_lineup(away_club)
	best_of = bo
	results = []
	wins = {1: 0, -1: 0}


func index() -> int:
	return results.size()


func is_over() -> bool:
	return wins[1] >= 3 or wins[-1] >= 3


## [home player, away player] of match `i` (default: the next one).
func pair(i := -1) -> Array:
	if i < 0:
		i = index()
	return [home_line[ORDER[i][0]], away_line[ORDER[i][1]]]


func record(winner: int, games: Array, scores: Array) -> void:
	results.append({"winner": winner, "games": games, "scores": scores})
	wins[winner] += 1


## The AI coach's line-up: the best two fit players take A/B (they play
## twice), with a little bluffing on who goes first; the weakest sits out.
static func ai_lineup(c: Dictionary) -> Array:
	var ps: Array = c.players.filter(func(p): return p.get("injured", 0) <= 0)
	if ps.size() < 3:
		ps = c.players.duplicate()   # not enough fit players: the injured have to play
	# your squad roles count (主力 first, 替补 last); other clubs just go by form
	var pick := func(p: Dictionary) -> float:
		return Roster.overall(Roster.effective(p)) + {"star": 8.0, "rotation": 0.0, "reserve": -8.0}.get(p.get("role", ""), 0.0)
	ps.sort_custom(func(x, y): return pick.call(x) > pick.call(y))
	var line := [ps[0], ps[1], ps[2]]
	if randf() < 0.4:
		line = [ps[1], ps[0], ps[2]]
	return line


## The AI coach's instruction, from how the points have gone: where the other
## player has been losing points (`their_weak` = {"fh", "bh"} counts), how many
## points we gave away ourselves, and the other player's ratings.
static func ai_order(their_weak: Dictionary, own_errors: int, them: Dictionary) -> String:
	if own_errors >= 6:
		return "steady"
	if their_weak.bh >= their_weak.fh + 2:
		return "press_bh"
	if their_weak.fh >= their_weak.bh + 2:
		return "wide_fh"
	return suggest(them)


## The plan the scouting points to against `them`: the weaker wing, a shaky
## receive, nerves; otherwise just keep it tight.
static func suggest(them: Dictionary) -> String:
	var fh := Roster.attr(them, "fh")
	var bh := Roster.attr(them, "bh")
	if bh + 4 <= fh:
		return "press_bh"
	if fh + 4 <= bh:
		return "wide_fh"
	if Roster.attr(them, "receive") <= 72:
		return "serve_attack"
	if Roster.attr(them, "mental") <= 68:
		return "attack"
	return "steady"
