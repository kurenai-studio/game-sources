class_name Player
extends CharacterBody2D
## Player: 8-way movement, dash with i-frames, auto-aimed weapon and a class ability.

signal fired(origin: Vector2, directions: Array[Vector2])
signal ability_used(kind: int, origin: Vector2, direction: Vector2)
signal dashed
signal damaged(amount: int, current: int, maximum: int)
signal healed(current: int, maximum: int)
signal died

const DASH_SPEED_MULT := 3.4
const DASH_DURATION := 0.16
const INVULN_TIME := 0.6
const RADIUS := 15.0

var character: CharacterData
var stats: PlayerStats
var health: float = 100.0
var facing: Vector2 = Vector2.RIGHT
var aim: Vector2 = Vector2.RIGHT
var is_dashing: bool = false
var is_dead: bool = false
var input_override: Variant = null
var slow_factor: float = 1.0
var invulnerable_debug: bool = false
## Returns a Vector2 target position or null when nothing is in range.
var aim_provider: Callable

var _dash_left: float = 0.0
var _dash_cd: float = 0.0
var _invuln: float = 0.0
var _fire_cd: float = 0.0
var _ability_cd: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
var _trail: Array[Vector2] = []
var _t: float = 0.0
var _glow: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	if stats == null:
		stats = PlayerStats.new()
		health = stats.get_stat(&"max_hp")
	_glow = Fx.make_glow(Color(body_color(), 0.45), 52.0)
	add_child(_glow)


func setup(c: CharacterData, s: PlayerStats) -> void:
	character = c
	stats = s
	health = float(max_health())


func body_color() -> Color:
	return character.color if character else UiTheme.ACCENT


func max_health() -> int:
	return stats.get_int(&"max_hp")


func health_int() -> int:
	return int(ceil(health))


func get_input_direction() -> Vector2:
	if input_override != null:
		return (input_override as Vector2).limit_length(1.0)
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func can_dash() -> bool:
	return not is_dead and not is_dashing and _dash_cd <= 0.0


func try_dash(direction: Vector2) -> bool:
	if not can_dash():
		return false
	_dash_dir = direction.normalized() if direction != Vector2.ZERO else facing
	is_dashing = true
	_dash_left = DASH_DURATION
	_dash_cd = stats.get_stat(&"dash_cooldown")
	dashed.emit()
	return true


func dash_ready_ratio() -> float:
	return 1.0 - clampf(_dash_cd / stats.get_stat(&"dash_cooldown"), 0.0, 1.0)


func ability_ready_ratio() -> float:
	return 1.0 - clampf(_ability_cd / stats.get_stat(&"ability_cooldown"), 0.0, 1.0)


func get_dash_cooldown_left() -> float:
	return _dash_cd


func step(delta: float, direction: Vector2) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return
	_t += delta
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_ability_cd = maxf(0.0, _ability_cd - delta)
	var regen := stats.get_stat(&"regen")
	if regen > 0.0 and health < max_health():
		health = minf(float(max_health()), health + regen * delta)
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	if is_dashing:
		velocity = _dash_dir * stats.get_stat(&"move_speed") * DASH_SPEED_MULT
		_dash_left -= delta
		if _dash_left <= 0.0:
			is_dashing = false
	else:
		velocity = direction * stats.get_stat(&"move_speed") * slow_factor


func try_fire(target_pos: Variant) -> bool:
	if is_dead or _fire_cd > 0.0 or target_pos == null:
		return false
	_fire_cd = 1.0 / stats.get_stat(&"fire_rate")
	aim = global_position.direction_to(target_pos as Vector2)
	fired.emit(global_position, Combat.spread_directions(aim, stats.get_int(&"projectile_count"), 9.0))
	return true


func try_ability(direction: Vector2) -> bool:
	if is_dead or _ability_cd > 0.0:
		return false
	_ability_cd = stats.get_stat(&"ability_cooldown")
	var kind: int = character.ability if character else CharacterData.Ability.SHOCKWAVE
	ability_used.emit(kind, global_position, direction.normalized() if direction != Vector2.ZERO else facing)
	return true


## Returns damage actually taken (0 when blocked by dash, i-frames or debug god mode).
func take_damage(amount: int) -> int:
	if is_dead or is_dashing or _invuln > 0.0 or invulnerable_debug or amount <= 0:
		return 0
	var dealt := Combat.mitigate(amount, stats.get_stat(&"armor"))
	health -= dealt
	_invuln = INVULN_TIME
	damaged.emit(dealt, maxi(0, health_int()), max_health())
	if health <= 0.0:
		die()
	return dealt


func die() -> void:
	if is_dead:
		return
	health = 0.0
	is_dead = true
	died.emit()


func heal(amount: float) -> void:
	if is_dead:
		return
	health = minf(float(max_health()), health + amount)
	healed.emit(health_int(), max_health())


func _physics_process(delta: float) -> void:
	var direction := get_input_direction()
	if input_override == null and not is_dead:
		if Input.is_action_just_pressed(&"dash"):
			try_dash(direction)
		if Input.is_action_just_pressed(&"ability"):
			try_ability(direction)
	if aim_provider.is_valid():
		try_fire(aim_provider.call())
	step(delta, direction)
	move_and_slide()
	_trail.push_front(global_position)
	if _trail.size() > (10 if is_dashing else 5):
		_trail.pop_back()
	queue_redraw()


func _draw() -> void:
	if is_dead:
		return
	var c := body_color()
	for i in range(1, _trail.size()):
		var a := 1.0 - float(i) / _trail.size()
		draw_circle(to_local(_trail[i]), RADIUS * a * 0.9, Color(c, a * (0.35 if is_dashing else 0.12)))
	var blink := _invuln > 0.0 and int(_invuln * 24.0) % 2 == 0
	var body := Color(1, 1, 1) if is_dashing else c
	if blink:
		body.a = 0.3
	var sides := character.shape_sides if character else 0
	if sides >= 3:
		var pts := PackedVector2Array()
		for i in sides:
			pts.append(Vector2.RIGHT.rotated(aim.angle() + TAU * i / sides) * RADIUS * 1.25)
		draw_colored_polygon(pts, body)
		pts.append(pts[0])
		draw_polyline(pts, Color(1, 1, 1, 0.8 * body.a), 2.0, true)
	else:
		draw_circle(Vector2.ZERO, RADIUS, body)
		for i in 3:
			var orb := Vector2.RIGHT.rotated(_t * 4.0 + TAU * i / 3.0) * (RADIUS + 9.0)
			draw_circle(orb, 3.5, Color(c.lightened(0.5), body.a))
	draw_circle(Vector2.ZERO, 5.0, Color(1, 1, 1, 0.9 * body.a))
	draw_line(aim * 8.0, aim * (RADIUS + 12.0), Color(1, 1, 1, 0.8), 3.0, true)
	if _dash_cd > 0.0:
		var pct := dash_ready_ratio()
		draw_arc(Vector2.ZERO, RADIUS + 8.0, -PI / 2.0, -PI / 2.0 + TAU * pct, 32, Color(c, 0.55), 2.0, true)
