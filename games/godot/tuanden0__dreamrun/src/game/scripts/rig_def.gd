## Proportions and color of a procedural silhouette character. One .tres per character.
class_name RigDef
extends Resource

@export var head_radius := 13.0
@export var torso_size := Vector2(24.0, 34.0)
@export var upper_leg := 24.0
@export var lower_leg := 24.0
@export var upper_arm := 16.0
@export var lower_arm := 15.0
@export_group("Limb thickness")
@export var thigh_width := 11.0
@export var ankle_width := 5.0
@export var arm_width := 7.0
@export var wrist_width := 4.0
@export var hand_radius := 4.0
@export_group("Feet and face")
## Distance from ankle joint to sole; the hip stands this much higher.
@export var ankle_height := 5.0
@export var shoe_length := 13.0
@export var hair_spikes := 6
@export var eye_color := Color(1.0, 1.0, 1.0)
@export var color := Color(0.02, 0.02, 0.02)


func leg_length() -> float:
	return upper_leg + lower_leg
