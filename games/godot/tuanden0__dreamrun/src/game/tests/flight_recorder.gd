## Samples a PlayerController every physics frame and records physics that cannot be right, so a
## bot (scripted or random) can play and a test can read `violations` afterwards.
## Checks: NaN, teleporting, falling through the floor, free flight that is not ballistic,
## jumps higher than the jump allows, hard landings that never fired `landed`, and being stuck: holding a
## direction on open ground (no wall, nothing held) and not moving.
class_name FlightRecorder
extends RefCounted

## px per physics frame; faster than this without climbing is a teleport.
const MAX_STEP := 30.0
const BALLISTIC_TOLERANCE := 3.0
## Highest rise of a plain jump (the default jump apex is ~128 px).
const MAX_JUMP_RISE := 140.0
const MIN_LANDING_SPEED := 150.0
const FALL_THROUGH_Y := 150.0
## Frames of holding a direction on open ground without moving 1 px before it counts as stuck.
const STUCK_FRAMES := 45

var violations: Array[String] = []
## Highest rise of an airborne segment with no climb/rope involved, for tests.
var max_rise := 0.0

var _player: PlayerController
var _tree: SceneTree
var _frame := 0
var _has_prev := false
var _prev_pos := Vector2.ZERO
var _prev_vel := Vector2.ZERO
var _prev_state: StringName = &"idle"
var _prev_floor := true
var _landed := 0
var _landed_seen := 0
var _air_start_y := 0.0
var _air_min_y := 0.0
var _air_clean := true
var _push_frames := 0
var _push_x := 0.0


func _init(player: PlayerController, tree: SceneTree) -> void:
	_player = player
	_tree = tree


func start() -> void:
	_player.landed.connect(_on_landed)
	_tree.physics_frame.connect(_sample)


func stop() -> void:
	if _tree.physics_frame.is_connected(_sample):
		_tree.physics_frame.disconnect(_sample)
	if _player.landed.is_connected(_on_landed):
		_player.landed.disconnect(_on_landed)


func report(limit: int = 5) -> String:
	return "\n".join(violations.slice(0, limit))


## Climbing, hanging and dying move the body by code, so the free-flight and teleport checks do not apply.
func _is_held(state: StringName) -> bool:
	return state == &"climb" or state == &"hang" or state == &"die"


func _on_landed(_impact: float) -> void:
	_landed += 1


func _flag(message: String) -> void:
	violations.append("frame %d state=%s pos=%s: %s" % [_frame, _player.state, _player.global_position.round(), message])


func _sample() -> void:
	if _tree.paused:
		return  # nothing moves while the game is paused
	_frame += 1
	var pos := _player.global_position
	var vel := _player.velocity
	var state := _player.state
	var on_floor := _player.is_on_floor()
	if not (is_finite(pos.x) and is_finite(pos.y) and is_finite(vel.x) and is_finite(vel.y)):
		_flag("non-finite position or velocity")
		return
	if pos.y > FALL_THROUGH_Y:
		_flag("fell through the floor")
	if _has_prev:
		# Climbing/hanging snaps the body on purpose, and a respawn is a deliberate teleport.
		var attached := _is_held(state) or _is_held(_prev_state)
		if not attached and pos.distance_to(_prev_pos) > MAX_STEP:
			_flag("teleported %.0f px in one frame" % pos.distance_to(_prev_pos))
		var took_off := absf(vel.y - _player.jump_velocity) < 1.0  # a coyote or buffered jump in mid-air is allowed
		if not attached and not took_off and not on_floor and not _prev_floor and _player.get_slide_collision_count() == 0 \
				and vel.y < _player.max_fall_speed - 1.0 and _prev_vel.y < _player.max_fall_speed - 1.0:
			var expected := _player.gravity / Engine.physics_ticks_per_second
			if absf((vel.y - _prev_vel.y) - expected) > BALLISTIC_TOLERANCE:
				_flag("free flight not ballistic: dvy %.1f, gravity says %.1f" % [vel.y - _prev_vel.y, expected])
		if _prev_floor and not on_floor:
			_air_start_y = _prev_pos.y
			_air_min_y = pos.y
			_air_clean = true
		if not on_floor:
			_air_min_y = minf(_air_min_y, pos.y)
			if _is_held(state):
				_air_clean = false
		if on_floor and not _prev_floor:
			if _air_clean:
				max_rise = maxf(max_rise, _air_start_y - _air_min_y)
				if _air_start_y - _air_min_y > MAX_JUMP_RISE:
					_flag("rose %.0f px, more than a jump allows" % (_air_start_y - _air_min_y))
			if _prev_vel.y > MIN_LANDING_SPEED and _landed == _landed_seen and state != &"die":  # a body that died in the air just lies down
				_flag("hard landing at %.0f px/s without a landed signal" % _prev_vel.y)
	_check_stuck(pos, on_floor, state)
	_landed_seen = _landed
	_prev_pos = pos
	_prev_vel = vel
	_prev_state = state
	_prev_floor = on_floor
	_has_prev = true


## A wall, door, crate or the step in front of the player is a reason not to move; open ground is not.
func _check_stuck(pos: Vector2, on_floor: bool, state: StringName) -> void:
	var open := on_floor and Input.get_axis(&"move_left", &"move_right") != 0.0 and _player.grabbed == null 			and not _player.is_dead and not _is_held(state) and not _player.is_on_wall()
	if open:
		for i in _player.get_slide_collision_count():
			if absf(_player.get_slide_collision(i).get_normal().x) > 0.5:
				open = false
	if open and absf(pos.x - _push_x) < 1.0:
		_push_frames += 1
		if _push_frames == STUCK_FRAMES:
			_flag("stuck: held a direction for %d frames on open ground and did not move" % STUCK_FRAMES)
	else:
		_push_frames = 0
		_push_x = pos.x
