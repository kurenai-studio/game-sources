extends Node2D

@export var bulletscene: PackedScene = preload("res://bullet.tscn")
@export var shootcooldown := 0.25
@export var enemyinterval := 0.5
@export var turnspeed := 3.0
@export var swayamount := 0.08
@export var swayspeed := 1.1
@export var hasreload := false
@export var reloadtime := 1.0
@export var reloadinterval := 30.0
@export var aimheight := 0.0
@export var spread := 0.0
@export var maxfiredist := 0.0
@export var shoot_audio: AudioStream

@onready var muzzle = $Muzzle
@onready var ginsprite = $Sprite2D
@onready var shooter = get_parent()
@onready var audio: AudioStreamPlayer = get_node_or_null("AudioStreamPlayer")

var reloading := false
var _cooldown := 0.0
var _enemytimer := 0.0
var _swaytime := 0.0
var _aimangle := 0.0
var _reloadtimer := 0.0
var _reloadcooldown := 0.0

func _ready() -> void:
	_enemytimer = enemyinterval
	_aimangle = rotation
	_reloadcooldown = reloadinterval

func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)

	if shooter.is_in_group("player"):
		look_at(get_global_mouse_position())
		_aimangle = rotation
		_keepgunupright()
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _cooldown <= 0.0:
			_shoot(0.0)
		return

	# enemy gun: line up first (slow turn + sway), then pop one every enemyinterval
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not _can_enemy_fire():
		return

	# reload cycle: fire for reloadinterval seconds, then pause reloadtime
	if hasreload:
		if reloading:
			_reloadtimer -= delta
			if _reloadtimer <= 0.0:
				reloading = false
				_reloadcooldown = reloadinterval
				_enemytimer = 0.0
		else:
			_reloadcooldown -= delta
			if _reloadcooldown <= 0.0:
				reloading = true
				_reloadtimer = reloadtime
				print(shooter.name, " reloads")

	_swaytime += delta
	var aimpoint = player.global_position + Vector2(0, aimheight)
	var to_player = aimpoint - global_position
	var dist = (player.global_position - global_position).length()
	var target = to_player.angle()
	var angdiff = wrapf(target - _aimangle, -PI, PI)
	_aimangle += clampf(angdiff, -turnspeed * delta, turnspeed * delta)
	rotation = _aimangle + sin(_swaytime * swayspeed) * swayamount
	_keepgunupright()

	if reloading:
		return

	# lined up = barrel near the target, and inside max fire range
	var aimed = absf(angdiff) < 0.45 or dist < 90.0
	if maxfiredist > 0.0 and dist > maxfiredist:
		aimed = false
	if not aimed:
		_enemytimer = enemyinterval
		return

	_enemytimer -= delta
	if _enemytimer <= 0.0:
		_enemytimer = enemyinterval
		print(shooter.name, " shoots")
		_shoot(0.0)

func _can_enemy_fire() -> bool:
	if shooter.has_method("is_gun_ready"):
		return shooter.is_gun_ready()
	if "activated" in shooter:
		return shooter.activated
	return true

func _shoot(angle_error: float):
	if bulletscene == null:
		return
	var packed = bulletscene.instantiate()
	var bullet = packed if packed is Area2D else packed.get_node("Area2D")
	bullet.shooter = shooter
	# fire along where the barrel actually points (includes sway + spread)
	var err = randf_range(-spread, spread) if spread > 0.0 else 0.0
	bullet.direction = Vector2.from_angle(rotation + angle_error + err)
	get_tree().current_scene.add_child(packed)
	packed.global_position = muzzle.global_position
	_cooldown = shootcooldown
	_play_shoot_sound()

# never let the gun art go upside down
func _keepgunupright() -> void:
	if ginsprite == null:
		return
	var ang = wrapf(rotation, -PI, PI)
	ginsprite.flip_v = absf(ang) > PI / 2.0
	
func _play_shoot_sound() -> void:
	if audio == null or shoot_audio == null:
		return
	audio.stream = shoot_audio
	audio.play()
