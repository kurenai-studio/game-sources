# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The fixes from the QA review of 2026-10-25: the Info rules, the tower panel under the No Selling
## and tier cap Twists, the silent socket under the No Gates Twist, the path card rows, "Best that
## day" and the About privacy line. No running scene tree.

const Fx: GDScript = preload("res://tests/ui/battle_fixtures.gd")

var spare: Array[Node] = []


func after_each() -> void:
	for node: Node in spare:
		if is_instance_valid(node):
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


func _all(root: Node) -> String:
	return " ".join(_texts(root))


## A battle on a real level with its Twist's effects.
func _twist(id: StringName) -> Battle:
	var level: LevelData = Fx.game().levels[id]
	assert_false(level.twist_effects.is_empty(), "%s has a Twist" % id)
	return Battle.create(level, Fx.game().catalog, false, level.twist_effects)


func _panel(b: Battle) -> TowerPanel:
	var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	panel.setup(b)
	return panel


# m1: Info.

func test_info_holds_the_twist_rules() -> void:
	var text: String = _all(_keep(InfoScreen.new()))
	assert_true(text.contains("Once you have 3 stars on a level, its Twist opens."))
	assert_true(text.contains("same map and the same waves with one rule changed"))
	assert_true(text.contains("no stars of its own"))
	assert_true(text.contains("A win on Normal or Relaxed clears it."))


func test_info_holds_the_targeting_modes() -> void:
	var text: String = _all(_keep(InfoScreen.new()))
	for mode: String in ["First", "Last", "Strong"]:
		assert_true(text.contains(mode), mode)
	assert_true(text.contains("highest maximum health"))
	assert_true(text.contains("even in the middle of a wave"))


func test_info_holds_runs_cards_and_the_daily() -> void:
	var text: String = _all(_keep(InfoScreen.new({"runs_built": true})))
	assert_true(text.contains("A run has 18 waves. The last one is a boss wave."))
	assert_true(text.contains("1 card from 3"))
	assert_true(text.contains("cannot skip it"))
	assert_true(text.contains("Cards come in five kinds."))
	assert_true(text.contains("Risk cards change the next wave and pay a reward."))
	assert_true(text.contains("at most one risk card"))
	assert_true(text.contains("the boss wave is never changed"))
	assert_true(text.contains("A tower perk you unlocked is offered only once every tower in your run has its basic perk."))
	assert_true(text.contains("always Normal and uses every card"))
	assert_true(text.contains("the day's best"))
	assert_true(text.contains("Your streak counts days in a row"))


func test_info_leaves_the_run_rules_out_until_runs_are_built() -> void:
	var text: String = _all(_keep(InfoScreen.new({"runs_built": false})))
	assert_false(text.contains("A run has 18 waves"))
	assert_true(text.contains("Once you have 3 stars"), "Twists and targeting are always there")


func test_info_new_sections_keep_the_plain_style_and_name_nothing() -> void:
	var info: InfoScreen = _keep(InfoScreen.new({"runs_built": true})) as InfoScreen
	var all: String = _all(info).to_lower()
	for word: String in ["sling", "pebbles", "pumpkin", "lullaby", "longbow", "firework", "bakery", "scamp", "pip", "skitter", "flitter", "grumblesack", "ironshell", "old tusk", "moon moth", "crowded night", "gold purse"]:
		assert_false(all.contains(word), "Info must not name %s" % word)
	for text: String in _texts(info):
		assert_false(text.contains("—") or text.contains("–") or text.contains("--"), text)
	var titles: PackedStringArray = _texts(info)
	for title: String in ["Targeting", "Twists", "How a run goes", "Cards", "The daily"]:
		assert_true(titles.has(title), title)


# m2: No Selling.

func test_no_selling_twist_shows_that_towers_cannot_be_sold() -> void:
	var b: Battle = _twist(&"r4_l4")
	var cell: Vector2i = b.level.spots[0]
	assert_eq(b.place_tower(cell, &"sling_post"), Battle.DONE)
	for wide: bool in [false, true]:
		var panel: TowerPanel = _panel(b)
		panel.set_wide(wide)
		panel.show_tower(cell)
		assert_null(panel.sell_button, "no Sell button")
		assert_null(panel.refund_label, "no refund sentence")
		var text: String = _all(panel)
		assert_true(text.contains("Towers cannot be sold on this level."))
		assert_false(text.contains("Sell value") or text.contains("Sell for") or text.contains("Full refund"), text)


func test_selling_still_works_on_a_level_without_the_twist() -> void:
	var b: Battle = Fx.battle(&"r4_l4")
	var cell: Vector2i = b.level.spots[0]
	b.place_tower(cell, &"sling_post")
	var panel: TowerPanel = _panel(b)
	panel.show_tower(cell)
	assert_not_null(panel.sell_button)
	assert_true(panel.sell_button.text.begins_with("Sell for"))


func test_a_sell_call_under_no_selling_arms_nothing_and_keeps_the_tower() -> void:
	var b: Battle = _twist(&"r4_l4")
	var cell: Vector2i = b.level.spots[0]
	b.place_tower(cell, &"sling_post")
	var panel: TowerPanel = _panel(b)
	var seen: Array[StringName] = []
	panel.refused.connect(func(reason: StringName, _text: String) -> void: seen.append(reason))
	panel.show_tower(cell)
	panel.sell()
	assert_false(panel.sell_armed)
	assert_not_null(b.tower_at(cell))
	assert_eq(seen, [&"no_selling"] as Array[StringName])


# m3: tier cap.

func test_tier_cap_twist_shows_the_cap_instead_of_tier_3_paths() -> void:
	var b: Battle = _twist(&"r3_l5")
	b.gold = 2000
	var cell: Vector2i = b.level.spots[0]
	assert_eq(b.place_tower(cell, &"sling_post"), Battle.DONE)
	assert_eq(b.upgrade_tower(cell), Battle.DONE)
	assert_eq(b.upgrade_options(cell)[0]["refusal"], &"tier_cap")
	var panel: TowerPanel = _panel(b)
	panel.show_tower(cell)
	assert_true(panel.path_cards.is_empty(), "no tier 3 paths are offered")
	assert_null(panel.confirm_button)
	var text: String = _all(panel)
	assert_true(text.contains("At the tier cap. This level stops towers at tier 2."), text)
	assert_false(text.contains("Pick a path"), text)


func test_without_the_cap_the_paths_are_offered() -> void:
	var b: Battle = Fx.battle(&"r3_l5")
	b.gold = 2000
	var cell: Vector2i = b.level.spots[0]
	b.place_tower(cell, &"sling_post")
	b.upgrade_tower(cell)
	var panel: TowerPanel = _panel(b)
	panel.show_tower(cell)
	assert_eq(panel.path_cards.size(), 2)


func test_the_cap_does_not_hide_a_tier_2_upgrade() -> void:
	var b: Battle = _twist(&"r3_l5")
	b.gold = 2000
	var cell: Vector2i = b.level.spots[0]
	b.place_tower(cell, &"sling_post")
	var panel: TowerPanel = _panel(b)
	panel.show_tower(cell)
	assert_not_null(panel.upgrade_button, "a tier 1 tower can still go to tier 2")


# p1: No Gates.

func test_a_socket_tap_under_no_gates_says_nothing() -> void:
	var b: Battle = _twist(&"r2_l4")
	assert_eq(b.gates_in_hand, 0)
	var screen: BattleScreen = BattleScreen.new()
	spare.append(screen)
	screen.setup(b, null, Progress.new())
	screen.tap_socket(b.level.sockets[0])
	assert_eq(screen.gate_tray.feedback_text(), "")
	assert_true(b.gates.is_empty())


# p2: path card rows.

func test_a_slow_tower_path_card_says_affects_with_the_panels_words() -> void:
	var before: Dictionary = {"hits_ground": true, "hits_air": false, "slow_pct": 35, "slow_ms": 1000, "reach": 200}
	var after: Dictionary = {"hits_ground": true, "hits_air": true, "slow_pct": 35, "slow_ms": 1000, "reach": 200}
	var rows: Array[Dictionary] = BattleText.change_rows(before, after, &"slow")
	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["label"], "Affects")
	assert_eq(rows[0]["before"], "Walkers")
	assert_eq(rows[0]["after"], "Walkers and flyers")


func test_every_real_bell_path_uses_affects() -> void:
	var catalog: Catalog = Fx.game().catalog
	for id: StringName in catalog.tower_ids():
		var type: TowerType = catalog.tower(id)
		if type.kind != &"slow":
			continue
		for spec: int in [0, 1]:
			for row: Dictionary in BattleText.change_rows(type.stats(2, -1).numbers(), type.stats(3, spec).numbers(), type.kind):
				assert_ne(row["label"], "Hits", "%s path %d" % [id, spec])
				assert_ne(row["after"], "Both")


func test_a_one_target_path_card_says_none_not_zero_tiles() -> void:
	var catalog: Catalog = Fx.game().catalog
	var type: TowerType = catalog.tower(&"firework_tower")
	var any_none: bool = false
	for spec: int in [0, 1]:
		for row: Dictionary in BattleText.change_rows(type.stats(2, -1).numbers(), type.stats(3, spec).numbers(), type.kind):
			assert_false(str(row["after"]).begins_with("0 tiles") or str(row["before"]).begins_with("0 tiles"))
			if row["label"] == "Splash" and row["after"] == "none":
				any_none = true
	assert_true(any_none, "one path drops the splash and says none")
	var rows: Array[Dictionary] = BattleText.change_rows({"splash": 75}, {"splash": 0}, &"attack")
	assert_eq(rows[0]["before"], "0.75 tiles")
	assert_eq(rows[0]["after"], "none")


# p4: Best that day.

func test_the_daily_end_says_best_that_day_when_the_day_is_not_today() -> void:
	var game: GameData = Fx.game()
	var result: Dictionary = {"won": false, "waves": 9, "lives": 0}
	var best: Dictionary = {"won": false, "waves": 9, "lives": 0}
	var same: RunEndPanel = _keep(RunEndPanel.new(game, result, false, "2026-10-24", best, 1, "2026-10-24")) as RunEndPanel
	assert_eq(same.best_label.text, "Best today: Lost with 9 of 18 waves cleared.")
	var late: RunEndPanel = _keep(RunEndPanel.new(game, result, false, "2026-10-24", best, 1, "2026-10-25")) as RunEndPanel
	assert_eq(late.best_label.text, "Best that day: Lost with 9 of 18 waves cleared.")
	var unknown: RunEndPanel = _keep(RunEndPanel.new(game, result, false, "2026-10-24", best, 1)) as RunEndPanel
	assert_eq(unknown.best_label.text, "Best today: Lost with 9 of 18 waves cleared.")


# p5: About.

func test_about_names_all_three_buttons_that_hand_over_an_address() -> void:
	var text: String = _all(_keep(AboutScreen.new()))
	assert_true(text.contains("Three buttons hand a fixed address to another app on your phone"))
	assert_true(text.contains("Buy me a coffee"))
	assert_true(text.contains("the source code link"))
	assert_true(text.contains("Send feedback opens a message in your email app"))
	assert_true(text.contains("The app itself sends nothing."))
