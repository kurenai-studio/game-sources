extends "res://tests/base_test.gd"
## QA6-01: every pressable control of the design area reacts exactly once to
## one tap, whichever way it arrives: a finger (with or without the mouse
## event Godot emulates from it), a real mouse click (with or without an
## emulated touch), or ui_accept. The events are real InputEvent objects fed
## to each control's _gui_input; the last test also pushes them through a
## live viewport (scenes/design/tap_check.tscn), where BaseButton's own input
## handling runs too.

const TAP_CHECK: String = "res://scenes/design/tap_check.tscn"
## Longer than the check's own watchdog (30 s), so the child normally quits
## by itself; the parent kills it only past this.
const CHILD_SECONDS: float = 45.0

var _made: Array[Node] = []


func before_each() -> void:
	Motion.bind_tweens = false


func after_each() -> void:
	Motion.bind_tweens = true
	for tween: Tween in (Engine.get_main_loop() as SceneTree).get_processed_tweens():
		tween.kill()
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func test_qa6_01_icon_button_presses_once_for_a_touch_and_its_emulated_mouse() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var button: BaseButton = _icon_button(skin_id)
		var heard: Array[int] = [0]
		button.pressed.connect(func() -> void: heard[0] += 1)
		var at: Vector2 = button.size * 0.5
		# Godot's order on a phone: the emulated mouse, then the touch.
		button._gui_input(_mouse(true, at, InputEvent.DEVICE_ID_EMULATION))
		button._gui_input(_touch(true, at, 0))
		assert_eq(button.call(&"state"), &"pressed", "%s shows pressed while the finger is down" % skin_id)
		button._gui_input(_mouse(false, at, InputEvent.DEVICE_ID_EMULATION))
		assert_eq(heard[0], 0, "%s the emulated mouse release does nothing" % skin_id)
		button._gui_input(_touch(false, at, 0))
		assert_eq(heard[0], 1, "%s one pressed for one tap" % skin_id)
		assert_eq(button.call(&"state"), &"normal", "%s back to normal" % skin_id)


func test_qa6_01_every_way_of_tapping_presses_once() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for way: String in _ways():
			var button: BaseButton = _icon_button(skin_id)
			var heard: Array[int] = [0]
			button.pressed.connect(func() -> void: heard[0] += 1)
			_tap(button, way)
			assert_eq(heard[0], 1, "%s icon button, %s" % [skin_id, way])


func test_qa6_01_toggles_pause_and_booster_buttons_react_once() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for way: String in _ways():
			var toggle: SkinToggle = _keep(UiKit.make_toggle(skin)) as SkinToggle
			var flips: Array[int] = [0]
			toggle.toggled.connect(func(_on: bool) -> void: flips[0] += 1)
			_tap(toggle, way)
			assert_eq(flips[0], 1, "%s toggle, %s" % [skin_id, way])

			var hud: SkinHud = _keep(UiKit.make_hud(skin)) as SkinHud
			hud.size = Vector2(1080.0, hud.preferred_height())
			hud.notification(Control.NOTIFICATION_RESIZED)
			var pauses: Array[int] = [0]
			hud.pause_pressed.connect(func() -> void: pauses[0] += 1)
			_tap(hud.get_node(^"Pause") as Control, way)
			assert_eq(pauses[0], 1, "%s HUD pause, %s" % [skin_id, way])

			var bar: SkinBoosterBar = _keep(UiKit.make_booster_bar(skin)) as SkinBoosterBar
			bar.size = Vector2(1080.0, bar.preferred_height())
			bar.notification(Control.NOTIFICATION_RESIZED)
			var statuses: Array[BoosterStatus] = []
			for id: StringName in [&"hammer", &"swap", &"shuffle", &"double", &"undo"]:
				var status: BoosterStatus = BoosterStatus.new()
				status.id = id
				status.cost = 7
				status.usable = true
				statuses.append(status)
			bar.show_boosters(statuses)
			var boosts: Array[int] = [0]
			bar.booster_pressed.connect(func(_id: StringName) -> void: boosts[0] += 1)
			_tap((bar.call(&"buttons") as Array[Control])[1], way)
			assert_eq(boosts[0], 1, "%s booster button, %s" % [skin_id, way])


func test_a_second_finger_or_a_cancelled_touch_adds_no_tap() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var button: BaseButton = _icon_button(skin_id)
		var heard: Array[int] = [0]
		button.pressed.connect(func() -> void: heard[0] += 1)
		var at: Vector2 = button.size * 0.5
		button._gui_input(_touch(true, at, 0))
		button._gui_input(_touch(true, at, 1, 1))
		button._gui_input(_touch(false, at, 0))
		button._gui_input(_touch(false, at, 1, 1))
		assert_eq(heard[0], 1, "%s two fingers make one tap" % skin_id)
		var cancelled: InputEventScreenTouch = _touch(false, at, 0)
		cancelled.canceled = true
		button._gui_input(_touch(true, at, 0))
		button._gui_input(cancelled)
		assert_eq(heard[0], 1, "%s a cancelled touch is no tap" % skin_id)
		assert_eq(button.call(&"state"), &"normal", "%s and it lets go" % skin_id)


func test_a_touch_lifted_outside_does_not_tap() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var button: BaseButton = _icon_button(skin_id)
		var heard: Array[int] = [0]
		button.pressed.connect(func() -> void: heard[0] += 1)
		button._gui_input(_touch(true, button.size * 0.5, 0))
		button._gui_input(_touch(false, button.size * 3.0, 0))
		assert_eq(heard[0], 0, "%s slid off before lifting" % skin_id)


func test_qa6_01_through_a_live_viewport() -> void:
	# BaseButton's own touch handling only runs when a viewport routes the
	# events, which needs a running scene tree: the check runs as its own
	# Godot process. It exits 0 only when every expected check ran, each
	# control reacted exactly once and no error was logged; for details, run
	# it by hand: godot --headless --path . res://scenes/design/tap_check.tscn
	var code: int = run_child(TAP_CHECK, CHILD_SECONDS)
	assert_eq(code, 0, "tap check exit code (1: a check failed, 2: its watchdog fired, -1: killed)")


## Runs scene in a child Godot and returns its exit code. Waits at most
## seconds; if it overruns, kills that child only, by its PID, and returns
## -1. The child's output is not read: a pipe nobody empties can stall it.
static func run_child(scene: String, seconds: float) -> int:
	var args: PackedStringArray = PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), scene])
	var pid: int = OS.create_process(OS.get_executable_path(), args)
	if pid <= 0:
		return -1
	var deadline: int = Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while OS.is_process_running(pid):
		if Time.get_ticks_msec() > deadline:
			OS.kill(pid)
			return -1
		OS.delay_msec(50)
	return OS.get_process_exit_code(pid)


func _ways() -> PackedStringArray:
	return PackedStringArray(["touch with the emulated mouse", "touch alone", "mouse", "mouse with an emulated touch", "ui_accept"])


func _tap(control: Control, way: String) -> void:
	var at: Vector2 = control.size * 0.5
	match way:
		"touch with the emulated mouse":
			for down: bool in [true, false]:
				control._gui_input(_mouse(down, at, InputEvent.DEVICE_ID_EMULATION))
				control._gui_input(_touch(down, at, 0))
		"touch alone":
			control._gui_input(_touch(true, at, 0))
			control._gui_input(_touch(false, at, 0))
		"mouse":
			control._gui_input(_mouse(true, at, 0))
			control._gui_input(_mouse(false, at, 0))
		"mouse with an emulated touch":
			for down: bool in [true, false]:
				control._gui_input(_mouse(down, at, 0))
				control._gui_input(_touch(down, at, InputEvent.DEVICE_ID_EMULATION))
		"ui_accept":
			for down: bool in [true, false]:
				var key: InputEventKey = InputEventKey.new()
				key.keycode = KEY_ENTER
				key.physical_keycode = KEY_ENTER
				key.pressed = down
				control._gui_input(key)


func _icon_button(skin_id: StringName) -> BaseButton:
	return _keep(UiKit.make_icon_button(SkinCatalog.get_skin(skin_id), &"settings")) as BaseButton


func _keep(node: Node) -> Node:
	_made.append(node)
	return node


func _mouse(down: bool, at: Vector2, device: int) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.device = device
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.position = at
	return event


func _touch(down: bool, at: Vector2, device: int, index: int = 0) -> InputEventScreenTouch:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.device = device
	event.index = index
	event.pressed = down
	event.position = at
	return event
