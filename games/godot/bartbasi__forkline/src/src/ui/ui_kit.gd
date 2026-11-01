# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name UiKit
extends RefCounted
## Small builders for the controls every screen uses, so the screens stay short.
## Colors and sizes come from the UiTheme; nothing here picks a color of its own.


## A Label that wraps. `variation` is a UiTheme label type.
static func label(text: String, variation: StringName = &"Label") -> Label:
	var l: Label = Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A section heading: bold, a little bigger than body text.
static func heading(text: String) -> Label:
	var l: Label = label(text)
	l.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_BOLD))
	l.add_theme_font_size_override(&"font_size", UiTheme.FONT_BUTTON)
	return l


## A button of at least the touch size. `variation` is a UiTheme button type.
static func button(text: String, variation: StringName = &"Button") -> TapButton:
	var b: TapButton = TapButton.new()
	b.text = text
	b.theme_type_variation = variation
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


## Lets a button's text wrap, so a long label never pushes its panel wider.
static func wrapped(b: TapButton) -> TapButton:
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return b


## A square icon-only button (the settings gear, the back arrow).
static func icon_button(kind: StringName) -> TapButton:
	var b: TapButton = TapButton.new()
	b.icon = IconTex.make(kind, 72)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = false
	b.custom_minimum_size = Vector2(Layout.MIN_TOUCH, Layout.MIN_TOUCH)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	return b


## A button with two lines on it: a name and a smaller line under it. The labels
## use `name_variation` and `sub_variation` (UiTheme label types).
static func two_line_button(name_text: String, sub_text: String, button_variation: StringName, name_variation: StringName, sub_variation: StringName) -> TapButton:
	var b: TapButton = button("", button_variation)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", UiTheme.PAD_X)
	margin.add_theme_constant_override(&"margin_right", UiTheme.PAD_X)
	margin.add_theme_constant_override(&"margin_top", 18)
	margin.add_theme_constant_override(&"margin_bottom", 18)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 4)
	var first: Label = label(name_text, name_variation)
	first.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_BOLD))
	first.add_theme_font_size_override(&"font_size", UiTheme.FONT_BUTTON)
	column.add_child(first)
	var second: Label = label(sub_text, sub_variation)
	second.add_theme_font_override(&"font", UiTheme.font(UiTheme.WEIGHT_REGULAR))
	column.add_child(second)
	margin.add_child(column)
	b.add_child(margin)
	b.custom_minimum_size = Vector2(Layout.MIN_TOUCH, 230.0)
	return b


## A dark panel with a vertical box in it. Returns the box; the panel is its parent.
static func section() -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	panel.add_child(column)
	return column


## A flat rounded box in the theme's look, for a state the theme has no type for
## (a chosen card, a dimmed card). Colors are Palette tokens.
static func box(fill: Color, edge: Color, border: int, radius: int = UiTheme.RADIUS, margin: int = 32) -> StyleBoxFlat:
	var b: StyleBoxFlat = StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = edge
	b.set_border_width_all(border)
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(margin)
	return b


## A fixed gap.
static func gap(px: float) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(0.0, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## An empty control that takes up the spare room.
static func spacer() -> Control:
	var c: Control = Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
