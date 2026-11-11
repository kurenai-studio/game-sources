extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var prefs=load("res://core/game_settings.gd").new()
	check(prefs.values.get("photo_frequency",0)==20,"20 percent photo target default")
	check(prefs.values.race_spread==1.0 and prefs.values.race_lead_changes==0.5,"tested race defaults")
	var old: Dictionary=prefs.export_data(); old.schema=8
	old.values.erase("photo_frequency"); old.values.photo_threshold=10.0
	old.values.race_spread=0.5; old.values.race_energy=0.6
	old.profiles["My original"]=old.values.duplicate(true)
	var migrated=load("res://core/game_settings.gd").new()
	check(migrated.restore(old),"schema eight current game migrates")
	check(migrated.values.race_spread==1.0 and migrated.values.race_energy==0.8,"approved current setup applied once")
	check(migrated.profiles["My original"].race_spread==0.5 and migrated.profiles["My original"].race_energy==0.6,"named alternatives keep their original effect")
	migrated.values.race_spread=0.0
	check(migrated.restore(migrated.export_data()) and migrated.values.race_spread==0.0,"new adjustments survive reopening without another reset")
	check(ResourceLoader.exists("res://core/slider_scale.gd"),"centered slider mapping available")
	if ResourceLoader.exists("res://core/slider_scale.gd"):
		var scale=load("res://core/slider_scale.gd")
		for item in prefs.catalog:
			if item.type!="number" or not item.has("center"): continue
			check(is_equal_approx(scale.to_position(item,item.center),.5),"preferred value at midpoint: "+item.key)
			check(is_equal_approx(scale.from_position(item,0),item.limits[0]) and is_equal_approx(scale.from_position(item,1),item.limits[1]),"both endpoints reachable: "+item.key)
			for i in range(101):
				var raw: float=lerpf(item.limits[0],item.limits[1],i/100.0)
				check(absf(scale.from_position(item,scale.to_position(item,raw))-raw)<=float(item.limits[2])*.501,"round trip within one half step: "+item.key)
	check(ResourceLoader.exists("res://core/replay_policy.gd"),"gap-based replay policy available")
	if ResourceLoader.exists("res://core/replay_policy.gd"):
		var policy=load("res://core/replay_policy.gd")
		var previous:=-1.0
		for percent in range(1,31):
			var config: Dictionary=policy.configuration(percent)
			check(config.threshold>=previous,"larger target never tightens the gap")
			previous=config.threshold
			check(config.tie_fraction>=0 and config.tie_fraction<=1,"valid tie boundary probability")
			check(absf(policy.calibrated_fraction(config)-percent/100.0)<.00001,"expected calibration frequency matches each target")
		var sample: Dictionary={"first":0,"second":1,"positions":[1000.1,1000.0,980.0,975.0,970.0],"seed":"a".repeat(64)}
		var config: Dictionary=policy.configuration(20)
		check(not policy.decide(sample,config).replay,"close first/second alone does not trigger")
		sample.positions[2]=999.99
		var before: Dictionary=sample.duplicate(true)
		check(policy.decide(sample,config).replay,"genuine very close second/third triggers")
		check(sample==before,"replay policy cannot mutate result")
		check(policy.decide(sample,config)==policy.decide(sample,config),"decision stable across repeated UI reads")
	var panel=load("res://ui/settings_panel.gd").new(); root.add_child(panel); panel.configure(prefs,func(): pass)
	var slider=panel.find_child("Setting_photo_frequency",true,false).find_child("ValueSlider",true,false)
	check(is_equal_approx(slider.value,.5),"20 percent target visibly centered")
	var key:=InputEventKey.new(); key.pressed=true; key.keycode=KEY_RIGHT
	slider.gui_input.emit(key)
	check(prefs.values.photo_frequency==21,"one arrow press changes exactly one percent")
	key.keycode=KEY_HOME; slider.gui_input.emit(key)
	check(prefs.values.photo_frequency==1 and is_zero_approx(slider.value),"Home reaches lower endpoint")
	key.keycode=KEY_END; slider.gui_input.emit(key)
	check(prefs.values.photo_frequency==30 and is_equal_approx(slider.value,1.0),"End reaches upper endpoint")
	panel.queue_free(); await process_frame
	print("Settings 20 failures: ",failures); quit(1 if failures else 0)
