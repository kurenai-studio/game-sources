extends SceneTree
const Session = preload("res://core/game_session.gd")
var checks := 0
var failures := 0
func check(value: bool, caption: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + caption)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var settings = load("res://core/game_settings.gd").new()
	check(settings.values.has("horse_scale") and settings.values.has("lane_spacing"),"horse size and visual lane spacing are adjustable")
	if settings.values.has("horse_scale"):
		var old_settings: Dictionary = settings.export_data()
		old_settings.schema = 1
		old_settings.values.erase("horse_scale")
		old_settings.values.erase("lane_spacing")
		old_settings.profiles["Old preset"] = old_settings.values.duplicate(true)
		check(settings.restore(old_settings) and settings.profiles["Old preset"].has("horse_scale"),"legacy settings and named presets migrate together")
	var game = Session.new()
	game.fund_demo()
	check(game.players[0].state == "BETTING","Player 1 starts In")
	for i in range(1,8):
		check(game.players[i].state == "OUT","Player %d starts Out" % (i+1))
	game.set_ready(0,true)
	check(game.can_start(),"Player 1 can start without clearing seven seats")
	for i in range(1,8):
		game.set_out(i)
	game.start_race(51)
	game.finish_race(game._race.run())
	game.announce_result()
	game.next_round()
	check(game.players[7].state == "OUT","Out persists to next round")
	var legacy = Session.new()
	legacy.fund_demo()
	for player in legacy.players:
		player.state = "BETTING"
	legacy.edit_bet(2,"1-2",3)
	var snapshot: Dictionary = legacy.export_data()
	snapshot.schema = 2
	var migrated = Session.new()
	check(migrated.restore(snapshot),"old session migrates")
	check(migrated.players[1].state == "OUT" and migrated.players[2].state == "BETTING" and migrated.wager_total(2) == 3,"migration sits out unused automatic demo seats and preserves wagers")
	check(migrated.players[1].balance == 100,"seating does not remove credits")
	var app = load("res://ui/main.tscn").instantiate()
	app.save_path = "user://sigma-test-%d.json" % OS.get_process_id()
	app.instance_guard.acquire(0) # Isolated test lock; never touch the running user session.
	root.add_child(app)
	await process_frame
	app.select_player(0)
	await process_frame
	var left: Node = app.find_child("PlayerConsole",true,false)
	check(left.is_ancestor_of(app.find_child("PlayerReady",true,false)),"Ready is on left panel")
	check(left.is_ancestor_of(app.find_child("PlayerOut",true,false)),"Out is on left panel")
	var bet: Button = app.find_child("BetUp_1_2",true,false)
	check(bet != null,"machine has a physical-style increase button per pair")
	if bet != null:
		bet.pressed.emit()
		check(app.session.wager_total(0) == 1,"BET increments selected player's wager")
	await process_frame
	await process_frame
	var last_summary: Control = app.find_child("PlayerSummary7",true,false)
	check(last_summary.get_global_rect().end.y <= app.body.get_parent().get_global_rect().end.y,"all eight summaries fit at standard text size")
	await capture("sigma-console")
	app.flow.ready()
	app.show_betting()
	for i in range(1,8):
		app.session.set_out(i)
	app.start_race()
	check(app.display_phase == "RACING","single player starts race")
	app._process(12.0)
	await process_frame
	check(app.track.geometry.lane_width >= 40.0,"wider visual lanes")
	check(app.track.directional,"horses turn along travel direction")
	await capture("sigma-race")
	app._process(130.0)
	app.display_phase = "REPLAY"
	app.playback.photo_monochrome = false
	app.playback.show_horse_numbers = false
	app.playback.always_numbers = false
	app._process(100.0)
	check(app.display_phase == "PHOTO" and not app.track.photo,"color photo review is supported")
	if app.track.has_method("number_visible"):
		check(app.track.number_visible(app.visual_result.second),"photo highlight remains visible with normal numbers hidden")
	else:
		check(false,"photo highlight visibility is independent of normal numbers")
	if app.track.has_method("number_font_size"):
		check(app.track.number_font_size() >= 26,"enlarged photo numbers work with monochrome off")
	else:
		check(false,"photo-number enlargement is independent of monochrome")
	app.playback.show_horse_numbers = true
	app.playback.always_numbers = true
	for frame in range(2000):
		if app.session.phase == "SETTLED":
			break
		app._process(0.05)
	check(app.session.phase == "SETTLED","Sigma race settles")
	check(not app.track.moving,"horse stepping stops after settlement")
	check(app.track.highlights == [app.visual_result.first,app.visual_result.second],"both official finish numbers highlighted")
	if app.track.has_method("number_color"):
		app.track._highlight_clock = 0.0
		var first_color: Color = app.track.number_color(app.visual_result.first)
		app.track._highlight_clock = 0.7
		check(app.track.number_color(app.visual_result.first) != first_color,"number flashes independently of horse motion")
		app.track.preferences.reduce_flashing = true
		var steady: Color = app.track.number_color(app.visual_result.first)
		app.track._highlight_clock = 0.0
		check(app.track.number_color(app.visual_result.first) == steady,"reduced flashing keeps steady highlight")
		app.track.preferences.reduce_flashing = false
		app.track._highlight_clock = 0.0
	else:
		check(false,"number-only finish highlighting available")
	await process_frame
	await capture("sigma-finish")
	app.queue_free()
	await process_frame
	await process_frame
	print("SIGMA: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
func capture(caption: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw() # Idle windows intentionally skip automatic redraws.
	DirAccess.make_dir_recursive_absolute("res://test-results")
	check(root.get_texture().get_image().save_png("res://test-results/"+caption+".png") == OK,"capture " + caption)
