## Swinging rope (analytic pendulum). The player grabs the grip in mid-air with interact, keeps the
## swing going by holding left/right, and releases with jump. Origin is the anchor point.
class_name Rope
extends Node2D

@export var length := 260.0
@export var gravity := 1500.0
## Energy loss per second; the swing dies out unless the player pumps.
@export var damping := 0.35
## Angular acceleration (rad/s^2) while the player pushes along the swing direction.
@export var pump_strength := 4.0
## Pumping stops once the swing holds as much energy as a swing of this amplitude, so it tops out here.
@export var pump_limit_deg := 55.0
@export var start_angle_deg := 0.0
@export var color := Color(0.03, 0.03, 0.035)

var angle := 0.0
var omega := 0.0
var attached := false

var _pump := 0.0
var _line: Line2D
var _grip: Area2D
var _knot: Polygon2D


func save_checkpoint() -> void:
	pass  # a rope always restarts from its resting swing


func reset_to_checkpoint() -> void:
	attached = false
	angle = deg_to_rad(start_angle_deg)
	omega = 0.0


func _ready() -> void:
	add_to_group(&"resettable")
	angle = deg_to_rad(start_angle_deg)
	_line = Line2D.new()
	_line.width = 4.0
	_line.default_color = color
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_line)
	_knot = Polygon2D.new()
	var points := PackedVector2Array()
	for k in 10:
		points.append(Vector2.from_angle(TAU * k / 10.0) * Vector2(9.0, 12.0))
	_knot.polygon = points
	_knot.color = color
	_knot.antialiased = true
	add_child(_knot)
	_grip = Area2D.new()
	_grip.add_to_group(&"rope_grip")
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 30.0
	_grip.add_child(shape)
	add_child(_grip)
	_place_bob()


## The player grabbed on with this velocity: its momentum along the swing becomes angular speed.
func attach(player_velocity: Vector2) -> void:
	attached = true
	omega += player_velocity.dot(Vector2(cos(angle), -sin(angle))) / length


func release() -> void:
	attached = false
	_pump = 0.0


## Player input while hanging: -1..1. Only pushes along the current swing direction (pumping).
func pump(axis: float) -> void:
	_pump = axis


func bob_position() -> Vector2:
	return global_position + Vector2(sin(angle), cos(angle)) * length


func bob_velocity() -> Vector2:
	return Vector2(cos(angle), -sin(angle)) * length * omega


func _physics_process(delta: float) -> void:
	var alpha := -(gravity / length) * sin(angle) - damping * omega
	var sway := gravity / length
	var energy := 0.5 * omega * omega + sway * (1.0 - cos(angle))
	if attached and _pump != 0.0 and energy < sway * (1.0 - cos(deg_to_rad(pump_limit_deg))) \
			and (signf(_pump) == signf(omega) or absf(omega) < 0.2):
		alpha += _pump * pump_strength
	omega += alpha * delta
	angle += omega * delta
	_place_bob()


func _place_bob() -> void:
	var tip := Vector2(sin(angle), cos(angle)) * length
	# Slight fixed kinks so the rope is not a ruler-straight line.
	var points := PackedVector2Array()
	for k in 9:
		var t := k / 8.0
		points.append(tip * t + tip.orthogonal().normalized() * sin(t * 17.0) * 1.6 * t * (1.0 - t) * 4.0)
	_line.points = points
	_knot.position = tip
	_grip.position = tip
