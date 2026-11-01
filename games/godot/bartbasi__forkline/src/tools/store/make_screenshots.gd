# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Renders a few real screens of the app at phone size for the Google Play listing and
## writes them to docs/store/graphics/. It runs the real App (src/ui/app.gd) inside a
## SubViewport, with the bundled data, a throwaway save folder and the sound off.
## It needs a rendering display, so run it without --headless, from the repo root:
##     godot --path . --script res://tools/store/make_screenshots.gd
## Optional: -- --only=front_door (one screen, by the name in SCREENS).
## It opens a window for about a minute and exits 0 when every file is written.
## Nothing here ships in the APK, and it never touches the player's real saves.
##
## Size: 1080 x 2160, the tallest shape Play accepts (twice as tall as wide). The
## picture is 24 bit PNG with no see-through pixels.

const OUT_DIR: String = "res://docs/store/graphics"
const SIZE: Vector2i = Vector2i(1080, 2160)
## A small top inset, as a phone's camera cutout would leave.
const SAFE: Rect2 = Rect2(0.0, 72.0, 1080.0, 2088.0)
const SAVE_DIR: String = "user://store_shots/"
## The build phase picture: level 1-2 before wave 5. The wave picture: level 3-2.
const LEVEL: StringName = &"r1_l2"
const BUILD_AT: int = 4
const WAVE_LEVEL: StringName = &"r3_l2"
const SCREENS: Array[String] = ["front_door", "modes", "levels", "build", "wave"]
## The stars shown on the level list: level id to star bits.
const STARS: Dictionary[StringName, int] = {&"r1_l1": 7, &"r1_l2": 7, &"r1_l3": 7, &"r1_l4": 7, &"r1_l5": 1}
## How many waves are played out of sight before the pictures are taken.
const WAVE_AT: int = 5
## The lowest frame score the wave picture may have.
const MIN_SCORE: int = 30
const WAVE_SECONDS: float = 25.0
## Gold given before each round of building, for the picture only.
const SHOT_GOLD: int = 700
## The gold the HUD shows in the pictures, set after the building.
const SHOWN_GOLD: int = 140

var _only: String = ""
var _host: SubViewport
var _app: App
var _audio: AudioService
var _failed: int = 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("make_screenshots.gd needs a display. Run it without --headless.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_wipe()
	await _start_app()
	if _wants("front_door"):
		await _shoot("screen_1_front_door.png")
	_app.open_mode()
	await _frames(6)
	if _wants("modes"):
		await _shoot("screen_2_modes.png")
	_app.campaign_requested.emit()
	await _frames(6)
	if _wants("levels"):
		await _shoot("screen_3_levels.png")
	if _wants("build") or _wants("wave"):
		await _battle()
	_app.queue_free()
	_audio.queue_free()
	_host.queue_free()
	await _frames(2)
	_wipe()
	quit(1 if _failed > 0 else 0)


func _wants(screen_name: String) -> bool:
	return _only.is_empty() or _only == screen_name


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


## The real App on the bundled data. Saves go to a folder of their own, and the sound is off.
func _start_app() -> void:
	_host = SubViewport.new()
	_host.size = SIZE
	_host.disable_3d = true
	_host.transparent_bg = false
	_host.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_host)
	_audio = AudioService.new()
	_audio.set_enabled(false)
	root.add_child(_audio)
	_app = (load("res://scenes/ui/app.tscn") as PackedScene).instantiate() as App
	_app.game = GameData.load_from("res://data")
	_app.store = SaveStore.new(SAVE_DIR)
	_app.audio = _audio
	_app.date_source = func() -> Dictionary: return {"year": 2026, "month": 10, "day": 24}
	_app.seed_source = func() -> int: return 1234
	_host.add_child(_app)
	await _frames(3)
	_app.apply_layout(Vector2(SIZE), SAFE)
	for id: StringName in STARS:
		_app.progress.record_level(id, STARS[id])
	for id: StringName in _app.game.catalog.tower_ids():
		_app.progress.mark_seen(id)
	for id: StringName in _app.game.catalog.enemy_ids():
		_app.progress.mark_seen(id)
	_app.save_progress()
	await _frames(6)


## Plays a level through the real screens: a defense is built, a few waves are played out of
## sight, and the screen is left in the build phase before the next wave. Null if it did not start.
func _prepare_battle(level: StringName, waves_before: int) -> BattleScreen:
	_app.start_level(level, false)
	await _frames(4)
	var screen: BattleScreen = _app.battle_screen()
	if screen == null:
		printerr("The battle did not start.")
		_failed += 1
		return null
	var b: Battle = screen.battle
	_spend(screen)
	if not b.level.sockets.is_empty():
		b.place_gate(b.level.sockets[0])
	while b.waves_started < waves_before and b.phase == Battle.Phase.BUILD:
		b.start_next_wave()
		var guard: int = 0
		while b.phase == Battle.Phase.WAVE and guard < 20000:
			b.step()
			guard += 1
		b.take_events()
		if b.phase == Battle.Phase.BUILD:
			_spend(screen)
	screen.close_context()
	b.gold = SHOWN_GOLD
	await _frames(8)
	return screen


## The build phase on The Fork, with route lines, then a wave on a later level.
func _battle() -> void:
	if _wants("build"):
		var screen: BattleScreen = await _prepare_battle(LEVEL, BUILD_AT)
		if screen == null:
			return
		await _shoot("screen_4_build_phase.png")
		screen.left.emit()
		await _frames(6)
	if _wants("wave"):
		await _wave_picture()


## A wave in progress on WAVE_LEVEL. Every frame is looked at and the busiest one is kept.
func _wave_picture() -> void:
	var screen: BattleScreen = await _prepare_battle(WAVE_LEVEL, WAVE_AT)
	if screen == null:
		return
	var b: Battle = screen.battle
	if b.phase != Battle.Phase.BUILD:
		printerr("The level ended before the wave picture.")
		_failed += 1
		return
	b.start_next_wave()
	screen.clock.speed = 2
	var best: Image = null
	var best_score: int = -1
	var started: int = Time.get_ticks_usec()
	while b.phase == Battle.Phase.WAVE:
		await RenderingServer.frame_post_draw
		var elapsed: float = float(Time.get_ticks_usec() - started) / 1000000.0
		if elapsed > WAVE_SECONDS:
			break
		var score: int = _wave_score(b, screen.map_view)
		if score > best_score:
			best_score = score
			best = _host.get_texture().get_image()
	if best == null or best_score < MIN_SCORE:
		printerr("No frame of the wave was busy enough (best score %d)." % best_score)
		_failed += 1
		if best == null:
			return
	print("wave picture score: %d" % best_score)
	_save(best, "screen_5_wave.png")


## How good this frame looks for a store picture, or -1 when it is not usable. It wants
## creatures spread along the road (not one stack), a lobbed shot or a splash, and shots of more
## than one kind in the air.
func _wave_score(b: Battle, map: MapView) -> int:
	var shots: MapShots = map.get("_shots") as MapShots
	if shots == null or b.enemies.size() < 4:
		return -1
	var looks: Dictionary[int, bool] = {}
	var lobbed: int = 0
	for s: MapShots.Shot in shots.shots:
		looks[s.look] = true
		if MapShots.is_lobbed(s.look):
			lobbed += 1
	var splashes: int = 0
	for f: MapShots.Flash in shots.flashes:
		if f.kind == MapShots.Fx.SPLASH:
			splashes += 1
	if lobbed + splashes == 0 or looks.size() < 2:
		return -1
	# Pairs of creatures closer than a third of a cell look like one stack.
	var close: int = 0
	var near: int = Sim.UNIT / 3
	for i: int in b.enemies.size():
		for j: int in range(i + 1, b.enemies.size()):
			if (b.enemies[i].pos - b.enemies[j].pos).length_squared() < near * near:
				close += 1
	var spread: int = maxi(mini(b.enemies.size(), 8) - mini(close, 6), 0)
	return 4 * mini(looks.size(), 4) + 5 * mini(lobbed, 2) + 3 * mini(splashes, 2) 		+ 2 * mini(shots.shots.size(), 6) + 2 * spread + mini(map.sparkles().active_count(), 4)


## Builds and upgrades through the screen's own panels. The gold is topped up first, so the
## picture shows a full defense and the creatures walk the whole road. The gold is only for
## the picture: it is not how a level is played.
func _spend(screen: BattleScreen) -> void:
	var b: Battle = screen.battle
	b.gold = maxi(b.gold, SHOT_GOLD)
	var types: Array[StringName] = b.level.towers
	var n: int = 0
	for cell: Vector2i in b.level.spots:
		if b.tower_at(cell) == null:
			if _build(screen, cell, types[n % types.size()]):
				n += 1
		else:
			screen.tap_at(cell)
			if screen.tower_panel.is_open() and b.tower_at(cell).tier == 1:
				screen.tower_panel.upgrade()
	screen.close_context()


## The same steps a player takes: tap the spot, pick the tower, confirm.
func _build(screen: BattleScreen, cell: Vector2i, type: StringName) -> bool:
	screen.tap_at(cell)
	if screen.context_panel() != screen.build_panel:
		return false
	screen.build_panel.select_tower(type)
	screen.build_panel.confirm()
	return screen.battle.tower_at(cell) != null


func _shoot(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	_save(_host.get_texture().get_image(), file_name)


func _save(img: Image, file_name: String) -> void:
	img.convert(Image.FORMAT_RGB8)
	var path: String = OUT_DIR.path_join(file_name)
	var err: Error = img.save_png(path)
	print("%s %dx%d: %s" % [path, img.get_width(), img.get_height(), error_string(err)])
	if err != OK:
		_failed += 1


func _wipe() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		return
	for file_name: String in DirAccess.get_files_at(SAVE_DIR):
		DirAccess.remove_absolute(SAVE_DIR + file_name)
	DirAccess.remove_absolute(SAVE_DIR)
