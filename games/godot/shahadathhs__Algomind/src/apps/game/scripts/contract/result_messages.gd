class_name ResultMessages
extends RefCounted
## Player-facing text for a run result. The one place these strings live.
## Mirrors packages/level-contract/src/explain.ts. The game shows them in capitals
## (docs/README_VISUAL_DESIGN.md section 7), which is a display concern and not done here.

const REASON_MESSAGES := {
	"GOAL_REACHED": "Level solved.",
	"BLOCKED_BY_WALL": "The automaton tried to move into a wall.",
	"BLOCKED_BY_BOUNDARY": "The automaton tried to move off the board.",
	"HIT_BY_PATROL": "A guard reached the automaton.",
	"BLOCKED_BY_DOOR": "The automaton tried to go through a locked door.",
	"BLOCKED_BY_GATE": "The automaton tried to go through a shut gate.",
	"TOO_DEEP": "The procedures called each other too many times.",
	"UNDELIVERED": "The automaton reached the target before every item was delivered.",
	"PROGRAM_ENDED": "The program ended before the goal.",
	"STEP_LIMIT": "The program ran too long and was stopped.",
	"INVALID_INSTRUCTION": "The program contains an instruction this level cannot run.",
}


## The text for a reason code; an empty string for an unknown code.
static func for_reason(reason: Variant) -> String:
	if typeof(reason) != TYPE_STRING:
		return ""
	return REASON_MESSAGES.get(reason, "")


## The text for a simulator result (a Dictionary with a "reason").
static func for_result(result: Variant) -> String:
	if typeof(result) != TYPE_DICTIONARY:
		return ""
	return for_reason(result.get("reason"))
