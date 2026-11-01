class_name LevelStars
extends RefCounted
## The stars shown on a solved level's tile (1 to 3, 0 when there is nothing to show).
##
## The server's answer wins once a sync has reported it. Until then the stars are provisional:
## the best result on this device scored against the par bundled with the level, with the same
## function the solved screen uses (Scoring, a mirror of the contract's scoring).


static func of(progress: ProgressStore, entry: Dictionary) -> int:
	var id := str(entry["id"])
	var reported := progress.results.stars_for(id)
	if reported > 0:
		return reported
	return provisional(
		entry.get("par", {}),
		str(entry["level"]["difficulty"]),
		progress.best_commands(id, int(entry["level"]["levelVersion"]))
	)


## Stars for `commands` used against `par` ({ commands, steps }); 0 without both.
static func provisional(par: Dictionary, difficulty: String, commands: int) -> int:
	if (
		commands <= 0
		or not par.has("commands")
		or not Scoring.DEFAULT_RULES["base"].has(difficulty)
	):
		return 0
	var score := (
		Scoring
		. score_result(
			Scoring.DEFAULT_RULES,
			{
				"difficulty": difficulty,
				"par": par,
				"slots": commands,
				"steps": int(par.get("steps", 0)),
			}
		)
	)
	return int(score["stars"])


## The words for a screen reader.
static func words(count: int) -> String:
	return "%d star%s" % [count, "" if count == 1 else "s"]
