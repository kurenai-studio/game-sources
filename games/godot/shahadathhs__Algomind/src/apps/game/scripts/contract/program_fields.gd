class_name ProgramFields
extends RefCounted
## Field checks shared by the node checks of ProgramValidator: a procedure name, an array of
## instructions with a length range, the condition of a REPEAT_UNTIL and the count of a REPEAT.


## The name of a PROC or a CALL. Returns it when valid, else null.
static func check_name(issues: Array[Dictionary], node: Dictionary, path: String) -> Variant:
	var name_path := path + ".name"
	if not node.has("name"):
		LevelValidator._add(issues, name_path, "REQUIRED", "%s is required." % name_path)
	elif typeof(node["name"]) != TYPE_STRING:
		LevelValidator._add(issues, name_path, "INVALID_TYPE", "%s must be a string." % name_path)
	elif not ContractLimits.PROCEDURE_NAMES.has(node["name"]):
		LevelValidator._add(
			issues,
			name_path,
			"INVALID_VALUE",
			"%s must be one of %s." % [name_path, ", ".join(ContractLimits.PROCEDURE_NAMES)]
		)
	else:
		return node["name"]
	return null


## Reads an array field with a length range. Returns the array, or null when absent or not an array.
static func check_list(
	issues: Array[Dictionary],
	node: Dictionary,
	key: String,
	path: String,
	low: int,
	high: int,
	required: bool
) -> Variant:
	var list_path := "%s.%s" % [path, key]
	if not node.has(key):
		if required:
			LevelValidator._add(issues, list_path, "REQUIRED", "%s is required." % list_path)
		return null
	if typeof(node[key]) != TYPE_ARRAY:
		LevelValidator._add(
			issues, list_path, "INVALID_TYPE", "%s must be an array of instructions." % list_path
		)
		return null
	var list: Array = node[key]
	if list.size() < low or list.size() > high:
		LevelValidator._add(
			issues,
			list_path,
			"LENGTH_OUT_OF_RANGE",
			"%s must have %d to %d instructions." % [list_path, low, high]
		)
	return list


## Checks the until condition of a REPEAT_UNTIL.
static func check_until(issues: Array[Dictionary], node: Dictionary, path: String) -> void:
	var until_path := path + ".until"
	if not node.has("until"):
		LevelValidator._add(issues, until_path, "REQUIRED", "%s is required." % until_path)
	elif typeof(node["until"]) != TYPE_STRING:
		LevelValidator._add(issues, until_path, "INVALID_TYPE", "%s must be a string." % until_path)
	elif not ContractLimits.UNTIL_CONDITIONS.has(node["until"]):
		LevelValidator._add(
			issues,
			until_path,
			"INVALID_VALUE",
			"%s must be one of %s." % [until_path, ", ".join(ContractLimits.UNTIL_CONDITIONS)]
		)


## Checks the count of a REPEAT: an integer from 2 to 11, or "N" when the level offers INC.
static func check_count(
	issues: Array[Dictionary], node: Dictionary, path: String, available: Variant
) -> void:
	var count_path := path + ".count"
	if not node.has("count"):
		LevelValidator._add(issues, count_path, "REQUIRED", "%s is required." % count_path)
	elif typeof(node["count"]) == TYPE_STRING and node["count"] == ContractLimits.COUNTER_REF:
		if available != null and not (available as Array).has(ContractLimits.INC_OP):
			LevelValidator._add(
				issues,
				count_path,
				"COMMAND_NOT_AVAILABLE",
				"%s: the counter needs INC, which is not available in this level." % count_path
			)
	elif not LevelValidator._is_int(node["count"]):
		LevelValidator._add(
			issues, count_path, "INVALID_TYPE", '%s must be an integer or "N".' % count_path
		)
	else:
		var count := int(node["count"])
		if count < ContractLimits.REPEAT_COUNT_MIN or count > ContractLimits.REPEAT_COUNT_MAX:
			LevelValidator._add(
				issues,
				count_path,
				"OUT_OF_RANGE",
				(
					"%s must be from %d to %d."
					% [count_path, ContractLimits.REPEAT_COUNT_MIN, ContractLimits.REPEAT_COUNT_MAX]
				)
			)
