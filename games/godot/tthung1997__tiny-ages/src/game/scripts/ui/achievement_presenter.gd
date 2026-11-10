class_name AchievementPresenter
extends RefCounted
## What the achievements panel shows: only what the group has earned, in the order it was earned,
## each with its title and an icon. No empty slots, no count, no progress: the age gate is hidden
## on purpose (docs/gameplay.md P2, P12). Pure logic, no nodes.

## The icon cell in `ICONS_PATH` for each achievement, left to right. Mirrored by
## `tools/art/ui_achievements.js`; append new ones at the end.
const ICON_ORDER: Array[StringName] = [
	&"fire", &"stone_tools", &"reliable_food", &"shared_stories", &"bigger_group",
	&"unexpected_garden", &"first_roof", &"first_harvest", &"fired_clay", &"woven_cloth",
	&"a_village", &"green_stone", &"the_first_field", &"a_place_to_stay", &"rare_visitor",
	&"first_casting", &"bronze_alloy", &"mud_brick_walls", &"wheel_and_road", &"a_town",
	&"beyond_the_water", &"first_bloom", &"fuller_harvest", &"the_hill_fort", &"silver_by_weight",
	&"written_word", &"name_abroad", &"paved_streets", &"water_from_afar", &"written_law",
	&"the_square", &"lamp_and_stage", &"wider_world",
]
const ICONS_PATH: String = "res://assets/ui/achievements.png"
const CELL: Vector2i = Vector2i(20, 20)
## Shown for an achievement with no icon of its own: the cell after the last one in `ICON_ORDER`.
const GENERIC_ICON: int = 33


class Badge:
	extends RefCounted
	var key: StringName = &""
	var title: String = ""
	## The cell in the icon sheet.
	var icon: int = GENERIC_ICON


## Everything earned, oldest first.
static func badges(world: WorldState, content: ContentLibrary) -> Array[Badge]:
	var result: Array[Badge] = []
	for key: StringName in world.achievements:
		var badge: Badge = Badge.new()
		badge.key = key
		badge.title = title_for(key, world, content)
		badge.icon = icon_for(key)
		result.append(badge)
	return result


## The title it was earned under; for an older save that did not keep it, the content's title,
## and failing that the key spelled out ("first_roof" -> "First Roof").
static func title_for(key: StringName, world: WorldState, content: ContentLibrary) -> String:
	var title: String = world.achievement_titles.get(key, "")
	if title.is_empty() and content != null:
		title = content.achievement_title(key)
	if title.is_empty():
		title = String(key).replace("_", " ").capitalize()
	return title


static func icon_for(key: StringName) -> int:
	var index: int = ICON_ORDER.find(key)
	return index if index >= 0 else GENERIC_ICON
