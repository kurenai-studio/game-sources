extends "res://tests/base_test.gd"
## AT-158: coming back from the browser leaves the run and the save
## untouched (GDD 15.5, TH18, TH24). The hand off is captured (TH24), so no
## browser opens, and leaving and returning is the App's lifecycle
## notifications: focus out, pause, resume, focus in.
##
## The run is set up as AT-158 says: right after a chain, score 12,400, Undo
## enabled, at least 3 stars and 1 free booster held. The app is closed and
## opened again, so the splash shows, and the save files are copied aside.
## After each case the run and profile read from the save must equal, field
## by field, the ones read from the copies set aside.

const U := preload("res://tests/ui/ui_fixtures.gd")
const Copy := preload("res://src/ui/screen_copy.gd")
const CoffeeButton := preload("res://src/ui/coffee_button.gd")

var _dir: String = ""
var _aside: String = ""
var _app: App = null
var _quits: Array[int] = []
var _sent: Array[String] = []


func before_each() -> void:
	_dir = ""
	_aside = ""
	_app = null
	_quits = []
	_sent = []
	CoffeeButton.opener = _capture
	SafeArea.simulated_insets = Vector2(120.0, 66.0)
	Motion.bind_tweens = false


func after_each() -> void:
	_clean_up()
	CoffeeButton.use_system_opener()
	SafeArea.simulated_insets = Vector2(-1.0, -1.0)
	Motion.bind_tweens = true


func _clean_up() -> void:
	if _app != null:
		U.stop_app(_app)
		_app = null
	if not _dir.is_empty():
		U.remove_temp_dir(_dir)
		_dir = ""
	if not _aside.is_empty():
		U.remove_temp_dir(_aside)
		_aside = ""


## TH24: records each address instead of opening a browser.
func _capture(address: String) -> Error:
	_sent.append(address)
	return OK


func _tap(target: Control) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = Vector2(40.0, 40.0)
		event.global_position = Vector2(40.0, 40.0)
		target._gui_input(event)


## The save lands, then the board's frames run until its move has been shown,
## as the board would.
func _settle(app: App) -> void:
	U.gate(app)
	var board: BoardController = app.game_screen().board()
	for frame: int in 900:
		if not board.is_animating():
			return
		board._process(1.0 / 60.0)


## The app goes to the browser and comes back from recent apps.
func _leave_and_return(app: App) -> void:
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)


func _files(folder: String) -> Dictionary[String, PackedByteArray]:
	var found: Dictionary[String, PackedByteArray] = {}
	for file_name: String in DirAccess.get_files_at(folder):
		found[file_name] = FileAccess.get_file_as_bytes(folder.path_join(file_name))
	return found


## Copies every save file in _dir into a new folder, as AT-158's setup does.
func _set_aside() -> String:
	var folder: String = U.make_temp_dir()
	var files: Dictionary[String, PackedByteArray] = _files(_dir)
	for file_name: String in files:
		var out: FileAccess = FileAccess.open(folder.path_join(file_name), FileAccess.WRITE)
		out.store_buffer(files[file_name])
		out.close()
	return folder


## TH18: the run and profile read from the save in folder, through a fresh
## SaveService.
func _read(folder: String) -> Dictionary:
	var service: SaveService = SaveService.new(folder)
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	service.load_profile(settings, records)
	return {"run": service.load_run(GameConfig.new()), "settings": settings, "records": records}


## The run and profile read from the save equal, field by field, the ones
## read from the copies set aside.
func _assert_save_as_aside(app: App, label: String) -> void:
	U.settle(app)
	var now: Dictionary = _read(_dir)
	var aside: Dictionary = _read(_aside)
	var run_now: RunState = now["run"] as RunState
	var run_aside: RunState = aside["run"] as RunState
	assert_not_null(run_aside, "%s: the copy set aside holds a run" % label)
	assert_not_null(run_now, "%s: the saved run loads" % label)
	if run_now != null and run_aside != null:
		assert_eq(run_now.cells, run_aside.cells, "%s: board" % label)
		assert_eq(U.text(run_now.score), U.text(run_aside.score), "%s: score" % label)
		assert_eq(run_now.run_highest, run_aside.run_highest, "%s: run highest tile" % label)
		assert_eq(run_now.free_used, run_aside.free_used, "%s: free boosters used" % label)
		assert_eq(run_now.snapshot_cells, run_aside.snapshot_cells, "%s: the Undo board" % label)
		assert_eq(U.text(run_now.snapshot_points), U.text(run_aside.snapshot_points), "%s: the Undo points" % label)
		assert_true(run_now.equals(run_aside), "%s: the whole run, snapshot included" % label)
	var settings_now: Settings = now["settings"] as Settings
	var settings_aside: Settings = aside["settings"] as Settings
	assert_eq(settings_now.skin_id, settings_aside.skin_id, "%s: skin" % label)
	assert_eq(settings_now.sound_on, settings_aside.sound_on, "%s: sound" % label)
	var records_now: Records = now["records"] as Records
	var records_aside: Records = aside["records"] as Records
	assert_eq(U.text(records_now.best_score), U.text(records_aside.best_score), "%s: Best Score" % label)
	assert_eq(records_now.best_tile, records_aside.best_tile, "%s: Best Tile" % label)
	# The run and profile files themselves, byte for byte. A lifecycle save
	# writes them again with the same bytes, and that moves the old bytes into
	# each backup, so backups are left out here.
	var files_now: Dictionary[String, PackedByteArray] = _files(_dir)
	var files_aside: Dictionary[String, PackedByteArray] = _files(_aside)
	for file_name: String in files_aside:
		if file_name.ends_with(".bak"):
			continue
		assert_true(files_now.get(file_name, PackedByteArray()) == files_aside[file_name], "%s: %s byte for byte" % [label, file_name])


func _statuses(app: App) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for status: BoosterStatus in app.session.booster_statuses():
		parts.append("%s %d %s %s" % [status.id, status.cost, status.usable, status.free])
	return ", ".join(parts)


## PLAY shows the run exactly as noted, every booster reads Free.
func _assert_run_as_noted(app: App, noted: RunState, statuses: String, label: String) -> void:
	assert_true(app.session.state.equals(noted), "%s: the run as noted" % label)
	assert_eq(_statuses(app), statuses, "%s: booster costs, usability and Free" % label)
	for status: BoosterStatus in app.session.booster_statuses():
		assert_true(status.free, "%s: %s reads Free" % [label, status.id])


func test_at_158_coming_back_from_the_browser() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var label: String = "%s" % skin_id
		# Setup: a run right after a chain, score 12,400 (12,396 plus the
		# chain's 4), the 8192 tile for 3 stars and 1 free booster held.
		_dir = U.make_temp_dir()
		var settings: Settings = Settings.new()
		settings.set_skin_id(skin_id)
		settings.set_sound_on(false)
		U.save_game(_dir, U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 13), 12396), 12396, 13, settings)
		_app = U.start_app(_dir, _quits)
		U.play(_app)
		_settle(_app)
		var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
		assert_true(_app.session.commit_chain(chain).accepted, "%s: a chain" % label)
		_settle(_app)
		assert_eq(U.text(_app.session.state.score), "12400", "%s: score 12,400" % label)
		assert_true(_app.session.stars() >= 3, "%s: at least 3 stars" % label)
		assert_eq(_app.session.free_held(), 1, "%s: 1 free booster held" % label)
		var undo_usable: bool = false
		for status: BoosterStatus in _app.session.booster_statuses():
			if status.id == &"undo":
				undo_usable = status.usable
		assert_true(undo_usable, "%s: Undo enabled" % label)
		var noted: RunState = _app.session.state.copy()
		var statuses: String = _statuses(_app)
		# Close the app fully and open it again: the splash shows.
		U.stop_app(_app)
		_app = U.start_app(_dir, _quits)
		_aside = _set_aside()
		var app: App = _app
		var splash: SplashScreen = app.splash_screen()
		assert_not_null(splash, "%s: the splash at launch" % label)

		# (a) The splash button, out and back.
		_tap(splash.coffee_button())
		assert_eq(_sent.size(), 1, "%s (a): one hand off" % label)
		_leave_and_return(app)
		assert_eq(app.splash_screen(), splash, "%s (a): the splash as it was left" % label)
		assert_null(app.game_screen(), "%s (a): not the play screen" % label)
		assert_true(app.open_panels().is_empty(), "%s (a): nothing over it" % label)
		assert_true(app.has_held_run(), "%s (a): the run still held for PLAY" % label)
		_assert_save_as_aside(app, "%s (a)" % label)

		# (b) About over the splash, its button, out and back.
		splash.about_chosen.emit()
		var about: AboutPanel = app.top_panel() as AboutPanel
		assert_not_null(about, "%s (b): About open" % label)
		_tap(about.coffee_button())
		assert_eq(_sent.size(), 2, "%s (b): one hand off" % label)
		_leave_and_return(app)
		assert_eq(app.open_panels(), [about] as Array[Control], "%s (b): About, still open" % label)
		assert_false(about.is_closing(), "%s (b): not closing" % label)
		assert_eq(app.splash_screen(), splash, "%s (b): still over the splash" % label)
		_assert_save_as_aside(app, "%s (b)" % label)
		app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		assert_true(app.open_panels().is_empty(), "%s (b): back closes About" % label)

		# (c) PLAY, Pause, Settings, About, its button, out and back.
		U.play(app)
		_assert_run_as_noted(app, noted, statuses, "%s (c) after PLAY" % label)
		var game: GameScreen = app.game_screen()
		app.open_pause()
		var pause: PausePanel = app.top_panel() as PausePanel
		pause.settings_chosen.emit()
		var settings_panel: SettingsPanel = app.top_panel() as SettingsPanel
		assert_not_null(settings_panel, "%s (c): Settings over Pause" % label)
		settings_panel.about_chosen.emit()
		about = app.top_panel() as AboutPanel
		assert_not_null(about, "%s (c): About over Settings" % label)
		_tap(about.coffee_button())
		assert_eq(_sent.size(), 3, "%s (c): one hand off" % label)
		_leave_and_return(app)
		assert_eq(app.open_panels(), [pause, settings_panel, about] as Array[Control], "%s (c): About, still over Settings over Pause" % label)
		assert_false(about.is_closing(), "%s (c): not closing" % label)
		assert_eq(app.game_screen(), game, "%s (c): the same play screen under them" % label)
		_assert_save_as_aside(app, "%s (c)" % label)
		for index: int in 3:
			app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		assert_true(app.open_panels().is_empty(), "%s (c): back three times returns to the run" % label)
		assert_eq(app.game_screen(), game, "%s (c): the play screen" % label)
		_assert_run_as_noted(app, noted, statuses, "%s (c) after back" % label)
		assert_eq(app.settings.skin_id, skin_id, "%s (c): skin unchanged" % label)
		assert_false(app.settings.sound_on, "%s (c): sound unchanged" % label)
		_assert_save_as_aside(app, "%s (c) resumed" % label)

		# (d) As (a), but the app is ended while the browser is open.
		U.stop_app(_app)
		_app = U.start_app(_dir, _quits)
		app = _app
		splash = app.splash_screen()
		_tap(splash.coffee_button())
		assert_eq(_sent.size(), 4, "%s (d): one hand off" % label)
		app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		U.stop_app(_app)
		_app = U.start_app(_dir, _quits)
		app = _app
		assert_not_null(app.splash_screen(), "%s (d): the splash, as at any launch" % label)
		assert_null(app.game_screen(), "%s (d): not the play screen" % label)
		assert_true(app.open_panels().is_empty(), "%s (d): nothing over it" % label)
		_assert_save_as_aside(app, "%s (d)" % label)
		U.play(app)
		_assert_run_as_noted(app, noted, statuses, "%s (d) after PLAY" % label)
		assert_eq(app.settings.skin_id, skin_id, "%s (d): skin unchanged" % label)
		assert_false(app.settings.sound_on, "%s (d): sound unchanged" % label)

		for address: String in _sent:
			assert_eq(address, Copy.COFFEE_URL, "%s: every hand off is the one constant" % label)
		_clean_up()
		_sent = []
