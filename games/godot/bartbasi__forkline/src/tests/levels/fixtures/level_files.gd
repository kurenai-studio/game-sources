# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Reads the real data files for tests/levels/. src/sim/ reads no files, so the tests
## read data/ here through FileAccess and Godot's JSON parser, and hand the parsed
## values to the sim's own checks.

const LEVELS_DIR: String = "res://data/levels/"
const STATS_DIR: String = "res://data/stats/"
const CAMPAIGN_FILE: String = "campaign.json"


static func read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func stats_files() -> Array:
	return [read_json(STATS_DIR + "towers.json"), read_json(STATS_DIR + "enemies.json"), read_json(STATS_DIR + "rules.json")]


static func catalog() -> Catalog:
	var files: Array = stats_files()
	return Catalog.from_data(files[0], files[1], files[2])


## Every level file name in data/levels/ without ".json", sorted. campaign.json is left out.
static func level_file_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for file_name: String in DirAccess.get_files_at(LEVELS_DIR):
		if file_name.ends_with(".json") and file_name != CAMPAIGN_FILE:
			ids.append(file_name.trim_suffix(".json"))
	ids.sort()
	return ids


static func level_path(id: String) -> String:
	return LEVELS_DIR + id + ".json"


static func level_data(id: String) -> Variant:
	return read_json(level_path(id))


static func level(id: String, stats: Catalog) -> LevelData:
	return LevelData.from_data(level_data(id), stats)


static func campaign() -> Variant:
	return read_json(LEVELS_DIR + CAMPAIGN_FILE)


## Level ids in play order, from campaign.json. Empty when the file has the wrong shape.
static func campaign_order() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var data: Variant = campaign()
	if not (data is Dictionary) or not ((data as Dictionary).get("regions") is Array):
		return out
	for region: Variant in data["regions"]:
		if region is Dictionary and (region as Dictionary).get("levels") is Array:
			for id: Variant in region["levels"]:
				out.append(str(id))
	return out


## Region id for each level id, from campaign.json.
static func region_of() -> Dictionary:
	var out: Dictionary = {}
	var data: Variant = campaign()
	if not (data is Dictionary) or not ((data as Dictionary).get("regions") is Array):
		return out
	for region: Variant in data["regions"]:
		if region is Dictionary and (region as Dictionary).get("levels") is Array:
			for id: Variant in region["levels"]:
				out[str(id)] = str(region.get("id", ""))
	return out


## "c,r c,r ..." for a list of cells, the form the pinned routes use.
static func cells_text(cells: Array[Vector2i]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for cell: Vector2i in cells:
		parts.append("%d,%d" % [cell.x, cell.y])
	return " ".join(parts)
