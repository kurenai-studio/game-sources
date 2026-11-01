class_name TapeEdit
extends RefCounted
## The part of the tape that edits what is already there: the cells, the selection and the
## changes to the selected cell. TapeModel adds building (open loops and IFs). Pure data.

var nodes: Array = []
## The commands the level offers.
var available: Array[String] = []
## True when the level lists the mechanic recursion: a CALL may go into a definition and carry a
## sensor.
var recursion := false
## Index of the selected cell, or -1.
var selected := -1


func is_empty() -> bool:
	return nodes.is_empty()


## The cells the tape shows, in order (see TapeCells).
func cells() -> Array[Dictionary]:
	return TapeCells.build(nodes, _else_showing())


## The cell index for a node path ([i], [i, j], [i, k] or [i, j, k]), or -1.
func cell_for_node(path: Array) -> int:
	var all := cells()
	for k in all.size():
		var cell_path: Array = all[k]["path"]
		if cell_path == path:
			return k
	return -1


## Selects a cell; selecting the selected cell again clears the selection. An else divider cannot
## be selected.
func toggle_select(index: int) -> void:
	var all := cells()
	if index < 0 or index >= all.size() or index == selected:
		selected = -1
	elif all[index]["kind"] != "else":
		selected = index


func clear_selection() -> void:
	selected = -1


func selected_is_count() -> bool:
	return selected >= 0 and cells()[selected]["kind"] == "count"


## The kind of the selected cell (see TapeCells), or "" when nothing is selected.
func selected_kind() -> String:
	return "" if selected < 0 else String(cells()[selected]["kind"])


## The values a loop's count can take: 2 to 11, then "N" (the counter) when the level offers INC.
func count_values() -> Array:
	var out: Array = range(ContractLimits.REPEAT_COUNT_MIN, ContractLimits.REPEAT_COUNT_MAX + 1)
	if available.has(ContractLimits.INC_OP):
		out.append(ContractLimits.COUNTER_REF)
	return out


## Moves the count of the selected loop by `delta` places along count_values(), within its ends.
func adjust_count(delta: int) -> bool:
	if not selected_is_count():
		return false
	var node := node_of(cells()[selected])
	var values := count_values()
	var current := values.find(node["count"])
	var next := clampi(current + delta, 0, values.size() - 1)
	if next == current:
		return false
	node["count"] = values[next]
	return true


## The sensors an IF can be set to: the CLEAR ones, and the breadcrumb ones when MARK is offered.
func sensor_options() -> Array[String]:
	var out: Array[String] = []
	for sensor in ContractLimits.SENSORS:
		if available.has(ContractLimits.MARK_OP) or not ContractLimits.is_marker_sensor(sensor):
			out.append(sensor)
	return out


## Moves the selected IF to its next sensor (ahead, left, right per family: CLEAR, then FRESH and
## BACK when MARK is offered) or the selected REPEAT_UNTIL to its next condition (BLOCKED, GOAL).
func cycle_condition() -> bool:
	var kind := selected_kind()
	if kind == "call" and recursion:
		return _cycle_call_sensor()
	if kind != "if" and kind != "until":
		return false
	var node := node_of(cells()[selected])
	var key := "when" if kind == "if" else "until"
	var options: Array[String] = (
		sensor_options() if kind == "if" else ContractLimits.UNTIL_CONDITIONS
	)
	node[key] = options[(options.find(node[key]) + 1) % options.size()]
	return true


## Moves the selected CALL to its next sensor (none, then the sensors an IF can look at): the
## procedure then runs only while the sensor is true.
func _cycle_call_sensor() -> bool:
	var node := node_of(cells()[selected])
	var options: Array = [""]
	options.append_array(sensor_options())
	var next := (options.find(node.get("when", "")) + 1) % options.size()
	if next == 0:
		node.erase("when")
	else:
		node["when"] = options[next]
	return true


## The list (the program, a loop body or an IF branch) that holds the cell's node.
func siblings_of(cell: Dictionary) -> Array:
	return TapeCells.siblings_of(nodes, cell)


func position_of(cell: Dictionary) -> int:
	return TapeCells.position_of(cell)


## The node a cell stands for: a primitive, a loop (its header) or an IF (its header).
func node_of(cell: Dictionary) -> Dictionary:
	return siblings_of(cell)[position_of(cell)]


## Removes the selected cell: a primitive, or a whole loop or IF when its header is selected.
func remove_selected() -> bool:
	if selected < 0:
		return false
	var cell := cells()[selected]
	siblings_of(cell).remove_at(position_of(cell))
	selected = -1
	return true


## True when the selected cell can move one place earlier (-1) or later (1): it stays inside its
## list, and a definition never leaves the start of the program or a main node enters it.
func can_move(direction: int) -> bool:
	if selected < 0:
		return false
	var cell := cells()[selected]
	var list := siblings_of(cell)
	var target := position_of(cell) + direction
	if target < 0 or target >= list.size():
		return false
	if (cell["path"] as Array).size() > 1:
		return true
	return (list[target]["op"] == "PROC") == (list[position_of(cell)]["op"] == "PROC")


## Moves the selected cell one place earlier (-1) or later (1) among its siblings: a node among
## the program or a loop body, a command within its IF branch. A loop or IF moves with its
## contents. The selection follows it.
func move_selected(direction: int) -> bool:
	if selected < 0:
		return false
	var cell := cells()[selected]
	var list := siblings_of(cell)
	var place := position_of(cell)
	if not can_move(direction):
		return false
	var target := place + direction
	var item: Dictionary = list[place]
	list[place] = list[target]
	list[target] = item
	var path: Array = (cell["path"] as Array).duplicate()
	path[path.size() - 1] = int(path.back()) + direction
	selected = cell_for_node(path)
	return true


func clear() -> void:
	nodes.clear()
	selected = -1


## The program in the simulator's format: a list of instruction nodes (copies).
func program() -> Array:
	return TapeCells.program_of(nodes)


## The `iff` key of the IF whose else divider must show although its else is empty; "" for none.
func _else_showing() -> String:
	return ""
