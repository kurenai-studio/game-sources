extends SceneTree
var draws := 0
var themes := 0
var frame_count := 0
var process_sum := 0.0
var draw_sum := 0.0
var recording := false
var results := []
func _initialize() -> void:
	call_deferred("run")
func _process(_delta: float) -> bool:
	if recording:
		frame_count += 1
		process_sum += Performance.get_monitor(Performance.TIME_PROCESS)
		draw_sum += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	return false
func sample(caption: String) -> void:
	draws = 0
	themes = 0
	frame_count = 0
	process_sum = 0.0
	draw_sum = 0.0
	var start := Time.get_ticks_msec()
	recording = true
	await create_timer(3.0).timeout
	recording = false
	results.append({"state":caption,"elapsed_ms":Time.get_ticks_msec()-start,"frames":frame_count,
		"one_wager_redraws":draws,"one_label_theme_changes":themes,
		"mean_process_ms":process_sum*1000.0/maxi(frame_count,1),"mean_draw_calls":draw_sum/maxi(frame_count,1)})
func run() -> void:
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var session = load("res://core/game_session.gd").new()
	session.fund_demo()
	var prefs = load("res://core/game_settings.gd").new().values
	prefs.master_volume = 0.0
	var frame := Control.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(frame)
	var display = load("res://ui/race_display.gd").new()
	frame.add_child(display)
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.configure(session,prefs)
	display.minis[0].cells["1-2"].amount.draw.connect(func(): draws += 1)
	display.minis[0].cells["1-2"].label.theme_changed.connect(func(): themes += 1)
	await create_timer(0.5).timeout
	await sample("moving")
	display.track.moving = false
	await sample("paused")
	display.track.highlights = [0,1]
	display.set_winning_pair("1-2")
	await sample("finished_flash")
	var report := {"cap":60,"states":results,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)}
	var suffix := "latest"
	if not OS.get_cmdline_user_args().is_empty(): suffix = OS.get_cmdline_user_args()[0]
	var file := FileAccess.open("res://test-results/performance-"+suffix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print(JSON.stringify(report))
	frame.queue_free()
	await process_frame
	quit()
