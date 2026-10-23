class_name Cage
extends RefCounted
## A company trap with a cat in it: to the company, cats are pests. A cat standing by it picks the
## lock, a little at a time, and if he leaves, the pick slips back. Opened, the cat inside has its
## say, each its own way, and runs for the jungle, home to the village.

## How close he has to stand, how long the lock takes, and how fast the pick slips back while
## nobody's at it, as a share of the lock a second.
const PICK_REACH := 0.6
const PICK_TIME := 3.0
const SLIP_RATE := 0.25
## How fast a freed cat runs for home.
const RUN_SPEED := 3.2
## Freed, a cat has its own way of saying thanks: grateful, a word and gone; chatty, talking until
## he tells it to go; or a fighter, throwing a firecracker at the horde on its way out. What each
## might say, and what he says back to a chatty one. They talk in bubbles while the fight goes on.
const TEMPERAMENTS: Array[String] = ["grateful", "chatty", "fighter"]
const SAYS := {
	"grateful": ["Thank you! I'll tell the village!", "You came! I knew someone would.", "Free! Thank you, thank you!",
		"I owe you a fish. A big one.", "Home! Which way is home? That way. Bye!"],
	"chatty": ["Oh thank goodness, the food in there was terrible, and the rats, and the noise...",
		"You won't believe what I saw: a giant, and a whistle, and my cousin says...",
		"I was only looking for mangoes, honestly, and then this box came down, and...",
		"Do you know how long I've been in there? Let me tell you, it started on a Tuesday..."],
	"cut_in": ["Not now. It's dangerous. Go!", "Tell me at home. Run!", "Later! Get to safety!"],
	"chatty_goes": ["Going, going!", "Right. Running now!", "Saving you a seat!"],
	"fighter": ["Thanks! And one for the rats!", "Take that, you pests! Thank you!", "Thank you! Duck!"],
}
## How long a freed cat stays by the cage, talking, before it runs: a grateful one a moment, a
## fighter long enough to throw, a chatty one until he's had his say. And when a fighter throws.
const LINGER := {"grateful": 0.9, "chatty": 3.6, "fighter": 1.3}
const THROW_AT := 0.5
## The cats a cage might hold: their names, and their coats.
const NAMES: Array[String] = ["Belang", "Kumis", "Manis", "Cemong", "Oyen", "Bulu", "Gembul", "Mochi", "Kenari", "Ciko", "Lintang"]
const COATS: Array[String] = ["orange", "gray", "black", "cream"]

var body := Body.new()
## How far the lock is picked, from 0 to 1, and in how many clicks so far, for the sound.
var picked := 0.0
var clicks := 0
var opened := false
## Who's inside: {name, coat}, and how it'll take being freed.
var prisoner := {}
var temperament := "grateful"
## Freed: how long ago, what's said and by whom, as {from, until, by ("freed" or "tompel"), text},
## whether a fighter has thrown yet, and what it throws.
var freed_for := 0.0
var talk: Array[Dictionary] = []
var thrown := false
var _thrower: Cat
## Once opened, the freed cat running for the jungle, until it's gone into it.
var runner := Body.new()
var home := false
## How far it has run, so its legs step with the ground it covers.
var ran := 0.0


func _init(random: RandomNumberGenerator) -> void:
	body.radius = 0.25
	body.tall = 0.35
	body.kind = "cage"
	prisoner = {"name": NAMES[random.randi_range(0, NAMES.size() - 1)], "coat": COATS[random.randi_range(0, COATS.size() - 1)]}
	temperament = TEMPERAMENTS[random.randi_range(0, TEMPERAMENTS.size() - 1)]
	var says := func(pool: String) -> String: return SAYS[pool][random.randi_range(0, SAYS[pool].size() - 1)]
	match temperament:
		"chatty":
			talk = [{"from": 0.0, "until": 1.9, "by": "freed", "text": says.call("chatty")},
				{"from": 1.9, "until": 3.4, "by": "tompel", "text": says.call("cut_in")},
				{"from": 3.4, "until": 4.6, "by": "freed", "text": says.call("chatty_goes")}]
		_:
			talk = [{"from": 0.0, "until": 1.8, "by": "freed", "text": says.call(temperament)}]
	runner.radius = Cat.RADIUS
	runner.tall = Cat.TALL


## Picks at the lock while he's by it, or slips back. Returns true on the step it opens.
func pick(delta: float, picking: bool) -> bool:
	if opened:
		return false
	picked = clampf(picked + (delta / PICK_TIME if picking else -delta * SLIP_RATE), 0.0, 1.0)
	clicks = maxi(clicks, floori(picked * 8.0))
	if picked < 1.0:
		return false
	opened = true
	runner.position = body.position
	freed_for = 0.0
	return true


## What's being said right now, as {by, text}, or nothing once it's all been said.
func saying() -> Dictionary:
	if not opened:
		return {}
	for line in talk:
		if freed_for >= line.from and freed_for < line.until:
			return line
	return {}


## A fighter, before it runs, throws a firecracker at the horde close by: a real one, lobbed, that
## lands and pops like any. Returns whether it threw.
func throw_at(arena: Arena) -> bool:
	if temperament != "fighter" or thrown or freed_for < THROW_AT:
		return false
	if _thrower == null:
		_thrower = Cat.new()
		_thrower.weapons.clear()
		_thrower.body = runner
	var firecrackers := Weapon.named("petasan")
	thrown = firecrackers.step(0.0, _thrower, arena, runner, 0.2)
	if freed_for >= LINGER.fighter:
		# Nothing in reach to throw at: it goes without.
		thrown = true
	return thrown


## The freed cat runs for the nearest edge of the clearing, and is home once it reaches it.
func run_home(delta: float, size: Vector2) -> void:
	if not opened or home:
		return
	freed_for += delta
	# It has its say first, by the cage.
	if freed_for < LINGER[temperament]:
		return
	var edges := [Vector2(runner.position.x, 0.0), Vector2(runner.position.x, size.y), Vector2(0.0, runner.position.y), Vector2(size.x, runner.position.y)]
	var nearest: Vector2 = edges[0]
	for edge: Vector2 in edges:
		if runner.position.distance_to(edge) < runner.position.distance_to(nearest):
			nearest = edge
	runner.velocity = (nearest - runner.position).normalized() * RUN_SPEED
	runner.position += runner.velocity * delta
	ran += RUN_SPEED * delta
	home = runner.position.distance_to(nearest) < 0.3
