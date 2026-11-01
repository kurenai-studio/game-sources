# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Real Battle objects for the panel tests, made from the real level files
## through GameData. Load it with preload; it has no class name.

static var _game: GameData = null


static func game() -> GameData:
	if _game == null:
		_game = GameData.load_from("res://data")
	return _game


## A battle on a real campaign level.
static func battle(level_id: StringName = &"r1_l1", relaxed: bool = false) -> Battle:
	return Battle.create(game().levels[level_id], game().catalog, relaxed, [] as Array[Dictionary])


## The same level, but offering every tower in the catalog.
static func all_towers_battle(level_id: StringName = &"r1_l1") -> Battle:
	var data: Dictionary = game().levels[level_id].to_data()
	data["towers"] = game().catalog.tower_ids()
	var level: LevelData = LevelData.from_data(data, game().catalog)
	return Battle.create(level, game().catalog, false, [] as Array[Dictionary])


## A battle on a real level whose first wave is changed (to bring a boss early, say).
static func battle_with_first_wave(groups: Array, level_id: StringName = &"r1_l1") -> Battle:
	var data: Dictionary = game().levels[level_id].to_data()
	data["waves"][0] = {"groups": groups}
	var level: LevelData = LevelData.from_data(data, game().catalog)
	return Battle.create(level, game().catalog, false, [] as Array[Dictionary])


## Steps until the phase leaves WAVE, at most `limit` ticks. Returns ticks run.
static func finish_wave(b: Battle, limit: int = 20000) -> int:
	var ran: int = 0
	while b.phase == Battle.Phase.WAVE and ran < limit:
		b.step()
		ran += 1
	return ran


static func steps(b: Battle, count: int) -> void:
	for i: int in count:
		b.step()


## Every level file under data/levels, listed in the campaign or not, in file name order.
## The dock test covers all of them, so a region still being added is checked too.
static func all_level_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	var names: PackedStringArray = DirAccess.get_files_at("res://data/levels")
	names.sort()
	for file_name: String in names:
		if file_name.get_extension() == "json" and file_name != GameData.CAMPAIGN_FILE:
			ids.append(StringName(file_name.get_basename()))
	return ids


## A battle on any level file. Null when the file does not make a level.
static func file_battle(level_id: StringName, relaxed: bool = false) -> Battle:
	var level: LevelData = game().levels.get(level_id)
	if level == null:
		var got: Dictionary = JsonFile.read("res://data/levels/%s.json" % level_id, GameData.LEVEL_CAP)
		if got["status"] != JsonFile.OK_STATUS:
			return null
		level = LevelData.from_data(got["data"], game().catalog)
	if level == null:
		return null
	return Battle.create(level, game().catalog, relaxed, [] as Array[Dictionary])


## A battle on a real level whose waves are replaced (to bring one creature, a boss included).
static func battle_with_waves(waves: Array, level_id: StringName = &"r1_l1") -> Battle:
	var data: Dictionary = game().levels[level_id].to_data()
	data["waves"] = waves
	var level: LevelData = LevelData.from_data(data, game().catalog)
	if level == null:
		return null
	return Battle.create(level, game().catalog, false, [] as Array[Dictionary])


## A game of four regions of six levels, for the level list. The levels are copies of one
## real level with other ids, so only the campaign order differs.
static func four_region_game() -> GameData:
	var made: GameData = GameData.new()
	made.catalog = game().catalog
	var base: Dictionary = game().levels[&"r1_l1"].to_data()
	for r: int in 4:
		var ids: Array[StringName] = []
		for n: int in 6:
			var id: StringName = StringName("x%d_l%d" % [r + 1, n + 1])
			var data: Dictionary = base.duplicate(true)
			data["id"] = String(id)
			data["name"] = "Fixture %d-%d" % [r + 1, n + 1]
			made.levels[id] = LevelData.from_data(data, made.catalog)
			ids.append(id)
		made.campaign.append({"id": StringName("x%d" % (r + 1)), "name": "Fixture region %d" % (r + 1), "levels": ids})
	return made
