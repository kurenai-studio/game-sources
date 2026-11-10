extends SceneTree
## Run: Godot --headless --path . --script res://tests/smoke.gd
## Exercises the real game scene without modifying the player's saved progress.

const Scene = preload("res://main.tscn")
const Level = preload("res://scripts/level.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: " + message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = Scene.instantiate()
	root.add_child(game)
	game.persist_progress = false
	game.set_process(false)
	game.set_physics_process(false)
	game.input_offset = 0.0
	game.reduced_fx = false
	game._start_run()
	check(game.chart.size() == 78, "Authored chart contains 78 notes")
	check(game.obstacles.size() == 11, "Street contains 11 barriers")
	check(game.music.stream.get_length() >= Level.DURATION - 0.01, "Music spans the full chart")
	game.clock.stop()
	game.song_time = game.chart[0]["time"]
	game._hit_note()
	check(game.perfects == 1 and game.combo == 1 and game.score == 100, "On-time Shift is PERFECT")
	check(not game.juice.rings.is_empty(), "Successful rhythm input triggers the FX layer")
	var fx_event := InputEventKey.new()
	fx_event.keycode = KEY_V
	fx_event.pressed = true
	game._unhandled_input(fx_event)
	check(game.reduced_fx and game.juice.rings.is_empty() and game.juice.shards.is_empty() and game.score == 100, "Reduced FX immediately clears decoration while keeping score")
	game._unhandled_input(fx_event)
	game._hit_note()
	check(game.perfects == 1, "Repeated Shift cannot double-score the same note")
	var previous_layout: bool = game.classic_lane
	var layout_event := InputEventKey.new()
	layout_event.keycode = KEY_TAB
	layout_event.pressed = true
	game._unhandled_input(layout_event)
	check(game.classic_lane != previous_layout and game.score == 100 and game.combo == 1 and game.chart[0]["state"] == 1 and game.mode == "play", "Switching rhythm view preserves the active run and judged notes")
	game._unhandled_input(layout_event)
	check(game.classic_lane == previous_layout, "Both rhythm views remain available")
	game.hit_cooldown = 0.0
	game.song_time = game.chart[1]["time"] + 0.1
	game._hit_note()
	check(game.goods == 1 and game.combo == 2, "100 ms late is NICE")
	game.song_time = game.chart[2]["time"] + 0.2
	game._advance_game(1.0/120.0)
	check(game.misses == 1 and game.combo == 0, "Unplayed notes expire and reset combo")

	game._start_run()
	game.clock.stop()
	game.input_offset = 0.1
	game.song_time = game.chart[0]["time"] - 0.1
	game._hit_note()
	check(game.perfects == 1, "Offset applies consistently to hit judgement")
	game.input_offset = 0.0
	game._jump()
	game._advance_game(1.0/60.0)
	check(game.player_y < 0 and game.velocity_y < 0, "Space lifts the player off the road")
	game._jump()
	check(game.velocity_y > game.JUMP_SPEED, "Space in midair does not grant a double jump")

	# Space must still work while Shift is held (no modifier-based input mapping).
	game._start_run()
	game.clock.stop()
	var jump_event := InputEventKey.new()
	jump_event.keycode = KEY_SPACE
	jump_event.pressed = true
	jump_event.shift_pressed = true
	game._unhandled_input(jump_event)
	check(game.velocity_y == game.JUMP_SPEED, "Shift+Space preserves simultaneous input")
	game.velocity_y = 0.0
	game.player_y = 0.0
	game.song_time = game.obstacles[0]["time"]
	game._advance_game(1.0/120.0)
	check(game.bumps == 1 and game.mode == "play", "Grounded collision penalizes without ending the song")

	# Play every note and clear every barrier over a whole simulated song.
	game._start_run()
	game.clock.stop()
	var next_note: int = 0
	var next_jump: int = 0
	var step: float = 1.0/120.0
	for frame in range(int(Level.DURATION/step)+2):
		game.song_time = frame*step
		if next_jump < game.obstacles.size() and game.song_time >= float(game.obstacles[next_jump]["time"])-0.28:
			game._jump()
			next_jump += 1
		if next_note < game.chart.size() and game.song_time >= float(game.chart[next_note]["time"]):
			game._hit_note()
			next_note += 1
		game._advance_game(step)
		if game.mode == "results":
			break
	check(game.mode == "results", "Full chart reaches results")
	check(game.perfects == 78 and game.misses == 0, "All 78 chart notes can be hit perfectly")
	check(game.cleared == 11 and game.bumps == 0, "Every authored barrier is jumpable")
	check(is_equal_approx(game.accuracy(),100.0), "Perfect full run yields 100 percent accuracy")
	check(game.juice.shards.size() <= 144 and game.juice.rings.size() <= 8 and game.juice.glyphs.size() <= 18, "Effect pools stay bounded during a full perfect run")
	print("Full-run simulation: %d score, %d perfects, %d cleared, %d bumps" % [game.score,game.perfects,game.cleared,game.bumps])
	game._start_run()
	check(game.score == 0 and game.combo == 0 and game.misses == 0 and game.bumps == 0, "Restart clears previous run state")
	check(game.chart[0]["state"] == 0 and not game.obstacles[0]["cleared"], "Restart restores the chart and barriers")
	await create_timer(0.15).timeout
	game._pause()
	var pause_time: float = game.clock.seconds()
	await create_timer(0.05).timeout
	check(is_equal_approx(pause_time,game.clock.seconds()), "Paused song clock stays frozen")
	game._resume()
	check(absf(game.clock.seconds()-pause_time) < 0.02, "Resume excludes paused wall-clock time")
	game.clock.stop()
	# Let the audio mix thread retire a stopped WAV playback before teardown.
	await create_timer(0.10).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.05).timeout
	if failures == 0:
		print("PASS: rhythm, bounded FX/reduced mode, live layout switch, offset, simultaneous keys, physics, collisions, full song, restart and pause")
	else:
		print("FAILED: %d checks" % failures)
	quit(0 if failures == 0 else 1)
