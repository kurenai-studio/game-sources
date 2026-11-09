class_name Player
extends Node2D
## Player that shifts between two forms.
## Knight: slower, melee pulse around the player.
## Mage: faster, auto-aimed bolts at the nearest enemy.

signal form_changed(form: Form)
signal health_changed(current: float, maximum: float)
signal died
## A noticeable hit landed on the player (rate limited). Main adds hitstop.
signal hurt_feedback
## The player shifted just before a hit; see [PerfectShift].
signal perfect_shifted

enum Form { KNIGHT, MAGE }

const BOLT_SCENE := preload("res://scenes/bolt.tscn")
const KNIGHT_FRAMES := preload("res://assets/sprite_frames/warrior.tres")
const MAGE_FRAMES := preload("res://assets/sprite_frames/mage.tres")
const BODY_RADIUS := 7.0
const HURT_FLASH_TIME := 0.1
const HURT_TINT := Color(1.0, 0.45, 0.45)
## Sprite scale right after a shift; it eases back to 1.
const SHIFT_POP_SCALE := 1.35
const SHIFT_POP_TIME := 0.18
## Small delay before the first attack after a shift, so shifting feels snappy.
const SHIFT_ATTACK_DELAY := 0.1
## Angle between bolts when the mage casts several at once.
const MULTISHOT_SPREAD := 0.2
const SHIFT_BURST_RADIUS := 64.0
## Minimum time between two Shift Bursts, so shift spam is not free damage.
const SHIFT_BURST_COOLDOWN := 2.0
const KNIGHT_LIGHT_COLOR := Color(1.0, 0.88, 0.72)
const MAGE_LIGHT_COLOR := Color(0.72, 0.66, 1.0)
## HUD colors of the forms: energy bars, weakness marks.
const KNIGHT_UI_COLOR := Color(1.0, 0.6, 0.25)
const MAGE_UI_COLOR := Color(0.72, 0.5, 1.0)
## Torch flicker: energy wobbles by this much around the base energy.
const LIGHT_FLICKER := 0.05
const LIGHT_FLICKER_SPEED := 9.0
## Contact damage ticks every frame; feedback fires at most this often.
const HURT_FEEDBACK_COOLDOWN := 1.2
const HURT_TRAUMA := 0.45
const DEATH_TRAUMA := 0.8
const SHIFT_TRAUMA := 0.15
const SHIFT_BURST_TRAUMA := 0.4
const CRIT_MULTIPLIER := 2.0
## Death: flash white, squash and fade like the enemies, while the light dies.
const DEATH_TIME := 0.6
const DEATH_SCALE := Vector2(1.8, 0.2)
const DEATH_FLASH := Color(8.0, 8.0, 8.0)
## Invulnerable: the sprite blinks between these every BLINK_TIME seconds.
const INVULNERABLE_TINT := Color(1.8, 1.8, 2.2)
const INVULNERABLE_BLINK_TIME := 0.06
const INTRO_TIME := 0.45
## Momentum: damage bonus lasts this long after each shift.
const MOMENTUM_TIME := 2.0
## Blood Pact: damage factor while at full health.
const BLOOD_PACT_FULL_HEALTH_BONUS := 1.25
## Twin Soul: Shift Burst radius factor and the mage's bolt ring size.
const TWIN_SOUL_RADIUS_FACTOR := 2.0
const TWIN_SOUL_BOLTS := 8
## Storm Cleaver: push speed (px/s) of each bolt hit.
const STORM_BOLT_KNOCKBACK := 140.0

@export var move_speed: float = 110.0
@export var max_health: float = 10.0
@export var shift_cooldown: float = 0.5
## Group the attacks search. Main syncs it with HordeSpawner.enemy_group.
@export var enemy_group: StringName = &"horde_enemy"

@export_group("Knight")
@export var knight_interval: float = 0.9
@export var knight_radius: float = 44.0
@export var knight_damage: float = 2.0
@export var knight_speed_multiplier: float = 0.9

@export_group("Mage")
@export var mage_interval: float = 0.45
@export var mage_damage: float = 1.0
@export var mage_range: float = 240.0
@export var mage_speed_multiplier: float = 1.15

@export_group("Upgrades")
## Chance (0..1) that a hit deals [constant CRIT_MULTIPLIER] damage.
@export var crit_chance: float = 0.1
## HP healed per sword hit.
@export var lifesteal: float = 0.0
## Knockback impulse (px/s) per sword hit.
@export var knockback: float = 0.0
@export var blade_count: int = 1
@export var bolt_count: int = 1
@export var bolt_pierce: int = 0
@export var bolt_chain: int = 0
@export var regen_per_second: float = 0.0
## Damage dealt around the player on shift. 0 disables the burst.
@export var shift_burst_damage: float = 0.0
## Extra damage (0.2 = +20%) for [constant MOMENTUM_TIME] after a shift.
@export var momentum_bonus: float = 0.0

var form: Form = Form.KNIGHT
## Direction the sprite faces; see [Facing].
var facing: StringName = Facing.DOWN
var health: float
var is_dead: bool = false

var _attack_timer: float = 0.0
var _shift_timer: float = 0.0
var _hurt_flash: float = 0.0
var _burst_timer: float = 0.0
var _hurt_feedback_timer: float = 0.0
var _light_base_energy: float = 0.0
var _light_time: float = 0.0
var _energy := FormEnergy.new()
var _perfect := PerfectShift.new()
var _invulnerable_time: float = 0.0
var _momentum_time: float = 0.0
## Ids of the evolutions taken; see [UpgradeCatalog].
var _evolutions: Dictionary[StringName, bool] = {}
## Blades that already hit each enemy this spin (instance id -> bitmask).
var _sword_hits: Dictionary[int, int] = {}

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _sword: SpinningSword = $Sword
@onready var _light: PointLight2D = $Light
@onready var _camera: ShakeCamera = $Camera2D


func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	refresh_stats()
	_sword.swept.connect(_on_sword_swept)
	_light_base_energy = _light.energy
	_apply_form_visuals()


func _physics_process(delta: float) -> void:
	if is_dead:
		_sprite.pause()
		return
	_shift_timer = maxf(_shift_timer - delta, 0.0)
	_burst_timer = maxf(_burst_timer - delta, 0.0)
	_hurt_feedback_timer = maxf(_hurt_feedback_timer - delta, 0.0)
	_update_light(delta)
	_energy.tick(form, delta)
	_perfect.tick(delta)
	_momentum_time = maxf(_momentum_time - delta, 0.0)
	_update_invulnerability(delta)
	_update_hurt_flash(delta)
	if regen_per_second > 0.0:
		heal(regen_per_second * delta)
	if Input.is_action_just_pressed(&"shift_form") and _shift_timer == 0.0:
		shift()
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	position += direction * move_speed * _speed_multiplier() * delta
	_update_animation(direction)
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _attack_interval()
		_attack()


func shift() -> void:
	var perfect := _perfect.try_trigger(_in_danger())
	form = Form.MAGE if form == Form.KNIGHT else Form.KNIGHT
	AudioManager.play(&"shift_to_mage" if form == Form.MAGE else &"shift_to_warrior")
	_shift_timer = shift_cooldown
	_attack_timer = SHIFT_ATTACK_DELAY
	_momentum_time = MOMENTUM_TIME
	_apply_form_visuals()
	_shift_burst()
	_shake(SHIFT_TRAUMA)
	_sprite.scale = Vector2.ONE * SHIFT_POP_SCALE
	create_tween().tween_property(_sprite, "scale", Vector2.ONE, SHIFT_POP_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	form_changed.emit(form)
	if perfect:
		make_invulnerable(PerfectShift.INVULNERABLE_TIME)
		_energy.restore(form, PerfectShift.ENERGY_REFUND)
		AudioManager.play(&"perfect_shift")
		perfect_shifted.emit()


static func momentum_factor(bonus: float, time_left: float) -> float:
	return 1.0 + bonus if time_left > 0.0 else 1.0


static func blood_pact_factor(has_pact: bool, current_health: float, maximum_health: float) -> float:
	return BLOOD_PACT_FULL_HEALTH_BONUS if has_pact and current_health >= maximum_health else 1.0


## Everything that scales [param of_form]'s damage right now: its energy,
## Momentum after a shift and Blood Pact at full health.
func damage_multiplier(of_form: Form) -> float:
	return _energy.damage_multiplier(of_form) \
		* momentum_factor(momentum_bonus, _momentum_time) \
		* blood_pact_factor(has_evolution(&"evo_blood_pact"), health, max_health)


func has_evolution(id: StringName) -> bool:
	return _evolutions.has(id)


func add_evolution(id: StringName) -> void:
	if has_evolution(id):
		return
	_evolutions[id] = true
	if id == &"evo_arcane_orbit":
		var orbit := ArcaneOrbit.new()
		orbit.player = self
		add_child(orbit)


## The run's opening: the sprite pops in from nothing.
func play_intro() -> void:
	_sprite.scale = Vector2.ZERO
	create_tween().tween_property(_sprite, ^"scale", Vector2.ONE, INTRO_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func make_invulnerable(seconds: float) -> void:
	_invulnerable_time = maxf(_invulnerable_time, seconds)


func is_invulnerable() -> bool:
	return _invulnerable_time > 0.0


## True when an enemy or an enemy bolt is touching the player or about to.
func _in_danger() -> bool:
	if not is_inside_tree():
		return false
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if enemy is Enemy and PerfectShift.is_threat(global_position, enemy.global_position, enemy.body_radius):
			return true
	for bolt in get_tree().get_nodes_in_group(EnemyBolt.GROUP):
		if PerfectShift.is_threat(global_position, bolt.global_position, EnemyBolt.RADIUS):
			return true
	return false


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_time <= 0.0:
		return
	_invulnerable_time = maxf(_invulnerable_time - delta, 0.0)
	var blink_on := int(_invulnerable_time / INVULNERABLE_BLINK_TIME) % 2 == 0
	_sprite.modulate = INVULNERABLE_TINT if blink_on and _invulnerable_time > 0.0 else Color.WHITE


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0 or is_invulnerable():
		return
	health = maxf(health - amount, 0.0)
	_hurt_flash = HURT_FLASH_TIME
	_sprite.modulate = HURT_TINT
	health_changed.emit(health, max_health)
	if health == 0.0:
		is_dead = true
		_shake(DEATH_TRAUMA)
		AudioManager.play(&"player_death")
		_play_death()
		died.emit()
	elif _hurt_feedback_timer == 0.0:
		_hurt_feedback_timer = HURT_FEEDBACK_COOLDOWN
		_shake(HURT_TRAUMA)
		AudioManager.play(&"player_hurt")
		hurt_feedback.emit()


## The body vanishes but the node stays: the camera and the run screen
## still need it.
func _play_death() -> void:
	_sword.cancel()
	_sword.hide()
	$Shadow.hide()
	_sprite.modulate = DEATH_FLASH
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, ^"scale", DEATH_SCALE, DEATH_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, ^"modulate", Color(DEATH_FLASH, 0.0), DEATH_TIME)
	tween.tween_property(_light, ^"energy", 0.0, DEATH_TIME * 2.0)
	tween.chain().tween_callback(_sprite.hide)


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0 or health >= max_health:
		return
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)


## Pushes upgraded stats to child nodes. Safe to call before _ready.
func refresh_stats() -> void:
	health = minf(health, max_health)
	if not is_node_ready():
		return
	_sword.reach = knight_radius
	_sword.blade_count = blade_count
	health_changed.emit(health, max_health)


static func is_crit(chance: float, roll: float) -> bool:
	return roll < chance


static func hit_damage(base: float, crit: bool) -> float:
	return base * CRIT_MULTIPLIER if crit else base


static func ui_color(of_form: int) -> Color:
	return KNIGHT_UI_COLOR if of_form == Form.KNIGHT else MAGE_UI_COLOR


## Energy of [param of_form], 0..1. See [FormEnergy].
func energy_level(of_form: Form) -> float:
	return _energy.level(of_form)


func form_name() -> String:
	return "Warrior" if form == Form.KNIGHT else "Mage"


func _apply_form_visuals() -> void:
	var animation := _sprite.animation
	_sprite.sprite_frames = KNIGHT_FRAMES if form == Form.KNIGHT else MAGE_FRAMES
	_sprite.play(animation if _sprite.sprite_frames.has_animation(animation) else Facing.idle_animation(_sprite.sprite_frames, facing))
	_sword.visible = form == Form.KNIGHT
	if form != Form.KNIGHT:
		_sword.cancel()
	_light.color = KNIGHT_LIGHT_COLOR if form == Form.KNIGHT else MAGE_LIGHT_COLOR


func _update_light(delta: float) -> void:
	_light_time += delta * LIGHT_FLICKER_SPEED
	_light.energy = _light_base_energy + LIGHT_FLICKER * (sin(_light_time) + 0.5 * sin(_light_time * 2.7))


func _shake(trauma_amount: float) -> void:
	if _camera != null:
		_camera.add_trauma(trauma_amount)


func _update_animation(direction: Vector2) -> void:
	facing = Facing.from_vector(direction, facing)
	var frames := _sprite.sprite_frames
	if direction.is_zero_approx():
		_sprite.play(Facing.idle_animation(frames, facing))
	else:
		_sprite.play(Facing.walk_animation(frames, facing))
	if not is_zero_approx(direction.x):
		_sword.facing_left = direction.x < 0.0


func _update_hurt_flash(delta: float) -> void:
	if _hurt_flash <= 0.0:
		return
	_hurt_flash -= delta
	if _hurt_flash <= 0.0:
		_sprite.modulate = Color.WHITE


func _speed_multiplier() -> float:
	return knight_speed_multiplier if form == Form.KNIGHT else mage_speed_multiplier


func _attack_interval() -> float:
	return knight_interval if form == Form.KNIGHT else mage_interval


func _attack() -> void:
	if form == Form.KNIGHT:
		_knight_pulse()
	else:
		_mage_bolt()


func _knight_pulse() -> void:
	_sword_hits.clear()
	_sword.spin()
	AudioManager.play(&"axe_swing")


## Hits enemies in range whose direction a blade just swept over.
## Each blade hits each enemy at most once per spin.
func _on_sword_swept(from_angle: float, to_angle: float) -> void:
	for node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := node as Node2D
		if enemy == null or not enemy.has_method("take_damage"):
			continue
		var offset := enemy.global_position - global_position
		if offset.length() > knight_radius:
			continue
		var id := enemy.get_instance_id()
		var mask: int = _sword_hits.get(id, 0)
		for blade in SpinningSword.blades_in_sweep(offset.angle(), from_angle, to_angle, blade_count):
			if mask & (1 << blade):
				continue
			mask |= 1 << blade
			_sword_hit(enemy, offset)
		_sword_hits[id] = mask


func _sword_hit(enemy: Node2D, offset: Vector2) -> void:
	# Another blade or a Shift Burst may have killed it earlier this frame.
	if enemy is Enemy and enemy.health <= 0.0:
		return
	if knockback > 0.0 and enemy.has_method("knockback"):
		enemy.knockback(offset.normalized() * knockback)
	var crit := is_crit(crit_chance, randf())
	var damage := hit_damage(knight_damage * damage_multiplier(Form.KNIGHT), crit)
	enemy.take_damage(damage, Form.KNIGHT, crit)
	if enemy is Enemy and has_evolution(&"evo_storm_cleaver"):
		StormCleaver.strike(enemy, enemy_group, damage * StormCleaver.DAMAGE_SHARE, self)
	var resisted: bool = enemy is Enemy and enemy.resists(Form.KNIGHT)
	AudioManager.play(&"hit_resisted" if resisted else &"axe_hit")
	heal(lifesteal)


func _shift_burst() -> void:
	if shift_burst_damage <= 0.0 or _burst_timer > 0.0:
		return
	_burst_timer = SHIFT_BURST_COOLDOWN
	var twin_soul := has_evolution(&"evo_twin_soul")
	var radius := SHIFT_BURST_RADIUS * (TWIN_SOUL_RADIUS_FACTOR if twin_soul else 1.0)
	add_child(ShiftBurstFx.create(radius))
	AudioManager.play(&"shift_burst")
	_shake(SHIFT_BURST_TRAUMA)
	for node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := node as Node2D
		if enemy != null and enemy.has_method("take_damage") \
				and enemy.global_position.distance_to(global_position) <= radius:
			enemy.take_damage(shift_burst_damage)
	if twin_soul:
		_unleash_form_attack()


## Twin Soul: the new form attacks at once, the mage with a ring of bolts.
func _unleash_form_attack() -> void:
	if form == Form.KNIGHT:
		_knight_pulse()
		return
	AudioManager.play(&"bolt_cast")
	for i in TWIN_SOUL_BOLTS:
		_spawn_bolt(Vector2.from_angle(TAU * i / TWIN_SOUL_BOLTS))


func _mage_bolt() -> void:
	var target := _nearest_enemy(mage_range)
	if target == null:
		return
	var aim := global_position.direction_to(target.global_position)
	AudioManager.play(&"bolt_cast")
	for i in bolt_count:
		_spawn_bolt(aim.rotated((i - (bolt_count - 1) * 0.5) * MULTISHOT_SPREAD))


func _spawn_bolt(direction: Vector2) -> void:
	var bolt := BOLT_SCENE.instantiate() as Bolt
	bolt.direction = direction
	bolt.damage = mage_damage * damage_multiplier(Form.MAGE)
	bolt.crit_chance = crit_chance
	bolt.pierce = bolt_pierce
	bolt.chain = bolt_chain
	bolt.enemy_group = enemy_group
	if has_evolution(&"evo_storm_cleaver"):
		bolt.knockback = STORM_BOLT_KNOCKBACK
	if has_evolution(&"evo_blood_pact"):
		bolt.lifesteal = lifesteal
		bolt.healer = self
	get_parent().add_child(bolt)
	bolt.global_position = global_position


func _nearest_enemy(max_distance: float) -> Node2D:
	var nearest: Node2D = null
	var best := max_distance * max_distance
	for node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := node as Node2D
		if enemy == null:
			continue
		var distance := enemy.global_position.distance_squared_to(global_position)
		if distance < best:
			best = distance
			nearest = enemy
	return nearest
