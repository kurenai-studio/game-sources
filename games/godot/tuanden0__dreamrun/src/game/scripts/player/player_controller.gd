## Platformer movement + state machine. Knows nothing about art: it only emits signals
## (state_changed, moved, landed) that a child named "Visual" may listen to.
## Interactions use a child Area2D named "GrabZone" and groups: usable (levers), grabbable (crates),
## ledge, rope_grip.
class_name PlayerController
extends CharacterBody2D

signal state_changed(state: StringName)
signal moved(velocity: Vector2, run_ratio: float, facing: int, on_floor: bool)
signal landed(impact_speed: float)
## 0..1 while climbing onto a ledge; the visual poses the climb from it.
signal climb_progress(t: float)
## While holding a crate: how far ahead its near face is (px, in the facing direction) and how high its top is above
## our feet, so the hands can land on it. distance is -1 once we let go.
signal grab_contact(distance: float, top: float)
signal died
signal respawned

@export_group("Movement")
@export var walk_speed := 120.0
@export var run_speed := 260.0
## Seconds of held input before walk becomes run.
@export var run_ramp_time := 0.6
@export var acceleration := 1400.0
@export var friction := 1800.0
@export_group("Jump")
@export var jump_velocity := -620.0
@export var gravity := 1500.0
@export var max_fall_speed := 900.0
@export var coyote_time := 0.1
@export var buffer_time := 0.1
## Seconds the "land" state lasts after touching down.
@export var land_time := 0.12
@export_group("Interaction")
## Top speed while pushing or pulling a crate.
@export var grab_speed := 80.0
## Distance from the rope grip down to the feet while hanging.
@export var hang_offset := 78.0
@export var climb_time := 1.0
## The crate is let go if it ends up this far (px, centre to centre) from us, e.g. stuck while we pulled.
@export var grab_break_distance := 110.0
## Seconds after letting go before the same rope can be grabbed again.
@export var rope_regrab_delay := 0.5

var state: StringName = &"idle"
## The crate currently held (interact key), or null.
var grabbed: RigidBody2D
var is_dead := false

var _timers := JumpTimers.new()
var _run_t := 0.0
var _land_left := 0.0
var _facing := 1
var _usables: Array[Node2D] = []
var _grabbables: Array[Node2D] = []
var _ledge: Ledge
var _rope_near: Rope
var _rope: Rope
var _rope_cooldown := 0.0
var _climbing := false
var _climb_tween: Tween
var _climb_from := Vector2.ZERO
var _climb_hang := Vector2.ZERO
var _climb_hug := Vector2.ZERO
var _climb_top := Vector2.ZERO


func _ready() -> void:
	add_to_group(&"player")
	_timers.coyote_time = coyote_time
	_timers.buffer_time = buffer_time
	var zone := get_node_or_null(^"GrabZone") as Area2D
	if zone != null:
		zone.area_entered.connect(_on_zone_area_entered)
		zone.area_exited.connect(_on_zone_area_exited)
		zone.body_entered.connect(_on_zone_body_entered)
		zone.body_exited.connect(_on_zone_body_exited)


func _physics_process(delta: float) -> void:
	_rope_cooldown = maxf(_rope_cooldown - delta, 0.0)
	if is_dead:
		_fall_dead(delta)
		return
	if _climbing:
		moved.emit(Vector2.ZERO, 0.0, _facing, false)
		return
	if _rope != null:
		_swing()
		return
	_update_interaction()
	if _climbing or _rope != null:
		return

	var axis := Input.get_axis(&"move_left", &"move_right")
	if axis != 0.0:
		if grabbed == null:
			_facing = 1 if axis > 0.0 else -1
		_run_t = minf(_run_t + delta / run_ramp_time, 1.0)
	else:
		_run_t = 0.0
	var top_speed := grab_speed if grabbed != null else lerpf(walk_speed, run_speed, _run_t)
	var rate := acceleration if axis != 0.0 else friction
	velocity.x = move_toward(velocity.x, axis * top_speed, rate * delta)

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	_timers.update(delta, is_on_floor(), Input.is_action_just_pressed(&"jump"))
	if _timers.consume_jump():
		_release_crate()
		velocity.y = jump_velocity

	# Pushing: the crate moves first and a blocked crate stops us too. Pulling: it follows how far we really got.
	var pushing := grabbed != null and absf(velocity.x) > 0.0 \
			and signf(velocity.x) == signf(grabbed.global_position.x - global_position.x)
	if pushing:
		velocity.x = (grabbed as Crate).shove(velocity.x * delta) / delta

	var was_on_floor := is_on_floor()
	var fall_speed := velocity.y
	var before_x := global_position.x
	move_and_slide()
	if grabbed != null:
		if not pushing:
			(grabbed as Crate).shove(global_position.x - before_x)
		(grabbed as Crate).settle(delta)
		var crate := grabbed as Crate
		grab_contact.emit((crate.global_position.x - global_position.x) * _facing - crate.size.x * 0.5,
				global_position.y - crate.global_position.y + crate.size.y * 0.5)
		if absf(grabbed.global_position.x - global_position.x) > grab_break_distance:
			_release_crate()
	if is_on_floor() and not was_on_floor:
		_land_left = land_time
		landed.emit(fall_speed)
	_land_left = maxf(_land_left - delta, 0.0)

	_set_state(_pick_state(axis))
	moved.emit(velocity, absf(velocity.x) / run_speed, _facing, is_on_floor())


## Called by whatever kills the player (the monster). The collapse plays out until the manager respawns us.
func die() -> void:
	if is_dead:
		return
	_release_crate()
	if _rope != null:
		_rope.release()
		_rope = null
	if _climb_tween != null:
		_climb_tween.kill()
	_climbing = false
	is_dead = true
	velocity.x *= 0.3
	_set_state(&"die")
	died.emit()


func respawn(at: Vector2) -> void:
	is_dead = false
	global_position = at
	velocity = Vector2.ZERO
	_run_t = 0.0
	_land_left = 0.0
	_set_state(&"idle")
	respawned.emit()


func _fall_dead(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	move_and_slide()
	moved.emit(velocity, 0.0, _facing, is_on_floor())


func _update_interaction() -> void:
	if grabbed != null and (not Input.is_action_pressed(&"interact") or not is_on_floor()):
		_release_crate()
	if Input.is_action_just_pressed(&"interact"):
		if _rope_near != null and not is_on_floor() and _rope_cooldown <= 0.0:
			_rope = _rope_near
			_rope.attach(velocity)
			_set_state(&"hang")  # hanging from this very frame
		elif not _usables.is_empty():
			_usables[0].call(&"interact")
		elif grabbed == null and not _grabbables.is_empty() and is_on_floor():
			_grab_crate(_grabbables[0] as RigidBody2D)
	# Jump toward a platform (or hold up) and the hands catch its edge once they reach it.
	if _can_catch_ledge():
		_start_climb(_ledge)


## The hands are at the edge of a ledge we are in front of, in mid-air, reaching for it.
func _can_catch_ledge() -> bool:
	if _ledge == null or grabbed != null or is_on_floor():
		return false
	if global_position.x >= _ledge.top_position().x:  # already over it: never grab from the platform side
		return false
	return _ledge.can_grab(global_position.y) and _reaching_for(_ledge)


## Pressing toward the platform (or up) means the player wants to catch the edge; walking off it the other way does not.
func _reaching_for(ledge: Ledge) -> bool:
	var toward := signf(ledge.top_position().x - global_position.x)
	return signf(Input.get_axis(&"move_left", &"move_right")) == toward or Input.is_action_pressed(&"climb_up")


func _grab_crate(crate: RigidBody2D) -> void:
	grabbed = crate
	(crate as Crate).hold()
	add_collision_exception_with(crate)  # code keeps the gap constant, so we never need to touch
	_facing = 1 if crate.global_position.x > global_position.x else -1


func _release_crate() -> void:
	if grabbed == null:
		return
	remove_collision_exception_with(grabbed)
	(grabbed as Crate).drop()
	grabbed = null
	grab_contact.emit(-1.0, 0.0)


func _swing() -> void:
	_rope.pump(Input.get_axis(&"move_left", &"move_right"))
	global_position = _rope.bob_position() + Vector2(0.0, hang_offset)
	velocity = _rope.bob_velocity()
	if absf(velocity.x) > 20.0:
		_facing = 1 if velocity.x > 0.0 else -1
	_set_state(&"hang")
	if Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"interact"):
		_rope.release()
		_rope = null
		_rope_cooldown = rope_regrab_delay
		# No extra jump: the player leaves with the rope's own velocity, gravity does the rest.
	moved.emit(velocity, 0.0, _facing, false)


## Ledge climb: catch the edge with the hands and hang (t 0..0.3), pull up the wall until the knee is
## at the edge (0.3..0.65), then roll over onto the top (0.65..1). Never slides sideways while low.
func _start_climb(ledge: Ledge) -> void:
	_climbing = true
	velocity = Vector2.ZERO
	_climb_from = global_position
	_climb_top = ledge.top_position()
	_climb_hang = ledge.hang_position()
	_climb_hug = ledge.hug_position()
	_facing = 1 if _climb_top.x > global_position.x else -1
	_set_state(&"climb")
	_climb_tween = create_tween()
	_climb_tween.tween_method(_apply_climb, 0.0, 1.0, climb_time)
	_climb_tween.tween_callback(func() -> void: _climbing = false)


func _apply_climb(t: float) -> void:
	if t < 0.3:  # the jump's momentum is caught by the hands: ease out onto the hang point, then hang
		var grab := minf(t / 0.2, 1.0)
		global_position = _climb_from.lerp(_climb_hang, 1.0 - (1.0 - grab) * (1.0 - grab))
	elif t < 0.65:
		global_position = _climb_hang.lerp(_climb_hug, smoothstep(0.3, 0.65, t))
	else:
		global_position = _climb_hug.lerp(_climb_top, smoothstep(0.65, 1.0, t))
	climb_progress.emit(t)


func _pick_state(axis: float) -> StringName:
	if not is_on_floor():
		return &"jump" if velocity.y < 0.0 else &"fall"
	if grabbed != null:
		if absf(velocity.x) < 5.0:
			return &"idle"
		var toward := signf(grabbed.global_position.x - global_position.x)
		return &"push" if signf(velocity.x) == toward else &"pull"
	if _land_left > 0.0:
		return &"land"
	if axis == 0.0 and absf(velocity.x) < 5.0:
		return &"idle"
	return &"run" if _run_t > 0.5 else &"walk"


func _set_state(next: StringName) -> void:
	if next == state:
		return
	state = next
	state_changed.emit(state)


func _on_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group(&"usable"):
		_usables.append(area)
	elif area.is_in_group(&"ledge"):
		_ledge = area as Ledge
	elif area.is_in_group(&"rope_grip"):
		_rope_near = area.get_parent() as Rope


func _on_zone_area_exited(area: Area2D) -> void:
	_usables.erase(area)
	if area == _ledge:
		_ledge = null
	if area.get_parent() == _rope_near:
		_rope_near = null


func _on_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"grabbable"):
		_grabbables.append(body)


func _on_zone_body_exited(body: Node2D) -> void:
	_grabbables.erase(body)
