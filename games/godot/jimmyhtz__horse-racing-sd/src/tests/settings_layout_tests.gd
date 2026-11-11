extends SceneTree
var failures := 0
func check(ok: bool, caption: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var settings = load("res://core/game_settings.gd").new()
	var panel = load("res://ui/settings_panel.gd").new()
	root.add_child(panel)
	var changes := [0]
	panel.configure(settings,func(): changes[0] += 1)
	var profiles_page = panel.profile_picker.get_parent().get_parent().get_parent()
	check(profiles_page is ScrollContainer and profiles_page.name == "Saved profiles" and profiles_page.get_parent() == panel.tabs,"profile controls have a dedicated page")
	var light = panel.find_child("Setting_light_intensity",true,false)
	check(light.get_child(1) is HSlider,"intensity uses a slider")
	check(light.find_child("ReadableValue",true,false) != null,"intensity has a readable value label")
	panel.filter_rows("volume")
	var audio = panel.find_child("Setting_master_volume",true,false)
	check(audio.get_parent() == panel.tabs.get_current_tab_control().get_child(0),"search results appear across categories")
	panel.filter_rows("horse")
	check(panel.find_child("Setting_horse_scale",true,false).get_parent() == panel.find_child("Setting_horse_style",true,false).get_parent(),"search combines active race controls and planned skin controls")
	panel.filter_rows("  HORSE APPEARANCE  ")
	check(panel.find_child("Setting_horse_style",true,false).visible,"search ignores case and surrounding spaces")
	panel.filter_rows("")
	check(panel.rows.size() == settings.catalog.size(),"search preserves every catalog row")
	if light.get_child(1) is HSlider:
		light.get_child(1).value = 0.5
		check(settings.values.light_intensity == 0.5 and changes[0] == 1,"slider changes apply immediately once")
		check(light.find_child("ReadableValue",true,false).text == "50%","slider value is human readable")
	panel.queue_free()
	await process_frame
	print("SETTINGS LAYOUT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
