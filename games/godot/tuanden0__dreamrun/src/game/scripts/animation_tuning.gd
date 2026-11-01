## Every procedural-animation value in one place; tweak the .tres by eye in the inspector.
class_name AnimationTuning
extends Resource

@export_group("Legs")
## Fraction of full leg length used for the standing hip height (<1 keeps knees bent).
@export_range(0.7, 1.0) var stance := 0.96
## Foot travel half-range at standstill speed / at run speed (px). Also sets cadence: one cycle = 4 x this.
@export var step_min := 20.0
@export var step_max := 34.0
@export var step_height := 12.0
@export var idle_foot_spread := 12.0
@export var air_foot_spread := 10.0
## Leg extension (fraction of leg length) while rising / falling.
@export_range(0.3, 1.0) var jump_leg_reach := 0.7
@export_range(0.3, 1.0) var fall_leg_reach := 0.88
## Higher = feet follow their targets faster.
@export var limb_smoothing := 25.0
@export_group("Body")
@export var hip_bob := 3.0
@export var lean_deg := 9.0
@export var breathe_amount := 1.2
@export var breathe_rate := 1.6
@export_group("Arms")
@export var arm_swing_deg := 40.0
@export var elbow_bend_deg := 25.0
@export var air_arm_raise_deg := 55.0
@export var arm_spring_stiffness := 180.0
@export var arm_spring_damping := 11.0
@export_group("Push, pull, climb")
## Body lean while pushing (forward) / pulling (backward), degrees.
@export var push_lean_deg := 12.0
@export var pull_lean_deg := 3.0
## While holding a crate: knees bend this many px so the shoulders drop to the crate, and the hands rest this far below its top.
@export var grab_crouch := 14.0
@export var grab_hand_drop := 8.0
## Arm angle while climbing (-90 = straight up).
@export var climb_arm_deg := -80.0
## Ledge climb: arm angle while pushing off the top, forearm bend while pulling, forward lean, leg scramble (px).
@export var climb_push_arm_deg := 50.0
@export var climb_elbow_deg := 80.0
@export var climb_lean_deg := 28.0
@export var climb_kick := 7.0
@export_group("Landing")
## How far the hips drop on a hard landing (px, at full impact) and how fast they recover (px/s).
@export var land_crouch := 18.0
@export var land_recover_speed := 80.0
## Falls slower than this (px/s) do not crouch.
@export var land_min_speed := 150.0
@export_group("Death")
## Degrees the body topples forward, and how far the hips crumple (px).
@export var die_lean_deg := 82.0
@export var die_drop := 26.0
@export_group("Squash and stretch")
@export var land_squash := 0.25
@export var jump_stretch := 0.18
## Fall speed (px/s) that gives full land_squash.
@export var squash_ref_speed := 800.0
@export var squash_stiffness := 260.0
@export var squash_damping := 16.0
