# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends SceneTree
## Step U6 checks that need a running scene tree: a finger that slides over a list scrolls it
## and does not press the button under it, on every scrolling list in the app; and the new
## Restart and sound buttons at both Fold5 sizes. The test runner has no tree, so
## tests/ui/test_u6_real_tree.gd starts this script in a second Godot process.
##
##     godot --headless --path . --script res://tests/ui/real_tree_u6.gd
##
## Every problem prints a line starting with "FAIL". The exit code is 0 when nothing failed.
## Touches are pushed the way Godot delivers them: an emulated mouse event first, then the
## touch event. Headless Godot has no touch screen, so the scroll container's own touch
## scrolling does not run here; what is tested is what the buttons do with the touch.

const COVER: Vector2 = Vector2(1080.0, 2767.0)
const INNER: Vector2 = Vector2(1998.0, 2400.0)
const COVER_SAFE: Rect2 = Rect2(0.0, 96.0, 1080.0, 2500.0)
const INNER_SAFE: Rect2 = Rect2(0.0, 0.0, 1998.0, 2250.0)
const WATCHDOG_SECONDS: float = 300.0
const BattleFixtures: GDScript = preload("res://tests/ui/battle_fixtures.gd")

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


func _viewport(size: Vector2) -> SubViewport:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(size)
	root.add_child(vp)
	return vp


func _hosted(vp: SubViewport, screen: Control, size: Vector2, safe: Rect2) -> void:
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	holder.add_child(screen)
	screen.call("apply_layout", size, safe)
	await _frames()


func _run() -> void:
	await _plain_list()
	await _real_lists()
	await _battle_lists()
	await _battle_buttons()
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 else 0)


# Fingers.

## A finger goes down. `touch` adds the touch event Godot sends with the emulated mouse.
func _down(vp: SubViewport, at: Vector2, touch: bool) -> void:
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = at
	mouse.global_position = at
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse.device = InputEvent.DEVICE_ID_EMULATION if touch else 0
	vp.push_input(mouse)
	if touch:
		var event: InputEventScreenTouch = InputEventScreenTouch.new()
		event.position = at
		event.pressed = true
		vp.push_input(event)


func _move(vp: SubViewport, from: Vector2, to: Vector2, touch: bool) -> void:
	var mouse: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse.position = to
	mouse.global_position = to
	mouse.relative = to - from
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse.device = InputEvent.DEVICE_ID_EMULATION if touch else 0
	vp.push_input(mouse)
	if touch:
		var event: InputEventScreenDrag = InputEventScreenDrag.new()
		event.position = to
		event.relative = to - from
		vp.push_input(event)


func _up(vp: SubViewport, at: Vector2, touch: bool) -> void:
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	mouse.position = at
	mouse.global_position = at
	mouse.device = InputEvent.DEVICE_ID_EMULATION if touch else 0
	vp.push_input(mouse)
	if touch:
		var event: InputEventScreenTouch = InputEventScreenTouch.new()
		event.position = at
		event.pressed = false
		vp.push_input(event)


## A finger down at `from`, moving to `from + travel` in `steps` equal moves, then up.
func _swipe(vp: SubViewport, from: Vector2, travel: Vector2, touch: bool, steps: int = 8) -> void:
	_down(vp, from, touch)
	var last: Vector2 = from
	for i: int in steps:
		var to: Vector2 = from + travel * float(i + 1) / float(steps)
		_move(vp, last, to, touch)
		last = to
	_up(vp, last, touch)


## The index of the button that covers `at`, or -1.
func _index_at(buttons: Array[TapButton], at: Vector2) -> int:
	for i: int in buttons.size():
		if buttons[i].get_global_rect().has_point(at):
			return i
	return -1


func _tap(vp: SubViewport, at: Vector2, touch: bool) -> void:
	_down(vp, at, touch)
	_up(vp, at, touch)


# A plain list of buttons.

func _plain_list() -> void:
	for touch: bool in [true, false]:
		var kind: String = "touch" if touch else "mouse"
		var vp: SubViewport = _viewport(Vector2(1080.0, 1000.0))
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.size = Vector2(900.0, 500.0)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.scroll_deadzone = int(TapButton.DEADZONE)
		vp.add_child(scroll)
		var column: VBoxContainer = VBoxContainer.new()
		column.custom_minimum_size.x = 880.0
		scroll.add_child(column)
		var taps: Array[int] = [0, 0, 0, 0, 0, 0]
		var buttons: Array[TapButton] = []
		for i: int in 6:
			var b: TapButton = UiKit.button("Row %d" % i)
			b.custom_minimum_size = Vector2(0.0, 200.0)
			b.tapped.connect(func() -> void: taps[i] += 1)
			column.add_child(b)
			buttons.append(b)
		var row_taps: Array[int] = [0]
		var row: TapRow = TapRow.new()
		row.custom_minimum_size.y = 200.0
		row.tapped.connect(func() -> void: row_taps[0] += 1)
		column.add_child(row)
		await _frames()
		var most: int = int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page)
		check(most > 300, "%s: the test list overflows (%d)" % [kind, most])
		var second: Vector2 = buttons[1].get_global_rect().get_center()
		# A tap presses.
		_tap(vp, second, touch)
		check(taps[1] == 1, "%s: a tap presses the button" % kind)
		check(scroll.scroll_vertical == 0, "%s: a tap scrolls nothing" % kind)
		# A slow drag inside the dead zone is still a tap.
		_swipe(vp, second, Vector2(0.0, -TapButton.DEADZONE * 0.5), touch)
		check(taps[1] == 2, "%s: a drag inside the dead zone is a tap" % kind)
		check(scroll.scroll_vertical == 0, "%s: and scrolls nothing" % kind)
		_swipe(vp, second, Vector2(TapButton.DEADZONE * 0.5, TapButton.DEADZONE * 0.5), touch, 3)
		check(taps[1] == 3, "%s: a small diagonal wobble is a tap" % kind)
		# A drag up from a button scrolls the list by the finger's travel and presses nothing.
		_swipe(vp, second, Vector2(0.0, -200.0), touch)
		check(taps[1] == 3, "%s: a drag that starts on a button does not press it" % kind)
		check(absi(scroll.scroll_vertical - 200) <= 2, "%s: the list follows the finger (%d)" % [kind, scroll.scroll_vertical])
		check(buttons[1].get_draw_mode() != BaseButton.DRAW_PRESSED, "%s: the button lets go once the list moves" % kind)
		# Back down again, from the button that is under the middle of the view now.
		var at: Vector2 = Vector2(400.0, 250.0)
		var under: int = _index_at(buttons, at)
		check(under >= 0, "%s: a button is under the middle of the view" % kind)
		_swipe(vp, at, Vector2(0.0, 120.0), touch)
		check(absi(scroll.scroll_vertical - 80) <= 2, "%s: a drag down brings it back (%d)" % [kind, scroll.scroll_vertical])
		check(under < 0 or taps[under] == (3 if under == 1 else 0), "%s: still no press" % kind)
		# Up and back in one touch ends where it started.
		scroll.scroll_vertical = 100
		await _frames()
		at = Vector2(400.0, 250.0)
		_down(vp, at, touch)
		var finger: Vector2 = at
		for dy: float in [-60.0, -60.0, 60.0, 60.0]:
			_move(vp, finger, finger + Vector2(0.0, dy), touch)
			finger += Vector2(0.0, dy)
		_up(vp, finger, touch)
		check(absi(scroll.scroll_vertical - 100) <= 2, "%s: up and back lands where it began (%d)" % [kind, scroll.scroll_vertical])
		check(str(taps) == "[0, 3, 0, 0, 0, 0]", "%s: and presses nothing (%s)" % [kind, taps])
		# A sideways drag does not scroll and is not a tap.
		scroll.scroll_vertical = 0
		await _frames()
		at = buttons[1].get_global_rect().get_center()
		_swipe(vp, at, Vector2(150.0, 0.0), touch)
		check(taps[1] == 3 and scroll.scroll_vertical == 0, "%s: a sideways drag does nothing" % kind)
		# The list stops at both ends.
		_swipe(vp, Vector2(400.0, 250.0), Vector2(0.0, 300.0), touch)
		check(scroll.scroll_vertical == 0, "%s: no scroll past the top" % kind)
		for k: int in 6:
			scroll.scroll_vertical = 0
			await _frames()
			_swipe(vp, Vector2(400.0, 450.0), Vector2(0.0, -420.0), touch)
			if scroll.scroll_vertical >= most:
				break
		check(scroll.scroll_vertical <= most, "%s: no scroll past the end (%d of %d)" % [kind, scroll.scroll_vertical, most])
		# A tap still works after all that.
		scroll.scroll_vertical = 0
		await _frames()
		_tap(vp, buttons[1].get_global_rect().get_center(), touch)
		check(taps[1] == 4, "%s: taps work again after a scroll" % kind)
		# A TapRow (a level row, a card) scrolls too.
		scroll.scroll_vertical = most
		await _frames()
		var row_at: Vector2 = row.get_global_rect().get_center()
		_swipe(vp, row_at, Vector2(0.0, 150.0), touch)
		check(row_taps[0] == 0, "%s: a drag on a row does not tap it" % kind)
		check(scroll.scroll_vertical < most - 100, "%s: a drag on a row scrolls the list (%d)" % [kind, scroll.scroll_vertical])
		_tap(vp, row.get_global_rect().get_center(), touch)
		check(row_taps[0] == 1, "%s: a tap on a row taps it" % kind)
		vp.queue_free()
		await _frames(1)


# The real lists.

## The page frame's scroll container and a button inside it, for a drag test.
func _drag_on_list(vp: SubViewport, scroll: ScrollContainer, label: String, touch: bool) -> void:
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	var most: int = int(bar.max_value - bar.page)
	check(most > 250, "%s: the list overflows, so it can be tested (%d)" % [label, most])
	var picked: TapButton = null
	for node: Node in scroll.find_children("*", "TapButton", true, false):
		var b: TapButton = node as TapButton
		if b.is_visible_in_tree() and b.size.y > 40.0 and not b.disabled:
			picked = b
			break
	if picked == null:
		# Nothing in this list is a button (the Info guide): the controls take no touch, so a
		# drag reaches the scroll container itself. _no_stop_controls checks that.
		return
	if most <= 250:
		return
	var presses: Array[int] = [0]
	picked.tapped.connect(func() -> void: presses[0] += 1)
	# Put the button mid way down the view, with room to scroll both ways.
	var inside: float = picked.global_position.y - scroll.global_position.y + float(scroll.scroll_vertical)
	scroll.scroll_vertical = clampi(int(inside - scroll.size.y * 0.5), 150, most - 150)
	await _frames(2)
	var at: Vector2 = picked.get_global_rect().get_center()
	at.y = clampf(at.y, scroll.global_position.y + 60.0, scroll.global_position.y + scroll.size.y - 60.0)
	if not picked.get_global_rect().has_point(at):
		at = picked.get_global_rect().get_center()
	var before: int = scroll.scroll_vertical
	_swipe(vp, at, Vector2(0.0, -100.0), touch)
	check(presses[0] == 0, "%s: a drag that starts on a button does not press it" % label)
	check(absi(scroll.scroll_vertical - (before + 100)) <= 2, "%s: the list follows a finger on a button (%d to %d)" % [label, before, scroll.scroll_vertical])
	await _frames(2)
	at = picked.get_global_rect().get_center()
	if scroll.get_global_rect().has_point(at) and picked.get_global_rect().has_point(at):
		_tap(vp, at, touch)
		check(presses[0] == 1, "%s: a tap on the button still presses it" % label)


func _real_lists() -> void:
	var game: GameData = BattleFixtures.four_region_game()
	var progress: Progress = Progress.new()
	var catalog: Catalog = game.catalog
	var names: Dictionary = {}
	for id: StringName in catalog.tower_ids():
		names[id] = catalog.tower(id).name
	for id: StringName in catalog.enemy_ids():
		names[id] = catalog.enemy(id).name
	var rules: Dictionary = {"refund_pct": 70, "star2_lives": 15, "max_waves_running": 2, "run_stars": 12, "start_lives": 20, "relaxed_lives_pct": 200, "relaxed_gold_pct": 150, "early_bonus_pct": 10, "max_gates": 3, "runs_built": true}
	var real: GameData = BattleFixtures.game()
	for touch: bool in [true, false]:
		var kind: String = "touch" if touch else "mouse"
		var size: Vector2 = Vector2(1080.0, 1100.0)
		var safe: Rect2 = Rect2(Vector2.ZERO, size)
		# Campaign.
		var vp: SubViewport = _viewport(size)
		var list: LevelSelect = LevelSelect.new()
		await _hosted(vp, list, size, safe)
		list.populate(game, progress, &"")
		await _frames()
		await _drag_on_list(vp, list.scroll, "%s campaign list" % kind, touch)
		_no_stop_controls(list.scroll, "campaign list")
		vp.queue_free()
		# Info.
		vp = _viewport(size)
		var info: InfoScreen = InfoScreen.new(rules, names, InfoContent.from_game(game))
		await _hosted(vp, info, size, safe)
		await _drag_on_list(vp, info.scroll, "%s Info" % kind, touch)
		_no_stop_controls(info.scroll, "Info")
		vp.queue_free()
		# About.
		vp = _viewport(Vector2(1080.0, 900.0))
		var about: AboutScreen = AboutScreen.new()
		await _hosted(vp, about, Vector2(1080.0, 900.0), Rect2(0.0, 0.0, 1080.0, 900.0))
		await _drag_on_list(vp, about.scroll, "%s About" % kind, touch)
		_no_stop_controls(about.scroll, "About")
		vp.queue_free()
		# The mode screen.
		vp = _viewport(Vector2(1080.0, 800.0))
		var mode: ModeScreen = ModeScreen.new()
		mode.set_runs(true, 14, 12, true, "Best today: Won with 14 lives left. Streak: 3 days.", "Regions 1 to 6")
		mode.set_continue("Continue", "Daily 2026-10-28. Wave 2 of 18.")
		await _hosted(vp, mode, Vector2(1080.0, 800.0), Rect2(0.0, 0.0, 1080.0, 800.0))
		await _drag_on_list(vp, mode.scroll, "%s mode screen" % kind, touch)
		_no_stop_controls(mode.scroll, "mode screen")
		vp.queue_free()
		# A level card.
		vp = _viewport(Vector2(1080.0, 800.0))
		var card: LevelCard = LevelCard.new(real, progress, &"r1_l1", false, false, false)
		await _hosted(vp, card, Vector2(1080.0, 800.0), Rect2(0.0, 0.0, 1080.0, 800.0))
		await _drag_on_list(vp, card.scroll, "%s level card" % kind, touch)
		_no_stop_controls(card.scroll, "level card")
		vp.queue_free()
		await _frames(1)
	# The license reader and the run card hold text only or the same parts; check they hold
	# nothing that would stop a drag.
	var vp2: SubViewport = _viewport(Vector2(1080.0, 800.0))
	var reader: LicenseViewer = LicenseViewer.new("Forkline", LicenseText.build(LicenseText.FORKLINE))
	await _hosted(vp2, reader, Vector2(1080.0, 800.0), Rect2(0.0, 0.0, 1080.0, 800.0))
	_no_stop_controls(reader.scroll, "license reader")
	vp2.queue_free()
	var vp3: SubViewport = _viewport(Vector2(1080.0, 800.0))
	var run_card: RunCard = RunCard.new(real, real.run, false, "", {}, 0, "", false, "")
	await _hosted(vp3, run_card, Vector2(1080.0, 800.0), Rect2(0.0, 0.0, 1080.0, 800.0))
	_no_stop_controls(run_card.scroll, "run card")
	vp3.queue_free()


## Inside a list only buttons may take a touch. Any other control that stops the mouse would
## swallow a drag that starts on it, and the list would not move.
func _no_stop_controls(scroll: ScrollContainer, label: String) -> void:
	var seen: int = 0
	for node: Node in scroll.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if not control.is_visible_in_tree():
			continue
		seen += 1
		if control is BaseButton or control is ScrollBar:
			continue
		check(control.mouse_filter != Control.MOUSE_FILTER_STOP, "%s: %s (%s) stops a drag" % [label, control.get_class(), control.name])
	check(seen > 3, "%s: the scan found the list's controls (%d)" % [label, seen])


# The battle screen's two lists.

func _seen_progress(catalog: Catalog) -> Progress:
	var progress: Progress = Progress.new()
	for id: StringName in catalog.tower_ids():
		progress.mark_seen(id)
	for id: StringName in catalog.enemy_ids():
		progress.mark_seen(id)
	return progress


func _battle_in(size: Vector2) -> Array:
	var vp: SubViewport = _viewport(size)
	var holder: Control = Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.theme = UiTheme.build()
	vp.add_child(holder)
	var b: Battle = BattleFixtures.all_towers_battle()
	b.gold = 5000
	var screen: BattleScreen = BattleScreen.new()
	screen.setup(b, null, _seen_progress(b.catalog))
	holder.add_child(screen)
	screen.apply_layout(size, Rect2(Vector2.ZERO, size))
	await _frames(6)
	screen.hint_banner.dismiss()
	await _frames(2)
	return [vp, screen]


## The build panel in the landscape side column and in the portrait sheet: a drag that starts
## on a tower button scrolls the column.
func _battle_lists() -> void:
	for pair: Array in [[Vector2(1998.0, 1000.0), "side column"], [Vector2(1080.0, 1500.0), "sheet"]]:
		var size: Vector2 = pair[0]
		var made: Array = await _battle_in(size)
		var vp: SubViewport = made[0]
		var screen: BattleScreen = made[1]
		screen.tap_at(screen.battle.level.spots[0])
		await _frames(4)
		var panel: BuildPanel = screen.build_panel
		check(panel.visible, "%s: the build panel is open" % pair[1])
		var scroll: ScrollContainer = null
		var node: Node = panel
		while node != null and scroll == null:
			scroll = node as ScrollContainer
			node = node.get_parent()
		check(scroll != null, "%s: the panel sits in a scroll container" % pair[1])
		if scroll != null:
			await _drag_on_list(vp, scroll, "%s battle %s" % ["touch", pair[1]], true)
			_no_stop_controls(scroll, "battle %s" % pair[1])
		vp.queue_free()
		await _frames(1)


# The new battle buttons.

func _rects_apart(a: Control, b: Control) -> bool:
	return not a.get_global_rect().intersects(b.get_global_rect())


func _battle_buttons() -> void:
	for pair: Array in [[COVER, COVER_SAFE, "cover"], [INNER, INNER_SAFE, "inner"]]:
		var size: Vector2 = pair[0]
		var safe: Rect2 = pair[1]
		var where: String = pair[2]
		var made: Array = await _battle_in(size)
		var vp: SubViewport = made[0]
		var screen: BattleScreen = made[1]
		var hud: BattleHud = screen.hud
		var sound: TapButton = hud.sound_button
		var rect: Rect2 = sound.get_global_rect()
		check(sound.is_visible_in_tree(), "%s: the sound button shows" % where)
		check(rect.size.x >= Layout.MIN_TOUCH - 0.5 and rect.size.y >= Layout.MIN_TOUCH - 0.5, "%s: the sound button is 48 dp (%s)" % [where, rect.size])
		check(hud.get_global_rect().encloses(rect), "%s: the sound button is inside the HUD (%s in %s)" % [where, rect, hud.get_global_rect()])
		check(safe.encloses(rect), "%s: and inside the safe area" % where)
		for other: Control in [hud.pause_button, hud.speed_buttons[0], hud.speed_buttons[1], hud.speed_buttons[2], hud.call_button]:
			check(_rects_apart(sound, other), "%s: the sound button does not overlap '%s'" % [where, str((other as Button).text)])
		check(hud.call_button.size.x >= 340.0, "%s: the call button keeps room for its words (%s)" % [where, hud.call_button.size.x])
		var call_rows: float = hud.call_button.size.y
		check(call_rows <= Layout.MIN_TOUCH + 60.0, "%s: the call button stays a single row high (%s)" % [where, call_rows])
		# A tap on the sound button toggles it, and a swipe over it does not.
		var seen: Array[bool] = []
		hud.sound_selected.connect(func(on: bool) -> void: seen.append(on))
		_tap(vp, rect.get_center(), true)
		check(seen == ([false] as Array[bool]), "%s: a touch on the sound button turns the sound off" % where)
		_swipe(vp, rect.get_center(), Vector2(TapButton.DEADZONE * 3.0, 0.0), true)
		check(seen.size() == 1, "%s: a swipe over it does nothing" % where)
		# Pause with Restart.
		screen.pause()
		await _frames(3)
		var pause: PausePanel = null
		for node: Node in screen.find_children("*", "PausePanel", true, false):
			pause = node as PausePanel
		if pause == null:
			pause = screen._pause_panel
		check(pause != null, "%s: Pause is open" % where)
		if pause != null:
			pause.apply_layout(size, safe)
			await _frames(3)
			var restart: Rect2 = pause.restart_button.get_global_rect()
			var abandon: Rect2 = pause.abandon_button.get_global_rect()
			for r: Rect2 in [restart, abandon]:
				check(r.size.x >= Layout.MIN_TOUCH - 0.5 and r.size.y >= Layout.MIN_TOUCH - 0.5, "%s: a Pause button is 48 dp (%s)" % [where, r.size])
				check(safe.encloses(r) or Rect2(Vector2.ZERO, size).encloses(r), "%s: a Pause button is on the screen" % where)
			check(not restart.intersects(abandon), "%s: Restart and Abandon do not overlap" % where)
			check(absf(restart.position.y - abandon.position.y) < 1.0, "%s: Restart sits beside Abandon" % where)
			check(restart.position.x < abandon.position.x, "%s: Restart is left of Abandon" % where)
			pause.restart_button.tapped.emit()
			await _frames(3)
			check(pause.confirm_open(), "%s: Restart asks first" % where)
			for node: Node in pause.find_children("*", "BaseButton", true, false):
				var b: BaseButton = node as BaseButton
				if b.is_visible_in_tree():
					check(b.size.x >= Layout.MIN_TOUCH - 0.5 and b.size.y >= Layout.MIN_TOUCH - 0.5, "%s: a question button is 48 dp" % where)
		vp.queue_free()
		await _frames(1)
