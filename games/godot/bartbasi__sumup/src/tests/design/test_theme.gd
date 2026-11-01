extends "res://tests/base_test.gd"
## UiKit.build_theme for every skin: every variation, every button state,
## text only on listed text pairs, and buttons a thumb can hit
## (docs/ARCHITECTURE.md section 7, DESIGN_SYSTEM.md 1.4, 2.7 and 7.8).

const Fixtures: GDScript = preload("res://tests/design/design_fixtures.gd")
const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")


func test_every_contract_variation_is_defined() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var theme: Theme = UiKit.build_theme(SkinCatalog.get_skin(skin_id))
		for type_name: StringName in Fixtures.CONTRACT_VARIATIONS:
			assert_eq(theme.get_type_variation_base(type_name), Fixtures.CONTRACT_VARIATIONS[type_name], "%s %s base" % [skin_id, type_name])


func test_every_added_variation_is_defined() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var theme: Theme = UiKit.build_theme(SkinCatalog.get_skin(skin_id))
		for type_name: StringName in Fixtures.ADDED_VARIATIONS:
			assert_eq(theme.get_type_variation_base(type_name), Fixtures.ADDED_VARIATIONS[type_name], "%s %s base" % [skin_id, type_name])
	# The code's list is exactly the contract plus the additions.
	assert_eq(ThemeKit.VARIATIONS.size(), Fixtures.CONTRACT_VARIATIONS.size() + Fixtures.ADDED_VARIATIONS.size(), "variation count")


func test_default_font_is_the_body_role() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		assert_true(theme.default_font == skin.font(&"body"), "%s default font" % skin_id)
		assert_eq(theme.default_font_size, skin.font_size(&"body"), "%s default size" % skin_id)


func test_every_button_type_has_every_state() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var theme: Theme = UiKit.build_theme(SkinCatalog.get_skin(skin_id))
		for type_name: StringName in Fixtures.BUTTON_TYPES:
			for state: StringName in Fixtures.BUTTON_STATES:
				assert_true(theme.has_stylebox(state, type_name), "%s %s has %s" % [skin_id, type_name, state])
			for color_name: StringName in Fixtures.BUTTON_COLORS:
				assert_true(theme.has_color(color_name, type_name), "%s %s has %s" % [skin_id, type_name, color_name])
			assert_true(theme.has_font(&"font", type_name), "%s %s font" % [skin_id, type_name])
			assert_true(theme.has_font_size(&"font_size", type_name), "%s %s font size" % [skin_id, type_name])


func test_label_types_have_font_size_and_color() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var theme: Theme = UiKit.build_theme(SkinCatalog.get_skin(skin_id))
		for type_name: StringName in [&"Label", &"DisplayLabel", &"TitleLabel", &"BodyLabel", &"MutedLabel", &"CaptionLabel", &"BadgeLabel", &"SignalLabel", &"HintLabel"]:
			assert_true(theme.has_font(&"font", type_name), "%s %s font" % [skin_id, type_name])
			assert_true(theme.has_font_size(&"font_size", type_name), "%s %s size" % [skin_id, type_name])
			assert_true(theme.has_color(&"font_color", type_name), "%s %s color" % [skin_id, type_name])


func test_label_roles_match_the_design() -> void:
	var roles: Dictionary[StringName, StringName] = {
		&"DisplayLabel": &"display", &"TitleLabel": &"title", &"BodyLabel": &"body",
		&"MutedLabel": &"body", &"CaptionLabel": &"label", &"BadgeLabel": &"label", &"HintLabel": &"label",
	}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		for type_name: StringName in roles:
			assert_true(theme.get_font(&"font", type_name) == skin.font(roles[type_name]), "%s %s font" % [skin_id, type_name])
			assert_eq(theme.get_font_size(&"font_size", type_name), skin.font_size(roles[type_name]), "%s %s size" % [skin_id, type_name])
		# Slate's signal label is the label role in accent; the others use the title.
		var signal_role: StringName = &"label" if skin_id == &"slate" else &"title"
		assert_eq(theme.get_font_size(&"font_size", &"SignalLabel"), skin.font_size(signal_role), "%s SignalLabel size" % skin_id)


func test_label_colors_are_listed_text_colors() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		for type_name: StringName in [&"Label", &"DisplayLabel", &"TitleLabel", &"BodyLabel", &"MutedLabel", &"CaptionLabel", &"SignalLabel", &"HintLabel"]:
			var color: Color = theme.get_color(&"font_color", type_name)
			assert_true(Fixtures.is_listed_pair(skin, color, skin.color(Fixtures.PAGE[skin_id])) or Fixtures.is_listed_text_color(skin, color), "%s %s color is listed" % [skin_id, type_name])
		assert_true(Fixtures.is_listed_pair(skin, theme.get_color(&"font_color", &"BadgeLabel"), skin.color(&"badge")), "%s BadgeLabel on badge" % skin_id)


func test_button_text_sits_on_listed_pairs() -> void:
	var states: Dictionary[StringName, StringName] = {&"normal": &"font_color", &"pressed": &"font_pressed_color", &"disabled": &"font_disabled_color"}
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		for type_name: StringName in [&"PrimaryButton", &"SecondaryButton", &"ChipButton"]:
			for state: StringName in states:
				var face: Color = Fixtures.face_color(skin, theme.get_stylebox(state, type_name))
				var ink: Color = theme.get_color(states[state], type_name)
				assert_true(Fixtures.is_listed_pair(skin, ink, face), "%s %s %s: %s on %s is listed" % [skin_id, type_name, state, ink.to_html(), face.to_html()])


func test_buttons_are_button_height_tall() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		var line: float = ThemeKit.line_height(skin, &"body")
		for type_name: StringName in [&"PrimaryButton", &"SecondaryButton", &"ChipButton"]:
			for state: StringName in [&"normal", &"pressed", &"disabled"]:
				var height: float = theme.get_stylebox(state, type_name).get_minimum_size().y + line
				assert_near(height, skin.num(&"button_height"), 1.0, "%s %s %s height" % [skin_id, type_name, state])
				assert_true(height >= skin.num(&"touch_min") - 1.0, "%s %s %s is a touch target" % [skin_id, type_name, state])
		# An icon button's styles alone make it touch_min square.
		var icon_size: Vector2 = theme.get_stylebox(&"normal", &"IconButton").get_minimum_size()
		assert_eq(icon_size, Vector2(skin.num(&"touch_min"), skin.num(&"touch_min")), "%s IconButton size" % skin_id)


func test_panels_and_dividers() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var theme: Theme = UiKit.build_theme(skin)
		for type_name: StringName in [&"CardPanel", &"PillPanel", &"HintPanel", &"BadgePanel"]:
			assert_true(theme.has_stylebox(&"panel", type_name), "%s %s panel" % [skin_id, type_name])
		var card: StyleBox = theme.get_stylebox(&"panel", &"CardPanel")
		assert_near(card.content_margin_left, skin.num(&"space_m"), 0.01, "%s card padding" % skin_id)
		var badge: StyleBoxFlat = theme.get_stylebox(&"panel", &"BadgePanel") as StyleBoxFlat
		assert_true(badge != null and badge.bg_color.is_equal_approx(skin.color(&"badge")), "%s badge fill" % skin_id)
		assert_near(badge.content_margin_left, skin.num(&"space_s"), 0.01, "%s badge side padding" % skin_id)
		for type_name: StringName in [&"Hairline", &"HSeparator"]:
			var line: StyleBoxFlat = theme.get_stylebox(&"separator", type_name) as StyleBoxFlat
			assert_true(line != null and line.bg_color.is_equal_approx(skin.color(&"line")), "%s %s color" % [skin_id, type_name])
			assert_near(line.get_minimum_size().y, skin.num(&"hairline"), 0.01, "%s %s thickness" % [skin_id, type_name])
			assert_eq(theme.get_constant(&"separation", type_name), roundi(skin.num(&"hairline")), "%s %s separation" % [skin_id, type_name])
