# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The level list, the level card, the end panel and the star sentences (RULES 10, 12.4,
## 16; docs/ARCHITECTURE.md 2.7). Every name and sentence comes from the data. No
## running scene tree.

const Fx: GDScript = preload("res://tests/ui/battle_fixtures.gd")

var spare: Array[Node] = []


func after_each() -> void:
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


func _level_with(star3: Dictionary) -> LevelData:
	var data: Dictionary = Fx.game().levels[&"r1_l1"].to_data()
	data["star3"] = star3
	return LevelData.from_data(data, Fx.game().catalog)


# Star sentences.

func test_star_sentences_are_built_from_the_kind_the_number_and_the_catalog() -> void:
	var catalog: Catalog = Fx.game().catalog
	var sling_plural: String = catalog.tower(&"sling_post").plural
	var cases: Array[Array] = [
		[{"kind": "no_lives_lost"}, "Lose no lives."],
		[{"kind": "towers_at_most", "value": 4}, "Have at most 4 towers."],
		[{"kind": "towers_at_most", "value": 1}, "Have at most 1 tower."],
		[{"kind": "tower_ban", "tower": "sling_post"}, "Build no %s." % sling_plural],
		[{"kind": "gates_at_most", "value": 0}, "Use no gates."],
		[{"kind": "gates_at_most", "value": 1}, "Use at most 1 gate."],
		[{"kind": "gates_at_most", "value": 2}, "Use at most 2 gates."],
		[{"kind": "tier_at_most", "value": 2}, "No tower above tier 2."],
		[{"kind": "early_calls_at_least", "value": 4}, "Call 4 waves early."],
		[{"kind": "early_calls_at_least", "value": 1}, "Call 1 wave early."],
		[{"kind": "kinds_at_most", "value": 3}, "Use at most 3 kinds of tower."],
		[{"kind": "gates_whole"}, "Use every gate and keep them whole."],
	]
	for item: Array in cases:
		var level: LevelData = _level_with(item[0])
		assert_not_null(level, "a level with %s loads" % item[0])
		if level != null:
			assert_eq(StarText.challenge(level, catalog), item[1])


func test_the_three_lines_of_every_real_level() -> void:
	var game: GameData = Fx.game()
	for id: StringName in game.levels:
		var lines: PackedStringArray = StarText.lines(game.levels[id], game.catalog)
		assert_eq(lines.size(), 3)
		assert_eq(lines[0], "Win the level.")
		assert_eq(lines[1], "Keep %d lives." % game.catalog.rules.star2_lives, "the number is rules.json's")
		assert_false(lines[2].is_empty(), "%s has a star 3 line" % id)


func test_star_count() -> void:
	assert_eq(StarText.count(0), 0)
	assert_eq(StarText.count(5), 2)
	assert_eq(StarText.count(7), 3)


# Campaign text.

func test_numbers_come_from_the_campaign_order() -> void:
	var game: GameData = Fx.game()
	assert_eq(CampaignText.number(game, &"r1_l1"), "1-1")
	assert_eq(CampaignText.number(game, &"r1_l6"), "1-6")
	assert_eq(CampaignText.number(game, &"nope"), "")
	assert_eq(CampaignText.next_level(game, &"r1_l1"), &"r1_l2")
	assert_eq(CampaignText.next_level(game, &"r1_l6"), &"", "the last level of a region has no next")
	assert_eq(CampaignText.gates_text(0), "No gates")
	assert_eq(CampaignText.gates_text(1), "1 gate")
	assert_eq(CampaignText.gates_text(3), "3 gates")


# The level list.

func test_the_level_list_opens_levels_in_order_and_shows_the_rest_locked() -> void:
	var game: GameData = Fx.game()
	var progress: Progress = Progress.new()
	var list: LevelSelect = _keep(LevelSelect.new()) as LevelSelect
	list.populate(game, progress, &"")
	assert_eq(list.rows.size(), game.levels.size(), "every level of the campaign is listed")
	assert_false(list.rows[&"r1_l1"].overlay.disabled, "the first level is open")
	assert_true(list.rows[&"r1_l2"].overlay.disabled, "the next is locked until this one is cleared")
	progress.record_level(&"r1_l1", 1)
	list.populate(game, progress, &"")
	assert_false(list.rows[&"r1_l2"].overlay.disabled)
	assert_true(list.rows[&"r1_l3"].overlay.disabled)
	assert_true(_texts(list.rows[&"r1_l3"]).has("Clear level 1-2 first."), "a locked level says why")
	assert_true(_texts(list.rows[&"r1_l1"]).has("1 of 3 stars"))


func test_a_saved_level_says_so_and_a_tap_chooses_it() -> void:
	var game: GameData = Fx.game()
	var list: LevelSelect = _keep(LevelSelect.new()) as LevelSelect
	list.populate(game, Progress.new(), &"r1_l1")
	assert_true(_texts(list.rows[&"r1_l1"]).has("Saved game"))
	var chosen: Array[StringName] = []
	list.level_chosen.connect(func(id: StringName) -> void: chosen.append(id))
	list.rows[&"r1_l1"].tapped.emit()
	assert_eq(chosen, [&"r1_l1"] as Array[StringName])


func test_level_names_are_the_data_names() -> void:
	var game: GameData = Fx.game()
	var list: LevelSelect = _keep(LevelSelect.new()) as LevelSelect
	list.populate(game, Progress.new(), &"")
	for id: StringName in game.levels:
		assert_true(_texts(list.rows[id]).has(game.levels[id].name))
	assert_true(_texts(list).has("Region 1: %s" % game.campaign[0]["name"]))


# The level card.

func test_the_level_card_shows_name_waves_gates_stars_hint_and_difficulty() -> void:
	var game: GameData = Fx.game()
	var level: LevelData = game.levels[&"r1_l2"]
	var progress: Progress = Progress.new()
	progress.record_level(&"r1_l2", 5)
	var card: LevelCard = _keep(LevelCard.new(game, progress, &"r1_l2", false)) as LevelCard
	var texts: PackedStringArray = _texts(card)
	assert_true(texts.has(level.name))
	assert_true(texts.has("%d waves" % level.waves.size()))
	assert_true(texts.has(CampaignText.gates_text(level.gates)))
	assert_true(texts.has(level.hint_text), "the hint is always on the card")
	assert_eq(card.title_label.text, "Level 1-2")
	var lines: PackedStringArray = StarText.lines(level, game.catalog)
	for i: int in 3:
		assert_eq(card.star_sentences[i].text, lines[i])
	assert_true(card.star_icons[0].earned)
	assert_false(card.star_icons[1].earned)
	assert_true(card.star_icons[2].earned)
	assert_true(texts.has("Stars: 2 of 3"))


func test_normal_is_always_the_default_and_the_card_does_not_remember_relaxed() -> void:
	var game: GameData = Fx.game()
	var card: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", false)) as LevelCard
	assert_false(card.relaxed)
	var seen: Array[bool] = []
	card.play_requested.connect(func(relaxed: bool) -> void: seen.append(relaxed))
	card.play_button.tapped.emit()
	card.relaxed_button.tapped.emit()
	assert_true(card.relaxed)
	assert_true(card.difficulty_label.text.begins_with("Relaxed: 40 lives"))
	card.play_button.tapped.emit()
	card.normal_button.tapped.emit()
	card.play_button.tapped.emit()
	assert_eq(seen, [false, true, false] as Array[bool])
	var next_time: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", false)) as LevelCard
	assert_false(next_time.relaxed, "a new card starts on Normal again")
	assert_true(next_time.difficulty_label.text.begins_with("Normal: 20 lives"))


func test_relaxed_numbers_come_from_the_sim() -> void:
	var game: GameData = Fx.game()
	var level: LevelData = game.levels[&"r1_l2"]
	var relaxed: Battle = Battle.create(level, game.catalog, true, [] as Array[Dictionary])
	var card: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l2", false)) as LevelCard
	card.relaxed_button.tapped.emit()
	assert_true(card.difficulty_label.text.contains("%d lives and %d gold" % [relaxed.lives, relaxed.gold]))


func test_a_saved_level_offers_resume_before_start_over() -> void:
	var game: GameData = Fx.game()
	var card: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", true)) as LevelCard
	assert_not_null(card.resume_button)
	assert_eq(card.play_button.text, "Start over")
	var fired: Array[int] = [0]
	card.resume_requested.connect(func() -> void: fired[0] += 1)
	card.resume_button.tapped.emit()
	assert_eq(fired[0], 1)
	var plain: LevelCard = _keep(LevelCard.new(game, Progress.new(), &"r1_l1", false)) as LevelCard
	assert_null(plain.resume_button)
	assert_eq(plain.play_button.text, "Play")


# The end panel.

func _result(won: bool, bits: int, relaxed: bool = false) -> Dictionary:
	return {"won": won, "stars": bits, "lives_left": 17 if won else 0, "waves_cleared": 3, "abandoned": false, "relaxed": relaxed}


func test_a_win_says_which_stars_are_new_earned_or_missed() -> void:
	var game: GameData = Fx.game()
	var panel: EndPanel = _keep(EndPanel.new(game, &"r1_l2", _result(true, 5), 3, &"r1_l3")) as EndPanel
	assert_true(panel.won)
	assert_eq(panel.title_label.text, "Level won")
	assert_eq(panel.star_states[0].text, "Earned", "star 1 was already earned")
	assert_eq(panel.star_states[1].text, "Earned before", "star 2 came from an earlier win")
	assert_eq(panel.star_states[2].text, "New star")
	assert_true(panel.star_icons[1].earned, "a star kept from before still shows")
	assert_not_null(panel.next_button)
	assert_true(_texts(panel).has("Lives left: 17"))


func test_a_win_that_misses_a_star_says_not_earned() -> void:
	var game: GameData = Fx.game()
	var panel: EndPanel = _keep(EndPanel.new(game, &"r1_l2", _result(true, 1), 0, &"r1_l3")) as EndPanel
	assert_eq(panel.star_states[1].text, "Not earned")
	assert_false(panel.star_icons[1].earned)


func test_a_relaxed_win_says_only_the_first_star() -> void:
	var game: GameData = Fx.game()
	var panel: EndPanel = _keep(EndPanel.new(game, &"r1_l2", _result(true, 1, true), 0, &"r1_l3")) as EndPanel
	assert_true(panel.summary_label.text.contains("Relaxed wins earn the first star only."))


func test_a_loss_has_no_stars_and_no_next_level() -> void:
	var game: GameData = Fx.game()
	var panel: EndPanel = _keep(EndPanel.new(game, &"r1_l2", _result(false, 0), 0, &"r1_l3")) as EndPanel
	assert_false(panel.won)
	assert_eq(panel.title_label.text, "Level lost")
	assert_true(panel.star_states.is_empty())
	assert_null(panel.next_button)
	assert_eq(panel.retry_button.text, "Try again")


func test_the_last_level_of_a_region_has_no_next_button() -> void:
	var game: GameData = Fx.game()
	var panel: EndPanel = _keep(EndPanel.new(game, &"r1_l6", _result(true, 7), 0, &"")) as EndPanel
	assert_null(panel.next_button)
	assert_eq(panel.retry_button.theme_type_variation, &"PrimaryButton")


func test_the_end_panel_answers_close_the_panel_first() -> void:
	var game: GameData = Fx.game()
	var panel: EndPanel = _keep(EndPanel.new(game, &"r1_l2", _result(true, 7), 0, &"r1_l3")) as EndPanel
	var order: Array[String] = []
	panel.closed.connect(func() -> void: order.append("closed"))
	panel.next_requested.connect(func() -> void: order.append("next"))
	panel.levels_requested.connect(func() -> void: order.append("levels"))
	panel.next_button.tapped.emit()
	panel.request_close()
	assert_eq(order, ["closed", "next", "closed", "levels"] as Array[String])
