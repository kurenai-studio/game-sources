class_name RangedEnemy
extends Enemy
## Eye: keeps its distance and shoots slow bolts at the player. Closes in
## when far, backs off when the player comes close, and drifts sideways
## in between, so the axe has a hard time reaching it.

## Range it tries to hold, with a dead zone of RANGE_SLACK either side.
const PREFERRED_DISTANCE := 110.0
const RANGE_SLACK := 20.0
## Sideways drift while in range, as a share of move speed.
const STRAFE_SHARE := 0.5
const SHOT_INTERVAL := 2.6
## The eye glows for this long before each shot.
const SHOT_WINDUP := 0.4
const SHOT_DAMAGE := 1.0
## Shots only start once the eye is this close (on or near the screen).
const SHOT_RANGE := 220.0
const WINDUP_TINT := Color(2.0, 1.2, 1.2)

var _shot_timer: float = SHOT_INTERVAL
var _strafe_sign: float = 1.0


## 1 to close in, -1 to back off, 0 to hold at [param distance].
static func range_step(distance: float) -> int:
	if distance > PREFERRED_DISTANCE + RANGE_SLACK:
		return 1
	if distance < PREFERRED_DISTANCE - RANGE_SLACK:
		return -1
	return 0


func _ready() -> void:
	super._ready()
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	_shot_timer = randf_range(SHOT_INTERVAL * 0.5, SHOT_INTERVAL)


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)
	_update_knockback(delta)
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	_face(offset)
	var toward := offset / maxf(distance, 0.001)
	var step := range_step(distance)
	var motion := toward * step if step != 0 else toward.orthogonal() * _strafe_sign * STRAFE_SHARE
	global_position += motion * move_speed * delta
	_update_shot(delta, distance, toward)


func _update_shot(delta: float, distance: float, toward: Vector2) -> void:
	if distance > SHOT_RANGE:
		return
	_shot_timer -= delta
	if _shot_timer <= SHOT_WINDUP and _hit_flash <= 0.0:
		_sprite.self_modulate = WINDUP_TINT
	if _shot_timer > 0.0:
		return
	_shot_timer = SHOT_INTERVAL
	_sprite.self_modulate = Color.WHITE
	var bolt := EnemyBolt.create(Vector2.ZERO, toward, SHOT_DAMAGE)
	bolt.target = target
	get_parent().add_child(bolt)
	bolt.global_position = global_position
	AudioManager.play(&"boss_shot")
