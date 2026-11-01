# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name CampaignText
extends RefCounted
## Where a level sits in the campaign, from the campaign order in the data
## (docs/ARCHITECTURE.md 2.1: level numbers such as 1-3 come from the order).


## The level number as players read it: region 1, level 3 is "1-3". "" when unknown.
static func number(game: GameData, id: StringName) -> String:
	for region_index: int in game.campaign.size():
		var list: Array[StringName] = game.campaign[region_index]["levels"]
		var at: int = list.find(id)
		if at >= 0:
			return "%d-%d" % [region_index + 1, at + 1]
	return ""


## The level after this one in its region, or &"" for the last level of a region.
static func next_level(game: GameData, id: StringName) -> StringName:
	for region: Dictionary in game.campaign:
		var list: Array[StringName] = region["levels"]
		var at: int = list.find(id)
		if at >= 0:
			return list[at + 1] if at + 1 < list.size() else &""
	return &""


## "1-2 The Fork" for lists and messages.
static func title(game: GameData, id: StringName) -> String:
	var level: LevelData = game.levels.get(id)
	if level == null:
		return ""
	return "%s  %s" % [number(game, id), level.name]


## "1 gate", "2 gates", "No gates".
static func gates_text(count: int) -> String:
	if count <= 0:
		return "No gates"
	return "%d %s" % [count, "gate" if count == 1 else "gates"]
