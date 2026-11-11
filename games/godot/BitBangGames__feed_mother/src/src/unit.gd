@abstract
class_name Unit
extends CharacterBody3D

var __collided: bool
var __collided_prev: bool
var __vel_y: int
var __broken: bool = false

var __sprite: Sprite2D
var __anim_player: AnimationPlayer

static func isometric(cartesian: Vector3) -> Vector2:
	return Vector2(
		cartesian.x - cartesian.z,
		0.5*(cartesian.x + cartesian.z) - cartesian.y
	)

func _ready() -> void:
	if (get_sprite()):
		__anim_player = get_sprite().get_node_or_null("AnimationPlayer")

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			get_sprite().queue_free()

func _physics_process(_delta: float) -> void:
	if not (is_on_floor()):
		set_vel_y(get_vel_y() - Consts.ACCEL_Y)
	elif (get_vel_y() < 0):
		set_vel_y(0)

	set_velocity(Vector3(get_velocity().x, get_vel_y(), get_velocity().z))
	__collided_prev = __collided
	__collided = (move_and_slide() and not is_on_floor_only())

	get_sprite().set_position(isometric(get_position()))

func set_sprite(val: Sprite2D) -> void:
	__sprite = val
	get_node(Consts.MAP_CANVAS_PATH).add_child(__sprite)

func get_sprite() -> Sprite2D:
	return __sprite

func get_anim_player() -> AnimationPlayer:
	return __anim_player

func set_vel_y(val: int) -> void:
	__vel_y = val

func get_vel_y() -> int:
	return __vel_y

func is_collided() -> bool:
	return __collided

func just_collided() -> bool:
	return (__collided and not __collided_prev)

func is_broken() -> bool:
	return __broken

func set_broken(val: bool) -> void:
	if not (is_broken()):
		get_sprite().set_frame(1)
		if (self is Mother):
			Main.get_singleton().stop_music()
			Main.get_singleton().play_sound(Consts.SFX_CRACK, 0.5)
		else:
			Main.get_singleton().play_sound(Consts.SFX_CRACK)
		
	__broken = val

func update_z_index() -> void:
	get_sprite().set_z_index(int(get_position().y) >> 0b11)
