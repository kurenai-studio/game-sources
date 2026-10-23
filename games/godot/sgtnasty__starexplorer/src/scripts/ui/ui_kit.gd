# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name UIKit
extends RefCounted
## Palette, theme and small factory helpers for building the UI in code.
##
## All screens are built from these helpers rather than .tscn files, which
## keeps layouts in one readable place and makes them easy to tweak.

const BG := Color("#0b0e1a")
const PANEL := Color("#141a2e")
const BUTTON := Color("#1c2440")
const BUTTON_HOVER := Color("#26315a")
const BUTTON_PRESSED := Color("#2e6a8a")
const BORDER := Color("#2e3a66")
const ACCENT := Color("#5ad1ff")
const TEXT := Color("#d8e2ff")
const DIM := Color("#7a86aa")
const WARN := Color("#ffb347")
const BAD := Color("#ff5a5a")
const GOOD := Color("#6ee77a")
const GOLD := Color("#ffec6e")

const FONT_SIZE := 10
const TITLE_SIZE := 16


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_stylebox("normal", "Button", _box(BUTTON, BORDER))
	t.set_stylebox("hover", "Button", _box(BUTTON_HOVER, BORDER))
	t.set_stylebox("pressed", "Button", _box(BUTTON_PRESSED, ACCENT))
	t.set_stylebox("disabled", "Button", _box(PANEL, BORDER.darkened(0.3)))
	var focus := _box(Color.TRANSPARENT, ACCENT)
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", DIM)
	t.set_stylebox("panel", "PanelContainer", _box(Color(PANEL, 0.92), BORDER))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_constant("separation", "VBoxContainer", 2)
	t.set_constant("separation", "HBoxContainer", 4)
	t.set_stylebox("background", "ProgressBar", _box(BG, BORDER))
	return t


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.anti_aliasing = false
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	return sb


static func label(text: String, color: Color = TEXT, size: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	return l


static func wrap_label(text: String, color: Color = TEXT) -> Label:
	var l := label(text, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


## `focus_key` names the button so a screen can restore focus to it after
## rebuilding its UI (important for gamepad play).
static func button(text: String, callback: Callable, disabled: bool = false, focus_key: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	b.pressed.connect(callback)
	if focus_key != "":
		b.name = focus_key
	return b


static func panel(child: Control = null) -> PanelContainer:
	var p := PanelContainer.new()
	if child:
		p.add_child(child)
	return p


static func vbox(separation: int = -1) -> VBoxContainer:
	var v := VBoxContainer.new()
	if separation >= 0:
		v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation: int = -1) -> HBoxContainer:
	var h := HBoxContainer.new()
	if separation >= 0:
		h.add_theme_constant_override("separation", separation)
	return h


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


## A pixel-art image shown at an integer scale.
static func sprite(tex: Texture2D, scale: int = 1, flip: bool = false) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = tex.get_size() * scale
	r.flip_h = flip
	return r


static func bar(value: int, max_value: int, color: Color, width: int = 80) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = maxi(1, max_value)
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(width, 6)
	var fill := _box(color, color.darkened(0.4))
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	p.add_theme_stylebox_override("fill", fill)
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
