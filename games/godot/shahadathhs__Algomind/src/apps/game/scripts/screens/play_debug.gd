class_name PlayDebug
extends RefCounted
## Debug screenshots only (see main.gd): put a program on the tape and show a point of its run.

const LETTERS := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT", "I": "INC", "K": "MARK"}


## Puts `program_text` on the tape and shows the state after `steps` events (-1 for the whole
## run, 0 for none). Writes no progress.
static func show(p: PlayScreen, program_text: String, steps: int) -> void:
	p.persist = false
	_fill_tape(p._tape, program_text)
	p._tape.clear_selection()
	if steps != 0 and p._session.start(p._tape.program(), PlaySession.State.PAUSED):
		var count: int = p._session.trace().size() if steps < 0 else steps
		for step in count:
			p._session.advance()
		if p._session.state == PlaySession.State.SUCCEEDED and p._entry.has("daily"):
			var results := p.app.progress.results
			results.queue_daily(
				str(p._entry["daily"]),
				p._entry["id"],
				int(p._level["levelVersion"]),
				p._tape.program(),
				p._tape.slots()
			)
		elif p._session.state == PlaySession.State.SUCCEEDED:
			p.app.progress.record_completion(
				p._entry["id"], int(p._level["levelVersion"]), p._tape.slots()
			)
	p._refresh()


## Selects a tape cell, to show its tools.
static func select(p: PlayScreen, index: int) -> void:
	p._tape.toggle_select(index)
	p._refresh()


## Opens the "pause" or "hint" panel.
static func overlay(p: PlayScreen, kind: String) -> void:
	if kind == "pause":
		p._open_pause()
	elif kind == "hint":
		p._open_hint()


## Letters are commands (I is INC and K is MARK); "3{MRML}" is a loop of three rounds over that
## body and "U{M}" a loop that runs its body until the way ahead is blocked. "P{MR}" defines the
## next procedure over that body (no closing brace leaves it open) and "@A" calls procedure A; in a
## procedure body "@A?" calls A while the way ahead is clear (a recursion).
static func _fill_tape(tape: TapeModel, program_text: String) -> void:
	var i := 0
	while i < program_text.length():
		var letter := program_text[i]
		if letter == "P":
			var proc_close := program_text.find("}", i)
			var proc_open_end := proc_close < 0
			if proc_open_end:
				proc_close = program_text.length()
			tape.append(TapeModel.PROC)
			_fill_proc_body(tape, program_text.substr(i + 2, proc_close - i - 2))
			if not proc_open_end:
				tape.end_proc()
			i = proc_close + 1
			continue
		if letter == "@":
			tape.append_call(program_text.substr(i + 1, 1))
			i += 2
			continue
		if letter == "U":
			# "U{MR}" is a REPEAT_UNTIL (until blocked) over that body.
			var until_close := program_text.find("}", i)
			var until_open_end := until_close < 0
			if until_open_end:
				until_close = program_text.length()
			tape.append(TapeModel.REPEAT_UNTIL)
			for inner in program_text.substr(i + 2, until_close - i - 2):
				tape.append(LETTERS.get(inner, "MOVE_FORWARD"))
			if not until_open_end:
				tape.end_loop()
			i = until_close + 1
			continue
		if letter.is_valid_int():
			var end := i
			while end < program_text.length() and program_text[end].is_valid_int():
				end += 1
			var close := program_text.find("}", end)
			var open_end := close < 0
			if open_end:
				close = program_text.length()
			tape.append(TapeModel.REPEAT)
			tape.adjust_count(
				int(program_text.substr(i, end - i)) - ContractLimits.REPEAT_COUNT_MIN
			)
			for inner in program_text.substr(end + 1, close - end - 1):
				tape.append(LETTERS.get(inner, "MOVE_FORWARD"))
			# No closing brace leaves the loop open, as while the player is still building it.
			if not open_end:
				tape.end_loop()
			i = close + 1
			continue
		tape.append(LETTERS.get(letter, "MOVE_FORWARD"))
		i += 1


## The body of a procedure: letters, "@A" for a CALL of A and "@A?" for a CALL that looks ahead.
static func _fill_proc_body(tape: TapeModel, body_text: String) -> void:
	var j := 0
	while j < body_text.length():
		if body_text[j] != "@":
			tape.append(LETTERS.get(body_text[j], "MOVE_FORWARD"))
			j += 1
			continue
		tape.append_call(body_text.substr(j + 1, 1))
		j += 2
		if j < body_text.length() and body_text[j] == "?":
			tape.selected = tape.cells().size() - 1
			tape.cycle_condition()
			tape.selected = -1
			j += 1
