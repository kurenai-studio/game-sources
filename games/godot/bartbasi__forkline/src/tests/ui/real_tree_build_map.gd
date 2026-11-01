# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Opening the build panel must not resize or move the map in the landscape layout, whether
## the level offers 8, 9 or 10 towers (step U6b). Ten towers want 5 columns of cards, wider
## than the side column, so the side column used to grow and push the map aside. Checked at
## the Fold5 inner size and the cover size, on the real battle screen. The tower fixtures
## (tests/sim/fixtures/tower_fixtures.gd) supply the 9th and 10th tower. The test runner has
## no scene tree, so tests/ui/test_build_map.gd starts this script in a second Godot process.
##
##     godot --headless --path . --script res://tests/ui/real_tree_build_map.gd
##
## Every problem prints a line starting with "FAIL". The exit code is 0 when nothing failed.
## Landscape: the map's scale, position and the side column's width stay exactly as they were.
## Portrait: the map keeps its scale and its place in the slot; it may slide up, on purpose,
## so a selected cell stays above the sheet (docs/ARCHITECTURE.md 7.4).

const COVER: Vector2 = Vector2(1080.0, 2767.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
const WATCHDOG_SECONDS: float = 200.0
const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")

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


func _seen(catalog: Catalog) -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


## A battle that offers the first `count` of the ten towers, with gold for all of them.
static func battle(count: int) -> Battle:
	var towers: Array = Tx.ALL.slice(0, count)
	var waves: Array = [{"groups": [Sx.group("scamp", 3), Sx.group("flitter", 2, 2000)]}]
	return Tx.battle(Sx.CLUSTER_GRID, waves, {"start_gold": 5000, "towers": towers})


func _run() -> void:
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		for count: int in [8, 9, 10]:
			await _case(pair[0], pair[1], "%s, %d towers" % [pair[2], count], count)
	for count: int in [8, 9, 10]:
		await _bare(count, true)
		await _bare(count, false)
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _case(size: Vector2, safe: Rect2, where: String, count: int) -> void:
	var b: Battle = battle(count)
	check(b.level.towers.size() == count, "%s: the battle offers %d towers (%d)" % [where, count, b.level.towers.size()])
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(size)
	root.add_child(vp)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _seen(b.catalog))
	holder.add_child(screen)
	screen.apply_layout(size, safe)
	await _frames(6)
	screen.hint_banner.dismiss()
	await _frames(4)
	var landscape: bool = screen.landscape
	var scale_before: Vector2 = screen.map_view.scale
	var pos_before: Vector2 = screen.map_view.position
	var side_before: float = screen._side.size.x
	var base_before: Vector2 = screen._map_base
	screen.tap_at(b.level.spots[0])
	await _frames(10)
	var panel: BuildPanel = screen.build_panel
	check(panel.is_open() and panel.is_visible_in_tree(), "%s: a tap on a spot opens the build panel" % where)
	check(panel.card_buttons.size() == count, "%s: %d cards (%d)" % [where, count, panel.card_buttons.size()])
	var scale_after: Vector2 = screen.map_view.scale
	var pos_after: Vector2 = screen.map_view.position
	check(scale_after.is_equal_approx(scale_before), "%s: the map keeps its scale (%s to %s)" % [where, scale_before, scale_after])
	check(screen._map_base.is_equal_approx(base_before), "%s: the map keeps its place in the slot (%s to %s)" % [where, base_before, screen._map_base])
	if landscape:
		check(pos_after.is_equal_approx(pos_before), "%s: the map does not move (%s to %s)" % [where, pos_before, pos_after])
		check(is_equal_approx(screen._side.size.x, side_before), "%s: the side column keeps its width (%.1f to %.1f)" % [where, side_before, screen._side.size.x])
	else:
		check(is_equal_approx(pos_after.x, pos_before.x) and pos_after.y <= pos_before.y + 0.5, "%s: the map stays put or slides up (%s to %s)" % [where, pos_before, pos_after])
	var tops: Dictionary = {}
	for type: StringName in panel.card_buttons:
		var card: TapButton = panel.card_buttons[type]
		var r: Rect2 = card.get_global_rect()
		check(Rect2(Vector2.ZERO, size).encloses(r), "%s: card %s is inside the screen (%s)" % [where, type, r])
		check(safe.grow(1.0).encloses(r), "%s: card %s is inside the safe area (%s)" % [where, type, r])
		check(r.size.x >= Layout.MIN_TOUCH - 0.5 and r.size.y >= Layout.MIN_TOUCH - 0.5, "%s: card %s is under 48 dp (%s)" % [where, type, r.size])
		if landscape:
			check(screen._side.get_global_rect().grow(1.0).encloses(r), "%s: card %s is inside the side column (%s in %s)" % [where, type, r, screen._side.get_global_rect()])
		tops[snappedf(r.position.y, 1.0)] = true
	if landscape:
		check(tops.size() <= 3, "%s: at most three rows of cards in the side column (%d)" % [where, tops.size()])
	var build: Rect2 = panel.build_button.get_global_rect()
	check(safe.grow(1.0).encloses(build), "%s: the Build button is inside the safe area (%s)" % [where, build])
	print("INFO %s: scale %s to %s, map at %s to %s, side %.0f, %d rows, panel %s" % [where, scale_before, scale_after, pos_before, pos_after, screen._side.size.x, tops.size(), panel.get_global_rect()])
	vp.queue_free()
	await _frames(2)


## The panel on its own in a 760 px column, as tests/ui/real_tree_checks.gd hosts it: no
## BattleScreen, so nothing tells it how much room there is. It starts with no width, and it
## must not ask for five columns, grow to fit them and then keep them. `wide_first` sets the
## landscape look before the panel is in the tree; otherwise after.
func _bare(count: int, wide_first: bool) -> void:
	var where: String = "bare side panel, %d towers, look set %s" % [count, "first" if wide_first else "after"]
	var b: Battle = battle(count)
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(INNER)
	root.add_child(vp)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(INNER.x - 36.0 - 760.0, 36.0)
	column.custom_minimum_size = Vector2(760.0, 0.0)
	column.size = Vector2(760.0, 100.0)
	holder.add_child(column)
	var panel: BuildPanel = BuildPanel.new()
	panel.setup(b)
	if wide_first:
		panel.set_wide(false)
	panel.show_spot(b.level.spots[0])
	column.add_child(panel)
	if not wide_first:
		panel.set_wide(false)
	await _frames(10)
	check(panel.size.x <= 760.5, "%s: the panel is no wider than its column (%.0f)" % [where, panel.size.x])
	var grid: GridContainer = null
	for node: Node in panel.find_children("*", "GridContainer", true, false):
		if (node as GridContainer).columns >= 3:
			grid = node as GridContainer
			break
	check(grid != null and grid.columns == 4, "%s: four columns (%s)" % [where, grid.columns if grid != null else -1])
	for type: StringName in panel.card_buttons:
		var r: Rect2 = (panel.card_buttons[type] as TapButton).get_global_rect()
		check(Rect2(Vector2.ZERO, INNER).encloses(r) and r.end.x <= column.get_global_rect().end.x + 0.5, "%s: card %s is inside the column and the screen (%s)" % [where, type, r])
	check(panel.build_button.get_global_rect().end.x <= column.get_global_rect().end.x + 0.5, "%s: the Build button is inside the column" % where)
	vp.queue_free()
	await _frames(2)
