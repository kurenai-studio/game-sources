class_name ChoiceDef
extends Resource
## One option in a decision. Hidden or disabled in the UI until its requirements are met.

@export var id: StringName = &""
@export var label: String = ""
@export var requires: Array[SimCondition] = []
@export var effects: Array[SimEffect] = []
