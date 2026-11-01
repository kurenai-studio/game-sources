# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Step U4 checks that need a running scene tree: the build panel with ten towers and the
## panels of the four new towers on the real battle screen, at both Fold5 sizes. The test
## runner has no tree, so tests/ui/test_u4_real_tree.gd starts this script in a second Godot
## process and reads what it prints.
##
##     godot --headless --path . --script res://tests/ui/real_tree_u4.gd
##
## Every problem prints a line starting with "FAIL". The exit code is 0 when nothing failed.

const COVER: Vector2 = Vector2(1080.0, 2767.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
const WATCHDOG_SECONDS: float = 200.0
const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const NEW_TOWERS: Array[StringName] = [&"bramble_cottage", &"scarecrow", &"snow_fort", &"moth_lantern"]

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	create_timer(WATCHDOG_SECONDS).timeout.connect(func() -> void:
		print("FAIL watchdog: the checks did not finish")
		quit(2))
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL %s" % message)


func _frames(count: int = 3) -> void:
	for i: int in count:
		await process_frame


## A 13 row map with a build spot beside every second row: the tallest the game allows.
static func tall_grid() -> Array:
	var grid: Array = []
	grid.append_array(Sx.CLUSTER_GRID.slice(0, 7))
	for i: int in 5:
		grid.append("..o#o.." if i % 2 == 0 else "...#...")
	grid.append("...B...")
	return grid


static func battle(grid: Array) -> Battle:
	return Tx.battle(grid, [{"groups": [Sx.group("scamp", 3), Sx.group("flitter", 2, 2000)]}], {"start_gold": 5000})


func _seen() -> Progress:
	var progress: Progress = Progress.new()
	var catalog: Catalog = Tx.catalog()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


func _screen(size: Vector2, safe: Rect2, b: Battle) -> Array:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(size)
	root.add_child(vp)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _seen())
	holder.add_child(screen)
	screen.apply_layout(size, safe)
	await _frames(6)
	screen.hint_banner.dismiss()
	await _frames(2)
	return [vp, screen]


func _run() -> void:
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		for grid_name: String in ["cluster", "tall", "poor"]:
			var grid: Array = tall_grid() if grid_name == "tall" else Sx.CLUSTER_GRID
			await _build_ten(pair[0], pair[1], "%s %s" % [pair[2], grid_name], grid, 0 if grid_name == "poor" else 5000)
		await _tower_panels(pair[0], pair[1], pair[2])
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


## Every visible button of `panel` is a 48 dp target.
func _buttons_big(panel: Control, where: String) -> int:
	var seen: int = 0
	for node: Node in panel.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node as BaseButton
		if not button.is_visible_in_tree():
			continue
		seen += 1
		var rect: Rect2 = button.get_global_rect()
		var label: String = "%s: button '%s'" % [where, str((button as Button).text)]
		check(rect.size.x >= Layout.MIN_TOUCH - 0.5 and rect.size.y >= Layout.MIN_TOUCH - 0.5, "%s is under 48 dp (%s)" % [label, rect.size])
	return seen


func _build_ten(size: Vector2, safe: Rect2, where: String, grid: Array, gold: int) -> void:
	var b: Battle = battle(grid)
	b.gold = gold
	var made: Array = await _screen(size, safe, b)
	var vp: SubViewport = made[0]
	var screen: BattleScreen = made[1]
	check(b.level.towers.size() == 10, "%s: the battle offers ten towers" % where)
	screen.tap_at(b.level.spots[0])
	await _frames(4)
	var panel: BuildPanel = screen.build_panel
	check(panel.is_open() and panel.is_visible_in_tree(), "%s: a tap on a spot opens the build panel" % where)
	check(panel.card_buttons.size() == 10, "%s: ten cards (%d)" % [where, panel.card_buttons.size()])
	var buttons: int = _buttons_big(panel, where)
	check(buttons >= 12, "%s: the cards, Build and close are all counted (%d)" % [where, buttons])
	var rect: Rect2 = panel.get_global_rect()
	check(safe.grow(1.0).encloses(rect), "%s: the build panel is inside the safe area (%s in %s)" % [where, rect, safe])
	if size == COVER:
		check(rect.position.y >= screen.hud.get_global_rect().end.y - 1.0, "%s: the sheet leaves the HUD uncovered" % where)
	var tops: Dictionary = {}
	for type: StringName in panel.card_buttons:
		var card: TapButton = panel.card_buttons[type]
		var r: Rect2 = card.get_global_rect()
		check(card.is_visible_in_tree(), "%s: card %s shows" % [where, type])
		check(rect.grow(1.0).encloses(r), "%s: card %s is inside the panel (%s in %s)" % [where, type, r, rect])
		tops[snappedf(r.position.y, 1.0)] = true
		# The price and the "Need N" line fit in the card's width.
		for label_node: Node in card.find_children("*", "Label", true, false):
			var label: Label = label_node as Label
			check(label.get_minimum_size().x <= r.size.x - 8.0, "%s: card %s text '%s' is wider than the card" % [where, type, label.text])
	var rows: int = tops.size()
	print("INFO %s: panel %s, %d rows of cards, card %s, Build button %s" % [where, rect, rows, (panel.card_buttons.values()[0] as TapButton).get_global_rect().size, panel.build_button.get_global_rect()])
	if size == COVER:
		check(rows == 2, "%s: ten towers are two rows in portrait (%d)" % [where, rows])
	else:
		check(rows <= 3, "%s: ten towers are at most three rows in the side column (%d)" % [where, rows])
	# The Build button can be reached: inside the screen, or the panel scrolls.
	var build: Rect2 = panel.build_button.get_global_rect()
	check(Rect2(Vector2.ZERO, size).encloses(build), "%s: the Build button is on the screen (%s)" % [where, build])
	check(safe.grow(1.0).encloses(build), "%s: the Build button is inside the safe area (%s)" % [where, build])
	# The tenth card can be chosen, and Build is still reachable.
	var last: StringName = b.level.towers[9]
	panel.select_tower(last)
	await _frames(2)
	check(panel.selected == last and safe.grow(1.0).encloses(panel.build_button.get_global_rect()), "%s: the tenth card can be chosen and Build is still reachable" % where)
	if gold > 0:
		panel.confirm()
		check(b.tower_at(b.level.spots[0]) != null and b.tower_at(b.level.spots[0]).type == last, "%s: the tenth tower builds" % where)
	else:
		check(not panel.need_labels.is_empty() and panel.need_labels.size() == 10, "%s: every card says what it still needs" % where)
	vp.queue_free()
	await _frames(2)


func _tower_panels(size: Vector2, safe: Rect2, label: String) -> void:
	for type: StringName in NEW_TOWERS:
		for tier: int in [1, 2, 3]:
			var where: String = "%s %s tier %d" % [label, type, tier]
			var b: Battle = battle(Sx.CLUSTER_GRID)
			var made: Array = await _screen(size, safe, b)
			var vp: SubViewport = made[0]
			var screen: BattleScreen = made[1]
			var cell: Vector2i = b.level.spots[0]
			Tx.build(b, cell, type, tier, 0)
			screen.tap_at(cell)
			await _frames(4)
			var panel: TowerPanel = screen.tower_panel
			check(panel.is_open() and panel.is_visible_in_tree(), "%s: a tap on the tower opens its panel" % where)
			_buttons_big(panel, where)
			var rect: Rect2 = panel.get_global_rect()
			# The side column scrolls when a state is tall (the tier 3 path cards).
			if size == COVER or tier < 2:
				check(safe.grow(1.0).encloses(rect), "%s: the panel is inside the safe area (%s in %s)" % [where, rect, safe])
			if type == &"bramble_cottage" or type == &"scarecrow":
				check(panel.aim_buttons.is_empty(), "%s: no targeting buttons" % where)
			else:
				check(panel.aim_buttons.size() == 3, "%s: three targeting buttons" % where)
			vp.queue_free()
			await _frames(2)
