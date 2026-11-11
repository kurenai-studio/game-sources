extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, caption: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	var app=load("res://ui/main.gd").new()
	# The display must use timestamps, including irregular final intervals.
	for spacing in [1.0,0.001]:
		app.snapshots=[]
		for frame in range(100):
			app.snapshots.append({"time":frame*spacing,"positions":[float(frame),0.0,0.0,0.0,0.0]})
		check(is_equal_approx(app.interpolate_motion(50.5*spacing)[0],50.5),"timeline lookup handles legacy and microturn timestamps")
		check(app.interpolate_motion(-1.0)[0]==0.0,"before-start interpolation clamps safely")
		check(app.interpolate_motion(200.0)[0]==99.0,"after-end interpolation clamps safely")
	var odds=load("res://core/calibrated_odds.gd").new()
	app.visual_race=load("res://core/calibrated_race.gd").new("playback-timeline".sha256_text(),odds.board(90))
	app.snapshots=[app.visual_race.snapshot()]
	while not app.visual_race.finished:
		app.visual_race.advance_event()
		app.snapshots.append(app.visual_race.snapshot())
	app.visual_result=app.visual_race.result()
	var middle: Array=app.interpolate_motion(app.visual_result.second_time*0.5)
	check(middle.min()>450.0 and middle.max()<550.0,"visible horses reach midtrack at half the actual race time")
	var finish: Array=app.interpolate_motion(app.visual_result.second_time)
	check(is_equal_approx(finish[app.visual_result.second],1000.0),"display crosses at the official second-place time without a jump")
	app.playback={"replay_seconds":7.5}
	if not app.has_method("replay_time_at"):
		check(false,"photo replay needs a timestamp-independent visible duration")
	else:
		var start: float=app.replay_time_at(0.0)
		var half: float=app.replay_time_at(1.25)
		check(start<half and half<app.visual_result.second_time,"photo replay remains moving after more than one second")
		check(is_equal_approx(app.replay_time_at(7.5),app.visual_result.second_time),"default replay lasts 7.5 visible seconds")
		app.playback.replay_seconds=10.0
		check(app.replay_time_at(7.5)<app.visual_result.second_time,"longer replay setting increases visible duration")
	app.frame_budget.free() # This isolated controller was never added to the scene.
	app.free()
	print("PAYBACK PLAYBACK: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
