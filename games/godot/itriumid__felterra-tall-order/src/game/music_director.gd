class_name MusicDirector
extends Node
## Plays the soundtrack's layers together, in step, and fades each to what the run calls for:
## drums and bass always; chords, then the lead, as the horde thickens around him; the gamelan
## answering throughout; the rock layer whenever a giant is on his feet. In the pause menu it all
## drops back. In the village the village's own layers play instead, and walking out to a run
## crossfades from one to the other. On the title and through the story's opening, the opening's
## own music plays, mellow, until he reaches the village. Real music
## replaces the layers one for one; this stays.

## How far around him the horde counts toward the music, in meters, and how fast layers fade.
const NEAR := 6.0
const FADE := 1.5
const PAUSED_SHARE := 0.35

var arena: Arena
var cat: Cat
## Where he is: "run" in the clearing, "village" in the village, "intro" on the title and
## through any story told going in, "freed" as an area is freed.
var place := "run"
var _players := {}
var _levels := {}


func setup() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layers := MusicKit.make_all()
	layers.merge(MusicKit.make_village())
	layers.merge(MusicKit.make_intro())
	layers.merge(MusicKit.make_freed())
	for layer: String in layers:
		var player := AudioStreamPlayer.new()
		player.stream = layers[layer]
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_players[layer] = player
		_levels[layer] = 0.0
	# All together, so every layer keeps the same beat.
	for layer: String in _players:
		_players[layer].play()


## How loud each layer should be, 0 to 1, from how thick the horde is around him, whether a giant
## is standing, and whether the game is paused.
static func targets(horde_near: int, giant_standing: bool, paused: bool, where := "run") -> Dictionary:
	if where != "run":
		var calm := {}
		for layer in MusicKit.LAYERS + MusicKit.VILLAGE_LAYERS + MusicKit.INTRO_LAYERS + MusicKit.FREED_LAYERS:
			calm[layer] = 0.0
		var playing: Array[String] = {"village": MusicKit.VILLAGE_LAYERS, "freed": MusicKit.FREED_LAYERS}.get(where, MusicKit.INTRO_LAYERS)
		for layer in playing:
			calm[layer] = PAUSED_SHARE if paused else 1.0
		return calm
	var levels := {
		"drums": 1.0, "bass": 1.0,
		"chords": clampf(horde_near / 15.0, 0.0, 1.0),
		"lead": clampf((horde_near - 8) / 20.0, 0.0, 1.0),
		"gamelan": 0.75,
		"rock": 1.0 if giant_standing else 0.0,
	}
	for layer in MusicKit.VILLAGE_LAYERS + MusicKit.INTRO_LAYERS + MusicKit.FREED_LAYERS:
		levels[layer] = 0.0
	if paused:
		for layer: String in levels:
			levels[layer] *= PAUSED_SHARE
	return levels


func _process(delta: float) -> void:
	if _players.is_empty():
		return
	if place != "run":
		_fade(targets(0, false, get_tree().paused, place), delta)
		return
	if arena == null:
		return
	# Behind the title there's no cat: the horde around him counts as none.
	var near := 0
	if cat != null:
		for creature in arena.creatures:
			if creature.body.position.distance_to(cat.body.position) < NEAR:
				near += 1
	# A machine at work counts as a giant: the rock comes in for it too.
	var giant := arena.giants.any(func(each: Giant) -> bool: return each.standing()) \
			or arena.machines.any(func(each: Machine) -> bool: return each.standing())
	_fade(targets(near, giant, get_tree().paused), delta)


func _fade(wanted: Dictionary, delta: float) -> void:
	for layer: String in _players:
		_levels[layer] = move_toward(_levels[layer], wanted[layer], delta * FADE)
		_players[layer].volume_db = linear_to_db(maxf(_levels[layer], 0.0001))
