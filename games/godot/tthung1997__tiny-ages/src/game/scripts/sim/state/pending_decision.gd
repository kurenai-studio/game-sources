class_name PendingDecision
extends Resource
## A decision waiting for the player. It never expires or penalises waiting.

@export var id: StringName = &""
@export var event_id: StringName = &""
@export var subject_id: StringName = &""
@export var opened_tick: int = 0
