class_name TutorialSteps
extends RefCounted
## The guided first run as a small state machine: move, shift, beat a
## resistant enemy, land a perfect shift. Each step advances only on its
## own event; [Tutorial] feeds the events and shows the prompts.

enum Step { MOVE, SHIFT, RESIST, PERFECT, DONE }

## Pixels the player must walk to finish the move step.
const MOVE_DISTANCE := 96.0
const STEP_COUNT := 4
const EVENTS: Dictionary[Step, StringName] = {
	Step.SHIFT: &"shifted",
	Step.RESIST: &"resist_kill",
	Step.PERFECT: &"perfect",
}
const PROMPTS: Dictionary[Step, String] = {
	Step.MOVE: "Move",
	Step.SHIFT: "Shift",
	Step.RESIST: "Immunity",
	Step.PERFECT: "Perfect shift",
}
const HINTS: Dictionary[Step, String] = {
	Step.MOVE: "WASD, arrow keys or the left stick. You attack on your own.",
	Step.SHIFT: "Press Space or A to switch between warrior and mage.",
	Step.RESIST: "Skulls are immune to magic. Kill this one as the warrior. The diamond above an enemy shows the only form that hurts it.",
	Step.PERFECT: "Shift just as an enemy is about to hit you: time slows and you cannot be hurt.",
}

var current: Step = Step.MOVE
var _moved: float = 0.0


static func prompt(step: Step) -> String:
	return PROMPTS.get(step, "")


static func hint(step: Step) -> String:
	return HINTS.get(step, "")


static func progress_text(step: Step) -> String:
	return "%d/%d" % [mini(step + 1, STEP_COUNT), STEP_COUNT]


func is_done() -> bool:
	return current == Step.DONE


## Adds walked distance. Returns true when it finishes the move step.
func add_movement(distance: float) -> bool:
	if current != Step.MOVE:
		return false
	_moved += distance
	if _moved < MOVE_DISTANCE:
		return false
	current = Step.SHIFT
	return true


## Returns true when [param event] finishes the current step.
func notify(event: StringName) -> bool:
	if EVENTS.get(current, &"") != event:
		return false
	current = (current + 1) as Step
	return true
