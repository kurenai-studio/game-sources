extends CharacterBody2D

class_name Enemy

signal died(exp_reward: float)

const ITEM = preload("uid://biqu7yu622j6t")
const ATTACKING_NUMBER = preload("uid://xse7q58h2rl8")

const PATH_SERVICE_GROUP := "path_service"

# 配置数据（游戏启动时由 Config 一次性写入，见 _apply_config）
var MAP_SPEED: float
var TILE: float
var LOOT_CHANCE: float
var CONTACT_HIT_COOLDOWN: float
var FLASH_TIMES: int

@export var health: float = 3.0
@export var damage_amount: int = 1
@export var exp_reward: float = 0.5
@export var invincible_time: float = 0.4

var damaged: bool = false
var dying: bool = false
var path: Array[Vector2i] = []
var tile_pos: Vector2i = Vector2i.ZERO
var next_pos: Vector2i = Vector2i.ZERO

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitter_shape: CollisionShape2D = $Hitter/CollisionShape2D

var _path_service: Node
var _flashing: bool = false


func _ready() -> void:
	_apply_config()
	health_bar.max_value = health
	$Hitter.body_entered.connect(_on_hitter_body_entered)
	next_pos = tile_pos
	_init_path_following()


func _apply_config() -> void:
	var c: Dictionary = Config.data["enemy"]
	MAP_SPEED = c["map_speed"]
	TILE = c["tile"]
	LOOT_CHANCE = c["loot_chance"]
	CONTACT_HIT_COOLDOWN = c["contact_hit_cooldown"]
	FLASH_TIMES = int(c["flash_times"])
	invincible_time=float(c["invincible_time"])


func _process(delta: float) -> void:
	health_bar.value = health


func _physics_process(delta: float) -> void:
	if health <= 0:
		die()
	_act(delta)
	if damaged and not dying:
		_flash_while_invincible()
	if _can_move():
		move_and_slide()


func _act(delta: float) -> void:
	if (global_position-(get_tree().get_first_node_in_group("player") as Player).global_position).length_squared()<=40000:
		if self not in GameManager.camera_inst.follow_targets:
			GameManager.camera_inst.append_follow_targets(self)
	else:
		if self in GameManager.camera_inst.follow_targets:
			GameManager.camera_inst.follow_targets.erase(self)

func _can_move() -> bool:
	return not dying


func take_hit(amount: float, is_critical: bool = false) -> bool:
	if damaged:
		return false
	damaged = true
	health -= amount
	_spawn_attacking_number(amount, is_critical)
	return true


func die() -> void:
	if dying:
		return
	dying = true
	died.emit(exp_reward)
	GameManager.camera_inst.follow_targets.erase(self)
	var tween := get_tree().create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_drop_loot_and_free)


func go_on_map(delta: float) -> void:
	if path.is_empty():
		velocity = Vector2.ZERO
		return
	var target: Vector2 = Vector2(next_pos) * TILE + Vector2(TILE * 0.5, TILE * 0.5)
	if (position - target).length_squared() > 0:
		position.x = move_toward(position.x, target.x, MAP_SPEED * delta)
		position.y = move_toward(position.y, target.y, MAP_SPEED * delta)
	else:
		tile_pos = path[0]
		next_pos = path[0]
		path.remove_at(0)


func _init_path_following() -> void:
	if not is_in_group("map_moving"):
		return
	_path_service = get_tree().get_first_node_in_group(PATH_SERVICE_GROUP)
	if _path_service == null:
		return
	path = _path_service.request_path(tile_pos, _path_service.player_tile)
	_path_service.player_tile_changed.connect(_on_player_tile_changed)


func _on_player_tile_changed(player_tile: Vector2i) -> void:
	path = _path_service.request_path(tile_pos, player_tile)


func _on_hitter_body_entered(body: Node2D) -> void:
	if body is Player:
		body.get_damage(damage_amount)
		hitter_shape.set_deferred("disabled", true)
		await get_tree().create_timer(CONTACT_HIT_COOLDOWN).timeout
		hitter_shape.set_deferred("disabled", false)


func _flash_while_invincible() -> void:
	if _flashing:
		return
	_flashing = true
	var flash: float = invincible_time / FLASH_TIMES
	for i in range(FLASH_TIMES):
		sprite.modulate = Color.RED if i % 2 == 0 else Color.WHITE
		await get_tree().create_timer(flash).timeout
	sprite.modulate = Color.WHITE
	damaged = false
	_flashing = false


func _spawn_attacking_number(amount: float, is_critical: bool) -> void:
	var number: AttackingNumber = ATTACKING_NUMBER.instantiate()
	if is_critical:
		number.modulate = Color.RED
		number.set_motion_mode(AttackingNumber.MoveMode.GRAVITY)
	else:
		number.set_motion_mode(AttackingNumber.MoveMode.STRAIGHT)
	number.text = str(amount)
	number.origin_pos = global_position
	_arena().add_child(number)


func _drop_loot_and_free() -> void:
	GameManager.camera_inst.erase_follow_targets(self)
	if randf_range(0.0, 1.0) <= LOOT_CHANCE:
		var inst = ITEM.instantiate() as Area2D
		inst.global_position = global_position
		_arena().add_child(inst)
	queue_free()


func _arena() -> Node:
	return get_parent().get_parent()
