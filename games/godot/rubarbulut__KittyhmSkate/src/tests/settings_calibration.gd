extends SceneTree
const Scene = preload("res://main.tscn")
const Calibration = preload("res://scripts/calibration.gd")
const Clock = preload("res://scripts/beat_clock.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error("FAIL: "+message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(Clock.estimated_delay(-11.0,0.01,true) == 0.01,"Web's inactive mixer cannot advance the first song by seconds")
	check(is_equal_approx(Clock.estimated_delay(0.005,0.015,false),0.02),"Native clock includes valid mix and device latency")
	check(Clock.estimated_delay(INF,NAN,false) == 0.0,"Invalid device timing never poisons the clock")
	var calibration = Calibration.new()
	for beat in range(4,20):
		calibration.tap(beat*Calibration.BEAT+0.085+(0.006 if beat%2 else -0.006))
	calibration.tap(4*Calibration.BEAT+0.085)
	check(calibration.errors.size() == 16,"Calibration ignores duplicate taps in the same beat")
	check(calibration.valid() and absf(calibration.offset()+0.085) < 0.001,"Consistently late taps produce compensating negative offset")
	calibration.reset()
	for beat in range(4,20):
		calibration.tap(beat*Calibration.BEAT-0.070)
	check(calibration.valid() and absf(calibration.offset()-0.070) < 0.001,"Consistently early taps produce compensating positive offset")
	calibration.reset()
	for beat in range(4,20):
		calibration.tap(beat*Calibration.BEAT+(0.17 if beat%2 else -0.17))
	check(not calibration.valid(),"Unsteady taps cannot apply an unreliable calibration")
	calibration.reset()
	calibration.tap(5*Calibration.BEAT)
	check(not calibration.valid(),"Insufficient taps require retry")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.qa"))
	var game = Scene.instantiate()
	game.save_path = "res://.qa/progress-roundtrip.cfg"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.input_offset = -0.085
	game.music_volume = 0.45
	game.hit_sounds = false
	game.classic_lane = true
	game.reduced_fx = true
	game.unlocked_track = 2
	game.tutorial_done = true
	game.track_records = {"1": {"score": 37200,"accuracy": 96.4,"combo": 70}}
	game._save_settings()
	game._load_settings()
	check(is_equal_approx(game.input_offset,-0.085) and is_equal_approx(game.music_volume,0.45),"Audio settings persist exactly")
	check(not game.hit_sounds and game.classic_lane and game.reduced_fx,"Preferences persist exactly")
	check(game.unlocked_track == 2 and game.tutorial_done and int(game.track_records["1"]["score"]) == 37200,"Tour progress and records survive reload")
	var broken := ConfigFile.new()
	broken.set_value("options","offset","broken")
	broken.set_value("options","music_volume",NAN)
	broken.set_value("progress","unlocked_track",9999)
	broken.set_value("progress","records",{"1": {"score": "oops","combo": -400,"accuracy": 999},"2": []})
	broken.save(game.save_path)
	game._load_settings()
	check(game.input_offset == 0 and is_equal_approx(game.music_volume,0.6),"Invalid numeric preferences fall back safely")
	check(game.unlocked_track == 2 and int(game.track_records["1"]["score"]) == 0 and int(game.track_records["1"]["combo"]) == 0 and float(game.track_records["1"]["accuracy"]) == 100,"Corrupt records are bounded and sanitized")
	check(not game.track_records.has("2"),"Invalid record structures are skipped")
	var legacy := ConfigFile.new()
	legacy.set_value("progress","best",9680)
	legacy.save(game.save_path)
	game._load_settings()
	check(int(game.track_records["0"]["score"]) == 9680 and game.track_records["0"]["legacy"],"Prototype scores migrate without inventing zero-percent accuracy")
	game._save_settings()
	game._load_settings()
	check(game.track_records["0"]["legacy"],"Legacy provenance survives saving and reloading")
	game.persist_progress = false
	game._go_menu()
	game.mode = "menu"
	game._open_settings()
	game._begin_calibration()
	check(game.mode == "calibration" and game.clock.running,"Settings open the playable timing check")
	game.clock.stop()
	game.calibration.errors.assign([0.08,0.08,0.08,0.08,0.08,0.08,0.08,0.08])
	game.calibration.done = true
	var apply := InputEventKey.new()
	apply.keycode = KEY_ENTER
	apply.pressed = true
	game._unhandled_input(apply)
	check(game.mode == "settings" and absf(game.input_offset+0.08) < 0.001,"Calibration result applies through the real settings input path")
	game.muted = true
	game._begin_calibration()
	check(game.calibration_paused and not game.clock.running,"Muted audio pauses the timing check rather than collecting silent taps")
	game.track_id = 0
	game._start_run()
	check(game.clock.paused_at == 0 and game.mode == "play","Muted gameplay remains playable")
	await create_timer(0.06).timeout
	game.clock.stop()
	await create_timer(0.15).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.05).timeout
	print("PASS: calibration statistics/sign, unreliable-tap rejection, persistence, legacy migration and corrupt saves" if failures == 0 else "FAILED %d settings checks" % failures)
	quit(0 if failures == 0 else 1)
