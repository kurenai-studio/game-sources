extends SceneTree
const Scene = preload("res://main.tscn")
const Level = preload("res://scripts/level.gd")
var game: Node

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	var error: Error = root.get_texture().get_image().save_png("res://.qa/"+name+".png")
	if error != OK:
		push_error("Could not render "+name)

func fixture(index: int, beat: float) -> void:
	game.track_id = index
	game.track = Level.spec(index)
	game.chart = Level.notes(index)
	game.obstacles = Level.obstacles(index)
	game.rails = Level.rails(index)
	game.mode = "play"
	game.song_time = beat*game._beat()
	game.visual_time = game.song_time
	game.dimension = 0.0
	game.player_y = 0.0
	game.active_hold = -1
	game.juice.clear()
	for note in game.chart:
		if float(note["time"]) < game.song_time-0.1:
			note["state"] = 1

func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(640,360)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa"))
	game = Scene.instantiate()
	root.add_child(game)
	game.persist_progress = false
	game.set_process(false)
	game.set_physics_process(false)
	game.classic_lane = false
	game.reduced_fx = false
	game.tutorial_done = false
	game.mode = "menu"
	await capture("tour-home")
	game.mode = "tracks"
	game.unlocked_track = 2
	game.selected_track = 1
	await capture("tour-select")
	fixture(-1,30)
	await capture("tour-tutorial-hold")
	fixture(1,24)
	game.shift_held = true
	game._hit_note()
	game.song_time += 0.25
	game._process(0.08)
	await capture("tour-holding")
	game.classic_lane = true
	await capture("tour-classic-hold")
	game.classic_lane = false
	fixture(1,33)
	game.player_y = -28
	game.grinding = true
	game.feedback = "GRIND!"
	game.feedback_color = game.CYAN
	game.feedback_life = 0.4
	await capture("tour-grinding")
	fixture(2,160)
	game.mode = "results"
	game.score = 56350
	game.perfects = 141
	game.max_combo = 141
	game.misses = 0
	game.goods = 0
	game.holds_completed = 7
	game.grinds = 4
	game.cleared = 13
	game.bumps = 0
	await capture("tour-complete")
	game.mode = "settings"
	game.settings_return = "menu"
	await capture("tour-settings")
	game.mode = "calibration"
	game.song_time = 6.0
	await capture("tour-calibration")
	game.calibration.errors.assign([0.065,0.065,0.066,0.064,0.065,0.065,0.063,0.067])
	game.calibration.done = true
	await capture("tour-calibration-result")
	game.queue_free()
	await process_frame
	print("Rendered tour UI, tutorial, sustained notes, rails and results fixtures")
	quit()
