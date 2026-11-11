extends SceneTree
const Settings = preload("res://core/game_settings.gd")
const Audio = preload("res://ui/race_audio.gd")
var checks := 0
var failures := 0
func check(ok: bool, caption: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var settings := Settings.new()
	settings.set_value("master_volume",0.5)
	settings.save_profile("Saved before update")
	var old: Dictionary = settings.export_data()
	old.schema = 2
	for key in settings.added_keys:
		old.values.erase(key)
		old.profiles["Saved before update"].erase(key)
	var restored := Settings.new()
	check(restored.restore(old),"previous saved settings migrate")
	check(restored.values.master_volume == 0.5 and restored.values.hoof_enabled,"migration preserves old values and adds defaults")
	check(restored.profiles["Saved before update"].has("hoof_volume"),"saved profiles migrate too")
	check(restored.import_profile("Old import",{"schema":2,"values":old.values}),"old exported profiles remain importable")
	check(restored.import_profile("New import",restored.export_profile("Old import")),"new profile round trip")
	old.values.erase("master_volume")
	check(not Settings.new().restore(old),"migration does not repair malformed old required values")
	var panel = load("res://ui/settings_panel.gd").new()
	root.add_child(panel)
	panel.configure(restored,func(): pass)
	check(panel.rows.size() == restored.catalog.size(),"all catalog settings are present")
	for key in ["presentation_mode","virtual_style","enable_full_order","history_comments"]:
		var row = panel.find_child("Setting_"+key,true,false)
		check(row != null and row.modulate.r < 0.7,"unfinished setting visibly dimmed")
		if row.get_child(1) is BaseButton: check(row.get_child(1).disabled,"unfinished choice disabled")
		else: check(not row.get_child(1).editable,"unfinished number disabled")
	for key in ["master_volume","hoof_volume","mechanical_volume"]:
		var row = panel.find_child("Setting_"+key,true,false)
		check(row.get_child(1).editable and row.find_child("VolumeSlider",true,false) != null,"working audio volume has active slider")
	for i in range(panel.navigation.item_count):
		if panel.navigation.get_item_text(i) == "Modes and skins": panel.navigate(i)
	check(panel.find_child("Setting_presentation_mode",true,false).visible,"opening category with empty search retains future settings")
	panel.filter_rows("horse appearance")
	check(panel.find_child("Setting_horse_style",true,false).visible and not panel.find_child("Setting_presentation_mode",true,false).visible,"search narrows matching settings")
	panel.filter_rows("")
	check(panel.find_child("Setting_presentation_mode",true,false).visible,"clearing search restores future settings")
	panel.filter_rows("   ")
	check(panel.find_child("Setting_presentation_mode",true,false).visible,"blank search retains settings")
	panel.queue_free()
	var audio := Audio.new()
	audio.preferences = restored.values
	root.add_child(audio)
	await process_frame
	for stream in [audio.mechanical.stream,audio.hoofs.stream]:
		var peak := 0
		for offset in range(0,stream.data.size(),2): peak = maxi(peak,absi(stream.data.decode_s16(offset)))
		check(peak > 1000 and peak < 30000,"sound contains audible unclipped samples")
		check(stream.loop_end*2 == stream.data.size(),"loop endpoints match sample data")
	check(audio.mechanical.stream.data != audio.hoofs.stream.data,"separate mechanical and hoof effects")
	audio.update_playback(true)
	check(audio.mechanical.playing and audio.hoofs.playing,"both effects start with motion")
	audio.preferences.hoof_enabled = false
	audio.update_playback(true)
	check(audio.mechanical.playing and not audio.hoofs.playing,"hoof toggle independent")
	audio.preferences.master_volume = 0.0
	audio.update_playback(true)
	check(not audio.mechanical.playing and not audio.hoofs.playing,"master zero silences both")
	audio.preferences.master_volume = 0.5
	audio.preferences.hoof_enabled = true
	audio.update_playback(true)
	audio.update_playback(false)
	check(not audio.mechanical.playing and not audio.hoofs.playing,"pause and finish stop both")
	audio.queue_free()
	var mini = load("res://ui/mini_bets.gd").new()
	mini.configure({"1-2":4},96)
	root.add_child(mini)
	check(mini.cells["1-2"].amount.ink.get_luminance() > mini.cells["1-3"].amount.ink.get_luminance()*3,"actual wagers much brighter than zero")
	mini.highlight_pair("1-2",true)
	var bright: Color = mini.cells["1-2"].amount.ink
	mini.highlight_pair("1-2",false)
	check(mini.cells["1-2"].amount.ink != bright,"winning wager flashes")
	mini.highlight_pair("1-3",true)
	check(mini.cells["1-3"].amount.ink == Color("24181c"),"unwagered winning pair remains dim")
	mini.queue_free()
	await process_frame
	Audio.loops.clear()
	print("SOUND AND VISIBILITY: %d checks, %d failures; %d settings" % [checks,failures,settings.catalog.size()])
	quit(0 if failures == 0 else 1)
