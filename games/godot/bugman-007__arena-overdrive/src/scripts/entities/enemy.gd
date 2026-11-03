class_name Enemy
extends CharacterBody2D
## Data-driven enemy. One finite state machine covers every archetype:
## IDLE -> CHASE -> ATTACK, plus RETREAT (shooter kiting), FUSE (exploder) and DEAD.
## Bosses switch attack patterns across three health phases.

signal state_changed(old_state: State, new_state: State)
signal died(enemy: Enemy, rewarded: bool)
signal fire_requested(origin: Vector2, directions: Array[Vector2], speed: float, damage: int)
signal exploded(origin: Vector2, radius: float, damage: int)
signal summon_requested(enemy_id: StringName, origin: Vector2)
signal phase_changed(phase: int)
signal attacked(target: Node2D)

enum State { IDLE, CHASE, ATTACK, RETREAT, FUSE, DEAD }

const B := EnemyData.Behavior

var data: EnemyData
var target: Node2D
var state: State = State.IDLE
var max_health: float = 30.0
var health: float = 30.0
var phase: int = 1
var flash: float = 0.0
var dissolve: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var _attack_cd: float = 0.0
var _fuse: float = 0.0
var _summon_cd: float = 6.0
var _t: float = 0.0
var _spiral: float = 0.0
var _strafe: float = 1.0
var _mat: ShaderMaterial
var _glow: Sprite2D
var _shape: CollisionShape2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_shape = $CollisionShape2D
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/flash_dissolve.gdshader")
	material = _mat
	_glow = Fx.make_glow(Color.WHITE, 40.0)
	add_child(_glow)
	if data == null:
		setup(load("res://data/enemies/chaser.tres"))


func setup(d: EnemyData, health_scale: float = 1.0) -> void:
	data = d
	max_health = d.max_hp * health_scale
	health = max_health
	state = State.IDLE
	phase = 1
	flash = 0.0
	dissolve = 0.0
	knockback = Vector2.ZERO
	_attack_cd = d.attack_cooldown * 0.5
	_fuse = 0.0
	_summon_cd = 6.0
	_strafe = 1.0 if randf() < 0.5 else -1.0
	collision_layer = 2
	collision_mask = 4 | 2
	if _shape:
		(_shape.shape as CircleShape2D).radius = d.radius
		_shape.set_deferred("disabled", false)
	if _glow:
		_glow.modulate = Color(d.color, 0.4)
		_glow.scale = Vector2.ONE * (d.radius * 3.2 / 128.0)
	add_to_group("enemies")


func is_alive() -> bool:
	return state != State.DEAD


func is_boss() -> bool:
	return data.behavior == B.BOSS


static func boss_phase_for(ratio: float) -> int:
	if ratio > 0.66:
		return 1
	if ratio > 0.33:
		return 2
	return 3


func evaluate_state(distance: float, has_target: bool) -> State:
	if state == State.DEAD:
		return State.DEAD
	if state == State.FUSE:
		return State.FUSE
	if not has_target:
		return State.IDLE
	var leash := data.detect_range * (1.25 if state != State.IDLE else 1.0)
	match data.behavior:
		B.SHOOTER:
			if distance < data.attack_range * 0.5:
				return State.RETREAT
			if distance <= data.attack_range:
				return State.ATTACK
		B.EXPLODER:
			if distance <= data.attack_range:
				return State.FUSE
		_:
			if distance <= data.attack_range:
				return State.ATTACK
	return State.CHASE if distance <= leash else State.IDLE


func set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	if new_state == State.FUSE:
		_fuse = data.attack_cooldown
	state_changed.emit(old, new_state)


func _has_target() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	return not (target is Player and (target as Player).is_dead)


func speed_multiplier() -> float:
	return [1.0, 1.0, 1.3, 1.6][phase] if is_boss() else 1.0


func tick(delta: float) -> void:
	_t += delta
	flash = maxf(0.0, flash - delta * 6.0)
	if state == State.DEAD:
		dissolve = minf(1.0, dissolve + delta * 2.2)
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, 1200.0 * delta)
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	var has_target := _has_target()
	var distance := global_position.distance_to(target.global_position) if has_target else INF
	set_state(evaluate_state(distance, has_target))
	var to_target := global_position.direction_to(target.global_position) if has_target else Vector2.ZERO
	var speed := data.speed * speed_multiplier()
	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, speed * 4.0 * delta)
		State.CHASE:
			velocity = to_target * speed
			if is_boss():
				_boss_tick(delta)
		State.RETREAT:
			velocity = -to_target * speed
			_try_shoot(to_target)
		State.ATTACK:
			match data.behavior:
				B.SHOOTER:
					velocity = to_target.orthogonal() * _strafe * speed * 0.6
					_try_shoot(to_target)
				B.BOSS:
					velocity = to_target * speed * 0.4
					_boss_tick(delta)
					_try_melee()
				_:
					velocity = to_target * speed * 0.25
					_try_melee()
		State.FUSE:
			velocity = Vector2.ZERO
			_fuse -= delta
			if _fuse <= 0.0:
				exploded.emit(global_position, data.explode_radius, data.damage)
				_die(false)
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 1400.0 * delta)


func _try_melee() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = data.attack_cooldown
	attacked.emit(target)
	if target.has_method("take_damage"):
		target.take_damage(data.damage)


func _try_shoot(dir: Vector2) -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = data.attack_cooldown
	var dirs: Array[Vector2] = [dir]
	fire_requested.emit(global_position, dirs, data.projectile_speed, data.damage)


func _boss_tick(delta: float) -> void:
	var p := boss_phase_for(health / max_health)
	if p != phase:
		phase = p
		_attack_cd = 0.6
		phase_changed.emit(phase)
	_spiral += delta * (1.4 if phase >= 2 else 0.6)
	if _attack_cd <= 0.0:
		_attack_cd = [0.0, 2.0, 1.4, 1.0][phase]
		var count: int = [0, 12, 16, 20][phase]
		fire_requested.emit(global_position, Combat.ring_directions(count, _spiral), data.projectile_speed, int(data.damage * 0.6))
	if phase == 3:
		_summon_cd -= delta
		if _summon_cd <= 0.0:
			_summon_cd = 6.0
			summon_requested.emit(&"exploder", global_position + Vector2(70, 0))
			summon_requested.emit(&"chaser", global_position - Vector2(70, 0))


## Returns true if this hit killed the enemy.
func take_hit(amount: float, push: Vector2 = Vector2.ZERO) -> bool:
	if state == State.DEAD:
		return false
	health -= amount
	flash = 1.0
	knockback += push * (1.0 - data.knockback_resist)
	if health <= 0.0:
		_die(true)
		return true
	return false


func _die(rewarded: bool) -> void:
	set_state(State.DEAD)
	collision_layer = 0
	collision_mask = 4
	remove_from_group("enemies")
	died.emit(self, rewarded)


func dissolved() -> bool:
	return state == State.DEAD and dissolve >= 1.0


func _physics_process(delta: float) -> void:
	tick(delta)
	move_and_slide()
	_mat.set_shader_parameter("flash", flash)
	_mat.set_shader_parameter("dissolve", dissolve)
	_glow.visible = state != State.DEAD
	queue_redraw()


func _draw() -> void:
	if data == null:
		return
	var c := data.color
	if state == State.FUSE and int(_t * 14.0) % 2 == 0:
		c = Color.WHITE
	var r := data.radius
	var rot := _t * (0.6 if not is_boss() else 0.4 * phase)
	if data.behavior == B.EXPLODER and state == State.FUSE:
		r *= 1.0 + 0.25 * (1.0 - _fuse / data.attack_cooldown)
	var pts := PackedVector2Array()
	for i in data.shape_sides:
		pts.append(Vector2.RIGHT.rotated(rot + TAU * i / data.shape_sides) * r * 1.2)
	draw_colored_polygon(pts, c.darkened(0.25))
	pts.append(pts[0])
	draw_polyline(pts, c.lightened(0.3), 3.0, true)
	draw_circle(Vector2.ZERO, r * 0.35, c.lightened(0.5))
	if is_boss():
		for i in 3:
			var inner := PackedVector2Array()
			for k in 3:
				inner.append(Vector2.RIGHT.rotated(-rot * 2.0 + TAU * k / 3.0 + TAU * i / 9.0) * r * 0.75)
			draw_polyline(inner + PackedVector2Array([inner[0]]), Color(UiTheme.GOLD, 0.7), 2.0, true)
	if data.behavior == B.EXPLODER and state == State.FUSE:
		draw_arc(Vector2.ZERO, data.explode_radius, 0, TAU, 48, Color(UiTheme.DANGER, 0.35), 2.0, true)
	if (data.behavior == B.TANK) and health < max_health and state != State.DEAD:
		var w := r * 2.4
		draw_rect(Rect2(-w / 2, -r - 16, w, 5), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-w / 2, -r - 16, w * health / max_health, 5), UiTheme.DANGER)
