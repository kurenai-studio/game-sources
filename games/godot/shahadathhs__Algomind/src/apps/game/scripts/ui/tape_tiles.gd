class_name TapeTiles
extends RefCounted
## Draws one cell of the tape in the state the view is in (editing, running, finished). The view
## owns the state; this only reads it.


## Draws cells[index] of `view` into `rect`.
static func draw(view: TapeView, index: int, rect: Rect2) -> void:
	var cell := view.cells[index]
	var running := view.running
	var chosen := not running and view.selected == index
	if cell["kind"] == "else":
		TapeIfCells.draw_else(view, rect)
	elif TapeHeaders.is_header(cell):
		var solid := chosen or view.header_passed(index)
		TapeHeaders.draw(view, cell, rect, solid, _round_of(view, index) if running else 0)
	elif TapeProcCells.is_header(cell):
		var header_fill := TapeProcCells.Fill.PLAIN
		if chosen or view.header_passed(index):
			header_fill = TapeProcCells.Fill.SOLID
		TapeProcCells.draw(view, cell, rect, header_fill)
	elif TapeProcCells.is_call(cell):
		var fill := TapeProcCells.Fill.PLAIN
		if running and index == view.call_index:
			fill = TapeProcCells.Fill.ACTIVE
		elif chosen or view.is_passed(index):
			fill = TapeProcCells.Fill.SOLID
		TapeProcCells.draw(view, cell, rect, fill)
	elif TapeIfCells.is_header(cell):
		TapeIfCells.draw_header(view, cell, rect, view.header_passed(index) or chosen)
	else:
		_draw_command(view, index, rect, view.is_passed(index), chosen)


static func _draw_command(
	view: TapeView, index: int, rect: Rect2, passed: bool, chosen: bool
) -> void:
	var kind := _icon_for(view.cells[index]["op"])
	var icon_size := rect.size.x * 0.5
	var tone := TileDraw.Tone.PLAIN
	var color := Palette.INK
	if index == view.failed_index and view.running:
		tone = TileDraw.Tone.ACTIVE
		kind = "x"
		color = Palette.ON_SIGNAL
	elif view.running and index == view.current:
		tone = TileDraw.Tone.ACTIVE
		color = Palette.ON_SIGNAL
	elif passed or chosen:
		tone = TileDraw.Tone.SOLID
		color = Palette.ON_INK
	var face := TileDraw.tile(view, rect, tone)
	UiKit.icon(view, kind, face.get_center(), icon_size, color)


## The round a loop header shows: the read-head's round when it is inside the loop, 0 (the count
## alone) when a running CALL is inside it, -1 when the loop is finished, else 0.
static func _round_of(view: TapeView, index: int) -> int:
	if view.group_holds(index, view.current):
		# A loop that holds another loop knows its own round only from the trace so far.
		if view.outer_rounds.has(index):
			return int(view.outer_rounds[index])
		return maxi(view.current_round, 1)
	if view.group_holds(index, view.call_index):
		return 0
	return -1 if view.header_passed(index) else 0


static func _icon_for(op: String) -> String:
	match op:
		"TURN_LEFT":
			return "left"
		"TURN_RIGHT":
			return "right"
		"INC":
			return "inc"
		"MARK":
			return "mark"
		_:
			return "move"
