extends "res://tests/test_case.gd"


func _chapter() -> Dictionary:
	SaveGame.erase()  # no resuming from another test's checkpoint
	var room := (load("res://levels/chapter1.tscn") as PackedScene).instantiate() as Chapter
	room.change_scenes = false
	tree.root.add_child(room)
	var audio := room.get_node("Audio") as AudioManager
	var player := room.get_node("Player") as PlayerController
	var c := {"room": room, "audio": audio, "player": player, "steps": [], "zones": []}
	audio.footstep.connect(func(kind: StringName) -> void: c.steps.append(kind))
	audio.zone_changed.connect(func(zone: StringName) -> void: c.zones.append(zone))
	await frames(10)
	return c


func _teleport(c: Dictionary, x: float) -> void:
	c.player.position = Vector2(x, -3.0)
	c.player.velocity = Vector2.ZERO
	await frames(30)


func _done(c: Dictionary) -> void:
	release_all_inputs()
	c.room.queue_free()
	await frames(3)


func test_every_sound_file_loads_and_is_not_empty() -> void:
	var files: Array[String] = ["rumble.ogg", "land.ogg", "birds.ogg", "room.ogg"]
	for layer in AudioManager.LAYER_FILES.values():
		files.append(layer)
	for i in 4:
		files.append("step_%d.ogg" % (i + 1))
	for file in files:
		var stream := load(AudioManager.DIR + file) as AudioStreamOggVorbis
		check(stream != null, "%s loads as an ogg stream" % file)
		if stream != null:
			check(stream.get_length() > 0.1, "%s has sound in it, length %s" % [file, stream.get_length()])


func test_ambient_layers_follow_the_zone_the_player_is_in() -> void:
	var c := await _chapter()
	var audio: AudioManager = c.audio
	check(c.zones == [&"ZoneIntro"], "the start is in the intro zone, zones=%s" % [c.zones])
	check(audio.layer_target_db(&"wind") == -12.0 and audio.layer_target_db(&"drone") == AudioManager.SILENT_DB, "intro: wind only")
	await _teleport(c, 3500.0)
	check(c.zones.back() == &"ZonePuzzles", "puzzle country, zones=%s" % [c.zones])
	check(audio.layer_target_db(&"drips") == -22.0 and audio.layer_target_db(&"drone") == -36.0, "puzzles: drips and a faint drone")
	await _teleport(c, 6500.0)
	check(c.zones.back() == &"ZoneChase" and audio.layer_target_db(&"drone") == -14.0 and audio.layer_target_db(&"drips") == AudioManager.SILENT_DB, "the chase brings the drone up and the drips go quiet")
	await _teleport(c, 8200.0)
	check(c.zones.back() == &"ZonePen" and audio.layer_target_db(&"drone") == -8.0, "the pen is the loudest drone")
	# the volumes really get there (the layers fade over layer_fade seconds)
	await frames(int(audio.layer_fade * 60.0) + 20)
	var drone := audio.get_child(1) as AudioStreamPlayer
	var loudest := -1000.0
	for child in audio.get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).stream is AudioStreamOggVorbis and (child as AudioStreamPlayer).stream.resource_path.ends_with("drone.ogg"):
			loudest = (child as AudioStreamPlayer).volume_db
	check(absf(loudest - (-8.0)) < 0.6, "the drone player faded to -8 dB, is %s" % loudest)
	check(drone != null, "layers are children of the manager")
	await _done(c)


func test_walking_a_distance_gives_a_step_every_stride_and_running_has_longer_strides() -> void:
	var c := await _chapter()
	var player: PlayerController = c.player
	await _teleport(c, 300.0)
	var audio: AudioManager = c.audio
	c.steps.clear()
	var start := player.position.x
	Input.action_press(&"move_right")
	await frames(50)  # from standing to full speed (the keyboard ramps walk into run in well under a second)
	var x_start := player.position.x
	var before: int = c.steps.size()
	await frames(100)  # at full speed
	var run_dx := player.position.x - x_start
	var run_steps: int = c.steps.size() - before
	Input.action_release(&"move_right")
	check(before >= 1, "starting to walk makes steps, got %d over %d px" % [before, x_start - start])
	var expected_run := run_dx / audio.stride_run
	check(absf(run_steps - expected_run) <= 2.0, "running: %d steps for %d px, expected about %.1f" % [run_steps, run_dx, expected_run])
	check(c.steps.has(&"run"), "running steps are heard: %s" % [c.steps.slice(0, 6)])
	await _done(c)


func test_no_steps_when_standing_still_or_in_the_air() -> void:
	var c := await _chapter()
	await _teleport(c, 300.0)
	c.steps.clear()
	await frames(120)
	check(c.steps.is_empty(), "standing still is silent, heard %d" % c.steps.size())
	Input.action_press(&"move_right")
	Input.action_press(&"jump")  # one long jump: the whole flight is silent
	await frames(2)
	Input.action_release(&"jump")
	var in_air := 0
	var heard_in_air := 0
	for i in 40:
		await frames(1)
		if not c.player.is_on_floor():
			in_air += 1
			heard_in_air = c.steps.size()
	Input.action_release(&"move_right")
	check(in_air > 20 and heard_in_air == 0, "no step while airborne: %d frames up, %d steps by then" % [in_air, heard_in_air])
	await _done(c)


func test_pushing_a_crate_sounds_like_pushing_not_walking() -> void:
	var c := await _chapter()
	var player: PlayerController = c.player
	await _teleport(c, 2508.0)
	c.steps.clear()
	Input.action_press(&"interact")
	Input.action_press(&"move_right")
	await frames(120)
	release_all_inputs()
	check(player.grabbed != null or c.steps.has(&"push"), "grabbed the crate")
	check(c.steps.has(&"push") and not c.steps.has(&"run"), "slow dragging steps, heard %s" % [c.steps.slice(0, 5)])
	await _done(c)


func test_a_harder_landing_is_louder() -> void:
	var c := await _chapter()
	var player: PlayerController = c.player
	var heard: Array[float] = []
	c.audio.landing_heard.connect(func(db: float) -> void: heard.append(db))
	await _teleport(c, 300.0)
	player.position.y = -60.0  # a short drop
	await frames(40)
	var short_drop: float = heard.back() if not heard.is_empty() else -999.0
	heard.clear()
	player.position = Vector2(300.0, -600.0)  # a long fall
	player.velocity = Vector2.ZERO
	await frames(120)
	check(not heard.is_empty() and heard.back() > short_drop + 1.0, "long fall louder than the short drop: %s vs %s" % [heard, short_drop])
	await _done(c)


func test_the_rumble_swells_as_the_monster_gets_close_and_stops_when_it_is_held() -> void:
	var c := await _chapter()
	var audio: AudioManager = c.audio
	var player: PlayerController = c.player
	var monster := c.room.get_node("Monster") as Monster
	await _teleport(c, 5500.0)
	check(audio.proximity == 0.0, "the sleeping monster is not heard")
	monster.position.x = 4300.0  # 1200 px away: out of earshot
	monster.start()
	await frames(20)
	check(audio.proximity == 0.0, "too far to hear")
	monster.position.x = player.position.x - 700.0
	await frames(60)
	var far := audio.proximity
	monster.position.x = player.position.x - 250.0
	await frames(60)
	var near := audio.proximity
	check(far > 0.05 and near > far + 0.2, "closer is louder: %.2f then %.2f" % [far, near])
	monster.stun(5.0)
	await frames(90)
	check(audio.proximity < 0.05, "a held monster falls silent, proximity %.2f" % audio.proximity)
	await _done(c)


## Wrong way: the whole chapter's worth of events thrown at the manager (deaths, respawns, teleports across zones).
func test_dying_and_respawning_across_zones_keeps_the_audio_sane() -> void:
	var c := await _chapter()
	for x in [7000.0, 1000.0, 8300.0, 3000.0]:
		await _teleport(c, x)
		c.player.die()
		await frames(60)
	check(not c.zones.is_empty(), "zones were entered: %s" % [c.zones])
	for child in c.audio.get_children():
		if child is AudioStreamPlayer:
			check(is_finite((child as AudioStreamPlayer).volume_db), "volume is a number")
	await _done(c)
