class_name ProgramValidator
extends RefCounted
## Validates a program (the player's or a reference solution) against a level's limits.
## Mirrors checkProgram in packages/level-contract/src/validate.ts. LevelValidator calls it and
## owns the shared helpers; the issue format is the same.
##
## Slots: a primitive is 1; a loop is 1 plus the slots of its body items; an IF is 1 plus the
## primitives in its two branches; a CALL is 1; a PROC is 1 plus its body items.

## A place is a ProgramShape place: { top, proc, loops, branch }. A loop may hold one more loop
## only when the level lists the mechanic nested_loops.


## Best-effort read of availableCommands and maxCommands from a level that may have other
## problems. "available" and "max" are null when unreadable.
static func limits_of(level: Variant) -> Dictionary:
	var limits := {"available": null, "max": null, "nested": false, "recursion": false}
	if typeof(level) != TYPE_DICTIONARY:
		return limits
	var root: Dictionary = level
	if typeof(root.get("availableCommands")) == TYPE_ARRAY:
		var available: Array[String] = []
		for item: Variant in root["availableCommands"]:
			if LevelValidator._is_command_name(item):
				available.append(item)
		limits["available"] = available
	var constraints: Variant = root.get("constraints")
	if (
		typeof(constraints) == TYPE_DICTIONARY
		and LevelValidator._is_int(constraints.get("maxCommands"))
	):
		limits["max"] = int(constraints["maxCommands"])
	var requires: Variant = root.get("requires")
	if typeof(requires) == TYPE_DICTIONARY and typeof(requires.get("mechanics")) == TYPE_ARRAY:
		limits["nested"] = (requires["mechanics"] as Array).has(
			ContractLimits.NESTED_LOOPS_MECHANIC
		)
		limits["recursion"] = (requires["mechanics"] as Array).has(
			ContractLimits.RECURSION_MECHANIC
		)
	return limits


static func check_program(
	issues: Array[Dictionary], program: Variant, base: String, limits: Dictionary
) -> void:
	if typeof(program) != TYPE_ARRAY:
		LevelValidator._add(
			issues, base, "INVALID_TYPE", "%s must be an array of instructions." % base
		)
		return
	var nodes: Array = program
	var proc_names := {}
	for node: Variant in nodes:
		if (
			typeof(node) == TYPE_DICTIONARY
			and ContractLimits.is_proc(node.get("op"))
			and typeof(node.get("name")) == TYPE_STRING
		):
			proc_names[node["name"]] = true
	var ctx := {
		"issues": issues,
		"available": limits["available"],
		"nested": limits["nested"],
		"recursion": limits["recursion"],
		"proc_names": proc_names,
		"defined": {},
		"slots": 0,
	}
	for i in nodes.size():
		check_item(ctx, nodes[i], "%s[%d]" % [base, i], ProgramShape.top_place(limits["recursion"]))
	var max_commands: Variant = limits["max"]
	if max_commands != null and int(ctx["slots"]) > int(max_commands):
		LevelValidator._add(
			issues,
			base,
			"TOO_MANY_COMMANDS",
			"%s uses %d slots; this level allows %d." % [base, ctx["slots"], max_commands]
		)


## One instruction in a place: checks it, counts its slots, and goes into what it holds.
static func check_item(ctx: Dictionary, item: Variant, path: String, place: Dictionary) -> void:
	var issues: Array[Dictionary] = ctx["issues"]
	ctx["slots"] = int(ctx["slots"]) + 1
	if typeof(item) != TYPE_DICTIONARY:
		LevelValidator._add(
			issues, path, "INVALID_TYPE", "%s must be an instruction object." % path
		)
		return
	var node: Dictionary = item
	var checked := _check_op(issues, node, path, ctx, place)
	# A node the place does not allow is reported once, not field by field.
	if not checked["nested"]:
		LevelValidator._reject_unknown(
			issues, node, path, allowed_keys(checked["op"], ctx["recursion"])
		)
	var op: Variant = checked["op"]
	if ContractLimits.is_loop(op):
		var inner := ProgramShape.place_of(
			false, place["proc"], int(place["loops"]) + 1, false, place["recursion"]
		)
		_check_loop(ctx, node, path, op, inner)
	elif ContractLimits.is_if(op):
		ProgramIf.check_if(ctx, node, path, place, 1)
	elif ContractLimits.is_proc(op):
		_check_proc(ctx, node, path)
	elif ContractLimits.is_call(op):
		var name: Variant = ProgramFields.check_name(issues, node, path)
		if name != null and not (ctx["proc_names"] as Dictionary).has(name):
			LevelValidator._add(
				issues,
				path + ".name",
				"UNDEFINED_PROCEDURE",
				"%s.name: no procedure %s is defined." % [path, name]
			)
		if ctx["recursion"] and node.has("when"):
			var when_path := path + ".when"
			if typeof(node["when"]) != TYPE_STRING:
				LevelValidator._add(
					issues, when_path, "INVALID_TYPE", "%s must be a string." % when_path
				)
			elif not ContractLimits.SENSORS.has(node["when"]):
				LevelValidator._add(
					issues, when_path, "INVALID_VALUE", "%s must be one of the sensors." % when_path
				)


static func allowed_keys(op: Variant, recursion: bool = false) -> Array[String]:
	if ContractLimits.is_repeat(op):
		return ["op", "count", "body"]
	if ContractLimits.is_repeat_until(op):
		return ["op", "until", "body"]
	if ContractLimits.is_if(op):
		return ["op", "when", "then", "else"]
	if ContractLimits.is_proc(op):
		return ["op", "name", "body"]
	if ContractLimits.is_call(op):
		if recursion:
			return ["op", "name", "when"]
		return ["op", "name"]
	return ["op"]


## Checks the op of one instruction. Returns { op, nested }: op is the op when it is a known one,
## else null; nested is true when the place does not allow it.
static func _check_op(
	issues: Array[Dictionary], node: Dictionary, path: String, ctx: Dictionary, place: Dictionary
) -> Dictionary:
	var available: Variant = ctx["available"]
	var op_path := path + ".op"
	if not node.has("op"):
		LevelValidator._add(issues, op_path, "REQUIRED", "%s is required." % op_path)
		return {"op": null, "nested": false}
	var op: Variant = node["op"]
	if typeof(op) != TYPE_STRING:
		LevelValidator._add(issues, op_path, "INVALID_TYPE", "%s must be a string." % op_path)
		return {"op": null, "nested": false}
	if not ContractLimits.is_node_op(op):
		LevelValidator._add(
			issues, op_path, "UNKNOWN_COMMAND", "%s is not a known command." % op_path
		)
		return {"op": null, "nested": false}
	var loops := int(place["loops"])
	var loop_allowed: bool = not place["branch"] and (loops == 0 or (loops == 1 and ctx["nested"]))
	if ContractLimits.is_loop(op) and not loop_allowed:
		LevelValidator._add(
			issues, op_path, "NESTED_REPEAT", "%s: a loop cannot contain a loop here." % op_path
		)
		return {"op": null, "nested": true}
	if place["branch"] and ContractLimits.is_if(op):
		LevelValidator._add(
			issues, op_path, "NESTED_IF", "%s: an IF cannot contain an IF." % op_path
		)
		return {"op": null, "nested": true}
	if not place["top"] and ContractLimits.is_proc(op):
		LevelValidator._add(
			issues,
			op_path,
			"NESTED_PROC",
			"%s: a procedure can only be defined at the top level." % op_path
		)
		return {"op": null, "nested": true}
	var in_proc_body: bool = place["proc"] and int(place["loops"]) == 0 and not place["branch"]
	if (
		ContractLimits.is_call(op)
		and (place["branch"] or (place["proc"] and not (ctx["recursion"] and in_proc_body)))
	):
		LevelValidator._add(
			issues,
			op_path,
			"CALL_NOT_ALLOWED",
			"%s: a CALL stands in the main program or, with recursion, a procedure body." % op_path
		)
		return {"op": null, "nested": true}
	var needed: String = ContractLimits.PROC_OP if ContractLimits.is_call(op) else op
	if available != null and not (available as Array).has(needed):
		LevelValidator._add(
			issues, op_path, "COMMAND_NOT_AVAILABLE", "%s is not available in this level." % op
		)
	return {"op": op, "nested": false}


## Checks the name and the body of a PROC whose op was already checked.
static func _check_proc(ctx: Dictionary, node: Dictionary, path: String) -> void:
	var issues: Array[Dictionary] = ctx["issues"]
	var name: Variant = ProgramFields.check_name(issues, node, path)
	if name != null:
		var defined: Dictionary = ctx["defined"]
		if defined.has(name):
			LevelValidator._add(
				issues,
				path + ".name",
				"DUPLICATE_PROCEDURE",
				"%s.name: %s is defined twice." % [path, name]
			)
		defined[name] = true
	var body: Variant = ProgramFields.check_list(
		issues, node, "body", path, ContractLimits.PROC_BODY_MIN, ContractLimits.PROC_BODY_MAX, true
	)
	if body != null:
		var items: Array = body
		for j in items.size():
			check_item(
				ctx,
				items[j],
				"%s.body[%d]" % [path, j],
				ProgramShape.place_of(false, true, 0, false, ctx["recursion"])
			)


## Checks the count (REPEAT) or condition (REPEAT_UNTIL) and the body of a loop.
static func _check_loop(
	ctx: Dictionary, node: Dictionary, path: String, op: Variant, body_place: Dictionary
) -> void:
	var issues: Array[Dictionary] = ctx["issues"]
	if ContractLimits.is_repeat_until(op):
		ProgramFields.check_until(issues, node, path)
	else:
		ProgramFields.check_count(issues, node, path, ctx["available"])
	var body: Variant = ProgramFields.check_list(
		issues,
		node,
		"body",
		path,
		ContractLimits.REPEAT_BODY_MIN,
		ContractLimits.REPEAT_BODY_MAX,
		true
	)
	if body == null:
		return
	var items: Array = body
	for j in items.size():
		check_item(ctx, items[j], "%s.body[%d]" % [path, j], body_place)
