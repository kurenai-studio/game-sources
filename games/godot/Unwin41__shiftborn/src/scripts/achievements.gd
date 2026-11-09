class_name Achievements
extends RefCounted
## The ten achievements and the rule for each, checked against
## [RunStats]. [Progress] stores which ones are unlocked.

const SHIFTS_NEEDED := 50
const PERFECTS_NEEDED := 5
const KILLS_NEEDED := 1000
## Untouchable: win with more than this share of max HP left.
const UNTOUCHABLE_HEALTH := 0.5

const LIST: Array[Dictionary] = [
	{id = &"first_blood", title = "First Blood", text = "Defeat an enemy"},
	{id = &"shapeshifter", title = "Shapeshifter", text = "Shift 50 times in one run"},
	{id = &"perfect", title = "Perfect", text = "Land a perfect shift"},
	{id = &"flawless_five", title = "Flawless Five", text = "Land 5 perfect shifts in one run"},
	{id = &"evolved", title = "Evolved", text = "Take an evolution"},
	{id = &"twin_evolution", title = "Twin Evolution", text = "Take 2 evolutions in one run"},
	{id = &"giant_slayer", title = "Giant Slayer", text = "Defeat both mini-bosses in one run"},
	{id = &"thousand", title = "Thousand Cuts", text = "Defeat 1000 enemies in one run"},
	{id = &"demon_slayer", title = "Demon Slayer", text = "Defeat The Shifting Demon"},
	{id = &"untouchable", title = "Untouchable", text = "Win with more than half your HP"},
]


static func is_met(id: StringName, stats: RunStats) -> bool:
	match id:
		&"first_blood": return stats.kills >= 1
		&"shapeshifter": return stats.shifts >= SHIFTS_NEEDED
		&"perfect": return stats.perfects >= 1
		&"flawless_five": return stats.perfects >= PERFECTS_NEEDED
		&"evolved": return stats.evolutions >= 1
		&"twin_evolution": return stats.evolutions >= 2
		&"giant_slayer": return stats.mini_bosses_killed >= Run.MINI_BOSSES.size()
		&"thousand": return stats.kills >= KILLS_NEEDED
		&"demon_slayer": return stats.won
		&"untouchable": return stats.won and stats.health_share > UNTOUCHABLE_HEALTH
	return false


## Ids met by [param stats] that are not in [param owned] yet.
static func newly_unlocked(stats: RunStats, owned: Array) -> Array[StringName]:
	var fresh: Array[StringName] = []
	for entry in LIST:
		if not entry.id in owned and is_met(entry.id, stats):
			fresh.append(entry.id)
	return fresh


static func title_of(id: StringName) -> String:
	for entry in LIST:
		if entry.id == id:
			return entry.title
	return String(id)
