# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## In the landscape layout, opening any panel in the side column leaves the map's scale and
## position and the column's width exactly as they were (step U6b). Panels: build (8 and 10
## towers), tower (tiers 1 and 2), creature, draft and the wave preview (a tall one). Checked
## at the Fold5 inner size and at a narrow landscape window, where a scroll bar appearing used
## to widen the column and shrink the map. The test runner has no scene tree, so
## tests/ui/test_side_steady.gd starts this script in a second Godot process.
##
##     godot --headless --path . --script res://tests/ui/real_tree_side_steady.gd
##
## Every problem prints a line starting with "FAIL". The exit code is 0 when nothing failed.

const INNER: Vector2 = Vector2(1998.0, 2400.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
## A narrow landscape window: the side column is as narrow as it gets.
const NARROW: Vector2 = Vector2(1300.0, 1700.0)
const NARROW_SAFE: Rect2 = Rect2(0.0, 0.0, 1300.0, 1600.0)
const WATCHDOG_SECONDS: float = 300.0
const Sx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const RunFx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")

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


## A battle on the cluster map offering the first `count` of the ten towers.
static func battle(count: int, waves: Array = []) -> Battle:
	var plan: Array = waves
	if plan.is_empty():
		plan = [{"groups": [Sx.group("scamp", 3), Sx.group("flitter", 2, 2000)]}]
	return Tx.battle(Sx.CLUSTER_GRID, plan, {"start_gold": 5000, "towers": Tx.ALL.slice(0, count)})


## A wave with six kinds of creature, so the open preview is tall.
static func busy_waves() -> Array:
	var groups: Array = []
	var at: int = 0
	for kind: String in ["scamp", "flitter", "shellback", "skitter", "mender", "grumblesack"]:
		groups.append(Sx.group(kind, 3, at))
		at += 2000
	return [{"groups": groups}, {"groups": [Sx.group("scamp", 3)]}]


func _run() -> void:
	for pair: Array in [[INNER, INNER_SAFE, "inner"], [NARROW, NARROW_SAFE, "narrow"]]:
		var size: Vector2 = pair[0]
		var safe: Rect2 = pair[1]
		var label: String = pair[2]
		await _build(size, safe, label, 8)
		await _build(size, safe, label, 10)
		await _tower(size, safe, label, 1)
		await _tower(size, safe, label, 2)
		await _tower(size, safe, label, 3)
		await _creature(size, safe, label)
		await _draft(size, safe, label)
		await _preview(size, safe, label)
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _screen(size: Vector2, safe: Rect2, b: Battle) -> Array:
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
	return [vp, screen]


## What must not change: the map's scale and position and the side column's width.
func _snap(screen: BattleScreen) -> Array:
	return [screen.map_view.scale, screen.map_view.position, screen._side.size.x]


func _same(before: Array, screen: BattleScreen, where: String) -> void:
	var after: Array = _snap(screen)
	check((before[0] as Vector2).is_equal_approx(after[0]), "%s: the map keeps its scale (%s to %s)" % [where, before[0], after[0]])
	check((before[1] as Vector2).is_equal_approx(after[1]), "%s: the map does not move (%s to %s)" % [where, before[1], after[1]])
	check(is_equal_approx(before[2], after[2]), "%s: the side column keeps its width (%.1f to %.1f)" % [where, before[2], after[2]])
	print("INFO %s: scale %.4f, map at %s, side %.0f to %.0f" % [where, (after[0] as Vector2).x, after[1], before[2], after[2]])


## Nothing in the panel sticks out past the panel's right edge or under the scroll bar. The
## column's width is fixed, so a panel that is too wide would be cut off, not widen the column.
func _fits(screen: BattleScreen, panel: Control, where: String) -> void:
	var side: Rect2 = screen._side_slot.get_global_rect()
	var bar: float = screen._side.get_v_scroll_bar().size.x if screen._side.get_v_scroll_bar().visible else 0.0
	var room: float = side.end.x - bar + 0.5
	var rect: Rect2 = panel.get_global_rect()
	check(rect.position.x >= side.position.x - 0.5 and rect.end.x <= room, "%s: the panel is inside the side column (%s in %s, bar %.0f)" % [where, rect, side, bar])
	var wide: int = 0
	for node: Node in panel.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if control.is_visible_in_tree() and control.get_global_rect().end.x > rect.end.x + 1.0:
			wide += 1
			if wide <= 3:
				print("INFO %s: %s %s reaches %.0f, the panel ends at %.0f" % [where, control.get_class(), control.name, control.get_global_rect().end.x, rect.end.x])
	check(wide == 0, "%s: %d parts stick out past the panel's right edge" % [where, wide])


func _done(vp: SubViewport) -> void:
	vp.queue_free()
	await _frames(2)


func _build(size: Vector2, safe: Rect2, label: String, count: int) -> void:
	var where: String = "%s build panel, %d towers" % [label, count]
	var b: Battle = battle(count)
	var made: Array = await _screen(size, safe, b)
	var screen: BattleScreen = made[1]
	var before: Array = _snap(screen)
	screen.tap_at(b.level.spots[0])
	await _frames(10)
	check(screen.build_panel.is_open() and screen.build_panel.is_visible_in_tree(), "%s opens" % where)
	_same(before, screen, where)
	_fits(screen, screen.build_panel, where)
	await _done(made[0])


func _tower(size: Vector2, safe: Rect2, label: String, tier: int) -> void:
	var where: String = "%s tower panel, tier %d" % [label, tier]
	var b: Battle = battle(10)
	var made: Array = await _screen(size, safe, b)
	var screen: BattleScreen = made[1]
	var cell: Vector2i = b.level.spots[0]
	Tx.build(b, cell, &"snow_fort", tier, 0)
	await _frames(2)
	var before: Array = _snap(screen)
	screen.tap_at(cell)
	await _frames(10)
	check(screen.tower_panel.is_open() and screen.tower_panel.is_visible_in_tree(), "%s opens" % where)
	_same(before, screen, where)
	_fits(screen, screen.tower_panel, where)
	await _done(made[0])


func _creature(size: Vector2, safe: Rect2, label: String) -> void:
	var where: String = "%s creature panel" % label
	var b: Battle = battle(8)
	var made: Array = await _screen(size, safe, b)
	var screen: BattleScreen = made[1]
	screen.hud.call_button.tapped.emit()
	var guard: int = 0
	while b.enemies.is_empty() and guard < 3000:
		b.step()
		guard += 1
	await _frames(6)
	check(not b.enemies.is_empty(), "%s: a creature is on the map" % where)
	if b.enemies.is_empty():
		await _done(made[0])
		return
	var before: Array = _snap(screen)
	screen.show_enemy(b.enemies[0].id)
	await _frames(10)
	check(screen.enemy_panel.is_open() and screen.enemy_panel.is_visible_in_tree(), "%s opens" % where)
	_same(before, screen, where)
	_fits(screen, screen.enemy_panel, where)
	await _done(made[0])


func _draft(size: Vector2, safe: Rect2, label: String) -> void:
	var where: String = "%s draft panel" % label
	var data: RunData = RunFx.run_data()
	var session: RunSession = RunSession.start(5, "", false, data.pool({}), data, RunFx.catalog())
	check(session != null, "%s: the fixture run starts" % where)
	if session == null:
		return
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(size)
	root.add_child(vp)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(session.battle, null, _seen(session.battle.catalog))
	screen.set_run(session)
	holder.add_child(screen)
	screen.apply_layout(size, safe)
	await _frames(10)
	var before: Array = _snap(screen)
	screen.hud.call_button.tapped.emit()
	session.battle.lives = 99
	var guard: int = 0
	while session.battle.phase == Battle.Phase.WAVE and guard < 40000:
		session.battle.step()
		guard += 1
	await _frames(10)
	check(screen.draft_is_open() and screen.draft_panel.is_visible_in_tree(), "%s opens" % where)
	_same(before, screen, where)
	_fits(screen, screen.draft_panel, where)
	await _done(vp)


func _preview(size: Vector2, safe: Rect2, label: String) -> void:
	var where: String = "%s wave preview, six kinds" % label
	var b: Battle = battle(8, busy_waves())
	var made: Array = await _screen(size, safe, b)
	var screen: BattleScreen = made[1]
	screen.preview.set_open(false)
	await _frames(6)
	var before: Array = _snap(screen)
	screen.preview.set_open(true)
	await _frames(10)
	check(screen.preview.expanded and screen.preview.is_visible_in_tree(), "%s opens" % where)
	_same(before, screen, where)
	_fits(screen, screen.preview, where)
	await _done(made[0])
