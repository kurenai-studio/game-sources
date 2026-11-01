class_name TileValidator
extends RefCounted
## Validates the optional floor tiles of a level: `ice` (a list of cells) and `belts` (cells with a
## direction). Mirrors validateTiles in packages/level-contract/src/validate-tiles.ts.


static func check_all(issues: Array[Dictionary], root: Dictionary) -> void:
	var facts := PatrolValidator.board_facts(root)
	var ice_cells: Array[Vector2i] = []
	var ice: Variant = _list(
		issues, root, "ice", ContractLimits.ICE_MIN, ContractLimits.ICE_MAX, "ICE_WITH_BOARDS"
	)
	if ice != null:
		var entries: Array = ice
		for i in entries.size():
			var path := "ice[%d]" % i
			var pair: Variant = LevelValidator._check_pair(issues, entries[i], path, facts["size"])
			if pair == null:
				continue
			var at: Vector2i = pair
			if (facts["walls"] as Array).has(at):
				LevelValidator._add(issues, path, "ICE_ON_WALL", "%s must not be a wall." % path)
			if ice_cells.has(at):
				LevelValidator._add(
					issues, path, "ICE_CELLS_REPEAT", "%s repeats an earlier ice cell." % path
				)
			else:
				ice_cells.append(at)

	var belt_cells: Array[Vector2i] = []
	var belts: Variant = _list(
		issues,
		root,
		"belts",
		ContractLimits.BELTS_MIN,
		ContractLimits.BELTS_MAX,
		"BELTS_WITH_BOARDS"
	)
	if belts != null:
		var entries: Array = belts
		for i in entries.size():
			_check_belt(issues, entries[i], "belts[%d]" % i, facts, ice_cells, belt_cells)


## Checks the length of a list of tiles and that the level has no test boards. Returns the list
## or null.
static func _list(
	issues: Array[Dictionary],
	root: Dictionary,
	field: String,
	minimum: int,
	maximum: int,
	boards_code: String
) -> Variant:
	if not root.has(field):
		return null
	var raw: Variant = root[field]
	if typeof(raw) != TYPE_ARRAY:
		LevelValidator._add(issues, field, "INVALID_TYPE", "%s must be an array." % field)
		return null
	var entries: Array = raw
	if entries.size() < minimum or entries.size() > maximum:
		LevelValidator._add(
			issues,
			field,
			"LENGTH_OUT_OF_RANGE",
			"%s must have %d to %d entries, or be left out." % [field, minimum, maximum]
		)
	if root.has("extraBoards"):
		LevelValidator._add(
			issues, field, boards_code, "A level with test boards cannot have %s." % field
		)
	return entries


static func _check_belt(
	issues: Array[Dictionary],
	entry: Variant,
	path: String,
	facts: Dictionary,
	ice_cells: Array[Vector2i],
	belt_cells: Array[Vector2i]
) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		LevelValidator._add(issues, path, "INVALID_TYPE", "%s must be an object." % path)
		return
	var belt: Dictionary = entry
	LevelValidator._reject_unknown(issues, belt, path, ["cell", "direction"])
	LevelValidator._enum_field(issues, belt, path, "direction", ContractLimits.DIRECTIONS)
	var cell_path := "%s.cell" % path
	if not belt.has("cell"):
		LevelValidator._add(issues, cell_path, "REQUIRED", "%s is required." % cell_path)
		return
	var pair: Variant = LevelValidator._check_pair(issues, belt["cell"], cell_path, facts["size"])
	if pair == null:
		return
	var at: Vector2i = pair
	if (facts["walls"] as Array).has(at):
		LevelValidator._add(issues, cell_path, "BELT_ON_WALL", "%s must not be a wall." % cell_path)
	if ice_cells.has(at):
		LevelValidator._add(
			issues, cell_path, "BELT_ON_ICE", "%s must not be an ice cell." % cell_path
		)
	if belt_cells.has(at):
		LevelValidator._add(
			issues, cell_path, "BELT_CELLS_REPEAT", "%s repeats an earlier belt." % cell_path
		)
	else:
		belt_cells.append(at)
