extends SceneTree
## Deterministic visual QA fixture, not a player recording. Writes .qa/ PNGs.

const Scene = preload("res://main.tscn")
const Level = preload("res://scripts/level.gd")

func _initialize() -> void:
	call_deferred("render_preview")

func render_preview() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(640,360)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	var game = Scene.instantiate()
	root.add_child(game)
	game.persist_progress = false
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "play"
	game.classic_lane = false
	game.reduced_fx = false
	game.input_offset = 0.0
	game.song_time = 50*Level.BEAT+0.04
	game.visual_time = game.song_time
	game.dimension = 1.0
	game.chart = Level.notes()
	game.obstacles = Level.obstacles()
	for note in game.chart:
		if float(note["time"]) < 50*Level.BEAT:
			note["state"] = 1
	game.score = 8200
	game.combo = 29
	game.max_combo = 29
	game.perfects = 29
	game.player_y = -30.0
	game._hit_note()
	for i in range(5):
		game._process(1.0/60.0)
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa"))
	var error: Error = root.get_texture().get_image().save_png("res://.qa/fx-full.png")
	if error != OK:
		push_error("Could not save full FX preview")
		quit(1)
		return
	game.reduced_fx = true
	game.juice.clear()
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	error = root.get_texture().get_image().save_png("res://.qa/fx-reduced.png")
	game.queue_free()
	await process_frame
	print("Rendered full/reduced FX visual QA fixtures to .qa/")
	quit(0 if error == OK else 1)
