class_name CharacterData
extends Resource
## Data definition for a playable class. Stored as .tres in data/characters.

enum Ability { SHOCKWAVE, VOLLEY, BLINK_NOVA }

@export var id: StringName
@export var name_key: String
@export var desc_key: String
@export var ability_key: String
@export var color: Color = Color.WHITE
@export var shape_sides: int = 6
@export var max_hp: float = 100.0
@export var move_speed: float = 250.0
@export var damage: float = 12.0
@export var fire_rate: float = 3.0
@export var projectile_speed: float = 720.0
@export var pierce: int = 0
@export var ability: Ability = Ability.SHOCKWAVE
@export var ability_cooldown: float = 6.0
@export var ability_power: float = 40.0
@export var unlock_cost: int = 0
@export var sort_order: int = 0
