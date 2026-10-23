extends Node2D
class_name NukeBomb

const NUKE_EXPLOSION_SCENE: PackedScene = preload("res://scenes/artifacts/nuke_explosion.tscn")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const SPRITE_FORWARD_ROTATION_OFFSET: float = PI * 0.5

@export_group("Homing")
@export_range(0.0, 3.0, 0.01) var deploy_duration: float = 0.18
@export_range(0.0, 12000.0, 10.0) var deploy_forward_speed: float = 1450.0
@export_range(0.0, 1.0, 0.01) var deploy_settle_duration: float = 0.05
@export_range(0.0, 12000.0, 10.0) var launch_speed: float = 180.0
@export_range(100.0, 24000.0, 50.0) var travel_speed: float = 2600.0
@export_range(100.0, 24000.0, 10.0) var acceleration: float = 3400.0
@export_range(1.0, 90.0, 1.0) var turn_speed: float = 4.0
@export_range(0.5, 20.0, 0.1) var lifetime: float = 8.0

@export_group("Impact")
@export_range(64.0, 6000.0, 10.0) var blast_radius: float = 700.0
@export_range(1, 999, 1) var damage: int = 30
@export_range(0.2, 12.0, 0.05) var explosion_duration: float = 10.0

@export_group("Ownership")
@export var deals_damage: bool = true
@export var owner_peer_id: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var jet: CPUParticles2D = get_node_or_null("FireSparkles") as CPUParticles2D

var _target_position: Vector2 = Vector2.ZERO
var _has_target: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _launch_direction: Vector2 = Vector2.ZERO
var _current_speed: float = 0.0
var _time_left: float = 0.0
var _deploy_time_left: float = 0.0
var _deploy_settle_time_left: float = 0.0
var _has_ignited: bool = false
var _trail_points: Array[Vector2] = []
var _trail_max_points: int = 18
var _detonated: bool = false
var _fog_alpha: float = 1.0
var _damage_config: Dictionary = {}


func _ready() -> void:
	_time_left = lifetime
	_set_jet_emitting(false)


func configure(
	launch_origin: Vector2,
	target_position: Vector2,
	effect_blast_radius: float,
	effect_damage: int,
	effect_travel_speed: float,
	effect_explosion_duration: float,
	should_deal_damage: bool,
	effect_owner_peer_id: int,
	launch_direction_value: Vector2 = Vector2.ZERO
) -> void:
	global_position = launch_origin
	_target_position = target_position
	blast_radius = maxf(effect_blast_radius, 1.0)
	damage = maxi(effect_damage, 1)
	travel_speed = maxf(effect_travel_speed, 1.0)
	explosion_duration = maxf(effect_explosion_duration, 0.1)
	deals_damage = should_deal_damage
	owner_peer_id = effect_owner_peer_id
	_has_target = true
	_launch_direction = launch_direction_value.normalized() if launch_direction_value != Vector2.ZERO else Vector2.ZERO
	_time_left = lifetime
	_deploy_time_left = deploy_duration
	_deploy_settle_time_left = deploy_settle_duration
	_has_ignited = false
	_current_speed = 0.0
	_velocity = Vector2.ZERO
	_trail_points.clear()
	_face_launch_direction()
	_set_jet_emitting(false)
	if is_zero_approx(_deploy_time_left):
		_ignite()
	queue_redraw()


func set_damage_config(damage_config: Dictionary) -> void:
	_damage_config = damage_config.duplicate()


func set_fog_presentation_alpha(alpha: float) -> void:
	_fog_alpha = clampf(alpha, 0.0, 1.0)
	visible = _fog_alpha > 0.01
	modulate = Color(1.0, 1.0, 1.0, _fog_alpha)
	queue_redraw()


func set_fog_presentation_visible(is_visible: bool) -> void:
	set_fog_presentation_alpha(1.0 if is_visible else 0.0)


func _physics_process(delta: float) -> void:
	if _detonated or not _has_target:
		return

	var safe_delta := maxf(delta, 0.0)
	_time_left = maxf(_time_left - safe_delta, 0.0)
	if _time_left <= 0.0:
		_detonate(global_position)
		return

	var movement_delta := safe_delta
	if _deploy_time_left > 0.0:
		var deploy_delta := minf(movement_delta, _deploy_time_left)
		_update_deploy_motion(deploy_delta)
		_deploy_time_left = maxf(_deploy_time_left - deploy_delta, 0.0)
		movement_delta = maxf(movement_delta - deploy_delta, 0.0)
		if _deploy_time_left > 0.0:
			return
		_velocity = Vector2.ZERO
		if _deploy_settle_time_left > 0.0 or is_zero_approx(movement_delta):
			return
		_ignite()

	if _deploy_settle_time_left > 0.0:
		var settle_delta := minf(movement_delta, _deploy_settle_time_left)
		_deploy_settle_time_left = maxf(_deploy_settle_time_left - settle_delta, 0.0)
		if _deploy_settle_time_left > 0.0:
			return
		_ignite()
		return

	_update_velocity(movement_delta)
	global_position += _velocity * movement_delta
	_update_trail()

	if _velocity != Vector2.ZERO:
		rotation = _velocity.angle() + SPRITE_FORWARD_ROTATION_OFFSET

	if global_position.distance_to(_target_position) <= _get_detonation_distance():
		_detonate(global_position)


func _draw() -> void:
	_draw_trail()


func _draw_trail() -> void:
	if _trail_points.size() < 2:
		return

	for index in range(1, _trail_points.size()):
		var previous := to_local(_trail_points[index - 1])
		var current := to_local(_trail_points[index])
		var progress := float(index) / float(maxi(_trail_points.size() - 1, 1))
		var alpha := progress * 0.42 * _fog_alpha
		var width := lerpf(2.0, 9.0, progress)
		draw_line(previous, current, Color(0.9, 0.98, 1.0, alpha), width, true)


func _face_launch_direction() -> void:
	var direction := _launch_direction
	if direction == Vector2.ZERO:
		direction = (_target_position - global_position).normalized()
	if direction == Vector2.ZERO:
		return

	rotation = direction.angle() + SPRITE_FORWARD_ROTATION_OFFSET


func _ignite() -> void:
	if _has_ignited:
		return

	_has_ignited = true
	_prime_velocity()
	_set_jet_emitting(true)
	GAME_SFX.play(self, GAME_SFX.CUE_MISSILE_LAUNCH)


func _prime_velocity() -> void:
	var launch_direction := _launch_direction
	if launch_direction == Vector2.ZERO:
		launch_direction = _get_forward_direction()

	_current_speed = minf(maxf(launch_speed, 0.0), travel_speed)
	_velocity = launch_direction * _current_speed
	if _velocity != Vector2.ZERO:
		rotation = _velocity.angle() + SPRITE_FORWARD_ROTATION_OFFSET


func _update_deploy_motion(delta: float) -> void:
	if deploy_forward_speed <= 0.0:
		return

	var launch_direction := _launch_direction
	if launch_direction == Vector2.ZERO:
		launch_direction = _get_forward_direction()
	global_position += launch_direction * deploy_forward_speed * delta
	rotation = launch_direction.angle() + SPRITE_FORWARD_ROTATION_OFFSET


func _update_velocity(delta: float) -> void:
	var travel_direction := _get_travel_direction()
	var desired_direction := (_target_position - global_position).normalized()
	if desired_direction != Vector2.ZERO:
		var max_turn_step := maxf(turn_speed, 0.0) * delta
		travel_direction = travel_direction.rotated(clampf(travel_direction.angle_to(desired_direction), -max_turn_step, max_turn_step))

	_current_speed = minf(_current_speed + acceleration * delta, travel_speed)
	_velocity = travel_direction * _current_speed


func _get_travel_direction() -> Vector2:
	if _velocity != Vector2.ZERO:
		return _velocity.normalized()

	return _get_forward_direction()


func _get_forward_direction() -> Vector2:
	var forward := Vector2.UP.rotated(rotation)
	if forward == Vector2.ZERO:
		return Vector2.UP

	return forward.normalized()


func _get_detonation_distance() -> float:
	return maxf(24.0, minf(blast_radius * 0.06, 140.0))


func _update_trail() -> void:
	if not _has_ignited:
		return

	_trail_points.append(global_position)
	while _trail_points.size() > _trail_max_points:
		_trail_points.pop_front()
	queue_redraw()


func _detonate(explosion_position: Vector2) -> void:
	if _detonated:
		return

	_detonated = true
	_set_jet_emitting(false)
	var parent_node := get_parent()
	if parent_node != null:
		var explosion := NUKE_EXPLOSION_SCENE.instantiate() as Node2D
		if explosion != null:
			if explosion.has_method("configure"):
				explosion.call(
					"configure",
					explosion_position,
					blast_radius,
					damage,
					explosion_duration,
					deals_damage,
					owner_peer_id,
					_damage_config
				)
			parent_node.add_child(explosion)
			if explosion.has_method("set_fog_presentation_alpha"):
				explosion.call("set_fog_presentation_alpha", _fog_alpha)

	queue_free()


func _set_jet_emitting(is_emitting: bool) -> void:
	if jet == null:
		return

	jet.emitting = is_emitting
