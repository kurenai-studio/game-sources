class_name TapeView
extends Control
## The tape: a strip of instruction tiles. Procedure definitions come first, each drawn as a
## header tile (PROC and its name) with its body inside one bracket, then the main program. A loop
## is a header tile (a count, or "until blocked") and its body inside a bracket; an IF is a header
## tile (IF and its sensor), its then tiles, an ELSE divider and its else tiles inside a bracket
## of their own. Brackets nest: an IF or a loop sits inside the bracket of the loop or procedure
## that holds it (TapeLayout).
##
## Editing: left-aligned, a dashed plus slot where the next tile goes, drag to scroll when it
## overflows. Running: a fixed read-head at the center; `scroll` is animated by the play screen so
## the current tile sits under it. States per tile: executed (solid), current (yellow), upcoming
## (outlined), failed (yellow with an X); the CALL that is running is yellow too. The view only
## displays; it never runs anything.

signal tile_tapped(index: int)

const PAD := TapeLayout.PAD
const DRAG_SLOP := 10.0

## The cells to show (TapeModel.cells()): one per slot.
var cells: Array[Dictionary] = []
var limit := 0
var used := 0
var selected := -1
## The keys (TapeCells.key_of) of the procedure, loop and IF that are open, outermost first.
var open_keys: Array[String] = []
## The trace paths (joined with "_") of the commands already shown by the run.
var executed := {}
## False while editing; true when the read-head is shown.
var running := false
## Index of the cell under the read-head, or -1 before the first step.
var current := -1
## Index of the CALL cell that is running the current command, or -1 in the main program.
var call_index := -1
## The 1-based round of the loop the read-head is in, or 0.
var current_round := 0
## The round of each loop that holds another loop and the read-head, by cell index (see LoopRounds).
var outer_rounds := {}
var failed_index := -1
## Horizontal offset of the strip in pixels.
var scroll := 0.0:
	set(value):
		scroll = value
		queue_redraw()

var _rects: Array[Rect2] = []
var _groups: Array[Rect2] = []
var _group_dashed: Array[bool] = []
var _slot := Rect2()
var _divider := -1.0
var _content_end := 0.0
var _press_at := Vector2.ZERO
var _press_scroll := 0.0
var _pressing := false
var _dragged := false


## Tile side for a control of this height (room for the number row and the read-head).
static func tile_for_height(height: float) -> float:
	return floorf(clampf(height - 54.0, 40.0, 60.0))


func tile_size() -> float:
	return tile_for_height(size.y)


func pitch() -> float:
	return tile_size() * 1.24


func set_content(
	tape_cells: Array[Dictionary],
	used_slots: int,
	max_commands: int,
	selected_index: int,
	open: Array[String] = []
) -> void:
	cells = tape_cells
	used = used_slots
	limit = max_commands
	selected = selected_index
	open_keys = open
	_layout_cells()
	queue_redraw()


func _top() -> float:
	return 22.0 if running else 12.0


func _layout_cells() -> void:
	var metrics := {
		"tile": tile_size(),
		"pitch": pitch(),
		"top": _top(),
		"editing": not running,
		"room": used < limit,
	}
	var laid := TapeLayout.compute(cells, metrics, open_keys)
	_rects = laid["rects"]
	_groups = laid["groups"]
	_group_dashed = laid["dashed"]
	_slot = laid["slot"]
	_divider = laid["divider"]
	_content_end = laid["end"]


## The scroll that shows the end of the program.
func edit_scroll() -> float:
	return maxf(0.0, _content_end - size.x)


## The scroll that shows the slot where the next tile goes (the end of the tape when there is no
## slot, or the open definition is further left).
func append_scroll() -> float:
	if _slot.size == Vector2.ZERO:
		return edit_scroll()
	return clampf(_slot.end.x + PAD - size.x, 0.0, edit_scroll())


## Scrolls just enough to show cell `index` in full, and not at all when it is already visible.
func reveal(index: int) -> void:
	if index < 0 or index >= _rects.size():
		return
	var rect := _rects[index]
	var next := scroll
	if rect.position.x - PAD < next:
		next = rect.position.x - PAD
	elif rect.end.x + PAD > next + size.x:
		next = rect.end.x + PAD - size.x
	scroll = clampf(next, 0.0, edit_scroll())


## The scroll that puts cell `index` under the read-head at the center.
func head_scroll(index: int) -> float:
	if index < 0 or index >= _rects.size():
		return 0.0
	return _rects[index].get_center().x - size.x / 2.0


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var motion := event as InputEventMouseMotion
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed:
			_pressing = true
			_dragged = false
			_press_at = click.position
			_press_scroll = scroll
		else:
			if _pressing and not _dragged:
				tile_tapped.emit(_index_at(click.position))
			_pressing = false
	elif motion != null and _pressing:
		if absf(motion.position.x - _press_at.x) > DRAG_SLOP:
			_dragged = true
		if _dragged and not running:
			scroll = clampf(_press_scroll - (motion.position.x - _press_at.x), 0.0, edit_scroll())


func _index_at(point: Vector2) -> int:
	var x := point.x + scroll
	for i in _rects.size():
		if x >= _rects[i].position.x and x <= _rects[i].end.x:
			return i
	return -1


func _draw() -> void:
	if UiLook.depth:
		DepthKit.trough(self, Rect2(Vector2.ZERO, size))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.STRIP)
	for g in _groups.size():
		var group := _groups[g]
		group.position.x -= scroll
		if group.end.x < 0.0 or group.position.x > size.x:
			continue
		UiKit.outline_chamfer(self, group, Palette.INK, 2.0, _group_dashed[g])
	if _divider >= 0.0:
		var x := _divider - scroll
		draw_line(Vector2(x, _top()), Vector2(x, _top() + tile_size()), Palette.MUTE, 2.0)
	var slot_number := 0
	for i in cells.size():
		var rect := _rects[i]
		rect.position.x -= scroll
		if cells[i]["kind"] != "else":
			slot_number += 1
		if rect.end.x < 0.0 or rect.position.x > size.x:
			continue
		TapeTiles.draw(self, i, rect)
		if cells[i]["kind"] == "else":
			continue
		var number := "%02d" % slot_number
		var number_rect := Rect2(rect.position.x, rect.end.y + 2.0, rect.size.x, 22.0)
		var number_color := Palette.INK if i == current and running else Palette.MUTE
		UiKit.text(self, number, number_rect, 14, number_color, 1)
	if _slot.size != Vector2.ZERO and not running:
		var slot := _slot
		slot.position.x -= scroll
		UiKit.outline_chamfer(self, slot, Palette.SLOT, 2.0, true)
		UiKit.icon(self, "plus", slot.get_center(), slot.size.x * 0.5, Palette.SLOT)
	if running:
		_draw_head()


func _draw_head() -> void:
	var x := size.x / 2.0
	var tip := Vector2(x, 18.0)
	var points := PackedVector2Array([Vector2(x - 8.0, 4.0), Vector2(x + 8.0, 4.0), tip])
	draw_colored_polygon(points, Palette.SIGNAL)
	points.append(points[0])
	draw_polyline(points, Palette.INK, 2.0)


# ----- what the run has reached --------------------------------------------------------------


## The cell of the main program the read-head stands at: the CALL that is running a procedure,
## else the current cell.
func main_position() -> int:
	return call_index if call_index >= 0 else current


## True for a command in an IF branch that the run has not taken.
func skipped(cell: Dictionary) -> bool:
	return cell.has("branch") and not executed.has(TapeCells.key_of(cell["path"]))


## True when the run has already passed cell `index` (header cells: see header_passed).
func is_passed(index: int) -> bool:
	if not running or current < 0:
		return false
	var cell := cells[index]
	var proc := int(cell["proc"])
	if proc < 0:
		return index < main_position() and not skipped(cell)
	if int(cells[current]["proc"]) == proc:
		return index < current and not skipped(cell)
	return executed.has(TapeCells.key_of(cell["path"])) and not skipped(cell)


## True when the read-head is inside the group of the header at `index`, or the CALL that is
## running stands in it.
func group_holds(index: int, cell_index: int) -> bool:
	if cell_index < 0 or cell_index >= cells.size():
		return false
	var header := cells[index]
	var key: String = header.get("group", TapeCells.key_of(header["path"]))
	return (cells[cell_index]["groups"] as Array).has(key)


## True when the run has reached the header at `index` (solid): the read-head is past it or in it.
func header_passed(index: int) -> bool:
	if not running or current < 0:
		return false
	if int(cells[index]["proc"]) < 0:
		return index < main_position()
	for j in range(index + 1, cells.size()):
		if not group_holds(index, j):
			break
		if j == current or is_passed(j):
			return true
	return false
