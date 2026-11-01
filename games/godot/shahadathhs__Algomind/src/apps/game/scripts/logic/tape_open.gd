class_name TapeOpen
extends TapeEdit
## What is open on the tape (a procedure, a loop, an IF) and the questions about it that the
## building rules of TapeModel ask. Pure data.

const REPEAT := ContractLimits.REPEAT_OP
const REPEAT_UNTIL := ContractLimits.REPEAT_UNTIL_OP
const IF := ContractLimits.IF_OP
const PROC := ContractLimits.PROC_OP
const CALL := ContractLimits.CALL_OP

var limit := 0
## True when the level lists nested_loops: a loop may be opened inside an open loop.
var nested_loops := false


## Slots used: this is what the limit counts (see ProgramSlots).
func slots() -> int:
	return ProgramSlots.count(nodes)


func is_full() -> bool:
	return limit > 0 and slots() >= limit


func has_empty_loop() -> bool:
	return TapeCells.has_empty_loop(nodes)


## The paths of the nodes that are open, outermost first: a procedure or loop, then the loop or
## IF inside it. Empty when nothing is open.
func open_chain() -> Array[Array]:
	var out: Array[Array] = []
	var list: Array = nodes
	var base: Array = []
	while true:
		var found := -1
		for i in list.size():
			if list[i].get("_open", false):
				found = i
				break
		if found < 0:
			break
		base = base + [found]
		out.append(base)
		var node: Dictionary = list[found]
		if ContractLimits.is_if(node["op"]):
			# An else-if chain: the IF that the else holds can be the open one.
			while _open_next(node):
				base = base + [(node["then"] as Array).size()]
				out.append(base)
				node = node["else"][0]
			break
		if not node.has("body"):
			break
		list = node["body"]
	return out


## True when the else of this IF holds an IF that is open.
func _open_next(node: Dictionary) -> bool:
	var other: Array = node["else"]
	return (
		other.size() == 1 and ContractLimits.is_if(other[0]["op"]) and other[0].get("_open", false)
	)


## The keys (see TapeCells.key_of) of the groups that are open, outermost first. An else-if chain
## is one group, named by its first IF.
func open_keys() -> Array[String]:
	var out: Array[String] = []
	for path in open_chain():
		if path.size() > 1 and _is_if_path(path.slice(0, path.size() - 1)):
			continue
		out.append(TapeCells.key_of(path))
	return out


func _is_if_path(path: Array) -> bool:
	return ContractLimits.is_if(TapeCells.node_at(nodes, path)["op"])


## How many loops are open (0 to 2).
func _loop_depth() -> int:
	var depth := 0
	for path in open_chain():
		if ContractLimits.is_loop(TapeCells.node_at(nodes, path)["op"]):
			depth += 1
	return depth


## How many IFs of the open else-if chain are open, the first included; 0 when no IF is open.
func _if_depth() -> int:
	var depth := 0
	for path in open_chain():
		if _is_if_path(path):
			depth += 1
	return depth


## The program index of the main-program loop that is open, or -1.
func open_loop() -> int:
	var path := open_loop_path()
	return int(path[0]) if path.size() == 1 else -1


## The path of the innermost loop that is open (in the main program or in a procedure), or [].
func open_loop_path() -> Array:
	var found: Array = []
	for path in open_chain():
		if ContractLimits.is_loop(TapeCells.node_at(nodes, path)["op"]):
			found = path
	return found


## The program index of the procedure that is open, or -1.
func open_proc() -> int:
	var chain := open_chain()
	if chain.is_empty() or TapeCells.node_at(nodes, chain[0])["op"] != PROC:
		return -1
	return int(chain[0][0])


## The IF that is open (a node of the tape), or an empty Dictionary.
func open_if() -> Dictionary:
	var chain := open_chain()
	if chain.is_empty():
		return {}
	var node := TapeCells.node_at(nodes, chain.back())
	return node if ContractLimits.is_if(node["op"]) else {}


## "then" or "else" while an IF is open, else "".
func open_branch() -> String:
	return String(open_if().get("_branch", ""))


## The open loop, else the open procedure (a node), or an empty Dictionary: what takes the next
## command when no IF is open.
func _open_container() -> Dictionary:
	var path := open_loop_path()
	if not path.is_empty():
		return TapeCells.node_at(nodes, path)
	var proc := open_proc()
	return nodes[proc] if proc >= 0 else {}


## The most items the open loop or procedure may hold.
func _container_max(container: Dictionary) -> int:
	if container["op"] == PROC:
		return ContractLimits.PROC_BODY_MAX
	return ContractLimits.REPEAT_BODY_MAX


## True while the open loop or procedure is at the most items a body may hold.
func open_loop_is_full() -> bool:
	var container := _open_container()
	return (
		not container.is_empty()
		and (container["body"] as Array).size() >= _container_max(container)
	)


## True when `end_loop` would be accepted: a loop is open, has an item, and no IF is open in it.
func can_end_loop() -> bool:
	var path := open_loop_path()
	if path.is_empty() or not open_if().is_empty():
		return false
	return not (TapeCells.node_at(nodes, path)["body"] as Array).is_empty()


## True when `end_proc` would be accepted: a definition is open, has an item, and no loop or IF
## is open in it.
func can_end_proc() -> bool:
	var chain := open_chain()
	if open_proc() < 0 or chain.size() != 1:
		return false
	return not (nodes[open_proc()]["body"] as Array).is_empty()


## True when an IF is open and its then branch has a command.
func can_end_if() -> bool:
	var node := open_if()
	return not node.is_empty() and not (node["then"] as Array).is_empty()


## True when `start_else` would be accepted: an IF is open on its then branch, which has a command.
func can_start_else() -> bool:
	return can_end_if() and open_branch() == "then"


## The names of the definitions on the tape, in the order they were made.
func defined_names() -> Array[String]:
	var out: Array[String] = []
	for node: Dictionary in nodes:
		if node["op"] == PROC:
			out.append(node["name"])
	return out


## The next name a definition can take (A, then B, then C), or "" when all three are used.
func next_proc_name() -> String:
	var used := defined_names()
	for name: String in ContractLimits.PROCEDURE_NAMES:
		if not used.has(name):
			return name
	return ""


## True when a loop, an IF or a definition has no item, or a CALL names a procedure that is not
## defined. Such a tape is not a program.
func is_incomplete() -> bool:
	return (
		TapeCells.has_empty_loop(nodes)
		or TapeCells.has_empty_if(nodes)
		or TapeCells.has_empty_proc(nodes)
		or not undefined_calls().is_empty()
	)


func has_empty_proc() -> bool:
	return TapeCells.has_empty_proc(nodes)


## Names that a CALL on the tape uses but no definition on the tape provides.
func undefined_calls() -> Array[String]:
	var out: Array[String] = []
	_collect_undefined(nodes, defined_names(), out)
	return out


func _collect_undefined(list: Array, defined: Array[String], out: Array[String]) -> void:
	for node: Dictionary in list:
		if node["op"] == CALL and not defined.has(node["name"]) and not out.has(node["name"]):
			out.append(node["name"])
		elif ContractLimits.is_loop(node["op"]):
			_collect_undefined(node["body"], defined, out)
