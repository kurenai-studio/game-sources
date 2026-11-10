class_name JournalEntry
extends Resource
## One line of the world journal: the settlement's remembered history.

@export var tick: int = 0
@export var day: int = 0
@export_multiline var text: String = ""
## Matches the category of the event that produced it (character, nature, settlement...).
@export var kind: StringName = &"settlement"
@export var event_id: StringName = &""
@export var subject_id: StringName = &""
