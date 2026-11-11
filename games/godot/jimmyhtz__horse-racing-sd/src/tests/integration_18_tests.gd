extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate()
	app.save_path="user://integration18-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app); await process_frame
	app.set_process(false)
	app.preferences.values.race_spread=0.8; app.preferences.values.race_lead_changes=0.65
	app.preferences.values.start_signal="Horn and bell"; app.preferences.values.bell_seconds=0.5
	app.preferences.values.master_volume=0.0; app.apply_settings()
	app.session.set_virtual_choice(1,11); app.show_betting(); await process_frame
	check(app.find_child("ReadyToggle1",true,false).disabled,"V player stays automatically Ready")
	check(not app.find_child("ReadyToggle0",true,false).disabled,"human Ready remains clickable")
	app.session.edit_bet(0,"1-2",1); app.session.set_ready(0,true)
	var balance: int=app.session.players[0].balance
	app.start_race()
	await process_frame; await process_frame
	check(app.display_phase=="PREPARING","race locks and calculates before playback")
	check(app.visual_race.race_control_summary().controls.race_spread==0.8,"chosen controls reach official recorded engine")
	var baseline=load("res://core/calibrated_race.gd").new(app.visual_result.seed,app.session.board)
	var original: Dictionary=baseline.run()
	check(original.full_order==app.visual_result.full_order and original.pair==app.visual_result.pair,"full-course revision preserves every official finisher and payout pair")
	var expected: Dictionary=app.visual_result.duplicate(true)
	app.playback.photo_threshold=10000.0
	app.announcers.close_finish=true
	app.begin_playback()
	var signal_duration: float=app.start_signal.duration
	app._process(signal_duration-0.05)
	check(app.track.positions==[0.0,0.0,0.0,0.0,0.0] and not app.track.moving,"horses remain still until buzzer ends")
	app._process(0.05)
	check(absf(app.race_elapsed)<0.00001,"movement clock starts at the end of buzzer")
	app._process(0.1)
	check(app.track.positions.max()>0.0 and app.track.moving,"horses begin moving after signal")
	app._process(app.playback.race_seconds)
	check(app.display_phase=="POST" and app.session.phase=="RESULTS","shaped result accepted by official engine")
	app._process(0.01)
	app._process(10.0)
	check(app.display_phase=="REPLAY","close second/third triggers replay")
	var length_units: float=app.track.horse_length_units()
	var travel: float=1000.0-float(app.track.positions[expected.second])
	check(absf(travel-length_units)<0.000001,"default replay covers one actual horse length")
	var start_time: float=app.replay_start
	for elapsed in [0.0,1.0,3.0,4.9,5.0]:
		var time: float=app.replay_time_at(elapsed)
		check(time>=start_time and time<=expected.second_time,"replay remains in recorded interval")
	check(app.replay_time_at(5.0)==expected.second_time,"five-second replay stops at second nose crossing")
	app._process(5.0)
	check(app.display_phase=="PHOTO" and is_equal_approx(app.track.positions[expected.second],1000.0),"photo freezes exactly on tape")
	var frozen: Array=app.track.positions.duplicate()
	for i in range(4): app._process(20.0)
	check(app.display_phase=="PAYOUT" and app.track.positions==frozen,"payout retains frozen all-horse closeup")
	var award: int=int(app.session.board.payouts["1-2"]) if expected.pair=="1-2" else 0
	check(app.session.players[0].balance==balance-1+award,"account settlement remains exact")
	app.queue_free(); await process_frame
	print("Integration 18 failures: ",failures); quit(1 if failures else 0)
