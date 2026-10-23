class_name AudioDirector
extends Node
## Plays the game's sounds from what the simulation does: a shot for each round fired, a whoosh
## for each swing, a thud for each hit (small for a rat, deep for a giant), a giant's footfalls in
## step with his stride. Sounds in the world sit where they happen and fade with distance; the
## interface's play flat. Voices are limited per sound, so a horde doesn't drown everything.

## Players for sounds in the world, and the most of any one sound playing at once.
const VOICES := 24
const LIMITS := {"squeak": 3, "hit_small": 6, "footstep_giant": 4, "swing": 4, "bite": 3, "bark": 3}
const DEFAULT_LIMIT := 4
## What each weapon sounds like firing, and how its swing is pitched: deeper for the heavy, quicker
## for the light.
const SHOTS := {
	"submachine_gun": "shot_submachine_gun", "rifle": "shot_rifle", "automatic_rifle": "shot_rifle",
	"assault_rifle": "shot_rifle", "sniper_rifle": "shot_heavy", "shotgun": "shot_heavy",
	"crossbow": "shot_twang", "panah": "shot_twang", "ketapel": "shot_twang", "sumpit": "shot_puff",
	"grenade_launcher": "shot_thunk", "lamp_oil": "shot_thunk", "petasan": "shot_thunk",
	"nail_gun": "shot_nail", "flare_gun": "shot_flare",
}
const SWING_PITCHES := {
	"nunchaku": 1.15, "keris": 0.85, "kerambit": 1.25, "greatsword": 0.6, "rattan_staff": 0.7, "mandau": 0.8,
	"machete": 0.9, "golok": 0.85, "tombak": 0.9, "bambu_runcing": 0.95, "rencong": 1.3,
	"badik": 1.2, "celurit": 1.05, "kujang": 1.0,
}
## Ground a giant covers between footfalls, in meters: half his stride.
const GIANT_STEP := 0.7

var arena: Arena
var _world: Node2D
var _voices: Array[AudioStreamPlayer2D] = []
var _interface: Array[AudioStreamPlayer] = []
var _seen := {}
## How many times each sound has played: what a test or a probe can check, since nobody can hear
## a headless run.
var played := {}
## The worker making every sound as the game starts, until it's done (-1 after).
var _making := -1


func setup(world: Node2D) -> void:
	_world = world
	# Every sound made off the main thread while the game starts, not on its first play mid-fight.
	_making = WorkerThreadPool.add_task(_make_sounds)
	for index in VOICES:
		var voice := AudioStreamPlayer2D.new()
		voice.bus = "Effects"
		voice.max_distance = 900.0
		voice.attenuation = 1.6
		_world.add_child(voice)
		_voices.append(voice)
	for index in 4:
		var player := AudioStreamPlayer.new()
		player.bus = "Interface"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_interface.append(player)


func _make_sounds() -> void:
	var made := SoundKit.make_all()
	_keep_sounds.call_deferred(made)


func _keep_sounds(made: Dictionary) -> void:
	SoundKit.take(made)
	WorkerThreadPool.wait_for_task_completion(_making)
	_making = -1


func _exit_tree() -> void:
	# Leaving before the sounds are made: wait for the worker, so it isn't cut off mid-sound.
	if _making >= 0:
		WorkerThreadPool.wait_for_task_completion(_making)
		_making = -1


## A new run: forget what was counted in the last one.
func watch(new_arena: Arena) -> void:
	arena = new_arena
	_seen.clear()


## Hits from the simulation's steps since the last frame.
func take_events(events: Array[Dictionary]) -> void:
	for event in events:
		match event.by:
			"stomp": play_at("stomp", event.position, 0.0)
			"fall": play_at("fall", event.position, 2.0)
			"bite": play_at("bite", event.position, -6.0 if event.get("kind", "rat") == "rat" else -2.0)
			"lunge": play_at("bark", event.position, -4.0)
			"rev": play_at("saw_rev", event.position, -3.0)
			"cut": play_at("saw_cut", event.position, -2.0)
			"leap": play_at("dodge", event.position, -6.0, 0.8)
			"landing": play_at("pounce", event.position, -4.0)
			"strike_back": play_at("riposte", event.position, -4.0)
			"dust": play_at("dodge", event.position, -8.0, 0.6)
			"beat": play_at("drum", event.position, -4.0)
			"snared": play_at("snare", event.position, -4.0)
			"sting": play_at("buzz", event.position, -10.0)
			"slipstream": play_at("dodge", event.position, -10.0, 1.4)
			"blast":
				match event.get("kind", ""):
					"petasan": play_at("pop", event.position, -6.0)
					"net_drone": play_at("net", event.position, -6.0)
					"mines": play_at("blast", event.position, 0.0)
					_: play_at("blast", event.position, -3.0, 1.3)
			"ignite": play_at("ignite", event.position, -4.0)
			"boss_arrives": play_at("boss_horn", event.position, 2.0)
			"whistle": play_at("whistle", event.position, -4.0)
			"horn": play_at("truck_horn", event.position, -2.0)
			"stall": play_at("stall", event.position, -4.0)
			"blade_up", "strafe_marked": play_at("hydraulic", event.position, -3.0)
			"throw": play_at("throw", event.position, -3.0)
			"log_lands": play_at("fall", event.position, -2.0)
			"lever": play_at("lever", event.position, -2.0)
			"call": play_at("squeak", event.position, -4.0, 0.7)
			"structure_down": play_at("structure_down", event.position, 0.0)
			"goal_done": interface("goal_done")
			"liberated": interface("freed")
			"snap": play_at("crack", event.position, -6.0, 1.3)
			"crack": play_at("crack", event.position, -4.0)
			"set_down":
				if event.get("kind", "") == "radio":
					play_at("radio", event.position, -6.0)
				else:
					play_at("pounce", event.position, -8.0, 0.7)
			"boom": play_at("hydraulic", event.position, -3.0)
			"jaws_shut": play_at("jaws", event.position, 0.0)
			"cage_open":
				play_at("cage_open", event.position, -4.0)
				play_at("meow", event.position, -3.0)
			"pickup": play_at("pickup", event.position, -10.0)
			_:
				if event.get("kind", "") == "machine":
					play_at("machine_break" if event.killed else "clang", event.position, 2.0 if event.killed else -8.0)
				elif event.get("kind", "") == "joint":
					play_at("machine_break" if event.killed else "hiss", event.position, 2.0 if event.killed else -5.0)
				elif event.get("giant", false):
					play_at("hit_big", event.position, -3.0)
				elif event.get("kind", "rat") == "dog":
					play_at("hit_dog", event.position, -5.0)
					if event.killed:
						play_at("yelp", event.position, -6.0)
				else:
					play_at("hit_small", event.position, -6.0)
					if event.killed:
						play_at("squeak", event.position, -8.0)


## Watches the simulation's counters each frame: rounds fired, swings, dodges, hits taken, the
## crew's level, and how far each giant has walked.
func _process(_delta: float) -> void:
	if arena == null:
		return
	for cat in arena.cats:
		for weapon in cat.weapons:
			if _counted(weapon, "rounds", weapon.rounds_fired):
				play_at(SHOTS.get(weapon.name, "shot_handgun"), cat.body.position, -4.0)
			if _counted(weapon, "swings", weapon.swings):
				# Deeper for a heavy blade, quicker for a light one.
				play_at("swing", cat.body.position, -10.0, SWING_PITCHES.get(weapon.name, 1.0))
		for slot: String in cat.supports:
			var support: Support = cat.supports[slot]
			if support.weapon != null and _counted(support.weapon, "rounds", support.weapon.rounds_fired):
				var fired: String = {"gun_drone": "shot_drone", "net_drone": "shot_thunk"}.get(support.name, "meriam")
				play_at(fired, support.body.position, -1.0 if fired == "meriam" else -8.0)
			if support.name == "mines" and _counted(support, "dropped", support.mines_dropped):
				play_at("mine_drop", cat.body.position, -10.0)
		if _counted(cat, "dodges", cat.dodges):
			play_at("dodge", cat.body.position, -8.0)
		if _counted(cat, "hurt", cat.hits_taken):
			play_at("hurt", cat.body.position, -6.0)
	if _counted(arena, "level", arena.level) and arena.level > 1:
		interface("level_up")
	for cage in arena.cages:
		if _counted(cage, "clicks", cage.clicks):
			play_at("lock_click", cage.body.position, -10.0)
	for machine in arena.machines:
		if machine is Helicopter:
			if _counted(machine, "rotor", int(machine.rotor)):
				play_at("rotor", machine.body.position, -10.0)
			continue
		# Its tracks clank as they run, link by link.
		var link := floori(machine.tracks_run / 0.5)
		if _counted(machine, "links", link) and machine.standing():
			play_at("track_clank", machine.body.position, -6.0)
	for giant in arena.giants:
		if not giant.standing():
			continue
		var walked: float = _seen.get([giant, "walked"], 0.0) + giant.body.velocity.length() * get_process_delta_time()
		if walked >= GIANT_STEP:
			walked -= GIANT_STEP
			play_at("footstep_giant", giant.body.position, -4.0)
		_seen[[giant, "walked"]] = walked


## Whether a counter has moved since the last look; the first look only takes note.
func _counted(thing: Object, what: String, value: int) -> bool:
	var key := [thing, what]
	var changed: bool = _seen.has(key) and _seen[key] != value
	_seen[key] = value
	return changed


## A sound in the world, at a point in meters, in one of its variants, a little off pitch each
## time so repeats don't ring the same.
func play_at(sound_name: String, where: Vector2, volume_db := 0.0, pitch := 1.0) -> void:
	var limit: int = LIMITS.get(sound_name, DEFAULT_LIMIT)
	var playing := 0
	var free: AudioStreamPlayer2D = null
	for voice in _voices:
		if voice.playing:
			if voice.get_meta("sound", "") == sound_name:
				playing += 1
		elif free == null:
			free = voice
	if playing >= limit or free == null:
		return
	free.stream = SoundKit.stream(sound_name, randi() % SoundKit.VARIANTS)
	free.set_meta("sound", sound_name)
	free.position = World.to_screen(where)
	free.volume_db = volume_db
	free.pitch_scale = pitch * randf_range(0.95, 1.05)
	free.play()
	played[sound_name] = played.get(sound_name, 0) + 1


## A sound of the interface: flat, not placed in the world.
func interface(sound_name: String) -> void:
	for player in _interface:
		if not player.playing:
			player.stream = SoundKit.stream(sound_name, 0)
			player.play()
			played[sound_name] = played.get(sound_name, 0) + 1
			return
