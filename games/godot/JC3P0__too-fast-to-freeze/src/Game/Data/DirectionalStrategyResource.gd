class_name DirectionalStrategyResource
extends Resource

## Tunable settings for DirectionalStrategy.
## Assign a .tres instance to the Player node's [member directional_stats] export.

## Top speed when skiing straight.
@export var max_speed: float = 18.0

## How fast speed ramps up to max in IDLE/TURNING (units/sec).
@export var acceleration: float = 5.0

## Direction lerp step per frame when actively steering — lower = lazier, floatier.
@export var turn_acceleration: float = 0.05

## Direction lerp step per frame when returning to center after release — should be slower than turn_acceleration.
@export var release_turn_acceleration: float = 0.04

## Maximum yaw angle from straight ahead (degrees).
@export var max_turn_angle: float = 60.0

## Speed gained per second during RELEASED (the boost window).
@export var boost_acceleration: float = 2.6

## Speed lost per second decaying back to max_speed after RELEASED.
@export var boost_deceleration: float = 0.8

## Absolute speed ceiling — boost will not push above this.
@export var boost_max_speed: float = 25.0
