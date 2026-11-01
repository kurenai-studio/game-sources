# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The run screens on a RunSession (docs/ARCHITECTURE.md 3.4, 3.6; RULES 14, 15), built on the
## fixture runs of tests/run/fixtures: the card draft that opens by itself and blocks the next
## wave, the back button that opens Pause instead of skipping it, a pick that adds its card, the
## risk row and chip in the wave preview, RunCard and the run end panel. No running scene tree:
## the layout itself is checked in real_tree_checks.gd.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const RunFx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")
const RunPlayer: GDScript = preload("res://tests/run/fixtures/run_player.gd")

var screens: Array[BattleScreen] = []
var spare: Array[Node] = []


func before_each() -> void:
	screens.clear()


func after_each() -> void:
	for screen: BattleScreen in screens:
		screen.free()
	for node: Node in spare:
		node.free()
	spare.clear()


func _keep(node: Node) -> Node:
	spare.append(node)
	return node


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


func _seen_all() -> Progress:
	var progress: Progress = Progress.new()
	var catalog: Catalog = RunFx.catalog()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


## A run on the fixture data with this pool of cards (ids), as a screen.
func _run_screen(pool: Array[StringName], run_seed: int = 7, progress: Progress = null) -> BattleScreen:
	var data: RunData = RunFx.run_data()
	var session: RunSession = RunSession.start(run_seed, "", false, pool, data, RunFx.catalog())
	assert_not_null(session, "the fixture run starts")
	var screen: BattleScreen = BattleScreen.new()
	screens.append(screen)
	screen.setup(session.battle, null, progress if progress != null else _seen_all())
	screen.set_run(session)
	screen.apply_layout(Fx.COVER, Fx.COVER_SAFE)
	return screen


## Plain pools: a tower card and an economy card; an economy card and a risk card.
func _tower_pool() -> Array[StringName]:
	return [&"tower_lullaby_bell", &"gold_purse"] as Array[StringName]


func _risk_pool() -> Array[StringName]:
	return [&"crowded_night", &"gold_purse"] as Array[StringName]


## Starts the next wave from the HUD button and plays it out with plenty of lives.
func _play_wave(screen: BattleScreen) -> void:
	screen.hud.call_button.tapped.emit()
	var b: Battle = screen.battle
	b.lives = 500
	var guard: int = 0
	while b.phase == Battle.Phase.WAVE and guard < 40000:
		b.step()
		guard += 1
	screen.frame(0.0)


# The screen around a run.

func test_a_run_has_no_stars_and_a_fresh_one_owes_no_card() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	assert_false(screen.stars_in_play, "runs have no stars")
	assert_false(screen.has_stars())
	assert_true(screen.star_entries().is_empty())
	for panel: BattlePanel in [screen.build_panel, screen.tower_panel, screen.gate_tray]:
		assert_false(panel.star_warnings, "no star warnings in a run")
	assert_false(screen.draft_is_open(), "no wave is cleared yet, so no card is owed")
	assert_eq(screen.hud.call_button.text, "Start wave 1")


func test_pause_in_a_run_has_no_star_lines() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	screen.pause()
	var pause: PausePanel = screen._pause_panel
	assert_not_null(pause)
	assert_true(pause.star_lines.is_empty())
	assert_null(pause.twist_name_label)


func test_the_run_ends_with_its_own_flags() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	var ended: Array[Dictionary] = []
	screen.ended.connect(func(result: Dictionary) -> void: ended.append(result))
	screen.pause()
	screen._pause_panel.abandon_confirmed.emit()
	assert_eq(ended.size(), 1)
	assert_true(ended[0]["abandoned"])
	assert_false(ended[0]["twist"])


# The draft.

func test_a_draft_opens_by_itself_after_a_cleared_wave() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	_play_wave(screen)
	assert_eq(screen.battle.phase, Battle.Phase.BUILD)
	assert_true(screen.draft_is_open(), "the draft opens in the build phase")
	assert_eq(screen.context_panel(), screen.draft_panel)
	assert_eq(screen.draft_panel.offered(), screen.run.offers(), "it shows the run's own offers, in order")
	assert_eq(screen.draft_panel.offered().size(), 2)
	var texts: PackedStringArray = _texts(screen.draft_panel)
	assert_true(texts.has("Wave 1 cleared. Pick a card."))
	for id: StringName in screen.draft_panel.offered():
		var card: Dictionary = RunFx.run_data().card(id)
		assert_true(texts.has(String(card["name"])), "%s shows its name" % id)
		assert_true(texts.has(String(card["text"])), "%s shows its text" % id)
	assert_true(texts.has("New tower"), "a tower card says what it is in words")
	assert_true(texts.has("Economy"))


func test_a_draft_blocks_the_next_wave_and_says_why() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	_play_wave(screen)
	var started: int = screen.battle.waves_started
	assert_eq(screen.hud.call_button.text, "Pick a card first", "the call button says a card is owed")
	assert_ne(screen.hud.call_button.icon, null, "and wears a lock")
	assert_eq(screen.hud.call_button.theme_type_variation, &"Button", "it is not honey while it cannot start")
	screen.hud.call_button.tapped.emit()
	assert_eq(screen.battle.waves_started, started, "the wave did not start")
	assert_eq(screen.battle.phase, Battle.Phase.BUILD)
	assert_eq(screen.hud.feedback_text(), "Pick a card first.")
	assert_true(screen.draft_is_open(), "and the draft stays")


func test_a_card_owed_during_a_wave_says_pick_it_after_the_wave() -> void:
	# Call waves early until one is cleared while another is still on the map.
	var data: RunData = RunFx.run_data()
	var pool: Array[StringName] = data.pool({})
	var found: bool = false
	for run_seed: int in range(1, 30):
		var session: RunSession = RunSession.start(run_seed, "", false, pool, data, RunFx.catalog())
		var player: RefCounted = RunPlayer.new(run_seed, 25, true)
		player.rich = true
		var screen: BattleScreen = BattleScreen.new()
		screens.append(screen)
		screen.setup(session.battle, null, _seen_all())
		screen.set_run(session)
		screen.apply_layout(Fx.COVER, Fx.COVER_SAFE)
		var guard: int = 0
		while player.advance(session) and guard < 60000:
			guard += 1
			if session.battle.phase == Battle.Phase.WAVE and session.drafts_owed() > 0:
				found = true
				break
		if found:
			screen.frame(0.0)
			assert_eq(screen.hud.call_button.text, "Card due next")
			var started: int = session.battle.waves_started
			screen.hud.call_button.tapped.emit()
			assert_eq(session.battle.waves_started, started, "no wave is called")
			assert_eq(screen.hud.feedback_text(), "Pick your card after this wave.")
			assert_false(screen.draft_is_open(), "a draft opens only in a build phase")
			break
	assert_true(found, "a fixture run owes a card during a wave")


func test_the_back_button_opens_pause_and_never_skips_the_draft() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	_play_wave(screen)
	assert_true(screen.draft_is_open())
	assert_false(screen.close_panel_for_back(), "back does not close the draft, so the App opens Pause")
	assert_true(screen.draft_is_open())
	screen.close_context()
	assert_true(screen.draft_is_open(), "nothing else closes it either")
	screen.pause()
	assert_true(screen.pause_menu_open(), "Pause opens on top of the draft")
	assert_true(screen.draft_is_open())
	screen._pause_panel.request_close()
	assert_false(screen.pause_menu_open())
	assert_true(screen.draft_is_open(), "and the draft is still there after Resume")


func test_the_map_does_nothing_while_the_draft_is_open() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	_play_wave(screen)
	var spot: Vector2i = screen.battle.level.spots[0]
	screen.tap_at(spot)
	assert_eq(screen.context_panel(), screen.draft_panel, "a spot does not open the build panel")
	screen.show_build(spot)
	assert_eq(screen.context_panel(), screen.draft_panel)
	assert_false(screen.build_panel.is_open())
	if not screen.battle.level.sockets.is_empty():
		var gates: int = screen.battle.gates.size()
		screen.tap_socket(screen.battle.level.sockets[0])
		assert_eq(screen.battle.gates.size(), gates, "no gate moves while a card is owed")
		screen.begin_drag(Vector2i(-1, -1), Vector2.ZERO)
		assert_false(screen.is_dragging())


func test_a_tap_on_a_card_chooses_it_and_take_adds_it() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	var saves: Array[int] = [0]
	screen.save_requested.connect(func() -> void: saves[0] += 1)
	_play_wave(screen)
	var panel: DraftPanel = screen.draft_panel
	assert_eq(panel.selected, &"", "nothing is chosen at first")
	assert_eq(panel.take_button.text, "Take a card")
	panel.take_button.tapped.emit()
	assert_eq(panel.feedback_text(), "Tap a card first.", "Take with no card says so")
	assert_true(screen.run.picks.is_empty())
	var saves_before: int = saves[0]
	panel.rows[&"tower_lullaby_bell"].tapped.emit()
	assert_eq(panel.selected, &"tower_lullaby_bell")
	assert_eq(panel.take_button.text, "Take Lullaby Bell")
	assert_eq(panel.take_button.theme_type_variation, &"PrimaryButton")
	assert_eq(panel.marks[&"tower_lullaby_bell"].modulate, Palette.HONEY, "the chosen card wears a check mark")
	assert_eq(panel.marks[&"gold_purse"].modulate.a, 0.0)
	panel.take_button.tapped.emit()
	assert_eq(screen.run.picks, [&"tower_lullaby_bell"] as Array[StringName], "the card is added")
	assert_false(screen.draft_is_open(), "the draft closes")
	assert_eq(saves[0], saves_before + 1, "a pick saves the game")
	var spot: Vector2i = screen.battle.level.spots[0]
	var towers: Array[StringName] = []
	for option: Dictionary in screen.battle.build_options(spot):
		towers.append(option["tower"])
	assert_true(towers.has(&"lullaby_bell"), "the new tower can be built now")
	screen.frame(0.0)
	assert_false(screen.draft_is_open(), "and no second draft is owed")
	assert_eq(screen.hud.call_button.text, "Start wave 2", "the next wave can start")
	assert_eq(screen.hud.call_button.theme_type_variation, &"PrimaryButton")


func test_a_new_tower_card_opens_its_first_sight_card() -> void:
	var progress: Progress = _seen_all()
	progress.seen.erase(&"lullaby_bell")
	var screen: BattleScreen = _run_screen(_tower_pool(), 7, progress)
	assert_false(screen.card_open(), "nothing but the Bell is new")
	_play_wave(screen)
	screen.draft_panel.select(&"tower_lullaby_bell")
	screen.draft_panel.take()
	assert_true(screen.card_open(), "the card of the new tower opens after the pick")
	var seen: bool = screen.progress.seen.has(&"lullaby_bell")
	assert_false(seen, "it counts as seen when the player closes it")
	screen._card.advance()
	assert_true(screen.progress.seen.has(&"lullaby_bell"))
	assert_false(screen.card_open())


func test_a_tower_already_seen_opens_no_card() -> void:
	var progress: Progress = _seen_all()
	var screen: BattleScreen = _run_screen(_tower_pool(), 7, progress)
	_play_wave(screen)
	screen.draft_panel.select(&"tower_lullaby_bell")
	screen.draft_panel.take()
	assert_false(screen.card_open())


func test_drafts_come_one_after_another_in_wave_order() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	_play_wave(screen)
	screen.draft_panel.select(&"gold_purse")
	screen.draft_panel.take()
	screen.frame(0.0)
	assert_false(screen.draft_is_open())
	_play_wave(screen)
	assert_true(screen.draft_is_open(), "the next cleared wave owes the next card")
	assert_true(_texts(screen.draft_panel).has("Wave 2 cleared. Pick a card."))
	assert_eq(screen.run.picks.size(), 1)
	screen.draft_panel.select(&"gold_purse")
	screen.draft_panel.take()
	assert_eq(screen.run.picks, [&"gold_purse", &"gold_purse"] as Array[StringName], "Gold Purse can be taken again")


func test_a_card_the_run_refuses_leaves_the_draft_open() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	_play_wave(screen)
	screen._on_draft_picked(&"tower_bakery")
	assert_true(screen.draft_is_open())
	assert_eq(screen.draft_panel.feedback_text(), "That card is not on offer.")
	assert_true(screen.run.picks.is_empty())


func test_the_draft_follows_the_layout_and_survives_a_fold() -> void:
	var screen: BattleScreen = _run_screen(_tower_pool())
	_play_wave(screen)
	var offers: Array[StringName] = screen.draft_panel.offered()
	var before: String = JSON.stringify(screen.battle.to_data()) + JSON.stringify(screen.run.to_data())
	assert_eq(screen.draft_panel.get_parent(), screen._sheet_scroll, "a sheet in portrait")
	screen.apply_layout(Fx.INNER, Fx.INNER_SAFE)
	assert_true(screen.landscape)
	assert_true(screen.draft_is_open(), "folding keeps the draft")
	assert_eq(screen.draft_panel.get_parent(), screen._side_box, "and moves it to the side column")
	assert_eq(screen.draft_panel.offered(), offers)
	screen.draft_panel.select(&"gold_purse")
	screen.apply_layout(Fx.COVER, Fx.COVER_SAFE)
	assert_eq(screen.draft_panel.get_parent(), screen._sheet_scroll)
	assert_eq(screen.draft_panel.selected, &"gold_purse", "the choice stays too")
	assert_eq(JSON.stringify(screen.battle.to_data()) + JSON.stringify(screen.run.to_data()), before, "nothing else changed")


func test_a_resumed_run_with_a_draft_owed_opens_it() -> void:
	var data: RunData = RunFx.run_data()
	var session: RunSession = RunSession.start(7, "", false, _tower_pool(), data, RunFx.catalog())
	var first: BattleScreen = BattleScreen.new()
	screens.append(first)
	first.setup(session.battle, null, _seen_all())
	first.set_run(session)
	_play_wave(first)
	var saved_battle: Dictionary = session.battle.to_data()
	var saved_run: Dictionary = session.to_data()
	var again_battle: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(saved_battle)), RunFx.catalog())
	var again: RunSession = RunSession.from_data(JSON.parse_string(JSON.stringify(saved_run)), again_battle, data)
	assert_not_null(again)
	var second: BattleScreen = BattleScreen.new()
	screens.append(second)
	second.setup(again.battle, null, _seen_all())
	second.set_run(again)
	assert_true(second.draft_is_open(), "a restored run with a card owed shows it at once")
	assert_eq(second.draft_panel.offered(), first.draft_panel.offered(), "the same offers")


# The risk row and chip.

func test_a_risk_card_shows_first_in_the_preview_as_a_row_and_a_chip() -> void:
	var screen: BattleScreen = _run_screen(_risk_pool())
	_play_wave(screen)
	assert_eq(screen.preview.risk_name, "", "no risk card is waiting yet")
	assert_null(screen.preview.risk_row)
	screen.draft_panel.select(&"crowded_night")
	screen.draft_panel.take()
	screen.frame(0.0)
	assert_eq(screen.run.risk_card(), &"crowded_night")
	assert_eq(screen.preview.risk_name, "crowded_night")
	assert_eq(screen.preview.risk_text, "A risk card.")
	# Open: a row at the top of the list.
	screen.preview.set_open(true)
	assert_not_null(screen.preview.risk_row, "the open preview has the risk row")
	assert_true(_texts(screen.preview.risk_row).has("Risk: crowded_night"))
	assert_true(_texts(screen.preview.risk_row).has("A risk card."))
	var column_kids: Array[Node] = screen.preview.column.get_children()
	assert_eq(column_kids.find(screen.preview.risk_row), 1, "right under the header, before the groups")
	# Folded: a chip at the start of the strip.
	screen.preview.set_open(false)
	assert_not_null(screen.preview.strip)
	assert_not_null(screen.preview.risk_chip)
	assert_eq(screen.preview.strip.chips()[0], screen.preview.risk_chip, "the chip comes first")
	assert_true(_texts(screen.preview.risk_chip).has("Risk"), "a word, not a color")


func test_the_preview_shows_the_wave_as_the_risk_will_change_it() -> void:
	var screen: BattleScreen = _run_screen(_risk_pool())
	var plain: Array[Dictionary] = screen.battle.wave_preview(screen.battle.waves_started)
	_play_wave(screen)
	var plain_next: Array[Dictionary] = screen.battle.wave_preview(screen.battle.waves_started)
	screen.draft_panel.select(&"crowded_night")
	screen.draft_panel.take()
	var risky: Array[Dictionary] = screen.battle.wave_preview(screen.battle.waves_started)
	assert_true(int(risky[0]["count"]) > int(plain_next[0]["count"]), "Crowded Night adds creatures to the preview")
	assert_false(plain.is_empty())


func test_starting_the_wave_takes_the_risk_row_away() -> void:
	var screen: BattleScreen = _run_screen(_risk_pool())
	_play_wave(screen)
	screen.draft_panel.select(&"crowded_night")
	screen.draft_panel.take()
	screen.frame(0.0)
	assert_eq(screen.preview.risk_name, "crowded_night")
	screen.hud.call_button.tapped.emit()
	screen.frame(0.0)
	assert_eq(screen.run.risk_card(), &"", "the wave took the card")
	assert_eq(screen.preview.risk_name, "", "so the row and the chip go")
	assert_null(screen.preview.risk_chip)


func test_no_risk_row_when_another_card_is_taken() -> void:
	var screen: BattleScreen = _run_screen(_risk_pool())
	_play_wave(screen)
	screen.draft_panel.select(&"gold_purse")
	screen.draft_panel.take()
	screen.frame(0.0)
	assert_eq(screen.preview.risk_name, "")


# RunCard.

func test_the_run_card_starts_on_normal_with_numbers_from_the_sim() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var data: RunData = RunFx.run_data()
	var card: RunCard = _keep(RunCard.new(game, data)) as RunCard
	assert_eq(card.title_label.text, "Roguelite")
	assert_false(card.relaxed, "Normal is chosen when the card opens")
	assert_true(card.difficulty_label.text.begins_with("Normal: 20 lives and 300 gold"), card.difficulty_label.text)
	var seen: Array[bool] = []
	card.start_requested.connect(func(relaxed: bool) -> void: seen.append(relaxed))
	card.start_button.tapped.emit()
	card.relaxed_button.tapped.emit()
	assert_true(card.relaxed)
	assert_true(card.difficulty_label.text.begins_with("Relaxed: 40 lives and 450 gold"), card.difficulty_label.text)
	card.start_button.tapped.emit()
	card.normal_button.tapped.emit()
	card.start_button.tapped.emit()
	assert_eq(seen, [false, true, false] as Array[bool])
	var next_time: RunCard = _keep(RunCard.new(game, data)) as RunCard
	assert_false(next_time.relaxed, "a new card starts on Normal again")
	assert_eq(card.start_button.theme_type_variation, &"PrimaryButton")
	assert_null(card.resume_button)


func test_a_saved_run_offers_resume_before_start_over() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var card: RunCard = _keep(RunCard.new(game, RunFx.run_data(), false, "", {}, 0, "Your saved run is on wave 4 of 18.")) as RunCard
	assert_not_null(card.resume_button)
	assert_eq(card.start_button.text, "Start over")
	assert_eq(card.saved_label.text, "Your saved run is on wave 4 of 18.")
	var fired: Array[int] = [0]
	card.resume_requested.connect(func() -> void: fired[0] += 1)
	card.resume_button.tapped.emit()
	assert_eq(fired[0], 1)


func test_the_daily_card_shows_the_day_the_best_and_the_streak() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var data: RunData = RunFx.run_data()
	var fresh: RunCard = _keep(RunCard.new(game, data, true, "2026-10-24", {}, 0)) as RunCard
	assert_eq(fresh.title_label.text, "Daily")
	assert_eq(fresh.day_label.text, "Today: 2026-10-24")
	assert_eq(fresh.best_label.text, "Best today: No result yet today.")
	assert_eq(fresh.streak_label.text, "No streak yet.")
	assert_null(fresh.normal_button, "the daily is always Normal, so there is no choice")
	assert_null(fresh.relaxed_button)
	var won: RunCard = _keep(RunCard.new(game, data, true, "2026-10-24", {"won": true, "waves": 18, "lives": 14}, 3)) as RunCard
	assert_eq(won.best_label.text, "Best today: Won with 14 lives left.")
	assert_eq(won.streak_label.text, "Streak: 3 days")
	var lost: RunCard = _keep(RunCard.new(game, data, true, "2026-10-24", {"won": false, "waves": 9, "lives": 0}, 1)) as RunCard
	assert_eq(lost.best_label.text, "Best today: Lost with 9 of 18 waves cleared.")
	assert_eq(lost.streak_label.text, "Streak: 1 day")
	var seen: Array[bool] = []
	won.start_requested.connect(func(relaxed: bool) -> void: seen.append(relaxed))
	won.start_button.tapped.emit()
	assert_eq(seen, [false] as Array[bool], "a daily always starts on Normal")


func test_a_daily_with_a_bad_phone_date_says_so_and_cannot_start() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var card: RunCard = _keep(RunCard.new(game, RunFx.run_data(), true, "", {}, 0)) as RunCard
	assert_eq(card.notice_label.text, "Check the phone's date.")
	assert_null(card.start_button)


# The run end panel.

func _result(won: bool, waves: int, lives: int) -> Dictionary:
	return {"won": won, "waves": waves, "lives": lives, "reached": waves, "risks": 0}


func test_a_won_run_shows_waves_and_lives() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var panel: RunEndPanel = _keep(RunEndPanel.new(game, _result(true, 18, 12))) as RunEndPanel
	assert_true(panel.won)
	assert_eq(panel.title_label.text, "Run won")
	assert_eq(panel.summary_label.text, "Waves cleared: 18 of 18")
	assert_eq(panel.lives_label.text, "Lives left: 12")
	assert_null(panel.relaxed_label)
	assert_null(panel.best_label)
	assert_eq(panel.retry_button.text, "Play again")


func test_a_normal_loss_points_to_relaxed_and_a_relaxed_loss_does_not() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var panel: RunEndPanel = _keep(RunEndPanel.new(game, _result(false, 7, 0))) as RunEndPanel
	assert_eq(panel.title_label.text, "Run lost")
	assert_eq(panel.summary_label.text, "Waves cleared: 7 of 18")
	assert_not_null(panel.relaxed_label)
	assert_eq(panel.relaxed_label.text, EndPanel.relaxed_hint(game))
	assert_eq(panel.retry_button.text, "Try again")
	var relaxed: RunEndPanel = _keep(RunEndPanel.new(game, _result(false, 7, 0), true)) as RunEndPanel
	assert_null(relaxed.relaxed_label)


func test_a_daily_end_shows_the_best_and_the_streak_and_no_relaxed_line() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var panel: RunEndPanel = _keep(RunEndPanel.new(game, _result(false, 9, 0), false, "2026-10-24", {"won": false, "waves": 9, "lives": 0}, 2)) as RunEndPanel
	assert_eq(panel.title_label.text, "Daily lost")
	assert_true(_texts(panel).has("2026-10-24"))
	assert_eq(panel.best_label.text, "Best today: Lost with 9 of 18 waves cleared.")
	assert_eq(panel.streak_label.text, "Streak: 2 days")
	assert_null(panel.relaxed_label, "the daily is always Normal, so it never points to Relaxed")


func test_the_run_end_panel_answers_close_the_panel_first() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var panel: RunEndPanel = _keep(RunEndPanel.new(game, _result(true, 18, 3))) as RunEndPanel
	var order: Array[String] = []
	panel.closed.connect(func() -> void: order.append("closed"))
	panel.retry_requested.connect(func() -> void: order.append("retry"))
	panel.menu_requested.connect(func() -> void: order.append("menu"))
	panel.retry_button.tapped.emit()
	panel.request_close()
	assert_eq(order, ["closed", "retry", "closed", "menu"] as Array[String])
