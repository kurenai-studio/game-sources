class_name PlayBoards
extends RefCounted
## The boards of a level with test boards on the play screen: the tab row, choosing a board, and
## what happens when a board is solved. A level without extra boards has none of this.


## Adds the tab row for a multi-board level (p._tab_row stays null otherwise).
static func build(p: PlayScreen) -> void:
	if not p._boards.is_multi():
		return
	p._tab_row = BoardTabs.new()
	p._tab_row.setup(p._boards.count())
	p._tab_row.chosen.connect(func(index: int) -> void: choose(p, index))
	p.add_child(p._tab_row)


## Brings the tabs in line with the marks of the current program.
static func refresh(p: PlayScreen) -> void:
	p._boards.sync(p._tape.program())
	if p._tab_row == null:
		return
	var marks: Array = []
	for i in p._boards.count():
		marks.append(p._boards.is_solved(i))
	var locked := p._session.is_active() or p._session.state == PlaySession.State.SUCCEEDED
	p._tab_row.refresh(p._boards.selected, marks, locked)


## Reserves the row above the board. Returns the y below it.
static func place(p: PlayScreen, m: float, y: float, width: float) -> float:
	if p._tab_row == null:
		return y
	p._tab_row.position = Vector2(m, y)
	p._tab_row.size = Vector2(width, BoardTabs.HEIGHT)
	return y + BoardTabs.HEIGHT + 8.0


## A tab was tapped: shows that board, ready to run. Ignored while a run is on or after the win.
static func choose(p: PlayScreen, index: int) -> void:
	if p._session.is_active() or p._session.state == PlaySession.State.SUCCEEDED:
		return
	show(p, index)
	p._refresh()


## Shows board `index` with a fresh session. No refresh.
static func show(p: PlayScreen, index: int) -> void:
	p._run_id += 1
	p._busy = false
	p._boards.select(index)
	p._session = PlaySession.new(p._boards.board_level())
	p._board.set_level(p._session.level)


## Called when a run succeeded on the shown board. Marks it and, when other boards are still
## unsolved, moves to the next one (and returns true). The level is solved when none is left.
static func after_success(p: PlayScreen) -> bool:
	if not p._boards.is_multi():
		return false
	var solved_number := p._boards.selected + 1
	p._boards.mark_solved(p._boards.selected, p._tape.program())
	var next := p._boards.next_unsolved()
	if next < 0:
		return false
	# The loop of the run ends because the new session is READY; _run_id stays as it is so
	# the step that is finishing can still clear _busy.
	p._boards.select(next)
	p._session = PlaySession.new(p._boards.board_level())
	p._board.set_level(p._session.level)
	p._boards.notice = "BOARD %d SOLVED" % solved_number
	return true
