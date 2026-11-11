extends SceneTree
var failures:=0
func check(ok: bool,why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var settings=load("res://core/game_settings.gd").new()
	check(settings.values.has("race_spread") and settings.values.has("race_lead_changes"),"Race Control sliders exist")
	check(settings.values.get("replay_seconds")==5.0 and settings.values.get("replay_lengths")==1.0,"replay defaults to five seconds and one horse length")
	check(settings.values.get("bell_seconds")==0.5,"buzzer defaults to half a second")
	if failures: quit(1); return
	check(settings.set_value("replay_seconds",1.0) and settings.set_value("replay_seconds",10.0),"replay duration accepts both endpoints")
	check(settings.set_value("replay_lengths",0.5) and settings.set_value("replay_lengths",3.0),"replay distance accepts both endpoints")
	check(settings.set_value("bell_seconds",1.0) and not settings.set_value("bell_seconds",1.1),"bell has one-second maximum")
	var old=settings.export_data(); old.schema=6
	for k in ["race_spread","race_lead_changes","bell_seconds","replay_lengths"]: old.values.erase(k)
	old.values.replay_seconds=7.5; old.profiles["Old"]=old.values.duplicate()
	var migrated=load("res://core/game_settings.gd").new()
	check(migrated.restore(old),"old saves and profiles migrate")
	check(migrated.values.replay_seconds==5.0 and migrated.values.race_spread==0.0,"old defaults adopt five-second replay with random movement")
	migrated.values.race_spread=0.8; migrated.values.bell_seconds=1.0
	check(migrated.import_profile("Imported older profile",{"schema":6,"values":old.values}),"old profile imports into customized settings")
	check(migrated.profiles["Imported older profile"].race_spread==0.0 and migrated.profiles["Imported older profile"].bell_seconds==0.5,"old profile migration uses factory defaults independently of current settings")
	var panel=load("res://ui/settings_panel.gd").new(); root.add_child(panel)
	panel.configure(settings,func(): pass)
	var control_index: int=-1; var playback_index: int=-1
	for i in range(panel.navigation.item_count):
		if panel.navigation.get_item_text(i)=="Race Control": control_index=i
		if panel.navigation.get_item_text(i)=="Race Playback": playback_index=i
	check(control_index>=0 and playback_index==control_index+1,"Race Control and Race Playback are adjacent")
	check(panel.find_child("RaceControlNotice",true,false)!=null,"Race Control explains preserved odds")
	for link in panel.tabs.get_child(0).find_children("*","Button",true,false):
		if link.text=="Race Playback":
			link.pressed.emit()
			check(panel.navigation.get_selected_items()[0]==playback_index,"Settings Home playback shortcut still works")
	var help_context:=[]
	panel.help_requested=func(context): help_context.append(context)
	panel.navigate(playback_index); panel.open_help()
	check(help_context==["Race playback"],"renamed menu preserves the existing help topic")
	for k in ["race_spread","race_lead_changes","bell_seconds","replay_lengths"]:
		check(panel.implemented(k),"new control is live: "+k)
	panel.queue_free()
	var view=load("res://ui/track_view.gd").new(); view.preferences=settings.values.duplicate(); root.add_child(view)
	var first=[1010.0,965.0,964.5,960.0,930.0]; var last=[1045.0,1000.0,999.5,995.0,965.0]
	for viewport in [Vector2(700,470),Vector2(1100,700),Vector2(1900,1000)]:
		view.size=viewport
		for scale_value in [1.0,1.55,2.0]:
			view.preferences.horse_scale=scale_value
			for spacing in [40.0,68.0]:
				view.preferences.lane_spacing=spacing; view.geometry.lane_width=spacing
				view.configure_photo_frame(first,last)
				for alpha in [0.0,0.25,0.5,0.75,1.0]:
					view.positions=[]
					for h in range(5): view.positions.append(lerpf(first[h],last[h],alpha))
					for h in range(5):
						check(view.photo_safe_rect().encloses(view.photo_horse_bounds(h)),"all horses and numbers stay inside replay camera")
	view.queue_free()
	for lit in [false,true]:
		var b=Button.new(); root.add_child(b); load("res://ui/sigma_style.gd").indicator(b,lit)
		var normal: StyleBoxFlat=b.get_theme_stylebox("pressed" if lit else "normal")
		var hover: StyleBoxFlat=b.get_theme_stylebox("hover_pressed" if lit else "hover")
		check(normal.bg_color==hover.bg_color,"hover preserves button fill")
		check(normal.border_color!=hover.border_color,"hover has visible border")
		check(b.get_theme_color("font_hover_pressed_color")==b.get_theme_color("font_pressed_color"),"active hover text stays dark")
		check(b.get_theme_color("font_hover_color")==b.get_theme_color("font_color"),"inactive hover text stays light")
		b.queue_free()
	var signal_node=load("res://ui/start_signal.gd").new(); root.add_child(signal_node)
	var horn=signal_node.plan({"start_signal":"Horn"})
	var both=signal_node.plan({"start_signal":"Horn and bell","bell_seconds":0.5})
	check(horn.horn_end>9.0 and is_equal_approx(horn.total-horn.horn_end,1.5),"traditional horn retains pre-race gap")
	check(is_equal_approx(both.bell_start,horn.total) and is_equal_approx(both.total-both.bell_start,0.5),"both sounds end with half-second bell")
	for seconds in [0.1,0.5,1.0]:
		var bell=signal_node.plan({"start_signal":"Bell","bell_seconds":seconds})
		check(bell.bell_start==0.0 and is_equal_approx(bell.total,seconds),"bell-only movement waits exactly its duration")
		check(is_equal_approx(signal_node.school_bell(seconds).get_length(),seconds),"buzzer sample length matches settings")
	check(signal_node.play_signal({"start_signal":"Off"})==0.0,"Off starts immediately")
	check(is_equal_approx(signal_node.play_signal({"start_signal":"Horn and bell","master_volume":0.0}),both.total),"muting keeps the selected start timing")
	check(signal_node.player.stream is AudioStreamPlaylist and not signal_node.player.stream.loop,"combined audio is a nonlooping sequence")
	signal_node.queue_free()
	await process_frame
	print("Presentation 18 failures: ",failures); quit(1 if failures else 0)
