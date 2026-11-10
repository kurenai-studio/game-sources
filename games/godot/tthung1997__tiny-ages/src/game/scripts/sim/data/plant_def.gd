class_name PlantDef
extends Resource
## A plant that grows from a seed item.

@export var id: StringName = &""
@export var display_name: String = ""
## The inventory item planted to grow this.
@export var seed_item: StringName = &""
## Ticks from planting until it flowers.
@export var ticks_to_flower: int = 72
@export_multiline var flower_text: String = ""
## World flag set when it flowers, so events can react to it.
@export var flower_flag: StringName = &""
@export var flower_achievement: StringName = &""
@export var flower_achievement_title: String = ""
