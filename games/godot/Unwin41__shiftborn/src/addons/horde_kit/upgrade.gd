@tool
class_name Upgrade
extends Resource
## One upgrade the player can pick on level-up. Managed by [UpgradePool].
## Game code reads [member id] and the level from the pool to apply the
## effect; this resource only holds data.

@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export_range(1, 99) var max_level: int = 5
## Relative chance to be offered. 0 means never offered.
@export_range(0.0, 100.0, 0.1) var weight: float = 1.0
## Offer filter. Untagged upgrades are shared and always eligible.
@export var tags: PackedStringArray = []
## Ids that need level 1 or higher before this upgrade is offered.
@export var requires: Array[StringName] = []
## Ids that must all be at max level before this upgrade is offered,
## e.g. an evolution that combines two maxed upgrades.
@export var requires_maxed: Array[StringName] = []
