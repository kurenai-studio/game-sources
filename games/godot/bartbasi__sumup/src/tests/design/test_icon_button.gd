extends "res://tests/base_test.gd"
## UiKit.make_icon_button for every skin: a set up BaseButton of at least
## touch_min, every icon name drawn on it, the built-in pressed signal on a
## tap, nothing when disabled, and the icon following Gumdrop's pressed face.

var _made: Array[Node] = []


func before_each() -> void:
	# The runner works before the scene tree starts, where bound tweens never
	# step; Motion makes unbound tweens while this is off.
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


func _button(skin_id: StringName, icon_name: StringName) -> BaseButton:
	var button: BaseButton = UiKit.make_icon_button(SkinCatalog.get_skin(skin_id), icon_name)
	_made.append(button)
	return button


func _icon(button: BaseButton) -> SkinIcon:
	return button.call(&"icon_view") as SkinIcon


func test_each_skin_returns_a_set_up_touch_target() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var button: BaseButton = _button(skin_id, &"settings")
		assert_true(button is BaseButton, "%s is a BaseButton" % skin_id)
		var path: String = (button.get_script() as Script).resource_path
		assert_true(path.begins_with("res://src/design/%s/" % skin_id), "%s comes from its own folder: %s" % [skin_id, path])
		var touch: float = skin.num(&"touch_min")
		assert_true(button.size.x >= touch and button.size.y >= touch, "%s size %s is at least touch_min" % [skin_id, button.size])
		assert_true(button.custom_minimum_size.x >= touch and button.custom_minimum_size.y >= touch, "%s minimum size is at least touch_min" % skin_id)
		var icon: SkinIcon = _icon(button)
		assert_true(icon != null and button.is_ancestor_of(icon), "%s has its icon" % skin_id)
		assert_eq(icon.size, Vector2(skin.num(&"icon_hud"), skin.num(&"icon_hud")), "%s icon is icon_hud" % skin_id)
		assert_eq(icon.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s the icon leaves touches to the button" % skin_id)
		assert_eq(button.call(&"state"), &"normal", "%s starts normal" % skin_id)


func test_every_icon_name_draws() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		for icon_name: StringName in SkinIcon.ICON_NAMES:
			var icon: SkinIcon = _icon(_button(skin_id, icon_name))
			assert_true(int(icon.call(&"drawn_parts")) > 0, "%s %s draws" % [skin_id, icon_name])


func test_a_tap_emits_pressed() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var button: BaseButton = _button(skin_id, &"close")
		var heard: Array[bool] = []
		button.pressed.connect(func() -> void: heard.append(true))
		button._gui_input(_mouse(true, button.size * 0.5))
		assert_eq(button.call(&"state"), &"pressed", "%s shows pressed while held" % skin_id)
		assert_eq(heard.size(), 0, "%s nothing until the finger lifts" % skin_id)
		button._gui_input(_mouse(false, button.size * 0.5))
		assert_eq(heard.size(), 1, "%s pressed fires once" % skin_id)
		assert_eq(button.call(&"state"), &"normal", "%s back to normal" % skin_id)


func test_lifting_outside_or_disabled_does_not_emit() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var button: BaseButton = _button(skin_id, &"close")
		var heard: Array[bool] = []
		button.pressed.connect(func() -> void: heard.append(true))
		button._gui_input(_mouse(true, button.size * 0.5))
		button._gui_input(_mouse(false, button.size * 2.0))
		assert_eq(heard.size(), 0, "%s slid off before lifting" % skin_id)
		button.disabled = true
		assert_eq(button.call(&"state"), &"disabled", "%s shows disabled" % skin_id)
		button._gui_input(_mouse(true, button.size * 0.5))
		button._gui_input(_mouse(false, button.size * 0.5))
		assert_eq(heard.size(), 0, "%s disabled ignores taps" % skin_id)


func test_disabled_icon_takes_the_disabled_look() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var button: BaseButton = _button(skin_id, &"settings")
		button.disabled = true
		button.call(&"_place_icon")
		assert_eq(_icon(button).call(&"look"), SkinIcon.LOOK_DISABLED, "%s disabled icon" % skin_id)


func test_gumdrop_icon_follows_the_face() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var button: BaseButton = _button(&"gumdrop", &"settings")
	var icon: SkinIcon = _icon(button)
	assert_near(icon.position.y + icon.size.y * 0.5, button.size.y * 0.5, 0.01, "the face is centered in the button")
	var rest_y: float = icon.position.y
	button._gui_input(_mouse(true, button.size * 0.5))
	button.call(&"_place_icon")
	var sink: float = skin.num(&"button_lip") - skin.num(&"button_lip_pressed")
	assert_near(icon.position.y - rest_y, sink, 0.01, "the icon sinks with the pressed face")
	button._gui_input(_mouse(false, button.size * 0.5))
	button.disabled = true
	button.call(&"_place_icon")
	assert_near(icon.position.y - rest_y, skin.num(&"button_lip"), 0.01, "the icon drops with the flat disabled face")


func test_toggle_mode_flips_and_shows_pressed() -> void:
	var button: BaseButton = _button(&"nova", &"sound_on")
	button.toggle_mode = true
	button._gui_input(_mouse(true, button.size * 0.5))
	button._gui_input(_mouse(false, button.size * 0.5))
	assert_true(button.button_pressed, "a tap turns a toggle on")
	assert_eq(button.call(&"state"), &"pressed", "and it shows pressed")


func test_styles_match_the_theme() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		var button: BaseButton = _button(skin_id, &"check")
		var styles: Dictionary[StringName, StyleBox] = button.get(&"_styles")
		for state: StringName in [&"normal", &"pressed", &"disabled"]:
			var mine: StyleBox = styles[state]
			var themed: StyleBox = theme.get_stylebox(state, &"IconButton")
			assert_eq(mine.get_class(), themed.get_class(), "%s %s kind" % [skin_id, state])
			assert_eq(mine.get_minimum_size(), themed.get_minimum_size(), "%s %s size" % [skin_id, state])
			if mine is StyleBoxFlat:
				assert_eq((mine as StyleBoxFlat).bg_color, (themed as StyleBoxFlat).bg_color, "%s %s fill" % [skin_id, state])
				assert_eq((mine as StyleBoxFlat).border_color, (themed as StyleBoxFlat).border_color, "%s %s edge" % [skin_id, state])


func _mouse(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event
