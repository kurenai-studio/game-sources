class_name UiKit
extends RefCounted
## Shared look for the menus: colors, labels, buttons and panels.
## The pixel font is crisp at multiples of 8, and text goes through
## String.to_upper(), which ignores the OS locale (Label.uppercase does
## not: on a Turkish system it turns "i" into "İ").

const SMALL_FONT_SIZE := 8
const HEADER_FONT_SIZE := 16
const TITLE_FONT_SIZE := 32
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.6)
const PANEL_COLOR := Color(0.12, 0.11, 0.16, 0.95)
const HOVER_COLOR := Color(0.2, 0.18, 0.26, 0.95)
const BORDER_COLOR := Color(0.45, 0.42, 0.55)
const ACCENT_COLOR := Color(1.0, 0.82, 0.35)
const TEXT_COLOR := Color(0.85, 0.85, 0.9)
const MUTED_COLOR := Color(0.6, 0.58, 0.68)
const BUTTON_SIZE := Vector2(144, 20)
const SEPARATION := 6
const PANEL_PADDING := 12

## Set while a menu grabs its first focus, so opening it stays silent.
static var _quiet := false


static func label(text: String, font_size: int = SMALL_FONT_SIZE, color: Color = TEXT_COLOR) -> Label:
	var result := Label.new()
	result.text = text.to_upper()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override(&"font_size", font_size)
	result.add_theme_color_override(&"font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## A menu button. The mouse moves focus, so keyboard, gamepad and mouse
## all share one highlight; focus changes play the UI tick.
static func button(text: String) -> Button:
	var result := Button.new()
	result.text = text.to_upper()
	result.custom_minimum_size = BUTTON_SIZE
	result.focus_mode = Control.FOCUS_ALL
	result.add_theme_font_size_override(&"font_size", SMALL_FONT_SIZE)
	style_focusable(result)
	result.mouse_entered.connect(result.grab_focus)
	result.focus_entered.connect(func() -> void: _on_focus_entered())
	return result


## Focuses [param control] without the UI tick, for a menu that opens.
static func grab_focus_quietly(control: Control) -> void:
	_quiet = true
	control.grab_focus()
	_quiet = false


static func _on_focus_entered() -> void:
	if not _quiet:
		AudioManager.play(&"ui_move")


## Panel, hover and accent-border focus styles for any button-like control.
static func style_focusable(control: Control) -> void:
	control.add_theme_stylebox_override(&"normal", box_style(PANEL_COLOR, BORDER_COLOR))
	control.add_theme_stylebox_override(&"hover", box_style(HOVER_COLOR, BORDER_COLOR))
	control.add_theme_stylebox_override(&"pressed", box_style(HOVER_COLOR, ACCENT_COLOR))
	control.add_theme_stylebox_override(&"hover_pressed", box_style(HOVER_COLOR, ACCENT_COLOR))
	control.add_theme_stylebox_override(&"focus", focus_style())
	control.add_theme_color_override(&"font_color", TEXT_COLOR)
	control.add_theme_color_override(&"font_hover_color", Color.WHITE)
	control.add_theme_color_override(&"font_focus_color", Color.WHITE)
	control.add_theme_color_override(&"font_pressed_color", ACCENT_COLOR)


static func panel(content: Control) -> PanelContainer:
	var result := PanelContainer.new()
	var style := box_style(PANEL_COLOR, BORDER_COLOR)
	style.set_content_margin_all(PANEL_PADDING)
	result.add_theme_stylebox_override(&"panel", style)
	result.add_child(content)
	return result


static func column() -> VBoxContainer:
	var result := VBoxContainer.new()
	result.add_theme_constant_override(&"separation", SEPARATION)
	result.alignment = BoxContainer.ALIGNMENT_CENTER
	return result


## A full-screen container that centers [param content] over a dim layer.
static func dimmed_center(content: Control) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	center.add_child(content)
	return root


static func box_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


static func focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = ACCENT_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style

