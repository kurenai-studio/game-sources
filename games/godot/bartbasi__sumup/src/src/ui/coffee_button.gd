extends "res://src/ui/open_row.gd"
## The Buy me a coffee button (DESIGN_SYSTEM.md 7.2, 7.15, GDD 15.5), the
## same on the splash, in About's "Supporting SumUp" section and on the play
## screen.
## - One line form (the default, and the play screen below the board):
##   content vertically centered, the coffee icon in ink_muted, in a square
##   box the body role's font size, centered on the label's cap middle; a gap
##   of 0.25 of that size; then "Buy me a coffee" in MutedLabel, as written
##   in every skin.
## - Stacked form (the play screen's side gutter only, 7.15): the same icon on
##   top, the same gap below it, then "Buy me" over "a coffee", two one line
##   MutedLabels with no space between them, everything centered.
## - Children ignore the mouse. touch_min tall at least and only as wide as
##   its content (it never expands). The touch area reaches space_s past the
##   content on both sides over the full height, the same reach as the
##   RowButton pressed fill, so the whole fill is the target.
## - The RowButton look and the tap rule of a row that opens a screen
##   (open_row.gd): down and up on it, moving less than the deadzone, with no
##   scroll in between; a drag that starts on it reaches the ScrollContainer.
## - Never disabled, no chevron, no scale, no motion of its own.
## Every tap hands Copy.COFFEE_URL to the system exactly once (hand_off). On
## failure nothing happens: no message, and the screen stays as it was (BC6).

const Copy: GDScript = preload("res://src/ui/screen_copy.gd")
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")
## DESIGN_SYSTEM.md 7.9: the gap between the icon and the label, as a share
## of the body role's font size.
const ICON_GAP: float = 0.25

## How the address reaches the system: OS.shell_open by default. Tests set a
## capture here (TH24) so no browser opens, and put the default back with
## use_system_opener(). It takes the address and returns an Error.
static var opener: Callable = Callable(OS, &"shell_open")

var _icon: SkinIcon = null
var _reach: float = 0.0
var _stacked: bool = false
## The title the one line form shows.
var _copy: String = Copy.COFFEE
## The label or labels on show, top first.
var _lines: Array[Label] = []


## Hands the one fixed address to the system. True when the system took it;
## anything other than OK counts as "could not open", and then nothing else
## happens (GDD BC6). Nothing is ever added to the address.
static func hand_off() -> bool:
	if not opener.is_valid():
		return false
	var result: Variant = opener.call(Copy.COFFEE_URL)
	return typeof(result) == TYPE_INT and int(result) == OK


## Puts the real hand off back (OS.shell_open). For tests.
static func use_system_opener() -> void:
	opener = Callable(OS, &"shell_open")


## Builds the button for skin, in its current form. The title is the one
## line form's copy; there is no detail line.
func setup(skin: SkinData, title: String = Copy.COFFEE, _no_detail: String = "") -> void:
	_skin = skin
	_copy = title
	UiParts.clear(self)
	name = "Coffee"
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	custom_minimum_size = Vector2(0.0, skin.num(&"touch_min"))
	_reach = skin.num(&"space_s")
	_lines = []
	_icon = UiKit.make_icon(skin)
	_icon.name = "Icon"
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font_px: int = skin.font_size(&"body")
	_icon.custom_minimum_size = Vector2(float(font_px), float(font_px))
	_icon.size = Vector2(float(font_px), float(font_px))
	_icon.set_icon(&"coffee")
	_icon.set_color(skin.color(&"ink_muted"))
	if _stacked:
		_build_stacked(skin)
	else:
		_build_line(skin, title)
	_title = _lines[0]
	_detail = null
	_chevron = null
	if not tapped.is_connected(_on_tapped):
		tapped.connect(_on_tapped)
	_apply_look()


func _build_line(skin: SkinData, title: String) -> void:
	var font_px: int = skin.font_size(&"body")
	var line: HBoxContainer = UiParts.hbox(float(roundi(ICON_GAP * float(font_px))))
	line.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(line)
	# Line the icon's middle up with the label's cap middle, not the middle
	# of its line box: shift it by the gap between the two.
	var font: Font = skin.font(&"body")
	var offset: float = 0.5 * (font.get_ascent(font_px) - font.get_descent(font_px) - FontMetrics.CAP_HEIGHT * float(font_px))
	var icon_box: MarginContainer = MarginContainer.new()
	icon_box.name = "IconBox"
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.add_theme_constant_override(&"margin_top", maxi(0, roundi(2.0 * offset)))
	icon_box.add_theme_constant_override(&"margin_bottom", maxi(0, roundi(-2.0 * offset)))
	line.add_child(icon_box)
	icon_box.add_child(_icon)
	var title_label: Label = UiParts.label(skin, &"MutedLabel", title)
	title_label.name = "Title"
	title_label.text = skin.cased(&"body", title)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(title_label)
	_lines = [title_label]


func _build_stacked(skin: SkinData) -> void:
	var font_px: int = skin.font_size(&"body")
	var column: VBoxContainer = UiParts.vbox(0.0)
	column.name = "Stack"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(column)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_icon)
	column.add_child(UiParts.spacer(float(roundi(ICON_GAP * float(font_px)))))
	for pair: Array in [["Top", Copy.COFFEE_TOP], ["Bottom", Copy.COFFEE_BOTTOM]]:
		var line: Label = UiParts.label(skin, &"MutedLabel", pair[1] as String, HORIZONTAL_ALIGNMENT_CENTER)
		line.name = pair[0] as String
		line.text = skin.cased(&"body", pair[1] as String)
		line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(line)
		_lines.append(line)


## Switches between the one line form (false, the default) and the stacked
## form (true). Setting the form it already has does nothing, so a layout can
## call it every time.
func set_stacked(on: bool) -> void:
	if on == _stacked:
		return
	_stacked = on
	if _skin != null:
		setup(_skin, _copy)


func is_stacked() -> bool:
	return _stacked


## The button's size where no container sizes it (the play screen, 7.15), in
## its current form: see size_for.
func content_size() -> Vector2:
	var computed: Vector2 = size_for(_stacked)
	var size_now: Vector2 = get_combined_minimum_size()
	return Vector2(maxf(size_now.x, computed.x), maxf(size_now.y, computed.y))


## The size the button takes in a form, worked out from the skin's body font,
## never less than touch_min tall. A label measures nothing until its theme
## reaches it in the tree, so this is right before that too, and the play
## screen can ask for a form it does not show yet.
## One line: the icon, the gap and the label wide. Stacked: the widest of the
## icon and the two lines wide; the icon, the gap and two line heights tall.
func size_for(stacked: bool) -> Vector2:
	if _skin == null:
		return get_combined_minimum_size()
	var font_px: int = _skin.font_size(&"body")
	var gap: float = float(roundi(ICON_GAP * float(font_px)))
	var touch: float = _skin.num(&"touch_min")
	if not stacked:
		var text: float = UiParts.text_width(_skin, &"MutedLabel", _skin.cased(&"body", _copy), font_px)
		return Vector2(float(font_px) + gap + text, touch)
	var top: float = UiParts.text_width(_skin, &"MutedLabel", _skin.cased(&"body", Copy.COFFEE_TOP), font_px)
	var bottom: float = UiParts.text_width(_skin, &"MutedLabel", _skin.cased(&"body", Copy.COFFEE_BOTTOM), font_px)
	var line_height: float = _skin.font(&"body").get_height(font_px)
	return Vector2(maxf(float(font_px), maxf(top, bottom)), maxf(touch, float(font_px) + gap + 2.0 * line_height))


## The coffee icon. For tests.
func icon() -> SkinIcon:
	return _icon


## The label (the top line in the stacked form). For tests.
func label() -> Label:
	return _title


## Every label on show, top first: one in the one line form, two stacked.
## For tests.
func labels() -> Array[Label]:
	return _lines.duplicate()


## The touch area reaches space_s past the content on both sides, where the
## pressed fill reaches (the Theme's RowButton expand margin).
func _has_point(point: Vector2) -> bool:
	return point.x >= -_reach and point.x < size.x + _reach and point.y >= 0.0 and point.y < size.y


func _on_tapped() -> void:
	hand_off()
