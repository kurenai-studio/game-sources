class_name PlayView
extends RefCounted
## Texts and tool states of the play screen, derived from the session and the tape.

## The commands of the palette, in order. A level shows the ones it offers.
const COMMANDS: Array[Dictionary] = [
	{"op": "MOVE_FORWARD", "label": "MOVE", "icon": "move"},
	{"op": "TURN_LEFT", "label": "LEFT", "icon": "left"},
	{"op": "TURN_RIGHT", "label": "RIGHT", "icon": "right"},
	{"op": "INC", "label": "INC", "icon": "inc", "name": "Add one to the counter"},
	{"op": "MARK", "label": "MARK", "icon": "mark", "name": "Drop a breadcrumb"},
	{"op": "REPEAT", "label": "REPEAT", "icon": "repeat"},
	{"op": "REPEAT_UNTIL", "label": "UNTIL", "icon": "until", "name": "Repeat until"},
	{"op": "IF", "label": "IF", "icon": "if", "name": "If"},
	{"op": "PROC", "label": "PROC", "icon": "proc", "name": "Procedure"},
]
## The Else tile, shown beside If while an IF is open.
const ELSE_COMMAND := {"label": "ELSE", "icon": "", "name": "Else"}
## The Else If tile (it starts an IF in the else of the open IF) and, on a level with nested loops,
## the End Loop tile (the loop tiles then start an inner loop instead of ending the open one).
const ELSE_IF_COMMAND := {"label": "ELSE IF", "icon": "if", "name": "Else if"}
const END_LOOP_COMMAND := {"label": "END LOOP", "icon": "check", "name": "End loop"}
## Palette tiles at which the tiles of a loop that is not open give way to Else while an IF is open.
const CROWDED := 6


## The COMMANDS entry of an op.
static func command_meta(op: String) -> Dictionary:
	for command in COMMANDS:
		if command["op"] == op:
			return command
	return {}


## The op of the loop that is open on the tape (in the main program or a definition), or "".
static func open_op(tape: TapeModel) -> String:
	var path := tape.open_loop_path()
	return "" if path.is_empty() else String(TapeCells.node_at(tape.nodes, path)["op"])


## True while the group a palette tile starts (IF, PROC, REPEAT, REPEAT_UNTIL) is open.
static func group_is_open(tape: TapeModel, op: String) -> bool:
	if op == "IF":
		return not tape.open_if().is_empty()
	if op == "PROC":
		return tape.open_proc() >= 0
	if tape.nested_loops:
		return false
	return open_op(tape) == op


## Does a palette tile: ends the open group when its own tile is tapped, switches an open IF to
## its else branch for Else, otherwise adds the command.
static func apply_command(tape: TapeModel, op: String) -> void:
	if op == "ELSE":
		tape.start_else()
	elif op == "ELSE_IF":
		tape.start_else_if()
	elif op == "END_LOOP":
		tape.end_loop()
	elif op == "IF" and group_is_open(tape, op):
		tape.end_if()
	elif op == "PROC" and group_is_open(tape, op):
		tape.end_proc()
	elif ContractLimits.is_loop(op) and group_is_open(tape, op):
		tape.end_loop()
	else:
		tape.append(op)


## Shows the palette: the commands while editing, the group tiles with the label and state they
## have now, a CALL tile for each defined procedure while no definition is open, and Else while
## an IF is open. Nothing shows once the level is solved.
static func refresh_palette(p: PlayScreen, solved: bool, running: bool) -> void:
	var tape := p._tape
	for button: TileButton in p._command_buttons:
		var op: String = button.get_meta("op")
		button.visible = not solved
		button.set_disabled(running or not tape.can_append(op))
	var if_open := not tape.open_if().is_empty()
	var crowded := p._command_buttons.size() >= CROWDED
	for op: String in p._group_buttons:
		var button: TileButton = p._group_buttons[op]
		var meta := command_meta(op)
		if group_is_open(tape, op):
			var can_end := tape.can_end_if() if op == "IF" else tape.can_end_loop()
			if op == "PROC":
				can_end = tape.can_end_proc()
			button.label = {"IF": "END IF", "PROC": "END PROC"}.get(op, "END LOOP")
			button.icon = "check"
			button.set_disabled(running or not can_end)
		else:
			button.label = meta["label"]
			button.icon = meta["icon"]
		# With a crowded palette, the loop tiles that cannot be used while an IF is open give way.
		if not solved and if_open and crowded and ContractLimits.is_loop(op):
			button.visible = group_is_open(tape, op)
		button.queue_redraw()
	for button: TileButton in p._call_buttons:
		var name: String = button.get_meta("name")
		button.visible = (
			not solved
			and (tape.open_proc() < 0 or tape.recursion)
			and not if_open
			and tape.defined_names().has(name)
		)
		button.set_disabled(running or not tape.can_call(name))
		button.queue_redraw()
	if p._else_button != null:
		p._else_button.visible = if_open and not solved
		p._else_button.set_disabled(running or not tape.can_start_else())
		p._else_button.queue_redraw()
	var else_if: TileButton = p._extra_buttons.get("ELSE_IF")
	if else_if != null:
		else_if.visible = if_open and not solved
		else_if.set_disabled(running or not tape.can_start_else_if())
		else_if.queue_redraw()
	var end_loop: TileButton = p._extra_buttons.get("END_LOOP")
	if end_loop != null:
		end_loop.visible = not solved and open_op(tape) != ""
		end_loop.set_disabled(running or not tape.can_end_loop())
		end_loop.queue_redraw()


## True when the selected cell is one whose tap changes its sensor or condition.
static func can_cycle(tape: TapeModel) -> bool:
	var kind := tape.selected_kind()
	return (
		kind == "if"
		or (kind == "until" and tape.available.has("IF"))
		or (kind == "call" and tape.recursion)
	)


## The trace paths (see TapeCells.key_of) of the commands the run has shown so far.
static func executed_paths(session: PlaySession) -> Dictionary:
	var out := {}
	for i in session.cursor:
		out[TapeCells.key_of(session.trace()[i]["node"])] = true
	return out


## Shows the tools that apply to the selected cell: rounds only for a loop's count tile, the
## sensor or condition for an IF or a REPEAT_UNTIL that can be changed.
static func refresh_tools(p: PlayScreen) -> void:
	var tape := p._tape
	var tools := p._tools
	var has_selection := tape.selected >= 0 and not p._session.is_active()
	var is_count := tape.selected_is_count()
	# Order: minus, plus, earlier, later, remove, condition.
	tools[0].visible = has_selection and is_count
	tools[1].visible = has_selection and is_count
	for i in range(2, 5):
		tools[i].visible = has_selection
	tools[5].visible = has_selection and can_cycle(tape)
	if not has_selection:
		return
	var cell := tape.cells()[tape.selected]
	tools[2].set_disabled(not tape.can_move(-1))
	tools[3].set_disabled(not tape.can_move(1))
	var values := tape.count_values()
	var at := values.find(cell.get("count", 0))
	tools[0].set_disabled(at <= 0)
	tools[1].set_disabled(at >= values.size() - 1)
	if tools[5].visible:
		var node := tape.node_of(cell)
		if cell["kind"] == "call":
			tools[5].icon = TapeIfCells.icon(node["when"]) if node.has("when") else "call"
		else:
			tools[5].icon = (
				TapeIfCells.icon(node["when"])
				if cell["kind"] == "if"
				else ("goal" if node["until"] == "GOAL" else "until")
			)
		tools[5].queue_redraw()


## The text at the right of the objective row: commands used while building, and the stars and
## points of a solved level (a provisional score; the server's total wins at the next sync).
static func counter_text(p: PlayScreen) -> String:
	if p._session.state != PlaySession.State.SUCCEEDED:
		var text := "%d / %d COMMANDS" % [p._tape.slots(), p._tape.limit]
		if LevelMechanics.is_sweep(p._session.level["goal"]):
			text += "\n" + cells_text(p._session)
		return text
	var par: Dictionary = p._entry.get("par", {})
	if not par.has("commands") or not par.has("steps"):
		return "SOLVED"
	var score := (
		Scoring
		. score_result(
			Scoring.DEFAULT_RULES,
			{
				"difficulty": p._level["difficulty"],
				"par": par,
				"slots": p._tape.slots(),
				"steps": run_steps(p),
			}
		)
	)
	if p._entry.has("daily"):
		return "%d / 3 STARS" % score["stars"]
	return "%d / 3 STARS\n%d POINTS" % [score["stars"], score["levelScore"]]


## The sweep readout under the command counter: the cells entered so far of all the floor cells.
static func cells_text(session: PlaySession) -> String:
	return "%d / %d CELLS" % [session.trail().size(), LevelMechanics.floor_cells(session.level)]


## The caption above the tape. On a level with the counter it also shows N while a run is shown.
static func program_caption(p: PlayScreen) -> String:
	if not LevelMechanics.has_counter(p._level) or p._session.state == PlaySession.State.READY:
		return "PROGRAM"
	var entry := p._session.current_entry()
	return "PROGRAM   N %d" % (int(entry["counter"]) if not entry.is_empty() else 1)


static func message_text(p: PlayScreen) -> String:
	match p._session.state:
		PlaySession.State.SUCCEEDED, PlaySession.State.FAILED:
			return result_text(p)
		PlaySession.State.READY:
			if p._boards.notice != "":
				return p._boards.notice
	return LoopMessages.building_text(
		p._tape, LevelMechanics.is_sweep(p._session.level["goal"]), p._level.has("startProgram")
	)


## The text of a finished run. A failure on a level with test boards names its board.
static func result_text(p: PlayScreen) -> String:
	var result := p._session.result
	var special := LoopMessages.for_result(p._session.level, p._tape.program(), result)
	var text := special if special != "" else ResultMessages.for_result(result)
	var prefix := p._boards.prefix() if p._session.state == PlaySession.State.FAILED else ""
	return prefix + text.to_upper().trim_suffix(".")


## The steps that results and scoring count: all boards added together for a multi-board level.
static func run_steps(p: PlayScreen) -> int:
	if p._boards.is_multi():
		return p._boards.total_steps(p._tape.program())
	return int(p._session.result.get("steps", 0))


static func update_stats(p: PlayScreen) -> void:
	var stats := p._stats
	var best := p.app.progress.best_commands(p._entry["id"], int(p._level["levelVersion"]))
	if p._entry.has("daily"):
		best = int(p.app.progress.results.daily_best.get(p._entry["daily"], {}).get("slots", 0))
	stats[0].value = "%d / %d" % [p._tape.slots(), p._tape.limit]
	stats[1].value = str(run_steps(p))
	var par: Dictionary = p._entry.get("par", {})
	if par.has("commands"):
		stats[2].caption = "BEST / PAR"
		stats[2].value = "%s / %d" % [str(best) if best > 0 else "-", int(par["commands"])]
	else:
		stats[2].caption = "BEST"
		stats[2].value = str(best) if best > 0 else "-"
	for stat in stats:
		stat.queue_redraw()


## The first-run coach on level 1: step 1 until a command is added, step 2 until the run starts.
static func update_coach(p: PlayScreen, state: PlaySession.State) -> void:
	var coach := p._coach
	var active := (
		int(p._entry["number"]) == 1
		and not p.app.progress.settings.tutorial_done()
		and state == PlaySession.State.READY
	)
	coach.visible = active
	if not active:
		return
	if p._tape.is_empty():
		coach.step_number = 1
		coach.text = "TAP MOVE TO ADD A COMMAND"
	else:
		coach.step_number = 2
		coach.text = "TAP RUN TO START YOUR PROGRAM"
	coach.queue_redraw()
