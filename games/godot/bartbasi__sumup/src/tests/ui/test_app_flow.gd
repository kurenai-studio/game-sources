extends "res://tests/base_test.gd"
## The App's flow (docs/ARCHITECTURE.md section 11, flow 1 to 10), with a real
## App in the scene tree and a temp save folder. Covers the UI halves of the
## save and flow acceptance tests (GDD 19.12, 19.14).

const U := preload("res://tests/ui/ui_fixtures.gd")
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
	U.stop_app(_app)
	U.remove_temp_dir(_dir)
	Motion.bind_tweens = true


func _start() -> App:
	_app = U.start_app(_dir, _quits)
	return _app


## The App reopened on the same folder, as after closing the app.
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


func _service() -> SaveService:
	U.settle(_app)
	return SaveService.new(_dir)


func _saved_run() -> RunState:
	return _service().load_run(GameConfig.new())


func _profile_bytes() -> PackedByteArray:
	U.settle(_app)
	return U.SaveFixtures.read_bytes(_dir.path_join("profile.json"))


func _undo_status(app: App) -> BoosterStatus:
	return app.session.booster_statuses()[4]


# Flow 1: start

func test_at_147_a_start_without_a_saved_run_shows_the_splash() -> void:
	var app: App = _start()
	assert_not_null(app.splash_screen(), "the splash")
	assert_false(app.has_held_run(), "no run held")
	assert_eq(app.splash_screen().best_score_text(), "0", "Best Score 0")
	assert_null(app.game_screen(), "no play screen")
	assert_eq(app.session.phase(), GameSession.Phase.NONE, "no run")
	assert_true(app.open_panels().is_empty(), "no panel")


func test_at_91_and_at_149_a_saved_run_shows_the_splash_and_play_resumes_it() -> void:
	var saved: RunState = U.run(U.board_p(), 1032, U.snapshot_board(), 32, 6)
	U.save_game(_dir, saved, 50000, 11)
	var before: PackedByteArray = U.SaveFixtures.read_bytes(_dir.path_join("run.json"))
	var app: App = _start()
	assert_not_null(app.splash_screen(), "the splash, not the board (AT-147 b)")
	assert_null(app.game_screen(), "no play screen yet")
	assert_true(app.has_held_run(), "the run is held")
	assert_eq(app.session.phase(), GameSession.Phase.NONE, "and not resumed")
	assert_eq(app.splash_screen().best_score_text(), "50,000", "the records on the splash")
	U.settle(app)
	assert_eq(U.SaveFixtures.read_bytes(_dir.path_join("run.json")), before, "the splash leaves the run file as it was")
	U.play(app)
	assert_null(app.splash_screen(), "Play leaves the splash")
	assert_not_null(app.game_screen(), "for the play screen")
	assert_false(app.has_held_run(), "nothing held any more")
	assert_true(app.session.is_run_in_progress(), "the run is live")
	assert_true(app.session.state.equals(saved), "same board, score, snapshot and run highest tile")
	assert_eq(U.text(app.records.best_score), "50000", "same Best Score")
	assert_eq(app.records.best_tile, 11, "same Best Tile")
	U.shown(app)
	var undo: BoosterStatus = _undo_status(app)
	assert_true(undo.usable, "Undo enabled")
	assert_eq(undo.cost, BoosterRules.cost(&"undo", saved, app.config), "at the same cost")


func test_at_95_a_broken_saved_run_is_discarded_at_launch() -> void:
	U.save_game(_dir, null, 5000, 9)
	U.SaveFixtures.write_text(_dir.path_join("run.json"), "{\"format\": 1, \"cells\": [1, 2")
	var app: App = _start()
	assert_not_null(app.splash_screen(), "the splash as usual (SP8)")
	assert_null(app.game_screen(), "no play screen")
	assert_false(app.has_held_run(), "nothing held")
	assert_false(_service().has_run(), "the broken run is discarded")
	assert_eq(U.text(app.records.best_score), "5000", "Best Score kept")
	assert_eq(app.records.best_tile, 9, "Best Tile kept")
	U.play(app)
	assert_eq(U.text(app.session.state.score), "0", "Play starts a new run")


func test_profile_loads_before_any_listener() -> void:
	var settings: Settings = Settings.new()
	settings.set_sound_on(false)
	settings.set_skin_id(&"slate")
	U.save_game(_dir, null, 1234, 6, settings)
	var before: PackedByteArray = _profile_bytes()
	var app: App = _start()
	assert_false(app.settings.sound_on, "sound off from the profile")
	assert_false(app.audio.is_enabled(), "and the audio service knows it")
	assert_eq(app.skin.id, &"slate", "the saved skin")
	assert_eq(app.theme.get_font_size(&"font_size", &"TitleLabel"), app.skin.font_size(&"title"), "the theme is Slate's")
	assert_eq(_profile_bytes(), before, "loading wrote nothing back")


func test_an_unknown_skin_id_falls_back_to_the_default() -> void:
	var settings: Settings = Settings.new()
	settings.set_skin_id(&"retro")
	U.save_game(_dir, null, 0, 0, settings)
	var app: App = _start()
	assert_eq(app.skin.id, SkinCatalog.DEFAULT_ID, "default skin")
	assert_eq(app.settings.skin_id, SkinCatalog.DEFAULT_ID, "the setting follows")


# Flow 2 and 8: new game and saving

func test_at_148_play_with_no_saved_run_starts_and_saves_a_run() -> void:
	var app: App = _start()
	U.play(app)
	assert_null(app.splash_screen(), "splash gone")
	assert_not_null(app.game_screen(), "play screen")
	assert_true(app.session.is_run_in_progress(), "a run")
	assert_eq(U.text(app.session.state.score), "0", "score 0")
	assert_true(app.session.state.equals(_saved_run()), "saved as soon as the board exists")


func test_at_92_a_move_is_saved_as_soon_as_it_resolves() -> void:
	U.save_game(_dir, U.run(U.board_p(), 0))
	var app: App = _play()
	U.shown(app)
	var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
	var result: MoveResult = app.session.commit_chain(chain)
	assert_true(result.accepted, "the chain commits")
	assert_true(app.session.is_waiting_for_view(), "its animation has not ended")
	assert_true(app.session.state.equals(_saved_run()), "the saved run already has the move")
	assert_eq(U.text(_saved_run().score), "4", "with its points")
	var records: Records = Records.new()
	_service().load_profile(Settings.new(), records)
	assert_eq(U.text(records.best_score), "4", "and the records")


func test_no_run_is_saved_when_no_run_is_in_progress() -> void:
	var app: App = _start()
	app.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_false(_service().has_run(), "no run file from the menu")
	assert_true(FileAccess.file_exists(_dir.path_join("profile.json")), "the profile is saved")


func test_lifecycle_events_save_the_run() -> void:
	U.save_game(_dir, U.run(U.board_p(), 700))
	var app: App = _play()
	U.shown(app)
	U.settle(app)
	for what: int in [Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_WM_CLOSE_REQUEST]:
		DirAccess.remove_absolute(_dir.path_join("run.json"))
		app.notification(what)
		assert_true(FileAccess.file_exists(_dir.path_join("run.json")), "written at once on notification %d" % what)
		assert_true(app.session.state.equals(_saved_run()), "saved on notification %d" % what)


# Flow 6: the end of a run

func test_at_50_run_end_deletes_the_run_saves_the_profile_and_shows_the_end_panel() -> void:
	var saved: RunState = U.run(U.board_d1024(), 300, U.snapshot_board(), 40)
	U.save_game(_dir, saved, 300, 10)
	var app: App = _play()
	U.shown(app)
	assert_eq(app.session.phase(), GameSession.Phase.ENDED, "nothing is usable, so the run ends at once")
	assert_false(app.session.is_offer_open(), "no offer")
	assert_false(_service().has_run(), "the saved run is deleted")
	var panel: EndPanel = app.top_panel() as EndPanel
	assert_not_null(panel, "the end of run panel shows")
	assert_eq(panel.score_text(), "300", "final score 300")
	assert_eq(panel.reason_text(), "No moves left.", "QA4-01: it says no moves were left (GDD 12.2 step 3)")
	assert_eq(panel.tile_values()[1], 10, "this run's highest tile 1024")
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_false(_service().has_run(), "an ended run is never saved again")


func test_at_54_an_ended_run_does_not_come_back() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 5000, U.snapshot_board(), 40))
	var app: App = _play()
	U.shown(app)
	assert_true(app.session.is_offer_open(), "the offer is open")
	var offer: OfferPanel = app.game_screen().offer_panel()
	offer.end_run_button().pressed.emit()
	assert_not_null(app.top_panel() as EndPanel, "End run shows the end of run panel")
	assert_eq((app.top_panel() as EndPanel).reason_text(), "", "with no 'No moves left.': something was still usable")
	assert_false(_service().has_run(), "the run is deleted")
	var reopened: App = _restart()
	assert_not_null(reopened.splash_screen(), "reopening shows the splash")
	assert_false(reopened.has_held_run(), "with no run held")
	U.play(reopened)
	assert_eq(U.text(reopened.session.state.score), "0", "Play starts a new run instead of that one")


func test_at_150_end_panel_new_game_and_home() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 300))
	var app: App = _play()
	U.shown(app)
	var panel: EndPanel = app.top_panel() as EndPanel
	panel.new_game_chosen.emit()
	assert_true(app.open_panels().is_empty(), "the panel closes")
	assert_true(app.session.is_run_in_progress(), "a new run starts")
	assert_eq(U.text(app.session.state.score), "0", "at 0")

	U.settle(app)
	U.save_game(_dir, U.run(U.board_d1024(), 300))
	var again: App = _restart_play()
	U.shown(again)
	var end: EndPanel = again.top_panel() as EndPanel
	assert_not_null(end.find_child("Home", true, false), "the end of run screen has Home")
	assert_null(end.find_child("MainMenu", true, false), "and no Main menu")
	end.home_chosen.emit()
	assert_not_null(again.splash_screen(), "Home goes to the splash")
	assert_null(again.game_screen(), "the play screen is gone")
	assert_true(again.open_panels().is_empty(), "no panel over it")
	assert_eq(again.splash_screen().best_score_text(), "300", "the records include the run")
	assert_false(again.has_held_run(), "no run held")
	U.play(again)
	assert_true(again.session.is_run_in_progress(), "Play starts a new run (AT-148 b)")
	assert_eq(U.text(again.session.state.score), "0", "at 0, with no confirmation")
	assert_true(again.open_panels().is_empty(), "no confirmation")
	assert_eq(U.text(again.records.best_score), "300", "Best Score keeps the old run's value")


func test_at_44_records_persist_after_a_run() -> void:
	U.save_game(_dir, U.run(U.with_cell(U.board_d(), Vector2i(0, 0), 3), 9990))
	var app: App = _play()
	U.shown(app)
	var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	app.session.commit_chain(chain)
	assert_eq(U.text(app.records.best_score), "10006", "a new Best Score")
	var reopened: App = _restart()
	assert_eq(U.text(reopened.records.best_score), "10006", "kept after reopening")
	assert_eq(reopened.records.best_tile, 4, "Best Tile kept after reopening")
	assert_eq(reopened.splash_screen().best_score_text(), "10,006", "on the splash")


# Flow 9: pause

func test_pause_cancels_the_drag_and_targeting() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	assert_true(app.session.begin_drag(), "a drag starts")
	app.game_screen().hud().pause_pressed.emit()
	assert_false(app.session.is_dragging(), "Pause dropped the drag")
	assert_true(app.top_panel() is PausePanel, "Pause is open")
	(app.top_panel() as PausePanel).resume_chosen.emit()
	assert_true(app.open_panels().is_empty(), "Resume closes it")

	app.session.press_booster(&"hammer")
	assert_eq(app.session.targeting_booster(), &"hammer", "targeting")
	app.open_pause()
	assert_eq(app.session.targeting_booster(), &"", "Pause cancelled targeting")
	assert_eq(U.text(app.session.state.score), "5000", "nothing charged")


func test_at_24_and_at_93_focus_loss_drops_the_drag_and_keeps_the_board() -> void:
	var saved: RunState = U.run(U.board_p(), 5000)
	U.save_game(_dir, saved)
	var app: App = _play()
	U.shown(app)
	app.session.begin_drag()
	app.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(app.session.is_dragging(), "no chain in progress")
	assert_true(_saved_run().equals(saved), "board and score as before the drag")
	var reopened: App = _restart_play()
	assert_true(reopened.session.state.equals(saved), "and that is what resumes")


func test_at_96_new_game_from_pause_asks_first() -> void:
	var saved: RunState = U.run(U.board_p(), 5000, U.snapshot_board(), 40)
	U.save_game(_dir, saved, 9000, 5)
	var app: App = _play()
	U.shown(app)
	app.open_pause()
	(app.top_panel() as PausePanel).new_game_chosen.emit()
	var dialog: ConfirmDialog = app.top_panel() as ConfirmDialog
	assert_not_null(dialog, "a confirmation first")
	assert_true(app.session.state.equals(saved), "the run is unchanged while it asks")
	dialog.cancelled.emit()
	assert_true(app.top_panel() is PausePanel, "Cancel returns to Pause")
	assert_true(app.session.state.equals(saved), "the run is unchanged after Cancel")

	(app.top_panel() as PausePanel).new_game_chosen.emit()
	(app.top_panel() as ConfirmDialog).confirmed.emit()
	assert_true(app.open_panels().is_empty(), "every panel closes")
	assert_eq(U.text(app.session.state.score), "0", "a new run at 0")
	assert_false(app.session.state.has_snapshot(), "Undo disabled")
	assert_eq(U.text(app.records.best_score), "9000", "Best Score still holds the old record")
	assert_true(app.session.state.equals(_saved_run()), "the new run replaced the saved one")


# Flow 10: the back button

func test_at_64_back_cancels_targeting_first() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	app.session.press_booster(&"swap")
	app.session.tap_cell(Vector2i(0, 0))
	assert_eq(app.session.swap_first(), Vector2i(0, 0), "one tile selected")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(app.session.targeting_booster(), &"", "targeting ends")
	assert_eq(U.text(app.session.state.score), "5000", "nothing charged")
	assert_true(app.open_panels().is_empty(), "no pause")
	assert_true(_quits.is_empty(), "no exit")
	assert_not_null(app.game_screen(), "still on the board")


func test_back_closes_the_top_panel_then_opens_pause() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(app.top_panel() is PausePanel, "back on the board opens Pause")
	(app.top_panel() as PausePanel).settings_chosen.emit()
	assert_true(app.top_panel() is SettingsPanel, "Settings over Pause")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(app.top_panel() is PausePanel, "back closes Settings")
	(app.top_panel() as PausePanel).new_game_chosen.emit()
	assert_true(app.top_panel() is ConfirmDialog, "the confirmation")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(app.top_panel() is PausePanel, "back closes the confirmation")
	assert_eq(U.text(app.session.state.score), "5000", "and starts nothing")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(app.open_panels().is_empty(), "back on Pause resumes")
	assert_true(_quits.is_empty(), "never an exit on the board")


func test_back_in_the_offer_opens_pause() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 5000))
	var app: App = _play()
	U.shown(app)
	assert_true(app.session.is_offer_open(), "the offer is open")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(app.top_panel() is PausePanel, "Pause")


func test_back_on_the_splash_quits_after_saving() -> void:
	var app: App = _start()
	app.splash_screen().settings_chosen.emit()
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(app.open_panels().is_empty(), "back first closes Settings")
	assert_true(_quits.is_empty(), "no exit yet")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(_quits.size(), 1, "then quits")
	assert_true(FileAccess.file_exists(_dir.path_join("profile.json")), "after saving")


func test_back_on_the_end_panel_quits_after_saving() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 300))
	var app: App = _play()
	U.shown(app)
	assert_true(app.top_panel() is EndPanel, "the end of run panel")
	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(_quits.size(), 1, "back quits")
	assert_false(_service().has_run(), "without saving the ended run")


func _escape(echo: bool = false) -> InputEventKey:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	key.echo = echo
	return key


func test_qa4_05_escape_does_what_back_does_on_desktop() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 5000))
	var app: App = _play()
	U.shown(app)
	assert_true(app.session.is_offer_open(), "the offer hides the HUD's pause button")
	app._unhandled_key_input(_escape())
	assert_true(app.top_panel() is PausePanel, "Escape opens Pause from the offer")
	app._unhandled_key_input(_escape(true))
	assert_true(app.top_panel() is PausePanel, "a held key's repeats do nothing")
	var other: InputEventKey = _escape()
	other.keycode = KEY_A
	app._unhandled_key_input(other)
	assert_true(app.top_panel() is PausePanel, "other keys do nothing")
	app._unhandled_key_input(_escape())
	assert_true(app.open_panels().is_empty(), "Escape again resumes, like back")
	app.session.press_booster(&"hammer")
	app._unhandled_key_input(_escape())
	assert_eq(app.session.targeting_booster(), &"", "Escape cancels targeting first")
	assert_true(app.open_panels().is_empty(), "without opening Pause")
	assert_true(_quits.is_empty(), "never an exit on the board")


func test_qa4_05_escape_on_the_splash_quits_like_back() -> void:
	var app: App = _start()
	app._unhandled_key_input(_escape())
	assert_eq(_quits.size(), 1, "the same back order: the splash quits after saving")


# Flow 7: settings

func test_at_94_sound_setting_reaches_the_audio_service_and_persists() -> void:
	var app: App = _start()
	assert_true(app.settings.sound_on, "sound on at first launch")
	assert_true(app.audio.is_enabled(), "audio on")
	app.splash_screen().settings_chosen.emit()
	var panel: SettingsPanel = app.top_panel() as SettingsPanel
	panel.sound_toggle().toggled.emit(false)
	assert_false(app.settings.sound_on, "the setting changes")
	assert_false(app.audio.is_enabled(), "the audio service is off")
	var reopened: App = _restart()
	assert_false(reopened.settings.sound_on, "off after reopening")
	assert_false(reopened.audio.is_enabled(), "audio off after reopening")


func test_at_94_skin_setting_switches_the_game_live_and_persists() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	app.open_pause()
	(app.top_panel() as PausePanel).settings_chosen.emit()
	var panel: SettingsPanel = app.top_panel() as SettingsPanel
	panel.skin_chips()[&"nova"].pressed.emit()
	assert_eq(app.settings.skin_id, &"nova", "the setting changes")
	assert_eq(app.skin.id, &"nova", "the App switches skin")
	assert_eq(app.theme.get_font_size(&"font_size", &"TitleLabel"), app.skin.font_size(&"title"), "a new theme")
	var hud_script: Script = app.game_screen().hud().get_script() as Script
	assert_true(hud_script.resource_path.contains("nova"), "the play screen rebuilt in Nova")
	assert_eq(app.open_panels().size(), 2, "Pause and Settings stay open")
	var chips: Dictionary[StringName, Button] = (app.top_panel() as SettingsPanel).skin_chips()
	assert_true(chips[&"nova"].button_pressed, "Nova's chip is selected")
	assert_false(chips[&"gumdrop"].button_pressed, "Gumdrop's is not")
	assert_eq(U.text(app.session.state.score), "5000", "the run carries on")
	var reopened: App = _restart()
	assert_eq(reopened.skin.id, &"nova", "Nova after reopening")
	assert_true((reopened.splash_screen().wordmark().get_script() as Script).resource_path.contains("nova"), "the splash in Nova")


# The offer on the play screen

func test_at_47_the_offer_takes_the_hud_place() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 5000, U.snapshot_board(), 40))
	var app: App = _play()
	U.shown(app)
	var game: GameScreen = app.game_screen()
	assert_true(app.session.is_offer_open(), "the offer opens")
	assert_true(game.offer_panel().visible, "the offer panel shows")
	assert_false(game.hud().visible, "in the HUD's place")
	assert_true(game.board().visible, "the board stays visible")
	var costs: Array[int] = []
	for status: BoosterStatus in app.session.booster_statuses():
		assert_true(status.usable, "%s enabled" % status.id)
		assert_eq(status.suggested, status.id == &"shuffle", "%s marked only if Shuffle" % status.id)
		costs.append(status.cost)
	assert_eq(costs, [10, 10, 10, 11, 9] as Array[int], "the costs 1024, 1024, 1024, 2048 and 512, as exponents")
	assert_eq(game.offer_panel().buy_button().text, "Shuffle for 1024", "the buy button")
	assert_not_null(game.offer_panel().end_run_button(), "End run is there")


func test_at_48_shuffle_from_the_offer_closes_it() -> void:
	U.save_game(_dir, U.run(U.board_d1024(), 5000, U.snapshot_board(), 40))
	var app: App = _play()
	U.shown(app)
	app.game_screen().offer_panel().buy_button().pressed.emit()
	assert_eq(U.text(app.session.state.score), "3976", "Shuffle charged")
	U.shown(app)
	assert_false(app.session.is_offer_open(), "the offer closes")
	assert_false(app.game_screen().offer_panel().visible, "its panel hides")
	assert_true(app.game_screen().hud().visible, "the HUD is back")


func test_at_55_the_offer_survives_a_restart() -> void:
	var saved: RunState = U.run(U.board_d1024(), 5000)
	U.save_game(_dir, saved)
	var app: App = _play()
	U.shown(app)
	assert_true(app.session.is_offer_open(), "the offer is open")
	app.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	var reopened: App = _restart()
	assert_not_null(reopened.splash_screen(), "the splash shows first (AT-147 d)")
	U.play(reopened)
	U.shown(reopened)
	assert_true(reopened.session.state.equals(saved), "same board and score")
	assert_true(reopened.session.is_offer_open(), "and the offer opens again")
	assert_true(reopened.game_screen().offer_panel().visible, "on screen")


func test_at_65_targeting_is_not_saved() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	app.session.press_booster(&"swap")
	app.session.tap_cell(Vector2i(0, 0))
	app.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	var reopened: App = _restart_play()
	assert_eq(reopened.session.targeting_booster(), &"", "no booster active")
	assert_eq(reopened.session.swap_first(), U.NO_CELL, "no tile selected")
	assert_eq(U.text(reopened.session.state.score), "5000", "score 5,000")


# Play screen mirrors

func test_at_97_booster_taps_wait_for_the_view() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6)]
	assert_true(app.session.commit_chain(chain).accepted, "a chain commits")
	assert_true(app.game_screen().board().is_animating(), "and its animation plays")
	var bar: SkinBoosterBar = app.game_screen().booster_bar()
	bar.booster_pressed.emit(&"shuffle")
	assert_eq(U.text(app.session.state.score), "5004", "a booster tap is ignored while it plays")
	assert_false(app.session.begin_drag(), "so is a new drag")
	var cost: int = BoosterRules.cost(&"shuffle", app.session.state, app.config)
	U.shown(app)
	bar.booster_pressed.emit(&"shuffle")
	assert_eq(app.session.state.score.to_int(), 5004 - (1 << cost), "works once it has been shown")


func test_targeting_hint_reaches_the_bar_and_the_context_row() -> void:
	U.save_game(_dir, U.run(U.board_p(), 5000))
	var app: App = _play()
	U.shown(app)
	app.session.press_booster(&"hammer")
	assert_eq(app.game_screen().booster_bar().call(&"hint_text"), app.skin.cased(&"label", "Tap a tile to smash it"), "Gumdrop's hint pill")
	app.session.cancel_targeting()
	assert_eq(app.game_screen().booster_bar().call(&"hint_text"), "", "hidden after targeting")


func test_slate_context_row_shows_targeting_and_the_chain() -> void:
	var settings: Settings = Settings.new()
	settings.set_skin_id(&"slate")
	U.save_game(_dir, U.run(U.board_p(), 5000), 0, 0, settings)
	var app: App = _play()
	U.shown(app)
	var hud: SkinHud = app.game_screen().hud()
	app.session.press_booster(&"swap")
	assert_eq(hud.call(&"context_text"), "SWAP: TAP TWO TILES TO SWAP THEM", "targeting in the context row")
	app.session.tap_cell(Vector2i(0, 0))
	assert_eq(hud.call(&"context_text"), "SWAP: NOW TAP THE TILE TO SWAP WITH", "after the first tile")
	app.session.cancel_targeting()
	assert_eq(hud.call(&"context_text"), "", "cleared")
	var chain: Array[Vector2i] = [Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]
	app.game_screen().board().chain_changed.emit(chain, 8)
	assert_eq(hud.call(&"context_text"), "CHAIN 3", "the chain while dragging")
	var preview: SkinTileView = hud.preview_slot().get_child(0) as SkinTileView
	assert_true(preview.visible, "the preview tile in the slot")
	var empty: Array[Vector2i] = []
	app.game_screen().board().chain_changed.emit(empty, 0)
	assert_eq(hud.call(&"context_text"), "", "cleared on lift")
	assert_false(preview.visible, "and the preview hides")


func test_at_104_a_clear_shows_the_notice() -> void:
	# AT-99: the chain raises the floor and clears one 2.
	var board: PackedInt64Array = U.with_cell(U.with_cell(U.with_cell(_board_e(), Vector2i(0, 3), 1), Vector2i(4, 6), 10), Vector2i(4, 7), 10)
	U.save_game(_dir, U.run(board, 10000))
	var app: App = _play()
	U.shown(app)
	var chain: Array[Vector2i] = [Vector2i(4, 6), Vector2i(4, 7)]
	var result: MoveResult = app.session.commit_chain(chain)
	assert_eq(result.cleared_values, PackedInt64Array([1]), "the move cleared the 2s")
	U.gate(app)
	assert_not_null(app.game_screen().hud().call(&"clear_notice"), "the HUD shows the clear notice")


func test_scores_reach_the_hud() -> void:
	U.save_game(_dir, U.run(U.board_p(), 1234), 98765, 5)
	var app: App = _play()
	U.gate(app)
	var label: Label = app.game_screen().hud().score_label()
	assert_eq(label.text, "1,234", "the score")


func _board_e() -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	for row: int in 8:
		for column: int in 5:
			if row % 2 == 0:
				cells.append(2 if column % 2 == 0 else 4)
			else:
				cells.append(3 if column % 2 == 0 else 5)
	return cells


# AT-154, the App half: which copy Play continues (GDD 15.1 LG1 to LG4).

## Saves run A (19,000) then run B (20,000) through the service, as two moves
## would, with Best Score 20,000, then cuts run.json off part way.
@warning_ignore("integer_division")
func _at_154_two_runs_then_damage() -> void:
	var service: SaveService = SaveService.new(_dir)
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(20000)
	records.best_tile = 10
	service.save_profile(Settings.new(), records)
	service.save_run(U.run(U.board_p(), 19000, PackedInt64Array(), 0, 0, 0, 18000))
	service.save_run(U.run(U.with_cell(U.board_p(), Vector2i(0, 0), 6), 20000, PackedInt64Array(), 0, 0, 0, 18000))
	var text: String = U.SaveFixtures.read_text(_dir.path_join("run.json"))
	U.SaveFixtures.write_text(_dir.path_join("run.json"), text.left(text.length() / 2))


func test_at_154_a_play_continues_the_last_good_copy() -> void:
	_at_154_two_runs_then_damage()
	var app: App = _start()
	assert_not_null(app.splash_screen(), "the splash as usual")
	assert_true(app.has_held_run(), "the last good copy is held")
	assert_eq(U.text(app.records.best_score), "20000", "Best Score kept")
	U.play(app)
	assert_eq(U.text(app.session.state.score), "19000", "Play continues the run at 19,000")
	assert_true(app.session.state.equals(U.run(U.board_p(), 19000, PackedInt64Array(), 0, 0, 0, 18000)), "run A exactly")


@warning_ignore("integer_division")
func test_at_154_b_play_starts_a_new_run_when_both_copies_are_damaged() -> void:
	_at_154_two_runs_then_damage()
	var bak: String = _dir.path_join("run.json.bak")
	var text: String = U.SaveFixtures.read_text(bak)
	U.SaveFixtures.write_text(bak, text.left(text.length() / 2))
	var app: App = _start()
	assert_false(app.has_held_run(), "no run held")
	assert_false(FileAccess.file_exists(bak), "the damaged last good copy is deleted")
	assert_eq(U.text(app.records.best_score), "20000", "Best Score kept")
	U.play(app)
	assert_eq(U.text(app.session.state.score), "0", "Play starts a new run")
