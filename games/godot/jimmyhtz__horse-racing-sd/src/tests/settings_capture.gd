extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("run")
func capture(panel: Window, category: String, filename: String) -> void:
	for index in range(panel.navigation.item_count):
		if panel.navigation.get_item_text(index) == category: panel.navigate(index)
	await process_frame
	await process_frame
	RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
	root.get_texture().get_image().save_png("res://test-results/"+filename+".png")
	for row in panel.rows:
		if row.node.is_visible_in_tree():
			var scroll: ScrollContainer = panel.tabs.get_current_tab_control()
			if row.node.size.x > scroll.size.x:
				failed = true
				printerr("FAIL: clipped setting row "+row.node.name)
func run() -> void:
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://settings-capture-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(app)
	await process_frame
	app.show_settings()
	await process_frame
	var panel: Window = app.settings_panel
	await capture(panel,"Settings Home","settings-home-09")
	await capture(panel,"Display","settings-display-09")
	await capture(panel,"Audio","settings-audio-09")
	await capture(panel,"Modes and skins","settings-planned-09")
	await capture(panel,"Saved profiles","settings-profiles-09")
	panel.search.text = "horse"
	panel.filter_rows("horse")
	await process_frame
	RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
	root.get_texture().get_image().save_png("res://test-results/settings-search-09.png")
	panel.return_to_game()
	app.preferences.values.ui_scale = 1.75
	app.preferences.values.large_text = true
	app.preferences.values.resolution = "1280 x 720"
	app.apply_settings()
	app.show_settings()
	await process_frame
	await capture(app.settings_panel,"Display","settings-large-09")
	app.queue_free()
	await process_frame
	print("SETTINGS CAPTURE: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
