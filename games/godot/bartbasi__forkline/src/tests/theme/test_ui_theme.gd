# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The UI theme builds with Outfit everywhere, the font files are the approved
## ones, unmodified, and the wordmark control sets up.

const FONT_PATH: String = "res://src/theme/fonts/Outfit[wght].ttf"
const FONT_MD5: String = "e31a3aa5fce3366bcadb8e9027f26178"
const OFL_PATH: String = "res://src/theme/fonts/OFL.txt"
const OFL_MD5: String = "fc7bcc2f3d37195db3ea982ccfecd531"


func test_font_and_license_are_unmodified() -> void:
	assert_eq(FileAccess.get_md5(FONT_PATH), FONT_MD5, "Outfit[wght].ttf")
	assert_eq(FileAccess.get_md5(OFL_PATH), OFL_MD5, "OFL.txt")


func test_theme_uses_outfit_everywhere() -> void:
	var theme: Theme = UiTheme.build()
	var f: FontVariation = theme.default_font as FontVariation
	assert_not_null(f, "the default font is an Outfit weight")
	if f != null:
		assert_eq(f.base_font, UiTheme.OUTFIT)
	assert_eq(theme.default_font_size, UiTheme.FONT_BODY)
	for type: StringName in [&"Button", &"PrimaryButton", &"CardButton", &"QuietButton", &"TitleLabel", &"CardLabel"]:
		var tf: FontVariation = theme.get_font(&"font", type) as FontVariation
		assert_not_null(tf, "%s has an Outfit font" % type)
		if tf != null:
			assert_eq(tf.base_font, UiTheme.OUTFIT, "%s uses Outfit" % type)


func test_type_variations_point_at_their_base() -> void:
	var theme: Theme = UiTheme.build()
	for v: StringName in [&"PrimaryButton", &"CardButton", &"QuietButton"]:
		assert_eq(theme.get_type_variation_base(v), &"Button", String(v))
	for v: StringName in [&"TitleLabel", &"SoftLabel", &"CardLabel", &"CardMutedLabel"]:
		assert_eq(theme.get_type_variation_base(v), &"Label", String(v))
	assert_eq(theme.get_type_variation_base(&"CardPanel"), &"PanelContainer")


func test_fonts_are_shared() -> void:
	assert_true(UiTheme.font(650) == UiTheme.font(650), "one FontVariation per weight")
	assert_true(UiTheme.font(450) != UiTheme.font(650))


func test_text_is_large_enough_for_the_cover_screen() -> void:
	# About 3.1 logical px per dp on the Fold5 cover: 40 is about 13 dp.
	assert_true(UiTheme.FONT_SMALL >= 40)
	assert_true(UiTheme.FONT_BODY >= 44)


func test_wordmark_sets_up_and_frees() -> void:
	var mark: Wordmark = Wordmark.new()
	assert_true(mark.custom_minimum_size.x > 0.0)
	assert_eq(mark.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	mark.free()
