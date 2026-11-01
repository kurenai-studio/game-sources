# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Step U4 (docs/ARCHITECTURE.md 14.11, part 1): the region reaching the map, the build
## panel with up to 10 towers, and the tower panels for pulses, lines, lures, frights and
## dozing. The four new towers are not in data/stats/ yet, so these tests use the sim's test
## catalog (tests/sim/fixtures/tower_fixtures.gd). Touch sizes and screenshots at both Fold5
## sizes are in tests/ui/real_tree_u4.gd and tests/ui/shots_u4.gd.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const UiFx: GDScript = preload("res://tests/ui/battle_fixtures.gd")
const FlowFx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const NEW_TOWERS: Array[StringName] = [&"bramble_cottage", &"scarecrow", &"snow_fort", &"moth_lantern"]
const TAG: String = "u4"


## A tower panel whose tower dozes for `doze_ms`, until S10b gives the sim a doze time.
class DozyPanel extends TowerPanel:
	var doze_ms: int = 0

	func _numbers() -> Dictionary:
		var numbers: Dictionary = super()
		numbers["doze_ms"] = doze_ms
		return numbers


var spare: Array[Node] = []


func after_each() -> void:
	for node: Node in spare:
		if is_instance_valid(node):
			node.free()
	spare.clear()
	FlowFx.wipe(TAG)


func _keep(node: Node) -> Node:
	spare.append(node)
	return node


## A battle that offers all ten towers, on the cluster map with many build spots.
func _battle() -> Battle:
	return Tx.battle(Fx.CLUSTER_GRID, [{"groups": [Fx.group("scamp", 1), Fx.group("flitter", 1)]}])


func _build_panel(b: Battle) -> BuildPanel:
	var panel: BuildPanel = _keep(BuildPanel.new()) as BuildPanel
	panel.setup(b)
	panel.show_spot(b.level.spots[0])
	return panel


func _tower_panel(b: Battle, type: StringName, tier: int = 1, spec: int = -1) -> TowerPanel:
	var cell: Vector2i = b.level.spots[0]
	assert_not_null(Tx.build(b, cell, type, tier, spec), "built %s" % type)
	var panel: TowerPanel = _keep(TowerPanel.new()) as TowerPanel
	panel.setup(b)
	panel.show_tower(cell)
	return panel


func _value(panel: Node, label: String) -> String:
	for node: Node in panel.find_children("*", "StatRow", true, false):
		var row: StatRow = node as StatRow
		if row.name_label.text == label and row.value_label != null:
			return row.value_label.text
	return "<missing %s>" % label


func _changes(panel: Node) -> Dictionary:
	var out: Dictionary = {}
	for node: Node in panel.find_children("*", "StatRow", true, false):
		var row: StatRow = node as StatRow
		if row.before_label != null:
			out[row.name_label.text] = "%s > %s" % [row.before_label.text, row.after_label.text]
	return out


# The region.

func test_the_region_reaches_the_map_view() -> void:
	var screen: BattleScreen = _keep(BattleScreen.new()) as BattleScreen
	screen.setup(UiFx.battle(&"r1_l1"), null, Progress.new())
	assert_eq(screen.map_view.ground_id(), &"lantern_hill", "the default is Lantern Hill")
	var other: BattleScreen = _keep(BattleScreen.new()) as BattleScreen
	other.setup(UiFx.battle(&"r2_l1"), null, Progress.new(), &"millbrook")
	assert_eq(other.map_view.ground_id(), &"millbrook", "the region picks the ground")
	var fen: BattleScreen = _keep(BattleScreen.new()) as BattleScreen
	fen.setup(UiFx.battle(&"r3_l1"), null, Progress.new(), &"willow_fen")
	assert_eq(fen.map_view.ground_id(), &"willow_fen")


func test_a_run_map_takes_its_ground_from_its_feature() -> void:
	var plain: BattleScreen = _keep(BattleScreen.new()) as BattleScreen
	plain.setup(UiFx.battle(&"r1_l1"), null, Progress.new(), &"")
	assert_eq(plain.map_view.ground_id(), &"lantern_hill", "no feature gives the meadow")
	var tunnel: BattleScreen = _keep(BattleScreen.new()) as BattleScreen
	tunnel.setup(Tx.battle(Fx.TUNNEL_GRID, [{"groups": [Fx.group("scamp", 1)]}]), null, Progress.new(), &"")
	assert_eq(tunnel.map_view.ground_id(), &"hollow_lanes", "a tunnel gives the Hollow Lanes ground")


func test_the_app_passes_the_campaign_region_and_nothing_for_a_run() -> void:
	var made: App = FlowFx.app(TAG)
	spare.append(made)
	for pair: Array in [[&"r1_l1", &"lantern_hill"], [&"r2_l3", &"millbrook"], [&"r3_l6", &"willow_fen"], [&"r4_l1", &"moonspire_keep"]]:
		var saved: SavedGame = SavedGame.new()
		saved.mode = SavedGame.LEVEL
		saved.level_id = pair[0]
		assert_eq(made.region_of(saved), pair[1], "region of %s" % pair[0])
	var twist: SavedGame = SavedGame.new()
	twist.mode = SavedGame.LEVEL
	twist.level_id = &"r2_l1"
	twist.twist = true
	assert_eq(made.region_of(twist), &"millbrook", "a Twist is played in its level's region")
	var unknown: SavedGame = SavedGame.new()
	unknown.level_id = &"nowhere"
	assert_eq(made.region_of(unknown), &"", "a level outside the campaign has no region")


func test_a_level_started_in_the_app_draws_its_region() -> void:
	var made: App = FlowFx.app(TAG)
	spare.append(made)
	FlowFx.mark_all_seen(made)
	made.start_level(&"r2_l1", false)
	var screen: BattleScreen = made.battle_screen()
	assert_not_null(screen)
	assert_eq(screen.map_view.ground_id(), &"millbrook", "level 2-1 is on the Millbrook ground")


# The build panel.

func test_ten_towers_make_two_rows_of_five() -> void:
	var panel: BuildPanel = _build_panel(_battle())
	assert_eq(panel.card_buttons.size(), 10, "one card for each of ten towers")
	var grids: Array[Node] = panel.find_children("*", "GridContainer", true, false)
	var cards: GridContainer = null
	for node: Node in grids:
		if (node as GridContainer).get_child_count() == 10:
			cards = node as GridContainer
	assert_not_null(cards, "the cards are in one grid")
	assert_eq(cards.columns, 5, "five across with no width known")
	for type: StringName in panel.card_buttons:
		var button: TapButton = panel.card_buttons[type]
		assert_true(button.custom_minimum_size.x >= Layout.MIN_TOUCH, "%s is wide enough" % type)
		assert_true(button.custom_minimum_size.y >= Layout.MIN_TOUCH, "%s is tall enough" % type)


func test_columns_never_squeeze_a_card_under_the_touch_size() -> void:
	assert_eq(BuildPanel.columns_for(10, 0.0), 5)
	assert_eq(BuildPanel.columns_for(9, 0.0), 5)
	assert_eq(BuildPanel.columns_for(8, 0.0), 4)
	assert_eq(BuildPanel.columns_for(7, 0.0), 4)
	assert_eq(BuildPanel.columns_for(6, 0.0), 3, "six stay two rows of three")
	assert_eq(BuildPanel.columns_for(5, 0.0), 3)
	assert_eq(BuildPanel.columns_for(4, 0.0), 2)
	assert_eq(BuildPanel.columns_for(3, 0.0), 3)
	assert_eq(BuildPanel.columns_for(1, 0.0), 1)
	for count: int in range(1, 11):
		for room: int in range(100, 1300, 7):
			var columns: int = BuildPanel.columns_for(count, float(room))
			var width: float = float(columns) * Layout.MIN_TOUCH + float(columns - 1) * float(BuildPanel.CARD_GAP)
			assert_true(columns >= 1 and columns <= BuildPanel.MAX_COLUMNS)
			assert_true(columns == 1 or width <= float(room), "%d cards in %d px fit at %d across" % [count, room, columns])


func test_a_narrow_panel_asks_for_fewer_columns() -> void:
	# The cover sheet is about 980 px inside its margins and the inner screen's side column about 690.
	assert_eq(BuildPanel.columns_for(10, 980.0), 5)
	assert_eq(BuildPanel.columns_for(10, 690.0), 4)
	assert_eq(BuildPanel.columns_for(10, 500.0), 2)


func test_choosing_a_new_tower_shows_its_real_numbers_and_range() -> void:
	var b: Battle = _battle()
	var panel: BuildPanel = _build_panel(b)
	var rings: Array = []
	panel.range_changed.connect(func(_cell: Vector2i, reach: int, boost: bool) -> void: rings.append([reach, boost]))
	panel.select_tower(&"bramble_cottage")
	assert_eq(_value(panel, "Ring"), "1.5 tiles")
	assert_eq(_value(panel, "Pulse"), "All in ring")
	assert_eq(_value(panel, "Hits"), "Walkers")
	assert_eq(rings.back(), [150, false], "the map is told the ring of the thorns")
	panel.select_tower(&"scarecrow")
	assert_eq(_value(panel, "Fright"), "15%")
	assert_eq(_value(panel, "Range"), "2 tiles")
	assert_eq(_value(panel, "Linger"), "1.0 s")
	assert_eq(_value(panel, "Affects"), "Walkers")
	assert_eq(rings.back(), [200, false], "the fright zone is shown as the range")
	panel.select_tower(&"snow_fort")
	assert_eq(_value(panel, "Line width"), "0.8 tiles")
	assert_eq(_value(panel, "Range"), "3 tiles")
	panel.select_tower(&"moth_lantern")
	assert_eq(_value(panel, "Stays low"), "2.0 s")
	assert_eq(_value(panel, "Hits"), "Flyers")
	assert_eq(_value(panel, "Line width"), "<missing Line width>", "no line row on a lantern")


# The tower panels.

func test_a_bramble_cottage_has_no_targeting() -> void:
	var b: Battle = _battle()
	var panel: TowerPanel = _tower_panel(b, &"bramble_cottage")
	assert_true(panel.aim_buttons.is_empty(), "no targeting row")
	assert_false(_texts(panel).has("Targeting"))
	assert_eq(_value(panel, "Ring"), "1.5 tiles")
	assert_eq(_value(panel, "Range"), "<missing Range>", "its reach is called a ring")
	assert_eq(_value(panel, "Pulse"), "All in ring")
	assert_eq(_value(panel, "Damage"), "4")
	panel.set_aim(TowerState.Aim.LAST)
	assert_eq(panel.feedback_text(), BattleText.refusal(&"no_aim"), "a forced aim says why")


func test_a_scarecrow_shows_fright_range_and_linger_and_no_targeting() -> void:
	var b: Battle = _battle()
	var panel: TowerPanel = _tower_panel(b, &"scarecrow")
	assert_true(panel.aim_buttons.is_empty(), "no targeting row")
	assert_eq(_value(panel, "Fright"), "15%")
	assert_eq(_value(panel, "Range"), "2 tiles")
	assert_eq(_value(panel, "Linger"), "1.0 s")
	assert_eq(_value(panel, "Affects"), "Walkers")
	assert_eq(_value(panel, "Damage"), "<missing Damage>", "it deals no damage")
	var keeper: TowerPanel = _tower_panel(_battle(), &"scarecrow", 3, 1)
	assert_eq(_value(keeper, "Affects"), "Walkers and flyers")
	assert_eq(_value(keeper, "Range"), "3 tiles")


func test_a_snow_fort_shows_its_line_width_and_keeps_targeting() -> void:
	var b: Battle = _battle()
	var panel: TowerPanel = _tower_panel(b, &"snow_fort")
	assert_eq(panel.aim_buttons.size(), 3, "it aims, so it has the three modes")
	assert_eq(_value(panel, "Line width"), "0.8 tiles")
	assert_eq(_value(panel, "Range"), "3 tiles")
	assert_eq(_value(panel, "Damage"), "16")
	var big: TowerPanel = _tower_panel(_battle(), &"snow_fort", 3, 0)
	assert_eq(_value(big, "Line width"), "1 tile", "Big Snowball is the wide one")


func test_a_moth_lantern_shows_how_long_a_flyer_stays_low() -> void:
	var b: Battle = _battle()
	var panel: TowerPanel = _tower_panel(b, &"moth_lantern")
	assert_eq(panel.aim_buttons.size(), 3)
	assert_eq(_value(panel, "Stays low"), "2.0 s")
	assert_eq(_value(panel, "Hits"), "Flyers")
	var beacon: TowerPanel = _tower_panel(_battle(), &"moth_lantern", 3, 0)
	assert_eq(_value(beacon, "Stays low"), "4.0 s")
	var garland: TowerPanel = _tower_panel(_battle(), &"moth_lantern", 3, 1)
	assert_eq(_value(garland, "Targets"), "3")


func test_old_towers_show_nothing_new() -> void:
	var b: Battle = _battle()
	var panel: TowerPanel = _tower_panel(b, &"pumpkin_catapult")
	for label: String in ["Ring", "Pulse", "Line width", "Stays low", "Fright", "Dozing"]:
		assert_eq(_value(panel, label), "<missing %s>" % label, "no %s row on a catapult" % label)
	assert_eq(panel.aim_buttons.size(), 3)
	var bell: TowerPanel = _tower_panel(_battle(), &"lullaby_bell")
	assert_ne(_value(bell, "Slow"), "<missing Slow>")
	assert_true(bell.aim_buttons.is_empty())


# First sight.

func test_the_first_sight_card_of_each_new_tower_shows_its_numbers() -> void:
	var b: Battle = _battle()
	var expected: Dictionary = {
		&"bramble_cottage": ["Ring", "1.5 tiles"], &"scarecrow": ["Fright", "15%"],
		&"snow_fort": ["Line width", "0.8 tiles"], &"moth_lantern": ["Stays low", "2.0 s"],
	}
	for type: StringName in NEW_TOWERS:
		var card: InfoCard = _keep(InfoCard.new(b, [{"kind": &"tower", "id": type, "wave": 0}] as Array[Dictionary])) as InfoCard
		assert_eq(card.name_label.text, b.catalog.tower(type).name, "the card names %s from the data" % type)
		assert_eq(_value(card, expected[type][0]), expected[type][1], "%s card" % type)


# Upgrades.

func test_an_upgrade_shows_the_new_numbers_before_and_after() -> void:
	var scare: TowerPanel = _tower_panel(_battle(), &"scarecrow")
	var changes: Dictionary = _changes(scare)
	assert_eq(changes["Fright"], "15% > 25%")
	assert_eq(changes["Range"], "2 tiles > 2.5 tiles")
	assert_false(changes.has("Linger"), "an unchanged number is not listed")
	var bramble: TowerPanel = _tower_panel(_battle(), &"bramble_cottage")
	var bramble_changes: Dictionary = _changes(bramble)
	assert_eq(bramble_changes["Damage"], "4 > 7")
	assert_false(bramble_changes.has("Range"), "a ring is a ring")
	var fort: TowerPanel = _tower_panel(_battle(), &"snow_fort", 2)
	var paths: Dictionary = _changes(fort)
	assert_true(paths.has("Line width"), "the Big Snowball is wider")
	var lantern: TowerPanel = _tower_panel(_battle(), &"moth_lantern")
	assert_eq(_changes(lantern)["Stays low"], "2.0 s > 3.0 s")


func test_the_tier_three_paths_of_a_scarecrow_show_their_difference() -> void:
	var panel: TowerPanel = _tower_panel(_battle(), &"scarecrow", 2)
	assert_eq(panel.path_cards.size(), 2)
	var rows: Array[Node] = panel.find_children("*", "StatRow", true, false)
	var affects: PackedStringArray = PackedStringArray()
	for node: Node in rows:
		var row: StatRow = node as StatRow
		if row.before_label != null and row.name_label.text == "Affects":
			affects.append("%s > %s" % [row.before_label.text, row.after_label.text])
	assert_eq(affects, PackedStringArray(["Walkers > Walkers and flyers"]), "only the Crow Keeper reaches flyers")
	var ring: Array[String] = []
	for node: Node in rows:
		var row: StatRow = node as StatRow
		if row.before_label != null and row.name_label.text == "Range":
			ring.append("%s > %s" % [row.before_label.text, row.after_label.text])
	assert_eq(ring.size(), 1, "the Crow Keeper's range changes, the Tall Scarecrow's does not")


# Dozing.

func test_the_text_of_a_dozing_tower() -> void:
	var rows: Array[PackedStringArray] = BattleText.tower_rows({"damage": 4, "reload_ms": 1000, "reach": 150, "hits_ground": true, "pulse": true, "doze_ms": 2400}, &"attack")
	assert_eq(rows[0], PackedStringArray(["Dozing", "2.4 s left"]), "the doze line comes first")
	var awake: Array[PackedStringArray] = BattleText.tower_rows({"damage": 4, "reload_ms": 1000, "reach": 150, "hits_ground": true}, &"attack")
	for row: PackedStringArray in awake:
		assert_ne(row[0], "Dozing")
	var zero: Array[PackedStringArray] = BattleText.tower_rows({"damage": 4, "reload_ms": 1000, "reach": 150, "hits_ground": true, "doze_ms": 0}, &"attack")
	for row: PackedStringArray in zero:
		assert_ne(row[0], "Dozing")
	assert_eq(BattleText.doze_text(50), "0.1 s left", "time left above zero never reads 0.0")
	assert_eq(BattleText.doze_text(3000), "3.0 s left")


func test_a_dozing_tower_panel_counts_down_without_being_rebuilt() -> void:
	var b: Battle = _battle()
	var cell: Vector2i = b.level.spots[0]
	assert_not_null(Tx.build(b, cell, &"snow_fort"))
	var panel: DozyPanel = _keep(DozyPanel.new()) as DozyPanel
	panel.setup(b)
	panel.doze_ms = 2400
	panel.show_tower(cell)
	assert_not_null(panel.doze_label, "a dozing tower shows the line")
	assert_eq(panel.doze_label.text, "2.4 s left")
	var first_aim: TapButton = panel.aim_buttons[0]
	panel.doze_ms = 2250
	panel.refresh()
	assert_eq(panel.doze_label.text, "2.3 s left", "the time runs down in place")
	assert_eq(panel.aim_buttons[0], first_aim, "the buttons are the same, so a finger on one is not lost")
	panel.doze_ms = 0
	panel.refresh()
	assert_null(panel.doze_label, "an awake tower shows no line")
	assert_eq(_value(panel, "Dozing"), "<missing Dozing>")
	panel.doze_ms = 1000
	panel.refresh()
	assert_not_null(panel.doze_label, "it dozes again")


func test_a_dozing_bramble_cottage_shows_the_line_and_still_no_targeting() -> void:
	var b: Battle = _battle()
	var cell: Vector2i = b.level.spots[0]
	assert_not_null(Tx.build(b, cell, &"bramble_cottage"))
	var panel: DozyPanel = _keep(DozyPanel.new()) as DozyPanel
	panel.setup(b)
	panel.doze_ms = 1500
	panel.show_tower(cell)
	assert_eq(_value(panel, "Dozing"), "1.5 s left")
	assert_true(panel.aim_buttons.is_empty())


func _texts(root: Node) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for node: Node in root.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out
