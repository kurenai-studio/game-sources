class_name Scoring
extends RefCounted
## Stars and points for one verified clear. A mirror of scoreResult in packages/level-contract
## (src/scoring.ts): both pass the same fixtures in fixtures/scoring. The game uses it for the
## provisional score shown offline; the server's total wins at the next sync.

## Rule set 1, the same as DEFAULT_POINTS_RULES.
const DEFAULT_RULES := {
	"version": 1,
	"base": {"easy": 10, "medium": 20, "hard": 30},
	"parFull": 10,
	"parNear": 5,
	"nearSlots": 2,
	"stepsBonus": 5,
	"firstClear": 10,
}


## Scores a result. `input` has difficulty, par {commands, steps}, slots, and steps. Returns
## { stars, points, levelScore }, with the first-clear bonus only in levelScore.
static func score_result(rules: Dictionary, input: Dictionary) -> Dictionary:
	var par: Dictionary = input["par"]
	var over := int(input["slots"]) - int(par["commands"])
	var near := int(rules["nearSlots"])
	var stars := 3 if over <= 0 else (2 if over <= near else 1)
	var par_bonus := (
		int(rules["parFull"]) if over <= 0 else (int(rules["parNear"]) if over <= near else 0)
	)
	var steps_bonus := int(rules["stepsBonus"]) if int(input["steps"]) <= int(par["steps"]) else 0
	var points := int(rules["base"][input["difficulty"]]) + par_bonus + steps_bonus
	return {"stars": stars, "points": points, "levelScore": points + int(rules["firstClear"])}
