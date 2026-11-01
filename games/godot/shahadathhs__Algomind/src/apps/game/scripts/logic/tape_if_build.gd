class_name TapeIfBuild
extends RefCounted
## The cells of an IF for TapeCells: its header, its then cells, the ELSE divider and its else
## cells. When the else holds an IF (an else-if chain) the divider is left out and the cells of
## that IF follow, headed by an ELSE IF cell; the whole chain shares the bracket of its first IF.
## Pure data.


## Adds the cells of `item` at `path`. `groups` already ends with the key of the chain's first IF.
## `root` is "" for the first IF of a chain and its key for the IFs that follow in an else.
static func add_if(
	out: Array[Dictionary],
	item: Dictionary,
	path: Array,
	ctx: Dictionary,
	groups: Array,
	showing_else: String,
	root: String = ""
) -> void:
	var key := TapeCells.key_of(path)
	var header := _cell("if", path, ctx, groups, key)
	header["when"] = item["when"]
	if root != "":
		header["elseif"] = true
		header["branch"] = "else"
		header["pos"] = 0
		header["group"] = root
	out.append(header)
	var then_list: Array = item["then"]
	var else_list: Array = item["else"]
	for k in then_list.size():
		out.append(_branch_cell(then_list[k], path, k, k, "then", ctx, groups))
	if else_list.size() == 1 and ContractLimits.is_if(else_list[0]["op"]):
		var next_path := path.duplicate()
		next_path.append(then_list.size())
		add_if(out, else_list[0], next_path, ctx, groups, showing_else, root if root != "" else key)
		return
	if not else_list.is_empty() or showing_else == key:
		out.append(_cell("else", path, ctx, groups, key))
	for k in else_list.size():
		out.append(_branch_cell(else_list[k], path, then_list.size() + k, k, "else", ctx, groups))


static func _cell(
	kind: String, path: Array, ctx: Dictionary, groups: Array, key: String
) -> Dictionary:
	return {
		"kind": kind,
		"op": "IF",
		"path": path,
		"loop": ctx["loop"],
		"iff": key,
		"proc": ctx["proc"],
		"groups": groups,
	}


static func _branch_cell(
	item: Dictionary,
	path: Array,
	trace_k: int,
	pos: int,
	branch: String,
	ctx: Dictionary,
	groups: Array
) -> Dictionary:
	var cell_path := path.duplicate()
	cell_path.append(trace_k)
	return {
		"kind": "op",
		"op": item["op"],
		"path": cell_path,
		"loop": ctx["loop"],
		"iff": TapeCells.key_of(path),
		"branch": branch,
		"pos": pos,
		"proc": ctx["proc"],
		"groups": groups,
	}
