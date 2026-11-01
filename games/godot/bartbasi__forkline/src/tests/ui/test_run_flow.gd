# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The App flow for runs and the daily (docs/ARCHITECTURE.md 3.6 steps 2, 3 and 5; RULES 14, 15, 16)
## on the real run data: the 12 star unlock, a run and a daily starting from their cards,
## saving, resuming paused at 1x, ending and recording the counters and the daily record, the
## Continue card with three saved games, starting over, a bad phone date, and the HUD numbers.
## No running scene tree: the layout itself is checked in real_tree_checks.gd.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "runflow"
const DAY_1: Dictionary = {"year": 2026, "month": 10, "day": 24}
const DAY_2: Dictionary = {"year": 2026, "month": 10, "day": 25}
const DAY_4: Dictionary = {"year": 2026, "month": 10, "day": 27}
const OLD_YEAR: Dictionary = {"year": 2025, "month": 12, "day": 31}

var apps: Array[App] = []


func before_each() -> void:
	apps.clear()
	Fx.wipe(TAG)


func after_each() -> void:
	for made: App in apps:
		made.free()
	Fx.wipe(TAG)


func _app(fresh: bool = true, day: Dictionary = DAY_1) -> App:
	var made: App = Fx.run_app(TAG, fresh, day)
	apps.append(made)
	return made


func _drop(made: App) -> void:
	apps.erase(made)
	made.free()


func _store() -> SaveStore:
	return SaveStore.new(Fx.dir(TAG))


func _saved_on_disk() -> Array[SavedGame]:
	return _store().load_games(Fx.BattleFixtures.game())


## The mode screen's Roguelite card, then Start (Relaxed first when asked).
func _start_run(made: App, relaxed: bool = false) -> BattleScreen:
	made.open_mode()
	made.roguelite_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_not_null(card, "Roguelite opens the run card")
	if relaxed:
		card.relaxed_button.tapped.emit()
	card.start_button.tapped.emit()
	assert_true(made.current_screen() is BattleScreen, "Start begins the run")
	return made.battle_screen()


func _start_daily(made: App) -> BattleScreen:
	made.open_mode()
	made.daily_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_not_null(card, "Daily opens the daily card")
	card.start_button.tapped.emit()
	assert_true(made.current_screen() is BattleScreen, "Start begins the daily")
	return made.battle_screen()


## Calls the next wave from the HUD and plays it out with plenty of lives.
func _play_wave(screen: BattleScreen) -> void:
	screen.hud.call_button.tapped.emit()
	screen.battle.lives = 500
	var guard: int = 0
	while screen.battle.phase == Battle.Phase.WAVE and guard < 40000:
		screen.battle.step()
		guard += 1
	screen.frame(0.0)


## The first offered card, taken.
func _pick_first(screen: BattleScreen) -> void:
	assert_true(screen.draft_is_open(), "a card is owed")
	screen.draft_panel.select(screen.draft_panel.offered()[0])
	screen.draft_panel.take()


## One life, one wave: the first creature that gets through loses the run.
func _lose(screen: BattleScreen) -> void:
	screen.battle.lives = 1
	screen.hud.call_button.tapped.emit()
	var guard: int = 0
	while screen.battle.phase != Battle.Phase.LOST and guard < 20000:
		screen.frame(0.05)
		guard += 1
	assert_eq(screen.battle.phase, Battle.Phase.LOST, "the run is lost")


## Wave 18 has started and nothing is running: the next tick is a win.
func _win(screen: BattleScreen) -> void:
	var b: Battle = screen.battle
	b.waves_started = b.wave_count()
	b.running.clear()
	b.phase = Battle.Phase.WAVE
	screen.frame(0.05)
	assert_eq(b.phase, Battle.Phase.WON, "the run is won")


func _text_of(root: Node) -> String:
	var words: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		words.append((node as Label).text)
	return " ".join(words)


# The unlock.

func test_runs_stay_closed_until_twelve_stars() -> void:
	var made: App = Fx.app(TAG)
	apps.append(made)
	assert_false(made.runs_open)
	made.open_mode()
	var mode: ModeScreen = made.current_screen() as ModeScreen
	assert_true(mode.roguelite_button.disabled)
	assert_true(mode.daily_button.disabled)
	assert_true(_text_of(mode.roguelite_button).contains("Needs 12 stars, you have 0"), "the lock says what it needs")
	made.roguelite_requested.emit()
	made.daily_requested.emit()
	assert_true(made.current_screen() is ModeScreen, "a tap on a locked card opens nothing")
	made.start_run()
	made.start_daily()
	assert_null(made.battle_screen(), "and nothing can be started")
	for id: StringName in [&"r1_l1", &"r1_l2", &"r1_l3"]:
		made.progress.record_level(id, 7)
	made.progress.record_level(&"r1_l4", 3)
	made.save_progress()
	assert_eq(made.stars, 11)
	assert_false(made.runs_open, "11 stars is not enough")
	made.progress.record_level(&"r1_l4", 4)
	made.save_progress()
	assert_eq(made.stars, 12)
	assert_true(made.runs_open, "12 stars open both")
	made.handle_back()
	made.open_mode()
	mode = made.current_screen() as ModeScreen
	assert_false(mode.roguelite_button.disabled)
	assert_false(mode.daily_button.disabled)


# A run.

func test_a_run_starts_at_1x_with_a_fresh_seed_and_the_unlocked_pool() -> void:
	var made: App = _app()
	made.progress.raise(&"best_run_wave", 6)
	var screen: BattleScreen = _start_run(made)
	var run: RunSession = screen.run
	assert_not_null(run)
	assert_eq(run.run_seed, 1234, "the seed comes from the App's draw")
	assert_false(run.daily)
	assert_false(run.battle.relaxed, "Normal is the default")
	assert_eq(screen.clock.speed, 1, "every run starts at 1x")
	assert_eq(run.pool, made.game.run.pool(made.progress.unlock_counters()), "the pool is what the progress unlocked")
	assert_true(run.pool.has(&"twin_pebbles"), "reaching wave 6 unlocked Twin Pebbles")
	assert_false(run.pool.has(&"spice_rack"), "24 stars have not been earned")
	assert_eq(run.battle.lives, 20)
	assert_eq(run.battle.gold, 300)
	assert_false(screen.stars_in_play, "a run has no stars")
	assert_eq(made.active_game().mode, SavedGame.RUN)
	var saved: Array[SavedGame] = _saved_on_disk()
	assert_eq(saved.size(), 1, "a new run is saved at once")
	assert_eq(saved[0].mode, SavedGame.RUN)
	assert_eq(saved[0].run.run_seed, 1234)
	assert_eq(saved[0].run.pool, run.pool)


func test_the_random_seed_is_drawn_when_nothing_stands_in() -> void:
	var made: App = _app()
	made.seed_source = Callable()
	var first: BattleScreen = _start_run(made)
	assert_true(first.run.run_seed >= 0 and first.run.run_seed <= RunSeeds.SEED_MAX)
	assert_ne(first.run.run_seed, 1234, "no stand-in, so a real draw")


func test_a_relaxed_run_has_more_lives_and_gold() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made, true)
	assert_true(screen.run.battle.relaxed)
	assert_eq(screen.run.battle.lives, 40)
	assert_eq(screen.run.battle.gold, 450)
	assert_true(made.saved_game(SavedGame.RUN).battle.relaxed)


func test_a_run_resumes_paused_at_1x_byte_identical() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	_play_wave(screen)
	_pick_first(screen)
	screen.clock.speed = 3
	made.leave_app()
	var battle_before: String = JSON.stringify(screen.battle.to_data())
	var run_before: String = JSON.stringify(screen.run.to_data())
	_drop(made)
	var again: App = _app(false)
	assert_eq(again.saved_games.size(), 1)
	again.open_mode()
	var mode: ModeScreen = again.current_screen() as ModeScreen
	assert_not_null(mode.continue_button)
	mode.continue_button.tapped.emit()
	var resumed: BattleScreen = again.battle_screen()
	assert_not_null(resumed, "Continue resumes the run")
	assert_eq(JSON.stringify(resumed.battle.to_data()), battle_before, "the exact moment")
	assert_eq(JSON.stringify(resumed.run.to_data()), run_before, "the same run")
	assert_true(resumed.is_paused(), "resumed paused")
	assert_true(again.top_modal() is PausePanel, "on the Pause menu")
	assert_eq(resumed.clock.speed, 1, "and at 1x")
	assert_eq(resumed.run.picks.size(), 1)
	assert_false(resumed.stars_in_play)


func test_a_run_with_a_card_owed_resumes_with_the_draft_open() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	_play_wave(screen)
	var offers: Array[StringName] = screen.draft_panel.offered()
	assert_eq(offers.size(), 3)
	made.leave_app()
	_drop(made)
	var again: App = _app(false)
	again.open_mode()
	(again.current_screen() as ModeScreen).continue_button.tapped.emit()
	var resumed: BattleScreen = again.battle_screen()
	assert_true(resumed.draft_is_open(), "the card still owed is on the table")
	assert_eq(resumed.draft_panel.offered(), offers, "the same offers")
	assert_true(resumed.is_paused())


func test_the_run_card_offers_resume_before_starting_over() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	_play_wave(screen)
	screen.pause()
	screen.left.emit()
	made.open_mode()
	made.roguelite_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_not_null(card.resume_button)
	assert_eq(card.saved_label.text, "Your saved run is on wave 2 of 18.")
	assert_eq(card.start_button.text, "Start over")
	card.resume_button.tapped.emit()
	assert_true(made.current_screen() is BattleScreen)
	assert_true(made.battle_screen().is_paused())
	assert_eq(made.battle_screen().run.picks.size(), 0, "the card still owed")


# The daily.

func test_the_daily_is_the_phones_date_always_normal_with_every_card() -> void:
	var made: App = _app()
	made.open_mode()
	made.daily_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_eq(card.day_label.text, "Today: 2026-10-24")
	assert_null(card.relaxed_button, "no choice of difficulty")
	card.start_button.tapped.emit()
	var run: RunSession = made.battle_screen().run
	assert_true(run.daily)
	assert_eq(run.day, "2026-10-24")
	assert_eq(run.run_seed, 20261024, "the seed is the date")
	assert_false(run.battle.relaxed)
	assert_eq(run.pool, made.game.run.card_ids(), "every card, unlocked or not")
	assert_eq(made.battle_screen().clock.speed, 1)
	assert_eq(made.active_game().mode, SavedGame.DAILY)
	assert_eq(_saved_on_disk()[0].mode, SavedGame.DAILY)


func test_the_same_day_gives_the_same_daily() -> void:
	var made: App = _app()
	var first: BattleScreen = _start_daily(made)
	var map_a: String = JSON.stringify(first.battle.level.to_data())
	var pool_a: Array[StringName] = first.run.pool
	first.pause()
	first.left.emit()
	made.open_mode()
	made.daily_requested.emit()
	(made.current_screen() as RunCard).start_button.tapped.emit()
	_press(made.top_modal(), "Start new daily")
	var second: BattleScreen = made.battle_screen()
	assert_eq(JSON.stringify(second.battle.level.to_data()), map_a, "the same map")
	assert_eq(second.run.pool, pool_a)
	assert_eq(second.battle.tick, 0, "but a fresh try")


func test_a_daily_with_a_bad_phone_date_cannot_start_but_a_saved_one_resumes() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_daily(made)
	_play_wave(screen)
	screen.pause()
	screen.left.emit()
	_drop(made)
	var odd: App = _app(false, OLD_YEAR)
	assert_eq(odd.today(), "", "a date before 2026 is no day")
	odd.open_mode()
	var mode: ModeScreen = odd.current_screen() as ModeScreen
	assert_true(_text_of(mode.daily_button).contains("Check the phone's date."))
	odd.daily_requested.emit()
	var card: RunCard = odd.current_screen() as RunCard
	assert_eq(card.notice_label.text, "Check the phone's date.")
	assert_null(card.start_button, "no new daily")
	assert_not_null(card.resume_button, "but the saved one resumes")
	card.resume_button.tapped.emit()
	assert_true(odd.battle_screen().run.daily)
	assert_eq(odd.battle_screen().run.day, "2026-10-24")
	odd.start_daily()
	assert_eq(odd.battle_screen().run.day, "2026-10-24", "nothing new starts")


func test_a_daily_started_before_midnight_belongs_to_its_own_day() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_daily(made)
	screen.pause()
	screen.left.emit()
	_drop(made)
	var next: App = _app(false, DAY_2)
	next.open_mode()
	(next.current_screen() as ModeScreen).continue_button.tapped.emit()
	var resumed: BattleScreen = next.battle_screen()
	assert_eq(resumed.run.day, "2026-10-24")
	(next.top_modal() as PausePanel).request_close()
	_lose(resumed)
	assert_eq(next.daily_record.day, "2026-10-24", "the result goes to the day it started")
	assert_eq(next.daily_record.streak_day, "2026-10-24")


# Ending.

func test_a_lost_run_records_its_counters_and_shows_its_end_panel() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	_lose(screen)
	assert_eq(made.progress.counters[&"best_run_wave"], 1, "wave 1 was reached")
	assert_eq(made.progress.counters[&"runs_won"], 0)
	assert_eq(made.progress.counters[&"dailies_finished"], 0, "a normal run is not a daily")
	assert_eq(_store().load_progress().counters[&"best_run_wave"], 1, "and saved")
	assert_eq(_saved_on_disk().size(), 0, "a finished run is not kept")
	assert_eq(made.saved_games.size(), 0)
	var panel: RunEndPanel = made.top_modal() as RunEndPanel
	assert_not_null(panel, "the run end panel shows")
	assert_false(panel.won)
	assert_eq(panel.title_label.text, "Run lost")
	assert_eq(panel.summary_label.text, "Waves cleared: 0 of 18")
	assert_eq(panel.lives_label.text, "Lives left: 0")
	assert_not_null(panel.relaxed_label, "a Normal loss points to Relaxed")
	assert_null(panel.best_label, "a run has no daily best")
	assert_eq(made.daily_record.streak, 0, "and no streak")


func test_try_again_starts_another_run_and_menu_goes_to_the_mode_screen() -> void:
	var made: App = _app()
	_lose(_start_run(made))
	(made.top_modal() as RunEndPanel).retry_button.tapped.emit()
	assert_true(made.current_screen() is BattleScreen)
	assert_eq(made.battle_screen().battle.tick, 0, "a new run")
	assert_eq(made.battle_screen().run.picks.size(), 0)
	assert_eq(made.modal_count(), 0)
	assert_eq(made.screen_count(), 4, "front door, mode screen, run card, battle")
	_lose(made.battle_screen())
	(made.top_modal() as RunEndPanel).menu_button.tapped.emit()
	assert_true(made.current_screen() is ModeScreen, "Menu lands on the mode screen")
	assert_eq(made.screen_count(), 2)
	assert_null((made.current_screen() as ModeScreen).continue_button, "nothing is saved")


func test_a_relaxed_loss_does_not_point_to_relaxed() -> void:
	var made: App = _app()
	_lose(_start_run(made, true))
	var panel: RunEndPanel = made.top_modal() as RunEndPanel
	assert_null(panel.relaxed_label)
	assert_true(panel.relaxed)
	(panel as RunEndPanel).retry_button.tapped.emit()
	assert_true(made.battle_screen().run.battle.relaxed, "Try again keeps the difficulty")


func test_a_won_normal_run_counts_wins_and_risky_wins() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	for id: StringName in [&"crowded_night", &"thick_hides", &"hurry_night"]:
		screen.run.picks.append(id)
	_win(screen)
	var counters: Dictionary = made.progress.counters
	assert_eq(counters[&"runs_won"], 1)
	assert_eq(counters[&"runs_won_normal"], 1)
	assert_eq(counters[&"risky_wins"], 1, "three risk cards taken")
	assert_eq(counters[&"best_run_wave"], 18)
	var panel: RunEndPanel = made.top_modal() as RunEndPanel
	assert_true(panel.won)
	assert_eq(panel.title_label.text, "Run won")
	assert_eq(panel.lives_label.text, "Lives left: 20")
	assert_eq(_saved_on_disk().size(), 0)
	var saved: Progress = _store().load_progress()
	assert_eq(saved.counters[&"runs_won"], 1)
	assert_eq(saved.counters[&"risky_wins"], 1)


func test_a_won_relaxed_run_is_not_a_normal_win_and_two_risks_are_not_risky() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made, true)
	for id: StringName in [&"crowded_night", &"thick_hides"]:
		screen.run.picks.append(id)
	_win(screen)
	assert_eq(made.progress.counters[&"runs_won"], 1)
	assert_eq(made.progress.counters[&"runs_won_normal"], 0, "Relaxed does not count as Normal")
	assert_eq(made.progress.counters[&"risky_wins"], 0)


func test_a_win_unlocks_the_cards_it_earns_for_the_next_run() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	assert_false(screen.run.pool.has(&"volley"))
	_win(screen)
	(made.top_modal() as RunEndPanel).retry_button.tapped.emit()
	var next: RunSession = made.battle_screen().run
	assert_true(next.pool.has(&"volley"), "a win unlocked Volley")
	assert_true(next.pool.has(&"long_fuse"), "a Normal win unlocked Long Fuse")
	assert_true(next.pool.has(&"twin_pebbles"), "wave 18 was reached, so Twin Pebbles and Heavy Pumpkins")
	assert_true(next.pool.has(&"heavy_pumpkins"))


func test_abandoning_a_run_counts_as_lost_at_its_wave_and_shows_no_panel() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	_play_wave(screen)
	_pick_first(screen)
	screen.hud.call_button.tapped.emit()
	assert_eq(screen.battle.waves_started, 2)
	screen.pause()
	screen._pause_panel.abandon_confirmed.emit()
	assert_eq(made.screen_count(), 1, "back at the front door")
	assert_eq(made.modal_count(), 0, "no end panel for an abandoned run")
	assert_eq(made.progress.counters[&"best_run_wave"], 2, "the wave it reached counts")
	assert_eq(made.progress.counters[&"runs_won"], 0, "and it is a loss")
	assert_eq(_saved_on_disk().size(), 0)
	assert_eq(made.saved_games.size(), 0)
	assert_null(made.active_game())


func test_a_lost_daily_records_the_best_the_streak_and_the_count() -> void:
	var made: App = _app()
	_lose(_start_daily(made))
	assert_eq(made.progress.counters[&"dailies_finished"], 1)
	assert_eq(made.progress.counters[&"best_run_wave"], 1)
	assert_eq(made.daily_record.day, "2026-10-24")
	assert_eq(made.daily_record.best, {"won": false, "waves": 0, "lives": 0})
	assert_eq(made.daily_record.streak, 1)
	assert_eq(made.daily_record.streak_day, "2026-10-24")
	var disk: DailyRecord = _store().load_daily()
	assert_eq(disk.best, made.daily_record.best, "saved on the phone")
	assert_eq(disk.streak, 1)
	var panel: RunEndPanel = made.top_modal() as RunEndPanel
	assert_eq(panel.title_label.text, "Daily lost")
	assert_eq(panel.best_label.text, "Best today: Lost with 0 of 18 waves cleared.")
	assert_eq(panel.streak_label.text, "Streak: 1 day")
	assert_null(panel.relaxed_label, "the daily is always Normal")
	assert_eq(_saved_on_disk().size(), 0)


func test_a_daily_finished_after_midnight_says_best_that_day() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_daily(made)
	assert_eq(screen.run.day, "2026-10-24")
	made.date_source = func() -> Dictionary: return DAY_2
	_lose(screen)
	var panel: RunEndPanel = made.top_modal() as RunEndPanel
	assert_eq(panel.best_label.text, "Best that day: Lost with 0 of 18 waves cleared.")


func test_the_daily_keeps_the_better_try_of_the_day() -> void:
	var made: App = _app()
	_lose(_start_daily(made))
	(made.top_modal() as RunEndPanel).retry_button.tapped.emit()
	var second: BattleScreen = made.battle_screen()
	assert_eq(second.run.day, "2026-10-24", "Try again plays today's daily again")
	_win(second)
	assert_eq(made.daily_record.best, {"won": true, "waves": 0, "lives": 20}, "a win beats a loss")
	assert_eq(made.daily_record.streak, 1, "the same day does not grow the streak")
	assert_eq(made.progress.counters[&"dailies_finished"], 2)
	var panel: RunEndPanel = made.top_modal() as RunEndPanel
	assert_eq(panel.title_label.text, "Daily won")
	assert_eq(panel.best_label.text, "Best today: Won with 20 lives left.")
	(panel as RunEndPanel).retry_button.tapped.emit()
	_lose(made.battle_screen())
	assert_true(made.daily_record.best["won"], "a later loss keeps the win")
	assert_eq(made.progress.counters[&"runs_won"], 1)
	assert_eq(made.progress.counters[&"dailies_finished"], 3)


func test_the_streak_grows_by_day_and_the_button_shows_it() -> void:
	var made: App = _app()
	_lose(_start_daily(made))
	_drop(made)
	var next: App = _app(false, DAY_2)
	next.open_mode()
	var line: String = _text_of((next.current_screen() as ModeScreen).daily_button)
	assert_true(line.contains("Not played today. Streak: 1 day."), line)
	_lose(_start_daily(next))
	assert_eq(next.daily_record.streak, 2, "the day after adds one")
	assert_eq(next.daily_record.day, "2026-10-25", "and a later day replaces the best")
	assert_eq((next.top_modal() as RunEndPanel).streak_label.text, "Streak: 2 days")
	(next.top_modal() as RunEndPanel).menu_button.tapped.emit()
	line = _text_of((next.current_screen() as ModeScreen).daily_button)
	assert_true(line.contains("Best today: Lost with 0 of 18 waves cleared. Streak: 2 days."), line)
	_drop(next)
	var gap: App = _app(false, DAY_4)
	gap.open_mode()
	line = _text_of((gap.current_screen() as ModeScreen).daily_button)
	assert_false(line.contains("Streak"), "after a gap the streak shows as nothing: %s" % line)
	assert_true(line.contains("One run a day"), "the plain line is back: %s" % line)


func test_abandoning_a_daily_still_counts_for_the_record() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_daily(made)
	screen.hud.call_button.tapped.emit()
	screen.pause()
	screen._pause_panel.abandon_confirmed.emit()
	assert_eq(made.modal_count(), 0)
	assert_eq(made.progress.counters[&"dailies_finished"], 1)
	assert_eq(made.daily_record.streak, 1, "an abandoned daily counts for the streak")
	assert_eq(made.daily_record.best["won"], false)
	assert_eq(made.progress.counters[&"best_run_wave"], 1)
	assert_eq(_store().load_daily().streak, 1)
	assert_eq(_saved_on_disk().size(), 0)


# Starting over.

func test_starting_a_run_over_asks_first_and_cancel_keeps_it() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	screen.hud.call_button.tapped.emit()
	screen.pause()
	screen.left.emit()
	var old: RunSession = made.saved_game(SavedGame.RUN).run
	made.open_mode()
	made.roguelite_requested.emit()
	(made.current_screen() as RunCard).start_button.tapped.emit()
	var dialog: ConfirmDialog = made.top_modal() as ConfirmDialog
	assert_not_null(dialog, "a saved run asks first")
	assert_true(made.current_screen() is RunCard, "nothing started yet")
	dialog.request_close()
	assert_eq(made.modal_count(), 0)
	assert_eq(made.saved_game(SavedGame.RUN).run, old, "cancel keeps the saved run")
	assert_eq(made.progress.counters[&"best_run_wave"], 0, "and records nothing")


func test_starting_over_counts_the_old_run_as_lost() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_run(made)
	screen.hud.call_button.tapped.emit()
	screen.pause()
	screen.left.emit()
	made.open_mode()
	made.roguelite_requested.emit()
	(made.current_screen() as RunCard).start_button.tapped.emit()
	_press(made.top_modal(), "Start new run")
	assert_true(made.current_screen() is BattleScreen)
	assert_eq(made.battle_screen().battle.tick, 0, "the new run starts fresh")
	assert_eq(made.progress.counters[&"best_run_wave"], 1, "the old run counted at its wave")
	assert_eq(made.progress.counters[&"runs_won"], 0)
	assert_eq(made.saved_games.size(), 1, "one saved run")
	assert_eq(made.saved_game(SavedGame.RUN).run, made.battle_screen().run)


func test_starting_a_daily_over_counts_it_for_the_record() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start_daily(made)
	screen.pause()
	screen.left.emit()
	made.open_mode()
	made.daily_requested.emit()
	(made.current_screen() as RunCard).start_button.tapped.emit()
	_press(made.top_modal(), "Start new daily")
	assert_eq(made.progress.counters[&"dailies_finished"], 1)
	assert_eq(made.daily_record.streak, 1)
	assert_eq(made.battle_screen().battle.tick, 0)


func _press(root: Node, text: String) -> void:
	for node: Node in root.find_children("*", "TapButton", true, false):
		if (node as TapButton).text == text:
			(node as TapButton).tapped.emit()
			return
	fail("no button '%s'" % text)


# Three saved games and the Continue card.

func test_continue_resumes_the_most_recent_of_the_three_saved_games() -> void:
	var made: App = _app()
	Fx.mark_all_seen(made)
	made.start_level(&"r1_l1", false)
	made.battle_screen().pause()
	made.battle_screen().left.emit()
	_start_run(made)
	_play_wave(made.battle_screen())
	made.battle_screen().pause()
	made.battle_screen().left.emit()
	_start_daily(made)
	made.battle_screen().pause()
	made.battle_screen().left.emit()
	assert_eq(made.saved_games.size(), 3, "one game per mode")
	assert_eq(_saved_on_disk().size(), 3)
	made.open_mode()
	var mode: ModeScreen = made.current_screen() as ModeScreen
	assert_true(_text_of(mode.continue_button).contains("Daily 2026-10-24. Ready to start."), _text_of(mode.continue_button))
	mode.continue_button.tapped.emit()
	assert_true(made.battle_screen().run.daily, "the daily was saved last")
	made.battle_screen().left.emit()
	# The run's own way in resumes it, and that save is now the most recent.
	made.open_mode()
	made.roguelite_requested.emit()
	(made.current_screen() as RunCard).resume_button.tapped.emit()
	assert_false(made.battle_screen().run.daily)
	made.battle_screen().left.emit()
	made.open_mode()
	mode = made.current_screen() as ModeScreen
	assert_true(_text_of(mode.continue_button).contains("Roguelite run. Wave 2 of 18."), _text_of(mode.continue_button))
	mode.continue_button.tapped.emit()
	assert_eq(made.battle_screen().run.run_seed, 1234)
	assert_false(made.battle_screen().run.daily)
	made.battle_screen().left.emit()
	# Then the level, from its card.
	made.open_mode()
	made.campaign_requested.emit()
	(made.current_screen() as LevelSelect).level_chosen.emit(&"r1_l1")
	(made.current_screen() as LevelCard).resume_requested.emit()
	assert_eq(made.battle_screen().battle.level.id, &"r1_l1")
	made.battle_screen().left.emit()
	made.open_mode()
	mode = made.current_screen() as ModeScreen
	assert_true(_text_of(mode.continue_button).contains("Level 1-1"), _text_of(mode.continue_button))
	mode.continue_button.tapped.emit()
	assert_eq(made.battle_screen().battle.level.id, &"r1_l1", "now the level is the most recent")
	assert_null(made.battle_screen().run)
	assert_true(made.battle_screen().stars_in_play)


func test_the_three_saved_games_come_back_after_a_restart() -> void:
	var made: App = _app()
	Fx.mark_all_seen(made)
	made.start_level(&"r1_l1", false)
	made.battle_screen().left.emit()
	_start_run(made)
	made.battle_screen().left.emit()
	_start_daily(made)
	made.battle_screen().left.emit()
	_drop(made)
	var again: App = _app(false)
	assert_eq(again.saved_games.size(), 3)
	assert_eq(again.saved_games[0].mode, SavedGame.DAILY, "the most recent first")
	assert_eq(again.saved_games[1].mode, SavedGame.RUN)
	assert_eq(again.saved_games[2].mode, SavedGame.LEVEL)


func test_a_level_game_does_not_end_a_run_and_a_run_does_not_end_a_level() -> void:
	var made: App = _app()
	made.start_level(&"r1_l1", false)
	made.battle_screen().left.emit()
	_start_run(made)
	made.battle_screen().left.emit()
	assert_eq(made.saved_games.size(), 2, "a run asked nothing about the saved level")
	made.start_level(&"r1_l1", false)
	assert_not_null(made.saved_game(SavedGame.RUN), "and a level did not end the run")


func test_the_continue_text_names_each_kind_of_game() -> void:
	var made: App = _app()
	_start_run(made, true)
	made.battle_screen().left.emit()
	made.open_mode()
	var text: String = _text_of((made.current_screen() as ModeScreen).continue_button)
	assert_true(text.contains("Roguelite run. Ready to start. Relaxed."), text)


# A run that cannot be made.

func test_a_run_that_cannot_be_made_shows_the_damaged_message() -> void:
	var made: App = _app()
	made.seed_source = func() -> int: return -1
	made.open_mode()
	made.roguelite_requested.emit()
	(made.current_screen() as RunCard).start_button.tapped.emit()
	assert_true(made.damaged)
	assert_true(made.current_screen() is DamagedScreen)
	assert_null(made.battle_screen())
	assert_eq(_saved_on_disk().size(), 0)


# The Daily button.

func test_the_daily_button_shows_its_plain_line_until_there_is_something_to_say() -> void:
	var made: App = _app()
	made.open_mode()
	var line: String = _text_of((made.current_screen() as ModeScreen).daily_button)
	assert_true(line.contains("One run a day. The same for everyone."), line)
	assert_eq(ModeScreen.daily_detail({}, 0), "")
	assert_eq(ModeScreen.daily_detail({}, 3), "Not played today. Streak: 3 days.")
	assert_eq(ModeScreen.daily_detail({"won": true, "waves": 18, "lives": 14}, 1), "Best today: Won with 14 lives left. Streak: 1 day.")
	assert_eq(ModeScreen.daily_detail({"won": false, "waves": 9, "lives": 0}, 0), "Best today: Lost with 9 of 18 waves cleared.")


func test_another_days_best_is_not_shown() -> void:
	var made: App = _app()
	made.daily_record.record_finish("2026-10-23", {"won": true, "waves": 18, "lives": 9})
	assert_eq(made.daily_detail(), "Not played today. Streak: 1 day.", "yesterday's best is not today's")
	made.daily_record.record_finish("2026-10-24", {"won": false, "waves": 5, "lives": 0})
	assert_eq(made.daily_detail(), "Best today: Lost with 5 of 18 waves cleared. Streak: 2 days.")


# The HUD numbers.

func test_big_hud_numbers_are_shortened_to_five_characters() -> void:
	assert_eq(BattleText.short_number(0), "0")
	assert_eq(BattleText.short_number(-5), "0", "below zero is zero")
	assert_eq(BattleText.short_number(20), "20")
	assert_eq(BattleText.short_number(999), "999")
	assert_eq(BattleText.short_number(99999), "99999", "five digits are shown whole")
	assert_eq(BattleText.short_number(100000), "100K")
	assert_eq(BattleText.short_number(999999), "999K")
	assert_eq(BattleText.short_number(1000000), "1M")
	assert_eq(BattleText.short_number(999999999), "999M")
	assert_eq(BattleText.short_number(1000000000), "1B")
	for value: int in [0, 7, 12345, 99999, 123456, 5000000, 999999999, 1000000000, 4000000000]:
		assert_true(BattleText.short_number(value).length() <= 5, "%d fits five characters" % value)


func test_the_hud_shows_shortened_lives_and_gold() -> void:
	var b: Battle = Fx.BattleFixtures.battle()
	b.lives = 1000000
	b.gold = 1000000000
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, Progress.new())
	assert_eq(screen.hud.lives_label.text, "1M")
	assert_eq(screen.hud.gold_label.text, "1B")
	b.lives = 20
	b.gold = 300
	screen.hud.refresh()
	assert_eq(screen.hud.lives_label.text, "20")
	assert_eq(screen.hud.gold_label.text, "300")
	screen.free()
