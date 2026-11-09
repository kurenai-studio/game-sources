class_name Boss
extends Enemy
## Final boss. Swaps the form it resists every [constant SWAP_INTERVAL]
## seconds (warning flash first), so the player keeps shifting. Between
## chases it winds up and dashes at the player, and it fires rings of
## bolts. Immune to knockback.

signal resistance_swapped(resisted: int)

enum State { CHASE, WINDUP, DASH }

const SWAP_INTERVAL := 8.0
## Seconds before a swap during which the boss flashes the next color.
const SWAP_WARNING := 1.2
const WARNING_BLINK_SPEED := 14.0
const DASH_INTERVAL := 6.0
const DASH_WINDUP := 0.7
const DASH_TIME := 0.45
const DASH_SPEED := 260.0
const RING_INTERVAL := 5.0
const RING_SHOTS := 12
const RING_DAMAGE := 1.5
## Each ring is rotated by half a gap so safe lanes move.
const RING_TWIST := PI / RING_SHOTS
const WINDUP_TINT := Color(1.6, 0.6, 0.6)
const LIGHT_TEXTURE := preload("res://assets/fx/light_radial.tres")
const LIGHT_ENERGY := 0.9
const LIGHT_SCALE := 1.6
const MARK_SCALE := Vector2(2.0, 2.0)
const UNSHADED := preload("res://assets/fx/unshaded.tres")

var state: State = State.CHASE

var _time: float = 0.0
var _dash_timer: float = DASH_INTERVAL
var _ring_timer: float = RING_INTERVAL * 0.6
var _state_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _ring_count: int = 0
var _light: PointLight2D


## Form resisted at [param time] seconds into the fight. Starts resisting
## the warrior, then alternates.
static func resisted_form_at(time: float) -> int:
	return Player.Form.KNIGHT if int(time / SWAP_INTERVAL) % 2 == 0 else Player.Form.MAGE


static func is_swap_warning(time: float) -> bool:
	return fmod(time, SWAP_INTERVAL) >= SWAP_INTERVAL - SWAP_WARNING


static func ring_directions(count: int, twist: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	for i in count:
		directions.append(Vector2.from_angle(twist + TAU * i / count))
	return directions


func _ready() -> void:
	resisted_form = resisted_form_at(0.0)
	super._ready()
	# The boss lights itself so it reads clearly in the dark dungeon.
	_sprite.material = UNSHADED
	if _weakness_mark != null:
		_weakness_mark.scale = MARK_SCALE
		_weakness_mark.position.y -= WEAKNESS_MARK_GAP
	_light = PointLight2D.new()
	_light.texture = LIGHT_TEXTURE
	_light.texture_scale = LIGHT_SCALE
	_light.energy = LIGHT_ENERGY
	add_child(_light)
	_update_light_color()


func knockback(_impulse: Vector2) -> void:
	pass


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)
	_time += delta
	_update_resistance()
	_update_ring(delta)
	match state:
		State.CHASE:
			_chase(delta)
		State.WINDUP:
			_windup(delta)
		State.DASH:
			_dash(delta)
	_touch_target(delta)


func _update_resistance() -> void:
	var wanted := resisted_form_at(_time)
	if wanted != resisted_form:
		set_resisted_form(wanted)
		_update_light_color()
		AudioManager.play(&"boss_swap")
		resistance_swapped.emit(wanted)
	if is_swap_warning(_time) and state != State.WINDUP:
		# Blink toward the color of the form that will beat it next.
		var next_weak := weak_form_for(resisted_form_at(_time + SWAP_WARNING))
		var blink := 0.5 + 0.5 * sin(_time * WARNING_BLINK_SPEED)
		_sprite.self_modulate = Color.WHITE.lerp(Player.ui_color(next_weak) * 1.5, blink)
	elif state != State.WINDUP:
		_sprite.self_modulate = Color.WHITE


func _update_ring(delta: float) -> void:
	_ring_timer -= delta
	if _ring_timer > 0.0 or state == State.DASH:
		return
	_ring_timer = RING_INTERVAL
	_ring_count += 1
	var parent := get_parent()
	for direction in ring_directions(RING_SHOTS, RING_TWIST * (_ring_count % 2)):
		var bolt := EnemyBolt.create(Vector2.ZERO, direction, RING_DAMAGE)
		bolt.target = target
		parent.add_child(bolt)
		bolt.global_position = global_position
	AudioManager.play(&"boss_shot")


func _chase(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	if not is_zero_approx(offset.x):
		_sprite.flip_h = offset.x < 0.0
	if offset.length() > body_radius + PLAYER_RADIUS:
		global_position += offset.normalized() * move_speed * delta
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		state = State.WINDUP
		_state_timer = DASH_WINDUP
		_dash_direction = offset.normalized()
		_sprite.self_modulate = WINDUP_TINT
		AudioManager.play(&"boss_dash")


func _windup(delta: float) -> void:
	_state_timer -= delta
	# Shiver in place so the player can read the dash coming.
	_sprite.position.x = sin(_time * 60.0) * 1.5
	if _state_timer <= 0.0:
		_sprite.position.x = 0.0
		_sprite.self_modulate = Color.WHITE
		state = State.DASH
		_state_timer = DASH_TIME


func _dash(delta: float) -> void:
	global_position += _dash_direction * DASH_SPEED * delta
	_state_timer -= delta
	if _state_timer <= 0.0:
		state = State.CHASE
		_dash_timer = DASH_INTERVAL


func _touch_target(delta: float) -> void:
	if not is_instance_valid(target) or not target.has_method("take_damage"):
		return
	if global_position.distance_to(target.global_position) <= body_radius + PLAYER_RADIUS:
		target.take_damage(contact_dps * delta)


func _update_light_color() -> void:
	if _light != null:
		_light.color = Player.ui_color(weak_form_for(resisted_form))
