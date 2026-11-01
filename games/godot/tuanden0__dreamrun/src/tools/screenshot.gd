## Windowed screenshot for visual checks (needs a display, not --headless):
## godot --path game --resolution 1280x720 --script ../tools/screenshot.gd -- <out.png> <frames_running_right> [start_x] [hold_interact]
extends SceneTree


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var run_frames := int(args[1]) if args.size() > 1 else 90
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	root.add_child(room)
	if args.size() > 2:
		room.get_node("Player").position.x = float(args[2])
	if args.size() > 3 and args[3] == "interact":
		Input.action_press(&"interact")
	Input.action_press(&"move_right")
	for i in run_frames:
		await physics_frame
	if args.size() <= 3:
		Input.action_release(&"move_right")
		for i in 40:
			await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit()
