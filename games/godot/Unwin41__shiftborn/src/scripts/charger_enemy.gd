class_name ChargerEnemy
extends Enemy
## Beast: walks in, then stops, shows a red line where it will go and
## charges along it. The charge is the moment for a perfect shift.

enum State { WALK, WINDUP, CHARGE, REST }

const TRIGGER_DISTANCE := 100.0
const WINDUP_TIME := 0.6
const CHARGE_TIME := 0.5
const CHARGE_SPEED := 240.0
## Recovery after a charge before it can wind up again.
const REST_TIME := 1.2
const WINDUP_TINT := Color(1.8, 0.7, 0.7)
const LINE_COLOR := Color(1.0, 0.25, 0.2, 0.55)
const LINE_WIDTH := 1.0

var state: State = State.WALK

var _state_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO
var _time: float = 0.0


## True when a walking beast [param distance] away should start a charge.
static func should_wind_up(distance: float, rest_left: float) -> bool:
	return distance <= TRIGGER_DISTANCE and rest_left <= 0.0


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)
	_update_knockback(delta)
	_time += delta
	if not is_instance_valid(target):
		return
	match state:
		State.WALK, State.REST:
			_walk(delta)
		State.WINDUP:
			_windup(delta)
		State.CHARGE:
			_charge(delta)
	_touch_target(delta)


func _walk(delta: float) -> void:
	var offset := target.global_position - global_position
	_face(offset)
	_state_timer = maxf(_state_timer - delta, 0.0)
	if state == State.REST and _state_timer <= 0.0:
		state = State.WALK
	if state == State.WALK and should_wind_up(offset.length(), _state_timer):
		state = State.WINDUP
		_state_timer = WINDUP_TIME
		_charge_direction = offset.normalized()
		_sprite.self_modulate = WINDUP_TINT
		AudioManager.play(&"boss_dash")
		queue_redraw()
		return
	if offset.length() > body_radius + PLAYER_RADIUS:
		global_position += offset.normalized() * move_speed * delta


func _windup(delta: float) -> void:
	_state_timer -= delta
	# Shiver in place so the charge reads before it comes.
	_sprite.position.x = sin(_time * 60.0) * 1.0
	if _state_timer <= 0.0:
		_sprite.position.x = 0.0
		_sprite.self_modulate = Color.WHITE
		state = State.CHARGE
		_state_timer = CHARGE_TIME
		queue_redraw()


func _charge(delta: float) -> void:
	global_position += _charge_direction * CHARGE_SPEED * delta
	_state_timer -= delta
	if _state_timer <= 0.0:
		state = State.REST
		_state_timer = REST_TIME


func _touch_target(delta: float) -> void:
	if not target.has_method("take_damage"):
		return
	if global_position.distance_to(target.global_position) <= body_radius + PLAYER_RADIUS:
		target.take_damage(contact_dps * delta)


func _draw() -> void:
	if state == State.WINDUP:
		draw_line(Vector2.ZERO, _charge_direction * CHARGE_SPEED * CHARGE_TIME, LINE_COLOR, LINE_WIDTH)
