## Frame-time check at 1080p (needs a display, not --headless):
## godot --path game --resolution 1920x1080 --script ../tools/fps.gd
## Plays the chapter by dropping the player at 17 spots along it, vsync off, and prints average fps, the 1% low and
## the worst frame. Budget (PLAN 2.3 #7): 60 fps at 1080p, so the 1% low must stay above 60.
extends SceneTree

const SPOTS := [150, 900, 1900, 2800, 3500, 3900, 4600, 5000, 5600, 6400, 7000, 7600, 8200, 8800, 9300, 10000, 10700]
const FRAMES_PER_SPOT := 240
const WARMUP := 60


func _initialize() -> void:
	_run()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var room := (load("res://levels/chapter1.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var player := room.get_node("Player") as CharacterBody2D
	var times: Array[float] = []
	for spot in SPOTS:
		player.position = Vector2(spot, -3.0)
		player.velocity = Vector2.ZERO
		Input.action_press(&"move_right")  # moving, so the animation and the camera are busy
		var last := Time.get_ticks_usec()
		for i in FRAMES_PER_SPOT + WARMUP:
			await process_frame
			var now := Time.get_ticks_usec()
			if i >= WARMUP:
				times.append((now - last) / 1000.0)
			last = now
		Input.action_release(&"move_right")
	times.sort()
	var total := 0.0
	for t in times:
		total += t
	var average_ms := total / times.size()
	var low_ms: float = times[int(times.size() * 0.99)]
	print("size=%s frames=%d average=%.1f fps  1%%-low=%.1f fps  worst=%.1f ms" % [root.get_visible_rect().size, times.size(), 1000.0 / average_ms, 1000.0 / low_ms, times.back()])
	quit()
