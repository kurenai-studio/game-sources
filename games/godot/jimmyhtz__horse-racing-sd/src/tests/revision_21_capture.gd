extends SceneTree
class FixtureEntropy extends RefCounted:
	var chosen: String
	func new_seed() -> String:return chosen
	func observe_pointer(_position: Vector2) -> void:pass
var failures:=0
var app: Node
var capture_audio:=AudioEffectCapture.new()
var clips: Array=[]
var signal_frames: Array=[]
var signal_wall_start:=-1
var signal_wall_end:=-1
var movement_wall_start:=-1
var peaks: Dictionary={}
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func shot(view: Viewport, name: String) -> void:
	await process_frame; await process_frame; RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://test-results/"+name+"-21.png")
func clip_event(kind: String, data: Dictionary) -> void:
	if kind!="audio_clip_started": return
	clips.append({"phase":app.display_phase,"race_elapsed":app.race_elapsed,"data":data})
	check(not (app.display_phase=="RACING" and app.race_elapsed<0.0),"announcer does not interrupt start sounds")
func run() -> void:
	root.close_requested.connect(func(): print("NATIVE21 interrupted by window close request"))
	app=load("res://ui/main.tscn").instantiate(); app.save_path="user://capture21.json"
	app.instance_guard.acquire(0); root.add_child(app); await process_frame
	root.size=Vector2i(1440,900)
	app.preferences.values.race_spread=1.0; app.preferences.values.race_lead_changes=0.5
	app.preferences.values.race_talk=0.5
	app.preferences.values.master_volume=0.35
	app.preferences.values.hoof_enabled=true; app.preferences.values.mechanical_enabled=false
	app.preferences.values.start_signal="Horn and bell"; app.preferences.values.bell_seconds=0.5
	app.preferences.values.race_seconds=35.0; app.preferences.values.photo_hold_seconds=1.0
	app.apply_settings()
	app.session.set_virtual_choice(1,11); app.session.set_virtual_choice(2,12)
	app.select_player(0); app.change_bet(0,"1-2",2)
	await shot(root,"betting")
	var hover=InputEventMouseMotion.new(); hover.position=app.find_child("VirtualToggle1",true,false).get_global_rect().get_center()
	Input.parse_input_event(hover); await shot(root,"virtual-hover")
	app.open_settings("")
	await process_frame; await process_frame
	check(app.settings_panel.size.y<=root.size.y,"settings fit within the game window")
	for section in ["Race Control","Race Playback","Replay","Audio","Announcers"]:
		for i in range(app.settings_panel.navigation.item_count):
			if app.settings_panel.navigation.get_item_text(i)==section: app.settings_panel.navigate(i)
		await shot(app.settings_panel,"settings-"+section.to_lower().replace(" ","-"))
	for i in range(app.settings_panel.navigation.item_count):
		if app.settings_panel.navigation.get_item_text(i)=="Players and PINs": app.settings_panel.navigate(i)
	await shot(app.settings_panel,"settings-players")
	var editor=app.settings_panel.find_child("PlayerBlock0",true,false).get_parent().get_parent()
	var icon_preview=load("res://ui/player_avatar.gd").new(); editor.add_child(icon_preview)
	var icon_caption:=Button.new(); editor.add_child(icon_caption)
	var gallery: AcceptDialog=editor.create_avatar_gallery(0,icon_preview,icon_caption)
	gallery.popup_centered(); await shot(gallery,"player-icon-gallery")
	gallery.queue_free(); icon_preview.queue_free(); icon_caption.queue_free()
	app.settings_panel.return_to_game()
	await process_frame
	for i in range(8): app.session.set_virtual_choice(i,1+i%10)
	app.select_player(1)
	app.show_betting()
	app.announcers.backend.playback_event.connect(clip_event)
	AudioServer.add_bus_effect(0,capture_audio)
	var balances: Array=app.session.players.map(func(p): return p.balance)
	# Select a replay fixture only inside this isolated UI test. The game never
	# searches or rejects real races, and the production seed source is unchanged.
	var entropy=FixtureEntropy.new()
	for attempt in range(50):
		var seed=("native21-replay-"+str(attempt)).sha256_text()
		var candidate=load("res://core/calibrated_race.gd").new(seed,app.session.board,app.preferences.values).run()
		var policy=load("res://core/replay_policy.gd")
		if policy.decide(candidate,policy.configuration(20,app.preferences.values,candidate.movement_component)).replay:
			entropy.chosen=seed;break
	check(not entropy.chosen.is_empty(),"naturally qualifying replay fixture located")
	app.race_entropy=entropy
	app.start_race()
	app.set_process(false)
	app.track.positions=[30.0,130.0,320.0,630.0,880.0]
	await shot(root,"nose-guides")
	app.track.positions=[0.0,0.0,0.0,0.0,0.0]
	await shot(root,"nose-start")
	app.set_process(true)
	app.start_signal.school_bell(0.5).save_to_wav("res://test-results/school-bell-21.wav")
	check(app.display_phase=="PREPARING","native fixture starts the ready virtual race")
	if failures:
		print("START21 ",JSON.stringify({"display":app.display_phase,"blocked":app.blocked,"screen":app.flow.screen,"settings_open":app.flow.settings_open,"phase":app.session.phase,"can_start":app.flow.can_start(),"states":app.session.players.map(func(p): return p.state),"error":app.session.error,"flow_error":app.flow.error,"windows":app.get_children().filter(func(n): return n is Window).map(func(n): return [n.name,n.visible])}))
		app.queue_free(); await process_frame; quit(1); return
	check(app.needs_photo_finish(),"real 20 percent policy qualifies without forced threshold")
	var deadline:=Time.get_ticks_msec()+190000
	var live_shot:=false; var replay_shot:=false; var frozen_shot:=false
	var replay_started:=-1
	var replay_finished:=-1
	var seen_signal_playing:=false
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var now:=Time.get_ticks_msec()
		var peak:=0.0
		for sample in capture_audio.get_buffer(capture_audio.get_frames_available()): peak=maxf(peak,maxf(absf(sample.x),absf(sample.y)))
		peaks[app.display_phase]=maxf(peak,peaks.get(app.display_phase,0.0))
		if app.display_phase=="RACING":
			if signal_wall_start<0: signal_wall_start=now
			if app.start_signal.player.playing: seen_signal_playing=true
			elif seen_signal_playing and signal_wall_end<0: signal_wall_end=now
			if app.race_elapsed<0.2: signal_frames.append([now-signal_wall_start,app.race_elapsed,peak,app.start_signal.player.playing])
			if movement_wall_start<0 and app.race_elapsed>=0: movement_wall_start=now
			if app.race_elapsed>15.0 and not live_shot:
				live_shot=true; await shot(root,"race-control-live")
		if app.display_phase=="REPLAY" and not replay_shot:
			replay_shot=true; replay_started=now; await shot(root,"replay-start")
		if app.display_phase in ["REPLAY","PHOTO"]:
			check(not app.race_screen.audio.hoofs.playing,"hoofbeats stay off during replay")
			for h in range(5): check(app.track.photo_safe_rect().encloses(app.track.photo_horse_bounds(h)),"native replay contains all horses")
		if app.display_phase=="PHOTO" and not frozen_shot:
			frozen_shot=true; replay_finished=now; await shot(root,"photo-finish")
			check(absf(app.track.positions[app.visual_result.second]-1000.0)<0.00001,"second nose freezes exactly on the line")
		if app.display_phase=="PAYOUT" and app.race_screen.payout_complete and app.announcers.active_role.is_empty(): break
	await shot(root,"payout")
	check(app.display_phase=="PAYOUT","native race reaches payout")
	check(replay_shot and frozen_shot,"qualified replay visibly enters close-up and freeze")
	check(absf((replay_finished-replay_started)/1000.0-5.0)<0.35,"replay lasts the selected five seconds")
	check(signal_wall_end>0 and absf(signal_wall_end-movement_wall_start)<=150,"movement and actual signal ending align within one audio buffer/frame allowance")
	check(peaks.get("RACING",0.0)>0.001,"audio reaches native output mix")
	check(clips.filter(func(c): return c.phase=="RACING").size()>=5,"midpoint talk delivers opening and action commentary")
	check(app.session.players.map(func(p): return p.balance)==balances,"V balances remain protected")
	check(app.diagnostics.error.is_empty(),"native diagnostics remain healthy")
	check(app.announcers.backend.failure.is_empty(),"native speech preparation has no errors")
	var report={"failures":failures,"clips":clips,"peaks":peaks,"signal_frames":signal_frames,
		"schedule":app.start_signal.schedule,"signal_end_ms":signal_wall_end-signal_wall_start,
		"movement_start_ms":movement_wall_start-signal_wall_start,"audio_driver":AudioServer.get_driver_name(),
		"replay_wall_seconds":(replay_finished-replay_started)/1000.0,"replay_decision":app.replay_decision(),"replay_start":app.replay_start,"replay_end":app.visual_result.second_time,"race_control":app.visual_race.race_control_summary()}
	FileAccess.open("res://test-results/native21.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("NATIVE21 ",JSON.stringify({"failures":failures,"clips":clips.size(),"signal_end_ms":report.signal_end_ms,"movement_start_ms":report.movement_start_ms,"peaks":peaks}))
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	app.queue_free(); await process_frame; quit(1 if failures else 0)
