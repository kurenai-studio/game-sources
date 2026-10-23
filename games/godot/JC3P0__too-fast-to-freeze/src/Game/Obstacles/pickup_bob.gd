extends Node3D

## Timed-abilities test - idle bob + sway for pickups (axe/hammer/saw).
## Attach this to a wrapper Node3D that holds ONLY a pickup's visual mesh
## pieces - never to the pickup's CharacterBody3D root. obstacle_move.gd
## drives that root's position every physics frame via velocity/
## move_and_slide(), so animating the root directly here would fight that
## movement, the same class of bug as the earlier turn-animation and
## swing-rotation conflicts. Keeping this on a separate visual-only child
## sidesteps that entirely.
##
## Uses continuous sine waves rather than a looping Tween, so there's no
## restart hitch and position/rotation always stay perfectly smooth.
## bob_height/bob_speed/sway_angle_degrees/sway_speed are all tunable in
## the Inspector per pickup. Bobbing only ever moves UP from wherever this
## node was placed in the scene (never down), so pickups never dip into
## the ground, no repositioning needed in the scene itself. Rotation sways
## from -sway_angle_degrees to +sway_angle_degrees and back, centered on
## whatever rotation this node already had.
## See Notes/TEST-TIMED-ABILITIES.md.

@export var bob_height: float = 0.75
@export var bob_speed: float = 2.5
@export var sway_angle_degrees: float = 45.0
@export var sway_speed: float = 1.2

var _base_position: Vector3
var _base_rotation_y: float
var _time: float = 0.0

func _ready() -> void:
	_base_position = position
	_base_rotation_y = rotation.y

func _process(delta: float) -> void:
	_time += delta
	# Remap sin()'s -1..1 range to 0..1 so the bob only ever adds height,
	# never subtracts it - starts at _base_position.y (t=0 -> sin=0 -> 0
	# added) and never goes below it.
	var bob_offset: float = (sin(_time * bob_speed) * 0.5 + 0.5) * bob_height
	position.y = _base_position.y + bob_offset
	rotation.y = _base_rotation_y + sin(_time * sway_speed) * deg_to_rad(sway_angle_degrees)
