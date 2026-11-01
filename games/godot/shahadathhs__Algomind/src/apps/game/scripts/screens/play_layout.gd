class_name PlayLayout
extends RefCounted
## Places the play screen's children for the current size and session state.

const GAP := 10.0
const ACTION_HEIGHT := 44.0
## Palette tiles that share one row; more than this wrap onto a second row.
const PALETTE_ROW := 6


static func apply(p: PlayScreen) -> void:
	var m := p.margin()
	var compact := p.size.y < 760.0
	var control_h := 48.0 if compact else 56.0
	var width := p.size.x - 2.0 * m
	var y := p.inset_top() + (12.0 if compact else 28.0)
	y = _header(p, m, y, width, compact)
	y = _objective(p, m, y, width, compact)

	var controls_y := p.size.y - p.inset_bottom() - m - control_h
	var palette := _palette_nodes(p)
	var palette_rows := palette_row_count(palette.size())
	var palette_h := control_h if palette_rows == 1 else minf(control_h, 44.0)
	var palette_total := palette_rows * palette_h + (palette_rows - 1) * 6.0
	var row_y := controls_y - 10.0 - palette_total
	var tape_bottom := row_y - (10.0 if compact else 6.0)
	if p._session.state == PlaySession.State.SUCCEEDED:
		# Share and Ranking sit in a row of their own above the result figures.
		var actions_y := row_y - 8.0 - ACTION_HEIGHT
		_place_row([p._share, p._ranking], actions_y, ACTION_HEIGHT, width, m)
		tape_bottom = actions_y - 8.0
	var cursor := _tape_area(p, m, tape_bottom, width, compact)
	y = PlayBoards.place(p, m, y, width)
	var board_h := cursor - y
	if UiLook.depth:
		# The tilted board is wider than it is tall: it gets all the free width and height.
		p._board.size = Vector2(width, board_h)
		p._board.position = Vector2(m, y)
	else:
		var side := minf(width, board_h)
		p._board.size = Vector2(side, side)
		p._board.position = Vector2((p.size.x - side) / 2.0, y + (board_h - side) / 2.0)

	PlayTape.sync_scroll(p)
	_place_palette(palette, palette_rows, row_y, palette_h, width, m)
	_place_controls(p, controls_y, control_h, width, m)
	p._commands_caption.visible = not compact and not p._session.is_finished()


## The back, title, hint and menu row. Returns the y below it.
static func _header(p: PlayScreen, m: float, y: float, width: float, compact: bool) -> float:
	p._back.position = Vector2(m, y)
	p._back.size = Vector2(44.0, 44.0)
	p._menu.position = Vector2(p.size.x - m - 44.0, y)
	p._menu.size = Vector2(44.0, 44.0)
	p._help.position = Vector2(p.size.x - m - 96.0, y)
	p._help.size = Vector2(44.0, 44.0)
	p._caption.position = Vector2(m + 54.0, y)
	p._caption.size = Vector2(width - 158.0, 18.0)
	p._title.position = Vector2(m + 54.0, y + 16.0)
	p._title.size = Vector2(width - 158.0, 30.0)
	return y + 44.0 + (10.0 if compact else 12.0)


## The objective message, result badge and command counter. Returns the y below them.
static func _objective(p: PlayScreen, m: float, y: float, width: float, compact: bool) -> float:
	var objective_h := 52.0 if compact else 54.0
	var finished := p._session.is_finished()
	# The counter shows the commands, then the stars and points of a solved level.
	var counter_w := 0.0 if p._session.state == PlaySession.State.FAILED else 150.0
	var badge_w := 40.0 if finished else 0.0
	p._badge.visible = finished
	p._badge.position = Vector2(m, y + (objective_h - 28.0) / 2.0)
	p._badge.size = Vector2(28.0, 28.0)
	p._message.position = Vector2(m + badge_w, y)
	p._message_box = Vector2(
		width - badge_w - counter_w - (8.0 if counter_w > 0.0 else 0.0), objective_h
	)
	p._message.size = p._message_box
	settle_message(p)
	p._counter.position = Vector2(p.size.x - m - 150.0, y)
	p._counter.size = Vector2(150.0, objective_h)
	return y + objective_h + 8.0


## Stacks the commands caption, coach, tape and tape tools upward from `cursor`. Returns the y of
## the top of the stack, which is where the board ends.
static func _tape_area(
	p: PlayScreen, m: float, cursor: float, width: float, compact: bool
) -> float:
	if not compact:
		p._commands_caption.position = Vector2(m, cursor - 18.0)
		p._commands_caption.size = Vector2(width, 18.0)
		cursor -= 18.0 + 14.0
	var coach_h := 40.0
	if p._coach.visible:
		p._coach.position = Vector2(m, cursor - coach_h)
		p._coach.size = Vector2(width, coach_h)
		cursor -= coach_h + 8.0
	var tape_h := 84.0 if compact else 112.0
	p._tape_view.position = Vector2(m, cursor - tape_h)
	p._tape_view.size = Vector2(width, tape_h)
	cursor = p._tape_view.position.y - 6.0
	var caption_h := 40.0 if compact else 44.0
	var shown: Array[TileButton] = []
	for tool in p._tools:
		if tool.visible:
			shown.append(tool)
	# The caption also carries the counter readout (PROGRAM N 3) while a run is shown.
	p._program_caption.position = Vector2(m, cursor - caption_h)
	p._program_caption.size = Vector2(width * (0.4 if not shown.is_empty() else 0.7), caption_h)
	var tool_size := caption_h - 4.0
	for i in shown.size():
		shown[i].size = Vector2(tool_size, tool_size)
		shown[i].position = Vector2(
			p.size.x - m - (shown.size() - i) * (tool_size + 8.0) + 8.0, cursor - caption_h + 2.0
		)
	return p._program_caption.position.y - 4.0


## A wrapping label first measured at zero width keeps a huge minimum height, so it is sized
## again one frame later, after the label has recomputed its minimum for the real width.
static func settle_message(p: PlayScreen) -> void:
	await p.get_tree().process_frame
	if is_instance_valid(p) and is_instance_valid(p._message):
		p._message.size = p._message_box


## The visible tiles of the palette area: commands, CALL tiles, Else, and the result figures.
static func _palette_nodes(p: PlayScreen) -> Array[Control]:
	var all: Array = []
	all.append_array(p._command_buttons)
	all.append_array(p._call_buttons)
	if p._else_button != null:
		all.append(p._else_button)
	all.append_array(p._extra_buttons.values())
	all.append_array(p._stats)
	var out: Array[Control] = []
	for node: Control in all:
		if node.visible:
			out.append(node)
	return out


## Rows the palette needs: tiles stay in one row up to PALETTE_ROW and share two rows beyond it.
static func palette_row_count(tiles: int) -> int:
	return 1 if tiles <= PALETTE_ROW else 2


## Places the palette tiles in `rows` rows of equal-width tiles, the first row on top.
static func _place_palette(
	nodes: Array[Control], rows: int, row_y: float, height: float, width: float, m: float
) -> void:
	var per_row := ceili(float(nodes.size()) / float(rows))
	for r in rows:
		var start := r * per_row
		_place_row(
			nodes.slice(start, start + per_row), row_y + r * (height + 6.0), height, width, m
		)


## Places equal-width controls in one row; hidden ones are skipped.
static func _place_row(nodes: Array, row_y: float, height: float, width: float, m: float) -> void:
	var visible_nodes: Array[Control] = []
	for node: Control in nodes:
		if node.visible:
			visible_nodes.append(node)
	if visible_nodes.is_empty():
		return
	var each := floorf((width - GAP * (visible_nodes.size() - 1)) / visible_nodes.size())
	for i in visible_nodes.size():
		visible_nodes[i].position = Vector2(m + i * (each + GAP), row_y)
		visible_nodes[i].size = Vector2(each, height)


static func _place_controls(
	p: PlayScreen, row_y: float, height: float, width: float, m: float
) -> void:
	var rows: Array = control_plan(p)
	var total_weight := 0.0
	for item: Array in rows:
		total_weight += float(item[1])
	var x := m
	for item: Array in rows:
		var button: TileButton = item[0]
		var w := floorf((width - GAP * (rows.size() - 1)) * float(item[1]) / total_weight)
		button.position = Vector2(x, row_y)
		button.size = Vector2(w, height)
		x += w + GAP


## Which control buttons are shown in the bottom row, with relative widths.
static func control_plan(p: PlayScreen) -> Array:
	match p._session.state:
		PlaySession.State.SUCCEEDED:
			if p.app.campaign.next_after(p._entry["id"]).is_empty():
				return [[p._levels, 0.4], [p._replay, 0.6]]
			return [[p._levels, 0.27], [p._replay, 0.3], [p._next, 0.43]]
		PlaySession.State.FAILED:
			return [[p._reset, 0.38], [p._edit, 0.62]]
		_:
			return [[p._step, 0.28], [p._run, 0.44], [p._reset, 0.28]]
