class_name ScheduledEvent
extends Resource
## An event queued to fire at a future tick, for a consequence that emerges later.

@export var event_id: StringName = &""
@export var subject_id: StringName = &""
@export var due_tick: int = 0
