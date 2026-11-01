extends "res://tests/base_test.gd"
## UiKit's factories, the icons, the toggles and the backdrops for every
## skin (docs/ARCHITECTURE.md section 7, DESIGN_SYSTEM.md 4.7, 5.7, 6.7).

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")

var _made: Array[Node] = []


func after_each() -> void:
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func _keep(node: Node) -> Node:
	_made.append(node)
	return node


func test_factories_return_the_base_classes() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var made: Array[Node] = [
			_keep(UiKit.make_hud(skin)),
			_keep(UiKit.make_booster_bar(skin)),
			_keep(UiKit.make_icon(skin)),
			_keep(UiKit.make_toggle(skin)),
			_keep(UiKit.make_backdrop(skin)),
		]
		assert_true(made[0] is SkinHud, "%s hud" % skin_id)
		assert_true(made[1] is SkinBoosterBar, "%s booster bar" % skin_id)
		assert_true(made[2] is SkinIcon, "%s icon" % skin_id)
		assert_true(made[3] is SkinToggle, "%s toggle" % skin_id)
		assert_true(made[4] is SkinBackdrop, "%s backdrop" % skin_id)
		for node: Node in made:
			var path: String = (node.get_script() as Script).resource_path
			assert_true(path.begins_with("res://src/design/%s/" % skin_id), "%s component comes from its own folder: %s" % [skin_id, path])


func test_every_icon_draws_in_every_look() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var icon: SkinIcon = _keep(UiKit.make_icon(skin)) as SkinIcon
		assert_eq(icon.size, Vector2(skin.num(&"icon_hud"), skin.num(&"icon_hud")), "%s icon starts icon_hud" % skin_id)
		for icon_name: StringName in SkinIcon.ICON_NAMES:
			icon.set_icon(icon_name)
			for look: int in [SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_DISABLED]:
				icon.set_look(look)
				for side: float in [24.0, skin.num(&"icon_booster"), 512.0]:
					icon.size = Vector2(side, side)
					assert_true(int(icon.call(&"drawn_parts")) > 0, "%s %s look %d at %d px draws" % [skin_id, icon_name, look, side])


func test_icon_looks_use_the_design_colors() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var icon: SkinIcon = _keep(UiKit.make_icon(skin)) as SkinIcon
		icon.set_icon(&"hammer")
		icon.set_look(SkinIcon.LOOK_NORMAL)
		assert_eq(icon.call(&"ink"), skin.color(&"ink"), "%s normal" % skin_id)
		icon.set_look(SkinIcon.LOOK_ACTIVE)
		assert_eq(icon.call(&"ink"), skin.color(&"ink_dark"), "%s active sits on the active fill" % skin_id)
		icon.set_look(SkinIcon.LOOK_DISABLED)
		var disabled: Color = skin.color(&"disabled_ink")
		if skin_id == &"nova":
			disabled.a *= skin.num(&"disabled_icon_alpha")
		assert_true((icon.call(&"ink") as Color).is_equal_approx(disabled), "%s disabled" % skin_id)


func test_set_color_overrides_the_look() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var icon: SkinIcon = _keep(UiKit.make_icon(skin)) as SkinIcon
		icon.set_icon(&"close")
		icon.set_color(skin.color(&"ink_dark"))
		icon.set_look(SkinIcon.LOOK_NORMAL)
		assert_eq(icon.call(&"ink"), skin.color(&"ink_dark"), "%s override stays across set_look" % skin_id)


func test_toggles_switch_without_emitting() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var toggle: SkinToggle = _keep(UiKit.make_toggle(skin)) as SkinToggle
		var heard: Array[bool] = []
		toggle.toggled.connect(func(on: bool) -> void: heard.append(on))
		assert_false(bool(toggle.call(&"is_on")), "%s starts off" % skin_id)
		toggle.set_on(true)
		assert_true(bool(toggle.call(&"is_on")), "%s on" % skin_id)
		toggle.set_on(false, true)
		assert_false(bool(toggle.call(&"is_on")), "%s off" % skin_id)
		assert_eq(heard.size(), 0, "%s set_on never emits" % skin_id)


func test_toggle_tap_flips_and_emits() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var toggle: SkinToggle = _keep(UiKit.make_toggle(skin)) as SkinToggle
		var heard: Array[bool] = []
		toggle.toggled.connect(func(on: bool) -> void: heard.append(on))
		for down: bool in [true, false]:
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			event.position = toggle.size * 0.5
			toggle._gui_input(event)
		assert_eq(heard, [true] as Array[bool], "%s tap turns it on" % skin_id)


func test_slate_toggle_shows_its_words() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var toggle: SkinToggle = _keep(UiKit.make_toggle(skin)) as SkinToggle
	toggle.set_on(true)
	assert_eq(toggle.call(&"word"), "ON", "on word")
	toggle.set_on(false)
	assert_eq(toggle.call(&"word"), "OFF", "off word")


func test_toggles_are_touch_targets() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var toggle: SkinToggle = _keep(UiKit.make_toggle(skin)) as SkinToggle
		assert_true(toggle.custom_minimum_size.x >= skin.num(&"touch_min"), "%s toggle width" % skin_id)
		assert_true(toggle.custom_minimum_size.y >= skin.num(&"touch_min"), "%s toggle height" % skin_id)
		assert_true(toggle.size.x >= skin.num(&"touch_min") and toggle.size.y >= skin.num(&"touch_min"), "%s toggle size" % skin_id)


func test_backdrops_ignore_input() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var backdrop: SkinBackdrop = _keep(UiKit.make_backdrop(SkinCatalog.get_skin(skin_id))) as SkinBackdrop
		assert_eq(backdrop.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s backdrop" % skin_id)
		backdrop.set_clear_rects([Rect2(0.0, 0.0, 10.0, 10.0)])


func test_nova_star_dust_keeps_clear_of_text() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"nova")
	var backdrop: SkinBackdrop = _keep(UiKit.make_backdrop(skin)) as SkinBackdrop
	backdrop.size = Vector2(1080.0, 2400.0)
	backdrop.set_clear_rects([])
	var all: int = int(backdrop.call(&"star_count"))
	assert_eq(all, int(skin.num(&"star_count")), "every star with nothing to avoid")
	backdrop.set_clear_rects([Rect2(0.0, 0.0, 1080.0, 1200.0)])
	var some: int = int(backdrop.call(&"star_count"))
	assert_true(some < all and some > 0, "stars over the text rect are left out")
	backdrop.set_clear_rects([Rect2(-100.0, -100.0, 1300.0, 2700.0)])
	assert_eq(int(backdrop.call(&"star_count")), 0, "no star under a full screen text rect")
