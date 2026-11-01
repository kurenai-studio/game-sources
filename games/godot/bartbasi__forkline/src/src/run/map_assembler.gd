# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name MapAssembler
extends RefCounted
## Builds a run's map and 18 waves from a seed (docs/ARCHITECTURE.md 3.4). Pure: the
## same seed and data always give an equal level. All chance comes from generators
## seeded with RunSeeds.derive(), and only randi_range() is called on them, in the
## order below.

const TAG_BOSS: String = "boss"
const TAG_MAP: String = "map"
const TAG_PACK: String = "pack"
const WAVES_PER_BAND: int = 3


## The run's level: its map and its 18 waves, from the bosses, segments and packs of that
## tier and below (14.8). Null on a data bug, for a seed outside 0 to 2^32 - 1, or for a tier
## outside 0 to the tier count.
static func assemble(run_seed: int, data: RunData, catalog: Catalog, tier: int = 0) -> LevelData:
	var picks: Dictionary = plan(run_seed, data, tier)
	if picks.is_empty():
		return null
	var pack_ids: Array[StringName] = picks["packs"]
	return build(data, catalog, picks["top"], picks["middle"], picks["bottom"], pack_ids)


## The seeded picks, in the order of 3.4. Returns {"boss": StringName, "top": StringName,
## "middle": StringName, "bottom": StringName, "packs": Array[StringName]} (the pack of
## band 1 first), or {} when a pick has nothing to choose from or the tier is outside 0 to the
## tier count. Things above the tier leave every list before any pick, and the picks walk the
## lists in file order (14.8).
static func plan(run_seed: int, data: RunData, tier: int = 0) -> Dictionary:
	if data == null or run_seed < 0 or run_seed > RunSeeds.SEED_MAX:
		return {}
	if tier < 0 or tier > data.tiers.size():
		return {}
	# 1. The boss, over the bosses that have a band 6 pack, in enemies.json order.
	var bosses: Array[StringName] = data.boss_ids(tier)
	if bosses.is_empty():
		return {}
	var boss_rng: RandomNumberGenerator = generator(run_seed, TAG_BOSS, 0)
	var boss: StringName = bosses[boss_rng.randi_range(0, bosses.size() - 1)]
	# 2. The map: a top, then a middle that fits under it, then a bottom that fits under that.
	var map_rng: RandomNumberGenerator = generator(run_seed, TAG_MAP, 0)
	var tops: Array[Dictionary] = data.segments_of(&"top", tier)
	if tops.is_empty():
		return {}
	var top: Dictionary = tops[map_rng.randi_range(0, tops.size() - 1)]
	var middles: Array[Dictionary] = data.segments_under(top["id"], tier)
	if middles.is_empty():
		return {}
	var middle: Dictionary = middles[map_rng.randi_range(0, middles.size() - 1)]
	var bottoms: Array[Dictionary] = data.segments_under(middle["id"], tier)
	if bottoms.is_empty():
		return {}
	var bottom: Dictionary = bottoms[map_rng.randi_range(0, bottoms.size() - 1)]
	# 3. One pack per band, each on its own generator. Band 6 uses only the boss's packs.
	var pack_ids: Array[StringName] = []
	for band: int in range(1, RunData.BANDS + 1):
		var choices: Array[Dictionary] = data.packs_of(band, boss if band == RunData.BANDS else &"", tier)
		if choices.is_empty():
			return {}
		var pack_rng: RandomNumberGenerator = generator(run_seed, TAG_PACK, band)
		pack_ids.append(choices[pack_rng.randi_range(0, choices.size() - 1)]["id"])
	return {"boss": boss, "top": top["id"], "middle": middle["id"], "bottom": bottom["id"], "packs": pack_ids}


## The level for chosen segments and packs (one pack id per band, band 1 first): steps 4
## and 5 of 3.4. Null when anything is unknown or the level fails LevelData's checks, or
## its build spots or gate sockets fall outside run.json's ranges.
static func build(data: RunData, catalog: Catalog, top_id: StringName, middle_id: StringName, bottom_id: StringName, pack_ids: Array[StringName]) -> LevelData:
	if data == null or catalog == null or pack_ids.size() != RunData.BANDS:
		return null
	var top: Dictionary = data.segment(top_id)
	var middle: Dictionary = data.segment(middle_id)
	var bottom: Dictionary = data.segment(bottom_id)
	if top.is_empty() or middle.is_empty() or bottom.is_empty():
		return null
	if top["kind"] != &"top" or middle["kind"] != &"middle" or bottom["kind"] != &"bottom":
		return null
	var grid: Array = []
	for segment: Dictionary in [top, middle, bottom]:
		for line: String in segment["grid"]:
			grid.append(line)
	var two_entrances: bool = false
	for line: String in top["grid"]:
		if line.contains("2"):
			two_entrances = true
	var waves: Array = []
	for b: int in RunData.BANDS:
		var pack: Dictionary = _pack_by_id(data, pack_ids[b])
		if pack.is_empty() or pack["band"] != b + 1:
			return null
		var pack_waves: Array = pack["waves"]
		for k: int in WAVES_PER_BAND:
			var groups: Array = []
			for raw: Variant in (pack_waves[k] as Dictionary)["groups"]:
				var group: Dictionary = raw
				var entrance: int = int(group["entrance"])
				if entrance == 2 and not two_entrances:
					entrance = 1
				groups.append({
					"enemy": String(group["enemy"]), "count": int(group["count"]), "entrance": entrance,
					"at_ms": int(group["at_ms"]), "every_ms": int(group["every_ms"]),
				})
			var wave_number: int = b * WAVES_PER_BAND + k + 1
			# Waves 1 to 17 rise by the step. Wave 18, the boss wave, takes its pack's own strength.
			var strength: int = data.strength_start + data.strength_step * (wave_number - 1)
			if wave_number == RunData.BANDS * WAVES_PER_BAND:
				var boss_wave: Dictionary = pack_waves[k]
				if not boss_wave.has("strength"):
					return null
				strength = int(boss_wave["strength"])
			waves.append({
				"strength": strength,
				"groups": groups,
			})
	var tower_ids: Array = []
	for id: StringName in data.towers:
		tower_ids.append(String(id))
	var level: LevelData = LevelData.from_data({
		"format": LevelData.FORMAT, "id": "run", "name": "Run", "grid": grid,
		"start_gold": data.start_gold, "gates": data.gates, "towers": tower_ids,
		"strength": data.strength_start, "star3": {"kind": "no_lives_lost"}, "waves": waves,
	}, catalog)
	if level == null:
		return null
	if level.spots.size() < data.spots_min or level.spots.size() > data.spots_max:
		return null
	if level.sockets.size() < data.sockets_min or level.sockets.size() > data.sockets_max:
		return null
	return level


## A generator for one purpose, seeded from the run seed (3.4).
static func generator(run_seed: int, tag: String, index: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = RunSeeds.derive(run_seed, tag, index)
	return rng


static func _pack_by_id(data: RunData, id: StringName) -> Dictionary:
	for pack: Dictionary in data.packs:
		if pack["id"] == id:
			return pack
	return {}
