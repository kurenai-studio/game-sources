# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Bart's three requests of 2026-10-28: Restart in Pause (in a level, a Twist, a run and the
## daily, with what each records), the sound button in the HUD (U8), and the Music and Sound
## effects rows in Settings. The finger scrolling of lists needs a scene tree and is checked in
## tests/ui/real_tree_u6.gd. No running scene tree here.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "u6"
const DAY_1: Dictionary = {"year": 2026, "month": 10, "day": 24}

var apps: Array[App] = []
var spare: Array[Node] = []


func before_each() -> void:
	apps.clear()
	Fx.wipe(TAG)


func after_each() -> void:
	for made: App in apps:
		made.free()
	for node: Node in spare:
		node.free()
	spare.clear()
	Fx.audio().set_music_on(true)
	Fx.audio().set_enabled(true)
	Fx.wipe(TAG)


func _keep(node: Node) -> Node:
	spare.append(node)
	return node


func _app(fresh: bool = true) -> App:
	var made: App = Fx.app(TAG, fresh)
	apps.append(made)
	return made


func _run_app(day: Dictionary = DAY_1) -> App:
	var made: App = Fx.run_app(TAG, true, day)
	apps.append(made)
	return made


func _store() -> SaveStore:
	return SaveStore.new(Fx.dir(TAG))


func _saved_on_disk() -> Array[SavedGame]:
	return _store().load_games(Fx.BattleFixtures.game())


func _button(root: Node, text: String) -> TapButton:
	for node: Node in root.find_children("*", "TapButton", true, false):
		if (node as TapButton).text == text:
			return node as TapButton
	return null


func _press(root: Node, text: String) -> void:
	var found: TapButton = _button(root, text)
	assert_not_null(found, "a button '%s'" % text)
	if found != null:
		found.tapped.emit()


## Pause is open: Restart, then the answer in the question.
func _restart_through_the_question(made: App) -> void:
	var pause: PausePanel = made.top_modal() as PausePanel
	assert_not_null(pause, "Pause is open")
	_press(pause, "Restart")
	assert_true(pause.confirm_open(), "Restart asks first")
	var confirm: ConfirmDialog = pause.find_children("*", "ConfirmDialog", true, false)[0] as ConfirmDialog
	_press(confirm, "Restart")


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


# Level helpers.

func _start(made: App, id: StringName = &"r1_l1", relaxed: bool = false, twist: bool = false) -> BattleScreen:
	Fx.mark_all_seen(made)
	made.open_mode()
	made.campaign_requested.emit()
	(made.current_screen() as LevelSelect).level_chosen.emit(id)
	var card: LevelCard = made.current_screen() as LevelCard
	if twist:
		card.twist_requested.emit(relaxed)
	else:
		card.play_requested.emit(relaxed)
	assert_true(made.current_screen() is BattleScreen, "the level starts")
	return made.battle_screen()


func _midwave(screen: BattleScreen) -> void:
	Fx.build(screen, screen.battle.level.spots[0], &"sling_post")
	screen.hud.call_button.tapped.emit()
	Fx.run(screen, 200, func() -> bool: return screen.battle.enemies.size() >= 2)
	assert_true(screen.battle.phase == Battle.Phase.WAVE, "a wave is running")


func _start_run(made: App, relaxed: bool = false) -> BattleScreen:
	made.open_mode()
	made.roguelite_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	if relaxed:
		card.relaxed_button.tapped.emit()
	card.start_button.tapped.emit()
	return made.battle_screen()


func _start_daily(made: App) -> BattleScreen:
	made.open_mode()
	made.daily_requested.emit()
	(made.current_screen() as RunCard).start_button.tapped.emit()
	return made.battle_screen()


## Calls the next wave from the HUD and plays it out with plenty of lives, then takes a card.
func _play_wave_and_pick(screen: BattleScreen) -> void:
	screen.hud.call_button.tapped.emit()
	screen.battle.lives = 500
	var guard: int = 0
	while screen.battle.phase == Battle.Phase.WAVE and guard < 40000:
		screen.battle.step()
		guard += 1
	screen.frame(0.0)
	if screen.draft_is_open():
		screen.draft_panel.select(screen.draft_panel.offered()[0])
		screen.draft_panel.take()


# The Pause menu.

func test_pause_has_restart_beside_abandon_and_both_are_touch_sized() -> void:
	var panel: PausePanel = _keep(PausePanel.new()) as PausePanel
	assert_not_null(panel.restart_button)
	assert_not_null(panel.abandon_button)
	assert_eq(panel.restart_button.text, "Restart")
	assert_true(panel.restart_button.get_parent() == panel.abandon_button.get_parent(), "side by side in one row")
	for b: TapButton in [panel.restart_button, panel.abandon_button]:
		assert_true(b.custom_minimum_size.x >= Layout.MIN_TOUCH and b.custom_minimum_size.y >= Layout.MIN_TOUCH, "%s is at least 48 dp" % b.text)


func test_restart_asks_first_the_back_button_cancels_and_only_the_answer_restarts() -> void:
	var panel: PausePanel = _keep(PausePanel.new()) as PausePanel
	panel.apply_layout(Vector2(1080.0, 2767.0), Rect2(0.0, 96.0, 1080.0, 2500.0))
	var events: Array[String] = []
	panel.restart_confirmed.connect(func() -> void: events.append("restart"))
	panel.abandon_confirmed.connect(func() -> void: events.append("abandon"))
	panel.restart_button.tapped.emit()
	assert_true(panel.confirm_open(), "the question is open")
	assert_eq(events.size(), 0, "nothing happens before the answer")
	panel.request_close()
	assert_false(panel.confirm_open(), "back cancels the question")
	assert_eq(events.size(), 0)
	panel.restart_button.tapped.emit()
	var confirm: ConfirmDialog = panel.find_children("*", "ConfirmDialog", true, false)[0] as ConfirmDialog
	assert_true(_texts(confirm).has("Restart?"), "the question is titled Restart?")
	_press(confirm, "Keep playing")
	assert_eq(events.size(), 0, "Keep playing changes nothing")
	panel.restart_button.tapped.emit()
	confirm = panel.find_children("*", "ConfirmDialog", true, false)[0] as ConfirmDialog
	_press(confirm, "Restart")
	assert_eq(events, ["restart"] as Array[String], "only Restart was sent")


func test_the_question_says_plainly_what_happens_in_each_mode() -> void:
	var made: App = _run_app()
	var level: BattleScreen = _start(made)
	assert_eq(level.restart_text(), PausePanel.RESTART_LEVEL)
	assert_true(level.restart_text().contains("Nothing from this game is recorded"))
	level.pause()
	_press(made.top_modal(), "Restart")
	var asked: Array[String] = []
	for node: Node in made.top_modal().find_children("*", "Label", true, false):
		asked.append((node as Label).text)
	assert_true(asked.has(PausePanel.RESTART_LEVEL), "Pause shows the level sentence: %s" % [asked])
	made.close_all_modals()
	var twist: App = _run_app()
	twist.progress.record_level(&"r1_l1", 7)
	var twist_screen: BattleScreen = _start(twist, &"r1_l1", false, true)
	assert_true(twist_screen.restart_text().begins_with("This Twist starts over"), twist_screen.restart_text())
	assert_true(twist_screen.restart_text().contains("Nothing from this game is recorded"))
	var run_app: App = _run_app()
	var run_screen: BattleScreen = _start_run(run_app)
	assert_true(run_screen.restart_text().contains("counts as lost on its current wave"), run_screen.restart_text())
	assert_true(run_screen.restart_text().contains("new run starts, on the same difficulty"))
	var daily_app: App = _run_app()
	var daily_screen: BattleScreen = _start_daily(daily_app)
	assert_true(daily_screen.restart_text().contains("counts as lost on its current wave"), daily_screen.restart_text())
	assert_true(daily_screen.restart_text().contains("same day's daily starts again"))


# Restart: a level.

func test_restarting_a_level_starts_it_over_on_the_same_difficulty_and_records_nothing() -> void:
	for relaxed: bool in [false, true]:
		var made: App = _app()
		var screen: BattleScreen = _start(made, &"r1_l1", relaxed)
		_midwave(screen)
		screen.hud.set_speed(3)
		screen.clock.speed = 3
		var depth: int = made.screen_count()
		screen.pause()
		_restart_through_the_question(made)
		var fresh: BattleScreen = made.battle_screen()
		assert_not_null(fresh)
		assert_true(fresh != screen, "a new battle screen")
		assert_true(made.current_screen() == fresh, "and it is on top")
		assert_eq(made.screen_count(), depth, "the old screen was replaced, not stacked")
		assert_eq(made.modal_count(), 0, "Pause is gone")
		assert_eq(fresh.battle.level.id, &"r1_l1", "the same level")
		assert_eq(fresh.battle.relaxed, relaxed, "the same difficulty")
		assert_eq(fresh.battle.tick, 0, "from the beginning")
		assert_eq(fresh.battle.waves_started, 0)
		assert_true(fresh.battle.phase == Battle.Phase.BUILD, "a build phase")
		assert_eq(fresh.clock.speed, 1, "speed is back at 1x")
		assert_eq(fresh.hud.speed, 1, "and the HUD shows it")
		assert_false(made.progress.levels.has(&"r1_l1"), "nothing recorded: no stars")
		assert_true(made.progress.twists.is_empty(), "nothing recorded: no Twist")
		assert_eq(made.saved_games.size(), 1, "one saved game for the mode")
		var on_disk: Array[SavedGame] = _saved_on_disk()
		assert_eq(on_disk.size(), 1, "the new game is the saved one")
		assert_eq(on_disk[0].battle.tick, 0, "and it is the fresh one")
		assert_eq(on_disk[0].battle.relaxed, relaxed)
		assert_true(made.active_game() == made.saved_games[0] or made.active_game().level_id == &"r1_l1")
		_drop(made)


func test_cancelling_the_restart_question_keeps_the_game() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	_midwave(screen)
	var tick: int = screen.battle.tick
	screen.pause()
	var pause: PausePanel = made.top_modal() as PausePanel
	_press(pause, "Restart")
	pause.request_close()
	assert_false(pause.confirm_open())
	assert_true(made.battle_screen() == screen, "the same screen")
	assert_eq(screen.battle.tick, tick, "the same moment")
	assert_eq(_saved_on_disk().size(), 1)


func _drop(made: App) -> void:
	apps.erase(made)
	made.free()


# Restart: a Twist.

func test_restarting_a_twist_starts_the_twist_again_and_records_nothing() -> void:
	var made: App = _app()
	Fx.mark_all_seen(made)
	made.progress.record_level(&"r1_l1", 7)
	made.save_progress()
	var screen: BattleScreen = _start(made, &"r1_l1", true, true)
	assert_false(screen.battle.twist_effects.is_empty())
	_midwave(screen)
	screen.pause()
	_restart_through_the_question(made)
	var fresh: BattleScreen = made.battle_screen()
	assert_true(fresh != screen)
	assert_true(made.active_game().twist, "still the Twist")
	assert_false(fresh.battle.twist_effects.is_empty(), "with its effects")
	assert_true(fresh.battle.relaxed, "on the same difficulty")
	assert_eq(fresh.battle.tick, 0)
	assert_true(made.progress.twists.is_empty(), "no Twist recorded as cleared")
	assert_eq(made.progress.levels.get(&"r1_l1", 0), 7, "the stars it had are untouched")
	assert_eq(_saved_on_disk().size(), 1)
	assert_true(_saved_on_disk()[0].twist)


# Restart: a roguelite run.

func test_restarting_a_run_counts_it_as_lost_then_starts_a_new_run_on_the_same_difficulty() -> void:
	for relaxed: bool in [false, true]:
		var made: App = _run_app()
		var screen: BattleScreen = _start_run(made, relaxed)
		assert_eq(screen.battle.relaxed, relaxed)
		_play_wave_and_pick(screen)
		screen.hud.call_button.tapped.emit()
		assert_eq(screen.battle.waves_started, 2, "wave 2 is out")
		screen.clock.speed = 2
		screen.pause()
		_restart_through_the_question(made)
		assert_eq(made.progress.counters[&"best_run_wave"], 2, "it counts as lost at the wave it reached")
		assert_eq(made.progress.counters[&"runs_won"], 0, "and it is no win")
		var fresh: BattleScreen = made.battle_screen()
		assert_not_null(fresh)
		assert_true(fresh != screen)
		assert_not_null(made.active_game().run, "a run is on")
		assert_false(made.active_game().run.daily, "it is a roguelite run")
		assert_eq(fresh.battle.relaxed, relaxed, "same difficulty")
		assert_eq(fresh.battle.waves_started, 0, "from the first wave")
		assert_eq(fresh.clock.speed, 1, "1x again")
		assert_eq(made.modal_count(), 0, "no end panel")
		assert_eq(made.saved_games.size(), 1)
		assert_eq(_saved_on_disk().size(), 1)
		assert_eq(_saved_on_disk()[0].battle.waves_started, 0, "the saved run is the new one")
		assert_eq(_store().load_progress().counters[&"best_run_wave"], 2, "the loss is on disk")
		_drop(made)


# Restart: the daily.

func test_restarting_the_daily_records_the_loss_and_starts_the_same_day_again() -> void:
	var day: Dictionary = DAY_1.duplicate()
	var made: App = _run_app(day)
	var screen: BattleScreen = _start_daily(made)
	assert_eq(screen.battle.relaxed, false, "the daily is always Normal")
	var first_seed: int = made.active_game().run.run_seed
	screen.hud.call_button.tapped.emit()
	screen.pause()
	# The phone's date moves on while the game is paused. The daily that restarts is the one
	# the run belongs to.
	day["day"] = 25
	_restart_through_the_question(made)
	assert_eq(made.progress.counters[&"dailies_finished"], 1, "the lost try is counted")
	assert_eq(made.daily_record.streak, 1, "and it counts for the streak")
	assert_eq(made.daily_record.best["won"], false, "as a loss")
	assert_eq(made.progress.counters[&"best_run_wave"], 1)
	assert_eq(_store().load_daily().streak, 1, "on disk too")
	var fresh: BattleScreen = made.battle_screen()
	assert_not_null(fresh)
	assert_true(fresh != screen)
	var run: RunSession = made.active_game().run
	assert_true(run.daily, "a daily is on")
	assert_eq(run.day, "2026-10-24", "the same day's daily")
	assert_eq(run.run_seed, first_seed, "the same seed")
	assert_eq(fresh.battle.waves_started, 0, "from the first wave")
	assert_false(fresh.battle.relaxed)
	assert_eq(fresh.clock.speed, 1)
	assert_eq(made.saved_games.size(), 1)
	assert_eq(_saved_on_disk().size(), 1)


func test_restarting_one_mode_leaves_the_other_modes_saved_games_alone() -> void:
	var made: App = _run_app()
	var daily: BattleScreen = _start_daily(made)
	daily.pause()
	made.close_all_modals()
	made.handle_back()
	made.close_all_modals()
	# Back to the menu keeps the daily saved; then start a level and restart it.
	daily.left.emit()
	var level: BattleScreen = _start(made)
	_midwave(level)
	level.pause()
	_restart_through_the_question(made)
	assert_not_null(made.saved_game(SavedGame.DAILY), "the daily is still saved")
	assert_not_null(made.saved_game(SavedGame.LEVEL), "and the restarted level is saved")
	assert_eq(made.progress.counters[&"dailies_finished"], 0, "the daily was not counted")


# The sound button in the HUD (U8: it turns sound effects and music off together).

func test_the_hud_sound_button_is_a_round_touch_sized_speaker_that_crosses_out() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	var hud: BattleHud = screen.hud
	var button: TapButton = hud.sound_button
	assert_not_null(button)
	assert_true(button.custom_minimum_size.x >= Layout.MIN_TOUCH and button.custom_minimum_size.y >= Layout.MIN_TOUCH, "at least 48 dp")
	assert_true(button.icon == IconTex.make(&"speaker", 72), "a speaker while the sound is on")
	var round_box: StyleBoxFlat = button.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_true(round_box.corner_radius_top_left >= 80, "round")
	var seen: Array[bool] = []
	hud.sound_selected.connect(func(on: bool) -> void: seen.append(on))
	button.tapped.emit()
	assert_eq(seen, [false] as Array[bool], "a tap asks for sound off")
	assert_true(button.icon == IconTex.make(&"speaker_off", 72), "the speaker is crossed out")
	assert_false(button.disabled, "never disabled")
	assert_false(hud.sound_on)
	button.tapped.emit()
	assert_eq(seen, [false, true] as Array[bool])
	assert_true(button.icon == IconTex.make(&"speaker", 72))
	assert_false(button.disabled)


func test_the_sound_button_flips_sound_on_and_never_touches_music_on() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	assert_true(made.audio.is_enabled())
	screen.hud.sound_button.tapped.emit()
	assert_false(made.settings.sound_on, "the master switch changed")
	assert_false(made.sound_on)
	assert_false(made.audio.is_enabled(), "sound effects are off")
	assert_true(made.settings.music_on, "the music setting is untouched")
	assert_true(made.music_on)
	assert_true(made.audio.is_music_on(), "and so is the music switch in the audio service")
	assert_false(_store().load_settings().sound_on, "saved")
	assert_true(_store().load_settings().music_on, "music setting saved as it was")
	screen.hud.sound_button.tapped.emit()
	assert_true(made.audio.is_enabled())
	assert_true(_store().load_settings().sound_on)
	assert_true(_store().load_settings().music_on)


func test_a_tap_never_leaves_music_playing_with_sound_off() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	assert_true(made.audio.is_music_playing(), "the battle music plays")
	screen.hud.sound_button.tapped.emit()
	assert_false(made.audio.is_music_playing(), "sound off silences the music too")
	assert_false(made.audio.is_enabled())
	screen.hud.sound_button.tapped.emit()
	assert_true(made.audio.is_music_playing(), "sound on brings the music back")
	# The player's own music choice is kept across the toggle.
	made.settings.music_on = false
	made.audio.set_music_on(false)
	made.music_on = false
	screen.hud.sound_button.tapped.emit()
	screen.hud.sound_button.tapped.emit()
	assert_true(made.audio.is_enabled())
	assert_false(made.audio.is_music_playing(), "music stays off when the player had it off")
	assert_false(made.settings.music_on)


func test_a_saved_sound_off_is_applied_at_boot_and_shown_in_the_next_level() -> void:
	var first: App = _app()
	first.settings.sound_on = false
	assert_true(first.store.save_settings(first.settings))
	var again: App = _app(false)
	assert_false(again.sound_on)
	assert_false(again.audio.is_enabled(), "the audio service follows the setting")
	var screen: BattleScreen = _start(again)
	assert_true(screen.hud.sound_button.icon == IconTex.make(&"speaker_off", 72), "the level shows it crossed out")
	assert_false(again.audio.is_music_playing())


func test_settings_has_music_and_sound_effects_rows_that_save() -> void:
	var made: App = _app()
	made.open_settings()
	var panel: SettingsPanel = made.top_modal() as SettingsPanel
	assert_eq(panel.sound_button.text, "Sound effects: On")
	assert_eq(panel.music_button.text, "Music: On")
	for b: TapButton in [panel.sound_button, panel.music_button]:
		assert_true(b.custom_minimum_size.x >= Layout.MIN_TOUCH and b.custom_minimum_size.y >= Layout.MIN_TOUCH)
	panel.music_button.tapped.emit()
	assert_eq(panel.music_button.text, "Music: Off")
	assert_false(made.settings.music_on)
	assert_false(made.audio.is_music_on())
	assert_true(made.audio.is_enabled(), "sound effects stay on")
	assert_false(_store().load_settings().music_on, "saved")
	panel.sound_button.tapped.emit()
	assert_eq(panel.sound_button.text, "Sound effects: Off")
	assert_false(made.audio.is_enabled())
	assert_false(made.settings.sound_on)
	assert_false(made.settings.music_on, "music setting kept as it was")
	panel.request_close()
	made.open_settings()
	var again: SettingsPanel = made.top_modal() as SettingsPanel
	assert_eq(again.sound_button.text, "Sound effects: Off", "Settings shows the current states")
	assert_eq(again.music_button.text, "Music: Off")


func test_settings_rows_and_the_hud_sound_button_stay_in_step() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made)
	screen.pause()
	_press(made.top_modal(), "Settings")
	made.open_settings()
	var panel: SettingsPanel = made.top_modal() as SettingsPanel
	# The Music row is not the HUD button's business.
	panel.music_button.tapped.emit()
	assert_true(screen.hud.sound_button.icon == IconTex.make(&"speaker", 72), "music off leaves the speaker plain")
	assert_false(screen.hud.sound_button.disabled)
	panel.music_button.tapped.emit()
	# The Sound effects row crosses the speaker out.
	panel.sound_button.tapped.emit()
	assert_true(screen.hud.sound_button.icon == IconTex.make(&"speaker_off", 72), "sound off, so crossed out")
	assert_false(screen.hud.sound_button.disabled, "and still tappable")
	panel.sound_button.tapped.emit()
	assert_true(screen.hud.sound_button.icon == IconTex.make(&"speaker", 72), "back to a plain speaker")
	# The other way: the HUD button shows in Settings the next time it opens.
	panel.request_close()
	screen.hud.sound_button.tapped.emit()
	made.open_settings()
	var again: SettingsPanel = made.top_modal() as SettingsPanel
	assert_eq(again.sound_button.text, "Sound effects: Off")
	assert_eq(again.music_button.text, "Music: On", "the Music row is as it was")
