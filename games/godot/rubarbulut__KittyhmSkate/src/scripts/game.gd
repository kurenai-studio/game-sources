extends Node2D

const Level = preload("res://scripts/level.gd")
const BeatClock = preload("res://scripts/beat_clock.gd")
const CatArt = preload("res://scripts/cat_art.gd")
const Juice = preload("res://scripts/juice.gd")
const Calibration = preload("res://scripts/calibration.gd")
const CALIBRATION_AUDIO = preload("res://assets/audio/calibration.wav")
const SOUNDS: Dictionary = {"perfect": preload("res://assets/audio/perfect.wav"),"good": preload("res://assets/audio/good.wav"),"land": preload("res://assets/audio/land.wav"),"bump": preload("res://assets/audio/bump.wav"),"hold": preload("res://assets/audio/hold.wav"),"clear": preload("res://assets/audio/clear.wav"),"ui": preload("res://assets/audio/ui.wav")}
const FONT = preload("res://assets/fonts/Silkscreen-Regular.ttf")
const TRACK = preload("res://assets/audio/alley_shift.wav")
const TRACK_AUDIO: Array[AudioStream] = [preload("res://assets/audio/alley_shift.wav"),preload("res://assets/audio/rooftop_radio.wav"),preload("res://assets/audio/midnight_overdrive.wav")]
const WARMUP_AUDIO = preload("res://assets/audio/warmup.wav")
const BG: Color = Color("10121f")
const PAPER: Color = Color("eee9d4")
const LIME: Color = Color("dcff50")
const CYAN: Color = Color("2bcbd4")
const PINK: Color = Color("f776a7")
const MUTED: Color = Color("8b90aa")
const FLOOR: float = 254.0
const PLAYER_X: float = 146.0
const JUMP_SPEED: float = -310.0
const GRAVITY: float = 900.0
const SHORT_JUMP_SPEED: float = -150.0
const START_RECT: Rect2 = Rect2(30, 228, 230, 35)
const OPTIONS_RECT: Rect2 = Rect2(30, 270, 230, 22)

var music: AudioStreamPlayer
var clock = BeatClock.new()
var juice = Juice.new()
var calibration = Calibration.new()
var calibration_paused: bool = false
var sound_players: Array[AudioStreamPlayer] = []
var music_volume: float = 0.6
var hit_sounds: bool = true
var save_path: String = "user://settings.cfg"
var mode: String = "menu"
var chart: Array[Dictionary] = []
var obstacles: Array[Dictionary] = []
var rails: Array[Dictionary] = []
var track_id: int = 0
var track: Dictionary = Level.spec(0)
var selected_track: int = 0
var unlocked_track: int = 0
var track_records: Dictionary = {}
var tutorial_done: bool = false
var shift_held: bool = false
var held_shift_keys: Dictionary = {}
var active_hold: int = -1
var hold_regrip: float = 0.0
var holds_completed: int = 0
var grinding: bool = false
var active_rail: int = -1
var grinds: int = 0
var grind_spark_time: float = 0.0
var song_time: float = 0.0
var simulation_time: float = 0.0
var visual_time: float = 0.0
var player_y: float = 0.0
var velocity_y: float = 0.0
var jump_buffer: float = 0.0
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var perfects: int = 0
var goods: int = 0
var misses: int = 0
var bumps: int = 0
var cleared: int = 0
var best: int = 0
var invulnerable: float = 0.0
var feedback: String = ""
var feedback_color: Color = LIME
var feedback_life: float = 0.0
var shift_flash: float = 0.0
var hit_cooldown: float = 0.0
var trick: float = 0.0
var impact: float = 0.0
var dimension: float = 0.0
var reduced_fx: bool = false
var classic_lane: bool = false
var success_flash: float = 0.0
var muted: bool = false
var input_offset: float = 0.0
var particles: Array[Dictionary] = []
var last_beat: int = -1
var new_best: bool = false
var settings_return: String = "menu"
var persist_progress: bool = true

func _ready() -> void:
	RenderingServer.set_default_clear_color(BG)
	music = AudioStreamPlayer.new()
	music.stream = TRACK
	music.volume_db = -5.0
	add_child(music)
	for i in range(4):
		var sound := AudioStreamPlayer.new()
		add_child(sound)
		sound_players.append(sound)
	_load_settings()
	get_window().focus_exited.connect(_focus_lost)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "play":
		_focus_lost()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "calibration" and not calibration.done:
		_focus_lost()

func _focus_lost() -> void:
	if mode == "play":
		_pause()
	elif mode == "calibration" and not calibration.done:
		calibration_paused = true
		clock.set_paused(true)

func _exit_tree() -> void:
	clock.stop()
	for sound in sound_players:
		sound.stop()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var point: Vector2 = get_global_mouse_position()
		if mode == "menu":
			if START_RECT.has_point(point):
				_home_start()
			elif OPTIONS_RECT.has_point(point):
				_open_settings()
		elif mode == "results" and Rect2(194,278,252,34).has_point(point):
			_results_continue()
		elif mode == "tracks":
			for i in range(3):
				if Rect2(18+i*205,99,194,174).has_point(point):
					selected_track = i
					if i <= unlocked_track:
						track_id = i
						_start_run()
		return
	if not event is InputEventKey:
		return
	if not event.pressed:
		if event.keycode == KEY_SHIFT:
			if mode == "play":
				_sync_before_input()
			held_shift_keys.erase(event.location)
			shift_held = not held_shift_keys.is_empty()
			if mode == "play" and not shift_held:
				_release_hold()
		elif event.keycode == KEY_SPACE and mode == "play" and velocity_y < SHORT_JUMP_SPEED:
			_sync_before_input()
			_cut_jump()
		return
	if event.echo:
		return
	var key: int = event.keycode
	if key == KEY_SHIFT and mode in ["play","pause"]:
		held_shift_keys[event.location] = true
	if key == KEY_SHIFT and mode == "pause":
		shift_held = true
	if key == KEY_M:
		muted = not muted
		_apply_audio()
		_save_settings()
		return
	if key == KEY_V:
		reduced_fx = not reduced_fx
		if reduced_fx:
			juice.clear()
		_save_settings()
		return
	if key == KEY_TAB:
		classic_lane = not classic_lane
		_save_settings()
		get_viewport().set_input_as_handled()
		return
	if key == KEY_F1 and mode in ["menu","tracks"]:
		mode = "credits"
		return
	match mode:
		"menu":
			if key == KEY_ENTER or key == KEY_SPACE:
				_home_start()
			elif key == KEY_S:
				_open_settings()
			elif key == KEY_T:
				track_id = -1
				_start_run()
		"tracks":
			if key == KEY_LEFT:
				selected_track = maxi(0,selected_track-1)
			elif key == KEY_RIGHT:
				selected_track = mini(2,selected_track+1)
			elif key in [KEY_1,KEY_2,KEY_3]:
				selected_track = key-KEY_1
			elif key == KEY_ENTER or key == KEY_SPACE:
				if selected_track <= unlocked_track:
					track_id = selected_track
					_start_run()
			elif key == KEY_T:
				track_id = -1
				_start_run()
			elif key == KEY_ESCAPE:
				mode = "menu"
		"credits":
			if key == KEY_ESCAPE or key == KEY_ENTER:
				mode = "menu"
		"play":
			if key == KEY_ESCAPE or key == KEY_P:
				_pause()
			elif key == KEY_SPACE:
				_sync_before_input()
				if mode == "play":
					_jump()
			elif key == KEY_SHIFT:
				_sync_before_input()
				if mode == "play":
					shift_held = true
					_hit_note()
			elif key == KEY_R:
				_start_run()
		"pause":
			if key == KEY_ESCAPE or key == KEY_P or key == KEY_ENTER:
				_resume()
			elif key == KEY_R:
				_start_run()
			elif key == KEY_Q:
				_go_menu()
			elif key == KEY_S:
				_open_settings()
		"settings":
			if key == KEY_LEFT:
				input_offset = maxf(-0.200, input_offset - 0.005)
			elif key == KEY_RIGHT:
				input_offset = minf(0.200, input_offset + 0.005)
			elif key == KEY_BACKSPACE:
				input_offset = 0.0
			elif key == KEY_UP:
				music_volume = minf(1.0,music_volume+0.05)
				_apply_audio()
			elif key == KEY_DOWN:
				music_volume = maxf(0.0,music_volume-0.05)
				_apply_audio()
			elif key == KEY_H:
				hit_sounds = not hit_sounds
			elif key == KEY_C and settings_return != "pause":
				_begin_calibration()
			elif key == KEY_ESCAPE or key == KEY_ENTER:
				_save_settings()
				mode = settings_return
		"calibration":
			if key == KEY_ESCAPE:
				clock.stop()
				mode = "settings"
			elif key == KEY_ENTER and calibration_paused:
				if not muted and music_volume >= 0.01:
					calibration_paused = false
					if clock.running:
						clock.set_paused(false)
					else:
						clock.start(music)
			elif key == KEY_R:
				_begin_calibration()
			elif key == KEY_SHIFT and not calibration_paused:
				calibration.tap(clock.seconds())
			elif key == KEY_ENTER and calibration.done:
				if calibration.valid():
					input_offset = calibration.offset()
					_save_settings()
					mode = "settings"
				else:
					_begin_calibration()
		"results":
			if key == KEY_R:
				_start_run()
			elif key == KEY_ENTER or key == KEY_SPACE:
				_results_continue()
			elif key == KEY_ESCAPE:
				_go_menu()
	get_viewport().set_input_as_handled()

func _start_run() -> void:
	clock.stop()
	track = Level.spec(track_id)
	music.stream = WARMUP_AUDIO if track_id < 0 else TRACK_AUDIO[track_id]
	chart = Level.notes(track_id)
	obstacles = Level.obstacles(track_id)
	rails = Level.rails(track_id)
	shift_held = false
	held_shift_keys.clear()
	active_hold = -1
	hold_regrip = 0.0
	holds_completed = 0
	grinding = false
	active_rail = -1
	grinds = 0
	grind_spark_time = 0.0
	song_time = 0.0
	simulation_time = 0.0
	player_y = 0.0
	velocity_y = 0.0
	jump_buffer = 0.0
	score = 0
	combo = 0
	max_combo = 0
	perfects = 0
	goods = 0
	misses = 0
	bumps = 0
	cleared = 0
	invulnerable = 0.0
	feedback_life = 0.0
	shift_flash = 0.0
	success_flash = 0.0
	hit_cooldown = 0.0
	trick = 0.0
	impact = 0.0
	dimension = 0.0
	particles.clear()
	juice.clear()
	last_beat = -1
	mode = "play"
	clock.start(music)

func _go_menu() -> void:
	clock.stop()
	mode = "tracks"
	player_y = 0.0
	particles.clear()
	juice.clear()

func _pause() -> void:
	clock.set_paused(true)
	held_shift_keys.clear()
	shift_held = false
	for sound in sound_players:
		sound.stop()
	mode = "pause"

func _resume() -> void:
	clock.set_paused(false)
	hold_regrip = 0.18
	mode = "play"

func _results_continue() -> void:
	if track_id < 0 and not tutorial_done:
		_start_run()
		return
	if track_id < 2:
		track_id = maxi(0,track_id+1)
		selected_track = track_id
		_start_run()
	else:
		_go_menu()

func _home_start() -> void:
	if not tutorial_done:
		track_id = -1
		_start_run()
	else:
		mode = "tracks"

func _beat() -> float:
	return float(track["beat"])

func _duration() -> float:
	return float(track["duration"])

func _speed() -> float:
	return float(track["speed"])

func _open_settings() -> void:
	settings_return = mode
	mode = "settings"

func _begin_calibration() -> void:
	clock.stop()
	calibration.reset()
	calibration_paused = false
	song_time = 0.0
	music.stream = CALIBRATION_AUDIO
	mode = "calibration"
	if muted or music_volume < 0.01:
		calibration_paused = true
	else:
		clock.start(music)

func _apply_audio() -> void:
	music.volume_db = -80.0 if muted or music_volume < 0.001 else linear_to_db(music_volume)
	if muted:
		for sound in sound_players:
			sound.stop()

func _play_sound(kind: String) -> void:
	if muted or not hit_sounds:
		return
	var player: AudioStreamPlayer = sound_players[0]
	for sound in sound_players:
		if not sound.playing:
			player = sound
			break
	player.stop()
	player.stream = SOUNDS[kind]
	player.volume_db = -15.0 if kind in ["clear","bump"] else -19.0
	player.play()

func _jump() -> void:
	if song_time > simulation_time+0.000001:
		_advance_game(0.0)
	if mode != "play":
		return
	# A small input buffer makes a press just before landing feel responsive.
	jump_buffer = 0.11
	if player_y >= -0.1 or grinding:
		grinding = false
		velocity_y = JUMP_SPEED
		jump_buffer = 0.0
		_burst(Vector2(PLAYER_X + 12, FLOOR - 2), CYAN, 7)

func _cut_jump() -> void:
	# A short tap still has enough pop for a barrier; holding Space gives the
	# full arc. This avoids making a beginner's quick tap a doomed jump.
	var remaining_height: float = maxf(0.0,38.0+player_y)
	var minimum_pop: float = -sqrt(2.0*GRAVITY*remaining_height)
	velocity_y = maxf(velocity_y,minf(SHORT_JUMP_SPEED,minimum_pop))

func _hit_note() -> void:
	if active_hold >= 0:
		return
	if hit_cooldown > 0.0:
		return
	hit_cooldown = 0.075
	shift_flash = 1.0
	var judged_time: float = song_time + input_offset
	var nearest: int = -1
	var distance: float = INF
	for i in range(chart.size()):
		if chart[i]["state"] != 0:
			continue
		var difference: float = absf(judged_time - float(chart[i]["time"]))
		if difference < distance:
			distance = difference
			nearest = i
		if float(chart[i]["time"]) > judged_time + 0.6:
			break
	if nearest >= 0 and distance <= Level.GOOD:
		var is_perfect: bool = distance <= Level.PERFECT
		chart[nearest]["quality"] = 1 if is_perfect else 2
		chart[nearest]["state"] = 1 if is_perfect else 2
		if float(chart[nearest]["hold"]) > 0.0:
			chart[nearest]["state"] = 3
			active_hold = nearest
			hold_regrip = 0.12
		combo += 1
		max_combo = maxi(max_combo, combo)
		if is_perfect:
			perfects += 1
		else:
			goods += 1
		var award: int = (100 if is_perfect else 60)*(1+mini(combo/10,3))
		chart[nearest]["award"] = award
		score += award
		_feedback("HOLD SHIFT" if active_hold >= 0 else ("PERFECT" if is_perfect else "NICE"), LIME if is_perfect else CYAN)
		_play_sound("perfect" if is_perfect else "good")
		trick = 1.0
		success_flash = 1.0
		impact = 0.35 if is_perfect else 0.15
		var hit_at: Vector2 = Vector2(124,312) if classic_lane else _street_target()
		if not reduced_fx:
			juice.hit(hit_at,is_perfect,combo if track_id >= 0 else mini(combo,9))
		else:
			_burst(hit_at,LIME if is_perfect else CYAN,3)
		if combo % 10 == 0:
			_burst(Vector2(PLAYER_X + 20, FLOOR - 36 + player_y), PINK, 18)
	elif song_time >= 7.0 * _beat():
		combo = 0
		_feedback("EARLY" if nearest >= 0 and judged_time < float(chart[nearest]["time"]) else "LATE", PINK)

func _release_hold() -> void:
	if active_hold < 0:
		return
	if song_time+input_offset >= float(chart[active_hold]["end"])-0.10:
		_complete_hold()
	else:
		_break_hold()

func _complete_hold() -> void:
	if active_hold < 0:
		return
	chart[active_hold]["state"] = chart[active_hold]["quality"]
	active_hold = -1
	holds_completed += 1
	score += 150
	success_flash = 1.0
	_feedback("HELD!",CYAN)
	_play_sound("hold")
	if not reduced_fx:
		juice.hit(Vector2(124,312) if classic_lane else _street_target(),false,combo if track_id >= 0 else mini(combo,9))

func _break_hold() -> void:
	var note: Dictionary = chart[active_hold]
	note["state"] = -2
	if note["quality"] == 1:
		perfects -= 1
	else:
		goods -= 1
	misses += 1
	score = maxi(0,score-int(note["award"]))
	combo = 0
	active_hold = -1
	_feedback("HOLD TO THE END",PINK)

func _process(delta: float) -> void:
	visual_time += delta
	if mode == "calibration" and not calibration_paused:
		calibration.flash = maxf(0.0,calibration.flash-delta*5)
	if mode != "pause" and not (mode == "settings" and settings_return == "pause"):
		juice.tick(delta)
		feedback_life = maxf(0.0, feedback_life - delta)
		shift_flash = maxf(0.0, shift_flash - delta * 5.0)
		success_flash = maxf(0.0, success_flash - delta * 5.0)
		trick = maxf(0.0, trick - delta * 3.8)
		impact = maxf(0.0, impact - delta * 2.0)
		for particle in particles:
			particle["life"] -= delta
			particle["pos"] += particle["vel"] * delta
			particle["vel"].y += delta * 95.0
		particles = particles.filter(func(p: Dictionary) -> bool: return p["life"] > 0.0)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if mode == "calibration":
		if not calibration.done and not calibration_paused:
			song_time = clock.seconds()
			if song_time >= Calibration.DURATION:
				calibration.done = true
				clock.stop()
		return
	if mode != "play":
		return
	song_time = clock.seconds()
	_advance_game(delta)

func _sync_before_input() -> void:
	if clock.running:
		song_time = clock.seconds()
		_advance_game(0.0)

func _advance_game(delta: float) -> void:
	# Advance skate physics on the same clock as the song. Fixed small steps
	# prevent dropped frames or a throttled browser tab from skipping barriers.
	var target_time: float = song_time
	if target_time > simulation_time+0.000001:
		while simulation_time < target_time-0.000001:
			var step: float = minf(1.0/120.0,target_time-simulation_time)
			simulation_time += step
			song_time = simulation_time
			_step_game(step)
			if mode != "play":
				break
		song_time = target_time
	elif delta > 0.0:
		_step_game(delta)

func _step_game(delta: float) -> void:
	hit_cooldown = maxf(0.0, hit_cooldown - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	hold_regrip = maxf(0.0,hold_regrip-delta)
	if active_hold >= 0:
		if song_time+input_offset >= float(chart[active_hold]["end"]):
			_complete_hold()
		elif not shift_held and hold_regrip <= 0.0:
			_break_hold()
	if grinding and active_rail >= 0:
		if song_time > float(rails[active_rail]["end"]):
			grinding = false
			velocity_y = -85.0
			if not rails[active_rail]["cleared"]:
				rails[active_rail]["cleared"] = true
				score += 200
		else:
			player_y = -28.0
			velocity_y = 0.0
			grind_spark_time -= delta
			if grind_spark_time <= 0.0:
				_burst(Vector2(PLAYER_X+15,FLOOR-28),CYAN,2)
				grind_spark_time = 0.06
	if not grinding and (player_y < 0.0 or velocity_y < 0.0):
		var old_y: float = player_y
		velocity_y += GRAVITY * delta
		player_y += velocity_y * delta
		if velocity_y >= 0.0 and old_y <= -28.0 and player_y >= -28.0:
			for i in range(rails.size()):
				if song_time >= float(rails[i]["time"])-0.03 and song_time <= float(rails[i]["end"]):
					grinding = true
					active_rail = i
					player_y = -28.0
					velocity_y = 0.0
					if not rails[i]["entered"]:
						rails[i]["entered"] = true
						grinds += 1
						score += 300
						_feedback("GRIND!",CYAN)
					break
		if player_y >= 0.0:
			player_y = 0.0
			velocity_y = 0.0
			_play_sound("land")
			_burst(Vector2(PLAYER_X + 14, FLOOR - 2), PAPER, 5)
			if jump_buffer > 0.0:
				velocity_y = JUMP_SPEED
				jump_buffer = 0.0
	var beat: float = song_time / _beat()
	var desired_dimension: float = 1.0 if beat >= float(track["drop_start"]) and beat < float(track["drop_end"]) else 0.0
	dimension = move_toward(dimension, desired_dimension, delta * 3.0)
	for note in chart:
		if note["state"] == 0 and song_time + input_offset - float(note["time"]) > Level.GOOD:
			note["state"] = -1
			misses += 1
			combo = 0
			_feedback("MISS", PINK)
	for obstacle in obstacles:
		var difference: float = float(obstacle["time"]) - song_time
		var x: float = PLAYER_X + 13.0 + difference * _speed()
		var overlap: float = 18.0-absf(x-(PLAYER_X+13.0))
		if not obstacle["hit"] and not obstacle["cleared"] and overlap > 0.0:
			# Forgiving bevelled corners: an ascending board can skim the edge,
			# but must clear the full barrier height over its solid center.
			var clearance: float = minf(24.0,overlap*3.0)
			if player_y > -clearance and invulnerable <= 0.0:
				obstacle["hit"] = true
				bumps += 1
				combo = 0
				invulnerable = 0.8
				impact = 0.8
				_feedback("OUCH! KEEP GOING", PINK)
				_play_sound("bump")
				_burst(Vector2(PLAYER_X + 20, FLOOR - 12), PINK, 15)
		if difference < -0.2 and not obstacle["hit"] and not obstacle["cleared"]:
			obstacle["cleared"] = true
			cleared += 1
			score += 200
	last_beat = int(beat)
	if song_time >= _duration():
		_finish()

func _finish() -> void:
	clock.stop()
	_play_sound("clear")
	mode = "results"
	var key: String = str(track_id)
	var record: Dictionary = track_records.get(key,{"score": 0,"accuracy": 0.0,"combo": 0})
	new_best = score > int(record["score"])
	if new_best:
		track_records[key] = {"score": score,"accuracy": accuracy(),"combo": max_combo}
	if track_id >= 0:
		unlocked_track = maxi(unlocked_track,mini(track_id+1,2))
	else:
		tutorial_done = tutorial_done or (perfects+goods >= 6 and cleared >= 1 and holds_completed >= 1)
	best = int(track_records.get("0",{"score": 0})["score"])
	_save_settings()

func _feedback(message: String, color: Color) -> void:
	feedback = message
	feedback_color = color
	feedback_life = 0.48

func _burst(at: Vector2, color: Color, count: int) -> void:
	if reduced_fx:
		count = mini(count, 3)
	for i in range(count):
		if particles.size() >= 160:
			break
		particles.append({"pos": at, "vel": Vector2(randf_range(-95, 95), randf_range(-110, -20)), "life": randf_range(0.2, 0.6), "color": color})

func accuracy() -> float:
	var judged: int = perfects + goods + misses
	return 100.0 if judged == 0 else (float(perfects) + float(goods) * 0.6) / float(judged) * 100.0

func _load_settings() -> void:
	reduced_fx = false
	classic_lane = false
	muted = false
	input_offset = 0.0
	music_volume = 0.6
	hit_sounds = true
	best = 0
	unlocked_track = 0
	tutorial_done = false
	track_records = {}
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		reduced_fx = _safe_bool(config.get_value("options","reduced_fx",false))
		classic_lane = _safe_bool(config.get_value("options","classic_lane",false))
		muted = _safe_bool(config.get_value("options","muted",false))
		input_offset = clampf(_safe_number(config.get_value("options","offset",0.0)), -0.2, 0.2)
		music_volume = clampf(_safe_number(config.get_value("options","music_volume",0.6),0.6),0.0,1.0)
		hit_sounds = _safe_bool(config.get_value("options","hit_sounds",true),true)
		best = int(clampf(_safe_number(config.get_value("progress","best",0)),0,9999999))
		unlocked_track = int(clampf(_safe_number(config.get_value("progress","unlocked_track",0)),0,2))
		tutorial_done = _safe_bool(config.get_value("progress","tutorial_done",false))
		var stored_records = config.get_value("progress","records",{})
		if stored_records is Dictionary:
			for key in ["-1","0","1","2"]:
				if stored_records.get(key) is Dictionary:
					var record: Dictionary = stored_records[key]
					track_records[key] = {"score": int(clampf(_safe_number(record.get("score",0)),0,9999999)),"accuracy": clampf(_safe_number(record.get("accuracy",0.0)),0,100),"combo": int(clampf(_safe_number(record.get("combo",0)),0,9999)),"legacy": _safe_bool(record.get("legacy",false))}
					# The first prototype stored score alone. An impossible zero-hit
					# record above all barrier bonuses came from that older migration.
					if key == "0" and int(track_records[key]["score"]) > 2200 and float(track_records[key]["accuracy"]) == 0.0 and int(track_records[key]["combo"]) == 0:
						track_records[key]["legacy"] = true
		if not track_records.has("0") and best > 0:
			track_records["0"] = {"score": best,"accuracy": 0.0,"combo": 0,"legacy": true}
	_apply_audio()

func _safe_number(value: Variant, fallback: float = 0.0) -> float:
	if value is int or value is float:
		return float(value) if is_finite(float(value)) else fallback
	return fallback

func _safe_bool(value: Variant, fallback: bool = false) -> bool:
	return value if value is bool else fallback

func _save_settings() -> void:
	if not persist_progress:
		return
	var config := ConfigFile.new()
	config.set_value("options", "reduced_fx", reduced_fx)
	config.set_value("options", "classic_lane", classic_lane)
	config.set_value("options", "muted", muted)
	config.set_value("options","music_volume",music_volume)
	config.set_value("options","hit_sounds",hit_sounds)
	config.set_value("options", "offset", input_offset)
	config.set_value("progress", "best", best)
	config.set_value("progress","unlocked_track",unlocked_track)
	config.set_value("progress","tutorial_done",tutorial_done)
	config.set_value("progress","records",track_records)
	var error: Error = config.save(save_path)
	if error != OK:
		push_warning("Progress could not be saved: "+error_string(error))

# ---------------------------------------------------------------------------
# Pixel stage and interface. The 640 x 360 canvas scales cleanly by 2 at 720p.
# ---------------------------------------------------------------------------

func box(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(roundf(x), roundf(y), w, h), color)

func text_at(value: String, x: float, y: float, size: int = 10, color: Color = PAPER) -> void:
	draw_string(FONT, Vector2(roundf(x), roundf(y)), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(value: String, y: float, size: int = 10, color: Color = PAPER) -> void:
	var width: float = FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	text_at(value, (640.0 - width) / 2.0, y, size, color)

func outline(rectangle: Rect2, color: Color, width: float = 1.0) -> void:
	draw_rect(rectangle, color, false, width)

func _draw() -> void:
	if mode == "calibration":
		_draw_calibration()
		return
	var menu_mode: String = settings_return if mode == "settings" else mode
	var in_menu: bool = menu_mode in ["menu","tracks"]
	if mode == "credits":
		_draw_credits()
		return
	if not in_menu and not reduced_fx and mode == "play":
		draw_set_transform(juice.background_offset())
	_draw_city(in_menu)
	draw_set_transform(Vector2.ZERO)
	if in_menu:
		if menu_mode == "tracks":
			_draw_tracks()
		else:
			_draw_menu()
	else:
		if not reduced_fx:
			juice.draw_back(self)
		_draw_street()
		draw_set_transform(Vector2.ZERO)
		_draw_hud()
		if classic_lane:
			_draw_lane()
		else:
			_draw_street_footer()
		_draw_particles()
		if not reduced_fx:
			juice.draw_front(self,FONT)
		if mode == "pause":
			_draw_pause()
		elif mode == "results":
			_draw_results()
	if mode == "settings":
		_draw_settings()

func _draw_city(menu: bool) -> void:
	var d: float = 0.0 if menu else dimension
	var time: float = visual_time * 12.0 if menu else song_time * _speed()
	var pulse: float = pow(1.0 - fmod(song_time / _beat(), 1.0), 3.0)
	var sky: Color = Color("171c34").lerp(Color("34153d"), d)
	box(0,0,640,360,sky)
	# Moon and distant pixels.
	box(499,69,32,32,Color("26384b").lerp(Color("652f65"), d))
	box(503,65,24,40,Color("26384b").lerp(Color("652f65"), d))
	box(505,71,22,24,CYAN.lerp(PINK,d).darkened(0.35))
	box(510,74,17,18,sky)
	for i in range(32):
		var x: float = fposmod(float(i * 83 + 9) - time * 0.025, 660.0) - 10.0
		var y: float = float(60 + (i * 37) % 100)
		box(x, y, 1 if i % 3 else 2, 2, Color("505478"))
	# Far skyline.
	for i in range(12):
		var x: float = fposmod(float(i * 71) - time * 0.12, 852.0) - 90.0
		var height: float = float(34 + (i * 29) % 69)
		box(x,192-height,56,height,Color("222840").lerp(Color("3e244b"),d))
		box(x+8,185-height,2,7,Color("394361"))
		for row in range(3):
			for col in range(4):
				if (row + col + i) % 3 != 0:
					box(x+7+col*11,200-height+row*14,4,6,Color("465064").lerp(Color("a24686"),d))
	# Near brick blocks.
	for i in range(6):
		var x: float = fposmod(float(i * 155) - time * 0.36, 930.0) - 160.0
		var h: float = float(75 + (i * 17) % 49)
		var wall: Color = Color("29243c").lerp(Color("342140"),d)
		box(x,245-h,141,h,wall)
		box(x-3,242-h,147,5,Color("44415a"))
		for row in range(6):
			var yy: float = 253.0-h+row*15
			if yy < 244:
				draw_line(Vector2(x,yy),Vector2(x+141,yy),Color("393047"),1)
				for col in range(5):
					var xx: float = x+col*31+((row%2)*15)
					draw_line(Vector2(xx,yy),Vector2(xx,yy+14),Color("393047"),1)
		box(x+14,260-h,24,30,Color("121b2c"))
		box(x+17,263-h,18,23,Color("28465b").lerp(Color("703765"),d))
		box(x+25,263-h,2,23,wall)
		box(x+17,274-h,18,2,wall)
		box(x+91,211,27,33,Color("1a1a2c"))
		box(x+94,216,2,24,Color("45415b"))
		if i % 2 == 0:
			box(x+53,263-h,70,22,BG)
			outline(Rect2(x+53,263-h,70,22), CYAN.lerp(PINK,d).darkened(0.2))
			text_at("NITE SHOP" if i == 0 else "MEOW FM", x+58,277-h,8,CYAN.lerp(PINK,d))
		else:
			text_at("STAY",x+53,225,13,Color("61516b"))
			text_at("STRAY",x+48,239,13,Color("61516b"))
	# Overhead cable and hanging signal.
	draw_line(Vector2(0,103),Vector2(320,122),Color("111421"),2)
	draw_line(Vector2(320,122),Vector2(640,91),Color("111421"),2)
	box(355,117,1,20,Color("111421"))
	box(348,137,15,7,CYAN.lerp(PINK,d).darkened(0.25))
	# Sidewalk and road.
	box(0,244,640,10,Color("5a5061"))
	box(0,245,640,2,Color("827078"))
	box(0,254,640,18,Color("1b1b2a"))
	for i in range(18):
		var x: float = fposmod(i * 42.0 - time, 756.0) - 50.0
		box(x,249,1,5,Color("2a293d"))
		box(x+3,260,14,1,Color("454050"))
	if d > 0.01:
		var accent: Color = PINK
		accent.a = d * (0.25 if reduced_fx else 0.35 + pulse*0.3)
		box(0,253,640,1,accent)
		# Beat-driven skyline bars, kept behind gameplay silhouettes.
		if not reduced_fx:
			for i in range(24):
				var h: float = 3 + absf(sin(i*1.7+int(song_time/_beat()))) * pulse*16
				box(i*28,244-h,9,h,Color(accent,0.14))

func _draw_menu() -> void:
	# Left poster panel.
	box(18,18,274,285,BG)
	box(18,18,4,285,CYAN)
	text_at("GAME OFF '26",32,35,9,CYAN)
	text_at("A STRAY WITH SOMETHING TO PROVE.",32,51,7,MUTED)
	text_at("KITTYHM",34,104,35,Color("38324b"))
	text_at("KITTYHM",30,100,35,PAPER)
	text_at("SKATE",34,151,49,Color("38324b"))
	text_at("SKATE",30,147,49,LIME)
	box(32,163,174,18,PINK)
	text_at("SHIFT YOUR REALITY.",39,175,9,BG)
	text_at("ONE CAT. THREE TRACKS. ALL SWAG.",32,200,8,PAPER)
	text_at("SKATE THE STREET. CATCH THE BEAT.",32,214,7,MUTED)
	box(START_RECT.position.x+3,START_RECT.position.y+3,START_RECT.size.x,START_RECT.size.y,Color("566b34"))
	box(START_RECT.position.x,START_RECT.position.y,START_RECT.size.x,START_RECT.size.y,LIME)
	text_at("LET'S RIDE" if tutorial_done else "LEARN TO RIDE",46,251,12,BG)
	text_at("[ENTER]",194,249,8,BG)
	text_at("[S] SETTINGS",33,284,9,MUTED)
	text_at("[T] PRACTICE",162,284,8,CYAN)
	# Right-hand character sticker, shown larger than in play.
	draw_circle(Vector2(461,166),76,Color("28374a"))
	outline(Rect2(371,80,181,163),Color("3c485c"))
	box(368,77,9,9,LIME)
	box(546,237,9,9,PINK)
	CatArt.draw(self,Vector2(432,228),2.0,visual_time,false,0.0)
	text_at("LOCAL MENACE",391,69,10,PAPER)
	text_at("100% ATTITUDE",420,266,8,LIME)
	box(334,284,285,18,BG)
	text_at("01",342,296,9,PINK)
	text_at("THE NIGHT TOUR",368,296,9,PAPER)
	text_at("3 TRACKS",552,296,7,MUTED)
	# Bottom control strip.
	box(0,315,640,45,BG)
	box(0,315,640,1,Color("363b50"))
	_keycap("SPACE",29,328,51,PAPER)
	text_at("OLLIE",89,340,9,PAPER)
	_keycap("SHIFT",190,328,51,LIME)
	text_at("HIT THE BEAT",250,340,9,PAPER)
	text_at("[F1] CREDITS",486,336,8,CYAN)
	text_at("LET THE CITY HEAR YOU.",456,349,7,MUTED)

func _draw_tracks() -> void:
	box(0,0,640,360,Color(0.04,0.05,0.09,0.88))
	text_at("THE NIGHT TOUR",20,40,23,PAPER)
	text_at("THREE TRACKS. ONE VERY LONG NIGHT.",22,60,8,CYAN)
	text_at("FINISH EACH TRACK TO OPEN THE NEXT.",22,78,8,MUTED)
	for i in range(3):
		var at: float = 18+i*205
		var data: Dictionary = Level.spec(i)
		var available: bool = i <= unlocked_track
		var accent: Color = [LIME,CYAN,PINK][i] if available else MUTED
		box(at,99,194,174,BG)
		outline(Rect2(at,99,194,174),accent if selected_track == i else Color("363b50"),2 if selected_track == i else 1)
		text_at("0%d" % (i+1),at+13,132,27,accent)
		text_at(data["title"],at+13,155,9,PAPER if available else MUTED)
		text_at(data["tag"],at+13,173,7,MUTED)
		text_at("%d BPM / %d SEC" % [int(data["bpm"]),roundi(data["duration"])],at+13,196,8,accent)
		text_at(data["mechanic"],at+13,214,8,PAPER)
		var record: Dictionary = track_records.get(str(i),{})
		if not record.is_empty():
			text_at("BEST %06d" % int(record["score"]),at+13,240,9,accent)
			text_at("EARLIER PROTOTYPE SCORE" if bool(record.get("legacy",false)) else "%.1f%% / %d COMBO" % [float(record["accuracy"]),int(record["combo"])],at+13,257,7,MUTED)
		else:
			text_at("READY TO RIDE" if available else "FINISH TRACK %d" % i,at+13,244,8,accent)
	centered("[LEFT / RIGHT] SELECT   [ENTER] RIDE",304,10,LIME)
	centered("[T] LEARN TO RIDE   [ESC] HOME",336,8,MUTED)

func _draw_credits() -> void:
	box(0,0,640,360,BG)
	text_at("KITTYHM SKATE",33,46,24,LIME)
	text_at("SPACE FOR THE STREET. SHIFT FOR THE SONG.",35,71,9,CYAN)
	text_at("CONCEPT & ART DIRECTION",35,111,9,MUTED)
	text_at("ARENB",35,130,12,PAPER)
	text_at("IMPLEMENTATION / ORIGINAL SYNTH MUSIC / CODE ART",35,166,8,MUTED)
	text_at("DEVELOPED WITH CODEX ASSISTANCE",35,186,11,PAPER)
	text_at("GODOT ENGINE / MIT / GODOTENGINE.ORG/LICENSE",35,222,8,CYAN)
	text_at("SILKSCREEN FONT / SIL OPEN FONT LICENSE 1.1",35,242,8,CYAN)
	text_at("FX FEEL INSPIRED BY RIDICULOUS CODING / JOHN WATSON",35,267,7,MUTED)
	text_at("BUILT FOR GAME OFF 2026 / THEME: SHIFT",35,287,8,PINK)
	text_at("[ENTER / ESC] BACK TO THE STREET",35,332,10,PAPER)

func _draw_street() -> void:
	if not classic_lane:
		_draw_rhythm_target()
	for rail in rails:
		var start: float = PLAYER_X+13+(float(rail["time"])-song_time)*_speed()
		var end: float = PLAYER_X+13+(float(rail["end"])-song_time)*_speed()
		if end < -20 or start > 660:
			continue
		var left: float = maxf(-10,start)
		var right: float = minf(650,end)
		draw_line(Vector2(left,FLOOR-28),Vector2(right,FLOOR-28),BG,7)
		draw_line(Vector2(left,FLOOR-28),Vector2(right,FLOOR-28),CYAN,3)
		var post: float = start+8
		while post < end:
			if post > -10 and post < 650:
				box(post,FLOOR-27,3,26,Color("4f667c"))
				box(post-3,FLOOR-3,9,2,CYAN.darkened(0.4))
			post += 46
		if start > PLAYER_X+45:
			text_at("LAND HERE",start,FLOOR-40,7,CYAN)
	for obstacle in obstacles:
		var x: float = PLAYER_X + 13.0 + (float(obstacle["time"])-song_time)*_speed()
		if x < -40 or x > 680:
			continue
		var color: Color = Color("575065") if obstacle["hit"] else PINK
		# A checker-painted traffic barrier. Flat top makes clearance readable.
		box(x-10,FLOOR-25,26,22,BG)
		box(x-8,FLOOR-23,22,14,color)
		for i in range(3):
			box(x-7+i*8,FLOOR-22,4,6,BG)
			box(x-3+i*8,FLOOR-16,4,6,BG)
		box(x-10,FLOOR-5,29,3,color)
		box(x-6,FLOOR-9,3,6,PAPER)
		box(x+9,FLOOR-9,3,6,PAPER)
		if x > PLAYER_X+55:
			text_at("^",x-3,FLOOR-32,12,PAPER)
	# Character silhouette stays legible even at maximum combo.
	var at: Vector2 = Vector2(PLAYER_X, FLOOR-8+roundf(player_y))
	if not reduced_fx and combo >= 10:
		for i in range(3,0,-1):
			var tint: Color = CYAN.lerp(PINK,dimension)
			tint.a = 0.1 + float(3-i)*0.05
			CatArt.draw(self, at-Vector2(i*13,0),1.0,song_time,player_y<0,trick,tint,song_time/_beat())
	box(PLAYER_X-8,FLOOR,60,2,Color("0d101b"))
	if invulnerable <= 0.0 or int(visual_time*18)%2 == 0:
		CatArt.draw(self,at,1.0,song_time,player_y < -1.0,trick,Color.WHITE,song_time/_beat())
	if not classic_lane:
		_draw_street_notes()
	if combo >= 5 and not reduced_fx:
		for i in range(5):
			var length: float = 8+float((i*7+int(visual_time*20))%18)
			box(PLAYER_X-25-length-i*6,FLOOR-5-i*4,length,1,CYAN.darkened(float(i)*0.12))
	if feedback_life > 0:
		var color: Color = feedback_color
		color.a = minf(1.0,feedback_life*5)
		var label_at: Vector2 = Vector2(PLAYER_X-29,FLOOR-83+player_y*0.25)
		var size: int = 12 if success_flash > 0.45 and not reduced_fx else 10
		draw_string_outline(FONT,label_at,feedback,HORIZONTAL_ALIGNMENT_LEFT,-1,size,3,BG)
		text_at(feedback,label_at.x,label_at.y,size,color)
	if track_id < 0:
		_draw_lesson()
	elif song_time < 8*_beat():
		var beat: int = int(song_time/_beat())
		if beat < 4:
			centered("SPACE TO OLLIE. SHIFT TO THE BEAT.",102,10,PAPER)
			centered("NO GAME OVER. FIND YOUR FLOW.",119,8,CYAN)
		else:
			centered(str(8-beat),116,28,LIME)
	elif song_time < 15*_beat():
		if classic_lane:
			text_at("SHIFT WHEN THE DIAMOND HITS THE BOX",228,263,7,LIME)
		else:
			text_at("DIAMOND REACHES THE CAT? SHIFT!",263,263,7,LIME)
	elif song_time < 19*_beat():
		text_at("SPACE: JUMP THE PINK BARRIERS",255,263,7,PAPER)

func _lesson_text() -> Array[String]:
	var beat: float = song_time/_beat()
	if beat < 8:
		return ["LISTEN. FIND THE PULSE.","DIAMONDS MOVE TOWARD YOUR CAT. GET READY TO TAP SHIFT."]
	if beat < 16:
		return ["TAP SHIFT AT THE CAT", "TAP ONCE AS EACH DIAMOND REACHES THE FIXED RING."]
	if beat < 28:
		return ["SPACE TO OLLIE", "JUMP BEFORE PINK BARRIERS. KEEP TAPPING SHIFT IN THE AIR."]
	if beat < 40:
		return ["LONG NOTES: HOLD SHIFT", "KEEP SHIFT DOWN UNTIL THE CYAN TAIL REACHES THE CAT."]
	return ["PUT IT TOGETHER", "SPACE FOR THE STREET. SHIFT FOR THE SONG. YOU'VE GOT THIS."]

func _draw_lesson() -> void:
	var lesson: Array[String] = _lesson_text()
	box(180,78,436,49,Color(0.04,0.05,0.09,0.9))
	text_at(lesson[0],194,98,12,LIME)
	text_at(lesson[1],194,117,7,PAPER)

func _draw_particles() -> void:
	for particle in particles:
		var pos: Vector2 = particle["pos"]
		var color: Color = particle["color"]
		color.a = minf(1.0,float(particle["life"])*3.0)
		box(pos.x,pos.y,2,2,color)

func _street_target() -> Vector2:
	# A fixed timing landmark. Jumping changes the cat, never the note deadline.
	return Vector2(PLAYER_X+16.0,FLOOR-39.0)

func _draw_rhythm_target() -> void:
	var target: Vector2 = _street_target()
	var phase: float = fmod(song_time/_beat(),1.0)
	var pulse: float = pow(1.0-phase,3.0)
	var color: Color = LIME.lerp(PAPER,success_flash)
	# Black backing and a faint guide separate the cues from brickwork.
	draw_line(target+Vector2(24,0),Vector2(640,target.y),Color(0.05,0.07,0.13,0.75),3)
	draw_line(target+Vector2(24,0),Vector2(640,target.y),Color(0.86,1.0,0.31,0.12),1)
	# This ring stays fixed while an approach ring closes onto it.
	draw_arc(target,22,0,TAU,32,Color(color,0.55),1)
	var next_time: float = INF
	for note in chart:
		if note["state"] == 0 and float(note["time"]) >= song_time:
			next_time = float(note["time"])
			break
	var remaining: float = next_time-song_time
	if remaining <= _beat():
		var radius: float = 22.0+remaining/_beat()*16.0
		draw_arc(target,radius,-PI*0.85,PI*0.85,32,Color(color,0.7),1)
	if active_hold >= 0:
		var note: Dictionary = chart[active_hold]
		var progress: float = clampf((song_time+input_offset-float(note["time"]))/float(note["hold"]),0.0,1.0)
		draw_arc(target,25,-PI/2,-PI/2+progress*TAU,32,CYAN,3)
	# Short brackets expose the exact timing column without covering the cat.
	for direction in [-1,1]:
		var y: float = target.y+direction*25
		draw_line(Vector2(target.x-5,y),Vector2(target.x+5,y),BG,4)
		draw_line(Vector2(target.x-4,y),Vector2(target.x+4,y),color,2)
	# A musical pulse under the wheels also works in peripheral vision.
	var width: float = 34.0 if reduced_fx else 34.0+pulse*12.0
	box(target.x-width/2,FLOOR+1,width,2,Color(CYAN,0.35+pulse*0.4))
	if success_flash > 0.0:
		box(target.x-23,FLOOR-3,46,2,Color(LIME,success_flash))
	text_at("SHIFT",target.x-15,FLOOR+14,7,LIME)

func _draw_street_notes() -> void:
	var target: Vector2 = _street_target()
	# Notes and barriers share their horizontal speed and arrival column.
	for note in chart:
		_draw_chart_note(note,target,_speed(),target.x-30,650)

func _draw_chart_note(note: Dictionary, target: Vector2, speed: float, min_x: float, max_x: float) -> void:
	if note["state"] != 0 and note["state"] != 3:
		return
	var holding: bool = note["state"] == 3
	var x: float = target.x if holding else target.x+(float(note["time"])-song_time)*speed
	if x < min_x or x > max_x:
		return
	var y: float = target.y
	var color: Color = CYAN if float(note["hold"]) > 0.0 else LIME
	if float(note["hold"]) > 0.0:
		var end_x: float = minf(max_x,target.x+(float(note["end"])-song_time)*speed)
		end_x = maxf(x,end_x)
		draw_line(Vector2(x,y),Vector2(end_x,y),BG,8)
		draw_line(Vector2(x,y),Vector2(end_x,y),color if not holding or shift_held else PINK,4)
		draw_circle(Vector2(end_x,y),5,BG)
		draw_circle(Vector2(end_x,y),3,color)
	draw_colored_polygon(PackedVector2Array([Vector2(x,y-9),Vector2(x+9,y),Vector2(x,y+9),Vector2(x-9,y)]),BG)
	draw_colored_polygon(PackedVector2Array([Vector2(x,y-6),Vector2(x+6,y),Vector2(x,y+6),Vector2(x-6,y)]),color)
	box(x-2,y-2,4,4,BG)

func _draw_street_footer() -> void:
	box(0,273,640,87,BG)
	box(0,273,640,1,Color("363b50"))
	text_at("ONE STREET. ONE FLOW.",18,293,10,LIME)
	text_at("%02d / %02d HITS" % [perfects+goods,chart.size()],510,293,8,MUTED)
	_keycap("SPACE",18,308,57,PAPER)
	text_at("OLLIE / GRIND" if not rails.is_empty() else "PINK BARRIERS",85,320,8,PAPER)
	_keycap("SHIFT",246,308,57,LIME)
	text_at("TAP / HOLD DIAMONDS" if track_id != 0 else "DIAMONDS AT THE CAT",313,320,8,PAPER)
	text_at("[TAB] STREET / CLASSIC",18,350,8,CYAN)
	text_at("[ESC] PAUSE",244,350,8,MUTED)
	text_at("[V] FX",407,350,8,MUTED)
	text_at("[M] " + ("MUTED" if muted else "AUDIO ON"),514,350,8,MUTED)

func _draw_hud() -> void:
	box(0,0,640,49,BG)
	box(0,49,640,1,Color("383b52"))
	text_at("KITTYHM / SKATE",17,17,9,PAPER)
	text_at(track["title"],17,34,8,CYAN)
	centered(Level.section(song_time/_beat(),track_id),20,9,PINK if dimension > 0.5 else LIME)
	centered("%d BPM / %02d:%02d" % [int(track["bpm"]),int(song_time)/60,int(song_time)%60],36,8,MUTED)
	text_at("%06d" % score,516,23,16,PAPER)
	text_at("%05.1f%%" % accuracy(),551,38,8,CYAN)
	box(0,47,640*clampf(song_time/_duration(),0,1),2,LIME)
	# Combo sticker.
	if combo > 1:
		text_at("%02d" % combo,32,100,25,LIME)
		text_at("COMBO",31,115,8,PAPER)
		text_at("x%d" % (1+mini(combo/10,3)),36,131,9,CYAN)

func _draw_lane() -> void:
	box(0,273,640,87,BG)
	box(0,273,640,2,CYAN.lerp(PINK,dimension).darkened(0.3))
	text_at("RHYTHM",19,290,8,MUTED)
	text_at("[TAB] STREET / CLASSIC",190,290,8,CYAN)
	text_at("%02d / %02d" % [perfects+goods,chart.size()],545,290,8,MUTED)
	# Lane stays steady while the city transforms.
	box(104,297,520,32,Color("1d2235"))
	box(104,312,520,1,Color("40465d"))
	for i in range(int(song_time/_beat())-1,int(song_time/_beat())+8):
		var x: float = 124 + (float(i)*_beat()-song_time)*(_speed()+5.0)
		if x >= 103 and x <= 623:
			box(x,298,1,30,Color("333c52"))
	var target_color: Color = LIME.lerp(PAPER,shift_flash)
	box(107,296,34,34,BG)
	outline(Rect2(107,296,34,34),target_color,2)
	box(122,300,3,25,target_color)
	for note in chart:
		_draw_chart_note(note,Vector2(124,312),_speed()+5.0,96,625)
	_keycap("SHIFT",16,300,70,LIME)
	text_at("HIT",41,333,7,MUTED)
	text_at("[SPACE] OLLIE",17,350,8,PAPER)
	text_at("[ESC] PAUSE",193,350,8,MUTED)
	text_at("[V] FX: " + ("LOW" if reduced_fx else "FULL"),351,350,8,MUTED)
	text_at("[M] " + ("MUTED" if muted else "AUDIO ON"),514,350,8,MUTED)

func _keycap(label: String, x: float, y: float, w: float, color: Color) -> void:
	box(x,y+2,w,20,color.darkened(0.6))
	box(x,y,w,18,color)
	var tw: float = FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x
	text_at(label,x+(w-tw)/2,y+12,9,BG)

func _draw_pause() -> void:
	box(0,0,640,360,Color(0.03,0.04,0.08,0.84))
	box(165,83,310,192,BG)
	outline(Rect2(165,83,310,192),CYAN)
	centered("TAKE A BREATHER.",123,20,LIME)
	centered("THE CITY CAN WAIT.",147,9,MUTED)
	centered("[ENTER / ESC] RESUME",184,11,PAPER)
	centered("[R] RESTART     [S] SETTINGS",214,9,MUTED)
	centered("[Q] BACK TO THE STREET MENU",246,8,MUTED)

func _draw_results() -> void:
	box(0,0,640,360,Color(0.03,0.04,0.08,0.93))
	var rank: String = "S" if accuracy() >= 95 and bumps == 0 else ("A" if accuracy() >= 85 else ("B" if accuracy() >= 65 else "C"))
	text_at("TRACK COMPLETE / "+str(track["title"]),34,34,10,CYAN)
	var headline: String = "YOU OWN THE NIGHT." if track_id == 2 else ("READY TO RIDE!" if track_id < 0 and tutorial_done else ("KEEP FINDING YOUR FLOW" if track_id < 0 else "YOU OWN THIS ALLEY."))
	text_at(headline,33,73,22,PAPER)
	box(34,96,104,110,LIME)
	text_at(rank,54,179,76,BG)
	text_at("%06d" % score,166,139,34,PAPER)
	var record_best: int = int(track_records.get(str(track_id),{"score": 0})["score"])
	text_at("NEW PERSONAL BEST" if new_best else "PERSONAL BEST %06d" % record_best,168,163,9,PINK if new_best else MUTED)
	text_at("ACCURACY",168,188,8,MUTED)
	text_at("%.1f%%" % accuracy(),278,188,10,CYAN)
	text_at("MAX COMBO",168,207,8,MUTED)
	text_at(str(max_combo),278,207,10,LIME)
	CatArt.draw(self,Vector2(487,214),1.75,visual_time,false,0.0)
	text_at("PERFECT  %02d" % perfects,35,242,9,LIME)
	text_at("NICE  %02d" % goods,205,242,9,CYAN)
	text_at("MISS  %02d" % misses,340,242,9,PINK)
	text_at("BUMPS  %02d" % bumps,485,242,9,MUTED)
	box(194,278,252,34,LIME)
	var action: String = "[ENTER] NEXT TRACK" if track_id < 2 else "[ENTER] TOUR COMPLETE"
	if track_id < 0:
		action = "[ENTER] START THE TOUR" if tutorial_done else "[ENTER] TRY THE WARMUP AGAIN"
	centered(action,300,11,BG)
	centered("[R] RETRY   [ESC] TRACKS / JUMPS %d/%d / HOLDS %d / GRINDS %d" % [cleared,obstacles.size(),holds_completed,grinds],336,7,MUTED)

func _draw_settings() -> void:
	box(0,0,640,360,Color(0.03,0.04,0.08,0.95))
	outline(Rect2(73,25,494,310),CYAN)
	text_at("MAKE IT FEEL RIGHT.",99,63,19,PAPER)
	text_at("[V] EFFECTS",100,100,10,MUTED)
	text_at("REDUCED" if reduced_fx else "FULL SWAG",379,100,10,LIME)
	text_at("[M] AUDIO",100,126,10,MUTED)
	text_at("MUTED" if muted else "ON",379,126,10,CYAN)
	text_at("[UP / DOWN] MUSIC",100,152,9,MUTED)
	text_at("%d%%" % roundi(music_volume*100),379,152,10,CYAN)
	text_at("[H] HIT SOUNDS",100,178,9,MUTED)
	text_at("ON" if hit_sounds else "OFF",379,178,10,CYAN)
	text_at("RHYTHM INPUT OFFSET",100,211,10,PAPER)
	text_at("<  %+04d MS  >" % roundi(input_offset*1000),354,211,10,LIME)
	text_at("LEFT / RIGHT: 5 MS. BACKSPACE: RESET.",100,232,8,MUTED)
	text_at("[TAB] VIEW: " + ("CLASSIC LANE" if classic_lane else "ON THE STREET"),100,258,8,PINK)
	text_at("[C] SOUND TIMING CHECK" if settings_return != "pause" else "TIMING CHECK: AVAILABLE FROM HOME",100,282,8,CYAN if settings_return != "pause" else MUTED)
	text_at("[ENTER / ESC] SAVE & BACK",100,315,10,PAPER)

func _draw_calibration() -> void:
	box(0,0,640,360,BG)
	centered("MAKE THE BEAT FEEL RIGHT.",43,18,PAPER)
	centered("LISTEN TO THE CLICK. TAP SHIFT WITH THE SOUND.",68,9,MUTED)
	if calibration.done:
		if calibration.valid():
			centered("RECOMMENDED OFFSET",135,11,CYAN)
			centered("%+04d MS" % roundi(calibration.offset()*1000),186,36,LIME)
			centered("%d TAPS / CONSISTENCY %+d MS" % [calibration.errors.size(),roundi(calibration.spread()*1000)],220,9,MUTED)
			centered("[ENTER] APPLY   [R] TRY AGAIN",278,11,PAPER)
		else:
			centered("LET'S TRY A STEADIER GROOVE.",158,15,PINK)
			centered("TAP ONCE PER CLICK. AT LEAST 8 STEADY TAPS.",199,9,MUTED)
			centered("[ENTER / R] TRY AGAIN",278,11,PAPER)
	else:
		var phase: float = fmod(song_time/Calibration.BEAT,1.0)
		var pulse: float = pow(1.0-phase,3.0)
		draw_circle(Vector2(320,170),27+roundf(pulse*5),Color(CYAN,0.12+pulse*0.15))
		draw_arc(Vector2(320,170),38,-PI/2,-PI/2+TAU,40,LIME if calibration.flash > 0 else CYAN,2)
		centered(str(int(song_time/Calibration.BEAT)%4+1),183,30,PAPER)
		centered("LISTEN FIRST..." if song_time < Calibration.BEAT*4 else ("KEEP TAPPING SHIFT" if song_time < Calibration.BEAT*20 else "NICE. MEASURING..."),241,12,LIME)
		centered("%d / 16 TAPS" % calibration.errors.size(),266,9,MUTED)
		box(100,294,440*clampf(song_time/Calibration.DURATION,0,1),2,CYAN)
	if calibration_paused:
		box(70,308,500,24,BG)
		centered("AUDIO MUTED / ESC TO ADJUST AUDIO" if muted or music_volume < 0.01 else "FOCUS PAUSED / ENTER TO CONTINUE",325,10,PINK)
	else:
		centered("[ESC] BACK WITHOUT CHANGING YOUR OFFSET",336,8,MUTED)
