extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(view: Viewport, name: String) -> void:
	await process_frame; await process_frame; RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://test-results/"+name+"-20.png")
func run() -> void:
	var app=load("res://ui/main.gd").new(); app.instance_guard.acquire(0)
	root.add_child(app); root.size=Vector2i(1440,900)
	app.game_library.save_game(app.session,app.preferences,"Friday game")
	var other: Dictionary=load("res://core/new_game.gd").from_current(app.session,app.preferences)
	app.game_library.save_game(other.session,other.settings,"Weekend game")
	app.open_settings(""); await process_frame
	await shot(app.settings_panel,"settings-home")
	for section in ["Race Control","Announcers","Optional support"]:
		for i in range(app.settings_panel.navigation.item_count):
			if app.settings_panel.navigation.get_item_text(i)==section: app.settings_panel.navigate(i)
		await shot(app.settings_panel,"settings-"+section.to_lower().replace(" ","-"))
	var support=app.settings_panel.find_child("Support5",true,false).get_parent().get_parent()
	var amount: AcceptDialog=support.show_amount(10); await shot(amount,"support-amount")
	if amount.size.y>root.size.y: printerr("FAIL: support dialog exceeds window"); quit(1); return
	amount.queue_free(); await process_frame
	app.game_file_action("Load Game"); await process_frame
	var library=app.settings_panel.find_child("SavedGames",true,false)
	await shot(library,"saved-games"); library.queue_free(); await process_frame
	app.game_file_action("Save Game"); await process_frame
	var save=app.settings_panel.find_child("SaveGameName",true,false)
	await shot(save,"save-game-name"); save.queue_free(); await process_frame
	app.game_file_action("New Game"); await process_frame
	for child in app.settings_panel.get_children():
		if child is ConfirmationDialog: await shot(child,"new-game-confirmation"); child.queue_free()
	print("SETTINGS20 CAPTURE PASS")
	app.queue_free(); await process_frame; quit()
