extends SceneTree
var checks := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: "+message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if not ResourceLoader.exists("res://ui/movement_lab.tscn"):
		check(false,"movement preview scene exists")
		quit(1)
		return
	root.size = Vector2i(1280,800)
	var lab = load("res://ui/movement_lab.tscn").instantiate()
	lab.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(lab)
	await process_frame
	check(lab.track.has_method("display_finish_point"),"track exposes its visible finish location")
	if lab.track.has_method("display_finish_point"):
		var finish_point: Vector2 = lab.track.display_finish_point(0)
		check(finish_point.x > lab.track.geometry.straight_half-30.0 and finish_point.x < lab.track.geometry.straight_half,
			"finish line is near the right end of the foreground straight, before the curve")
		for lane in range(5):
			check(lab.track.display_point(0.0,lane).is_equal_approx(lab.track.display_finish_point(lane)),
				"horse start and finish line stay aligned in lane %d" % lane)
	lab.start_seed(123)
	check(not lab.outcome.is_empty(),"preview produces a seeded race")
	var official: Dictionary = lab.outcome.duplicate(true)
	lab.seek_to(0.5)
	var paused_positions: Array = lab.track.positions.duplicate()
	var paused_clock: float = lab.track._animation_clock
	lab._process(0.3)
	lab.track._process(0.3)
	check(lab.track.positions == paused_positions and lab.track._animation_clock == paused_clock,"pause freezes motion and stepping")
	lab.toggle_pause()
	lab._process(0.2)
	check(lab.track.positions != paused_positions,"resume advances recorded race")
	lab.seek_to(1.0)
	check(lab.track.highlights == [official.first,official.second],"both official winners highlighted")
	check(lab.track.positions == official.positions,"finish display matches exact recorded crossing")
	lab.start_seed(123)
	check(lab.outcome == official,"replay seed reproduces result")
	lab.seek_to(0.57)
	await process_frame
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture="):
				var error: int = root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
				check(error == OK,"rendered preview screenshot saved")
	lab.queue_free()
	await process_frame
	print("MOVEMENT UI CHECKS: %d | FAILURES: %d" % [checks,failed])
	quit(0 if failed == 0 else 1)
