# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Step U5 (docs/ARCHITECTURE.md 14.11, part 2): creature panels with every status, the Info
## guide with the new towers, creatures, bosses and map features read from the data, and tiers
## in run and daily starts with the Daily button's regions line. Also two small fixes from the
## QA round: the run card over a saved run, and the Daily button beside a saved daily. The new
## content is not in data/stats/ until region 5, so these tests use the sim's test catalog
## (tests/sim/fixtures/creature_fixtures.gd) and stand-in tiers on the real campaign.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")
const UiFx: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const FlowFx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "u5"
const DAY_1: Dictionary = {"year": 2026, "month": 10, "day": 24}
const DAY_2: Dictionary = {"year": 2026, "month": 10, "day": 25}

var spare: Array[Node] = []
var apps: Array[App] = []


func after_each() -> void:
	for node: Node in spare:
		if is_instance_valid(node):
			node.free()
	spare.clear()
	for made: App in apps:
		made.free()
	apps.clear()
	FlowFx.wipe(TAG)


func _keep(node: Node) -> Node:
	spare.append(node)
	return node


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


func _text_of(root: Node) -> String:
	return " ".join(_texts(root))


## Only the labels that show.
func _shown_text(root: Node) -> String:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		if (node as Label).is_visible_in_tree() or (node as Label).visible:
			out.append((node as Label).text)
	return " ".join(out)


# Creature panels: every status.

func _battle_with(type: StringName) -> Battle:
	var b: Battle = Cx.battle(Fx.LINE_GRID, [{"groups": [Fx.group(String(type), 1)]}])
	b.start_next_wave()
	Fx.steps(b, 3)
	return b


func _panel(b: Battle) -> EnemyPanel:
	var panel: EnemyPanel = _keep(EnemyPanel.new()) as EnemyPanel
	panel.setup(b)
	panel.show_enemy(b.enemies[0].id)
	return panel


func test_status_lines_are_empty_with_no_status() -> void:
	var b: Battle = _battle_with(&"scamp")
	assert_eq(BattleText.status_lines(b.enemy_numbers(b.enemies[0].id)).size(), 0)


func test_every_status_has_its_words() -> void:
	var base: Dictionary = {"max_health": 100}
	var cases: Array = [
		[{"fright_pct": 25, "fright_ms": 1000}, "Frightened: takes 25% more damage for 1.0 s"],
		[{"low_ms": 2500}, "Low: every tower can hit it for 2.5 s"],
		[{"hidden": true}, "Hidden: no tower can aim at it"],
		[{"out_of_reach": true}, "Out of reach: no tower can hit it"],
		[{"awake": true}, "Awake: it cannot be slowed"],
		[{"nap_ms": 1800}, "Napping: 1.8 s left. Health shows what it wakes with."],
	]
	for item: Array in cases:
		var numbers: Dictionary = base.duplicate()
		numbers.merge(item[0])
		var lines: PackedStringArray = BattleText.status_lines(numbers)
		assert_eq(lines.size(), 1, str(item[1]))
		assert_eq(lines[0], item[1])
	var dug: PackedStringArray = BattleText.status_lines({"out_of_reach": true}, {"dig_ms": 1500})
	assert_eq(dug, PackedStringArray(["Dug under: out of reach for 1.5 s"]), "a dig says why it is out of reach")
	var grown: PackedStringArray = BattleText.status_lines({"max_health": 90}, {"grown_from": 40})
	assert_eq(grown, PackedStringArray(["Grown: max health 90, started at 40"]))
	assert_eq(BattleText.status_lines({"max_health": 40}, {"grown_from": 40}).size(), 0, "not grown yet")
	var napping_in_a_tunnel: PackedStringArray = BattleText.status_lines({"nap_ms": 500, "out_of_reach": true})
	assert_eq(napping_in_a_tunnel.size(), 1, "a nap is its own status, stricter than out of reach")


func test_no_status_line_has_a_dash_pair() -> void:
	var numbers: Dictionary = {"slow_pct": 30, "slow_ms": 1000, "fright_pct": 25, "fright_ms": 1000, "bubble": true,
		"breaking_ms": 1000, "low_ms": 1000, "nap_ms": 1000, "hidden": true, "awake": true, "max_health": 90}
	for line: String in BattleText.status_lines(numbers, {"grown_from": 40}):
		assert_false(line.contains("—") or line.contains("--"), line)


func test_the_creature_panel_shows_each_status_from_the_numbers() -> void:
	var b: Battle = _battle_with(&"mossbud")
	var enemy: EnemyState = b.enemies[0]
	var panel: EnemyPanel = _panel(b)
	enemy.fright_pct = 25
	enemy.fright_ticks = 20
	enemy.hidden = true
	enemy.awake = true
	enemy.out_of_reach = true
	panel.refresh()
	var words: String = _shown_text(panel.status_box)
	assert_true(words.contains("Frightened: takes 25% more damage for 1.0 s"), words)
	assert_true(words.contains("Hidden"), words)
	assert_true(words.contains("Awake"), words)
	assert_true(words.contains("Out of reach"), words)
	enemy.fright_pct = 0
	enemy.fright_ticks = 0
	enemy.hidden = false
	enemy.awake = false
	enemy.out_of_reach = false
	panel.refresh()
	assert_eq(_shown_text(panel.status_box).strip_edges(), "", "the lines go when the statuses do")


func test_the_creature_panel_shows_a_low_flyer() -> void:
	var b: Battle = _battle_with(&"flitter")
	b.enemies[0].low_ticks = 30
	var panel: EnemyPanel = _panel(b)
	assert_true(_shown_text(panel.status_box).contains("Low: every tower can hit it for 1.5 s"), _shown_text(panel.status_box))


func test_the_creature_panel_shows_a_nap_with_its_time_and_the_wake_health() -> void:
	var b: Battle = _battle_with(&"sleepyhead")
	var enemy: EnemyState = b.enemies[0]
	enemy.health = 45
	enemy.napped = true
	enemy.nap_ticks = 24
	var panel: EnemyPanel = _panel(b)
	assert_true(_shown_text(panel.status_box).contains("Napping: 1.2 s left"), _shown_text(panel.status_box))
	assert_eq(panel.health_label.text, "Health 45 / %d" % enemy.max_health, "health is the value it wakes with")
	enemy.nap_ticks = 0
	panel.refresh()
	assert_false(_shown_text(panel.status_box).contains("Napping"))


func test_the_creature_panel_shows_a_dig_and_growth() -> void:
	var b: Battle = _battle_with(&"burrowbelly")
	var digger: EnemyState = b.enemies[0]
	digger.dig_ticks = 30
	digger.out_of_reach = true
	var panel: EnemyPanel = _panel(b)
	assert_true(_shown_text(panel.status_box).contains("Dug under: out of reach for 1.5 s"), _shown_text(panel.status_box))
	var g: Battle = _battle_with(&"snowroller")
	var roller: EnemyState = g.enemies[0]
	var before: PackedStringArray = BattleText.status_lines(g.enemy_numbers(roller.id), {"grown_from": roller.start_health})
	assert_eq(before.size(), 0, "a Snowroller that has not grown says nothing")
	roller.max_health += 20
	roller.health += 20
	var grown_panel: EnemyPanel = _panel(g)
	assert_true(_shown_text(grown_panel.status_box).contains("Grown: max health %d, started at %d" % [roller.max_health, roller.start_health]), _shown_text(grown_panel.status_box))
	assert_eq(grown_panel.health_label.text, "Health %d / %d" % [roller.health, roller.max_health], "max health is the grown one")


# Info reads the data.

## A game whose catalog has every new piece and whose levels hold the features in `grids`.
func _fixture_game(grids: Array[Array]) -> GameData:
	var game: GameData = GameData.new()
	game.catalog = Cx.catalog()
	for i: int in grids.size():
		var id: String = "fx_%d" % i
		var level: LevelData = Fx.level(grids[i], [{"groups": [Fx.group("scamp", 1)]}], {"id": id}, game.catalog)
		assert_not_null(level, "fixture level %d is valid" % i)
		game.levels[StringName(id)] = level
	return game


## The straight road map with some of its rows replaced: pairs of [row, text].
func _with(row: int, text: String, row2: int = -1, text2: String = "") -> Array:
	var grid: Array = Fx.LINE_GRID.duplicate()
	grid[row] = text
	if row2 >= 0:
		grid[row2] = text2
	return grid


func test_info_content_reads_every_tower_creature_and_boss_from_the_catalog() -> void:
	var game: GameData = _fixture_game([] as Array[Array])
	var content: InfoContent = InfoContent.from_game(game)
	assert_eq(content.towers, game.catalog.tower_ids())
	assert_eq(content.towers.size(), 10, "the six and the four new towers")
	for id: StringName in [&"mossbud", &"hootling", &"snowroller"]:
		assert_true(content.creatures.has(id), "%s is a creature" % id)
	for id: StringName in [&"burrowbelly", &"old_hayrick", &"snowsnore", &"glimmertoad", &"grumblesack"]:
		assert_true(content.bosses.has(id), "%s is a boss" % id)
		assert_false(content.creatures.has(id))
	assert_eq(content.pictures().size(), game.catalog.enemy_ids().size(), "nothing left out, nothing added")
	assert_eq(content.features.size(), 0, "no level uses a feature")


func test_info_content_lists_only_the_features_the_levels_use() -> void:
	var grids: Array[Array] = [_with(2, "...T..."), _with(4, "...v...")]
	var content: InfoContent = InfoContent.from_game(_fixture_game(grids))
	assert_eq(content.features, [&"tunnel", &"slide"] as Array[StringName], "in the order of the regions")
	var all: Array[Array] = [_with(2, "...T..."), _with(3, "...X..."), _with(4, "...v..."), _with(2, "...P...", 5, "...P...")]
	var every: InfoContent = InfoContent.from_game(_fixture_game(all))
	assert_eq(every.features, InfoArt.FEATURE_IDS)


func test_info_content_counts_the_tier_grids_of_run_json() -> void:
	var game: GameData = _fixture_game([] as Array[Array])
	game.run = RunData.new()
	game.run.tiers = [{"level": &"r5_l6", "towers": [], "creatures": [], "bosses": [], "grid": "T"}] as Array[Dictionary]
	assert_eq(InfoContent.from_game(game).features, [&"tunnel"] as Array[StringName])


func test_info_content_of_nothing_is_empty() -> void:
	var content: InfoContent = InfoContent.from_game(null)
	assert_eq(content.towers.size() + content.pictures().size() + content.features.size(), 0)
	assert_eq(InfoContent.from_game(GameData.new()).towers.size(), 0)


func _arts(info: InfoScreen) -> Dictionary:
	var out: Dictionary = {}
	for node: Node in info.find_children("*", "InfoArt", true, false):
		out[(node as InfoArt).kind] = node
	return out


func test_info_draws_the_new_towers_creatures_bosses_and_features() -> void:
	var grids: Array[Array] = [_with(2, "...T..."), _with(3, "...X..."), _with(4, "...v..."), _with(2, "...P...", 5, "...P...")]
	var game: GameData = _fixture_game(grids)
	var names: Dictionary = {}
	for id: StringName in game.catalog.tower_ids():
		names[id] = game.catalog.tower(id).name
	for id: StringName in game.catalog.enemy_ids():
		names[id] = game.catalog.enemy(id).name
	var info: InfoScreen = _keep(InfoScreen.new({}, names, InfoContent.from_game(game))) as InfoScreen
	var arts: Dictionary = _arts(info)
	var towers: InfoArt = arts[&"towers"]
	assert_eq(towers.ids.size(), 10)
	assert_true(towers.ids.has(&"moth_lantern"))
	assert_eq(towers.captions.size(), 10)
	assert_true(towers.captions.has("Scarecrow"))
	var creatures: InfoArt = arts[&"creatures"]
	assert_eq(creatures.ids.size(), game.catalog.enemy_ids().size())
	assert_true(creatures.ids.has(&"glimmertoad") and creatures.ids.has(&"yawner"))
	assert_eq(creatures.captions.size(), creatures.ids.size())
	var features: InfoArt = arts[&"features"]
	assert_eq(features.ids, InfoArt.FEATURE_IDS)
	assert_eq(features.captions, PackedStringArray(["Tunnel", "Bridge", "Ice slide", "Hollow stumps"]))
	var text: String = _text_of(info)
	assert_true(text.contains("Map features"))
	for feature: StringName in InfoArt.FEATURE_IDS:
		assert_true(text.contains(InfoScreen.FEATURE_TEXT[feature]), "%s is explained" % feature)
	for line: String in _texts(info):
		assert_false(line.contains("—") or line.contains("--"), "no em dashes or double hyphens")


func test_info_leaves_out_features_no_level_uses_and_pictures_with_no_content() -> void:
	var grids: Array[Array] = [_with(2, "...T...")]
	var info: InfoScreen = _keep(InfoScreen.new({}, {}, InfoContent.from_game(_fixture_game(grids)))) as InfoScreen
	var text: String = _text_of(info)
	assert_true(text.contains(InfoScreen.FEATURE_TEXT[&"tunnel"]))
	for feature: StringName in [&"bridge", &"slide", &"stumps"]:
		assert_false(text.contains(InfoScreen.FEATURE_TEXT[feature]), "%s is not in the game yet" % feature)
	assert_eq((_arts(info)[&"features"] as InfoArt).ids, [&"tunnel"] as Array[StringName])
	var bare: InfoScreen = _keep(InfoScreen.new()) as InfoScreen
	var kinds: Dictionary = _arts(bare)
	assert_false(kinds.has(&"towers") or kinds.has(&"creatures") or kinds.has(&"features"), "no content, no list pictures")
	assert_false(_text_of(bare).contains("Map features"))


func test_info_pictures_and_names_fit_at_both_widths() -> void:
	var grids: Array[Array] = [_with(2, "...T..."), _with(3, "...X..."), _with(4, "...v..."), _with(2, "...P...", 5, "...P...")]
	var game: GameData = _fixture_game(grids)
	var names: Dictionary = {}
	for id: StringName in game.catalog.tower_ids():
		names[id] = game.catalog.tower(id).name
	for id: StringName in game.catalog.enemy_ids():
		names[id] = game.catalog.enemy(id).name
	var info: InfoScreen = _keep(InfoScreen.new({}, names, InfoContent.from_game(game))) as InfoScreen
	var font: Font = UiTheme.font(UiTheme.WEIGHT_BOLD)
	var arts: Dictionary = _arts(info)
	for kind: StringName in [&"towers", &"creatures", &"features"]:
		var art: InfoArt = arts[kind]
		for width: float in [900.0, 1040.0, 640.0]:
			art.fit_width(width)
			assert_true(art.custom_minimum_size.y > 0.0, "%s has height at %d px" % [kind, width])
			var g: Dictionary = art._grid(width)
			var lines: Array = g["lines"]
			assert_eq(lines.size(), art.captions.size())
			for caption: PackedStringArray in lines:
				for line: String in caption:
					assert_true(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, InfoArt.CAPTION_SIZE).x <= float(g["slot"]), "'%s' fits at %d px" % [line, width])


func test_the_info_screen_never_reads_the_silhouette_lists() -> void:
	for file_name: String in DirAccess.get_files_at("res://src/ui"):
		if file_name.get_extension() != "gd":
			continue
		var source: String = FileAccess.get_file_as_string("res://src/ui/" + file_name)
		for list: String in ["Silhouettes.TOWERS", "Silhouettes.CREATURES", "Silhouettes.BOSSES"]:
			assert_false(source.contains(list), "%s does not read %s" % [file_name, list])


# Tiers in run and daily starts.

## The real data with run.json tiers on the boss levels of regions 3 and 4, standing in for regions 5 and 6.
func _tier_game() -> GameData:
	var game: GameData = GameData.load_from("res://data")
	var list: Array[Dictionary] = []
	for level: StringName in [&"r3_l6", &"r4_l6"]:
		list.append({"level": level, "towers": [] as Array[StringName], "creatures": [] as Array[StringName],
			"bosses": [] as Array[StringName], "grid": ""})
	game.run.tiers = list
	return game


## The real data with no tiers at all: what run.json held before region 5. Tests of the "no tiers"
## case use this, so they hold whatever tiers the real file gains.
func _no_tier_game() -> GameData:
	var game: GameData = GameData.load_from("res://data")
	game.run.tiers = [] as Array[Dictionary]
	return game


func _app(day: Dictionary = DAY_1, cleared: Array[StringName] = []) -> App:
	var made: App = FlowFx.run_app(TAG, true, day)
	apps.append(made)
	made.game = _tier_game()
	for id: StringName in cleared:
		made.progress.record_level(id, 1)
	return made


func _start_run(made: App, relaxed: bool = false) -> void:
	made.open_mode()
	made.roguelite_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_not_null(card)
	if relaxed:
		card.relaxed_button.tapped.emit()
	card.start_button.tapped.emit()


func _start_daily(made: App) -> void:
	made.open_mode()
	made.daily_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_not_null(card)
	card.start_button.tapped.emit()


func test_a_run_starts_at_the_players_tier() -> void:
	for pair: Array in [[[] as Array[StringName], 0], [[&"r3_l6"] as Array[StringName], 1], [[&"r3_l6", &"r4_l6"] as Array[StringName], 2]]:
		var made: App = _app(DAY_1, pair[0])
		assert_eq(made.progress.tier(made.game), pair[1])
		_start_run(made)
		var run: RunSession = made.saved_game(SavedGame.RUN).run
		assert_eq(run.tier, pair[1], "the run keeps the player's tier")
		assert_eq(run.to_data()["tier"], pair[1], "and saves it")


func test_a_cleared_boss_level_alone_does_not_count_twice() -> void:
	var made: App = _app(DAY_1, [&"r4_l6"] as Array[StringName])
	assert_eq(made.progress.tier(made.game), 1, "the count of cleared tier levels, as Progress says")
	_start_run(made)
	assert_eq(made.saved_game(SavedGame.RUN).run.tier, 1)


func test_the_daily_fixes_its_tier_for_the_day() -> void:
	var made: App = _app(DAY_1, [&"r3_l6"] as Array[StringName])
	_start_daily(made)
	var saved: SavedGame = made.saved_game(SavedGame.DAILY)
	assert_eq(saved.run.tier, 1)
	made._record_run(saved.run)
	assert_eq(made.daily_record.tier, 1, "record_finish gets the run's tier")
	made.progress.record_level(&"r4_l6", 1)
	assert_eq(made.progress.tier(made.game), 2)
	assert_eq(made.daily_tier(), 1, "a tier earned later that day joins tomorrow's daily")
	made.date_source = func() -> Dictionary: return DAY_2
	assert_eq(made.daily_tier(), 2, "tomorrow's daily uses it")
	made._end_saved(SavedGame.DAILY)
	made._leave_to_front_door()
	_start_daily(made)
	assert_eq(made.saved_game(SavedGame.DAILY).run.tier, 2)
	made._record_run(made.saved_game(SavedGame.DAILY).run)
	assert_eq(made.daily_record.tier, 2, "a later day replaces the tier")


func test_a_saved_daily_keeps_its_tier_for_the_buttons() -> void:
	var made: App = _app(DAY_1)
	_start_daily(made)
	assert_eq(made.saved_game(SavedGame.DAILY).run.tier, 0)
	made.progress.record_level(&"r3_l6", 1)
	assert_eq(made.daily_tier(), 0, "the daily in progress keeps its tier")
	assert_eq(made.daily_regions(), "Regions 1 to 2")


func test_the_daily_pool_is_the_cards_of_its_tier() -> void:
	var made: App = _app(DAY_1, [&"r3_l6", &"r4_l6"] as Array[StringName])
	_start_daily(made)
	var run: RunSession = made.saved_game(SavedGame.DAILY).run
	assert_eq(run.tier, 2)
	for id: StringName in run.pool:
		assert_true(made.game.run.card_ids(2).has(id), "%s is a card of the daily's tier" % id)


func test_the_daily_tier_never_passes_the_tiers_run_json_has() -> void:
	var made: App = _app(DAY_1, [&"r3_l6", &"r4_l6"] as Array[StringName])
	made.daily_record.record_finish("2026-10-24", {"won": true, "waves": 18, "lives": 3}, 4)
	assert_eq(made.daily_tier(), 2, "clamped to the two tiers of the stand-in data")
	var plain: App = FlowFx.run_app(TAG, true, DAY_1)
	apps.append(plain)
	assert_eq(plain.daily_tier(), 0, "no tiers in the real data")


# The Daily button and card name the regions.

func test_the_regions_line_follows_the_contract() -> void:
	var game: GameData = _tier_game()
	assert_eq(RunCard.regions_last(game, 0), 2, "tier 0: one less than the region of tier 1's level")
	assert_eq(RunCard.regions_last(game, 1), 3)
	assert_eq(RunCard.regions_last(game, 2), 4)
	assert_eq(RunCard.regions_last(game, 9), 4, "never above the tiers there are")
	assert_eq(RunCard.regions_text(6), "Regions 1 to 6")
	var real: GameData = _no_tier_game()
	assert_eq(RunCard.regions_last(real, 0), real.campaign.size(), "no tiers: every region there is")
	assert_eq(RunCard.regions_text(0), "Regions 1 to 1", "never below one region")


## The line with the tier 1 that the real run.json holds (region 5's level 6): one region less at
## tier 0, the whole region at tier 1.
func test_the_regions_line_with_the_real_tier_1() -> void:
	var real: GameData = GameData.load_from("res://data")
	if real.run.tiers.is_empty():
		return
	var level: StringName = real.run.tiers[0]["level"]
	var region: int = 0
	for r: int in real.campaign.size():
		if (real.campaign[r]["levels"] as Array).has(level):
			region = r + 1
	assert_true(region > 1, "tier 1's level is in the campaign, past region 1")
	assert_eq(RunCard.regions_last(real, 0), region - 1)
	assert_eq(RunCard.regions_last(real, 1), region)
	assert_eq(RunCard.regions_last(real, 9), RunCard.regions_last(real, real.run.tiers.size()), "never above the tiers there are")
	if level == &"r5_l6":
		assert_eq(RunCard.regions_text(RunCard.regions_last(real, 0)), "Regions 1 to 4")
		assert_eq(RunCard.regions_text(RunCard.regions_last(real, 1)), "Regions 1 to 5")


func test_the_daily_button_says_which_regions_it_covers() -> void:
	var made: App = _app(DAY_1)
	made.open_mode()
	var mode: ModeScreen = made.current_screen() as ModeScreen
	assert_true(_text_of(mode.daily_button).contains("Regions 1 to 2. One run a day. The same for everyone."), _text_of(mode.daily_button))
	made.progress.record_level(&"r3_l6", 1)
	made.progress.record_level(&"r4_l6", 1)
	made.pop_screen()
	made.open_mode()
	mode = made.current_screen() as ModeScreen
	assert_true(_text_of(mode.daily_button).contains("Regions 1 to 4. "), _text_of(mode.daily_button))
	made.daily_record.record_finish("2026-10-24", {"won": true, "waves": 18, "lives": 14}, 2)
	made.pop_screen()
	made.open_mode()
	mode = made.current_screen() as ModeScreen
	assert_true(_text_of(mode.daily_button).contains("Regions 1 to 4. Best today: Won with 14 lives left."), _text_of(mode.daily_button))


func test_the_daily_button_with_no_tiers_in_the_data_names_every_region() -> void:
	var made: App = FlowFx.run_app(TAG, true, DAY_1)
	apps.append(made)
	made.game = _no_tier_game()
	made.open_mode()
	var line: String = _text_of((made.current_screen() as ModeScreen).daily_button)
	assert_true(line.contains("Regions 1 to %d." % made.game.campaign.size()), line)


func test_a_locked_daily_button_says_nothing_of_regions() -> void:
	var made: App = FlowFx.app(TAG)
	apps.append(made)
	made.open_mode()
	var line: String = _text_of((made.current_screen() as ModeScreen).daily_button)
	assert_false(line.contains("Regions"), line)


func test_the_daily_card_names_the_regions() -> void:
	var made: App = _app(DAY_1, [&"r3_l6"] as Array[StringName])
	made.open_mode()
	made.daily_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_not_null(card.regions_label)
	assert_eq(card.regions_label.text, "Regions 1 to 3.")
	var run: RunCard = _keep(RunCard.new(made.game, made.game.run)) as RunCard
	assert_null(run.regions_label, "a normal run names no regions")


# QA L1: the run card over a saved run.

func test_the_run_card_over_a_saved_run_says_what_the_picker_is_for() -> void:
	var game: GameData = UiFx.game()
	var fresh: RunCard = _keep(RunCard.new(game, game.run)) as RunCard
	assert_eq(fresh.difficulty_heading.text, "Difficulty")
	assert_null(fresh.saved_difficulty_label)
	var normal: RunCard = _keep(RunCard.new(game, game.run, false, "", {}, 0, "Your saved run is on wave 4 of 18.", false)) as RunCard
	assert_eq(normal.difficulty_heading.text, "Difficulty if you start over")
	assert_eq(normal.saved_difficulty_label.text, "Your saved run is on Normal.")
	var easy: RunCard = _keep(RunCard.new(game, game.run, false, "", {}, 0, "Your saved run is on wave 4 of 18.", true)) as RunCard
	assert_eq(easy.saved_difficulty_label.text, "Your saved run is on Relaxed.")
	assert_eq(easy.start_button.text, "Start over")
	assert_false(easy.relaxed, "the picker still opens on Normal")


func test_the_daily_card_over_a_saved_daily_has_no_picker_text() -> void:
	var game: GameData = UiFx.game()
	var card: RunCard = _keep(RunCard.new(game, game.run, true, "2026-10-24", {}, 0, "Your saved daily is on wave 2 of 18.")) as RunCard
	assert_null(card.saved_difficulty_label, "the daily is always Normal")
	assert_null(card.difficulty_heading)


func test_the_app_tells_the_run_card_which_difficulty_is_saved() -> void:
	var made: App = _app(DAY_1)
	_start_run(made, true)
	made.battle_screen().pause()
	made.battle_screen().left.emit()
	made.open_mode()
	made.roguelite_requested.emit()
	var card: RunCard = made.current_screen() as RunCard
	assert_eq(card.saved_difficulty_label.text, "Your saved run is on Relaxed.")
	assert_eq(card.difficulty_heading.text, "Difficulty if you start over")


# QA L2: the Daily button beside a saved daily.

func test_the_daily_button_agrees_with_the_continue_card() -> void:
	assert_eq(ModeScreen.daily_detail({}, 0, true), "No result yet today.")
	assert_eq(ModeScreen.daily_detail({}, 3, true), "No result yet today. Streak: 3 days.")
	assert_eq(ModeScreen.daily_detail({}, 3, false), "Not played today. Streak: 3 days.")
	assert_eq(ModeScreen.daily_detail({}, 0, false), "")
	assert_eq(ModeScreen.daily_detail({"won": true, "waves": 18, "lives": 14}, 1, true), "Best today: Won with 14 lives left. Streak: 1 day.", "a best still shows")


func test_a_saved_daily_changes_the_daily_buttons_line() -> void:
	var made: App = _app(DAY_1)
	made.daily_record.record_finish("2026-10-23", {"won": true, "waves": 18, "lives": 9})
	assert_eq(made.daily_detail(), "Not played today. Streak: 1 day.")
	_start_daily(made)
	made.battle_screen().pause()
	made.battle_screen().left.emit()
	assert_eq(made.daily_detail(), "No result yet today. Streak: 1 day.")
	made.open_mode()
	var mode: ModeScreen = made.current_screen() as ModeScreen
	assert_true(_text_of(mode.continue_button).contains("Daily 2026-10-24"))
	assert_true(_text_of(mode.daily_button).contains("No result yet today."), _text_of(mode.daily_button))
	assert_false(_text_of(mode.daily_button).contains("Not played"))
	made.date_source = func() -> Dictionary: return DAY_2
	assert_eq(made.daily_detail(), "", "a daily saved from another day is not today's, and the streak has lapsed")
