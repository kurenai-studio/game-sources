extends GutTest
## The generated palette switches between the light and dark token sets.


func after_each() -> void:
	Palette.apply(false)


func test_light_theme_is_the_default() -> void:
	assert_eq(Palette.GROUND, Color("#F1F1EC"))
	assert_eq(Palette.INK, Color("#13161A"))


func test_apply_dark_switches_every_token() -> void:
	Palette.apply(true)
	assert_eq(Palette.GROUND, Color("#0E0F11"))
	assert_eq(Palette.INK, Color("#F2F2EE"))
	Palette.apply(false)
	assert_eq(Palette.GROUND, Color("#F1F1EC"))


func test_signal_is_the_same_in_both_themes() -> void:
	var light := Palette.SIGNAL
	Palette.apply(true)
	assert_eq(Palette.SIGNAL, light)
