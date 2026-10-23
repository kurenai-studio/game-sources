class_name DirectionalStrategy
extends InputStrategy

## Directional drag/angle control system — ported from WildJam76 player_mobile.gd.
## States: IDLE (no input) → TURNING (drag/key held) → RELEASED (boost window).
## During RELEASED, speed accumulates freely — far turn = longer return = more boost.
## Sets player.player_direction (Vector3) and player.player_current_speed each frame.

## Assign a DirectionalStrategyResource .tres in the Inspector (on the DirectionalStrategy node).
@export var settings: DirectionalStrategyResource

# --- State machine ---
enum State { IDLE, TURNING, RELEASED }
var _state: State = State.IDLE

# --- Drag tracking ---
var _touch_start_pos: Vector2 = Vector2.ZERO
var _touch_current_pos: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _max_drag_distance: float = 0.0

# --- Movement ---
var _current_speed: float = 0.0
var _current_direction: Vector3 = Vector3(0, 0, 1)
var _target_direction: Vector3 = Vector3(0, 0, 1)
const _DEFAULT_DIRECTION := Vector3(0, 0, 1)

# --- Model reference (lazy-init) ---
var _model: Node3D = null


func _ready() -> void:
	_max_drag_distance = get_viewport().get_visible_rect().size.x / 5.0


# Called from player.gd _input()
func handle_input_event(_player: CharacterBody3D, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_start_pos = event.position
			_touch_current_pos = event.position
			_is_dragging = true
		else:
			_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		_touch_current_pos = event.position


# Called from player.gd _physics_process()
func process_input(player: CharacterBody3D, delta: float) -> void:
	if _model == null:
		_model = player.get_node_or_null("Player4")

	# Hit freeze — stop everything while vulnerable
	if player.player_state_manager.current_state_name == "Vuln":
		_current_speed = 0.0
		_current_direction = _DEFAULT_DIRECTION
		_target_direction = _DEFAULT_DIRECTION
		_state = State.IDLE
		player.player_direction = _DEFAULT_DIRECTION
		player.player_current_speed = 0.0
		player.player_speed = 0.0
		return

	# Keyboard input
	var key_turn: float = 0.0
	if Input.is_action_pressed("Turn_Right"):
		key_turn = 1.0
	elif Input.is_action_pressed("Turn_Left"):
		key_turn = -1.0

	var is_steering: bool = _is_dragging or key_turn != 0.0

	match _state:
		State.IDLE:
			_target_direction = _DEFAULT_DIRECTION
			_ramp_speed(delta)
			if is_steering:
				_state = State.TURNING

		State.TURNING:
			if is_steering:
				_ramp_speed(delta)
				if key_turn != 0.0:
					var angle_rad: float = deg_to_rad(settings.max_turn_angle * key_turn * -1.0)
					_target_direction = Vector3(sin(angle_rad), 0.0, cos(angle_rad)).normalized()
				elif _is_dragging and _touch_current_pos != _touch_start_pos:
					var drag_vector: Vector2 = _touch_current_pos - _touch_start_pos
					var limited_x: float = clamp(drag_vector.x, -_max_drag_distance, _max_drag_distance)
					var normalized_x: float = limited_x / _max_drag_distance
					var turn_angle_deg: float = settings.max_turn_angle * normalized_x * -1.0
					var angle_rad: float = deg_to_rad(turn_angle_deg)
					_target_direction = Vector3(sin(angle_rad), 0.0, cos(angle_rad)).normalized()
			else:
				_state = State.RELEASED

		State.RELEASED:
			_target_direction = _DEFAULT_DIRECTION
			if not _current_direction.is_equal_approx(_DEFAULT_DIRECTION):
				# Still returning to center — accumulate boost up to ceiling
				if _current_speed < settings.boost_max_speed:
					_current_speed += settings.boost_acceleration * delta
					_current_speed = min(_current_speed, settings.boost_max_speed)
			else:
				# Reached forward — stop boosting, back to IDLE
				_state = State.IDLE

			if is_steering:
				_state = State.TURNING

	# Advance direction toward target.
	# RELEASED uses its own slower return speed — keeps the boost glide feeling weighty.
	# Active turning scales with speed: floaty at low, committed at high.
	var turn_step: float
	if _state == State.RELEASED:
		turn_step = settings.release_turn_acceleration
	else:
		var speed_factor: float = clamp(_current_speed / settings.max_speed, 0.0, 2.0)
		turn_step = settings.turn_acceleration * lerp(0.75, 1.5, speed_factor)
	_current_direction = _current_direction.move_toward(
		_target_direction.normalized(), turn_step
	)

	# Single speed update — one place, clear rules:
	# RELEASED + not at center → boost (handled above in state match)
	# Above max anywhere else  → decay back toward max
	# Below max anywhere       → ramp up (handled in _ramp_speed)
	if _state != State.RELEASED and _current_speed > settings.max_speed:
		_current_speed = move_toward(_current_speed, settings.max_speed, settings.boost_deceleration * delta)

	# Rotate model to face direction of travel
	if _model != null:
		var yaw: float = rad_to_deg(atan2(_current_direction.x, _current_direction.z))
		_model.rotation_degrees.y = yaw + 180.0

	# Write to player
	player.player_direction = _current_direction
	player.player_current_speed = _current_speed
	player.player_speed = _current_speed


func get_strategy_name() -> String:
	return "Directional"


func _ramp_speed(delta: float) -> void:
	# Only ramp UP — if above max_speed (from boost), let boost_deceleration handle the decay
	if _current_speed < settings.max_speed:
		_current_speed = move_toward(_current_speed, settings.max_speed, settings.acceleration * delta)
