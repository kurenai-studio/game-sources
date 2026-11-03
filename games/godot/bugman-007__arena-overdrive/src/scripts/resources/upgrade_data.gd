class_name UpgradeData
extends Resource
## A roguelite upgrade card. Stored as .tres in data/upgrades.

enum Rarity { COMMON, RARE, EPIC }
enum Mode { ADD, MULTIPLY }

@export var id: StringName
@export var name_key: String
@export var desc_key: String
@export var rarity: Rarity = Rarity.COMMON
@export var stat: StringName
@export var mode: Mode = Mode.MULTIPLY
@export var amount: float = 0.1
@export var max_stacks: int = 5
@export var icon_color: Color = Color.WHITE
