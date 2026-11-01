# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RunSegments
extends RefCounted
## Checks index.json and the segment files (docs/ARCHITECTURE.md 2.9). Internal to
## src/run/: RunData calls it. A segment is read into a plain Dictionary:
## {"id": StringName, "kind": StringName, "grid": PackedStringArray, "top_ports": Array[int],
## "bottom_ports": Array[int], "spots": int, "sockets": int, "tier": int}. A segment's tier is
## the highest tier among the map feature characters in its grid (RULES 14.9).

const KINDS: PackedStringArray = ["top", "middle", "bottom"]
const INDEX_MAX: int = 256
## Road cells: the plain ones and the map features (docs/ARCHITECTURE.md 14.2).
const ROAD_CHARS: String = "#G1234BTX^v<>PQ"


## The ids listed in index.json, or [] with problems. Missing is reported by the caller.
static func read_index(data: Variant, problems: PackedStringArray) -> Array[StringName]:
	var ids: Array[StringName] = []
	var chk: DataCheck = DataCheck.new("index.json")
	if chk.object(data, "", ["format", "segments"]):
		var top: Dictionary = data
		chk.integer(top, "format", "", 1, 1)
		var list: Array = chk.array(top, "segments", "", 1, INDEX_MAX)
		for i: int in list.size():
			var id: StringName = chk.ident_value(list[i], "segments[%d]" % i)
			if id == &"":
				continue
			if ids.has(id):
				chk.fail("segments[%d]" % i, "repeats %s" % id)
				continue
			ids.append(id)
	problems.append_array(chk.problems)
	return ids


## One segment. rows: the heights run.json sets, {"top": int, "middle": int, "bottom": int},
## or {} when run.json is unusable. feature_tiers: a feature character to its tier, from run.json's
## tiers (a character not in it is tier 0). Returns {} when the segment has a problem.
static func read_segment(data: Variant, listed_id: StringName, rows: Dictionary, problems: PackedStringArray, feature_tiers: Dictionary = {}) -> Dictionary:
	var chk: DataCheck = DataCheck.new("%s.json" % listed_id)
	var segment: Dictionary = _read(data, listed_id, rows, feature_tiers, chk)
	problems.append_array(chk.problems)
	if not chk.ok():
		return {}
	return segment


## True when `lower` fits under `upper`: its top ports equal the upper one's bottom ports.
static func fits(upper: Dictionary, lower: Dictionary) -> bool:
	var upper_ports: Array[int] = upper["bottom_ports"]
	var lower_ports: Array[int] = lower["top_ports"]
	return upper_ports == lower_ports


## Coverage (2.9): at least one segment of each kind, a middle under every top, and a
## bottom under every middle that fits under some top.
static func check_coverage(segments: Array[Dictionary], problems: PackedStringArray) -> void:
	var tops: Array[Dictionary] = []
	var middles: Array[Dictionary] = []
	var bottoms: Array[Dictionary] = []
	for segment: Dictionary in segments:
		match String(segment["kind"]):
			"top":
				tops.append(segment)
			"middle":
				middles.append(segment)
			"bottom":
				bottoms.append(segment)
	if tops.is_empty() or middles.is_empty() or bottoms.is_empty():
		problems.append("segments: need at least one top, one middle and one bottom segment")
		return
	var reachable: Array[StringName] = []
	for top: Dictionary in tops:
		var any: bool = false
		for middle: Dictionary in middles:
			if fits(top, middle):
				any = true
				if not reachable.has(middle["id"]):
					reachable.append(middle["id"])
		if not any:
			problems.append("%s.json: no middle segment fits under this top segment" % top["id"])
	for middle: Dictionary in middles:
		if not reachable.has(middle["id"]):
			continue
		var any_bottom: bool = false
		for bottom: Dictionary in bottoms:
			if fits(middle, bottom):
				any_bottom = true
				break
		if not any_bottom:
			problems.append("%s.json: no bottom segment fits under this middle segment" % middle["id"])


## The highest tier among the feature characters in a grid; 0 when it holds none.
static func tier_of(grid: PackedStringArray, feature_tiers: Dictionary) -> int:
	var best: int = 0
	for line: String in grid:
		for ch: String in line:
			best = maxi(best, int(feature_tiers.get(ch, 0)))
	return best


static func _read(data: Variant, listed_id: StringName, rows: Dictionary, feature_tiers: Dictionary, chk: DataCheck) -> Dictionary:
	var segment: Dictionary = {}
	if not chk.object(data, "", ["format", "id", "kind", "grid"]):
		return segment
	var top: Dictionary = data
	chk.integer(top, "format", "", 1, 1)
	var id: StringName = chk.ident(top, "id", "")
	if id != &"" and id != listed_id:
		chk.fail("id", "must equal the file name")
	var kind: String = ""
	if not DataCheck.is_string(top.get("kind", null)) or not KINDS.has(String(top["kind"])):
		chk.fail("kind", "must be top, middle or bottom")
	else:
		kind = String(top["kind"])
	var wanted: int = 0
	if not kind.is_empty() and rows.has(kind):
		wanted = int(rows[kind])
	var lines: Array = chk.array(top, "grid", "", wanted if wanted > 0 else 1, wanted if wanted > 0 else 11)
	if kind.is_empty() or lines.is_empty():
		return segment
	var grid: PackedStringArray = PackedStringArray()
	for r: int in lines.size():
		var line: Variant = lines[r]
		if typeof(line) != TYPE_STRING or (line as String).length() != Sim.MAP_COLUMNS:
			chk.fail("grid[%d]" % r, "must be a string of %d characters" % Sim.MAP_COLUMNS)
			return segment
		for c: int in Sim.MAP_COLUMNS:
			if LevelData.GRID_CHARS.find((line as String)[c]) < 0:
				chk.fail("grid[%d]" % r, "has an unknown character")
				return segment
		grid.append(line)
	_check_shape(grid, kind, rows, chk)
	var top_ports: Array[int] = _road_columns(grid[0])
	var bottom_ports: Array[int] = _road_columns(grid[grid.size() - 1])
	if kind != "top":
		_check_ports(top_ports, "top row", chk)
	if kind != "bottom":
		_check_ports(bottom_ports, "bottom row", chk)
	var spots: int = 0
	var sockets: int = 0
	for line: String in grid:
		spots += line.count("o")
		sockets += line.count("G")
	var no_ports: Array[int] = []
	return {
		"id": listed_id, "kind": StringName(kind), "grid": grid,
		"top_ports": top_ports if kind != "top" else no_ports,
		"bottom_ports": bottom_ports if kind != "bottom" else no_ports,
		"spots": spots, "sockets": sockets, "tier": tier_of(grid, feature_tiers),
	}


## Entrances, base, the scenery row and 2 x 2 road blocks.
static func _check_shape(grid: PackedStringArray, kind: String, rows: Dictionary, chk: DataCheck) -> void:
	var entrances: Array[String] = []
	var bases: int = 0
	for r: int in grid.size():
		for c: int in Sim.MAP_COLUMNS:
			var ch: String = grid[r][c]
			if ch == "B":
				bases += 1
			elif ch >= "1" and ch <= "4":
				entrances.append(ch)
				var edge: bool = r == 0 or c == 0 or c == Sim.MAP_COLUMNS - 1
				if kind == "top" and not edge:
					chk.fail("grid[%d]" % r, "entrance %s must be on the top row or column 0 or 6" % ch)
			if r + 1 < grid.size() and c + 1 < Sim.MAP_COLUMNS and _is_road(grid[r][c]) \
					and _is_road(grid[r][c + 1]) and _is_road(grid[r + 1][c]) and _is_road(grid[r + 1][c + 1]):
				chk.fail("grid", "roads must be one tile wide (a 2 x 2 block at [%d, %d])" % [c, r])
	if kind == "top":
		entrances.sort()
		var joined: String = "".join(entrances)
		if joined != "1" and joined != "12":
			chk.fail("grid", "a top segment holds entrance 1, or entrances 1 and 2")
	elif not entrances.is_empty():
		chk.fail("grid", "only a top segment holds entrances")
	if kind == "bottom":
		if bases != 1:
			chk.fail("grid", "a bottom segment holds exactly one base")
	elif bases != 0:
		chk.fail("grid", "only a bottom segment holds the base")
	if kind == "bottom" and _rows_total(rows) == 13:
		var last: String = grid[grid.size() - 1]
		if last != ".".repeat(Sim.MAP_COLUMNS):
			chk.fail("grid[%d]" % (grid.size() - 1), "the last row of a bottom segment must be all scenery")


static func _rows_total(rows: Dictionary) -> int:
	if rows.is_empty():
		return 0
	return int(rows["top"]) + int(rows["middle"]) + int(rows["bottom"])


static func _is_road(ch: String) -> bool:
	return ROAD_CHARS.contains(ch)


static func _road_columns(line: String) -> Array[int]:
	var out: Array[int] = []
	for c: int in Sim.MAP_COLUMNS:
		if _is_road(line[c]):
			out.append(c)
	return out


## A port row holds at least one road cell and no two side by side.
static func _check_ports(ports: Array[int], where: String, chk: DataCheck) -> void:
	if ports.is_empty():
		chk.fail("grid", "the %s needs at least one road cell" % where)
		return
	for i: int in range(1, ports.size()):
		if ports[i] == ports[i - 1] + 1:
			chk.fail("grid", "the %s holds two road cells side by side" % where)
			return
