# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Contrast, checked by script (WCAG 2 formula): every text pair reaches
## 4.5:1 and every graphic pair 3:1, both for the palette's listed pairs and
## for every text color the UI theme actually puts on a background.

const TEXT_MIN: float = 4.5
const GRAPHIC_MIN: float = 3.0
const BUTTON_TYPES: Array[StringName] = [&"Button", &"PrimaryButton", &"CardButton", &"QuietButton"]
## Each text color in a button and the stylebox it sits on.
const BUTTON_STATES: Array[Array] = [
	[&"font_color", &"normal"], [&"font_hover_color", &"hover"], [&"font_pressed_color", &"pressed"],
	[&"font_hover_pressed_color", &"hover_pressed"], [&"font_disabled_color", &"disabled"],
]


func test_formula_matches_known_values() -> void:
	assert_near(Palette.contrast(Color.BLACK, Color.WHITE), 21.0, 0.001)
	assert_near(Palette.contrast(Palette.PANEL, Palette.PANEL), 1.0, 0.001)
	assert_near(Palette.contrast(Color("767676"), Color.WHITE), 4.54, 0.01, "the classic grey on white")


func test_every_text_pair_reaches_4_5() -> void:
	_check_pairs(Palette.text_pairs(), TEXT_MIN)


func test_every_graphic_pair_reaches_3() -> void:
	_check_pairs(Palette.graphic_pairs(), GRAPHIC_MIN)


func test_every_button_text_reaches_4_5() -> void:
	var theme: Theme = UiTheme.build()
	for type: StringName in BUTTON_TYPES:
		for state: Array in BUTTON_STATES:
			var color_name: StringName = state[0]
			var box_name: StringName = state[1]
			assert_true(theme.has_color(color_name, type), "%s has %s" % [type, color_name])
			assert_true(theme.has_stylebox(box_name, type), "%s has %s" % [type, box_name])
			var text: Color = theme.get_color(color_name, type)
			var box: StyleBoxFlat = theme.get_stylebox(box_name, type) as StyleBoxFlat
			assert_not_null(box, "%s %s is a StyleBoxFlat" % [type, box_name])
			if box == null:
				continue
			# A see-through button (QuietButton) sits on a panel.
			var bg: Color = Palette.PANEL.blend(box.bg_color)
			var ratio: float = Palette.contrast(text, bg)
			assert_true(ratio >= TEXT_MIN, "%s %s on %s: %.2f:1, needs %.1f:1" % [type, color_name, box_name, ratio, TEXT_MIN])


func test_every_label_text_reaches_4_5() -> void:
	var theme: Theme = UiTheme.build()
	var backgrounds: Dictionary[StringName, Array] = UiTheme.label_backgrounds()
	assert_true(backgrounds.size() >= 5)
	for type: StringName in backgrounds:
		var text: Color = theme.get_color(&"font_color", type)
		for bg: Color in backgrounds[type]:
			var ratio: float = Palette.contrast(text, bg)
			assert_true(ratio >= TEXT_MIN, "%s on #%s: %.2f:1, needs %.1f:1" % [type, bg.to_html(false), ratio, TEXT_MIN])


func test_panels_are_opaque() -> void:
	var theme: Theme = UiTheme.build()
	for pair: Array in [[&"panel", &"PanelContainer"], [&"panel", &"Panel"], [&"panel", &"CardPanel"]]:
		var box: StyleBoxFlat = theme.get_stylebox(pair[0], pair[1]) as StyleBoxFlat
		assert_not_null(box)
		if box != null:
			assert_eq(box.bg_color.a, 1.0, "%s must be opaque so its text contrast holds" % pair[1])


func _check_pairs(pairs: Array[PackedStringArray], minimum: float) -> void:
	assert_true(pairs.size() > 0)
	var tokens: Dictionary = (Palette as Script).get_script_constant_map()
	for pair: PackedStringArray in pairs:
		assert_eq(pair.size(), 3, "a pair is [foreground, background, use]")
		if pair.size() != 3:
			continue
		assert_true(tokens.has(pair[0]), "token %s exists" % pair[0])
		assert_true(tokens.has(pair[1]), "token %s exists" % pair[1])
		var fg: Color = Palette.token(pair[0])
		var bg: Color = Palette.token(pair[1])
		assert_eq(fg.a, 1.0, "%s is opaque" % pair[0])
		assert_eq(bg.a, 1.0, "%s is opaque" % pair[1])
		var ratio: float = Palette.contrast(fg, bg)
		assert_true(ratio >= minimum, "%s on %s (%s): %.2f:1, needs %.1f:1" % [pair[0], pair[1], pair[2], ratio, minimum])
