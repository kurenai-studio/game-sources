class_name Barista
extends CharacterBody2D

@export var __barista_sprite: AnimatedSprite2D

@export var __collided: bool
@export var __collided_prev: bool

@export var __mouse_right: InputEventAction = InputEventAction.new()
@export var __mouse_left: InputEventAction = InputEventAction.new()
@export var __mouse_down: InputEventAction = InputEventAction.new()
@export var __mouse_up: InputEventAction = InputEventAction.new()

func _ready() -> void:
	__barista_sprite = get_child(0)

	set_position(Vector2i(Consts.SCREEN_SIZE.x >> 1, Consts.SCREEN_SIZE.y >> 0b10))

	__mouse_right.set_action("right")
	__mouse_left.set_action("left")
	__mouse_down.set_action("down")
	__mouse_up.set_action("up")

func _process(_delta: float) -> void:
	if (Main.get_singleton().get_state() == Consts.State.GAME_STATE):
		__mouse_right.set_pressed(false)
		__mouse_left.set_pressed(false)
		__mouse_down.set_pressed(false)
		__mouse_up.set_pressed(false)

		if (Input.is_action_pressed("click")):
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()

			__mouse_right.set_pressed(mouse_pos.x > (Consts.SCREEN_SIZE.x >> 1))
			__mouse_left.set_pressed(mouse_pos.x < (Consts.SCREEN_SIZE.x >> 1))
			__mouse_down.set_pressed(mouse_pos.y > (Consts.SCREEN_SIZE.y >> 1))
			__mouse_up.set_pressed(mouse_pos.y < (Consts.SCREEN_SIZE.y >> 1))

			__mouse_right.set_strength(
				(mouse_pos.x - float(Consts.SCREEN_SIZE.x >> 1))
				/float(Consts.SCREEN_SIZE.x >> 0b10)
			)
			__mouse_left.set_strength(
				(float(Consts.SCREEN_SIZE.x >> 1) - mouse_pos.x)
				/float(Consts.SCREEN_SIZE.x >> 0b10)
			)
			__mouse_down.set_strength(
				(mouse_pos.y - float(Consts.SCREEN_SIZE.y >> 1))
				/float(Consts.SCREEN_SIZE.y >> 0b10)
			)
			__mouse_up.set_strength(
				(float(Consts.SCREEN_SIZE.y >> 1) - mouse_pos.y)
				/float(Consts.SCREEN_SIZE.y >> 0b10)
			)

		Input.parse_input_event(__mouse_right)
		Input.parse_input_event(__mouse_left)
		Input.parse_input_event(__mouse_down)
		Input.parse_input_event(__mouse_up)

		if (Input.is_action_just_released("right") or Input.is_action_just_released("left")):
			__barista_sprite.play("side")
		elif (Input.is_action_just_released("down")):
			__barista_sprite.play("down")
		elif (Input.is_action_just_released("up")):
			__barista_sprite.play("up")

		if (Input.is_action_pressed("right") or Input.is_action_pressed("left")):
			__barista_sprite.set_flip_h(Input.is_action_pressed("left"))
			__barista_sprite.play("side_walk")
		elif (Input.is_action_pressed("down")):
			__barista_sprite.set_flip_h(false)
			__barista_sprite.play("down_walk")
		elif (Input.is_action_pressed("up")):
			__barista_sprite.set_flip_h(false)
			__barista_sprite.play("up_walk")

func _physics_process(_delta: float) -> void:
	if (Main.get_singleton().get_state() == Consts.State.GAME_STATE):
		__collided_prev = __collided
		__collided = false

		set_velocity(Input.get_vector("left", "right", "up", "down")*Consts.SPEED)
		__collided = move_and_slide()

		if (__collided and not __collided_prev):
			Main.get_singleton().play_sound("sfx_bonk")

func get_sprite() -> AnimatedSprite2D:
	return __barista_sprite
