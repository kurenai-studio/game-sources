# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Times the first frames of a wave through the real App, to find first-time work: a saved game is
## resumed through App.resume_game(), the wave is started the way the Start button does (the tap
## is timed on its own), and every frame of the next seconds is timed. The HUD, the panels and the
## audio run too, so a hitch that is not the map's shows up here. Needs a display. The saves go to
## a folder under user://tests/render/.
##
##     godot --path . --script res://tests/render/first_wave_app.gd -- save=PATH_TO_game_level.json [fps=60] [speed=3]
##
## Options: `parts` times start_next_wave, hud.refresh and save_active one by one instead of the
## tap; `lock_first` builds the HUD's lock icon (IconTex) before the tap, to show what the tap costs
## without it; `manual` runs the battle screen's frame() from here and times the script part;
## `nomap` hides the map. Prints the frames of the first two seconds that took more than 12 ms over
## the frame time, and a summary. The numbers are for this PC, not the phone (docs/ARCHITECTURE.md 9.4).

const Fx: GDScript = preload("res://tests/render/render_fixtures.gd")
const DIR: String = "user://tests/render/first_wave_app/"
const SECONDS: float = 4.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var args: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() == 2 else ""
	Engine.max_fps = int(String(args.get("fps", "60")))
	var game: GameData = GameData.load_from("res://data")
	DirAccess.make_dir_recursive_absolute(DIR)
	for name: String in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR + name)
	var file: FileAccess = FileAccess.open(DIR + "game_level.json", FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(String(args.get("save", ""))))
	file.close()
	var store: SaveStore = SaveStore.new(DIR)
	var saved: Array[SavedGame] = store.load_games(game)
	if saved.is_empty():
		printerr("the save did not load")
		quit(2)
		return
	var host: SubViewport = SubViewport.new()
	host.size = Vector2i(904, 2316)
	host.size_2d_override = Fx.COVER
	host.size_2d_override_stretch = true
	host.transparent_bg = false
	host.disable_3d = true
	host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(host)
	var made: App = App.new()
	made.game = game
	made.store = store
	made.end_delay = 0.0
	made.build()
	host.add_child(made)
	for i: int in 5:
		await process_frame
	made.apply_layout(Vector2(Fx.COVER), Rect2(Vector2.ZERO, Vector2(Fx.COVER)))
	for id: StringName in made.game.catalog.tower_ids():
		made.progress.mark_seen(id)
	for id: StringName in made.game.catalog.enemy_ids():
		made.progress.mark_seen(id)
	made.resume_game(saved[0])
	for i: int in 20:
		await process_frame
	var screen: BattleScreen = made.battle_screen()
	screen.resume()
	screen.clock.speed = int(String(args.get("speed", "3")))
	# A real phone is a moment in the build phase after the level opens, then a tap.
	for i: int in 30:
		await process_frame
	if args.has("lock_first"):
		var i0: int = Time.get_ticks_usec()
		IconTex.make(&"lock", 56)
		print("   IconTex.make(lock, 56) alone took %.1f ms" % [float(Time.get_ticks_usec() - i0) / 1000.0])
	if args.has("manual"):
		screen.set_process(false)
	if args.has("nomap"):
		screen.map_view.visible = false
	var t_call: int = Time.get_ticks_usec()
	if args.has("parts"):
		var p0: int = Time.get_ticks_usec()
		screen.battle.start_next_wave()
		var p1: int = Time.get_ticks_usec()
		screen.hud.refresh()
		var p2: int = Time.get_ticks_usec()
		made.save_active()
		var p3: int = Time.get_ticks_usec()
		print("   start_next_wave %.1f ms, hud.refresh %.1f ms, save_active %.1f ms" % [float(p1 - p0) / 1000.0, float(p2 - p1) / 1000.0, float(p3 - p2) / 1000.0])
	else:
		screen.hud._on_call()
	print("   the Start tap itself took %.1f ms" % [float(Time.get_ticks_usec() - t_call) / 1000.0])
	var started: int = Time.get_ticks_usec()
	var last: int = t_call
	var dts: PackedFloat32Array = PackedFloat32Array()
	var stamps: PackedFloat32Array = PackedFloat32Array()
	while float(Time.get_ticks_usec() - started) < SECONDS * 1000000.0:
		await process_frame
		var now: int = Time.get_ticks_usec()
		if args.has("manual"):
			var f0: int = Time.get_ticks_usec()
			screen.frame(float(now - last) / 1000000.0)
			var script_ms: float = float(Time.get_ticks_usec() - f0) / 1000.0
			if script_ms > 3.0 or dts.size() < 3:
				print("   frame %d: script %.1f ms, whole frame %.1f ms" % [dts.size(), script_ms, float(now - last) / 1000.0])
		dts.append(float(now - last) / 1000.0)
		stamps.append(float(now - started) / 1000000.0)
		last = now
	var worst: float = 0.0
	var spikes: int = 0
	for i: int in dts.size():
		if stamps[i] < 2.0 and dts[i] > 12.0 + 1000.0 / float(Engine.max_fps if Engine.max_fps > 0 else 60):
			print("   spike: frame %d at %.2f s took %.1f ms" % [i, stamps[i], dts[i]])
		if i > 0:
			worst = maxf(worst, dts[i])
		if i > 0 and dts[i] > 25.0:
			spikes += 1
	print("== first wave through the App: %d frames, worst %.1f ms, frames over 25 ms: %d, live at the end %d" % [dts.size(), worst, spikes, screen.battle.enemies.size()])
	quit(0)
