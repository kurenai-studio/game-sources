class_name VillagerPlan
extends RefCounted
## Where a villager should be and what they should be doing, as the view sees it.

const HIDDEN_ASLEEP: StringName = &"asleep"
const HIDDEN_AWAY: StringName = &"away"

var visible: bool = true
## Why they are out of sight, when not visible.
var hidden_reason: StringName = &""
## Feet position in art pixels.
var target: Vector2 = Vector2.ZERO
## idle, chop, hammer or spear: what to do on arrival.
var pose: StringName = &"idle"
## Face towards this x on arrival (NAN to keep the walking direction). Can be negative: the
## world runs west of the camp.
var focus_x: float = NAN
## True for aimless wandering: the actor keeps its current goal until it reaches it.
var wander: bool = false


func has_focus() -> bool:
	return not is_nan(focus_x)
