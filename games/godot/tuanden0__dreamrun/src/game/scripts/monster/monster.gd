## The chasing monster: a huge dark mass with glowing eyes, a tail that drags behind it (follow-the-leader)
## and tentacles clawing ahead (FABRIK). It only walks at a fixed speed and kills on contact; menace comes
## from scale and silence. Origin is the ground under the head; it faces `direction` (1 = right).
class_name Monster
extends Node2D

signal started
signal stunned

@export var speed := 150.0
@export var direction := 1
## The chase ends (it stops) at this world x.
@export var stop_x := 3200.0
## After a respawn it restarts this far behind its checkpoint position, so it cannot kill on arrival.
@export var respawn_lead := 350.0
## How long `hit()` stops it.
@export var hit_stun := 2.0
@export var head_size := Vector2(150.0, 170.0)
@export var shape_seed := 77
@export var color := Color(0.01, 0.01, 0.012)
@export var eye_color := Color(0.85, 0.9, 1.0)
@export_group("Tail")
@export var tail_segments := 16
@export var tail_spacing := 38.0
@export var tail_width := 90.0
@export_group("Tentacles")
@export var tentacle_count := 5
@export var tentacle_joints := 8
@export var tentacle_joint_length := 24.0

var active := false

var _time := 0.0
var _stun_left := 0.0
## Set by subclasses while telegraphing an attack: the tentacles rear up like they do when stunned.
var _rearing := false
## Dead: the tentacles lie on the ground instead of clawing.
var _limp := false
var _saved_x := 0.0
var _saved_active := false
var _body: Polygon2D
var _reach: Area2D
var _tail: Line2D
var _tail_points := PackedVector2Array()
var _tentacles: Array[Line2D] = []
var _tentacle_joints: Array[PackedVector2Array] = []
var _tentacle_lengths := PackedFloat32Array()


func _ready() -> void:
	add_to_group(&"resettable")
	add_to_group(&"monster")
	scale.x = direction
	_saved_x = position.x
	visible = active  # a dormant monster is not part of the level; it appears when the chase starts
	_build_body()
	_build_eyes()
	_build_tentacles()
	_build_tail()


func start() -> void:
	if active:
		return
	active = true
	visible = true
	started.emit()


func stop() -> void:
	active = false


## Halts the chase and its killing reach for `seconds` (never shortens a stun already running).
func stun(seconds: float) -> void:
	if _stun_left <= 0.0:
		stunned.emit()
	_stun_left = maxf(_stun_left, seconds)


func is_stunned() -> bool:
	return _stun_left > 0.0


## A trap landed on it.
func hit() -> void:
	stun(hit_stun)


func save_checkpoint() -> void:
	_saved_x = position.x
	_saved_active = active


func reset_to_checkpoint() -> void:
	active = _saved_active
	visible = active
	position.x = _saved_x - direction * respawn_lead if _saved_active else _saved_x
	_stun_left = 0.0
	_reset_tail()


func _physics_process(delta: float) -> void:
	_time += delta
	_stun_left = maxf(_stun_left - delta, 0.0)
	if active and _stun_left <= 0.0:
		_advance(delta)
	_body.position.y = sin(_time * 2.2) * 6.0
	if _stun_left > 0.0:  # shudders in place
		_body.position.x = sin(_time * 60.0) * 4.0
	else:
		_body.position.x = 0.0
	_update_tail()
	_update_tentacles()


## One step of the monster's behaviour while it is active and not stunned; subclasses replace it.
func _advance(delta: float) -> void:
	position.x += direction * speed * delta
	if (direction > 0 and position.x >= stop_x) or (direction < 0 and position.x <= stop_x):
		active = false
	_kill_touching()


func _kill_touching() -> void:
	for body in _reach.get_overlapping_bodies():
		if body.is_in_group(&"player") and body.has_method(&"die"):
			body.die()


func _build_body() -> void:
	_body = Polygon2D.new()
	_body.polygon = SolidProp.build_outline(SolidProp.Kind.BOULDER, head_size, shape_seed, 10.0)
	_body.color = color
	_body.antialiased = true
	add_child(_body)
	_reach = Area2D.new()
	var zone := CollisionShape2D.new()
	zone.shape = CircleShape2D.new()
	zone.shape.radius = head_size.y * 0.5
	zone.position = Vector2(head_size.x * 0.15, -head_size.y * 0.5)
	_reach.add_child(zone)
	add_child(_reach)


func _build_eyes() -> void:
	var glow := CanvasItemMaterial.new()
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for i in 2:
		var eye := Polygon2D.new()
		var points := PackedVector2Array()
		for k in 10:
			points.append(Vector2.from_angle(TAU * k / 10.0) * Vector2(7.0, 4.0 - i))
		eye.polygon = points
		eye.color = eye_color
		eye.material = glow
		eye.position = Vector2(head_size.x * (0.34 - 0.2 * i), -head_size.y * (0.72 + 0.04 * i))
		_body.add_child(eye)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var light := PointLight2D.new()
	light.texture = texture
	light.texture_scale = 2.2
	light.energy = 0.5
	light.color = eye_color
	light.position = Vector2(head_size.x * 0.3, -head_size.y * 0.72)
	_body.add_child(light)


func _build_tentacles() -> void:
	for i in tentacle_count:
		var line := Line2D.new()
		line.width = 7.0
		line.default_color = color
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		line.width_curve = _taper_curve(1.0, 0.25)
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(line)
		_tentacles.append(line)
		var joints := PackedVector2Array()
		for j in tentacle_joints:
			joints.append(_tentacle_root(i) + Vector2(j * tentacle_joint_length, 0.0))
		_tentacle_joints.append(joints)
	for j in tentacle_joints - 1:
		_tentacle_lengths.append(tentacle_joint_length)


func _build_tail() -> void:
	_tail = Line2D.new()
	_tail.top_level = true  # points are in world space so the tail trails behind a moving head
	_tail.width = tail_width
	_tail.default_color = color
	_tail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_tail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_tail.width_curve = _taper_curve(1.0, 0.06)
	add_child(_tail)
	_reset_tail()


func _taper_curve(from_value: float, to_value: float) -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, from_value))
	curve.add_point(Vector2(1.0, to_value))
	return curve


func _tail_anchor() -> Vector2:
	return to_global(Vector2(-head_size.x * 0.4, -head_size.y * 0.3))


func _reset_tail() -> void:
	if _tail == null:
		return
	_tail_points.resize(tail_segments)
	var anchor := _tail_anchor()
	for i in tail_segments:
		_tail_points[i] = anchor + Vector2(-direction * i * tail_spacing, 0.0)
	_tail.points = _tail_points


## Follow-the-leader: each segment keeps its spacing from the one in front and sags toward the ground.
func _update_tail() -> void:
	_tail_points[0] = _tail_anchor()
	for i in range(1, tail_segments):
		var prev := _tail_points[i - 1]
		var offset := _tail_points[i] - prev
		if offset.length_squared() < 0.0001:
			offset = Vector2(-direction, 0.0)
		var p := prev + offset.normalized() * tail_spacing
		var sag := global_position.y - tail_width * 0.2 + sin(_time * 3.0 + i * 0.8) * 10.0 * i / tail_segments
		p.y = lerpf(p.y, sag, 0.25)
		_tail_points[i] = p
	_tail.points = _tail_points


func _tentacle_root(index: int) -> Vector2:
	return Vector2(head_size.x * 0.32, -head_size.y * (0.3 + 0.08 * index))


## Each tentacle claws at the ground ahead in a slow wave, offset from its neighbours.
func _update_tentacles() -> void:
	for i in tentacle_count:
		var phase := _time * 2.0 + i * 1.3
		var target := Vector2(head_size.x * 0.5 + 60.0 + i * 26.0 + sin(phase * 1.3) * 35.0, -absf(sin(phase)) * 55.0)
		if _stun_left > 0.0 or _rearing:  # tentacles recoil up and back
			target = Vector2(head_size.x * 0.1 + i * 12.0, -head_size.y - 40.0 - i * 18.0)
		if _limp:
			target = Vector2(head_size.x * 0.3 + 20.0 + i * 14.0, -3.0)
		_tentacle_joints[i] = FabrikChain.solve(_tentacle_joints[i], _tentacle_lengths, _tentacle_root(i), target)
		_tentacles[i].points = _tentacle_joints[i]
