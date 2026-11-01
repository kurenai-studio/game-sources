# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name StripRow
extends Container
## The folded wave preview's chips, always on one line (RULES 9.1). It shows as many chips
## as fit, in spawn order, then a "+N" chip for the rest. The open preview lists them all.
## The row never asks for width, so a wave with many groups cannot widen its panel.

## Space between chips.
const GAP: float = 24.0
## A little slack, because the "+N" text is measured before it is set.
const SLACK: float = 6.0

## The framed "+N" tag. It is a child, shown only when some chips do not fit.
var more_chip: PanelContainer
var more_label: Label

var _chips: Array[Control] = []
## How many chips fit the last time the row was laid out. -1 before the first layout.
var shown: int = -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	more_chip = PanelContainer.new()
	more_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	more_chip.add_theme_stylebox_override(&"panel", UiKit.box(Palette.PANEL, Palette.HONEY, 4, 16, 8))
	more_label = UiKit.label("+1", &"Label")
	more_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	more_label.add_theme_color_override(&"font_color", Palette.HONEY)
	more_chip.add_child(more_label)
	more_chip.visible = false
	add_child(more_chip)


## Adds a chip. Chips keep the order they are added in.
func add_chip(chip: Control) -> void:
	_chips.append(chip)
	add_child(chip)


func chip_count() -> int:
	return _chips.size()


## The chips in spawn order, shown or not.
func chips() -> Array[Control]:
	return _chips.duplicate()


## How many chips are showing now (not hidden behind the "+N" chip).
func visible_chips() -> int:
	var count: int = 0
	for chip: Control in _chips:
		if chip.visible:
			count += 1
	return count


## The text of the "+N" chip, "" when every chip shows.
func more_text() -> String:
	return more_label.text if more_chip.visible else ""


## How many chips fit in `available`, leading with the first. `widths` are the chips' widths
## and `plus_width` is the width of the "+N" chip, shown when some do not fit.
static func count_that_fit(widths: Array[float], plus_width: float, available: float) -> int:
	var total: float = 0.0
	var all: int = widths.size()
	for width: float in widths:
		total += width
	total += GAP * float(maxi(all - 1, 0))
	if total <= available:
		return all
	for count: int in range(all - 1, -1, -1):
		var used: float = plus_width + SLACK
		for i: int in count:
			used += widths[i] + GAP
		if used <= available:
			return count
	return 0


func _get_minimum_size() -> Vector2:
	var tallest: float = 0.0
	for chip: Control in _chips:
		tallest = maxf(tallest, chip.get_combined_minimum_size().y)
	return Vector2(0.0, tallest)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout()


func _layout() -> void:
	var widths: Array[float] = []
	for chip: Control in _chips:
		widths.append(chip.get_combined_minimum_size().x)
	var plus_width: float = more_chip.get_combined_minimum_size().x
	shown = count_that_fit(widths, plus_width, size.x)
	var hidden: int = _chips.size() - shown
	var text: String = "+%d" % hidden
	if hidden > 0 and more_label.text != text:
		more_label.text = text
	if more_chip.visible != (hidden > 0):
		more_chip.visible = hidden > 0
	var x: float = 0.0
	for i: int in _chips.size():
		var chip: Control = _chips[i]
		var want: bool = i < shown
		if chip.visible != want:
			chip.visible = want
		if want:
			var chip_size: Vector2 = chip.get_combined_minimum_size()
			fit_child_in_rect(chip, Rect2(Vector2(x, (size.y - chip_size.y) * 0.5), chip_size))
			x += chip_size.x + GAP
	if hidden > 0:
		var tag: Vector2 = more_chip.get_combined_minimum_size()
		fit_child_in_rect(more_chip, Rect2(Vector2(x, (size.y - tag.y) * 0.5), tag))
