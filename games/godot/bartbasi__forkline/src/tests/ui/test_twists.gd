# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Twists in the UI (RULES 13, docs/ARCHITECTURE.md 3.6): the Twist block of the level card, a
## Twist starting with its effects, its saved game and Continue text, its rule in the hint and
## in Pause, its win recorded as cleared (never as stars), and its end panel. No running scene
## tree: the layout itself is checked in real_tree_checks.gd.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "twists"

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
	Fx.wipe(TAG)


func _keep(node: Node) -> Node:
	spare.append(node)
	return node


func _app(fresh: bool = true) -> App:
	var made: App = Fx.app(TAG, fresh)
	apps.append(made)
	return made


func _drop(made: App) -> void:
	apps.erase(made)
	made.free()


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


## An App with level 1-1 on three stars, so its Twist is open.
func _open_app() -> App:
	var made: App = _app()
	Fx.mark_all_seen(made)
	made.progress.record_level(&"r1_l1", 7)
	made.save_progress()
	return made


## Starts a level's Twist through its card, the way a player does.
func _start_twist(made: App, id: StringName = &"r1_l1", relaxed: bool = false) -> BattleScreen:
	made.open_level_card(id)
	var card: LevelCard = made.current_screen() as LevelCard
	assert_not_null(card.twist_play_button, "the card of %s offers its Twist" % id)
	card.twist_requested.emit(relaxed)
	assert_true(made.current_screen() is BattleScreen, "Play the Twist starts the battle")
	return made.battle_screen()


func _winning(screen: BattleScreen) -> bool:
	screen.battle.gold = 20000
	return Fx.play_out(screen)


# The level card.

func test_the_card_shows_no_twist_until_the_level_has_three_stars() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	for bits: int in [0, 1, 3, 5, 6]:
		var progress: Progress = Progress.new()
		progress.record_level(&"r1_l1", bits)
		var card: LevelCard = _keep(LevelCard.new(game, progress, &"r1_l1", false)) as LevelCard
		assert_null(card.twist_play_button, "stars %d: no Twist yet" % bits)
		assert_false(_texts(card).has("Twist: Thin Purse"))


func test_the_card_shows_the_twist_name_and_text_once_open() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var level: LevelData = game.levels[&"r1_l1"]
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 7)
	var card: LevelCard = _keep(LevelCard.new(game, progress, &"r1_l1", false)) as LevelCard
	assert_eq(card.twist_title_label.text, "Twist: %s" % level.twist_name)
	assert_eq(card.twist_text_label.text, level.twist_text)
	assert_eq(card.twist_play_button.text, "Play the Twist")
	assert_true(card.twist_state_label.text.begins_with("Not cleared yet"), "a new Twist says it is not cleared")
	progress.record_twist(&"r1_l1")
	var again: LevelCard = _keep(LevelCard.new(game, progress, &"r1_l1", false)) as LevelCard
	assert_true(again.twist_state_label.text.begins_with("Cleared"), "a won Twist says so, in words")


func test_a_level_without_a_twist_shows_no_block() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var data: Dictionary = game.levels[&"r1_l1"].to_data()
	data.erase("twist")
	var made: GameData = GameData.new()
	made.catalog = game.catalog
	made.levels[&"plain"] = LevelData.from_data(data, game.catalog)
	made.campaign.append({"id": &"x", "name": "X", "levels": [&"plain"] as Array[StringName]})
	var progress: Progress = Progress.new()
	progress.record_level(&"plain", 7)
	var card: LevelCard = _keep(LevelCard.new(made, progress, &"plain", false)) as LevelCard
	assert_null(card.twist_play_button, "no Twist in the file, no Twist block")


func test_the_twist_has_its_own_normal_first_choice_with_numbers_from_the_sim() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var level: LevelData = game.levels[&"r1_l1"]
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 7)
	var card: LevelCard = _keep(LevelCard.new(game, progress, &"r1_l1", false)) as LevelCard
	assert_false(card.twist_relaxed, "Normal is chosen when the card opens")
	var normal: Battle = Battle.create(level, game.catalog, false, level.twist_effects)
	var easy: Battle = Battle.create(level, game.catalog, true, level.twist_effects)
	assert_true(card.twist_difficulty_label.text.contains("%d lives and %d gold" % [normal.lives, normal.gold]))
	assert_eq(normal.gold, 100, "Thin Purse starts with half the gold")
	var seen: Array[bool] = []
	card.twist_requested.connect(func(relaxed: bool) -> void: seen.append(relaxed))
	card.twist_play_button.tapped.emit()
	card.twist_relaxed_button.tapped.emit()
	assert_true(card.twist_relaxed)
	assert_true(card.twist_difficulty_label.text.contains("%d lives and %d gold" % [easy.lives, easy.gold]))
	card.twist_play_button.tapped.emit()
	assert_eq(seen, [false, true] as Array[bool])
	assert_false(card.relaxed, "the level's own choice is separate and stays Normal")


func test_a_saved_twist_offers_resume_in_the_twist_block_only() -> void:
	var game: GameData = Fx.BattleFixtures.game()
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l1", 7)
	var card: LevelCard = _keep(LevelCard.new(game, progress, &"r1_l1", true, true, true)) as LevelCard
	assert_not_null(card.twist_resume_button, "the Twist's saved game resumes from the Twist block")
	assert_null(card.resume_button, "the plain level has no saved game of its own")
	assert_eq(card.play_button.text, "Play")
	assert_eq(card.twist_play_button.text, "Start the Twist over")
	var fired: Array[int] = [0]
	card.twist_resume_requested.connect(func() -> void: fired[0] += 1)
	card.twist_resume_button.tapped.emit()
	assert_eq(fired[0], 1)
	var plain: LevelCard = _keep(LevelCard.new(game, progress, &"r1_l1", true, false, false)) as LevelCard
	assert_not_null(plain.resume_button, "a saved plain level resumes from the top")
	assert_null(plain.twist_resume_button, "and the Twist has no saved game")
	assert_eq(plain.twist_play_button.text, "Play the Twist")


# Playing a Twist.

func test_a_twist_starts_with_its_effects_and_is_saved_as_a_twist() -> void:
	var made: App = _open_app()
	var level: LevelData = made.game.levels[&"r1_l1"]
	var screen: BattleScreen = _start_twist(made)
	assert_eq(screen.battle.twist_effects, level.twist_effects, "the Twist's effects play")
	assert_eq(screen.battle.gold, 100, "Thin Purse: half the gold")
	assert_true(made.active_game().twist)
	assert_false(screen.has_stars(), "a Twist has no stars")
	assert_eq(screen.clock.speed, 1)
	var saved: Array[SavedGame] = SaveStore.new(Fx.dir(TAG)).load_games(made.game)
	assert_eq(saved.size(), 1)
	assert_true(saved[0].twist, "the saved game remembers it is the Twist")


func test_a_twist_needs_the_levels_three_stars() -> void:
	var made: App = _app()
	made.start_level(&"r1_l1", false, true)
	assert_null(made.battle_screen(), "a Twist that is not open does not start")
	made.progress.record_level(&"r1_l1", 3)
	made.start_level(&"r1_l1", false, true)
	assert_null(made.battle_screen(), "two stars are not enough")
	made.progress.record_level(&"r1_l1", 7)
	made.start_level(&"r1_l1", false, true)
	assert_not_null(made.battle_screen())


func test_a_relaxed_twist_has_the_relaxed_lives() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made, &"r1_l1", true)
	assert_true(screen.battle.relaxed)
	assert_eq(screen.battle.lives, 40)
	assert_eq(screen.battle.twist_effects, made.game.levels[&"r1_l1"].twist_effects)


func test_a_won_twist_records_the_twist_and_no_stars() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	var ended: Array[Dictionary] = []
	screen.ended.connect(func(result: Dictionary) -> void: ended.append(result))
	var stars_before: int = made.progress.stars()
	assert_true(_winning(screen), "the scripted defense wins the Twist")
	assert_eq(ended.size(), 1)
	assert_true(ended[0]["twist"], "the screen says the game was a Twist")
	assert_true(made.progress.twists.has(&"r1_l1"), "the Twist is recorded as cleared")
	assert_eq(made.progress.stars(), stars_before, "and earns no stars")
	assert_eq(made.progress.levels[&"r1_l1"], 7)
	assert_eq(SaveStore.new(Fx.dir(TAG)).load_progress().twists, [&"r1_l1"] as Array[StringName], "saved")
	assert_eq(SaveStore.new(Fx.dir(TAG)).load_games(made.game).size(), 0, "the finished game is not kept")
	var panel: EndPanel = made.top_modal() as EndPanel
	assert_not_null(panel)
	assert_true(panel.twist and panel.won)
	assert_eq(panel.title_label.text, "Twist cleared")
	assert_true(panel.star_states.is_empty(), "no star lines")
	assert_null(panel.next_button, "a Twist leads nowhere new")
	assert_true(_texts(panel).has("Twist: Thin Purse"))
	assert_true(panel.summary_label.text.begins_with("The Twist is cleared."))
	assert_eq(panel.retry_button.text, "Play again")


func test_a_won_twist_on_relaxed_is_cleared_too() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made, &"r1_l1", true)
	assert_true(_winning(screen))
	assert_true(made.progress.twists.has(&"r1_l1"), "a win on either difficulty clears the Twist")


func test_a_won_level_still_records_stars_not_twists() -> void:
	var made: App = _app()
	Fx.mark_all_seen(made)
	made.open_level_card(&"r1_l1")
	(made.current_screen() as LevelCard).play_requested.emit(false)
	assert_true(Fx.play_out(made.battle_screen()))
	assert_true(made.progress.twists.is_empty(), "a plain win clears no Twist")
	assert_true(made.progress.levels[&"r1_l1"] & 1 == 1)


func test_a_lost_twist_records_nothing_and_does_not_mention_relaxed() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	var guard: int = 0
	while screen.battle.phase != Battle.Phase.LOST and guard < 40000:
		if screen.battle.phase == Battle.Phase.BUILD:
			screen.hud.call_button.tapped.emit()
		screen.frame(0.05)
		guard += 1
	assert_eq(screen.battle.phase, Battle.Phase.LOST)
	assert_true(made.progress.twists.is_empty())
	var panel: EndPanel = made.top_modal() as EndPanel
	assert_eq(panel.title_label.text, "Twist lost")
	assert_null(panel.relaxed_label, "the Relaxed line is for levels")
	panel.retry_button.tapped.emit()
	assert_true(made.current_screen() is BattleScreen, "Try again starts the Twist again")
	assert_eq(made.battle_screen().battle.twist_effects, made.game.levels[&"r1_l1"].twist_effects, "and it is the Twist")
	assert_true(made.active_game().twist)


func test_play_again_after_a_won_twist_starts_the_twist_again() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	assert_true(_winning(screen))
	(made.top_modal() as EndPanel).retry_button.tapped.emit()
	assert_true(made.current_screen() is BattleScreen)
	assert_true(made.active_game().twist)
	assert_false(made.battle_screen().battle.twist_effects.is_empty())


func test_an_abandoned_twist_records_nothing() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	screen.pause()
	var pause: PausePanel = made.top_modal() as PausePanel
	pause.abandon_confirmed.emit()
	assert_true(made.progress.twists.is_empty())
	assert_eq(made.screen_count(), 1)


# The Twist's rule in play.

func test_the_twist_rule_is_the_first_hint_and_not_remembered() -> void:
	var made: App = _open_app()
	made.progress.seen.erase(&"r1_l1")
	var level: LevelData = made.game.levels[&"r1_l1"]
	var screen: BattleScreen = _start_twist(made)
	assert_true(screen.hint_banner.visible, "a fresh Twist says its rule")
	assert_eq(screen.hint_banner.text_label.text, "Twist: %s" % level.twist_text)
	screen.hint_banner.tap()
	assert_false(screen.hint_banner.visible)
	assert_false(made.progress.seen.has(&"r1_l1"), "closing a Twist's hint does not mark the level's own hint read")


func test_the_level_hint_still_shows_on_a_plain_start() -> void:
	var made: App = _app()
	Fx.mark_all_seen(made)
	made.progress.seen.erase(&"r1_l1")
	made.open_level_card(&"r1_l1")
	(made.current_screen() as LevelCard).play_requested.emit(false)
	var screen: BattleScreen = made.battle_screen()
	assert_eq(screen.hint_banner.text_label.text, made.game.levels[&"r1_l1"].hint_text)


func test_pause_shows_the_twist_and_no_star_lines() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	screen.pause()
	var pause: PausePanel = made.top_modal() as PausePanel
	assert_true(pause.star_lines.is_empty(), "a Twist has no star lines")
	assert_eq(pause.twist_name_label.text, "Twist: Thin Purse")
	assert_eq(pause.twist_text_label.text, made.game.levels[&"r1_l1"].twist_text)
	pause.request_close()
	var plain_app: App = _app()
	Fx.mark_all_seen(plain_app)
	plain_app.open_level_card(&"r1_l1")
	(plain_app.current_screen() as LevelCard).play_requested.emit(false)
	plain_app.battle_screen().pause()
	var plain_pause: PausePanel = plain_app.top_modal() as PausePanel
	assert_eq(plain_pause.star_lines.size(), 3, "a plain level keeps its star lines")
	assert_null(plain_pause.twist_name_label)


func test_no_star_warnings_in_a_twist() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	for panel: BattlePanel in [screen.build_panel, screen.tower_panel, screen.gate_tray]:
		assert_false(panel.star_warnings, "no warnings without stars")


# Saved Twists.

func test_the_continue_card_says_it_is_a_twist() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	screen.pause()
	screen.left.emit()
	made.open_mode()
	var mode: ModeScreen = made.current_screen() as ModeScreen
	assert_not_null(mode.continue_button)
	assert_true(_texts(mode.continue_button).has("Level 1-1 Twist, First Lanterns. Ready to start."), "%s" % [_texts(mode.continue_button)])


func test_a_saved_twist_resumes_with_its_effects_paused() -> void:
	var made: App = _open_app()
	var screen: BattleScreen = _start_twist(made)
	made.leave_app()
	var before: String = JSON.stringify(screen.battle.to_data())
	_drop(made)
	var again: App = _app(false)
	assert_eq(again.saved_games.size(), 1)
	assert_true(again.saved_games[0].twist)
	again.open_level_card(&"r1_l1")
	var card: LevelCard = again.current_screen() as LevelCard
	assert_not_null(card.twist_resume_button)
	assert_null(card.resume_button)
	card.twist_resume_requested.emit()
	var resumed: BattleScreen = again.battle_screen()
	assert_not_null(resumed)
	assert_eq(JSON.stringify(resumed.battle.to_data()), before, "byte for byte")
	assert_false(resumed.battle.twist_effects.is_empty())
	assert_true(resumed.is_paused() and resumed.pause_menu_open())
	assert_true(again.active_game().twist, "and it ends as a Twist")


func test_starting_a_twist_while_the_level_is_saved_asks_first() -> void:
	var made: App = _open_app()
	made.open_level_card(&"r1_l1")
	(made.current_screen() as LevelCard).play_requested.emit(false)
	var screen: BattleScreen = made.battle_screen()
	screen.pause()
	screen.left.emit()
	made.open_level_card(&"r1_l1")
	var card: LevelCard = made.current_screen() as LevelCard
	assert_not_null(card.resume_button, "the plain game resumes from the top")
	assert_null(card.twist_resume_button)
	card.twist_requested.emit(false)
	var dialog: ConfirmDialog = made.top_modal() as ConfirmDialog
	assert_not_null(dialog, "a level and its own Twist are different games, so it asks")
	assert_true(made.current_screen() is LevelCard, "nothing started yet")
	dialog.request_close()
	assert_false(made.saved_games[0].twist, "cancel keeps the plain game")
