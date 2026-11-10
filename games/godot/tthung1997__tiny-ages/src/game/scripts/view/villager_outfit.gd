class_name VillagerOutfit
extends RefCounted
## What the villagers wear (docs/ages.md B8, "Clothes, one look per age"): an outfit for the turn of
## each age and a finer one at a milestone of its own. Pure and derived from the world, so there
## is nothing to save, and the outfit only follows what has been earned (the age gate stays hidden).

const FUR: StringName = &"fur"
const FIELD: StringName = &"field"
const WOVEN: StringName = &"woven"
const TOWN: StringName = &"town"
const BRONZE: StringName = &"bronze"
const CHECKED: StringName = &"checked"
const IRON: StringName = &"iron"
const LINEN: StringName = &"linen"
const CIVIC: StringName = &"civic"

## Every outfit, simplest first: each falls back to the one before it if its art is missing.
const ORDER: Array[StringName] = [FUR, FIELD, WOVEN, TOWN, BRONZE, CHECKED, IRON, LINEN, CIVIC]

const SETTLED_ERA: int = 1
const BRONZE_ERA: int = 2
const IRON_ERA: int = 3
const CLASSICAL_ERA: int = 4
const WOVEN_ACHIEVEMENT: StringName = &"woven_cloth"
const BRONZE_ACHIEVEMENT: StringName = &"first_casting"
const IRON_ACHIEVEMENT: StringName = &"first_bloom"
const CIVIC_ACHIEVEMENT: StringName = &"the_square"

## Where each outfit's sheets live, `<look>.png` inside. The woven tunic keeps its original path.
const DIRS: Dictionary = {
	FUR: "res://assets/world/cave/villagers/",
	FIELD: "res://assets/world/settled/villagers/field/",
	WOVEN: "res://assets/world/settled/villagers/",
	TOWN: "res://assets/world/bronze/villagers/town/",
	BRONZE: "res://assets/world/bronze/villagers/fittings/",
	CHECKED: "res://assets/world/iron/villagers/checked/",
	IRON: "res://assets/world/iron/villagers/fittings/",
	LINEN: "res://assets/world/classical/villagers/linen/",
	CIVIC: "res://assets/world/classical/villagers/civic/",
}


## The finest outfit the world has earned: the civic mantle once the Square is earned in the
## Classical Age, linen from the turn of that age, iron fittings once the first bloom is earned in
## the Iron Age, checked wool from the turn of that age, bronze fittings once the first casting is
## earned in the Bronze Age or later, town clothes from the turn of the Bronze Age, woven tunics once
## the cloth is woven in the Settled Age or later, field clothes from the turn of the Settled Age,
## else furs.
static func for_world(world: WorldState) -> StringName:
	if world.era_order >= CLASSICAL_ERA:
		if world.has_achievement(CIVIC_ACHIEVEMENT):
			return CIVIC
		return LINEN
	if world.era_order >= IRON_ERA:
		if world.has_achievement(IRON_ACHIEVEMENT):
			return IRON
		return CHECKED
	if world.era_order >= BRONZE_ERA:
		if world.has_achievement(BRONZE_ACHIEVEMENT):
			return BRONZE
		return TOWN
	if world.era_order >= SETTLED_ERA:
		if world.has_achievement(WOVEN_ACHIEVEMENT):
			return WOVEN
		return FIELD
	return FUR


## The sheet for `look` in `outfit`: `res://.../<look>.png`, or "" if there is no art.
static func sheet_path(outfit: StringName, look: StringName) -> String:
	var dir: String = DIRS.get(outfit, "")
	if dir.is_empty():
		return ""
	var path: String = "%s%s.png" % [dir, look]
	return path if ResourceLoader.exists(path) else ""
