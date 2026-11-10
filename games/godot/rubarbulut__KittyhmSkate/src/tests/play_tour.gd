extends SceneTree
## Real-time integration driver. Sends real Godot input events, uses actual audio
## clock and physics, and never saves test scores into the player's profile.

const Scene = preload("res://main.tscn")
var game: Node
var index: int = -1
var next_note: int = 0
var next_jump: int = 0
var jumps: Array[float] = []
var shift_release: float = INF
var space_release: float = INF
var transition: float = 0.0
var done: bool = false
var errors: int = 0
var capture_dir: String = ""
var captured: Dictionary = {}

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	if not capture_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(capture_dir)
	game = Scene.instantiate()
	root.add_child(game)
	game.persist_progress = false
	game.classic_lane = false
	game.reduced_fx = false
	game.input_offset = 0.0
	game.muted = false
	game.hit_sounds = true
	game._apply_audio()
	start_track()

func start_track() -> void:
	game.track_id = index
	game._start_run()
	next_note = 0
	next_jump = 0
	shift_release = INF
	space_release = INF
	jumps.clear()
	for obstacle in game.obstacles:
		jumps.append(float(obstacle["time"])-game._beat()*0.5)
	for rail in game.rails:
		jumps.append(float(rail["time"])-game._beat()*0.5)
	jumps.sort()
	print("LIVE INPUT QA START: "+str(game.track["title"]))

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _process(delta: float) -> bool:
	if not is_instance_valid(game) or done:
		return false
	if game.mode == "pause":
		game._resume()
		if game.active_hold >= 0:
			key(KEY_SHIFT,true)
	if game.mode == "results":
		if transition == 0.0:
			_capture("results-%d" % index)
			var success: bool = game.misses == 0 and game.bumps == 0 and game.grinds == game.rails.size()
			print("LIVE INPUT QA %s: %s / %.1f%% / %d misses / %d bumps / %d grinds" % [game.track["title"],"PASS" if success else "FAIL",game.accuracy(),game.misses,game.bumps,game.grinds])
			if not success:
				errors += 1
		transition += delta
		if transition > 1.2:
			transition = 0.0
			index += 1
			if index > 2:
				done = true
				game.clock.stop()
				print("LIVE TOUR INPUT QA COMPLETE: %d failures" % errors)
				quit(0 if errors == 0 else 1)
			else:
				start_track()
		return false
	var now: float = game.clock.seconds()
	if index >= 0 and not captured.has(index) and game.combo >= 12:
		var beat: float = now/game._beat()
		if (index == 0 and beat >= 56) or (index == 1 and game.grinding) or (index == 2 and beat >= 96 and game.grinding):
			captured[index] = true
			_capture("gameplay-%d" % index)
	if now >= shift_release:
		key(KEY_SHIFT,false)
		shift_release = INF
	if now >= space_release:
		key(KEY_SPACE,false)
		space_release = INF
	if next_jump < jumps.size() and now >= jumps[next_jump]:
		key(KEY_SPACE,true)
		space_release = now+0.22
		next_jump += 1
	if next_note < game.chart.size() and now >= float(game.chart[next_note]["time"])-0.004:
		key(KEY_SHIFT,true)
		shift_release = now+0.055 if float(game.chart[next_note]["hold"]) == 0 else float(game.chart[next_note]["end"])-0.025
		next_note += 1
	return false

func _capture(name: String) -> void:
	if capture_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	var path: String = capture_dir.path_join(name+".png")
	root.get_texture().get_image().save_png(path)
	print("QA_SCREENSHOT "+path)
