class_name TapeCells
extends RefCounted
## The cells the tape shows for a list of program nodes (see TapeModel). Pure data.
##
## Every cell is { kind, op, path, loop, iff, proc, groups } plus:
## - kind "op": a primitive. `path` is the node's trace path ([i], [i, j] in a loop or procedure
##   body, [i, k] in an IF at the top level, [i, j, k] in an IF in a body; k counts the then
##   primitives first; [p, j, m] in a loop in procedure p). Primitives in an IF also have
##   `branch` ("then" or "else") and `pos` (index in it).
## - kind "count" / "until": the first cell of a loop; `body` is its number of items, `count`
##   (a number, or "N") is set on "count" and `until` (BLOCKED or GOAL) on "until"; `nests` is
##   true when the body holds a loop (a loop may hold one loop when the level allows it).
## - kind "if": the first cell of an IF; `when` is its sensor. The first cell of an IF that an
##   else holds (an else-if chain) also has `elseif` true, `branch` "else", `pos` 0 and `group`,
##   the key of the first IF of the chain: a chain shares one bracket.
## - kind "else": the divider between the then and else tiles of an IF (not a slot).
## - kind "proc": the first cell of a procedure definition; `name` is A, B, or C and `body` its
##   number of items. kind "call": a CALL; `name` is the procedure it runs.
## `loop` is the index of the top-level node when the cell is in a loop (-1 otherwise), `iff`
## identifies the IF it belongs to (its path joined with "_", "" outside IFs), `proc` is the
## index of the procedure it belongs to (-1 in the main program) and `groups` lists the keys
## (key_of the header path) of every procedure, loop and IF around it, outermost first, a header
## cell included in its own group.
##
## Definitions come first in `nodes`; the main program follows them.

const REPEAT := ContractLimits.REPEAT_OP
const REPEAT_UNTIL := ContractLimits.REPEAT_UNTIL_OP
const IF := ContractLimits.IF_OP
const PROC := ContractLimits.PROC_OP
const CALL := ContractLimits.CALL_OP


## `showing_else` is the `iff` key of an IF whose else divider shows although its else is empty.
static func build(nodes: Array, showing_else: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in nodes.size():
		var node: Dictionary = nodes[i]
		var proc: int = i if node["op"] == PROC else -1
		_add_node(out, node, [i], {"groups": [], "proc": proc, "loop": -1}, showing_else)
	return out


static func key_of(path: Array) -> String:
	var parts := PackedStringArray()
	for part: Variant in path:
		parts.append(str(part))
	return "_".join(parts)


## Adds the cells of one node (and what it holds). `ctx` has the enclosing `groups`, `proc` and
## `loop` values.
static func _add_node(
	out: Array[Dictionary], node: Dictionary, path: Array, ctx: Dictionary, showing_else: String
) -> void:
	var op: String = node["op"]
	var key := key_of(path)
	var groups: Array = (ctx["groups"] as Array).duplicate()
	if ContractLimits.is_if(op):
		groups.append(key)
		TapeIfBuild.add_if(out, node, path, ctx, groups, showing_else)
		return
	var cell := {
		"kind": "op", "op": op, "path": path, "loop": ctx["loop"], "iff": "", "proc": ctx["proc"]
	}
	if op == CALL:
		cell["kind"] = "call"
		cell["name"] = node["name"]
		if node.has("when"):
			cell["when"] = node["when"]
		cell["groups"] = groups
		out.append(cell)
		return
	if op != PROC and not ContractLimits.is_loop(op):
		cell["groups"] = groups
		out.append(cell)
		return
	groups.append(key)
	var body: Array = node["body"]
	cell["groups"] = groups
	cell["body"] = body.size()
	var inner := {"groups": groups, "proc": ctx["proc"], "loop": ctx["loop"]}
	if op == PROC:
		cell["kind"] = "proc"
		cell["name"] = node["name"]
	else:
		cell["kind"] = "count" if op == REPEAT else "until"
		cell["until"] = String(node.get("until", ""))
		if op == REPEAT:
			cell["count"] = node["count"] if node["count"] is String else int(node["count"])
		cell["loop"] = path[0]
		cell["nests"] = _holds_loop(body)
		inner["loop"] = path[0]
	out.append(cell)
	for j in body.size():
		var inner_path := path.duplicate()
		inner_path.append(j)
		_add_node(out, body[j], inner_path, inner, showing_else)


## The node at a path of nodes ([i], [i, j], [i, j, m]); every step after the first goes into a
## body, except a step out of an IF, which goes into the IF that its else holds (an else-if
## chain). An IF is reached by its own path, never through its branches.
static func node_at(nodes: Array, path: Array) -> Dictionary:
	var node: Dictionary = nodes[int(path[0])]
	for k in range(1, path.size()):
		if ContractLimits.is_if(node["op"]):
			node = node["else"][0]
		else:
			node = node["body"][int(path[k])]
	return node


## The list (the program, a loop or procedure body, or an IF branch) that holds the cell's node.
static func siblings_of(nodes: Array, cell: Dictionary) -> Array:
	var path: Array = cell["path"]
	var owner: Array = path.slice(0, path.size() - 1)
	if cell.has("branch"):
		return node_at(nodes, owner)[cell["branch"]]
	return nodes if owner.is_empty() else node_at(nodes, owner)["body"]


## The position of the cell's node in siblings_of.
static func position_of(cell: Dictionary) -> int:
	return int(cell["pos"]) if cell.has("branch") else int((cell["path"] as Array).back())


## The nodes in the simulator's format: copies without the editing flags.
static func program_of(nodes: Array) -> Array:
	var out: Array = []
	for node: Dictionary in nodes:
		out.append(_plain(node))
	return out


static func _plain(node: Dictionary) -> Dictionary:
	var op: String = node["op"]
	if op == IF:
		return {
			"op": IF,
			"when": node["when"],
			"then": _plain_list(node["then"]),
			"else": _plain_list(node["else"]),
		}
	if op == REPEAT:
		var count: Variant = node["count"] if node["count"] is String else int(node["count"])
		return {"op": REPEAT, "count": count, "body": _plain_list(node["body"])}
	if op == REPEAT_UNTIL:
		return {"op": REPEAT_UNTIL, "until": node["until"], "body": _plain_list(node["body"])}
	if op == PROC:
		return {"op": PROC, "name": node["name"], "body": _plain_list(node["body"])}
	if op == CALL:
		var call := {"op": CALL, "name": node["name"]}
		if node.has("when"):
			call["when"] = node["when"]
		return call
	return {"op": op}


static func _plain_list(list: Array) -> Array:
	return program_of(list)


## True when a loop (anywhere, procedure bodies included) has no item.
static func has_empty_loop(nodes: Array) -> bool:
	for node: Dictionary in nodes:
		if ContractLimits.is_loop(node["op"]) and (node["body"] as Array).is_empty():
			return true
		if _holds_body(node) and has_empty_loop(node["body"]):
			return true
	return false


## True when a procedure definition has no item.
static func has_empty_proc(nodes: Array) -> bool:
	for node: Dictionary in nodes:
		if node["op"] == PROC and (node["body"] as Array).is_empty():
			return true
	return false


## True when an IF (anywhere) has no then command.
static func has_empty_if(nodes: Array) -> bool:
	for node: Dictionary in nodes:
		if ContractLimits.is_if(node["op"]) and _if_is_empty(node):
			return true
		if _holds_body(node) and has_empty_if(node["body"]):
			return true
	return false


static func _holds_loop(body: Array) -> bool:
	for item: Dictionary in body:
		if ContractLimits.is_loop(item["op"]):
			return true
	return false


static func _holds_body(node: Dictionary) -> bool:
	return ContractLimits.is_loop(node["op"]) or node["op"] == PROC


## True when an IF, or an IF its else holds (an else-if chain), has no then command.
static func _if_is_empty(node: Dictionary) -> bool:
	if (node["then"] as Array).is_empty():
		return true
	var other: Array = node["else"]
	return other.size() == 1 and ContractLimits.is_if(other[0]["op"]) and _if_is_empty(other[0])
