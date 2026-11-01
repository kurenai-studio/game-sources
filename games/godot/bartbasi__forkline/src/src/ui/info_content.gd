# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name InfoContent
extends RefCounted
## What the Info guide shows of the game's content: the ids of the towers, creatures and
## bosses in the catalog, in the data's order, and the map features that some level or
## run tier uses. Nothing here is a fixed list of ids (docs/ARCHITECTURE.md 2.1, 14.9), so
## content joins the guide when its data does. Ids the art code cannot draw are left out.

## Feature id to the grid characters that make it.
const FEATURE_CHARS: Dictionary[StringName, String] = {
	&"tunnel": "T", &"bridge": "X", &"slide": "^v<>", &"stumps": "PQ",
}

var towers: Array[StringName] = []
var creatures: Array[StringName] = []    # not bosses
var bosses: Array[StringName] = []
var features: Array[StringName] = []     # InfoArt.FEATURE_IDS order


## The content of a game. A null game, or one with no catalog, shows nothing.
static func from_game(game: GameData) -> InfoContent:
	var content: InfoContent = new()
	if game == null or game.catalog == null:
		return content
	for id: StringName in game.catalog.tower_ids():
		if Silhouettes.has_tower(id):
			content.towers.append(id)
	for id: StringName in game.catalog.enemy_ids():
		if not Silhouettes.has_enemy(id):
			continue
		if game.catalog.enemy(id).boss:
			content.bosses.append(id)
		else:
			content.creatures.append(id)
	var used: String = ""
	for level: LevelData in game.levels.values():
		for row: String in level.grid:
			used += row
	if game.run != null:
		for tier: Dictionary in game.run.tiers:
			used += String(tier.get("grid", ""))
	for feature: StringName in InfoArt.FEATURE_IDS:
		for ch: String in String(FEATURE_CHARS[feature]):
			if used.contains(ch):
				content.features.append(feature)
				break
	return content


## Every creature, then every boss: the pictures of the Creatures section.
func pictures() -> Array[StringName]:
	var out: Array[StringName] = []
	out.append_array(creatures)
	out.append_array(bosses)
	return out
