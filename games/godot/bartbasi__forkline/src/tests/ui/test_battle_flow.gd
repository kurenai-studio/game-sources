# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The game flow of the App around the battle screen (docs/ARCHITECTURE.md 3.6 flow
## steps 1 to 6, 5.1, 6, 7.5): start a level from the mode screen, play a scripted win
## through the screen's own panels, stars recorded, the Continue card, resume at the
## exact moment and paused, a resize that pauses, abandon, sound, and every save trigger.
## No running scene tree: the layout itself is checked in real_tree_checks.gd.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "flow"

var apps: Array[App] = []


func before_each() -> void:
	apps.clear()
	Fx.wipe(TAG)


func after_each() -> void:
	for made: App in apps:
		made.free()
	Fx.wipe(TAG)


func _drop(made: App) -> void:
	apps.erase(made)
	made.free()


func _app(fresh: bool = true) -> App:
	var made: App = Fx.app(TAG, fresh)
	apps.append(made)
	return made


## The App at the front door, then through Play and Campaign to a started level.
func _start(made: App, id: StringName = &"r1_l1", relaxed: bool = false) -> BattleScreen:
	Fx.mark_all_seen(made)
	made.open_mode()
	made.campaign_requested.emit()
	assert_true(made.current_screen() is LevelSelect, "Campaign opens the level list")
	(made.current_screen() as LevelSelect).level_chosen.emit(id)
	assert_true(made.current_screen() is LevelCard, "a level opens its card")
	(made.current_screen() as LevelCard).play_requested.emit(relaxed)
	assert_true(made.current_screen() is BattleScreen, "Play starts the battle")
	return made.battle_screen()


func _saved_on_disk() -> Array[SavedGame]:
	return SaveStore.new(Fx.dir(TAG)).load_games(Fx.BattleFixtures.game())


func _midwave(made: App) -> BattleScreen:
	var screen: BattleScreen = _start(made)
	Fx.build(screen, screen.battle.level.spots[0], &"sling_post")
	screen.hud.call_button.tapped.emit()
	Fx.run(screen, 200, func() -> bool: return screen.battle.enemies.size() >= 2)
	assert_true(screen.battle.phase == Battle.Phase.WAVE and screen.battle.enemies.size() >= 2, "a wave is running")
	return screen


# Start, play, record.

func test_a_level_starts_from_the_mode_screen_at_1x_and_is_saved() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	assert_eq(screen.clock.speed, 1, "every level starts at 1x")
	assert_false(screen.battle.relaxed, "Normal is the default")
	assert_eq(made.active_game().level_id, &"r1_l1")
	var saved: Array[SavedGame] = _saved_on_disk()
	assert_eq(saved.size(), 1, "a level begins in a build phase, which saves")
	assert_eq(saved[0].level_id, &"r1_l1")
	assert_eq(saved[0].battle.tick, 0)


func test_a_scripted_win_through_the_screen_records_the_stars() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	var ended: Array[Dictionary] = []
	screen.ended.connect(func(result: Dictionary) -> void: ended.append(result))
	assert_true(Fx.play_out(screen), "the scripted defense wins level 1-1")
	assert_eq(ended.size(), 1, "the screen reports the end once")
	assert_true(ended[0]["won"])
	assert_false(ended[0]["abandoned"])
	var bits: int = ended[0]["stars"]
	assert_true(bits & 1 == 1, "a win is at least one star")
	assert_eq(made.progress.levels[&"r1_l1"], bits, "the stars are recorded")
	assert_true(made.progress.cleared(&"r1_l1"))
	assert_true(made.progress.level_open(made.game, &"r1_l2"), "the next level opens")
	assert_eq(SaveStore.new(Fx.dir(TAG)).load_progress().levels[&"r1_l1"], bits, "and saved")
	assert_eq(_saved_on_disk().size(), 0, "a finished game is not kept")
	assert_eq(made.saved_games.size(), 0)
	assert_true(made.top_modal() is EndPanel, "the end panel shows")
	assert_true((made.top_modal() as EndPanel).won)
	assert_eq(made.stars, StarText.count(bits), "the App's star count follows")


func test_a_relaxed_win_earns_only_the_first_star() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made, &"r1_l1", true)
	assert_true(screen.battle.relaxed)
	assert_eq(screen.battle.lives, 40)
	assert_true(Fx.play_out(screen))
	assert_eq(made.progress.levels[&"r1_l1"], 1)


func test_a_loss_records_nothing_and_offers_another_try() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	var guard: int = 0
	while screen.battle.phase != Battle.Phase.LOST and guard < 40000:
		if screen.battle.phase == Battle.Phase.BUILD:
			screen.hud.call_button.tapped.emit()
		screen.frame(0.05)
		guard += 1
	assert_eq(screen.battle.phase, Battle.Phase.LOST)
	assert_false(made.progress.levels.has(&"r1_l1"), "a loss records nothing")
	assert_eq(_saved_on_disk().size(), 0)
	var panel: EndPanel = made.top_modal() as EndPanel
	assert_not_null(panel)
	assert_false(panel.won)
	assert_null(panel.next_button, "no next level after a loss")
	panel.retry_button.tapped.emit()
	assert_true(made.current_screen() is BattleScreen, "Try again starts the level again")
	assert_eq(made.battle_screen().battle.tick, 0)
	assert_eq(made.modal_count(), 0)


func test_the_end_panel_goes_to_the_next_level_and_the_level_list() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	assert_true(Fx.play_out(screen))
	var panel: EndPanel = made.top_modal() as EndPanel
	assert_not_null(panel.next_button)
	panel.next_button.tapped.emit()
	assert_true(made.current_screen() is LevelCard, "Next level opens the card of level 1-2")
	assert_eq((made.current_screen() as LevelCard).level_id, &"r1_l2")
	assert_eq(made.modal_count(), 0)
	assert_eq(made.screen_count(), 4, "front door, mode, levels, card")
	assert_true(made.handle_back() == &"page")
	assert_true(made.current_screen() is LevelSelect)


# Leaving and Continue.

func test_continue_appears_after_leaving_mid_wave() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.pause()
	assert_true(screen.pause_menu_open())
	screen.left.emit()
	assert_eq(made.screen_count(), 1, "Back to menu returns to the front door")
	assert_eq(made.modal_count(), 0)
	assert_null(made.battle_screen())
	made.open_mode()
	var mode: ModeScreen = made.current_screen() as ModeScreen
	assert_not_null(mode.continue_button, "the Continue card is on top")
	assert_eq(_saved_on_disk().size(), 1)
	assert_eq(_saved_on_disk()[0].battle.tick, screen.battle.tick, "saved at the exact moment")


func test_no_continue_card_without_a_saved_game() -> void:
	var made: App = _app()
	made.open_mode()
	assert_null((made.current_screen() as ModeScreen).continue_button)


func test_a_new_app_resumes_the_saved_battle_byte_identical_and_paused() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	made.leave_app()
	assert_true(screen.is_paused(), "leaving the app pauses a running wave")
	var before: String = JSON.stringify(screen.battle.to_data())
	var tick: int = screen.battle.tick
	_drop(made)
	var again: App = _app(false)
	assert_eq(again.saved_games.size(), 1, "the saved game loads at launch")
	again.open_mode()
	var mode: ModeScreen = again.current_screen() as ModeScreen
	assert_not_null(mode.continue_button)
	mode.continue_button.tapped.emit()
	var resumed: BattleScreen = again.battle_screen()
	assert_not_null(resumed, "one tap on Continue resumes")
	assert_eq(JSON.stringify(resumed.battle.to_data()), before, "the exact moment, byte for byte")
	assert_true(resumed.is_paused(), "resumed paused")
	assert_true(resumed.pause_menu_open(), "on the Pause menu")
	assert_true(again.top_modal() is PausePanel)
	for i: int in 20:
		resumed.frame(0.05)
	assert_eq(resumed.battle.tick, tick, "nothing moves while paused")
	(again.top_modal() as PausePanel).request_close()
	assert_false(resumed.is_paused(), "Resume goes on")
	for i: int in 20:
		resumed.frame(0.05)
	assert_true(resumed.battle.tick > tick)


func test_a_saved_level_resumes_from_its_own_card() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.pause()
	screen.left.emit()
	made.open_mode()
	made.campaign_requested.emit()
	var list: LevelSelect = made.current_screen() as LevelSelect
	list.level_chosen.emit(&"r1_l1")
	var card: LevelCard = made.current_screen() as LevelCard
	assert_not_null(card.resume_button, "the saved level's card offers Resume")
	card.resume_requested.emit()
	assert_true(made.current_screen() is BattleScreen)
	assert_true(made.battle_screen().is_paused())


func test_a_corrupt_saved_game_is_dropped_at_launch() -> void:
	var made: App = _app()
	_start(made)
	_drop(made)
	var file: FileAccess = FileAccess.open(Fx.dir(TAG) + "game_level.json", FileAccess.WRITE)
	file.store_string("{\"format\": 1, \"mode\": \"level\"}")
	file.close()
	DirAccess.remove_absolute(Fx.dir(TAG) + "game_level.json.bak")
	var again: App = _app(false)
	assert_eq(again.saved_games.size(), 0, "an invalid saved game is not offered")


# Starting a different level.

func test_starting_another_level_asks_first_and_cancel_keeps_the_game() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.pause()
	screen.left.emit()
	made.progress.record_level(&"r1_l1", 1)
	made.open_level_card(&"r1_l2")
	var card: LevelCard = made.current_screen() as LevelCard
	assert_null(card.resume_button, "level 1-2 has no saved game")
	card.play_requested.emit(false)
	var dialog: ConfirmDialog = made.top_modal() as ConfirmDialog
	assert_not_null(dialog, "a saved game of another level asks first")
	assert_true(made.current_screen() is LevelCard, "nothing started yet")
	dialog.request_close()
	assert_eq(made.modal_count(), 0)
	assert_eq(made.saved_games.size(), 1)
	assert_eq(made.saved_games[0].level_id, &"r1_l1", "cancel keeps the saved game")
	assert_eq(_saved_on_disk()[0].level_id, &"r1_l1")


func test_confirming_ends_the_saved_game_and_records_nothing() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.pause()
	screen.left.emit()
	made.progress.record_level(&"r1_l1", 1)
	var stars_before: int = made.progress.stars()
	made.open_level_card(&"r1_l2")
	(made.current_screen() as LevelCard).play_requested.emit(false)
	var dialog: ConfirmDialog = made.top_modal() as ConfirmDialog
	_press(dialog, "Start new game")
	assert_true(made.current_screen() is BattleScreen, "confirming starts the new level")
	assert_eq(made.battle_screen().battle.level.id, &"r1_l2")
	assert_eq(made.modal_count(), 0)
	assert_eq(made.saved_games.size(), 1)
	assert_eq(made.saved_games[0].level_id, &"r1_l2", "one saved game per mode")
	assert_eq(made.progress.stars(), stars_before, "nothing from the ended game was recorded")


func _press(root: Node, text: String) -> void:
	for node: Node in root.find_children("*", "TapButton", true, false):
		if (node as TapButton).text == text:
			(node as TapButton).tapped.emit()
			return
	fail("no button '%s'" % text)


# Abandon.

func test_abandon_asks_first() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.pause()
	var pause: PausePanel = made.top_modal() as PausePanel
	_press(pause, "Abandon")
	assert_true(pause.confirm_open(), "Abandon asks")
	assert_true(made.current_screen() is BattleScreen, "the game is still there")
	assert_eq(_saved_on_disk().size(), 1)
	pause.request_close()
	assert_false(pause.confirm_open(), "the back button cancels the question")
	assert_true(made.top_modal() is PausePanel)
	assert_eq(_saved_on_disk().size(), 1)


func test_confirmed_abandon_ends_the_game_and_records_nothing() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.pause()
	var pause: PausePanel = made.top_modal() as PausePanel
	_press(pause, "Abandon")
	var confirm: Node = pause.find_children("*", "ConfirmDialog", true, false)[0]
	_press(confirm, "Abandon")
	assert_eq(made.screen_count(), 1, "back at the front door")
	assert_eq(made.modal_count(), 0)
	assert_eq(_saved_on_disk().size(), 0, "the saved game ended")
	assert_eq(made.saved_games.size(), 0)
	assert_false(made.progress.levels.has(&"r1_l1"), "an abandoned level records nothing")
	assert_null(made.active_game())


# Pause on resize.

func test_a_resize_mid_wave_pauses_and_keeps_all_state() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	var before: String = JSON.stringify(screen.battle.to_data())
	var parts: Array[int] = [screen.map_view.get_instance_id(), screen.hud.get_instance_id(), screen.preview.get_instance_id(), screen.build_panel.get_instance_id(), screen.tower_panel.get_instance_id()]
	assert_false(screen.is_paused())
	made.apply_layout(Fx.INNER, Fx.INNER_SAFE)
	assert_true(screen.is_paused(), "a size change during a wave pauses")
	assert_true(screen.pause_menu_open())
	assert_true(screen.landscape, "and the layout follows the window")
	assert_eq(JSON.stringify(screen.battle.to_data()), before, "the battle is untouched")
	var after: Array[int] = [screen.map_view.get_instance_id(), screen.hud.get_instance_id(), screen.preview.get_instance_id(), screen.build_panel.get_instance_id(), screen.tower_panel.get_instance_id()]
	assert_eq(after, parts, "no state node was replaced")
	made.apply_layout(Fx.COVER, Fx.COVER_SAFE)
	assert_eq(JSON.stringify(screen.battle.to_data()), before, "folding back changes nothing either")
	assert_false(screen.landscape)
	assert_eq(screen.battle.to_data()["tick"], screen.battle.tick)


func test_a_resize_in_a_build_phase_only_changes_the_layout() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	made.apply_layout(Fx.INNER, Fx.INNER_SAFE)
	assert_false(screen.is_paused())
	assert_false(screen.pause_menu_open())
	assert_true(screen.landscape)


func test_the_same_size_again_does_not_pause() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	made.apply_layout(Fx.COVER, Fx.COVER_SAFE)
	assert_false(screen.is_paused())


# Settings.

func test_the_sound_setting_is_saved_and_applied() -> void:
	var made: App = _app()
	assert_true(made.audio.is_enabled())
	made.open_settings()
	(made.top_modal() as SettingsPanel).sound_button.tapped.emit()
	assert_false(made.audio.is_enabled(), "the toggle reaches the AudioService")
	assert_false(made.sound_on)
	assert_false(SaveStore.new(Fx.dir(TAG)).load_settings().sound_on, "and is saved")
	var again: App = _app(false)
	assert_false(again.sound_on, "a new launch reads it")
	assert_false(again.audio.is_enabled(), "and applies it at boot")
	again.open_settings()
	(again.top_modal() as SettingsPanel).sound_button.tapped.emit()
	assert_true(again.audio.is_enabled())
	assert_true(SaveStore.new(Fx.dir(TAG)).load_settings().sound_on)
	Fx.audio().set_enabled(true)


# The battle screen reaches the App only through signals.

func test_pause_goes_to_the_app_as_a_modal() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	assert_eq(made.modal_count(), 0)
	screen.pause()
	assert_true(screen.pause_menu_open())
	assert_eq(made.modal_count(), 1, "modal_requested put Pause in the App's layer")
	assert_true(made.top_modal() is PausePanel)
	assert_eq(screen._modals.size(), 0, "and the screen kept none of its own")


func test_pause_info_opens_the_info_screen() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	screen.pause()
	var before: int = made.screen_count()
	(made.top_modal() as PausePanel).info_requested.emit()
	assert_eq(made.screen_count(), before + 1, "info_requested pushed a screen")
	assert_true(made.current_screen() is InfoScreen)


func test_pause_settings_opens_the_settings_panel() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	screen.pause()
	(made.top_modal() as PausePanel).settings_requested.emit()
	assert_eq(made.modal_count(), 2, "settings_requested opened a second modal")
	assert_true(made.top_modal() is SettingsPanel)


# Save triggers.

func test_a_finished_wave_saves_the_next_build_phase() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	Fx.build(screen, screen.battle.level.spots[0], &"sling_post")
	Fx.build(screen, screen.battle.level.spots[1], &"sling_post")
	screen.hud.call_button.tapped.emit()
	Fx.run(screen, 5000, func() -> bool: return screen.battle.phase == Battle.Phase.BUILD)
	assert_eq(screen.battle.phase, Battle.Phase.BUILD)
	assert_eq(screen.battle.waves_started, 1)
	var saved: Array[SavedGame] = _saved_on_disk()
	assert_eq(saved[0].battle.waves_started, 1, "the build phase after wave 1 was saved")
	assert_eq(saved[0].battle.tick, screen.battle.tick)
	assert_eq(saved[0].battle.towers.size(), 2)


func test_pause_saves() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	var tick: int = screen.battle.tick
	assert_true(_saved_on_disk()[0].battle.tick < tick, "the file is behind the game before the pause")
	screen.pause()
	assert_eq(_saved_on_disk()[0].battle.tick, tick)


func test_the_pause_button_freezes_and_saves() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.hud.pause_button.tapped.emit()
	assert_true(screen.is_paused())
	assert_false(screen.pause_menu_open(), "the game stays open to build while frozen")
	assert_true(screen.pause_strip.visible)
	assert_eq(_saved_on_disk()[0].battle.tick, screen.battle.tick)
	var tick: int = screen.battle.tick
	for i: int in 10:
		screen.frame(0.05)
	assert_eq(screen.battle.tick, tick)
	var cell: Vector2i = screen.battle.level.spots[1]
	screen.battle.gold = 500
	assert_true(Fx.build(screen, cell, &"pumpkin_catapult"), "building works while paused")
	screen.hud.pause_button.tapped.emit()
	assert_false(screen.is_paused(), "the same button goes on")
	assert_false(screen.pause_strip.visible)


func test_the_paused_strips_menu_saves_what_was_built_while_frozen() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	screen.hud.pause_button.tapped.emit()
	var cell: Vector2i = screen.battle.level.spots[1]
	screen.battle.gold = 500
	assert_true(Fx.build(screen, cell, &"pumpkin_catapult"), "building works while frozen")
	var before: SavedGame = _saved_on_disk()[0]
	assert_null(before.battle.tower_at(cell), "the build is not on disk yet")
	screen.pause_strip.menu_button.tapped.emit()
	assert_true(screen.pause_menu_open())
	var after: SavedGame = _saved_on_disk()[0]
	assert_not_null(after.battle.tower_at(cell), "Menu saved the game with the new tower")
	assert_eq(after.battle.tower_at(cell).type, &"pumpkin_catapult")


func test_losing_focus_pauses_a_running_wave_and_saves() -> void:
	for what: int in [Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_WM_CLOSE_REQUEST]:
		var made: App = _app()
		var screen: BattleScreen = _midwave(made)
		var tick: int = screen.battle.tick
		made.notification(what)
		assert_true(screen.is_paused(), "notification %d pauses" % what)
		assert_true(screen.pause_menu_open())
		assert_eq(_saved_on_disk()[0].battle.tick, tick, "notification %d saves the exact moment" % what)
		_drop(made)
		Fx.wipe(TAG)


func test_leaving_the_app_in_a_build_phase_saves_without_a_pause() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	Fx.build(screen, screen.battle.level.spots[0], &"sling_post")
	made.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(screen.pause_menu_open())
	assert_eq(_saved_on_disk()[0].battle.towers.size(), 1)


# Back button.

func test_back_in_a_battle_opens_pause_and_back_again_resumes() -> void:
	var made: App = _app()
	var screen: BattleScreen = _midwave(made)
	assert_eq(made.handle_back(), &"modal")
	assert_true(screen.pause_menu_open())
	assert_true(screen.is_paused())
	assert_eq(made.handle_back(), &"modal")
	assert_false(screen.pause_menu_open())
	assert_false(screen.is_paused())
	assert_true(made.current_screen() is BattleScreen)


# Progress locks, names and the damaged copy.

func test_roguelite_and_daily_lock_follow_the_progress() -> void:
	var made: App = _app()
	assert_false(made.runs_open)
	made.open_mode()
	assert_true((made.current_screen() as ModeScreen).roguelite_button.disabled)
	assert_true((made.current_screen() as ModeScreen).daily_button.disabled)
	made.handle_back()
	for id: StringName in [&"r1_l1", &"r1_l2", &"r1_l3", &"r1_l4"]:
		made.progress.record_level(id, 7)
	made.save_progress()
	assert_true(made.runs_open, "the 12 star rule still counts the stars")
	assert_eq(made.stars, 12)
	made.open_mode()
	var mode: ModeScreen = made.current_screen() as ModeScreen
	assert_false(mode.roguelite_button.disabled, "the run mode is built, so 12 stars open it")
	assert_false(mode.daily_button.disabled)


func test_info_gets_its_numbers_and_names_from_the_catalog() -> void:
	var made: App = _app()
	var catalog: Catalog = made.game.catalog
	assert_eq(made.rules["refund_pct"], catalog.rules.refund_pct)
	assert_eq(made.rules["star2_lives"], catalog.rules.star2_lives)
	assert_eq(made.rules["run_stars"], catalog.rules.run_stars)
	assert_eq(made.names[&"sling_post"], catalog.tower(&"sling_post").name)
	assert_eq(made.names[&"scamp"], catalog.enemy(&"scamp").name)
	assert_eq(made.names.size(), catalog.tower_ids().size() + catalog.enemy_ids().size())


func test_a_damaged_data_folder_shows_the_message_and_starts_nothing() -> void:
	var made: App = App.new()
	apps.append(made)
	made.data_root = "res://tests/ui/no_such_folder"
	made.store = SaveStore.new(Fx.dir(TAG))
	made.audio = Fx.audio()
	made.build()
	assert_true(made.damaged)
	assert_true(made.current_screen() is DamagedScreen)
	assert_eq((made.current_screen() as DamagedScreen).message_label.text, "This copy of Forkline is damaged. Installing it again should fix it.")
	var count: int = made.screen_count()
	made.open_mode()
	made.campaign_requested.emit()
	assert_eq(made.screen_count(), count, "nothing else opens")
	assert_eq(made.handle_back(), &"quit")
