extends "res://tests/base_test.gd"
## The App's flow for the 2026-10-13 additions (docs/ARCHITECTURE.md section
## 11, flow 1, 2, 4 and 9 to 12), with a real App and a temp save folder:
## Info (AT-112 to AT-114), the splash (AT-147 to AT-153, the parts that run
## headless), About and its license texts (AT-140), the back
## button order, the free offer (AT-135), New best after a restart (AT-145),
## the show gate (AT-146) and the clear notice rules (GDD 11.5).

const U := preload("res://tests/ui/ui_fixtures.gd")
const UiCopy := preload("res://src/design/shared/ui_copy.gd")
const Copy := preload("res://src/ui/screen_copy.gd")

var _dir: String = ""
var _app: App = null
var _quits: Array[int] = []


func before_each() -> void:
	_dir = U.make_temp_dir()
	_quits = []
	_app = null
	Motion.bind_tweens = false


func after_each() -> void:
	if _app != null and is_instance_valid(_app) and _app.save != null:
		_app.save.set_hold(false)
	U.stop_app(_app)
	U.remove_temp_dir(_dir)
	Motion.bind_tweens = true


func _start() -> App:
	_app = U.start_app(_dir, _quits)
	return _app


func _restart() -> App:
	U.stop_app(_app)
	return _start()


## The App on the splash, then Play, as a player opening the game and
## tapping Play (flow 1 and 2).
func _play() -> App:
	var app: App = _start()
	U.play(app)
	return app


func _restart_play() -> App:
	var app: App = _restart()
	U.play(app)
	return app


func _back(app: App) -> void:
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)


func _info_open(app: App) -> bool:
	for panel: Control in app.open_panels():
		if panel is InfoPanel:
			return true
	return false


func _run_bytes() -> PackedByteArray:
	U.settle(_app)
	return U.SaveFixtures.read_bytes(_dir.path_join("run.json"))


## A saved run after a chain, with Undo, 3 stars and 1 free booster held
## (run highest 8192), and its records, as a previous session left them.
func _saved_with_stars() -> RunState:
	var state: RunState = U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 13), 9000, U.snapshot_board(), 40)
	U.save_game(_dir, state, 9000, 13)
	return state


# Info (D-44)

func test_at_112_info_opens_from_the_splash() -> void:
	var saved: RunState = _saved_with_stars()
	var app: App = _start()
	assert_not_null(app.splash_screen(), "the splash, with a saved run")
	app.splash_screen().info_chosen.emit()
	var panel: InfoPanel = app.top_panel() as InfoPanel
	assert_not_null(panel, "Info opens")
	assert_eq(panel.title_text(), "Info", "titled Info")
	assert_eq(panel.content().size(), 17, "IN1 to IN17")
	assert_eq(panel.scroll().scroll_vertical, 0, "scrolled to the top")
	_back(app)
	assert_true(app.open_panels().is_empty(), "back closes it")
	assert_not_null(app.splash_screen(), "back on the splash, not the board")
	assert_null(app.game_screen(), "no board")
	assert_true(_quits.is_empty(), "back closed the screen, it did not quit")
	app.splash_screen().info_chosen.emit()
	(app.top_panel() as InfoPanel).close_button().pressed.emit()
	assert_true(app.open_panels().is_empty(), "its close control returns to the splash too")
	assert_eq(U.text(app.records.best_score), "9000", "Best Score unchanged")
	assert_eq(app.records.best_tile, 13, "Best Tile unchanged")
	U.play(app)
	assert_true(app.session.state.equals(saved), "Play opens the saved run unchanged")


func test_at_113_info_from_pause_leaves_the_run_untouched() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
	assert_true(app.session.commit_chain(chain).accepted, "a chain")
	U.shown(app)
	var before: RunState = app.session.state.copy()
	var stars: int = app.session.stars()
	var free: int = app.session.free_held()
	var undo: BoosterStatus = app.session.booster_statuses()[4]
	assert_true(undo.usable, "Undo enabled")
	app.open_pause()
	var pause: PausePanel = app.top_panel() as PausePanel
	assert_not_null(pause.find_child("Info", true, false), "Pause has an Info button")
	for node: Node in pause.find_children("*", "Button", true, false):
		assert_false((node as Button).text.to_lower().contains("how to play"), "and no How to play button")
	pause.info_chosen.emit()
	assert_true(app.top_panel() is InfoPanel, "Info opens")
	assert_eq(app.open_panels().size(), 2, "over Pause, which stays open")
	_back(app)
	assert_true(app.top_panel() is PausePanel, "back returns to Pause, not to the board")
	(app.top_panel() as PausePanel).resume_chosen.emit()
	assert_true(app.open_panels().is_empty(), "Resume")
	assert_true(app.session.state.equals(before), "the board and score exactly as noted")
	assert_eq(app.session.stars(), stars, "the stars")
	assert_eq(app.session.free_held(), free, "the free boosters held")
	var undo_after: BoosterStatus = app.session.booster_statuses()[4]
	assert_eq(undo_after.cost, undo.cost, "the Undo cost")
	assert_true(undo_after.usable, "Undo still enabled")


func test_at_114_info_never_opens_by_itself() -> void:
	var app: App = _start()
	assert_false(_info_open(app), "not at first launch")
	U.play(app)
	U.shown(app)
	assert_false(_info_open(app), "not when a run starts")
	U.settle(app)
	U.save_game(_dir, U.run(U.board_d1024(), 300))
	var ended: App = _restart()
	assert_false(_info_open(ended), "not at launch with a saved run")
	U.play(ended)
	U.shown(ended)
	assert_true(ended.top_panel() is EndPanel, "the run ends")
	assert_false(_info_open(ended), "not when a run ends")
	(ended.top_panel() as EndPanel).new_game_chosen.emit()
	U.shown(ended)
	assert_false(_info_open(ended), "not on the next run")
	var reopened: App = _restart()
	U.play(reopened)
	U.shown(reopened)
	assert_false(_info_open(reopened), "not after reopening")


func test_info_opens_only_once() -> void:
	var app: App = _start()
	app.splash_screen().info_chosen.emit()
	app.open_info()
	assert_eq(app.open_panels().size(), 1, "a second open while it shows does nothing")


# The splash (D-47)

func test_at_147_the_splash_holds_the_gear_records_and_three_buttons() -> void:
	_saved_with_stars()
	var app: App = _start()
	var splash: SplashScreen = app.splash_screen()
	assert_not_null(splash, "the splash at launch with a saved run")
	assert_not_null(splash.find_child("Settings", true, false), "the Settings gear")
	assert_eq(splash.best_score_text(), "9,000", "Best Score")
	var names: Array[String] = []
	for node: Node in splash.find_children("*", "Button", true, false):
		names.append(String(node.name))
	assert_eq(names, ["Play", "Info", "About"] as Array[String], "Play, Info and About, in order, and nothing else")
	assert_eq((splash.find_child("Play", true, false) as Button).text, "Play", "Play reads the same with a run")
	U.stop_app(_app)
	U.remove_temp_dir(_dir)
	_dir = U.make_temp_dir()
	var fresh: App = _start()
	assert_eq((fresh.splash_screen().find_child("Play", true, false) as Button).text, "Play", "as without one")


func test_at_149_play_continues_the_saved_run_exactly() -> void:
	var saved: RunState = _saved_with_stars()
	var app: App = _start()
	assert_true(app.open_panels().is_empty(), "no confirmation")
	U.play(app)
	assert_true(app.open_panels().is_empty(), "still no confirmation")
	assert_true(app.session.state.equals(saved), "board, score, snapshot and run highest tile")
	U.shown(app)
	assert_eq(U.text(app.records.best_score), "9000", "Best Score")
	assert_eq(app.records.best_tile, 13, "Best Tile")
	assert_eq(app.session.stars(), 3, "3 stars")
	assert_eq(app.session.free_held(), 1, "1 free booster held")
	for status: BoosterStatus in app.session.booster_statuses():
		assert_true(status.free, "%s reads Free" % status.id)
	app.session.press_booster(&"undo")
	assert_eq(app.session.state.cells, U.snapshot_board(), "Undo gives the board from before the last chain")


func test_launch_folds_the_saved_run_into_the_records() -> void:
	# A kill between the run file and the profile: the run is ahead of the
	# records. The splash shows them up to date (GDD 15.1).
	var state: RunState = U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 12), 7000)
	U.save_game(_dir, state, 5000, 10)
	var app: App = _start()
	assert_eq(U.text(app.records.best_score), "7000", "Best Score from the run")
	assert_eq(app.records.best_tile, 12, "Best Tile from the run")
	assert_eq(app.splash_screen().best_score_text(), "7,000", "on the splash")
	var records: Records = Records.new()
	U.settle(app)
	SaveService.new(_dir).load_profile(Settings.new(), records)
	assert_eq(U.text(records.best_score), "7000", "and saved")


func test_at_151_info_about_and_settings_over_the_splash_return_to_it() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var settings: Settings = Settings.new()
		settings.set_skin_id(skin_id)
		var saved: RunState = U.run(U.board_p(), 5000, U.snapshot_board(), 40)
		# The last App's queued saves land before this run's files are written.
		U.stop_app(_app)
		U.save_game(_dir, saved, 6000, 6, settings)
		var app: App = _start()
		var run_before: PackedByteArray = _run_bytes()
		var splash: SplashScreen = app.splash_screen()
		# (a)
		splash.info_chosen.emit()
		assert_true(app.top_panel() is InfoPanel, "%s (a): Info" % skin_id)
		_back(app)
		assert_true(app.open_panels().is_empty(), "%s (a): back to the splash" % skin_id)
		# (b)
		splash.about_chosen.emit()
		var about: AboutPanel = app.top_panel() as AboutPanel
		assert_not_null(about, "%s (b): About straight from the splash" % skin_id)
		assert_true(about.info_text().contains("Copyright 2026 Play, Inc."), "%s (b): the same content" % skin_id)
		_back(app)
		assert_true(app.open_panels().is_empty(), "%s (b): back to the splash" % skin_id)
		splash.about_chosen.emit()
		(app.top_panel() as AboutPanel).close_button().pressed.emit()
		assert_true(app.open_panels().is_empty(), "%s (b): the close control too" % skin_id)
		# (c)
		splash.about_chosen.emit()
		about = app.top_panel() as AboutPanel
		about.license_rows()[&"game"].emit_signal(&"tapped")
		assert_not_null(about.license_view(), "%s (c): the SumUp license" % skin_id)
		_back(app)
		assert_null(about.license_view(), "%s (c): closes to About" % skin_id)
		assert_true(app.top_panel() == about, "%s (c): About stays" % skin_id)
		_back(app)
		assert_true(app.open_panels().is_empty(), "%s (c): then to the splash" % skin_id)
		# (d)
		splash.settings_chosen.emit()
		(app.top_panel() as SettingsPanel).about_chosen.emit()
		assert_true(app.top_panel() is AboutPanel, "%s (d): About from Settings" % skin_id)
		_back(app)
		assert_true(app.top_panel() is SettingsPanel, "%s (d): back to Settings" % skin_id)
		_back(app)
		assert_true(app.open_panels().is_empty(), "%s (d): then to the splash" % skin_id)
		assert_true(_quits.is_empty(), "%s: no exit" % skin_id)
		assert_eq(app.splash_screen(), splash, "%s: the same splash throughout" % skin_id)
		assert_eq(splash.entrance_stage(), SplashScreen.Entrance.BRAND_IN, "%s: its entrance was not restarted by a panel" % skin_id)
		assert_eq(U.text(app.records.best_score), "6000", "%s: Best Score unchanged" % skin_id)
		assert_eq(app.records.best_tile, 6, "%s: Best Tile unchanged" % skin_id)
		assert_eq(app.skin.id, skin_id, "%s: the skin unchanged" % skin_id)
		assert_eq(_run_bytes(), run_before, "%s: the run file unchanged" % skin_id)
		# (e)
		U.play(app)
		assert_true(app.session.state.equals(saved), "%s (e): the saved run opens unchanged" % skin_id)


func test_play_is_ignored_under_a_panel() -> void:
	var app: App = _start()
	app.splash_screen().settings_chosen.emit()
	U.play(app)
	assert_null(app.game_screen(), "Play under Settings does nothing")


func test_at_152_back_on_the_splash_quits_and_keeps_the_run() -> void:
	var saved: RunState = U.run(U.board_p(), 5000, U.snapshot_board(), 40)
	U.save_game(_dir, saved)
	var app: App = _start()
	var before: PackedByteArray = _run_bytes()
	app.splash_screen().settings_chosen.emit()
	_back(app)
	assert_true(_quits.is_empty(), "with Settings open, back closes Settings and the app stays open")
	_back(app)
	assert_eq(_quits.size(), 1, "back on the splash quits, with no dialog")
	assert_null(app.game_screen(), "and no board")
	assert_eq(_run_bytes(), before, "the saved run is kept exactly")
	var reopened: App = _restart()
	assert_not_null(reopened.splash_screen(), "the splash again")
	U.play(reopened)
	assert_true(reopened.session.state.equals(saved), "Play opens the same run unchanged")


func test_at_153_c_a_return_from_the_background_keeps_info_over_the_splash() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _start()
	var before: PackedByteArray = _run_bytes()
	app.splash_screen().info_chosen.emit()
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(app.top_panel() is InfoPanel, "Info is still open")
	assert_not_null(app.splash_screen(), "over the splash")
	assert_eq(_run_bytes(), before, "the held run was not written")


func test_at_153_a_b_a_return_from_the_background_keeps_the_play_screen() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	var game: GameScreen = app.game_screen()
	app.session.press_booster(&"swap")
	app.session.tap_cell(Vector2i(0, 0))
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_null(app.splash_screen(), "no splash")
	assert_eq(app.game_screen(), game, "the same play screen")
	assert_eq(app.session.targeting_booster(), &"", "targeting cancelled")
	assert_eq(U.text(app.session.state.score), "5000", "nothing charged")


# About (AT-140) and the back order (flow 10)

func test_at_140_about_opens_from_settings_and_back_closes_it() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var settings: Settings = Settings.new()
		settings.set_skin_id(skin_id)
		U.save_game(_dir, null, 0, 0, settings)
		var app: App = _restart() if _app != null else _start()
		app.splash_screen().settings_chosen.emit()
		(app.top_panel() as SettingsPanel).about_row().emit_signal(&"tapped")
		assert_true(app.top_panel() is AboutPanel, "%s: About opens from Settings" % skin_id)
		_back(app)
		assert_true(app.top_panel() is SettingsPanel, "%s: back returns to Settings, still open" % skin_id)
		(app.top_panel() as SettingsPanel).about_chosen.emit()
		(app.top_panel() as AboutPanel).close_button().pressed.emit()
		assert_true(app.top_panel() is SettingsPanel, "%s: the close control returns to Settings" % skin_id)
		_back(app)
		assert_true(app.open_panels().is_empty(), "%s: a second back closes Settings" % skin_id)
		assert_true(_quits.is_empty(), "%s: no exit" % skin_id)


func test_back_order_from_a_license_text_down_to_the_board() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	app.open_pause()
	(app.top_panel() as PausePanel).settings_chosen.emit()
	(app.top_panel() as SettingsPanel).about_chosen.emit()
	var about: AboutPanel = app.top_panel() as AboutPanel
	about.license_rows()[&"godot"].emit_signal(&"tapped")
	assert_not_null(about.license_view(), "a license text inside About")
	_back(app)
	assert_null(about.license_view(), "back closes the license text first")
	assert_true(app.top_panel() == about, "About stays")
	_back(app)
	assert_true(app.top_panel() is SettingsPanel, "then About")
	_back(app)
	assert_true(app.top_panel() is PausePanel, "then Settings")
	_back(app)
	assert_true(app.open_panels().is_empty(), "then Pause, which resumes")
	_back(app)
	assert_true(app.top_panel() is PausePanel, "back on the board opens Pause")
	(app.top_panel() as PausePanel).info_chosen.emit()
	_back(app)
	assert_true(app.top_panel() is PausePanel, "back closes Info before Pause")
	assert_true(_quits.is_empty(), "never an exit on the board")


func test_back_cancels_targeting_before_any_panel() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	app.session.press_booster(&"hammer")
	_back(app)
	assert_eq(app.session.targeting_booster(), &"", "targeting ends")
	assert_true(app.open_panels().is_empty(), "no panel opened")


func test_skin_switch_rebuilds_open_reading_screens() -> void:
	var app: App = _start()
	app.splash_screen().settings_chosen.emit()
	(app.top_panel() as SettingsPanel).about_chosen.emit()
	var about: AboutPanel = app.top_panel() as AboutPanel
	about.open_license(&"outfit")
	app.settings.set_skin_id(&"slate")
	assert_eq(about.title_text(), SkinCatalog.get_skin(&"slate").cased(&"title", "About"), "About rebuilt in the new skin")
	assert_not_null(about.license_view(), "with its license text still open")
	assert_eq(about.license_view().call(&"license_id"), &"outfit", "the same text")


# The offer with a free booster (AT-135, DESIGN_SYSTEM.md 7.5)

func test_at_135_a_the_offer_reads_shuffle_for_free() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 0, PackedInt64Array(), 0, 13))
	var app: App = _play()
	U.shown(app)
	assert_true(app.session.is_offer_open(), "the offer opens instead of ending the run")
	assert_eq(app.session.free_held(), 1, "1 free booster held")
	var offer: OfferPanel = app.game_screen().offer_panel()
	assert_eq(offer.buy_button().text, "Shuffle for free", "the buy button")
	offer.buy_button().pressed.emit()
	assert_eq(U.text(app.session.state.score), "0", "free: the score stays 0")
	assert_eq(app.session.free_held(), 0, "the free booster is used")


# New best after a restart (AT-145, the UI half)

func _at_145_end(best_at_start: int, format_1: bool) -> bool:
	U.save_game(_dir, null, 5000, 10)
	var state: RunState = U.run(U.board_d1024(), 5000, PackedInt64Array(), 0, 0, 0, best_at_start)
	if format_1:
		U.SaveFixtures.write_text(_dir.path_join("run.json"), U.SaveFixtures.to_text(U.SaveFixtures.format_1_data(state)))
	else:
		SaveService.new(_dir).save_run(state)
	var app: App = _restart() if _app != null else _start()
	U.play(app)
	U.shown(app)
	assert_true(app.session.is_offer_open(), "the offer opens (Board D1024 has no valid move)")
	app.game_screen().offer_panel().end_run_button().pressed.emit()
	var panel: EndPanel = app.top_panel() as EndPanel
	assert_not_null(panel, "the end of run screen")
	return panel != null and panel.shows_new_best()


func test_at_145_new_best_survives_a_restart() -> void:
	assert_true(_at_145_end(4000, false), "(a) began at 4,000: New best")
	assert_false(_at_145_end(5000, false), "(b) began at 5,000: it only equalled the record")
	assert_false(_at_145_end(4000, true), "(c) a file from before the rule: the old behaviour, no badge")


# The show gate (AT-146, the App half)

func test_at_146_a_held_save_keeps_the_hud_and_the_board_as_at_the_lift() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	var game: GameScreen = app.game_screen()
	var statuses: Array[BoosterStatus] = game.shown_statuses()
	assert_eq(U.text(game.shown_score()), "5000", "the score before the move")
	app.save.set_hold(true)
	var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
	assert_true(app.session.commit_chain(chain).accepted, "the chain commits in the rules model")
	assert_eq(U.text(app.session.state.score), "5004", "with its points")
	game.board()._check_gate()
	assert_true(game.board().is_waiting_for_save(), "the save is held, so the board has not started the move")
	assert_eq(U.text(game.shown_score()), "5000", "the HUD score is as at the lift")
	assert_eq(game.hud().score_label().text, "5,000", "on screen")
	assert_true(game.shown_statuses() == statuses, "the booster bar is as at the lift")
	app.save.set_hold(false)
	U.gate(app)
	assert_false(game.board().is_waiting_for_save(), "once the save lands the move starts")
	assert_eq(U.text(game.shown_score()), "5004", "and the HUD shows its score")
	assert_false(game.shown_statuses() == statuses, "and the bar its statuses")


func test_the_app_gates_every_board_it_shows() -> void:
	var app: App = _start()
	U.play(app)
	assert_true(app.game_screen().board().is_waiting_for_save(), "the new run's board waits for its save")
	U.gate(app)
	assert_false(app.game_screen().board().is_waiting_for_save(), "and shows once it landed")


# The clear notice (GDD 11.5, D-45, AT-104, AT-123, QA6-04)

func test_notice_rules() -> void:
	var star_only: MoveResult = MoveResult.new()
	star_only.stars_earned = 1
	assert_true(GameScreen.wants_notice(star_only), "a star with nothing cleared shows the notice (SC7)")
	var clear_only: MoveResult = MoveResult.new()
	clear_only.cleared_small = [Vector2i(0, 0)] as Array[Vector2i]
	assert_true(GameScreen.wants_notice(clear_only), "a clear with no star shows the notice (CL4)")
	var neither: MoveResult = MoveResult.new()
	neither.notice_values = PackedInt64Array([1])
	assert_false(GameScreen.wants_notice(neither), "a floor rise with no clear and no star shows none")
	assert_false(GameScreen.wants_notice(null), "no move, no notice")


func _board_e() -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	for row: int in 8:
		for column: int in 5:
			if row % 2 == 0:
				cells.append(2 if column % 2 == 0 else 4)
			else:
				cells.append(3 if column % 2 == 0 else 5)
	return cells


func test_at_123_a_star_with_nothing_cleared_shows_the_notice() -> void:
	var board: PackedInt64Array = U.with_cell(U.with_cell(_board_e(), Vector2i(4, 6), 10), Vector2i(4, 7), 10)
	U.save_game(_dir, U.run(board, 10000))
	var app: App = _play()
	U.shown(app)
	var result: MoveResult = app.session.commit_chain([Vector2i(4, 6), Vector2i(4, 7)] as Array[Vector2i])
	assert_eq(result.stars_earned, 1, "one star")
	assert_true(result.cleared_small.is_empty(), "nothing cleared")
	assert_eq(result.notice_values, PackedInt64Array([1]), "the 2s left the window")
	var hud: SkinHud = app.game_screen().hud()
	assert_null(hud.call(&"clear_notice"), "the notice waits with the move at the gate")
	assert_eq(hud.call(&"shown_stars"), Vector2i(0, 0), "and so does the counter")
	U.gate(app)
	var notice: Control = hud.call(&"clear_notice")
	assert_not_null(notice, "then the notice shows")
	assert_eq(notice.get_parent(), app.game_screen().notice_layer(), "on the play screen's notice layer")
	assert_eq(app.session.stars(), 1, "1 star")
	assert_true(hud.call(&"star_moment") != null, "with the star earned effect")
	hud.call(&"seek_star_moment", 10.0)
	assert_eq(hud.call(&"shown_stars"), Vector2i(1, 0), "the counter lands on 1")


func test_at_125_a_loaded_run_shows_its_stars_and_no_notice() -> void:
	var state: RunState = U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 17), 2400000, PackedInt64Array(), 0, 0, 1)
	U.save_game(_dir, state, 2400000, 17)
	var app: App = _play()
	U.shown(app)
	var hud: SkinHud = app.game_screen().hud()
	assert_eq(hud.call(&"shown_stars"), Vector2i(7, 1), "7 stars and 1 free booster held, at once")
	assert_null(hud.call(&"clear_notice"), "loading shows no notice")
	assert_null(hud.call(&"star_moment"), "and earns no star")


func test_stars_follow_a_skin_switch_and_a_new_run() -> void:
	var state: RunState = U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 13), 9000)
	U.save_game(_dir, state, 9000, 13)
	var app: App = _play()
	U.shown(app)
	assert_eq(app.game_screen().hud().call(&"shown_stars"), Vector2i(3, 1), "3 stars, 1 free booster")
	app.settings.set_skin_id(&"nova")
	var hud: SkinHud = app.game_screen().hud()
	assert_true((hud.get_script() as Script).resource_path.contains("nova"), "a new HUD")
	assert_eq(hud.call(&"shown_stars"), Vector2i(3, 1), "with the same counter")
	assert_true(hud.call(&"clear_notice") == null, "no notice from the switch")
	app.open_pause()
	(app.top_panel() as PausePanel).new_game_chosen.emit()
	(app.top_panel() as ConfirmDialog).confirmed.emit()
	U.gate(app)
	assert_eq(app.game_screen().hud().call(&"shown_stars"), Vector2i(0, 0), "a new run starts at 0")


func test_the_end_of_run_screen_has_no_stars_row() -> void:
	var state: RunState = U.run(U.board_d1024(), 300, PackedInt64Array(), 0, 13, 1)
	U.save_game(_dir, state, 300, 13)
	var app: App = _play()
	U.shown(app)
	var panel: EndPanel = app.top_panel() as EndPanel
	assert_not_null(panel, "the run ends (no valid move, nothing usable)")
	for label: Node in panel.find_children("*", "Label", true, false):
		assert_false((label as Label).text.to_lower().contains("star"), "no stars row (DESIGN_SYSTEM.md 7.6)")


func test_qa6_04_a_clear_from_the_offer_still_shows_the_notice() -> void:
	# AT-101: Double on the 1024 from the offer makes 2048, clears the 2 and
	# earns a star while the offer has the HUD's place.
	var board: PackedInt64Array = U.with_cell(U.with_cell(_board_e(), Vector2i(0, 3), 1), Vector2i(2, 0), 10)
	U.save_game(_dir, U.run(board, 5000))
	var app: App = _play()
	U.shown(app)
	assert_true(app.session.is_offer_open(), "the offer is open")
	app.session.press_booster(&"double")
	var result: MoveResult = app.session.tap_cell(Vector2i(2, 0))
	assert_true(result != null and result.accepted, "the Double applies")
	assert_eq(result.stars_earned, 1, "a star")
	assert_false(app.game_screen().hud().visible, "the offer has the HUD's place")
	U.gate(app)
	var notice: Control = app.game_screen().hud().call(&"clear_notice")
	assert_not_null(notice, "the notice is shown, offer or not")
	var layer: Control = app.game_screen().notice_layer()
	assert_eq(notice.get_parent(), layer, "on the notice layer, not inside the hidden HUD")
	var game: GameScreen = app.game_screen()
	assert_true(layer.get_index() > game.offer_panel().get_index(), "above the offer panel")
	assert_true(layer.get_index() > game.board().get_index(), "and the board")


func test_clear_notice_plural_follows_the_label() -> void:
	# GDD 11.5 and AT-161: the plural "s" stays after a digit or a capital
	# suffix and is left out after a lowercase one. Values are exponents.
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var one: String = UiCopy.clear_notice(skin, &"body", PackedInt64Array([53]))
		assert_true(one.ends_with("8Qs"), "%s: \"%s\" keeps the s after 8Q" % [skin_id, one])
		var lower: String = UiCopy.clear_notice(skin, &"body", PackedInt64Array([60]))
		assert_true(lower.ends_with("1aa"), "%s: \"%s\" has no s after 1aa" % [skin_id, lower])
		var as_label: String = UiCopy.clear_notice(skin, &"body", PackedInt64Array([220]))
		assert_true(as_label.ends_with("1as") and not as_label.contains("1ass"), "%s: \"%s\", never 1ass" % [skin_id, as_label])
		var range_text: String = UiCopy.clear_notice(skin, &"body", PackedInt64Array([67, 68, 69]))
		assert_true(range_text.contains("128aa") and range_text.ends_with("512aa") and not range_text.contains("128aas"), "%s: \"%s\"" % [skin_id, range_text])
