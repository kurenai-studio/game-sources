class_name BoardTabs
extends Control
## The row of board tabs of a level with test boards. One tab per board: the shown one is solid,
## the others outlined, and a board solved by the current program carries a check beside its
## label (a shape and a word, never colour alone). With many boards the labels shrink to the
## number and the word BOARD stands once in front of the row, so six tabs fit a 360 px phone.

signal chosen(index: int)

const HEIGHT := 40.0
const GAP := 6.0
const FONT := 14
## Room a full label ("BOARD 3") needs beside the check icon, plus the padding of the tile.
const ICON_AND_PADDING := 15.0 + 8.0 + 16.0

var _tabs: Array[TileButton] = []
var _caption: Label
var _short := false
var _selected := 0
var _solved: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_caption = UiKit.label("BOARD", FONT, Palette.MUTE, 3)
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_caption)
	resized.connect(_place)


func setup(count: int) -> void:
	for i in count:
		var tab := TileButton.make(TileButton.Kind.SECONDARY, "", "", FONT)
		tab.custom_minimum_size = Vector2.ZERO
		tab.pressed.connect(func() -> void: chosen.emit(i))
		add_child(tab)
		_tabs.append(tab)
	_solved.resize(count)
	_solved.fill(false)


## Shows which board is selected and which are solved. `locked` disables the tabs (a run is on
## or the level is solved).
func refresh(selected: int, solved: Array, locked: bool) -> void:
	_selected = selected
	_solved = solved
	for i in _tabs.size():
		var tab := _tabs[i]
		tab.kind = TileButton.Kind.SOLID if i == selected else TileButton.Kind.SECONDARY
		tab.icon = "check" if solved[i] else ""
		tab.set_disabled(locked and i != selected)
		tab.accessibility_name = "Board %d%s" % [i + 1, ", solved" if solved[i] else ""]
		tab.queue_redraw()
	_apply_labels()


func _apply_labels() -> void:
	_caption.visible = _short
	for i in _tabs.size():
		_tabs[i].label = str(i + 1) if _short else "BOARD %d" % (i + 1)


## True when "BOARD n" does not fit a tab at this width and the numbers must stand alone.
func _needs_short_labels() -> bool:
	if _tabs.is_empty():
		return false
	var each := (size.x - GAP * (_tabs.size() - 1)) / _tabs.size()
	var widest := UiKit.text_width("BOARD %d" % _tabs.size(), FONT) + ICON_AND_PADDING
	return each < widest


func _place() -> void:
	if _tabs.is_empty():
		return
	_short = _needs_short_labels()
	_apply_labels()
	var x := 0.0
	if _short:
		x = ceilf(UiKit.text_width("BOARD", FONT, 3)) + 10.0
		_caption.position = Vector2.ZERO
		_caption.size = Vector2(x, size.y)
	var each := floorf((size.x - x - GAP * (_tabs.size() - 1)) / _tabs.size())
	for i in _tabs.size():
		_tabs[i].position = Vector2(x + i * (each + GAP), 0.0)
		_tabs[i].size = Vector2(each, size.y)
		_tabs[i].queue_redraw()
