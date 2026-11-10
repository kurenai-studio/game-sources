class_name Season
extends RefCounted
## The four seasons of the year. They are plain integers so authored conditions can store them
## (`SimCondition.Kind.SEASON_IS`, `amount`). The calendar itself (how long a season lasts, which
## one the first day falls in) is on SimConfig.

const SPRING: int = 0
const SUMMER: int = 1
const AUTUMN: int = 2
const WINTER: int = 3
const COUNT: int = 4

const NAMES: Array[String] = ["Spring", "Summer", "Autumn", "Winter"]


static func display_name(season: int) -> String:
	if season < 0 or season >= COUNT:
		push_error("Unknown season %d" % season)
		return ""
	return NAMES[season]


## "Early spring", "Spring" or "Late spring": where `day_in_season` (0-based) falls in a season
## of `length` days, in thirds.
static func describe(season: int, day_in_season: int, length: int) -> String:
	var name: String = display_name(season).to_lower()
	var third: float = float(length) / 3.0
	if float(day_in_season) < third:
		return "Early %s" % name
	if float(day_in_season) >= third * 2.0:
		return "Late %s" % name
	return display_name(season)
