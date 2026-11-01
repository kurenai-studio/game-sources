class_name ProgramShape
extends RefCounted
## Which program nodes the simulator can run. A node that fails these checks stops the run with
## INVALID_INSTRUCTION. Mirrors the runnable function of level-contract src/simulate.ts.

## The place of a node in the main program: nothing encloses it.
const TOP := {"top": true, "proc": false, "loops": 0, "branch": false, "recursion": false}


## The place of a top-level node of a level; `recursion` is true when the level lists the mechanic
## recursion (a CALL may then stand in a procedure body).
static func top_place(recursion: bool) -> Dictionary:
	return place_of(true, false, 0, false, recursion)


## Where a node stands, which decides what it may hold: top (a PROC may stand here), proc (inside
## a procedure body: a CALL only with the mechanic recursion), loops (how many loops enclose it: a
## loop needs fewer than two), branch (inside an IF branch: only actions) and recursion.
static func place_of(
	top: bool, proc: bool, loops: int, branch: bool, recursion: bool = false
) -> Dictionary:
	return {"top": top, "proc": proc, "loops": loops, "branch": branch, "recursion": recursion}


## True for one action node: an object whose op is a move, a turn, INC or MARK.
static func is_primitive(node: Variant) -> bool:
	return typeof(node) == TYPE_DICTIONARY and ContractLimits.is_action(node.get("op"))


## True for a list of actions whose length is within [low, high].
static func _is_action_list(list: Variant, low: int, high: int) -> bool:
	if typeof(list) != TYPE_ARRAY:
		return false
	var items: Array = list
	if items.size() < low or items.size() > high:
		return false
	for item: Variant in items:
		if not is_primitive(item):
			return false
	return true


## True for an IF the simulator can run: a known sensor, 1 to 4 actions to run and 0 to 4 actions
## (or one more IF, up to the chain limit) otherwise. chain counts the IFs seen, this one included.
static func is_runnable_if(node: Variant, chain: int = 1) -> bool:
	if typeof(node) != TYPE_DICTIONARY or not ContractLimits.is_if(node.get("op")):
		return false
	if chain > ContractLimits.IF_CHAIN_MAX:
		return false
	var when: Variant = node.get("when")
	if typeof(when) != TYPE_STRING or not ContractLimits.SENSORS.has(when):
		return false
	if not _is_action_list(
		node.get("then"), ContractLimits.IF_THEN_MIN, ContractLimits.IF_THEN_MAX
	):
		return false
	var other: Variant = node.get("else")
	if typeof(other) == TYPE_ARRAY and (other as Array).size() == 1:
		var only: Variant = (other as Array)[0]
		if typeof(only) == TYPE_DICTIONARY and ContractLimits.is_if(only.get("op")):
			return is_runnable_if(only, chain + 1)
	return _is_action_list(other, ContractLimits.IF_ELSE_MIN, ContractLimits.IF_ELSE_MAX)


## True for a list of runnable items whose length is within [low, high].
static func _is_runnable_list(
	list: Variant, low: int, high: int, place: Dictionary, procs: Dictionary
) -> bool:
	if typeof(list) != TYPE_ARRAY:
		return false
	var items: Array = list
	if items.size() < low or items.size() > high:
		return false
	for item: Variant in items:
		if not is_runnable(item, place, procs):
			return false
	return true


## True when the node and everything inside it can be run: known ops and conditions, bodies and
## branches of the right size, and only what the place allows. procs maps the names a CALL may use.
## The simulator runs two loop levels whether or not the level lists nested_loops; a third stops it.
static func is_runnable(node: Variant, place: Dictionary, procs: Dictionary) -> bool:
	if typeof(node) != TYPE_DICTIONARY:
		return false
	if is_primitive(node):
		return true
	var op: Variant = node.get("op")
	if ContractLimits.is_if(op):
		return not place["branch"] and is_runnable_if(node)
	if ContractLimits.is_call(op):
		var name: Variant = node.get("name")
		# Inside a procedure a CALL stands directly in the body (the validator checks the mechanic).
		var stands: bool = (
			not place["branch"]
			and (not place["proc"] or (place["recursion"] and int(place["loops"]) == 0))
		)
		var when: Variant = node.get("when", null)
		var sensor_ok: bool = (
			when == null
			or (
				place["recursion"]
				and typeof(when) == TYPE_STRING
				and ContractLimits.SENSORS.has(when)
			)
		)
		return stands and sensor_ok and typeof(name) == TYPE_STRING and procs.has(name)
	if ContractLimits.is_loop(op):
		if place["branch"] or int(place["loops"]) >= 2:
			return false
		if ContractLimits.is_repeat(op):
			if not _is_valid_count(node.get("count")):
				return false
		else:
			var until: Variant = node.get("until")
			if typeof(until) != TYPE_STRING or not ContractLimits.UNTIL_CONDITIONS.has(until):
				return false
		var inner := place_of(
			false, place["proc"], int(place["loops"]) + 1, false, place["recursion"]
		)
		return _is_runnable_list(
			node.get("body"),
			ContractLimits.REPEAT_BODY_MIN,
			ContractLimits.REPEAT_BODY_MAX,
			inner,
			procs
		)
	if ContractLimits.is_proc(op):
		var proc_name: Variant = node.get("name")
		return (
			place["top"]
			and typeof(proc_name) == TYPE_STRING
			and ContractLimits.PROCEDURE_NAMES.has(proc_name)
			and _is_runnable_list(
				node.get("body"),
				ContractLimits.PROC_BODY_MIN,
				ContractLimits.PROC_BODY_MAX,
				place_of(false, true, 0, false, place["recursion"]),
				procs
			)
		)
	return false


static func _is_valid_count(count: Variant) -> bool:
	if typeof(count) == TYPE_STRING:
		return count == ContractLimits.COUNTER_REF
	if typeof(count) == TYPE_FLOAT:
		if count != floorf(count):
			return false
	elif typeof(count) != TYPE_INT:
		return false
	return (
		int(count) >= ContractLimits.REPEAT_COUNT_MIN
		and int(count) <= ContractLimits.REPEAT_COUNT_MAX
	)


## Every procedure name a definition of the program gives, for checking a CALL inside a definition.
static func proc_names(program: Array) -> Dictionary:
	var names := {}
	for node: Variant in program:
		if typeof(node) == TYPE_DICTIONARY and ContractLimits.is_proc(node.get("op")):
			var name: Variant = node.get("name")
			if typeof(name) == TYPE_STRING and not names.has(name):
				names[name] = true
	return names


## The procedures a CALL can reach: name -> { "node": the PROC node, "index": its index }. The
## first well-formed definition of each name wins.
static func reachable_procs(program: Array, top: Dictionary = TOP) -> Dictionary:
	var procs := {}
	var names := proc_names(program)
	for i in program.size():
		var node: Variant = program[i]
		if typeof(node) != TYPE_DICTIONARY or not ContractLimits.is_proc(node.get("op")):
			continue
		var name: Variant = node.get("name")
		if typeof(name) != TYPE_STRING or procs.has(name):
			continue
		if is_runnable(node, top, names):
			procs[name] = {"node": node, "index": i}
	return procs
