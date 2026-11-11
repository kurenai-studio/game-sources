extends SceneTree
var failures:=0
func check(ok: bool, why: String):
	if not ok:failures+=1;printerr("FAIL: "+why)
func _init():
	var settings=load("res://core/game_settings.gd").new()
	var old: Dictionary=settings.export_data();old.schema=9
	old.values.race_spread=0.25;old.values.race_lead_changes=0.15;old.values.photo_frequency=28
	old.profiles["Personal alternative"]=old.values.duplicate(true)
	check(settings.restore(old),"old saved preferences remain loadable")
	check(settings.values.race_spread==1.0 and settings.values.race_lead_changes==0.5 and settings.values.photo_frequency==20,"approved new setup applied at the midpoint once")
	check(settings.profiles["Personal alternative"].race_spread==0.25 and settings.profiles["Personal alternative"].photo_frequency==28,"named profiles are preserved")
	settings.values.race_spread=0.0;settings.values.photo_frequency=7
	check(settings.restore(settings.export_data()) and settings.values.race_spread==0.0 and settings.values.photo_frequency==7,"later changes survive reopening")
	print("Settings21 failures=",failures);quit(1 if failures else 0)
