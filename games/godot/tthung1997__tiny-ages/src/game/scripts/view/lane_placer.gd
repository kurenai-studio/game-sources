class_name LanePlacer
extends RefCounted
## Puts every piece the world shows in a space on its lane (issue #50), and remembers where, so a
## piece keeps its space and the buildings do not shuffle. Pure logic with no nodes.
##
## A piece goes in the free run of spaces nearest the hall that it is allowed in (`LaneSpaces`: its
## terrain, an age that has opened them, a crossing laid if they are across the river), or, when a
## piece replaces others (`SceneProps` `replaced_by`, the Granary on the Drying Rack's ground), in
## the spaces the old ones left. When no run is free the lowest-ranked piece already placed is
## hidden to make room (`LanePieces`: ranks 1 and 2 are never hidden, a better rank gives way to
## nobody, and within a rank the newest piece stays). Nothing is refused and nothing in the sim
## changes: the sim keeps what the view hides.
##
## The ledger is `WorldState.lane_spaces` (a key to its first space) and `lane_order` (the order
## keys were first shown, oldest first): saved with the world, never read by the sim. A world with
## none, an old save, is placed by the same rules from scratch, in the order its buildings were
## completed and then the table's, so the same world always looks the same.

const NONE: StringName = &""
## Wide enough to keep a rank apart from the next however many pieces a world has shown.
const RANK_WEIGHT: int = 100000

static var _replaces: Dictionary = {}


## Places what `world` shows, updates its ledger and returns where every piece stands.
static func place(world: WorldState) -> LaneLayout:
	var wanted: Array[StringName] = wanted_keys(world)
	for key: StringName in wanted:
		if not world.lane_order.has(key):
			world.lane_order.append(key)
	var ledger: Dictionary = {}
	for key: StringName in world.lane_spaces:
		ledger[key] = world.lane_spaces[key]
	var starts: Dictionary = pack(
		LanePieces.TABLE, wanted, ledger, world.lane_order, world.era_order,
		WorldLayout.crossing_open(world), replaces()
	)
	if not same_starts(starts, ledger):
		world.lane_spaces.clear()
		for key: StringName in starts:
			world.lane_spaces[key] = starts[key]
	var layout: LaneLayout = LaneLayout.new()
	layout.starts = starts
	return layout


## The keys of the pieces the world wants drawn in a space: completed buildings (and the one going
## up, whose site stands where the building will), then the props it shows, one key to a group of
## alternatives. Buildings come in the order they were started.
static func wanted_keys(world: WorldState) -> Array[StringName]:
	var found: Array[StringName] = []
	for building: BuildingState in world.buildings:
		var id: StringName = building.def_id
		if found.has(id) or not WorldLayout.BUILDINGS.has(id) or not LanePieces.TABLE.has(id):
			continue
		if not building.complete or WorldLayout.building_shown(id, world):
			found.append(id)
	for id: StringName in SceneProps.PROPS:
		if not LanePieces.has(id) or not SceneProps.is_shown(id, world):
			continue
		var key: StringName = LanePieces.key_of(id)
		if not found.has(key):
			found.append(key)
	return found


## For each key, the keys it takes the place of (a tidier piece, a granary where the rack stood),
## so it can stand where they did.
static func replaces() -> Dictionary:
	if not _replaces.is_empty():
		return _replaces
	for id: StringName in SceneProps.PROPS:
		var replaced: StringName = LanePieces.key_of(id)
		for replacer: StringName in SceneProps.replacements_of(SceneProps.PROPS[id]):
			_note_replaces(LanePieces.key_of(replacer), replaced)
	for old: StringName in WorldLayout.BUILDING_FOLDED_INTO:
		_note_replaces(WorldLayout.BUILDING_FOLDED_INTO[old], old)
	return _replaces


static func _note_replaces(replacer: StringName, replaced: StringName) -> void:
	var list: Array = _replaces.get(replacer, [])
	if not list.has(replaced):
		list.append(replaced)
	_replaces[replacer] = list


static func same_starts(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size():
		return false
	for key: StringName in a:
		if not b.has(key) or int(b[key]) != int(a[key]):
			return false
	return true


## The core: `wanted` keys of `table` (key to [lane, spaces, terrain, rank]) placed given what the
## `ledger` already holds, in an age and with or without a crossing. `order` is the keys oldest
## first. `replaces` says which keys a key stands in for. Returns key to first space.
static func pack(
	table: Dictionary, wanted: Array[StringName], ledger: Dictionary, order: Array[StringName],
	era_order: int, crossed: bool, replaces_of: Dictionary = {}
) -> Dictionary:
	var ranked: Array[StringName] = wanted.duplicate()
	ranked.sort_custom(func(a: StringName, b: StringName) -> bool:
		return _priority(table, order, a) < _priority(table, order, b)
	)
	var run: Dictionary = {
		"table": table, "order": order, "era": era_order, "crossed": crossed,
		"cells": {}, "starts": {}, "ranked": ranked,
	}
	for lane: StringName in LaneSpaces.LANES:
		var cells: Array[StringName] = []
		cells.resize(LaneSpaces.count(lane))
		cells.fill(NONE)
		run["cells"][lane] = cells
	for lane: StringName in LaneSpaces.LANES:
		# The building lane first: the prop lane is then placed between what stands on it.
		for key: StringName in ranked:
			if _lane(table, key) == lane and ledger.has(key) and _is_free(run, key, int(ledger[key])):
				_put(run, key, int(ledger[key]))
		for key: StringName in ranked:
			if _lane(table, key) != lane or (run["starts"] as Dictionary).has(key):
				continue
			var start: int = _free_start(run, key, _wishes(run, key, ledger, replaces_of))
			if start < 0:
				start = _evict_for(run, key)
			if start < 0 and _rank(table, key) <= 2:
				_repack(run, lane)
				var no_wishes: Array[int] = []
				start = _free_start(run, key, no_wishes)
			if start >= 0:
				_put(run, key, start)
	return run["starts"]


## Lower is more important: rank first, then the newest piece.
static func _priority(table: Dictionary, order: Array[StringName], key: StringName) -> int:
	return _rank(table, key) * RANK_WEIGHT - order.find(key)


static func _lane(table: Dictionary, key: StringName) -> StringName:
	return table[key][0]


static func _spaces(table: Dictionary, key: StringName) -> int:
	return int(table[key][1])


static func _terrain(table: Dictionary, key: StringName) -> StringName:
	return table[key][2]


static func _rank(table: Dictionary, key: StringName) -> int:
	return int(table[key][3])


## Whether a key's spaces from `start` are open to it and nobody's.
static func _is_free(run: Dictionary, key: StringName, start: int) -> bool:
	var table: Dictionary = run["table"]
	var lane: StringName = _lane(table, key)
	var spaces: int = _spaces(table, key)
	if not LaneSpaces.span_open(
		lane, start, spaces, _terrain(table, key), run["era"], run["crossed"]
	):
		return false
	var cells: Array = run["cells"][lane]
	for at: int in range(start, start + spaces):
		if cells[at] != NONE or _is_inside_building(run, lane, at):
			return false
	return true


## Whether a prop space lies inside a building that spans it, which would put the prop right in
## front of that building. A prop space is centred on the join between building space `index - 1`
## and `index`: inside one building when the same building stands on both.
static func _is_inside_building(run: Dictionary, lane: StringName, index: int) -> bool:
	if lane != LaneSpaces.MID:
		return false
	var back: Array = run["cells"][LaneSpaces.BACK]
	return index > 0 and index < back.size() and back[index] != NONE and back[index - 1] == back[index]


static func _put(run: Dictionary, key: StringName, start: int) -> void:
	var table: Dictionary = run["table"]
	var cells: Array = run["cells"][_lane(table, key)]
	for at: int in range(start, start + _spaces(table, key)):
		cells[at] = key
	(run["starts"] as Dictionary)[key] = start


static func _remove(run: Dictionary, key: StringName) -> void:
	var table: Dictionary = run["table"]
	var cells: Array = run["cells"][_lane(table, key)]
	var start: int = (run["starts"] as Dictionary)[key]
	for at: int in range(start, start + _spaces(table, key)):
		cells[at] = NONE
	(run["starts"] as Dictionary).erase(key)


## Where the keys this one replaces stood, in the same lane: it takes their place if it fits.
static func _wishes(
	run: Dictionary, key: StringName, ledger: Dictionary, replaces_of: Dictionary
) -> Array[int]:
	var table: Dictionary = run["table"]
	var wishes: Array[int] = []
	for old: StringName in replaces_of.get(key, []):
		if ledger.has(old) and table.has(old) and _lane(table, old) == _lane(table, key):
			wishes.append(int(ledger[old]))
	return wishes


## The free run nearest a wish (a replaced piece's first space), or else nearest the hall.
static func _free_start(run: Dictionary, key: StringName, wishes: Array[int]) -> int:
	var table: Dictionary = run["table"]
	var spaces: int = _spaces(table, key)
	for wish: int in wishes:
		for start: int in range(wish, wish - spaces, -1):
			if _is_free(run, key, start):
				return start
	for start: int in LaneSpaces.starts_by_distance(_lane(table, key), spaces):
		if _is_free(run, key, start):
			return start
	return -1


## Hides the lowest-ranked pieces that stand where `key` is allowed to go, if every one of them
## ranks below it and none is a need (ranks 1 and 2 are never hidden), and puts `key` there. Of the
## places it could go it picks the one whose most important victim matters least, then the fewest
## victims, then the nearest the hall. -1 if there is none (so a piece never takes a place from one
## that outranks it).
static func _evict_for(run: Dictionary, key: StringName) -> int:
	var table: Dictionary = run["table"]
	var order: Array[StringName] = run["order"]
	var lane: StringName = _lane(table, key)
	var spaces: int = _spaces(table, key)
	var cells: Array = run["cells"][lane]
	var mine: int = _priority(table, order, key)
	var best: int = -1
	var best_worst: int = -1
	var best_count: int = 0
	var best_distance: float = 0.0
	for start: int in LaneSpaces.starts_by_distance(lane, spaces):
		if not LaneSpaces.span_open(
			lane, start, spaces, _terrain(table, key), run["era"], run["crossed"]
		):
			continue
		var victims: Dictionary = {}
		var worst: int = 1 << 60
		var allowed: bool = true
		for at: int in range(start, start + spaces):
			if _is_inside_building(run, lane, at):
				allowed = false
				break
			var occupant: StringName = cells[at]
			if occupant == NONE or victims.has(occupant):
				continue
			var theirs: int = _priority(table, order, occupant)
			if theirs <= mine or _rank(table, occupant) <= 2:
				allowed = false
				break
			victims[occupant] = true
			worst = mini(worst, theirs)
		if not allowed or victims.is_empty():
			continue
		var distance: float = LaneSpaces.hall_distance(lane, start, spaces)
		var better: bool = best < 0 or worst > best_worst
		if not better and worst == best_worst:
			better = victims.size() < best_count \
					or (victims.size() == best_count and distance < best_distance - 0.001)
		if better:
			best = start
			best_worst = worst
			best_count = victims.size()
			best_distance = distance
	if best < 0:
		return -1
	for at: int in range(best, best + spaces):
		if cells[at] != NONE:
			_remove(run, cells[at])
	return best


## A last resort for a piece that must show: every piece of the lane is placed again, the needs
## first and the biggest of them first (so the long runs are not cut up), then the rest best first.
## It can only move pieces when the lane is too fragmented for a run.
static func _repack(run: Dictionary, lane: StringName) -> void:
	var table: Dictionary = run["table"]
	var no_wishes: Array[int] = []
	for key: StringName in (run["starts"] as Dictionary).keys():
		if _lane(table, key) == lane:
			_remove(run, key)
	var needs: Array[StringName] = []
	var rest: Array[StringName] = []
	for key: StringName in run["ranked"]:
		if _lane(table, key) != lane:
			continue
		if _rank(table, key) <= 2:
			needs.append(key)
		else:
			rest.append(key)
	var order: Array[StringName] = run["order"]
	needs.sort_custom(func(a: StringName, b: StringName) -> bool:
		if _spaces(table, a) != _spaces(table, b):
			return _spaces(table, a) > _spaces(table, b)
		return _priority(table, order, a) < _priority(table, order, b)
	)
	for key: StringName in needs + rest:
		var start: int = _free_start(run, key, no_wishes)
		if start >= 0:
			_put(run, key, start)
