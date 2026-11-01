extends Control
## The frame every reading screen shares (DESIGN_SYSTEM.md 7.11): Info,
## About and the license texts.
## - Full screen and opaque, over whatever opened it: the skin's backdrop
##   fills the screen, with the whole screen kept clear of decoration (Nova
##   shows no star dust behind text). It takes every touch, so nothing under
##   it can be reached.
## - In the content column (2.8): the header, touch_min tall inside the safe
##   area, with the title (TitleLabel, left at board_margin) and the close
##   icon button inset like the splash's settings button; Slate adds a
##   hairline under it. Then the ScrollContainer, down to the screen's bottom
##   edge: vertical only, the indicator's room always kept, the 24 px
##   deadzone, no follow focus. Its content is padded board_margin on the
##   left, space_s on top and space_xl plus the bottom inset at the end; the
##   indicator fills the right board_margin.
## - Sections in the SectionPanel variation: Gumdrop cards space_s apart,
##   Slate split by its hairline, Nova space_l apart. Inside: the heading,
##   space_xs, the reading text, then space_m and an example or rows.
## - Every label wraps and none sets a minimum width. Every control in the
##   scroll area ignores the mouse, except the rows that open a screen, which
##   pass it on, so a drag anywhere scrolls.
## - It comes and goes with screen_fade, never dialog_in.
## Subclasses call _frame(skin, title) and then build into _sections with the
## helpers below. close() fades it out and frees it.

signal closed()

const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")
const Copy: GDScript = preload("res://src/ui/screen_copy.gd")
const OpenRow: GDScript = preload("res://src/ui/open_row.gd")
## DESIGN_SYSTEM.md 7.9: the scroll deadzone, 24 px (8 dp, Android's touch slop).
const SCROLL_DEADZONE: int = 24

var _skin: SkinData = null
var _backdrop: SkinBackdrop = null
var _page: VBoxContainer = null
var _title: Label = null
var _close_button: BaseButton = null
var _scroll: ScrollContainer = null
var _pad: MarginContainer = null
var _sections: VBoxContainer = null
var _closing: bool = false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## True once close() has started; the screen then takes no more input.
func is_closing() -> bool:
	return _closing


## The scroll area. For tests and review pages.
func scroll() -> ScrollContainer:
	return _scroll


## The column of sections inside the scroll area. For tests.
func sections() -> VBoxContainer:
	return _sections


## The header's title as shown.
func title_text() -> String:
	return _title.text if _title != null else ""


## The close button. For tests.
func close_button() -> BaseButton:
	return _close_button


## Fades the screen in over screen_fade.
func play_in() -> void:
	if _skin == null or not is_inside_tree():
		return
	modulate.a = 0.0
	Motion.fade(self, _skin, 1.0)


## Fades the screen out and frees it. It stops taking input at once.
func close() -> void:
	if _closing:
		return
	_closing = true
	_ignore_input(self)
	if not is_inside_tree() or _skin == null:
		queue_free()
		return
	var tween: Tween = Motion.fade(self, _skin, 0.0)
	tween.finished.connect(queue_free)


## Clears the screen and builds the empty frame for skin with this title.
func _frame(skin: SkinData, title: String) -> void:
	_skin = skin
	UiParts.clear(self)
	_backdrop = UiKit.make_backdrop(skin)
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var margin: float = skin.num(&"board_margin")
	_page = UiParts.vbox(0.0)
	_page.name = "Page"
	add_child(_page)
	var header_box: MarginContainer = _margins(margin, UiParts.icon_button_inset(skin))
	_page.add_child(header_box)
	var header: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	header.name = "Header"
	header.custom_minimum_size = Vector2(0.0, skin.num(&"touch_min"))
	header_box.add_child(header)
	_title = UiParts.paragraph(skin, &"TitleLabel", title, HORIZONTAL_ALIGNMENT_LEFT)
	_title.name = "Title"
	header.add_child(_title)
	_close_button = UiParts.icon_button(skin, &"close")
	_close_button.name = "Close"
	_close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_close_button.pressed.connect(_on_close)
	header.add_child(_close_button)
	if UiParts.ruled(skin):
		var rule_box: MarginContainer = _margins(margin, margin)
		rule_box.add_child(UiParts.divider())
		_page.add_child(rule_box)

	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	_scroll.scroll_deadzone = SCROLL_DEADZONE
	_scroll.follow_focus = false
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_child(_scroll)
	_pad = _margins(margin, 0.0)
	_pad.name = "Pad"
	_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pad.add_theme_constant_override(&"margin_top", roundi(skin.num(&"space_s")))
	_scroll.add_child(_pad)
	_sections = UiParts.vbox(UiParts.section_gap(skin))
	_sections.name = "Sections"
	_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pad.add_child(_sections)
	_layout()


## A new section at the end: the SectionPanel box (Slate puts its hairline
## before every section but the first) holding a column, space_xs apart.
## Returns the column.
func _add_section() -> VBoxContainer:
	if UiParts.ruled(_skin) and _sections.get_child_count() > 0:
		_sections.add_child(UiParts.divider())
	var panel: PanelContainer = PanelContainer.new()
	panel.theme_type_variation = &"SectionPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sections.add_child(panel)
	var column: VBoxContainer = UiParts.vbox(_skin.num(&"space_xs"))
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(column)
	return column


## A heading in the heading role, cased by its rule (Slate capitals).
func _heading(text: String) -> Label:
	return UiParts.paragraph(_skin, &"HeadingLabel", text, HORIZONTAL_ALIGNMENT_LEFT)


## A paragraph in the reading role. Reading text is never cased: it is the
## GDD's or a license's own words.
func _reading(text: String) -> Label:
	var made: Label = UiParts.paragraph(_skin, &"ReadingLabel", text, HORIZONTAL_ALIGNMENT_LEFT)
	made.text = text
	return made


## A row that opens a screen, tap only (7.11).
func _open_row(title: String, detail: String) -> Control:
	var row: Control = OpenRow.new()
	row.call(&"setup", _skin, title, detail)
	return row


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
		_layout()


## The page in the content column, from the safe area's top to the screen's
## bottom edge; the scroll content ends space_xl plus the bottom inset down.
func _layout() -> void:
	if _page == null or _skin == null or not is_inside_tree():
		return
	var safe: Rect2 = SafeArea.viewport_safe_rect(get_viewport())
	layout_in(get_global_rect(), safe, SafeArea.column_in(safe, _skin))
	var whole: Array[Rect2] = [get_global_rect()]
	_backdrop.set_clear_rects(whole)


## Lays the page out for a screen rect, a safe rect and a content column, all
## in the same (global) coordinates. _layout calls it; tests call it with
## rects of their own, since headless tests never enter the scene tree.
func layout_in(screen: Rect2, safe: Rect2, column: Rect2) -> void:
	if _page == null or _skin == null:
		return
	var bottom_inset: float = maxf(0.0, screen.end.y - safe.end.y)
	_pad.add_theme_constant_override(&"margin_bottom", roundi(_skin.num(&"space_xl") + bottom_inset))
	_page.position = column.position - screen.position
	_page.size = Vector2(column.size.x, maxf(0.0, screen.end.y - column.position.y))


func _margins(left: float, right: float) -> MarginContainer:
	var box: MarginContainer = MarginContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"margin_left", roundi(left))
	box.add_theme_constant_override(&"margin_right", roundi(right))
	return box


func _on_close() -> void:
	if not _closing:
		closed.emit()


## Makes every control under node ignore the mouse, except the rows that
## open a screen, which pass it on (their insides ignore it): drags then
## reach the scroll area from anywhere, and example tiles and boards never
## take input (7.11, 7.12).
static func _quiet(node: Node) -> void:
	if node is OpenRow:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		for child: Node in node.get_children():
			_ignore_input(child)
		return
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_quiet(child)


## Makes every control under node ignore the mouse, so a closing screen takes
## no more taps.
static func _ignore_input(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_ignore_input(child)
