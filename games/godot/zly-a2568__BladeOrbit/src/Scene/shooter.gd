extends Enemy
class_name Shooter

const ENEMY_BULLET = preload("uid://bhscmcrks7mqp")

var attacking_radius: float
var bullet_speed: float
var shoot_interval: float

var player: Player
var shoot_timer: float = 0.0


func _ready() -> void:
	super()
	_apply_config()
	player = get_tree().get_first_node_in_group("player")


func _apply_config() -> void:
	super()
	var c: Dictionary = Config.data["shooter"]
	attacking_radius = c["attacking_radius"]
	bullet_speed = c["bullet_speed"]
	shoot_interval = c["shoot_interval"]


func _act(delta: float) -> void:
	if dying or player == null:
		return
	shoot_timer += delta
	if player.global_position.distance_squared_to(global_position) > attacking_radius ** 2:
		go_on_map(delta)
	else:
		velocity = Vector2.ZERO
		if shoot_timer >= shoot_interval:
			shoot_bullet()
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0


func shoot_bullet() -> void:
	var inst := ENEMY_BULLET.instantiate() as CharacterBody2D
	inst.global_position = global_position
	inst.velocity = (player.global_position - global_position).normalized() * bullet_speed
	_arena().add_child(inst)
