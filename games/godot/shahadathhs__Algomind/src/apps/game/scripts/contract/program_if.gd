class_name ProgramIf
extends RefCounted
## Checks one IF of a program, including an else-if chain. Mirrors checkIf in
## packages/level-contract/src/validate.ts; ProgramValidator calls it and owns the context.


## Checks the sensor and both branches of an IF whose op was already checked. chain is how many
## IFs of an else-if chain have been seen, this one included.
static func check_if(
	ctx: Dictionary, node: Dictionary, path: String, place: Dictionary, chain: int
) -> void:
	var issues: Array[Dictionary] = ctx["issues"]
	_check_when(ctx, node, path)
	var branch := ProgramShape.place_of(
		false, place["proc"], int(place["loops"]), true, place["recursion"]
	)
	var then_list: Variant = ProgramFields.check_list(
		issues, node, "then", path, ContractLimits.IF_THEN_MIN, ContractLimits.IF_THEN_MAX, true
	)
	if then_list != null:
		var then_items: Array = then_list
		for j in then_items.size():
			ProgramValidator.check_item(ctx, then_items[j], "%s.then[%d]" % [path, j], branch)
	var other: Variant = ProgramFields.check_list(
		issues, node, "else", path, ContractLimits.IF_ELSE_MIN, ContractLimits.IF_ELSE_MAX, true
	)
	if other == null:
		return
	var items: Array = other
	var next: Variant = null
	if items.size() == 1 and typeof(items[0]) == TYPE_DICTIONARY:
		if ContractLimits.is_if(items[0].get("op")):
			next = items[0]
	if next == null:
		for j in items.size():
			ProgramValidator.check_item(ctx, items[j], "%s.else[%d]" % [path, j], branch)
		return
	# An else-if chain: the else holds exactly one more IF.
	var next_path := path + ".else[0]"
	if chain >= ContractLimits.IF_CHAIN_MAX:
		LevelValidator._add(
			issues,
			next_path + ".op",
			"NESTED_IF",
			(
				"%s.op: an else-if chain holds at most %d IFs."
				% [next_path, ContractLimits.IF_CHAIN_MAX]
			)
		)
		return
	LevelValidator._reject_unknown(issues, next, next_path, ProgramValidator.allowed_keys("IF"))
	ctx["slots"] = int(ctx["slots"]) + 1
	check_if(ctx, next, next_path, place, chain + 1)


static func _check_when(ctx: Dictionary, node: Dictionary, path: String) -> void:
	var issues: Array[Dictionary] = ctx["issues"]
	var when_path := path + ".when"
	if not node.has("when"):
		LevelValidator._add(issues, when_path, "REQUIRED", "%s is required." % when_path)
	elif typeof(node["when"]) != TYPE_STRING:
		LevelValidator._add(issues, when_path, "INVALID_TYPE", "%s must be a string." % when_path)
	elif not ContractLimits.SENSORS.has(node["when"]):
		LevelValidator._add(
			issues,
			when_path,
			"INVALID_VALUE",
			"%s must be one of %s." % [when_path, ", ".join(ContractLimits.SENSORS)]
		)
	elif (
		ContractLimits.is_marker_sensor(node["when"])
		and ctx["available"] != null
		and not (ctx["available"] as Array).has(ContractLimits.MARK_OP)
	):
		LevelValidator._add(
			issues,
			when_path,
			"COMMAND_NOT_AVAILABLE",
			"%s needs MARK, which is not available in this level." % node["when"]
		)
