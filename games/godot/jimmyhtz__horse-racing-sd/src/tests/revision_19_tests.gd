extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var settings=load("res://core/game_settings.gd").new()
	check(not settings.values.has("race_speech_rate") and not settings.values.has("house_speech_rate"),"manual speech speed controls removed")
	var old=settings.export_data(); old.schema=7
	old.values.race_spread=1.0; old.values.race_lead_changes=0.6; old.values.race_talk=1.0
	old.values.race_speech_rate=0.9; old.values.house_speech_rate=0.3
	old.profiles["Old"]=old.values.duplicate()
	check(settings.restore(old),"version 7 settings migrate")
	check(settings.values.race_spread==0.5 and settings.values.race_lead_changes==0.3,"old movement controls preserve effect at new positions")
	check(settings.values.race_talk==0.5 and settings.profiles.Old.race_talk==0.5,"old maximum talk becomes midpoint including profiles")
	var director=load("res://ui/announcer_director.gd").new(); root.add_child(director); director.configure(settings.values)
	check(director.has_method("fit_delivery"),"automatic bounded speech fitting exists")
	check(director.has_method("talk_interval"),"expanded talk density has one shared mapping")
	if director.has_method("fit_delivery"):
		var normal=director.fit_delivery("race","Horse two takes the lead!",20.0)
		var tight=director.fit_delivery("race","Horse two takes the lead!",2.3)
		check(normal.rate>=1.0 and normal.rate<=1.6,"automatic normal rate stays bounded")
		check(tight.rate>=normal.rate and tight.rate<=1.6,"tight windows raise speech rate only to hard limit")
		check(not director.fit_delivery("race","This long sentence cannot fit into a tiny time window.",0.05).fits,"unfittable call is rejected")
	if director.has_method("talk_interval"):
		check(is_equal_approx(director.talk_interval(0.5),3.0) and director.talk_interval(1.0)<1.5,"old maximum interval is new midpoint")
	director.queue_free()
	var view=load("res://ui/track_view.gd").new(); view.preferences=settings.values; root.add_child(view); view.size=Vector2(1200,780)
	for progress in [0.0,0.03,0.08,0.13,0.20,0.26,0.35,0.51,0.60,0.76,0.88,0.99]:
		view.positions=[progress*1000,progress*1000,progress*1000,progress*1000,progress*1000]
		for h in range(5):
			var line: PackedVector2Array=view.nose_guide(h)
			var nose: Vector2=view.horse_point(h)+view.nose_offset(h)
			check(Geometry2D.get_closest_point_to_segment(nose,line[0],line[-1]).distance_to(nose)<0.1,"guide passes through nose at %s horse %d endpoints %s nose %s" % [progress,h,line,nose])
			for endpoint in [0,line.size()-1]:
				var point: Vector2=(line[endpoint]-Vector2(view.size.x*.5,view.size.y*.54))/view.view_scale()
				point.y/=0.87*view.preferences.get("camera_height",1.0)
				var radius: float=view.geometry.inner_radius+(-.5 if endpoint==0 else 4.5)*view.geometry.lane_width
				var capsule_distance: float=Vector2(maxf(absf(point.x)-view.geometry.straight_half,0),point.y).length()
				check(capsule_distance<=radius+0.15 if endpoint==0 else capsule_distance>=radius-0.15,"guide reaches both track edges including bends")
	view.queue_free()
	var signal_node=load("res://ui/start_signal.gd").new(); root.add_child(signal_node)
	check(signal_node.has_method("school_bell"),"school bell replaces buzzer synthesis")
	if signal_node.has_method("school_bell"):
		for length in [0.1,0.5,1.0]: check(is_equal_approx(signal_node.school_bell(length).get_length(),length),"school bell preserves exact signal duration")
	signal_node.queue_free()
	var app=load("res://ui/main.tscn").instantiate(); app.save_path="user://revision19-settings.json"; app.instance_guard.acquire(0); root.add_child(app); app.set_process(false)
	check(app.has_method("settings_snapshot"),"complete race settings snapshot exists")
	if app.has_method("settings_snapshot"):
		var snapshot: Dictionary=app.settings_snapshot("test")
		check(snapshot.preferences==app.preferences.values,"every preference is in diagnostic snapshot")
		check(snapshot.has("operator") and snapshot.has("virtual_styles") and snapshot.has("players"),"separate session settings included")
		check(not JSON.stringify(snapshot).contains('"credentials"') and not JSON.stringify(snapshot).contains('"pin"'),"snapshot does not record PINs")
		app.session.players[0].nickname="Changed name"
		var renamed: Dictionary=app.settings_snapshot("test")
		check(renamed.players[0].nickname=="Changed name" and renamed.fingerprint!=snapshot.fingerprint,"name changes are logged and fingerprinted")
		app.session.access.credentials["player_0"]={"salt":"private-salt","hash":"private-hash"}
		var protected_player: Dictionary=app.settings_snapshot("test")
		check(protected_player.players[0].access_code_enabled and protected_player.fingerprint!=renamed.fingerprint,"player code enablement is logged")
		if app.session.access.credentials.has("operator"): app.session.access.credentials.erase("operator")
		else: app.session.access.credentials["operator"]={"salt":"private-salt","hash":"private-hash"}
		var changed_operator: Dictionary=app.settings_snapshot("test")
		check(changed_operator.access_codes_enabled.settings!=protected_player.access_codes_enabled.settings and changed_operator.fingerprint!=protected_player.fingerprint,"manager code enablement is logged")
		app.session.player_profiles[0].image="private-image-data"
		var with_image: Dictionary=app.settings_snapshot("test")
		check(with_image.players[0].custom_image_present and with_image.fingerprint!=changed_operator.fingerprint,"custom image presence is logged")
		check(not JSON.stringify(with_image).contains("private-"),"snapshot contains no credential material or image data")
	app.queue_free(); await process_frame
	print("Revision 19 failures: ",failures); quit(1 if failures else 0)
