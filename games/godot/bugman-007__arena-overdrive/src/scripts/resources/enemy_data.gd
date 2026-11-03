class_name EnemyData
extends Resource
## Data definition for an enemy archetype. Stored as .tres in data/enemies.

enum Behavior { CHASER, SHOOTER, TANK, EXPLODER, BOSS }

@export var id: StringName
@export var name_key: String
@export var behavior: Behavior = Behavior.CHASER
@export var color: Color = Color(1, 0.5, 0.2)
@export var shape_sides: int = 4
@export var radius: float = 14.0
@export var max_hp: float = 30.0
@export var speed: float = 140.0
@export var damage: int = 10
@export var attack_range: float = 34.0
@export var detect_range: float = 2000.0
@export var attack_cooldown: float = 0.8
@export var projectile_speed: float = 320.0
@export var explode_radius: float = 0.0
@export var knockback_resist: float = 0.0
@export var xp: int = 2
@export var coin_chance: float = 0.2
@export var score: int = 10
@export var min_wave: int = 1
@export var spawn_weight: float = 1.0
@export var cost: int = 1
