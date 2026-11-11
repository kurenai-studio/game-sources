extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://ui/main.tscn").instantiate()
	app.save_path="user://integration15-%d.json" % Time.get_ticks_usec()
	app.instance_guard.acquire(0); root.add_child(app); app.set_process(false)
	app.preferences.values.race_mute=true; app.preferences.values.house_mute=true; app.preferences.values.master_volume=0
	app.apply_settings()
	for i in range(8): app.session.set_virtual_choice(i,11 if i==0 else i+1)
	app.show_betting()
	check(app.session.can_start(),"eight virtual seats prepare before card display")
	app.select_player(2)
	check(app.flow.screen=="virtual" and app.find_child("PlayerReady",true,false)==null and app.find_child("BetUp_1_2",true,false)==null,"virtual console is read-only")
	app.flow.back()
	app.open_settings("")
	var editor=app.settings_panel.find_child("VirtualStyleMode",true,false)
	check(editor!=null,"private style controls present")
	if editor!=null: check(editor.disabled,"random mode is chosen only on betting panels")
	await process_frame
	for factor in app.settings_panel.find_children("VirtualFactor_*","HSlider",true,false):
		check(not factor.editable and factor.value==snappedf((factor.min_value+factor.max_value)*0.5,factor.step),"random mode masks slider state")
	app.settings_panel.return_to_game()
	var id: String=app.session.game_id
	app.start_race()
	check(app.display_phase=="PREPARING","locked race calculation completes")
	var saved=load("res://core/session_store.gd").new()
	saved.save(app.session,app.preferences,"user://locked15.sdgame")
	check(not saved.load_session("user://locked15.sdgame",false).ok,"manual load cannot reroll locked race")
	app._process(40.0); app._process(50.0)
	for step in range(12): app._process(10.0)
	check(app.session.phase=="SETTLED","race reaches settlement")
	check(app.session.validate_state().is_empty(),"virtual credit ledger reconciles")
	var start:=Time.get_ticks_usec()
	for i in range(1200): app.diagnostics.frame(1.0/60.0,"PERFORMANCE_TEST",[1,2,3,4,5],i/60.0)
	var frame_cost: float=(Time.get_ticks_usec()-start)/1200.0
	check(frame_cost<4000.0,"diagnostic capture stays below 4ms per simulated frame")
	var path="user://integration15.zip"
	check(app.diagnostics.export_bundle(path,{"session":app.session.export_data()}),"whole race log exports")
	var zip=ZIPReader.new(); zip.open(path)
	var saw_motion:=false; var saw_replay:=false; var frame_count:=0; var compressed_size:=FileAccess.get_file_as_bytes(path).size()
	for file in zip.get_files():
		if not file.ends_with(".jsonl"): continue
		for line in zip.read_file(file).get_string_from_utf8().split("\n",false):
			var e=JSON.parse_string(line)
			if e.kind=="race_motion":
				saw_motion=true
				check(e.data.ticks.size()==app.visual_result.events,"every movement event logged")
				for horse in range(5): check(is_equal_approx(e.data.ticks[-1][5][horse],app.visual_result.final_positions[horse]),"last logged movement matches engine")
			if e.kind=="race_calculated": saw_replay=e.data.replay.has("gap") and e.data.replay.has("threshold")
			if e.kind=="frame_batch": frame_count+=e.data.samples.size()
	check(saw_motion and saw_replay and frame_count>=1200,"log includes motion, replay rationale and frames")
	zip.close()
	print("INTEGRATION15 ",JSON.stringify({"frame_capture_us":frame_cost,"export_bytes":compressed_size,"events":app.visual_result.events,"game_id_stable":app.session.game_id==id,"failures":failures}))
	app.queue_free(); await process_frame; quit(1 if failures else 0)
