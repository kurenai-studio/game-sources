class_name BoardProgress
extends RefCounted
## Which board of a level is shown and which boards the current program has solved.
##
## A level with `extraBoards` is solved only when one program solves every board. A mark belongs
## to the program it was earned with: `sync` clears all marks as soon as the program differs.
## A level without extra boards has one board and this behaves as if it were not there.

var level: Dictionary
## Index of the shown board; 0 is the level's own board.
var selected := 0
## A short line shown in place of the building hint after a board was solved ("" for none).
var notice := ""

var _solved: Array[bool] = []
var _signature := ""


func _init(level_data: Dictionary) -> void:
	level = level_data
	_solved.resize(count())
	_solved.fill(false)


func count() -> int:
	return BoardSet.boards_of(level).size()


func is_multi() -> bool:
	return level.has("extraBoards")


## The level as if the shown board (or board `index`) were its only board.
func board_level(index: int = -1) -> Dictionary:
	if not is_multi():
		return level
	return BoardSet.level_on_board(level, selected if index < 0 else index)


func select(index: int) -> void:
	selected = clampi(index, 0, count() - 1)
	notice = ""


## Forgets every mark unless `program` is the one they were earned with.
func sync(program: Array) -> void:
	var signature := JSON.stringify(program)
	if signature != _signature:
		_signature = signature
		_solved.fill(false)
		notice = ""


func mark_solved(index: int, program: Array) -> void:
	sync(program)
	_solved[index] = true


func is_solved(index: int) -> bool:
	return _solved[index]


func all_solved() -> bool:
	return not _solved.has(false)


## The next board after the shown one that is not solved (wrapping round), or -1 when none is left.
func next_unsolved() -> int:
	for k in range(1, count() + 1):
		var index := (selected + k) % count()
		if not _solved[index]:
			return index
	return -1


## Steps of `program` summed over every board (what results and scoring use).
func total_steps(program: Array) -> int:
	return int(LevelSimulator.simulate_all(level, program)["steps"])


## "BOARD 2: " for a level with test boards, "" for a single board.
func prefix() -> String:
	return "BOARD %d: " % (selected + 1) if is_multi() else ""
