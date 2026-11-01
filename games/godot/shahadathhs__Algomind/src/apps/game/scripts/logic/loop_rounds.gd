class_name LoopRounds
extends RefCounted
## The round of a loop that holds another loop, worked out from the trace shown so far. A trace
## entry carries only the round of the innermost loop it ran in, so the round of the outer loop
## is counted here: inside one round of the outer loop the entries come in a strictly rising
## order (body item, then inner round, then place in the inner body), and a new round starts
## when that order falls back. Pure data.


## The 1-based round of the loop at `loop_path` (an Array of node indexes) after the first
## `cursor` entries of `trace`. `loop` is that loop's node and `in_proc` is true when it stands
## in a procedure body. 0 when no entry ran in it. Entries of a procedure that the loop calls
## belong to the loop but do not move its round.
static func outer_round(
	trace: Array, cursor: int, loop_path: Array, loop: Dictionary, in_proc: bool
) -> int:
	if cursor <= 0 or cursor > trace.size():
		return 0
	var call: Variant = trace[cursor - 1]["call"] if in_proc else null
	var first := -1
	var i := cursor - 1
	while i >= 0 and _belongs(trace[i], loop_path, call, in_proc):
		first = i
		i -= 1
	if first < 0:
		return 0
	var round_number := 1
	var previous: Array = []
	for k in range(first, cursor):
		if not _runs_in(trace[k], loop_path, call):
			continue
		var key := _key(trace[k], loop_path.size(), loop)
		if not previous.is_empty() and _compare(key, previous) <= 0:
			round_number += 1
		previous = key
	return round_number


## True when the entry ran directly in the loop (not through a CALL of the main program).
static func _runs_in(entry: Dictionary, loop_path: Array, call: Variant) -> bool:
	var node: Array = entry["node"]
	if node.size() <= loop_path.size() or entry["call"] != call:
		return false
	return node.slice(0, loop_path.size()) == loop_path


## True when the entry belongs to the loop: it ran in it, or in a procedure the loop called.
static func _belongs(entry: Dictionary, loop_path: Array, call: Variant, in_proc: bool) -> bool:
	if _runs_in(entry, loop_path, call):
		return true
	var via: Variant = entry["call"]
	if in_proc or via == null:
		return false
	return (
		(via as Array).size() > loop_path.size()
		and (via as Array).slice(0, loop_path.size()) == loop_path
	)


## The order key of an entry inside the loop: the body item, then (for an inner loop) its round,
## then the rest of the path.
static func _key(entry: Dictionary, depth: int, loop: Dictionary) -> Array:
	var tail: Array = (entry["node"] as Array).slice(depth)
	var item: int = tail[0]
	var key: Array = [item]
	if ContractLimits.is_loop(((loop["body"] as Array)[item] as Dictionary)["op"]):
		key.append(int(entry["round"]) if entry["round"] != null else 0)
	key.append_array(tail.slice(1))
	return key


## Lexicographic comparison of two keys: negative, zero or positive.
static func _compare(a: Array, b: Array) -> int:
	for i in mini(a.size(), b.size()):
		if int(a[i]) != int(b[i]):
			return int(a[i]) - int(b[i])
	return a.size() - b.size()
