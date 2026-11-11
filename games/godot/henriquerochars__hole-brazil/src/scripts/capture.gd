extends SceneTree
## Captures the actual game viewport, including a complete autonomous round.
## Run with a rendering display, not --headless:
## xvfb-run -a godot --path . --rendering-method gl_compatibility
##   --fixed-fps 30 --script res://scripts/capture.gd -- --output=/tmp/buraco-capture

const FPS := 30
const FRAME_STRIDE := 2
const CLIP_SECONDS := 14
var output_dir := "/tmp/buraco-capture"
var main: Node
var gameplay: Node
var frame_number := 0

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_dir = argument.trim_prefix("--output=")
	call_deferred("_capture")

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Capture requires a rendering display. Use xvfb-run, without --headless.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output_dir.path_join("frames"))
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle(20)
	await _save("menu.png")
	main.call("show_selection")
	await _settle(20)
	await _save("selection.png")
	main.call("start_game", 0)
	await _settle(2)
	gameplay = main.get("gameplay")
	if gameplay == null:
		push_error("Capture requires main.gameplay to reference the active game.")
		quit(1)
		return
	gameplay.call("start_round", 0, 12345)
	gameplay.call("set_demo_mode", true)
	for tick in range(FPS * CLIP_SECONDS):
		await process_frame
		if tick % FRAME_STRIDE == 0:
			await _save("frames/frame_%04d.png" % frame_number)
			frame_number += 1
	await _save("gameplay.png")
	main.call("show_pause")
	await _settle(15)
	await _save("pause.png")
	main.call("resume_game")
	# Let the real timer expire. Do not inject a result, score, or growth.
	for _tick in range(FPS * 100):
		await process_frame
		var stats: Dictionary = gameplay.call("get_stats")
		if float(stats.get("time_left", stats.get("remaining", 1.0))) <= 0.0:
			break
	await _settle(30)
	await _save("results.png")
	var metadata := FileAccess.open(output_dir.path_join("capture.json"), FileAccess.WRITE)
	if metadata != null:
		metadata.store_string(JSON.stringify({
			"source": "Godot viewport, autonomous input, real round",
			"godot": Engine.get_version_info().get("string", ""),
			"fps": FPS / FRAME_STRIDE,
			"frames": frame_number,
			"stats": gameplay.call("get_stats")
		}, "\t"))
	print("Capture complete: ", output_dir)
	main.free()
	await create_timer(0.15).timeout
	quit()

func _settle(frames: int) -> void:
	for _frame in range(frames):
		await process_frame

func _save(relative_path: String) -> void:
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var result := screenshot.save_png(output_dir.path_join(relative_path))
	if result != OK:
		push_error("Screenshot save failed: %s (%s)" % [relative_path, result])
		quit(1)
