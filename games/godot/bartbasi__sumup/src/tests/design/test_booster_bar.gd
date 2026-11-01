extends "res://tests/base_test.gd"
## Every skin's booster bar maps each BoosterStatus to the right look, cost
## label and Suggested badge (DESIGN_SYSTEM.md 4.7, 5.7, 6.7, 7.5, D-32,
## D-42), lays out inside bar_height, and only emits for usable boosters.

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")

var _made: Array[Node] = []


func before_each() -> void:
	Motion.bind_tweens = false


func after_each() -> void:
	Motion.bind_tweens = true
	# Unbound tweens outlive the nodes they animated; stop them all.
	for tween: Tween in (Engine.get_main_loop() as SceneTree).get_processed_tweens():
		tween.kill()
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _bar(skin_id: StringName) -> SkinBoosterBar:
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	var bar: SkinBoosterBar = UiKit.make_booster_bar(skin)
	_made.append(bar)
	bar.size = Vector2(1080.0, bar.preferred_height())
	# Outside the scene tree Godot sends no resize notification; send it as
	# the engine does in the tree.
	bar.notification(Control.NOTIFICATION_RESIZED)
	return bar


func _buttons(bar: SkinBoosterBar) -> Array[Control]:
	return bar.call(&"buttons") as Array[Control]


func test_statuses_map_to_looks_costs_and_badges() -> void:
	var statuses: Array[BoosterStatus] = Fixtures.offer_statuses()
	var looks: Array[int] = [SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_DISABLED, SkinIcon.LOOK_DISABLED]
	var costs: PackedStringArray = PackedStringArray(["2K", "2K", "4K", "128K", "1024"])
	var suggested: Array[bool] = [false, false, true, false, false]
	for skin_id: StringName in SkinCatalog.IDS:
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(statuses)
		var buttons: Array[Control] = _buttons(bar)
		assert_eq(buttons.size(), 5, "%s five buttons" % skin_id)
		for i: int in buttons.size():
			var button: Control = buttons[i]
			assert_eq(button.get(&"booster_id"), statuses[i].id, "%s button %d id" % [skin_id, i])
			assert_eq(button.get(&"look"), looks[i], "%s %s look" % [skin_id, statuses[i].id])
			assert_eq(button.get(&"cost_text"), costs[i], "%s %s cost label" % [skin_id, statuses[i].id])
			assert_eq(button.get(&"cost_text"), NumberFormat.tile_label(statuses[i].cost), "%s %s uses the tile label" % [skin_id, statuses[i].id])
			assert_eq(button.get(&"suggested"), suggested[i], "%s %s suggested" % [skin_id, statuses[i].id])
			assert_eq(button.get(&"enabled"), looks[i] != SkinIcon.LOOK_DISABLED, "%s %s takes taps" % [skin_id, statuses[i].id])


func test_suggested_badge_hides_while_any_booster_is_active() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(_offer(-1))
		assert_eq(bar.call(&"badge_count"), 1, "%s the offer shows the badge" % skin_id)
		for active: int in [0, 1, 3]:
			bar.show_boosters(_offer(active))
			assert_eq(bar.call(&"badge_count"), 0, "%s no badge while booster %d is active" % [skin_id, active])
			assert_true(bool(_buttons(bar)[2].get(&"suggested")), "%s shuffle stays marked suggested" % skin_id)
		bar.show_boosters(_offer(-1))
		assert_eq(bar.call(&"badge_count"), 1, "%s the badge comes back when targeting ends" % skin_id)


func test_show_boosters_again_reuses_the_buttons() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(Fixtures.plain_statuses(7))
		var first: Array[Control] = _buttons(bar)
		bar.show_boosters(Fixtures.offer_statuses())
		var second: Array[Control] = _buttons(bar)
		for i: int in first.size():
			assert_true(first[i] == second[i], "%s button %d reused" % [skin_id, i])
		assert_eq(second[0].get(&"cost_text"), "2K", "%s new cost shown" % skin_id)
		bar.show_boosters(Fixtures.plain_statuses(8))
		assert_eq(second[1].get(&"look"), SkinIcon.LOOK_NORMAL, "%s active ends" % skin_id)


func test_taps_emit_only_for_usable_boosters() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(Fixtures.offer_statuses())
		var heard: Array[StringName] = []
		bar.booster_pressed.connect(func(id: StringName) -> void: heard.append(id))
		for button: Control in _buttons(bar):
			_tap(button)
		assert_eq(heard, [&"hammer", &"swap", &"shuffle"] as Array[StringName], "%s emits for usable and active boosters only" % skin_id)


func test_a_release_outside_the_button_does_not_tap() -> void:
	var bar: SkinBoosterBar = _bar(&"gumdrop")
	bar.show_boosters(Fixtures.plain_statuses(7))
	var heard: Array[StringName] = []
	bar.booster_pressed.connect(func(id: StringName) -> void: heard.append(id))
	var button: Control = _buttons(bar)[0]
	button._gui_input(_mouse(true, button.size * 0.5))
	button._gui_input(_mouse(false, button.size * 3.0))
	assert_eq(heard.size(), 0, "slid off before lifting")


func test_preferred_height_and_content_top() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(Fixtures.plain_statuses(7))
		assert_eq(bar.preferred_height(), skin.num(&"bar_height"), "%s height" % skin_id)
		var top: float = bar.content_top()
		match skin_id:
			&"gumdrop":
				assert_eq(top, skin.num(&"bar_height") - skin.num(&"dock_height"), "gumdrop dock top")
				assert_eq(top, skin.num(&"hint_height"), "gumdrop hint row above the dock")
			&"slate":
				assert_eq(top, 0.0, "slate has no hint row")
			&"nova":
				assert_true(top >= skin.num(&"hint_height"), "nova keeps the hint row above the rings")
		for button: Control in _buttons(bar):
			assert_true(button.position.y >= top - 0.01, "%s buttons sit below content_top" % skin_id)
			assert_true(button.position.y + button.size.y <= bar.size.y + 0.01, "%s buttons sit inside the bar" % skin_id)


func test_buttons_are_touch_targets() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(Fixtures.plain_statuses(7))
		for button: Control in _buttons(bar):
			assert_true(button.size.x >= skin.num(&"touch_min"), "%s button width %d" % [skin_id, button.size.x])
			assert_true(button.size.y >= skin.num(&"touch_min"), "%s button height %d" % [skin_id, button.size.y])


func test_gumdrop_buttons_fill_the_dock() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var bar: SkinBoosterBar = _bar(&"gumdrop")
	bar.show_boosters(Fixtures.plain_statuses(7))
	var buttons: Array[Control] = _buttons(bar)
	var pad: float = skin.num(&"space_xs")
	var expected_height: float = skin.num(&"dock_height") - skin.num(&"button_lip") - pad * 2.0
	var rests: Array[Rect2] = []
	for button: Control in buttons:
		var rest: Rect2 = button.call(&"rest_rect") as Rect2
		rests.append(Rect2(button.position + rest.position, rest.size))
	assert_near(rests[0].size.y, expected_height, 0.01, "face and lip fill the dock face less space_xs each side")
	assert_near(rests[0].position.x, skin.num(&"board_margin") + pad, 0.01, "first button inset")
	assert_near(rests[1].position.x - rests[0].end.x, pad, 0.01, "buttons space_xs apart")
	assert_near(rests[4].end.x, 1080.0 - skin.num(&"board_margin") - pad, 0.01, "last button inset")
	assert_near(rests[0].position.y, bar.size.y - skin.num(&"dock_height") + pad, 0.01, "space_xs under the dock's top")


func test_qa6_05_gumdrop_buttons_take_touch_on_the_whole_dock_face() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var bar: SkinBoosterBar = _bar(&"gumdrop")
	bar.show_boosters(Fixtures.plain_statuses(7))
	var buttons: Array[Control] = _buttons(bar)
	var margin: float = skin.num(&"board_margin")
	var face: float = skin.num(&"dock_height") - skin.num(&"button_lip")
	assert_near(face, 174.0, 0.01, "the dock face is 174 px")
	for i: int in buttons.size():
		var button: Control = buttons[i]
		assert_near(button.position.y, bar.size.y - skin.num(&"dock_height"), 0.01, "button %d touch starts at the dock's top" % i)
		assert_near(button.size.y, face, 0.01, "button %d takes the whole face height" % i)
		if i > 0:
			assert_near(button.position.x, buttons[i - 1].position.x + buttons[i - 1].size.x, 0.01, "button %d meets its neighbor mid gap" % i)
	assert_near(buttons[0].position.x, margin, 0.01, "the first reaches the dock's left edge")
	assert_near(buttons[4].position.x + buttons[4].size.x, 1080.0 - margin, 0.01, "the last reaches the dock's right edge")
	# The drawing does not change: the face and lip stay 187.2 by 150.
	var rest: Rect2 = buttons[2].call(&"rest_rect") as Rect2
	assert_near(rest.size.x, (1080.0 - margin * 2.0 - skin.num(&"space_xs") * 6.0) / 5.0, 0.01, "face width unchanged")
	assert_near(rest.size.y, 150.0, 0.01, "face and lip height unchanged")
	assert_near(rest.position.x, skin.num(&"space_xs") * 0.5, 0.01, "the face sits half a gap inside the touch area")


func test_hints_take_the_skin_case() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.set_hint("Tap a tile to smash it")
		var expected: String = "" if skin_id == &"slate" else skin.cased(&"label", "Tap a tile to smash it")
		assert_eq(bar.call(&"hint_text"), expected, "%s hint" % skin_id)
		bar.set_hint("")
		assert_eq(bar.call(&"hint_text"), "", "%s hint hidden" % skin_id)


## The offer with shuffle suggested and every booster usable; active is the
## index targeting, -1 for none.
func _offer(active: int) -> Array[BoosterStatus]:
	var statuses: Array[BoosterStatus] = []
	for i: int in Fixtures.BOOSTERS.size():
		statuses.append(Fixtures.status(Fixtures.BOOSTERS[i], 11, true, BoosterStatus.Usability.USABLE, i == active, i == 2))
	return statuses


func _tap(button: Control) -> void:
	button._gui_input(_mouse(true, button.size * 0.5))
	button._gui_input(_mouse(false, button.size * 0.5))


func _mouse(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event
