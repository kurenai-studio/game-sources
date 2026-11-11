extends SceneTree
var failures:=0
var app: Node
var clips: Array=[]
var round_events: Array=[]
var race_clips:=0
var phase_peaks: Dictionary={}
var capture_audio:=AudioEffectCapture.new()
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	RenderingServer.force_draw(); root.get_texture().get_image().save_png("res://test-results/"+name+"-17.png")
func playback(kind: String, details: Dictionary) -> void:
	clips.append({"kind":kind,"phase":app.display_phase,"race_elapsed":app.race_elapsed,"details":details})
	if kind=="audio_clip_started" and app.display_phase=="RACING": race_clips+=1
	if kind=="audio_clip_started" and app.race_elapsed<0 and app.display_phase=="RACING": check(false,"speech overlaps start signal")
func run() -> void:
	app=load("res://ui/main.tscn").instantiate(); app.save_path="user://capture17.json"
	app.instance_guard.acquire(0); root.add_child(app); await process_frame
	root.size=Vector2i(1440,900)
	app.preferences.values.race_voice="Automatic race"; app.preferences.values.house_voice="Automatic female"
	app.preferences.values.race_mute=false; app.preferences.values.house_mute=false
	app.preferences.values.master_volume=0.5; app.preferences.values.race_volume=1.0; app.preferences.values.house_volume=1.0
	app.preferences.values.mechanical_enabled=false; app.preferences.values.hoof_enabled=false; app.preferences.values.win_volume=0.0
	app.preferences.values.start_signal="Bell"; app.preferences.values.race_seconds=35.0; app.preferences.values.photo_hold_seconds=1.0
	app.apply_settings(); app.announcers.backend.playback_event.connect(playback)
	AudioServer.add_bus_effect(0,capture_audio)
	for iteration in range(2):
		app.preferences.values.race_talk=1.0 if iteration==0 else 0.5
		app.apply_settings()
		for i in range(8): app.session.set_virtual_choice(i,11 if i%2==0 else 12)
		app.show_betting(); await process_frame
		if iteration==0: shot("betting")
		var balances: Array=app.session.players.map(func(p): return p.balance)
		race_clips=0; phase_peaks={}; var before:=clips.size()
		app.start_race()
		var deadline:=Time.get_ticks_msec()+150000
		var snapped:=false; var photo_shot:=false
		while Time.get_ticks_msec()<deadline:
			await process_frame
			var peak:=0.0
			for frame in capture_audio.get_buffer(capture_audio.get_frames_available()): peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
			if app.announcers.backend.speaking(): phase_peaks[app.display_phase]=maxf(peak,phase_peaks.get(app.display_phase,0.0))
			if app.display_phase=="RACING" and app.race_elapsed>30.0 and not snapped:
				snapped=true; shot("live-%d" % iteration)
			if app.display_phase in ["REPLAY","PHOTO"] and not photo_shot:
				photo_shot=true; shot("replay-%d" % iteration)
			if app.display_phase=="PAYOUT" and app.race_screen.payout_complete and app.announcers.active_role.is_empty(): break
		check(app.display_phase=="PAYOUT","race completes and returns a payout screen")
		check(race_clips>=4 if iteration==0 else race_clips>=3,"actual Windows output delivers start and action calls")
		check(phase_peaks.get("RACING",0.0)>0.001,"race voice reaches actual audio mix")
		check(phase_peaks.get("PAYOUT",0.0)>0.001,"house voice reaches actual audio mix")
		check(app.session.players.map(func(p): return p.balance)==balances,"native V game preserves human balances")
		check(app.announcers.backend.failure.is_empty(),"speech preparation succeeds")
		round_events.append({"iteration":iteration,"race_talk":app.preferences.values.race_talk,"race_clips":race_clips,"peaks":phase_peaks.duplicate(),"events":clips.slice(before)})
		app.return_to_betting(); await process_frame
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var report={"failures":failures,"rounds":round_events,"audio_driver":AudioServer.get_driver_name(),"output_device":AudioServer.output_device}
	var file=FileAccess.open("res://test-results/native17-audio.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  ")); file.close()
	print("NATIVE17 ",JSON.stringify({"failures":failures,"race_clips":round_events.map(func(r): return r.race_clips),"peaks":round_events.map(func(r): return r.peaks)}))
	app.queue_free(); await process_frame; quit(1 if failures else 0)
