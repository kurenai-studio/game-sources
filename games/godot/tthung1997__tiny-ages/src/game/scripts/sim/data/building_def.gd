class_name BuildingDef
extends Resource
## A kind of building the settlement can construct.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Resources spent when construction starts.
@export var cost: Dictionary[StringName, int] = {}
## Builder-ticks of work needed to finish it.
@export var work_required: int = 30
## Resources produced per game day once complete.
@export var daily_output: Dictionary[StringName, float] = {}
## How many more villagers the camp holds once this is built.
@export var housing: int = 0
## What weather can reach it: `river` (floods), `dry` (droughts), `exposed` (storms). A tornado
## can reach any building.
@export var tags: Array[StringName] = []
@export_group("When completed")
@export var completion_flag: StringName = &""
@export var completion_achievement: StringName = &""
@export var completion_achievement_title: String = ""
