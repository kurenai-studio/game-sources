# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name GameData
extends RefCounted
## Every bundled data file, read through JsonFile and checked (docs/ARCHITECTURE.md 2.5, 2.12).
## A problem in a bundled file is a build bug: the App shows the damaged message.

const FORMAT: int = 1
const STATS_CAP: int = 262144
const LEVEL_CAP: int = 65536
const CAMPAIGN_CAP: int = 16384
const CAMPAIGN_FILE: String = "campaign.json"
## Most levels in one region. RULES 12 plans 6.
const REGION_LEVELS_MAX: int = 24
# The run files (2.9 to 2.12), by their path under data/, as RunData.check takes them.
const RUN_FILE: String = "runs/run.json"
const CARDS_FILE: String = "cards/cards.json"
const INDEX_FILE: String = "segments/index.json"
const PACKS_FILE: String = "segments/packs.json"
const SEGMENT_DIR: String = "segments"
const RUN_CAP: int = 16384
const CARDS_CAP: int = 262144
const INDEX_CAP: int = 16384
const PACKS_CAP: int = 262144
const SEGMENT_CAP: int = 16384
## Most segments index.json may list (2.9). A longer list is read no further.
const SEGMENTS_MAX: int = 256

var problems: PackedStringArray = PackedStringArray()   # empty when every file is valid
var catalog: Catalog = null
var campaign: Array[Dictionary] = []                    # [{"id": StringName, "name": String, "levels": Array[StringName]}]
var levels: Dictionary[StringName, LevelData] = {}
var run: RunData = null                                 # null until every run file is valid


static func load_from(root: String = "res://data") -> GameData:
	var game: GameData = new()
	game._load(root)
	return game


func _load(root: String) -> void:
	var stats_dir: String = root.path_join("stats")
	var towers: Variant = _read(stats_dir.path_join("towers.json"), "towers.json", STATS_CAP)
	var enemies: Variant = _read(stats_dir.path_join("enemies.json"), "enemies.json", STATS_CAP)
	var rules: Variant = _read(stats_dir.path_join("rules.json"), "rules.json", STATS_CAP)
	if not problems.is_empty():
		return
	var stat_problems: PackedStringArray = Catalog.check(towers, enemies, rules)
	if not stat_problems.is_empty():
		problems.append_array(stat_problems)
		return
	catalog = Catalog.from_data(towers, enemies, rules)
	var level_dir: String = root.path_join("levels")
	var order: Variant = _read(level_dir.path_join(CAMPAIGN_FILE), CAMPAIGN_FILE, CAMPAIGN_CAP)
	if not problems.is_empty():
		return
	var listed: Array[StringName] = _read_campaign(order)
	for id: StringName in listed:
		var file_name: String = String(id) + ".json"
		var before: int = problems.size()
		var data: Variant = _read(level_dir.path_join(file_name), file_name, LEVEL_CAP)
		if problems.size() > before:
			continue
		var level_problems: PackedStringArray = LevelData.check(data, catalog)
		if not level_problems.is_empty():
			problems.append_array(level_problems)
			continue
		var level: LevelData = LevelData.from_data(data, catalog)
		if level.id != id:
			problems.append("%s: id: must equal the file name" % file_name)
			continue
		levels[id] = level
	for file_name: String in DirAccess.get_files_at(level_dir):
		if file_name.get_extension() != "json" or file_name == CAMPAIGN_FILE:
			continue
		if not listed.has(StringName(file_name.get_basename())):
			problems.append("%s: is not listed in %s" % [file_name, CAMPAIGN_FILE])
	_load_run(root)


## Reads the run files and hands them to RunData (2.12): only the four fixed files and
## the segments index.json lists, keyed by their path under data/. A file that is missing
## is left out, and RunData reports it. A file that cannot be read is left out too, with
## its own problem line here.
func _load_run(root: String) -> void:
	var files: Dictionary = {}
	_read_run_file(root, RUN_FILE, RUN_CAP, files)
	_read_run_file(root, CARDS_FILE, CARDS_CAP, files)
	_read_run_file(root, INDEX_FILE, INDEX_CAP, files)
	_read_run_file(root, PACKS_FILE, PACKS_CAP, files)
	for id: StringName in _listed_segments(files.get(INDEX_FILE, null)):
		_read_run_file(root, "%s/%s.json" % [SEGMENT_DIR, id], SEGMENT_CAP, files)
	var data: RunData = RunData.from_data(files, catalog)
	if data == null:
		problems.append_array(RunData.check(files, catalog))
		return
	var tier_problems: PackedStringArray = _check_tiers(data)
	if not tier_problems.is_empty():
		problems.append_array(tier_problems)
		return
	run = data


## Contract 14.8: each tier's `level` is the last level of a campaign region, and the
## tiers come in campaign order, so tier k is earned with the k-th of these regions.
func _check_tiers(data: RunData) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var last_region: int = -1
	for t: int in data.tiers.size():
		var level: StringName = data.tiers[t]["level"]
		var region: int = -1
		for r: int in campaign.size():
			var ids: Array[StringName] = campaign[r]["levels"]
			if not ids.is_empty() and ids.back() == level:
				region = r
				break
		if region < 0:
			found.append("run.json: tiers[%d].level: %s is not the last level of a campaign region" % [t, level])
		elif region <= last_region:
			found.append("run.json: tiers[%d].level: must come after the level of the tier before it in campaign order" % t)
		last_region = maxi(last_region, region)
	return found


## One run file into files under its path. A missing file adds nothing.
func _read_run_file(root: String, relative: String, cap: int, files: Dictionary) -> void:
	var got: Dictionary = JsonFile.read(root.path_join(relative), cap)
	if got["status"] == JsonFile.MISSING:
		return
	var data: Variant = _take(got, relative.get_file(), cap)
	if data != null:
		files[relative] = data


## The ids index.json lists, when they are a list of at most SEGMENTS_MAX. Only ids in id
## form are kept, so no path can reach outside the folder. RunData checks the rest.
static func _listed_segments(index: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if typeof(index) != TYPE_DICTIONARY:
		return out
	var list: Variant = (index as Dictionary).get("segments", null)
	if typeof(list) != TYPE_ARRAY or (list as Array).size() > SEGMENTS_MAX:
		return out
	for item: Variant in list:
		if DataCheck.is_id(item) and not out.has(StringName(String(item))):
			out.append(StringName(String(item)))
	return out


## The parsed file, or null with a problem.
func _read(path: String, file_name: String, cap: int) -> Variant:
	return _take(JsonFile.read(path, cap), file_name, cap)


## The data of one JsonFile.read result, or null with a problem.
func _take(got: Dictionary, file_name: String, cap: int) -> Variant:
	var status: StringName = got["status"]
	if status == JsonFile.OK_STATUS:
		return got["data"]
	if status == JsonFile.MISSING:
		problems.append("%s: is missing" % file_name)
	elif status == JsonFile.LOCKED:
		problems.append("%s: cannot be opened" % file_name)
	else:
		problems.append("%s: is over %d bytes, not plain ASCII, or not valid JSON" % [file_name, cap])
	return null


## Checks campaign.json (2.5) and fills campaign. Returns every level id it lists, in order.
func _read_campaign(data: Variant) -> Array[StringName]:
	var listed: Array[StringName] = []
	var chk: DataCheck = DataCheck.new(CAMPAIGN_FILE)
	if chk.object(data, "", ["format", "regions"]):
		var top: Dictionary = data
		chk.integer(top, "format", "", FORMAT, FORMAT)
		var region_list: Array = chk.array(top, "regions", "", 1, catalog.rules.region_stars.size())
		var region_ids: Array[StringName] = []
		for r: int in region_list.size():
			var path: String = "regions[%d]" % r
			if not chk.object(region_list[r], path, ["id", "name", "levels"]):
				continue
			var item: Dictionary = region_list[r]
			var region_id: StringName = chk.ident(item, "id", path)
			if region_id != &"" and region_ids.has(region_id):
				chk.fail(path + ".id", "repeats %s" % region_id)
			region_ids.append(region_id)
			var region_name: String = chk.text(item, "name", path, 24)
			var ids: Array[StringName] = []
			var level_list: Array = chk.array(item, "levels", path, 1, REGION_LEVELS_MAX)
			for i: int in level_list.size():
				var level_path: String = "%s.levels[%d]" % [path, i]
				var id: StringName = chk.ident_value(level_list[i], level_path)
				if id == &"":
					continue
				if listed.has(id):
					chk.fail(level_path, "repeats %s" % id)
					continue
				listed.append(id)
				ids.append(id)
			campaign.append({"id": region_id, "name": region_name, "levels": ids})
	problems.append_array(chk.problems)
	return listed
