# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name CoffeeButton
extends TapButton
## Buy me a coffee (playbook section 5). Small and quiet: no face at rest, no
## outline, no accent color, a muted label, only as wide as its content, a light
## fill while pressed, never disabled. Its touch area is still at least
## Layout.MIN_TOUCH. A clean tap hands the one fixed address to the phone once.
## If nothing can open it, nothing happens.

const LABEL: String = "Buy me a coffee"
const ICON_PX: int = 56


func _init() -> void:
	super()
	text = LABEL
	theme_type_variation = &"QuietButton"
	icon = IconTex.make(&"cup", ICON_PX)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_theme_color_override(&"icon_normal_color", Palette.TEXT_SOFT)
	add_theme_color_override(&"icon_hover_color", Palette.TEXT_SOFT)
	add_theme_color_override(&"icon_pressed_color", Palette.TEXT_LIGHT)
	add_theme_color_override(&"icon_hover_pressed_color", Palette.TEXT_LIGHT)
	add_theme_color_override(&"icon_disabled_color", Palette.TEXT_SOFT)
	tapped.connect(Links.open_coffee)
