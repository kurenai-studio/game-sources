extends Node
## The player's things that last between games (autoload "Profile"): settings,
## the hot dogs they've made in the dressing room, and the records.
## Saved to user://profile.json.

const PATH := "user://profile.json"
const VERSION := 3
## A first guess at a tablet's lag, its speaker's and its screen's, when the
## sound system doesn't say (Android); the game learns the real one as it's
## played (game/timing.gd).
const ANDROID_LAG := 0.12

var music_volume := 0.8
var sfx_volume := 0.9
var level := "easy"                ## easy (young players), junior or pro (Catalog.LEVELS)
var rivals := "gentle"             ## how good the computer's athletes are: gentle, keen, fierce, legendary
var assist := true                 ## show where to jump over hurdles, and the beat ring
var calibration := 0.0             ## seconds added to every tap (late screens/headphones)
var players := 1
var athletes: Array = []           ## the dressing room's hot dogs (looks + name)
var chosen := [0, 1, 2, 3]         ## which saved athlete each player (up to four on one tablet) uses
var records := {}                  ## event id -> {mark, name, nation, when}
var bests := {}                    ## event id -> the player's own best
var medals := {"gold": 0, "silver": 0, "bronze": 0}
var championships := 0
var series := "classic"            ## the set series the Games screen last picked
var custom: Array = []             ## the player's own series
var learn := true                  ## LEARN MODE: the events coach (what to press, and when)
## What's happened, for the dressing room's unlocks (game/wardrobe.gd): play,
## medals, golds, perfects, sizzles, games, records, together, tutorial.
var stats := {}
var unlocked: Array = []           ## "slot:id" of everything unlocked (for everyone on this tablet)
var fresh: Array = []              ## the unlocked things nobody has looked at yet (NEW!)
var path := PATH


func _ready() -> void:
	load_profile()


func reset() -> void:
	music_volume = 0.8
	sfx_volume = 0.9
	level = "easy"
	rivals = "gentle"
	assist = true
	calibration = default_lag()
	players = 1
	athletes = [default_athlete(), default_athlete(1), default_athlete(2), default_athlete(3)]
	chosen = [0, 1, 2, 3]
	records = {}
	bests = {}
	medals = {"gold": 0, "silver": 0, "bronze": 0}
	championships = 0
	series = "classic"
	custom = ["sprint", "long_jump", "hurdles"]
	learn = true
	stats = {}
	unlocked = []
	fresh = []


## The players' own hot dogs until they make their own: one each (the third
## and fourth for players who join from their phones).
static func default_athlete(player := 0) -> Dictionary:
	if player == 2:
		return {
			"name": "Chilli Dog", "nation": "ngc", "sausage": "chorizo", "bun": "poppy",
			"toppings": ["beans", "jalapeno"], "band": ["orange", "navy"], "eyes": "wide", "hair": "curly",
			"specs": "none", "tache": "none", "outfit": "bowtie",
		}
	if player == 3:
		return {
			"name": "Corny Joe", "nation": "ngc", "sausage": "corn", "bun": "none",
			"toppings": ["mustard"], "band": ["sky", "pink"], "eyes": "front", "hair": "flattop",
			"specs": "round", "tache": "handlebar",
		}
	if player == 1:
		return {
			"name": "Hot Diggity", "nation": "ngc", "sausage": "red", "bun": "sesame",
			"toppings": ["ketchup", "onion"], "band": ["lime", "purple"], "eyes": "look", "hair": "spikes",
			"specs": "neon", "tache": "none", "hat": "party",
		}
	return {
		"name": "Top Dog", "nation": "ngc", "sausage": "frank", "bun": "soft",
		"toppings": ["mustard"], "band": ["pink", "teal"], "eyes": "look", "hair": "none",
		"specs": "none", "tache": "none", "hat": "cap",
	}


func load_profile() -> void:
	reset()
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
	if not d is Dictionary:
		return
	music_volume = float(d.get("music_volume", music_volume))
	sfx_volume = float(d.get("sfx_volume", sfx_volume))
	level = String(d.get("level", level))
	rivals = String(d.get("rivals", rivals))
	assist = bool(d.get("assist", assist))
	calibration = float(d.get("calibration", calibration))
	# version 3: one set of rules for every player; only the computer's age band changes
	level = "easy"
	if int(d.get("version", 1)) < 2:
		# version 2: young players found JUNIOR too hard; and taps on Android
		# were judged without the tablet's lag
		if level == "junior":
			level = "easy"
		if absf(calibration) < 0.001:
			calibration = default_lag()
	players = clampi(int(d.get("players", players)), 1, 4)
	var a: Variant = d.get("athletes", [])
	if a is Array and not a.is_empty():
		athletes = a
	for k in 4:
		# a hot dog each for up to four players (the spares if the dressing room hasn't made them)
		if athletes.size() < 4:
			var d2 := default_athlete(k)
			if athletes.filter(func(x): return String(x.get("name", "")) == String(d2.name)).is_empty():
				athletes.append(d2)
	while athletes.size() < 4:
		athletes.append(default_athlete(athletes.size()))
	var c: Variant = d.get("chosen", chosen)
	if c is Array and not c.is_empty():
		chosen = []
		for k in 4:
			chosen.append(clampi(int(c[k]) if k < c.size() else k, 0, athletes.size() - 1))
	_distinct_choices()
	var r: Variant = d.get("records", {})
	records = r if r is Dictionary else {}
	var b: Variant = d.get("bests", {})
	bests = b if b is Dictionary else {}
	var m: Variant = d.get("medals", medals)
	if m is Dictionary:
		medals = m
	championships = int(d.get("championships", 0))
	series = String(d.get("series", series))
	var cu: Variant = d.get("custom", custom)
	if cu is Array and not cu.is_empty():
		custom = cu
	learn = bool(d.get("learn", learn))
	var st: Variant = d.get("stats", {})
	stats = st if st is Dictionary else {}
	var un: Variant = d.get("unlocked", [])
	unlocked = un if un is Array else []
	var fr: Variant = d.get("fresh", [])
	fresh = fr if fr is Array else []


static func default_lag() -> float:
	if OS.has_feature("android") and AudioServer.get_output_latency() < 0.01:
		return ANDROID_LAG
	return 0.0


func save() -> void:
	var d := {
		"version": VERSION, "music_volume": music_volume, "sfx_volume": sfx_volume, "level": level, "rivals": rivals,
		"assist": assist, "calibration": calibration, "players": players, "athletes": athletes,
		"chosen": chosen, "records": records, "bests": bests, "medals": medals,
		"championships": championships, "series": series, "custom": custom,
		"learn": learn, "stats": stats, "unlocked": unlocked, "fresh": fresh,
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, " "))


## Each player a different hot dog: a repeat moves to the first one not taken.
func _distinct_choices() -> void:
	var seen := {}
	for k in chosen.size():
		if seen.has(chosen[k]):
			for i in athletes.size():
				if not seen.has(i) and not chosen.has(i):
					chosen[k] = i
					break
		seen[chosen[k]] = true


func athlete(player: int) -> Dictionary:
	if athletes.is_empty():
		return default_athlete(player)
	var i: int = chosen[clampi(player, 0, chosen.size() - 1)]
	return athletes[clampi(i, 0, athletes.size() - 1)]


## The world record for an event: the profile's if someone beat it, else the
## one in data/events.json.
func record(id: String) -> Dictionary:
	if records.has(id):
		return records[id]
	var e := Catalog.event(id)
	return {"mark": float(e.get("record", 0.0)), "name": "", "nation": ""}


## Offer a mark: returns which of "record" and "best" it set.
func offer(id: String, mark: float, who: Dictionary) -> Array:
	var set := []
	if mark <= 0.0:
		return set
	var rec := record(id)
	if Catalog.better(id, mark, float(rec.mark)):
		records[id] = {"mark": mark, "name": String(who.get("name", "")), "nation": String(who.get("nation", "")),
			"when": Time.get_date_string_from_system()}
		set.append("record")
	if not bests.has(id) or Catalog.better(id, mark, float(bests[id])):
		bests[id] = mark
		set.append("best")
	if not set.is_empty():
		save()
	return set
