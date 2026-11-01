# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name LevelData
extends RefCounted
## One checked level or assembled run map (docs/ARCHITECTURE.md 2.3, 2.4). Read only.

enum Kind { SCENERY, ROAD, SOCKET, SPOT, ENTRANCE, BASE }
## Map features (docs/ARCHITECTURE.md 14.2, RULES 3.5 to 3.9). Each is a road tile.
enum Feature { NONE, TUNNEL, BRIDGE, SLIDE, STUMP }
const FORMAT: int = 1
const GRID_CHARS: String = ".#Go1234BTX^v<>PQ"
## The characters kind_at() gives ROAD, SOCKET, ENTRANCE or BASE for.
const ROAD_CHARS: String = "#G1234BTX^v<>PQ"
const MAX_TOWER_KINDS: int = 10
const MAX_SPOTS: int = 24
const MAX_SOCKETS: int = 8
const MAX_WAVES: int = 40
const MAX_GROUPS: int = 8
const SPAWN_BOUND: int = 120
const STAR3_FIELDS: Dictionary = {
	"no_lives_lost": [], "towers_at_most": ["value"], "tower_ban": ["tower"],
	"gates_at_most": ["value"], "tier_at_most": ["value"], "early_calls_at_least": ["value"],
	"kinds_at_most": ["value"], "gates_whole": [],
}
const REQUIRED: PackedStringArray = [
	"format", "id", "name", "grid", "start_gold", "gates", "strength", "towers", "star3", "waves",
]
const OPTIONAL: PackedStringArray = ["hint", "twist"]

var id: StringName = &""
var name: String = ""
var grid: PackedStringArray = PackedStringArray()
var rows: int = 0
var entrances: Array[Vector2i] = []
var base: Vector2i = Vector2i(-1, -1)
var sockets: Array[Vector2i] = []
var spots: Array[Vector2i] = []
var start_gold: int = 0
var gates: int = 0
var strength: int = 100
var towers: Array[StringName] = []
var star3: Dictionary = {"kind": &"no_lives_lost", "value": 0, "tower": &""}
var hint_text: String = ""
var hint_cell: Vector2i = Vector2i(-1, -1)
var hint_button: StringName = &""
var waves: Array[WaveData] = []
var twist_name: String = ""
var twist_text: String = ""
var twist_effects: Array[Dictionary] = []


static func check(data: Variant, catalog: Catalog) -> PackedStringArray:
	var built: Array = _build(data, catalog)
	return built[1]


## Null when check() finds anything.
static func from_data(data: Variant, catalog: Catalog) -> LevelData:
	var built: Array = _build(data, catalog)
	var problems: PackedStringArray = built[1]
	if not problems.is_empty():
		return null
	return built[0]


## The file shape. from_data(to_data()) gives an equal level.
func to_data() -> Dictionary:
	var grid_out: Array = []
	for line: String in grid:
		grid_out.append(line)
	var tower_out: Array = []
	for tower_id: StringName in towers:
		tower_out.append(String(tower_id))
	var star_out: Dictionary = {"kind": String(star3["kind"])}
	var fields: Array = STAR3_FIELDS[String(star3["kind"])]
	if fields.has("value"):
		star_out["value"] = star3["value"]
	if fields.has("tower"):
		star_out["tower"] = String(star3["tower"])
	var wave_out: Array = []
	for wave: WaveData in waves:
		var group_out: Array = []
		for group: WaveGroup in wave.groups:
			group_out.append({
				"enemy": String(group.enemy), "count": group.count, "entrance": group.entrance + 1,
				"at_ms": group.at_tick * Sim.MS_PER_TICK, "every_ms": group.every_ticks * Sim.MS_PER_TICK,
			})
		wave_out.append({"strength": wave.strength, "groups": group_out})
	var out: Dictionary = {
		"format": FORMAT, "id": String(id), "name": name, "grid": grid_out,
		"start_gold": start_gold, "gates": gates, "strength": strength, "towers": tower_out,
		"star3": star_out, "waves": wave_out,
	}
	if not hint_text.is_empty():
		var hint: Dictionary = {"text": hint_text}
		if hint_cell != Vector2i(-1, -1):
			hint["cell"] = DataCheck.cell_data(hint_cell)
		if hint_button != &"":
			hint["button"] = String(hint_button)
		out["hint"] = hint
	if not twist_name.is_empty():
		out["twist"] = {"name": twist_name, "text": twist_text, "effects": twist_effects.duplicate(true)}
	return out


## SCENERY outside the map.
func kind_at(cell: Vector2i) -> Kind:
	if cell.x < 0 or cell.x >= Sim.MAP_COLUMNS or cell.y < 0 or cell.y >= rows:
		return Kind.SCENERY
	match grid[cell.y].unicode_at(cell.x):
		35:  # "#"
			return Kind.ROAD
		71:  # "G"
			return Kind.SOCKET
		111:  # "o"
			return Kind.SPOT
		66:  # "B"
			return Kind.BASE
		49, 50, 51, 52:  # "1" to "4"
			return Kind.ENTRANCE
		84, 88, 94, 118, 60, 62, 80, 81:  # the features: "T", "X", "^", "v", "<", ">", "P", "Q"
			return Kind.ROAD
	return Kind.SCENERY


## NONE outside the map and on every character of contract 2.3.
func feature_at(cell: Vector2i) -> Feature:
	if cell.x < 0 or cell.x >= Sim.MAP_COLUMNS or cell.y < 0 or cell.y >= rows:
		return Feature.NONE
	match grid[cell.y].unicode_at(cell.x):
		84:  # "T"
			return Feature.TUNNEL
		88:  # "X"
			return Feature.BRIDGE
		94, 118, 60, 62:  # "^", "v", "<", ">"
			return Feature.SLIDE
		80, 81:  # "P", "Q"
			return Feature.STUMP
	return Feature.NONE


## A slide's way out: ^ (0, -1), v (0, 1), < (-1, 0), > (1, 0); (0, 0) on any other cell.
func slide_dir(cell: Vector2i) -> Vector2i:
	if cell.x < 0 or cell.x >= Sim.MAP_COLUMNS or cell.y < 0 or cell.y >= rows:
		return Vector2i.ZERO
	match grid[cell.y].unicode_at(cell.x):
		94:  # "^"
			return Vector2i(0, -1)
		118:  # "v"
			return Vector2i(0, 1)
		60:  # "<"
			return Vector2i(-1, 0)
		62:  # ">"
			return Vector2i(1, 0)
	return Vector2i.ZERO


func is_road(cell: Vector2i) -> bool:
	var kind: Kind = kind_at(cell)
	return kind == Kind.ROAD or kind == Kind.SOCKET or kind == Kind.ENTRANCE or kind == Kind.BASE


## [LevelData, PackedStringArray of problems].
static func _build(data: Variant, catalog: Catalog) -> Array:
	var level: LevelData = new()
	var chk: DataCheck = DataCheck.new("level")
	if typeof(data) == TYPE_DICTIONARY and DataCheck.is_id((data as Dictionary).get("id", null)):
		chk.file = String((data as Dictionary)["id"]) + ".json"
	if catalog == null or catalog.rules == null:
		chk.fail("", "needs a valid catalog")
		return [level, chk.problems]
	level._read(data, catalog, chk)
	return [level, chk.problems]


func _read(data: Variant, catalog: Catalog, chk: DataCheck) -> void:
	if not chk.object(data, "", REQUIRED, OPTIONAL):
		return
	var top: Dictionary = data
	chk.integer(top, "format", "", FORMAT, FORMAT)
	id = chk.ident(top, "id", "")
	name = chk.text(top, "name", "", 24)
	var grid_ok: bool = _read_grid(chk.array(top, "grid", "", Sim.MAP_ROWS_MIN, Sim.MAP_ROWS_MAX), chk)
	start_gold = chk.integer(top, "start_gold", "", 0, 100000)
	gates = chk.integer(top, "gates", "", 0, mini(3, catalog.rules.max_gates))
	if gates > sockets.size():
		chk.fail("gates", "must be at most the socket count")
	strength = chk.integer(top, "strength", "", 50, 1000, 1, 100)
	var tower_list: Array = chk.array(top, "towers", "", 1, MAX_TOWER_KINDS)
	for i: int in tower_list.size():
		var tower_id: StringName = chk.ident_value(tower_list[i], "towers[%d]" % i)
		if tower_id == &"":
			continue
		if not catalog.has_tower(tower_id):
			chk.fail("towers[%d]" % i, "names no tower")
		elif towers.has(tower_id):
			chk.fail("towers[%d]" % i, "repeats %s" % tower_id)
		else:
			towers.append(tower_id)
	_read_star3(top.get("star3", null), catalog, chk)
	if top.has("hint"):
		_read_hint(top["hint"], grid_ok, chk)
	var wave_list: Array = chk.array(top, "waves", "", 1, MAX_WAVES)
	for w: int in wave_list.size():
		waves.append(_read_wave(wave_list[w], "waves[%d]" % w, catalog, chk))
	if top.has("twist"):
		_read_twist(top["twist"], grid_ok, catalog, chk)
	if grid_ok:
		var road: RoadMap = RoadMap.new(self)
		if road.seals([]):
			chk.fail("grid", "every entrance must reach the base with no gates")
		var fixed: Array[Vector2i] = Modifiers.fixed_cells(twist_effects)
		if not fixed.is_empty() and road.seals(fixed):
			chk.fail("twist", "every entrance must reach the base with the fixed gates closed")
	_check_spawn_bound(catalog, chk)


func _read_grid(lines: Array, chk: DataCheck) -> bool:
	if lines.is_empty():
		return false
	var good: bool = true
	for r: int in lines.size():
		var line: Variant = lines[r]
		if typeof(line) != TYPE_STRING or (line as String).length() != Sim.MAP_COLUMNS:
			chk.fail("grid[%d]" % r, "must be a string of %d characters" % Sim.MAP_COLUMNS)
			good = false
			continue
		for c: int in Sim.MAP_COLUMNS:
			if GRID_CHARS.find((line as String)[c]) < 0:
				chk.fail("grid[%d]" % r, "has an unknown character")
				good = false
				break
		grid.append(line)
	if not good:
		grid = PackedStringArray()
		return false
	rows = grid.size()
	var by_number: Dictionary[int, Vector2i] = {}
	var bases: int = 0
	var stumps: Dictionary[String, Array] = {"P": [], "Q": []}
	for r: int in rows:
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			var ch: int = grid[r].unicode_at(c)
			if feature_at(cell) == Feature.STUMP:
				stumps[grid[r][c]].append(cell)
			match kind_at(cell):
				Kind.SOCKET:
					sockets.append(cell)
				Kind.SPOT:
					spots.append(cell)
				Kind.BASE:
					bases += 1
					base = cell
				Kind.ENTRANCE:
					var number: int = ch - 48
					if by_number.has(number):
						chk.fail("grid", "entrance %d appears twice" % number)
						good = false
					by_number[number] = cell
					if c != 0 and c != Sim.MAP_COLUMNS - 1 and r != 0 and r != rows - 1:
						chk.fail("grid", "entrance %d must be on the map edge" % number)
						good = false
			if r + 1 < rows and c + 1 < Sim.MAP_COLUMNS and is_road(cell) and is_road(cell + Vector2i(1, 0)) \
					and is_road(cell + Vector2i(0, 1)) and is_road(cell + Vector2i(1, 1)):
				chk.fail("grid", "roads must be one tile wide (a 2 x 2 block at [%d, %d])" % [c, r])
				good = false
	if bases != 1:
		chk.fail("grid", "must hold exactly one base")
		good = false
	# 14.2: twin stumps. A step between neighbors is always a walk, so twins never touch.
	for letter: String in stumps:
		var pair: Array = stumps[letter]
		if pair.size() != 0 and pair.size() != 2:
			chk.fail("grid", "%s must appear exactly twice or not at all" % letter)
			good = false
		elif pair.size() == 2:
			var gap: Vector2i = (pair[1] as Vector2i) - (pair[0] as Vector2i)
			if absi(gap.x) + absi(gap.y) == 1:
				chk.fail("grid", "the two %s stumps must not be neighbors" % letter)
				good = false
	if by_number.is_empty():
		chk.fail("grid", "must hold 1 to 4 entrances")
		good = false
	for number: int in range(1, by_number.size() + 1):
		if not by_number.has(number):
			chk.fail("grid", "entrances must be numbered from 1 with no gaps")
			good = false
			break
		entrances.append(by_number[number])
	if spots.size() > MAX_SPOTS:
		chk.fail("grid", "holds more than %d build spots" % MAX_SPOTS)
		good = false
	if sockets.size() > MAX_SOCKETS:
		chk.fail("grid", "holds more than %d gate sockets" % MAX_SOCKETS)
		good = false
	return good


func _read_star3(data: Variant, catalog: Catalog, chk: DataCheck) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		chk.fail("star3", "must be an object")
		return
	var kind_value: Variant = (data as Dictionary).get("kind", null)
	if not DataCheck.is_string(kind_value) or not STAR3_FIELDS.has(String(kind_value)):
		chk.fail("star3.kind", "must be a known star 3 kind")
		return
	var kind: String = String(kind_value)
	var fields: PackedStringArray = ["kind"]
	for field: String in STAR3_FIELDS[kind]:
		fields.append(field)
	chk.object(data, "star3", fields)
	var star: Dictionary = data
	var value: int = 0
	match kind:
		"gates_at_most":
			value = chk.integer(star, "value", "star3", 0, 3)
		"tier_at_most":
			value = chk.integer(star, "value", "star3", 1, 2, 1, 1)
		"towers_at_most", "early_calls_at_least", "kinds_at_most":
			value = chk.integer(star, "value", "star3", 0, 100)
	var tower_id: StringName = &""
	if kind == "tower_ban":
		tower_id = chk.ident(star, "tower", "star3")
		if tower_id != &"" and not catalog.has_tower(tower_id):
			chk.fail("star3.tower", "names no tower")
	star3 = {"kind": StringName(kind), "value": value, "tower": tower_id}


func _read_hint(data: Variant, grid_ok: bool, chk: DataCheck) -> void:
	if not chk.object(data, "hint", ["text"], ["cell", "button"]):
		return
	var hint: Dictionary = data
	hint_text = chk.text(hint, "text", "hint", 80)
	if hint.has("cell") and hint.has("button"):
		chk.fail("hint", "holds at most one of cell or button")
	if hint.has("cell") and grid_ok:
		hint_cell = chk.cell(hint["cell"], "hint.cell", rows)
	if hint.has("button"):
		var button: Variant = hint["button"]
		if not DataCheck.is_string(button) or String(button) != "call":
			chk.fail("hint.button", "must be call")
		else:
			hint_button = &"call"


func _read_wave(data: Variant, path: String, catalog: Catalog, chk: DataCheck) -> WaveData:
	var wave: WaveData = WaveData.new()
	wave.strength = strength
	if not chk.object(data, path, ["groups"], ["strength"]):
		return wave
	var item: Dictionary = data
	wave.strength = chk.integer(item, "strength", path, 50, 1000, 1, strength)
	var group_list: Array = chk.array(item, "groups", path, 1, MAX_GROUPS)
	for g: int in group_list.size():
		var group_path: String = "%s.groups[%d]" % [path, g]
		if not chk.object(group_list[g], group_path, ["enemy", "count", "entrance", "at_ms", "every_ms"]):
			continue
		var raw: Dictionary = group_list[g]
		var group: WaveGroup = WaveGroup.new()
		group.enemy = chk.ident(raw, "enemy", group_path)
		if group.enemy != &"" and not catalog.has_enemy(group.enemy):
			chk.fail(DataCheck.join(group_path, "enemy"), "names no creature")
		group.count = chk.integer(raw, "count", group_path, 1, 200, 1, 1)
		group.entrance = chk.integer(raw, "entrance", group_path, 1, maxi(1, entrances.size()), 1, 1) - 1
		group.at_tick = chk.integer(raw, "at_ms", group_path, 0, 600000, 50) / Sim.MS_PER_TICK
		group.every_ticks = chk.integer(raw, "every_ms", group_path, 50, 60000, 50, 50) / Sim.MS_PER_TICK
		wave.groups.append(group)
	return wave


func _read_twist(data: Variant, grid_ok: bool, catalog: Catalog, chk: DataCheck) -> void:
	if not chk.object(data, "twist", ["name", "text", "effects"]):
		return
	var twist: Dictionary = data
	twist_name = chk.text(twist, "name", "twist", 24)
	twist_text = chk.text(twist, "text", "twist", 80)
	var effects: Variant = twist.get("effects", null)
	var effect_problems: PackedStringArray = Modifiers.check(effects, catalog, &"twist")
	for line: String in effect_problems:
		chk.fail("twist", line)
	if not effect_problems.is_empty():
		return
	var list: Array = effects
	if list.size() < 1 or list.size() > 2:
		chk.fail("twist.effects", "must hold 1 or 2 effects")
		return
	twist_effects = Modifiers.normalize_all(list)
	if not grid_ok:
		return
	var given: int = gates
	for effect: Dictionary in twist_effects:
		if effect["type"] == "set_gates":
			given = effect["count"]
	var fixed: Array[Vector2i] = Modifiers.fixed_cells(twist_effects)
	for cell: Vector2i in fixed:
		if not sockets.has(cell):
			chk.fail("twist", "fixed gate at [%d, %d] is not a socket" % [cell.x, cell.y])
	if fixed.size() > given:
		chk.fail("twist", "has more fixed gates than the level gives")


## One wave, with the Twist applied, spawns at most 120 creatures, counting
## split_count for each splitter (docs/ARCHITECTURE.md 2.4).
func _check_spawn_bound(catalog: Catalog, chk: DataCheck) -> void:
	for w: int in waves.size():
		var total: int = 0
		for group: WaveGroup in waves[w].groups:
			var type: EnemyType = catalog.enemy(group.enemy)
			if type == null:
				continue
			var count: int = Modifiers.group_count(twist_effects, group.count, type.flying, w == waves.size() - 1)
			total += count * (1 + type.split_count)
		if total > SPAWN_BOUND:
			chk.fail("waves[%d]" % w, "spawns %d creatures; at most %d" % [total, SPAWN_BOUND])
