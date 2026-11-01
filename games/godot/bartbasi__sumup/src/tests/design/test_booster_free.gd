extends "res://tests/base_test.gd"
## Free on the booster bar (GDD D-46, DESIGN_SYSTEM.md 4.7, 5.7, 6.7), the
## bar laid out inside a content column narrower than the screen (QA6-08),
## and every booster button's touch area (QA6-05).

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")
const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")

## The Free group's color for each look: normal, active, disabled.
const FREE_COLORS: Dictionary[StringName, Array] = {
	&"gumdrop": [&"badge", &"ink_dark", &"disabled_ink"],
	&"slate": [&"accent", &"ink_dark", &"disabled_ink"],
	&"nova": [&"accent", &"accent", &"disabled_ink"],
}

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


func _bar(skin_id: StringName, width: float = 1080.0) -> SkinBoosterBar:
	var bar: SkinBoosterBar = UiKit.make_booster_bar(SkinCatalog.get_skin(skin_id))
	_made.append(bar)
	bar.size = Vector2(width, bar.preferred_height())
	bar.notification(Control.NOTIFICATION_RESIZED)
	return bar


## The buttons, laid out for their size: outside the scene tree Godot sends
## no resize notification, so send it as the engine does in the tree.
func _buttons(bar: SkinBoosterBar) -> Array[Control]:
	var buttons: Array[Control] = bar.call(&"buttons") as Array[Control]
	for button: Control in buttons:
		button.notification(Control.NOTIFICATION_RESIZED)
	return buttons


func test_a_status_with_free_shows_free_disabled_included() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(Fixtures.free_statuses())
		var looks: Array[int] = [SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_DISABLED]
		for i: int in 5:
			var button: Control = _buttons(bar)[i]
			assert_true(bool(button.get(&"free")), "%s button %d reads Free" % [skin_id, i])
			assert_eq(button.get(&"free_text"), UiCopy.free_cost(skin, &"label"), "%s Free copy" % skin_id)
			assert_eq(button.get(&"cost_text"), "4K", "%s the cost is kept (AT-56)" % skin_id)
			assert_eq(button.get(&"look"), looks[i], "%s button %d keeps its look" % [skin_id, i])
			var star: SkinIcon = button.call(&"free_star") as SkinIcon
			assert_true(star != null and star.visible, "%s button %d shows the star" % [skin_id, i])
			var label: float = float(skin.font_size(&"label"))
			assert_near(star.size.x, label, 0.01, "%s the star's box is the label size" % skin_id)
			assert_near(star.size.y, label, 0.01, "%s the star's box is square" % skin_id)
			var color_name: StringName = FREE_COLORS[skin_id][[SkinIcon.LOOK_NORMAL, SkinIcon.LOOK_ACTIVE, SkinIcon.LOOK_DISABLED].find(looks[i])]
			assert_eq(star.call(&"ink"), skin.color(color_name), "%s button %d star in %s" % [skin_id, i, color_name])
			assert_eq(star.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s the star leaves taps to the button" % skin_id)
		assert_eq(UiCopy.free_cost(skin, &"label"), {&"gumdrop": "Free", &"slate": "FREE", &"nova": "free"}[skin_id], "%s cased" % skin_id)


func test_free_sits_where_the_cost_was() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(Fixtures.free_statuses())
		var button: Control = _buttons(bar)[2]
		var star: SkinIcon = button.call(&"free_star") as SkinIcon
		var label: float = float(skin.font_size(&"label"))
		var word: float = skin.font(&"label").get_string_size(UiCopy.free_cost(skin, &"label"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, skin.font_size(&"label")).x
		var group: float = label * 1.25 + word
		var left: float = star.position.x
		match skin_id:
			&"slate":
				assert_near(left, skin.num(&"space_s"), 0.01, "slate: left aligned where the cost was")
			&"gumdrop":
				var rest: Rect2 = button.call(&"rest_rect") as Rect2
				assert_near(left + group * 0.5, rest.get_center().x, 0.01, "gumdrop: centered on the face")
				assert_true(group <= 120.0, "gumdrop: the group is at most 120 px (%d)" % group)
			&"nova":
				assert_near(left + group * 0.5, button.size.x * 0.5, 0.01, "nova: centered under the ring")


func test_free_goes_when_none_is_held() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var bar: SkinBoosterBar = _bar(skin_id)
		bar.show_boosters(Fixtures.free_statuses())
		bar.show_boosters(Fixtures.plain_statuses(7))
		for button: Control in _buttons(bar):
			assert_false(bool(button.get(&"free")), "%s the cost is back" % skin_id)
			var star: SkinIcon = button.call(&"free_star") as SkinIcon
			assert_true(star == null or not star.visible, "%s no star" % skin_id)
			assert_eq(button.get(&"cost_text"), "128", "%s shows its cost" % skin_id)


func test_qa6_05_every_booster_touch_area_is_at_least_touch_min() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for width: float in [1080.0, 1200.0, 1220.0]:
			var bar: SkinBoosterBar = _bar(skin_id, width)
			bar.show_boosters(Fixtures.plain_statuses(7))
			for button: Control in _buttons(bar):
				assert_true(button.size.x >= skin.num(&"touch_min") and button.size.y >= skin.num(&"touch_min"), "%s at %d: touch area %s" % [skin_id, width, button.size])


func test_qa6_08_the_bar_lays_out_inside_a_narrow_column() -> void:
	# A 1,220 px column (the Fold5 inner screen is 1,998 px wide).
	var width: float = 1220.0
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var bar: SkinBoosterBar = _bar(skin_id, width)
		bar.show_boosters(Fixtures.plain_statuses(7))
		var buttons: Array[Control] = _buttons(bar)
		var margin: float = skin.num(&"board_margin")
		match skin_id:
			&"gumdrop":
				assert_near(buttons[0].position.x, margin, 0.01, "gumdrop: the dock sits board_margin inside the column")
				assert_near(buttons[4].position.x + buttons[4].size.x, width - margin, 0.01, "gumdrop: on both sides")
			&"slate":
				assert_near(buttons[0].position.x, 0.0, 0.01, "slate: the strip spans the column")
				assert_near(buttons[4].position.x + buttons[4].size.x, width, 0.51, "slate: to its right edge")
				var rules: Array[Rect2] = bar.get(&"_rules") as Array[Rect2]
				assert_near(rules[0].size.x, width, 0.01, "slate: the top hairline spans the column")
			&"nova":
				assert_near(buttons[0].position.x, margin, 0.01, "nova: the rings spread from the margin")
				assert_near(buttons[4].position.x + buttons[4].size.x, width - margin, 0.01, "nova: to the other margin")
		for button: Control in buttons:
			assert_true(button.position.x >= -0.01 and button.position.x + button.size.x <= width + 0.51, "%s button inside the column" % skin_id)


func test_qa6_05_icon_buttons_and_toggles_keep_their_drawn_sizes() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var touch: float = skin.num(&"touch_min")
		var button: BaseButton = UiKit.make_icon_button(skin, &"close")
		_made.append(button)
		assert_eq(button.size, Vector2(touch, touch), "%s icon button touch area" % skin_id)
		var styles: Dictionary[StringName, StyleBox] = button.get(&"_styles")
		var face: Rect2 = button.call(&"_face", styles[&"normal"]) as Rect2
		match skin_id:
			&"gumdrop":
				assert_near(face.size.x, skin.num(&"hud_button_face"), 0.01, "gumdrop face stays hud_button_face")
				assert_near(face.size.y, skin.num(&"hud_button_face"), 0.01, "gumdrop face height")
			&"nova":
				assert_near(face.size.x, skin.num(&"hud_ring"), 0.01, "nova ring stays hud_ring")
		var icon: SkinIcon = button.call(&"icon_view") as SkinIcon
		assert_eq(icon.size, Vector2(skin.num(&"icon_hud"), skin.num(&"icon_hud")), "%s icon stays icon_hud" % skin_id)
		var toggle: SkinToggle = UiKit.make_toggle(skin)
		_made.append(toggle)
		assert_eq(toggle.custom_minimum_size, Vector2(maxf(skin.num(&"toggle_w"), touch), maxf(skin.num(&"toggle_h"), touch)), "%s toggle touch area" % skin_id)
		assert_eq(toggle.get(&"_track_size"), Vector2(skin.num(&"toggle_w"), skin.num(&"toggle_h")), "%s the track keeps its size" % skin_id)
