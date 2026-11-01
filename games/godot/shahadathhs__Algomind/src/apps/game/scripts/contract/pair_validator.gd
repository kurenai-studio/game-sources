class_name PairValidator
extends RefCounted
## Validates the optional paired cells of a level: keys and doors (`locks`) and items and docks
## (`deliveries`). Mirrors validatePairs in packages/level-contract/src/validate.ts. Issues use
## LevelValidator's helpers and shape.

const LOCKS := {
	"field": "locks",
	"parts": ["key", "door"],
	"noun": "keys and doors",
	"min": ContractLimits.LOCKS_MIN,
	"max": ContractLimits.LOCKS_MAX,
	"apart": [],
	"wall": "LOCK_ON_WALL",
	"start": "LOCK_ON_START",
	"goal": "LOCK_ON_GOAL",
	"repeat": "LOCK_CELLS_REPEAT",
	"boards": "LOCKS_WITH_BOARDS",
	"sweep": "LOCKS_WITH_SWEEP",
}

const DELIVERIES := {
	"field": "deliveries",
	"parts": ["item", "dock"],
	"noun": "deliveries",
	"min": ContractLimits.DELIVERIES_MIN,
	"max": ContractLimits.DELIVERIES_MAX,
	"apart": ["locks"],
	"wall": "DELIVERY_ON_WALL",
	"start": "DELIVERY_ON_START",
	"goal": "DELIVERY_ON_GOAL",
	"repeat": "DELIVERY_CELLS_REPEAT",
	"boards": "DELIVERIES_WITH_BOARDS",
	"sweep": "DELIVERIES_WITH_SWEEP",
}

const SWITCHES := {
	"field": "switches",
	"parts": ["switch", "gate"],
	"noun": "switches and gates",
	"min": ContractLimits.SWITCHES_MIN,
	"max": ContractLimits.SWITCHES_MAX,
	"apart": ["locks", "deliveries"],
	"flag": "open",
	"wall": "SWITCH_ON_WALL",
	"start": "SWITCH_ON_START",
	"goal": "SWITCH_ON_GOAL",
	"repeat": "SWITCH_CELLS_REPEAT",
	"boards": "SWITCHES_WITH_BOARDS",
	"sweep": "SWITCHES_WITH_SWEEP",
}

const PART_NAMES := {
	"locks": ["key", "door"],
	"deliveries": ["item", "dock"],
	"switches": ["switch", "gate"],
	"teleports": ["a", "b"],
}

const TELEPORTS := {
	"field": "teleports",
	"parts": ["a", "b"],
	"noun": "teleporters",
	"min": ContractLimits.TELEPORTS_MIN,
	"max": ContractLimits.TELEPORTS_MAX,
	"apart": ["locks", "deliveries", "switches", "ice", "belts"],
	"wall": "TELEPORT_ON_WALL",
	"start": "TELEPORT_ON_START",
	"goal": "TELEPORT_ON_GOAL",
	"repeat": "TELEPORT_CELLS_REPEAT",
	"boards": "TELEPORTS_WITH_BOARDS",
	"sweep": "TELEPORTS_WITH_SWEEP",
}


static func check_all(issues: Array[Dictionary], root: Dictionary) -> void:
	check_pairs(issues, root, LOCKS)
	check_pairs(issues, root, DELIVERIES)
	check_pairs(issues, root, SWITCHES)
	check_pairs(issues, root, TELEPORTS)


static func check_pairs(issues: Array[Dictionary], root: Dictionary, spec: Dictionary) -> void:
	var field: String = spec["field"]
	if not root.has(field):
		return
	var raw: Variant = root[field]
	if typeof(raw) != TYPE_ARRAY:
		LevelValidator._add(issues, field, "INVALID_TYPE", "%s must be an array." % field)
		return
	var entries: Array = raw
	if entries.size() < int(spec["min"]) or entries.size() > int(spec["max"]):
		LevelValidator._add(
			issues,
			field,
			"LENGTH_OUT_OF_RANGE",
			(
				"%s must have %d to %d entries, or be left out."
				% [field, int(spec["min"]), int(spec["max"])]
			)
		)
	if root.has("extraBoards"):
		LevelValidator._add(
			issues, field, spec["boards"], "A level with test boards cannot have %s." % spec["noun"]
		)
	var goal: Variant = root.get("goal")
	if typeof(goal) == TYPE_DICTIONARY and (goal as Dictionary).get("type") == "visit_all":
		LevelValidator._add(
			issues,
			field,
			spec["sweep"],
			"A level that sweeps every cell cannot have %s." % spec["noun"]
		)
	var facts := PatrolValidator.board_facts(root)
	var seen: Array[Vector2i] = []
	for other: String in spec["apart"]:
		seen.append_array(_cells_of(root, other))
	for i in entries.size():
		_check_entry(issues, entries[i], "%s[%d]" % [field, i], spec, facts, seen)


## One cell read leniently from a value that may be a pair of integers, or null.
static func _as_cell(value: Variant) -> Variant:
	if typeof(value) == TYPE_ARRAY and (value as Array).size() == 2:
		var x: Variant = value[0]
		var y: Variant = value[1]
		if LevelValidator._is_int(x) and LevelValidator._is_int(y):
			return Vector2i(int(x), int(y))
	return null


## The cells named by a field of the level (`locks`, `deliveries`, `switches`, `ice` or `belts`),
## read leniently: an entry that is not a cell is skipped.
static func _cells_of(root: Dictionary, field: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if typeof(root.get(field)) != TYPE_ARRAY:
		return cells
	for entry: Variant in root[field]:
		var found: Array = []
		if field == "ice":
			found.append(_as_cell(entry))
		elif typeof(entry) == TYPE_DICTIONARY:
			var names: Array = ["cell"] if field == "belts" else PART_NAMES[field]
			for part: String in names:
				found.append(_as_cell((entry as Dictionary).get(part)))
		for cell: Variant in found:
			if cell != null:
				cells.append(cell)
	return cells


static func _check_entry(
	issues: Array[Dictionary],
	entry: Variant,
	path: String,
	spec: Dictionary,
	facts: Dictionary,
	seen: Array[Vector2i]
) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		LevelValidator._add(issues, path, "INVALID_TYPE", "%s must be an object." % path)
		return
	var pair_entry: Dictionary = entry
	var parts: Array[String] = []
	parts.assign(spec["parts"])
	var allowed := parts.duplicate()
	var flag: String = spec.get("flag", "")
	if flag != "":
		allowed.append(flag)
	LevelValidator._reject_unknown(issues, pair_entry, path, allowed)
	if flag != "" and pair_entry.has(flag) and typeof(pair_entry[flag]) != TYPE_BOOL:
		var flag_path := "%s.%s" % [path, flag]
		LevelValidator._add(
			issues, flag_path, "INVALID_TYPE", "%s must be true or false." % flag_path
		)
	for part: String in parts:
		var cell_path := "%s.%s" % [path, part]
		if not pair_entry.has(part):
			LevelValidator._add(issues, cell_path, "REQUIRED", "%s is required." % cell_path)
			continue
		var pair: Variant = LevelValidator._check_pair(
			issues, pair_entry[part], cell_path, facts["size"]
		)
		if pair == null:
			continue
		var at: Vector2i = pair
		if (facts["walls"] as Array).has(at):
			LevelValidator._add(
				issues, cell_path, spec["wall"], "%s must not be a wall." % cell_path
			)
		if facts["start"] != null and facts["start"] == at:
			LevelValidator._add(
				issues, cell_path, spec["start"], "%s must not be the automaton's cell." % cell_path
			)
		if facts["goal"] != null and facts["goal"] == at:
			LevelValidator._add(
				issues, cell_path, spec["goal"], "%s must not be the target." % cell_path
			)
		if seen.has(at):
			LevelValidator._add(
				issues,
				cell_path,
				spec["repeat"],
				"%s repeats an earlier cell of %s." % [cell_path, spec["noun"]]
			)
		else:
			seen.append(at)
