extends RefCounted
## SHIFT RUN (the jam's main mode): six opponents in a row, each a single game
## to 7, the last one a legend. The ladder is set by the player you take in:
## from well below them up to a little above, the legend brought down (or up)
## to a few points over them, so any pick makes the same climb. You start with your loadout of four skills;
## after every win three new ones are offered and one may be shifted in for one
## you have. Two hearts: a loss costs one and the same opponent comes again;
## with none left the run is over.

const Roster := preload("res://scripts/roster.gd")
const People := preload("res://scripts/people.gd")
const Tour := preload("res://scripts/tour.gd")

const STAGES := 6
const HEARTS := 2
const GAME_TO := 7                 # points a game in a run
const STEPS := [-12, -8, -5, -2, 2]  # each field opponent's overall, against yours
const BOSS_OVER := 6               # the legend's overall, against yours

var me: Dictionary                 # the player you took in
var ladder: Array = []             # the opponents, weakest first; the last a legend
var stage := 0                     # the next opponent (index into ladder)
var hearts := HEARTS
var loadout: Array = []            # skill ids, as in the settings
var offer: Array = []              # skill ids offered after a win (empty when none waits)
var log: Array = []                # per match played: {stage, won, score}


func _init(player: Dictionary, start_loadout: Array) -> void:
	me = player
	loadout = start_loadout.duplicate()
	var tour := Tour.new()
	var pool := []
	for c in tour.clubs:
		for p in c.players:
			if p.name != me.name:
				pool.append(p)
	var mine := Roster.overall(me)
	# five from the field, each the one nearest its step that isn't taken yet
	for step in STEPS:
		var best: Dictionary = pool[0]
		for p in pool:
			if absi(Roster.overall(p) - (mine + step)) < absi(Roster.overall(best) - (mine + step)):
				best = p
		ladder.append(best)
		pool.erase(best)
	var b: Dictionary = Roster.BOSSES.pick_random().duplicate(true)
	_rate_to(b, mine + BOSS_OVER)
	People.ensure(b)
	ladder.append(b)


## Scales all of a player's ratings so their overall comes out near `target`.
static func _rate_to(p: Dictionary, target: int) -> void:
	for i in 4:   # overall isn't quite linear in the ratings: a few passes settle it
		var k := float(target) / float(maxi(Roster.overall(p), 1))
		p.a = p.a.map(func(v): return clampf(roundf(v * k), 40.0, 99.0))


func opponent() -> Dictionary:
	return ladder[mini(stage, ladder.size() - 1)]


func is_boss() -> bool:
	return stage == STAGES - 1


func is_over() -> bool:
	return hearts <= 0 or stage >= STAGES


func won_all() -> bool:
	return stage >= STAGES


## The match against this stage's opponent is over.
func resolve(won: bool, score: String, all_ids: Array) -> void:
	log.append({"stage": stage, "won": won, "score": score})
	if won:
		stage += 1
		if stage < STAGES:
			var fresh := all_ids.filter(func(id): return not loadout.has(id))
			fresh.shuffle()
			offer = fresh.slice(0, 3)
	else:
		hearts -= 1


## Takes offered skill `id` in place of loadout slot `slot`.
func take(id: String, slot: int) -> void:
	loadout[slot] = id
	offer = []
