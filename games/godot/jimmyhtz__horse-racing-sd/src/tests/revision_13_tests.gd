extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate()
	app.save_path="user://revision-13-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0)
	root.add_child(app)
	await process_frame
	app.set_process(false)
	var settings=app.preferences
	var legacy: Dictionary=settings.export_data()
	legacy.schema=3
	legacy.values.erase("start_signal")
	legacy.values.erase("start_signal_volume")
	legacy.values.merge({"bell_enabled":true,"table_currency":"USD","denomination":0.25,"custom_currency":"Default","show_money":false})
	legacy.profiles["Older saved profile"]=legacy.values.duplicate()
	var migrated=load("res://core/game_settings.gd").new()
	check(migrated.restore(legacy),"previous settings and named profiles migrate")
	check(not migrated.values.has("denomination") and migrated.values.start_signal=="Bell","credits-only migration preserves bell preference")
	app.session.access.set_pin("operator","1234")
	check(app.session.adjust_balance(2,1,"set","1234"),"manager sets last credit")
	check(app.flow.select_player(2),"one-credit player can select")
	check(app.session.edit_bet(2,"1-2",1),"last credit can be reserved")
	check(app.session.available(2)==0 and app.flow.screen=="betting","last-credit bet stays open for editing")
	check(app.session.edit_bet(2,"1-2",0),"all-in player can change mind before Ready")
	check(app.flow.request_out_toggle(2) and app.flow.screen=="overview","Out closes selected betting panel")
	check(app.session.adjust_balance(2,0,"set","1234"),"manager removes final credit")
	check(app.flow.select_player(2) and app.flow.screen=="inactive","bust player gets read-only V/Reload console")
	check(not app.flow.request_out_toggle(2),"bust player cannot join")
	app.session.players[0].bets.clear()
	# Bet every combination to guarantee a payout for presentation testing, not outcomes.
	for pair in app.session.board.payouts: check(app.session.edit_bet(0,pair,1),"test stake "+pair)
	app.session.set_ready(0,true)
	app.show_betting()
	app.start_race()
	check(app.display_phase=="PREPARING","locked race prepares speech before playing")
	if app.race_screen == null:
		printerr("START FAILURE: %s | %s | %s | blocked=%s" % [app.session.error,app.flow.error,app.message.text,app.blocked])
		app.queue_free()
		quit(1)
		return
	var snapshots_before: Array=app.snapshots.duplicate(true)
	var result_before: Dictionary=app.visual_result.duplicate(true)
	var track=app.track
	var screen=app.race_screen
	check(screen.payout_panels.keys()==["1-2","1-3","1-4","1-5","2-3","2-4","2-5","3-4","3-5","4-5"],"race payoff banner is sorted")
	app._process(0.1)
	check(app.display_phase=="RACING","prepared race starts")
	app.announcers.observe("BETTING",[],0,{})
	check(app.announcers.caption.is_empty(),"no voice or caption while betting")
	# Force close presentation threshold without changing a single recorded move.
	app.playback.photo_threshold=10000.0
	app.announcers.close_finish=true
	app._process(float(app.playback.race_seconds)+app.start_signal.duration)
	check(app.display_phase=="POST","race runs through its normal finish first")
	app._process(0.01)
	app._process(20.0)
	check(app.display_phase=="REPLAY" and app.track.close_up,"runout leads to oblique replay")
	var at0: float=app.replay_time_at(0)
	var at1: float=app.replay_time_at(1)
	var at2: float=app.replay_time_at(2)
	check(at1-at0>at2-at1 and at2<app.visual_result.second_time,"recorded replay progressively slows")
	app._process(30.0)
	check(app.display_phase=="PHOTO" and app.track.photo_hold,"replay freezes at second crossing")
	check(is_equal_approx(app.track.positions[app.visual_result.second],1000.0),"second horse freezes precisely at line")
	var nose: Vector2=app.track.horse_point(app.visual_result.second)+Vector2(24,-16*0.7).rotated(-PI/4)*app.track.photo_scale()
	check(nose.is_equal_approx(app.track.photo_nose(1000.0,app.visual_result.second)),"projected horse nose touches tape")
	await process_frame
	await process_frame
	var frozen_size: Vector2=app.track.size
	var frozen_origin: Vector2=app.track.global_position
	var frozen: Array=app.track.positions.duplicate()
	app._process(10.0)
	app._process(0.01)
	app._process(20.0)
	check(app.display_phase=="PAYOUT" and app.track==track and app.race_screen==screen,"payout retains track and sidebar instances")
	check(app.track.photo_hold and app.track.positions==frozen,"close-up remains frozen during payout")
	await process_frame
	await process_frame
	check(app.track.size==frozen_size and app.track.global_position==frozen_origin,"payout preserves the frozen camera framing")
	screen.prefs.reduced_motion=true
	screen.prefs.reduce_flashing=false
	screen.payout_elapsed=0.0
	screen.advance_payouts(0.1)
	var first_border: Color=screen.cards[0].get_theme_stylebox("panel").border_color
	screen.advance_payouts(0.5)
	check(screen.cards[0].get_theme_stylebox("panel").border_color==first_border,"reduced motion disables celebration flashing")
	check(screen.counters.size()==8,"every player has a payout counter")
	for counter in screen.counters.values(): check(counter.digits>=4,"payout counter has at least four digits")
	var balance: int=app.session.players[0].balance
	app.return_to_betting()
	check(app.display_phase=="PAYOUT","return is gated until count and commentary complete")
	app._process(30.0)
	app._process(30.0)
	check(app.display_phase=="PAYOUT" and screen.payout_complete,"payout waits for manual return")
	check(screen.counters[0].value==app.session.race_logs.back().accounting[0],"counter reaches exact settled award")
	check(app.session.players[0].balance==balance,"count-up never pays a second time")
	check(app.snapshots==snapshots_before and app.visual_result==result_before,"presentation never changes recorded movement or result")
	app.return_to_betting()
	check(app.display_phase=="BETTING","manual return opens next betting round")
	app.queue_free()
	await process_frame
	print("REVISION 13: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
