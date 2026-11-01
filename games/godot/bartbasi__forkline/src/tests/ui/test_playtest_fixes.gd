# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The fixes of the round before the region 1 playtest (QA report 2026-10-24): live
## "Need" text, the Sell delay, the star warning, first sights, the back button, the
## Continue card, the locked run modes, the About wording, the Relaxed card, the reach
## format and the Info captions. The map cell floor is in real_tree_checks.gd.

const Fx: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const Flow: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "fixes"

var keep: Array[Node] = []


func after_each() -> void:
	for node: Node in keep:
		if is_instance_valid(node):
			node.free()
	keep.clear()
	Flow.wipe(TAG)


func _keep(node: Node) -> Node:
	keep.append(node)
	return node


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


func _seen_all(battle: Battle) -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in battle.catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in battle.catalog.enemy_ids():
		progress.mark_seen(id)
	for id: StringName in Fx.game().levels:
		progress.mark_seen(id)
	return progress


func _screen(battle: Battle, progress: Progress) -> BattleScreen:
	var screen: BattleScreen = _keep(BattleScreen.new()) as BattleScreen
	screen.setup(battle, null, progress)
	return screen


func _app() -> App:
	return _keep(Flow.app(TAG)) as App


# Need text (m5).

func test_need_text_on_build_cards_follows_the_gold_without_a_rebuild() -> void:
	var b: Battle = Fx.battle(&"r1_l1")
	b.gold = 0
	var spot: Vector2i = b.level.spots[0]
	var panel: BuildPanel = _keep(BuildPanel.new()) as BuildPanel
	panel.setup(b)
	panel.show_spot(spot)
	var type: StringName = b.level.towers[0]
	var cost: int = int(b.build_options(spot)[0]["cost"])
	assert_eq(panel.need_labels[type].text, "Need %d" % cost)
	var card: TapButton = panel.card_buttons[type]
	b.gold = 15
	panel.refresh()
	assert_eq(panel.need_labels[type].text, "Need %d" % (cost - 15), "the missing gold is live")
	assert_eq(panel.card_buttons[type], card, "the card was not rebuilt under a finger")
	b.gold = cost
	panel.refresh()
	assert_false(panel.need_labels.has(type), "an affordable card has no Need line")


func test_need_text_on_tier_3_path_cards_follows_the_gold() -> void:
	var b: Battle = Fx.battle(&"r1_l6")
	b.gold = 100000
	var cell: Vector2i = b.level.spots[0]
	assert_eq(b.place_tower(cell, b.level.towers[0]), Battle.DONE)
	assert_eq(b.upgrade_tower(cell), Battle.DONE)
	var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	panel.setup(b)
	var cost: int = int(b.upgrade_options(cell)[0]["cost"])
	b.gold = cost - 50
	panel.show_tower(cell)
	assert_eq(panel.cost_labels[0].text, "Cost %d, need 50 more" % cost)
	b.gold = cost - 20
	panel.refresh()
	assert_eq(panel.cost_labels[0].text, "Cost %d, need 20 more" % cost)
	b.gold = cost
	panel.refresh()
	assert_eq(panel.cost_labels[0].text, "Cost %d" % cost)


# The star warning (suggestion).

func test_the_upgrade_that_breaks_a_tier_star_says_so_on_every_such_level() -> void:
	for id: StringName in [&"r1_l1", &"r1_l2", &"r1_l4"]:
		var b: Battle = Fx.battle(id)
		assert_eq(b.level.star3["kind"], &"tier_at_most")
		b.gold = 100000
		var cell: Vector2i = b.level.spots[0]
		b.place_tower(cell, b.level.towers[0])
		var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
		panel.setup(b)
		panel.show_tower(cell)
		assert_not_null(panel.star_warning_label, "%s warns before the tier 2 upgrade" % id)
		assert_eq(panel.star_warning_label.text, "Loses the third star.")
	var plain: Battle = Fx.battle(&"r1_l3")
	plain.gold = 100000
	var spot: Vector2i = plain.level.spots[0]
	plain.place_tower(spot, plain.level.towers[0])
	var other: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	other.setup(plain)
	other.show_tower(spot)
	assert_null(other.star_warning_label, "a level with another star 3 rule shows no warning")


func test_a_tier_2_cap_warns_only_before_tier_3_and_not_when_already_lost() -> void:
	var b: Battle = Fx.battle(&"r1_l5")
	assert_eq(int(b.level.star3["value"]), 2)
	b.gold = 100000
	var first: Vector2i = b.level.spots[0]
	var second: Vector2i = b.level.spots[1]
	b.place_tower(first, b.level.towers[0])
	b.place_tower(second, b.level.towers[0])
	var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	panel.setup(b)
	panel.show_tower(first)
	assert_null(panel.star_warning_label, "tier 2 is allowed")
	b.upgrade_tower(first)
	panel.show_tower(first)
	assert_not_null(panel.star_warning_label, "the tier 3 choice warns")
	b.upgrade_tower(second)
	b.upgrade_tower(second, 0)
	panel.show_tower(first)
	assert_null(panel.star_warning_label, "a tower already above tier 2 means the star is gone, so no warning")


# The reach format (p8).

func test_reach_reads_the_same_way_everywhere() -> void:
	assert_eq(BattleText.tiles_text(250), "2.5 tiles")
	assert_eq(BattleText.tiles_text(300), "3 tiles")
	var rows: Array[Dictionary] = BattleText.change_rows({"reach": 250}, {"reach": 300}, &"attack")
	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["before"], "2.5 tiles")
	assert_eq(rows[0]["after"], "3 tiles")
	var stat: Array[PackedStringArray] = BattleText.tower_rows({"reach": 300, "hits_ground": true, "reload_ms": 500, "damage": 5}, &"attack")
	assert_eq(stat[2][1], "3 tiles")


# Wave numbers (m4).

func test_the_continue_card_and_the_hud_show_the_same_wave() -> void:
	var made: App = _app()
	Flow.mark_all_seen(made)
	made.start_level(&"r1_l4", false)
	var screen: BattleScreen = made.battle_screen()
	var b: Battle = screen.battle
	assert_eq(screen.hud.wave_label.text, "Wave 1/%d" % b.wave_count())
	Flow.build(screen, b.level.spots[0], &"sling_post")
	screen.hud.call_button.tapped.emit()
	Flow.run(screen, 4000, func() -> bool: return b.phase == Battle.Phase.BUILD)
	assert_eq(b.phase, Battle.Phase.BUILD)
	screen.frame(0.05)
	assert_eq(screen.hud.wave_label.text, "Wave 2/%d" % b.wave_count())
	made.save_active()
	var text: String = made._saved_text(made.saved_games[0])
	assert_true(text.contains("Wave 2 of %d." % b.wave_count()), "Continue says wave 2: %s" % text)
	screen.hud.call_button.tapped.emit()
	screen.frame(0.05)
	assert_eq(screen.hud.wave_label.text, "Wave 2/%d" % b.wave_count(), "mid wave the number stays")
	assert_eq(BattleText.wave_number(b), 2)


# Locked run modes and wording (m6, p1).

func test_roguelite_and_daily_say_when_they_come() -> void:
	var screen: ModeScreen = _keep(ModeScreen.new()) as ModeScreen
	screen.set_runs(true, 40, 12, false)
	assert_true(screen.roguelite_button.disabled)
	assert_true(screen.daily_button.disabled)
	var text: String = " ".join(_texts(screen))
	assert_true(text.contains("Coming in a later update."))
	assert_false(text.contains("Needs"))
	screen.set_runs(false, 3, 12, true)
	assert_true(" ".join(_texts(screen)).contains("Needs 12 stars, you have 3"), "the 12 star rule is kept for later")
	var info: InfoScreen = _keep(InfoScreen.new({"run_stars": 12, "runs_built": false})) as InfoScreen
	var words: String = " ".join(_texts(info))
	assert_true(words.contains("coming in a later update"))
	assert_false(words.contains("12 stars"))


func test_about_says_with_additional_terms() -> void:
	var about: AboutScreen = _keep(AboutScreen.new()) as AboutScreen
	var all: String = " ".join(_texts(about))
	assert_true(all.contains("GNU GPL version 3, with additional terms"))
	assert_false(all.contains("added terms"))


# The level card (p4).

func test_a_saved_relaxed_game_says_so_next_to_resume() -> void:
	var game: GameData = Fx.game()
	var saved: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", true, true)) as LevelCard
	assert_not_null(saved.resume_button)
	assert_eq(saved.saved_label.text, "Your saved game is on Relaxed.")
	var normal: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", true, false)) as LevelCard
	assert_eq(normal.saved_label.text, "Your saved game is on Normal.")
	assert_true(" ".join(_texts(saved)).contains("Difficulty if you start over"))
	assert_false(saved.relaxed, "Start over still begins on Normal")
	var fresh: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", false)) as LevelCard
	assert_null(fresh.saved_label)


# First sights (m2, m3, p2, p5).

func _pip_battle() -> Battle:
	var b: Battle = Fx.battle(&"r1_l4")
	b.gold = 100000
	b.lives = 100000
	for cell: Vector2i in b.level.spots:
		b.place_tower(cell, b.level.towers[0])
		b.upgrade_tower(cell)
	return b


func test_a_creature_keeps_its_new_tag_after_its_card_until_its_wave_starts() -> void:
	var b: Battle = _pip_battle()
	var index: int = -1
	for i: int in b.wave_count():
		for entry: Dictionary in b.wave_preview(i):
			if entry["enemy"] == &"pip" and index < 0:
				index = i
	while b.waves_started < index:
		b.start_next_wave()
		Fx.finish_wave(b)
	var progress: Progress = _seen_all(b)
	progress.seen.erase(&"pip")
	var screen: BattleScreen = _screen(b, progress)
	assert_true(screen.card_open())
	assert_true(screen.preview._unseen.has(&"pip"), "tagged while the card is open")
	screen._card.advance()
	assert_true(progress.seen.has(&"pip"), "seen once the card is closed")
	assert_true(screen.preview._unseen.has(&"pip"), "and still New in the preview until the wave starts")
	var open_texts: PackedStringArray = _texts(screen.preview)
	assert_true(open_texts.has("New"), "the open row shows the word")
	screen.preview.toggle()
	assert_false(screen.preview.expanded)
	assert_true(_texts(screen.preview).has("New"), "and so does the folded strip")
	b.start_next_wave()
	screen.frame(0.05)
	assert_false(screen.preview._unseen.has(&"pip"), "the tag goes when the wave starts")


func test_calling_a_wave_early_still_opens_the_new_creatures_card_and_waits() -> void:
	var b: Battle = _pip_battle()
	var progress: Progress = _seen_all(b)
	progress.seen.erase(&"pip")
	var screen: BattleScreen = _screen(b, progress)
	screen.clock.speed = 3
	b.start_next_wave()
	var guard: int = 0
	while not screen.card_open() and guard < 4000:
		if b.next_wave_info()["refusal"] == &"" and b.waves_started < b.wave_count():
			b.start_next_wave()
		screen.frame(0.05)
		guard += 1
	assert_true(screen.card_open(), "the card opened when the creature walked in, not at the next build phase")
	assert_true(screen.is_paused(), "and the game waits")
	assert_false(progress.seen.has(&"pip"))
	var tick: int = b.tick
	screen.frame(0.5)
	assert_eq(b.tick, tick, "no tick runs behind the card")
	screen._card.advance()
	assert_false(screen.is_paused(), "closing the card lets the wave go on")
	assert_true(progress.seen.has(&"pip"))
	screen.frame(0.1)
	assert_true(b.tick > tick)
	assert_false(screen.card_open(), "never a second time")


func test_the_hint_closes_on_a_tap_and_when_the_first_wave_starts() -> void:
	var progress: Progress = _seen_all(Fx.battle(&"r1_l1"))
	progress.seen.erase(&"r1_l1")
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l1"), progress)
	assert_true(screen.hint_banner.visible)
	screen.hint_banner.tap()
	assert_false(screen.hint_banner.visible, "a tap on the banner closes it")
	assert_true(progress.seen.has(&"r1_l1"))
	var other: Progress = _seen_all(Fx.battle(&"r1_l1"))
	other.seen.erase(&"r1_l1")
	var second: BattleScreen = _screen(Fx.battle(&"r1_l1"), other)
	assert_true(second.hint_banner.visible)
	second.battle.start_next_wave()
	second.frame(0.05)
	assert_false(second.hint_banner.visible, "the first wave closes it")
	assert_true(other.seen.has(&"r1_l1"))
	var card: LevelCard = _keep(LevelCard.new(Fx.game(), Progress.new(), &"r1_l1", false)) as LevelCard
	assert_eq(card.hint_label.text, Fx.game().levels[&"r1_l1"].hint_text, "the hint stays on the level card")


# The back button (p3).

func test_back_closes_an_open_panel_first_and_the_next_press_opens_pause() -> void:
	var made: App = _app()
	Flow.mark_all_seen(made)
	made.start_level(&"r1_l1", false)
	var screen: BattleScreen = made.battle_screen()
	screen.tap_at(screen.battle.level.spots[0])
	assert_not_null(screen.context_panel())
	assert_eq(made.handle_back(), &"modal")
	assert_null(screen.context_panel(), "the panel closed")
	assert_false(screen.pause_menu_open(), "and Pause did not open")
	assert_eq(made.handle_back(), &"modal")
	assert_true(screen.pause_menu_open(), "the next press opens Pause")


func test_one_back_press_is_one_step_even_if_two_signals_arrive() -> void:
	var made: App = _app()
	Flow.mark_all_seen(made)
	made.start_level(&"r1_l1", false)
	var screen: BattleScreen = made.battle_screen()
	screen.tap_at(screen.battle.level.spots[0])
	made._back_pressed()
	made._back_pressed()
	assert_null(screen.context_panel())
	assert_false(screen.pause_menu_open(), "the second signal of one press did nothing")
	made._last_back_ms = -1000
	made._back_pressed()
	assert_true(screen.pause_menu_open())


func test_back_on_a_first_sight_card_closes_it_and_counts_it_as_read() -> void:
	var made: App = _app()
	made.start_level(&"r1_l1", false)
	var screen: BattleScreen = made.battle_screen()
	assert_true(screen.card_open())
	assert_eq(made.handle_back(), &"modal")
	assert_false(screen.card_open())
	assert_true(made.progress.seen.has(&"sling_post"))


# The dock and the Info captions (M1, m7).

func test_the_dock_holds_the_floating_parts_in_portrait_only() -> void:
	var screen: BattleScreen = _screen(Fx.battle(&"r1_l2"), _seen_all(Fx.battle(&"r1_l2")))
	screen.apply_layout(Flow.COVER, Flow.COVER_SAFE)
	for part: Control in [screen.pause_strip, screen.preview, screen.hud.feedback_box, screen.gate_tray.feedback_box]:
		assert_eq(part.get_parent(), screen._dock, "%s floats over the map in portrait" % part.get_class())
	assert_eq(screen.hint_banner.get_parent(), screen._hint_layer, "the hint floats over a free row of the map")
	assert_eq(screen.hud.get_parent(), screen._top_box, "only the HUD takes height")
	assert_true(screen.hud.is_ancestor_of(screen.gate_tray), "the gate chip sits in the HUD's first row")
	assert_true(screen.gate_tray.chip)
	assert_true(screen.preview.expanded, "the preview is open in a build phase, in portrait too")
	screen.apply_layout(Flow.INNER, Flow.INNER_SAFE)
	for part: Control in [screen.hint_banner, screen.gate_tray, screen.pause_strip, screen.preview]:
		assert_eq(part.get_parent(), screen._side_box)
	assert_eq(screen.hud.feedback_box.get_parent(), screen.hud.column, "the HUD keeps its own message box in the side column")
	assert_false(screen.gate_tray.chip, "the side column has room for the full strip")


func test_info_names_fit_without_shrinking() -> void:
	var game: GameData = Fx.game()
	var names: Dictionary = {}
	for id: StringName in game.catalog.tower_ids():
		names[id] = game.catalog.tower(id).name
	for id: StringName in game.catalog.enemy_ids():
		names[id] = game.catalog.enemy(id).name
	var info: InfoScreen = _keep(InfoScreen.new({}, names, InfoContent.from_game(game))) as InfoScreen
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	var checked: int = 0
	for node: Node in info.find_children("*", "InfoArt", true, false):
		var art: InfoArt = node as InfoArt
		if art.kind != &"towers" and art.kind != &"creatures":
			continue
		for width: float in [900.0, 1040.0, 640.0]:
			var g: Dictionary = art._grid(width)
			assert_true(int(g["per_row"]) >= InfoArt.MIN_PER_ROW)
			var lines: Array = g["lines"]
			assert_eq(lines.size(), art.captions.size())
			for caption: PackedStringArray in lines:
				assert_true(caption.size() <= 2, "a name is at most two lines")
				for line: String in caption:
					checked += 1
					assert_true(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, InfoArt.CAPTION_SIZE).x <= float(g["slot"]), "'%s' fits its slot at %d px" % [line, width])
	assert_true(checked > 20)
	assert_true(InfoArt.CAPTION_SIZE >= 36, "names stay readable")
