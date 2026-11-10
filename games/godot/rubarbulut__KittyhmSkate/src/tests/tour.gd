extends SceneTree
const Scene = preload("res://main.tscn")
const Level = preload("res://scripts/level.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: "+message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = Scene.instantiate()
	root.add_child(game)
	game.persist_progress = false
	game.set_process(false)
	game.set_physics_process(false)
	game.input_offset = 0.0
	# This suite simulates minutes in one frame; audio feedback is covered by
	# the real-time driver rather than enqueueing hundreds of clicks at once.
	game.hit_sounds = false
	for fps in [30,60,120]:
		for index in [-1,0,1,2]:
			simulate(game,index,fps)
	for index in [-1,0,1,2]:
		simulate(game,index,60,0.05)
	for index in [-1,0,1,2]:
		simulate(game,index,60,0.22,0.05)
	check(game.unlocked_track == 2,"Tour unlocks all tracks in order")
	check(game.tutorial_done,"Successful warmup verifies actual controls")
	check(game.track_records.has("0") and game.track_records.has("1") and game.track_records.has("2"),"Every tour track stores a personal record")
	game._results_continue()
	check(game.mode == "tracks","Final track returns to tour selection")
	game.track_id = -1
	game.tutorial_done = false
	game._start_run()
	game.clock.stop()
	game.song_time = game._duration()
	game._advance_game(1.0/60.0)
	check(not game.tutorial_done,"Watching the warmup without playing does not mark it learned")
	game._results_continue()
	check(game.track_id == -1 and game.mode == "play","Unlearned warmup offers retry")
	game.track_id = 1
	game._start_run()
	game.clock.stop()
	var hold_index: int = -1
	for i in range(game.chart.size()):
		if float(game.chart[i]["hold"]) > 0:
			hold_index = i
			break
	game.song_time = game.chart[hold_index]["time"]
	game.shift_held = true
	game._hit_note()
	check(game.active_hold == hold_index,"Long note enters holding state")
	var left_shift := InputEventKey.new()
	left_shift.keycode = KEY_SHIFT
	left_shift.location = KEY_LOCATION_LEFT
	left_shift.pressed = true
	var right_shift := InputEventKey.new()
	right_shift.keycode = KEY_SHIFT
	right_shift.location = KEY_LOCATION_RIGHT
	right_shift.pressed = true
	game._unhandled_input(left_shift)
	game._unhandled_input(right_shift)
	right_shift.pressed = false
	game._unhandled_input(right_shift)
	check(game.shift_held and game.active_hold == hold_index,"Releasing one Shift key keeps a sustain when the other is held")
	game.song_time += 0.2
	game.shift_held = false
	game._release_hold()
	check(game.active_hold == -1 and game.misses == 1 and game.perfects == 0 and game.combo == 0,"Early release counts exactly one miss and removes provisional hit")
	check(game.score == 0,"Early release cannot farm head score")
	var release := InputEventKey.new()
	release.keycode = KEY_SPACE
	release.pressed = false
	game.player_y = -15
	game.velocity_y = -240
	game._unhandled_input(release)
	check(game.velocity_y > -240 and game.velocity_y < -140,"Releasing Space shortens an ollie while preserving minimum pop")
	game.track_id = 0
	game._start_run()
	game.clock.stop()
	game.song_time = game._duration()
	game._advance_game(0.5)
	check(game.bumps == game.obstacles.size() and game.cleared == 0 and game.score == 0,"A stalled or background browser cannot skip barriers and earn free score")
	game.clock.stop()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.05).timeout
	print("PASS: all tour charts at 30/60/120 FPS, musical offbeat jumps, sustain/release, rails, tutorial gates and progression" if failures == 0 else "FAILED %d tour checks" % failures)
	quit(0 if failures == 0 else 1)

func simulate(game: Node, index: int, fps: int, tap_duration: float = 0.22, jump_delay: float = 0.0) -> void:
	game.track_id = index
	game._start_run()
	game.clock.stop()
	var next_note: int = 0
	var next_jump: int = 0
	var release_shift: float = INF
	var release_space: float = INF
	var jumps: Array[float] = []
	for obstacle in game.obstacles:
		jumps.append(float(obstacle["time"])-game._beat()*0.5+jump_delay)
	for rail in game.rails:
		jumps.append(float(rail["time"])-game._beat()*0.5+jump_delay)
	jumps.sort()
	var step: float = 1.0/float(fps)
	for frame in range(ceili(game._duration()/step)+2):
		game.song_time = frame*step
		if game.song_time >= release_shift:
			game.shift_held = false
			game._release_hold()
			release_shift = INF
		if game.song_time >= release_space:
			game._cut_jump()
			release_space = INF
		if next_jump < jumps.size() and game.song_time >= jumps[next_jump]:
			game._jump()
			release_space = game.song_time+tap_duration
			next_jump += 1
		if next_note < game.chart.size() and game.song_time >= float(game.chart[next_note]["time"]):
			game.shift_held = true
			game._hit_note()
			release_shift = game.song_time+0.055 if float(game.chart[next_note]["hold"]) == 0 else float(game.chart[next_note]["end"])-0.02
			next_note += 1
		game._advance_game(step)
		game._process(step)
		if game.mode == "results":
			break
	var label: String = "%s @ %d FPS / %dms Space / +%dms jump" % [game.track["title"],fps,roundi(tap_duration*1000),roundi(jump_delay*1000)]
	check(game.mode == "results",label+" reaches results")
	check(game.perfects == game.chart.size() and game.misses == 0,label+" every note is playable")
	check(game.cleared == game.obstacles.size() and game.bumps == 0,label+" every barrier is clearable")
	check(game.grinds == game.rails.size(),label+" every rail can be entered")
	var expected_holds: int = 0
	for note in game.chart:
		if float(note["hold"]) > 0:
			expected_holds += 1
	check(game.holds_completed == expected_holds,label+" every sustain can complete")
	check(is_equal_approx(game.accuracy(),100.0),label+" ideal play yields 100 percent")
	check(absf(game.music.stream.get_length()-game._duration()) < 0.02,label+" audio and chart lengths match")
	print("%s: %d perfect / %d holds / %d barriers / %d grinds / %d score" % [label,game.perfects,game.holds_completed,game.cleared,game.grinds,game.score])
