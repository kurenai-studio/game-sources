extends "res://tests/base_test.gd"
## The reading screens' Theme pieces in every skin (DESIGN_SYSTEM.md 7.11):
## HeadingLabel, ReadingLabel, SectionPanel, RowButton, RowDetailLabel, and
## the ScrollContainer and VScrollBar looks; plus the new icons and copy of
## the 2026-10-13 additions (4.7, 5.7, 6.7, 7.10).

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")
const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")
const StarShape: GDScript = preload("res://src/design/shared/star_shape.gd")
const STARS: Dictionary[StringName, GDScript] = {
	&"gumdrop": preload("res://src/design/gumdrop/gumdrop_icon.gd"),
	&"slate": preload("res://src/design/slate/slate_icon.gd"),
	&"nova": preload("res://src/design/nova/nova_icon.gd"),
}

var _made: Array[Node] = []


func after_each() -> void:
	for node: Node in _made:
		if is_instance_valid(node):
			node.free()
	_made.clear()


func test_reading_labels_take_their_roles() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		var roles: Dictionary[StringName, Array] = {
			&"HeadingLabel": [&"heading", &"ink"],
			&"ReadingLabel": [&"reading", &"ink_muted"],
			&"RowDetailLabel": [&"label", &"ink_muted"],
		}
		for type_name: StringName in roles:
			var role: StringName = roles[type_name][0]
			assert_true(theme.get_font(&"font", type_name) == skin.font(role), "%s %s font" % [skin_id, type_name])
			assert_eq(theme.get_font_size(&"font_size", type_name), skin.font_size(role), "%s %s size" % [skin_id, type_name])
			var color: Color = theme.get_color(&"font_color", type_name)
			assert_eq(color, skin.color(roles[type_name][1]), "%s %s color" % [skin_id, type_name])
			assert_true(Fixtures.is_listed_pair(skin, color, skin.color(Fixtures.PAGE[skin_id])), "%s %s on the page is a listed pair" % [skin_id, type_name])
		assert_eq(theme.get_constant(&"line_spacing", &"ReadingLabel"), roundi(skin.num(&"reading_line_spacing")), "%s reading line spacing" % skin_id)


func test_section_panels_follow_each_skin() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		var section: StyleBox = theme.get_stylebox(&"panel", &"SectionPanel")
		match skin_id:
			&"gumdrop":
				var card: StyleBoxFlat = section as StyleBoxFlat
				assert_true(card != null and card.bg_color == skin.color(&"surface"), "gumdrop: a surface card")
				assert_eq(card.border_color, skin.color(&"surface_lip"), "gumdrop: with its lip")
				assert_eq(card.border_width_bottom, roundi(skin.num(&"button_lip")), "gumdrop: button_lip thick")
				assert_eq(card.corner_radius_top_left, roundi(skin.num(&"radius_card")), "gumdrop: radius_card")
				assert_near(card.content_margin_left, skin.num(&"space_m"), 0.01, "gumdrop: padded space_m")
				assert_near(card.content_margin_bottom, skin.num(&"space_m") + skin.num(&"button_lip"), 0.01, "gumdrop: the lip added at the bottom")
			&"slate":
				assert_true(section is StyleBoxEmpty, "slate: no box")
				assert_near(section.content_margin_top, skin.num(&"space_m"), 0.01, "slate: space_m above")
				assert_near(section.content_margin_bottom, skin.num(&"space_m"), 0.01, "slate: and below")
				assert_near(section.content_margin_left, 0.0, 0.01, "slate: no side padding")
			&"nova":
				assert_true(section is StyleBoxEmpty, "nova: no box")
				assert_eq(section.get_minimum_size(), Vector2.ZERO, "nova: nothing at all")


func test_row_button_fills_behind_its_content_when_pressed() -> void:
	var fills: Dictionary[StringName, StringName] = {&"gumdrop": &"surface_raised", &"slate": &"surface", &"nova": &"surface_raised"}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		assert_true(theme.get_stylebox(&"normal", &"RowButton") is StyleBoxEmpty, "%s flat at rest" % skin_id)
		var pressed: StyleBoxFlat = theme.get_stylebox(&"pressed", &"RowButton") as StyleBoxFlat
		assert_true(pressed != null and pressed.bg_color == skin.color(fills[skin_id]), "%s pressed fill" % skin_id)
		var radius: int = 0 if skin_id == &"slate" else roundi(skin.num(&"radius_chip"))
		assert_eq(pressed.corner_radius_top_left, radius, "%s pressed corners" % skin_id)
		assert_near(pressed.expand_margin_left, skin.num(&"space_s"), 0.01, "%s reaches space_s past the content" % skin_id)
		assert_near(pressed.expand_margin_right, skin.num(&"space_s"), 0.01, "%s on both sides" % skin_id)
		assert_eq(pressed.get_minimum_size(), Vector2.ZERO, "%s adds no padding" % skin_id)
		assert_true(theme.get_font(&"font", &"RowButton") == skin.font(&"body"), "%s body role" % skin_id)
		var ink: Color = theme.get_color(&"font_pressed_color", &"RowButton")
		assert_true(Fixtures.is_listed_pair(skin, ink, pressed.bg_color), "%s pressed text on a listed pair" % skin_id)


func test_scroll_indicator_looks() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		var margin: float = skin.num(&"board_margin")
		var bar: float = skin.num(&"scroll_bar")
		assert_true(theme.get_stylebox(&"panel", &"ScrollContainer") is StyleBoxEmpty, "%s no scroll panel" % skin_id)
		assert_eq(theme.get_constant(&"scrollbar_v_separation", &"ScrollContainer"), 0, "%s the bar sits at the content's edge" % skin_id)
		var track: StyleBox = theme.get_stylebox(&"scroll", &"VScrollBar")
		assert_true(track is StyleBoxEmpty, "%s no track" % skin_id)
		assert_near(track.get_minimum_size().x, margin, 0.01, "%s the bar is board_margin wide" % skin_id)
		for icon: StringName in [&"increment", &"decrement"]:
			assert_eq(theme.get_icon(icon, &"VScrollBar").get_size(), Vector2.ZERO, "%s no %s arrow" % [skin_id, icon])
		var colors: Dictionary[StringName, StringName] = {&"grabber": &"line", &"grabber_highlight": &"line", &"grabber_pressed": &"ink_muted"}
		for item: StringName in colors:
			var grab: StyleBoxFlat = theme.get_stylebox(item, &"VScrollBar") as StyleBoxFlat
			assert_true(grab != null and grab.bg_color == skin.color(colors[item]), "%s %s color" % [skin_id, item])
			assert_near(margin + grab.expand_margin_left + grab.expand_margin_right, bar, 0.01, "%s %s draws scroll_bar wide" % [skin_id, item])
			assert_true(grab.get_minimum_size().y >= 96.0, "%s %s at least 96 px long" % [skin_id, item])
			assert_eq(grab.corner_radius_top_left, 0 if skin_id == &"slate" else roundi(bar * 0.5), "%s %s ends" % [skin_id, item])
		# A real scroll bar takes that width. Outside the scene tree Godot
		# sends no theme notification; send it as the engine does in the tree.
		var scroll: VScrollBar = VScrollBar.new()
		_made.append(scroll)
		scroll.theme = theme
		scroll.notification(Control.NOTIFICATION_THEME_CHANGED)
		assert_near(scroll.get_combined_minimum_size().x, margin, 0.01, "%s a VScrollBar is board_margin wide" % skin_id)


func test_new_icons_draw_on_the_grid() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var icon: SkinIcon = UiKit.make_icon(skin)
		_made.append(icon)
		for icon_name: StringName in [&"star", &"chevron", &"arrow"]:
			assert_true(SkinIcon.ICON_NAMES.has(icon_name), "%s is a listed icon" % icon_name)
			icon.set_icon(icon_name)
			assert_true(int(icon.call(&"drawn_parts")) > 0, "%s %s draws" % [skin_id, icon_name])
			var expected: StringName = &"ink_muted" if icon_name != &"star" else &"ink"
			assert_eq(icon.call(&"ink"), skin.color(expected), "%s %s draws in %s" % [skin_id, icon_name, expected])
		icon.set_look(SkinIcon.LOOK_DISABLED)
		icon.set_icon(&"chevron")
		var disabled: Color = skin.color(&"disabled_ink")
		if skin_id == &"nova":
			disabled.a *= skin.num(&"disabled_icon_alpha")
		assert_true((icon.call(&"ink") as Color).is_equal_approx(disabled), "%s a disabled chevron" % skin_id)


func test_star_geometry_matches_the_design() -> void:
	var inner: Dictionary[StringName, float] = {&"gumdrop": 0.50, &"slate": 0.42, &"nova": 0.40}
	for skin_id: StringName in SkinCatalog.IDS:
		var star: Dictionary = STARS[skin_id].get(&"STAR") as Dictionary
		assert_eq(star["center"], Vector2(12.0, 12.9), "%s center" % skin_id)
		assert_eq(float(star["outer"]), 11.0, "%s outer radius" % skin_id)
		assert_eq(float(star["inner_share"]), inner[skin_id], "%s inner radius" % skin_id)
		var outline: PackedVector2Array = StarShape.outline(star)
		var bounds: Vector2 = StarShape.y_range(outline)
		assert_true(bounds.x >= 0.0 and bounds.y <= 24.0, "%s inside the 24 unit grid" % skin_id)
		# The fill lines sit at about 35% and 55% of the star's height above
		# its lowest points (4.7: measured 35.3% and 54.8%; Nova 36% and
		# 55%), the height taken between the sharp points the corners round.
		var center: Vector2 = star["center"]
		var top: float = center.y - float(star["outer"])
		var bottom: float = center.y + float(star["outer"]) * cos(deg_to_rad(36.0))
		for share: Vector2 in [Vector2(1.0 / 3.0, 0.355), Vector2(2.0 / 3.0, 0.55)]:
			var cut: float = StarShape.fill_cut(outline, share.x)
			assert_near((bottom - cut) / (bottom - top), share.y, 0.02, "%s fill line for %.2f" % [skin_id, share.x])
		var area: float = StarShape.area(outline)
		var below: float = 0.0
		for part: PackedVector2Array in StarShape.fill_parts(outline, 1.0 / 3.0):
			below += StarShape.area(part)
		assert_near(below / area, 1.0 / 3.0, 0.002, "%s a third of the area" % skin_id)


func test_counter_star_draws_every_step_at_its_sizes() -> void:
	const CounterStar: GDScript = preload("res://src/design/shared/counter_star.gd")
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var star: Control = CounterStar.new()
		_made.append(star)
		star.call(&"setup", STARS[skin_id].get(&"STAR") as Dictionary, skin.color(&"accent"), skin.num(&"star_icon"))
		for steps: int in 4:
			star.call(&"show_progress", steps, 1.0, skin.color(&"accent"))
			assert_eq(int(star.call(&"steps")), steps, "%s step %d" % [skin_id, steps])
		var fills: Array[PackedVector2Array] = star.get(&"_fill_points") as Array[PackedVector2Array]
		assert_true(fills.size() >= 3, "%s a fill shape for every step" % skin_id)
		assert_eq(star.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s ignores the mouse" % skin_id)


func test_new_copy_takes_each_case() -> void:
	var expected: Dictionary[StringName, PackedStringArray] = {
		&"gumdrop": PackedStringArray(["+2", "Free", "1 free", "Stars"]),
		&"slate": PackedStringArray(["+2", "FREE", "1 FREE", "STARS"]),
		&"nova": PackedStringArray(["+2", "free", "1 free", "stars"]),
	}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var got: PackedStringArray = PackedStringArray([
			UiCopy.stars_earned(skin, &"label", 2), UiCopy.free_cost(skin, &"label"),
			UiCopy.free_held(skin, &"label", 1), UiCopy.stars_caption(skin, &"label"),
		])
		assert_eq(got, expected[skin_id], "%s copy" % skin_id)
