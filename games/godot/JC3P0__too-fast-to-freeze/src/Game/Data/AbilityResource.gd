class_name AbilityResource
extends Resource

## Flyweight - tunable config for one ability (axe/saw/hammer). One .tres
## per ability type, assigned to the matching AbilityController's `stats`
## export. Pure data, no behavior - mirrors PlayerStatsResource's role.
##
## test/timed-abilities branch. See Notes/TEST-TIMED-ABILITIES.md §3.

@export var id: StringName            # "axe" | "saw" | "hammer"
@export var display_name: String
@export var input_action: StringName  # "fire_axe" | "fire_saw" | "fire_hammer"
@export var icon: Texture2D

## Timed-abilities test - tween-based swing. Spins the whole character
## (Player4) 360 degrees, direction matched to whichever way the player is
## currently turning. swing_weapon_paths are this ability's weapon mesh
## pieces (relative to Player) to show for the duration of the spin, e.g.
## "Player4/Armature/Skeleton3D/RightArmLeftLower/axe_base". Leave empty to
## skip the swing entirely. See Notes/TEST-TIMED-ABILITIES.md.
@export var swing_weapon_paths: Array[String] = []
@export var swing_duration: float = 0.75

@export var start_stacks: int = 1
@export var max_stacks: int = 10      # tentative global cap - see Open Questions in the doc

@export var base_cooldown: float = 2.0
@export var min_cooldown: float = 0.4
@export var cooldown_decrease_per_stack: float = 0.15

@export var base_area_scale: float = 1.0
@export var max_area_scale: float = 4.0
@export var area_growth_per_stack: float = 0.3
