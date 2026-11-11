extends SceneTree
## Reproducible CPU simulation profile. Does not measure rendering or mobile FPS.
const Gameplay = preload("res://scripts/gameplay.gd")
const Rules = preload("res://scripts/game_rules.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game := Gameplay.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.sound_enabled = false
	var reports: Array[Dictionary] = []
	for scenario in ["ordinary_round", "maximum_radius"]:
		game.start_round(0, 12345)
		game.set_demo_mode(true)
		if scenario == "maximum_radius":
			game.mass = 4000.0
			game.radius = Rules.MAX_RADIUS
			game.shown_radius = game.radius
		var samples: Array[int] = []
		var memory_start := OS.get_static_memory_usage()
		for _tick in range(5401):
			if not game.active:
				break
			var start := Time.get_ticks_usec()
			game._physics_process(1.0 / 60.0)
			samples.append(Time.get_ticks_usec() - start)
		samples.sort()
		var total_usec := 0
		for sample in samples:
			total_usec += sample
		reports.append({
			"scenario": scenario,
			"physics_steps": samples.size(),
			"mean_step_usec": float(total_usec) / samples.size(),
			"p50_step_usec": samples[samples.size() / 2],
			"p95_step_usec": samples[int(samples.size() * 0.95)],
			"max_step_usec": samples.back(),
			"static_memory_delta_bytes": OS.get_static_memory_usage() - memory_start,
			"round_stats": game.get_stats()
		})
	game.free()
	var report := {
		"method": "Headless CPU simulation only; no rendering, GPU, or physical device FPS measurement",
		"godot": Engine.get_version_info().get("string", ""),
		"seed": 12345,
		"scenarios": reports
	}
	print(JSON.stringify(report, "\t"))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			var path := argument.trim_prefix("--report=")
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file == null:
				push_error("Could not save profiling report: " + path)
				quit(1)
				return
			file.store_string(JSON.stringify(report, "\t") + "\n")
	quit()
