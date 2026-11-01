# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## The HUD keeps its size, and the map keeps its size and place, whatever the call button
## says (QA 2026-10-29 L1: "Last wave is out" wrapped to three lines on the Fold5 cover and
## the map moved down in the last wave). Checked at the cover and inner sizes, with real
## battle states (build phase, a wave running, the last wave out) and with every label the
## button can show, set one after the other with the lock it wears. The test runner
## has no scene tree, so tests/ui/test_hud_steady.gd starts this script in a second Godot
## process.
##
##     godot --headless --path . --script res://tests/ui/real_tree_hud_steady.gd
##
## Every problem prints a line starting with "FAIL". The exit code is 0 when nothing failed.

const COVER: Vector2 = Vector2(1080.0, 2767.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
const WATCHDOG_SECONDS: float = 600.0
## Every text the call button can show (BattleHud._refresh_call), with two digit wave numbers
## and a three digit bonus, which are the widest.
const LABELS: Array = [
	["Start wave 12", false], ["Call wave 12  +120", false], ["Call wave 12", true],
	["Last wave is out", true], ["Battle over", true], ["Pick a card first", true],
	["Card due next", true],
]
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


func _run() -> void:
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		await _states(pair[0], pair[1], pair[2])
		await _labels(pair[0], pair[1], pair[2])
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
	await _frames(8)
	return [vp, screen]


## What must not change: the HUD's rect, the map area's rect, and the map's scale and place.
func _snap(screen: BattleScreen) -> Array:
	return [screen.hud.get_global_rect(), screen.map_area.get_global_rect(), screen.map_view.scale, screen.map_view.global_position]


func _same(before: Array, screen: BattleScreen, where: String, with_hud: bool = true) -> void:
	var after: Array = _snap(screen)
	var hud_before: Rect2 = before[0]
	var hud_after: Rect2 = after[0]
	check(not with_hud or hud_before.position.is_equal_approx(hud_after.position) and hud_before.size.is_equal_approx(hud_after.size), "%s: the HUD keeps its place and size (%s to %s)" % [where, hud_before, hud_after])
	var area_before: Rect2 = before[1]
	var area_after: Rect2 = after[1]
	check(area_before.position.is_equal_approx(area_after.position) and area_before.size.is_equal_approx(area_after.size), "%s: the map area keeps its place and size (%s to %s)" % [where, area_before, area_after])
	check((before[2] as Vector2).is_equal_approx(after[2]), "%s: the map keeps its scale (%s to %s)" % [where, before[2], after[2]])
	check((before[3] as Vector2).is_equal_approx(after[3]), "%s: the map does not move (%s to %s)" % [where, before[3], after[3]])


func _two_waves() -> Array:
	return [
		{"groups": [Sx.group("scamp", 3), Sx.group("flitter", 2, 2000)]},
		{"groups": [Sx.group("scamp", 3)]},
	]


## The real states: a build phase ("Start wave 1"), the first wave running ("Call wave 2 +N"),
## and the last wave out ("Last wave is out").
func _states(size: Vector2, safe: Rect2, label: String) -> void:
	var where: String = "%s, real states" % label
	var b: Battle = Tx.battle(Sx.CLUSTER_GRID, _two_waves(), {"start_gold": 500})
	var made: Array = await _screen(size, safe, b)
	var screen: BattleScreen = made[1]
	var before: Array = _snap(screen)
	check(screen.hud.call_button.text.begins_with("Start wave"), "%s: the build phase offers the start (%s)" % [where, screen.hud.call_button.text])
	screen.hud.call_button.tapped.emit()
	await _frames(8)
	check(screen.hud.call_button.text.begins_with("Call wave"), "%s: a wave offers an early call (%s)" % [where, screen.hud.call_button.text])
	_same(before, screen, where + ", calling")
	var guard: int = 0
	while b.next_wave_info()["refusal"] == &"still_spawning" and guard < 40000:
		b.step()
		guard += 1
	await _frames(8)
	check(screen.hud.call_button.text.contains("+"), "%s: the early call shows its bonus (%s)" % [where, screen.hud.call_button.text])
	_same(before, screen, where + ", early call offered")
	screen.hud.call_button.tapped.emit()
	await _frames(8)
	check(screen.hud.call_button.text == "Last wave is out", "%s: the last wave is out (%s)" % [where, screen.hud.call_button.text])
	_same(before, screen, where + ", last wave out")
	guard = 0
	while b.phase == Battle.Phase.WAVE and guard < 40000:
		b.lives = 99
		b.step()
		guard += 1
	await _frames(8)
	check(screen.hud.call_button.text == "Battle over", "%s: the battle is over (%s)" % [where, screen.hud.call_button.text])
	# The side column also shows the "wave cleared" message in the HUD, so only the map is held.
	_same(before, screen, where + ", after the battle", false)
	made[0].queue_free()
	await _frames(2)


## The label takes a font size of 40 or more (FONT_SMALL, QA 2026-10-30 L1) and its wrapped text
## fits the button's fixed height at that size.
func _fits(hud: BattleHud, text: String, where: String) -> void:
	var size: int = hud.call_button.get_theme_font_size(&"font_size")
	check(size >= UiTheme.FONT_SMALL, "%s: the font size is %d, not below %d" % [where, size, UiTheme.FONT_SMALL])
	var width: float = hud.call_button.size.x - 2.0 * float(UiTheme.PAD_X)
	if hud.call_button.icon != null:
		width -= float(hud.call_button.icon.get_width()) + 16.0
	var room: float = hud.call_button.custom_minimum_size.y - 2.0 * float(UiTheme.PAD_Y)
	var wrapped: Vector2 = UiTheme.font(UiTheme.WEIGHT_BOLD).get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, size)
	check(wrapped.y <= room, "%s: the text fits the button at %d (%s high, room %s)" % [where, size, wrapped.y, room])
	print("%s: %d px" % [where, size])


## Every label the button can show, with the lock it wears, set straight on the button.
func _labels(size: Vector2, safe: Rect2, label: String) -> void:
	var b: Battle = Tx.battle(Sx.CLUSTER_GRID, _two_waves(), {"start_gold": 500})
	var made: Array = await _screen(size, safe, b)
	var screen: BattleScreen = made[1]
	var before: Array = _snap(screen)
	for pair: Array in LABELS:
		var text: String = pair[0]
		var locked: bool = pair[1]
		screen.hud.show_call_label(text, text.begins_with("Start"), locked)
		await _frames(6)
		_same(before, screen, "%s, label \"%s\"%s" % [label, text, " with lock" if locked else ""])
		_fits(screen.hud, text, "%s, label \"%s\"" % [label, text])
	made[0].queue_free()
	await _frames(2)
