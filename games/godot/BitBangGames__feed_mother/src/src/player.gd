class_name Player
extends Unit

static var __singleton: Player = null

var __input_vector: Vector2

var __mouse_right: InputEventAction = InputEventAction.new()
var __mouse_left: InputEventAction = InputEventAction.new()
var __mouse_down: InputEventAction = InputEventAction.new()
var __mouse_up: InputEventAction = InputEventAction.new()
var __click_timer: int = 0

static func get_singleton() -> Player:
	if (__singleton == null):
		__singleton = preload("res://src/player.tscn").instantiate()

	return __singleton

func _init() -> void:
	set_position(Vector3(32.0, 96.0, 32.0))

func _ready() -> void:
	set_sprite(preload("res://src/player_sprite.tscn").instantiate() as Sprite2D)

	__mouse_right.set_action("right")
	__mouse_left.set_action("left")
	__mouse_down.set_action("down")
	__mouse_up.set_action("up")

	super()

func _physics_process(_delta: float) -> void:
	if (Main.get_singleton().get_state() == Consts.GAME_STATE):
		if (get_position().y < 0):
			await Main.get_singleton().init_ending(Consts.FALL_ENDING)

		__mouse_right.set_pressed(false)
		__mouse_left.set_pressed(false)
		__mouse_down.set_pressed(false)
		__mouse_up.set_pressed(false)

		if (Input.is_action_just_released("click") and __click_timer == 0):
			__click_timer = 0b1000
		elif (__click_timer > 0):
			__click_timer -= 1

		if (Input.is_action_pressed("click")):
			var mouse_pos: Vector2 = get_viewport().get_mouse_position()
			var screen_size: Vector2 = get_viewport().get_window().get_content_scale_size()
			var radius: float = min(screen_size.x, screen_size.y)/2

			__mouse_right.set_pressed(mouse_pos.x > (screen_size.x + radius)/2)
			__mouse_left.set_pressed(mouse_pos.x < (screen_size.x - radius)/2)
			__mouse_down.set_pressed(mouse_pos.y > (screen_size.y + radius)/2)
			__mouse_up.set_pressed(mouse_pos.y < (screen_size.y - radius)/2)

			if (
				__mouse_right.is_pressed()
				or __mouse_left.is_pressed()
				or __mouse_down.is_pressed()
				or __mouse_up.is_pressed()
			):
				set_input_vector(
					(mouse_pos - screen_size/2).normalized()
				)
			else:
				set_input_vector(Vector2(0,0))
		else:
			set_input_vector(Input.get_vector("left", "right", "up", "down").normalized())

		if (is_on_floor() and (
			Input.is_action_just_pressed("confirm")
			or (Input.is_action_just_pressed("click") and __click_timer > 0)
		)):
			set_vel_y(get_vel_y() + Consts.JUMP_HEIGHT)

		set_velocity(Vector3(
			get_input_vector().x*Consts.SPEED,
			get_velocity().y,
			get_input_vector().y*Consts.SPEED
		))

		for i: int in get_slide_collision_count():
			var collision: KinematicCollision3D = get_slide_collision(i)

			if (collision):
				if (collision.get_collider() is Mother and (collision.get_collider() as Unit).is_broken()):
					(collision.get_collider() as Node).queue_free()
					await Main.get_singleton().init_ending(Consts.DEVOUR_ENDING)

				elif (collision.get_collider() is Unit):
					var collider: Unit = collision.get_collider() as Unit
					if (collider is Mother):
						collider.set_velocity(Vector3(
							get_input_vector().x,
							collider.get_velocity().y,
							get_input_vector().y
						))

						if (is_standing_on(collider) and (collider as Mother).get_eggs() == 0b11):
							await Main.get_singleton().init_ending(Consts.FEED_ENDING)

					else:
						collider.set_velocity(Vector3(
							get_input_vector().x*(Consts.SPEED >> 1),
							collider.get_velocity().y,
							get_input_vector().y*(Consts.SPEED >> 1)
						))

						if (is_standing_on(collider)):
							collider.set_broken(true)

	update_z_index()

	super(_delta)

	if (just_collided()):
		Main.get_singleton().play_sound(Consts.SFX_BONK)

func _process(_delta: float) -> void:
	if (Main.get_singleton().get_state() == Consts.GAME_STATE):
		Input.parse_input_event(__mouse_right)
		Input.parse_input_event(__mouse_left)
		Input.parse_input_event(__mouse_down)
		Input.parse_input_event(__mouse_up)

		if (Input.is_action_just_released("right") or Input.is_action_just_released("down")):
			get_anim_player().play("front")
		elif (Input.is_action_just_released("left") or Input.is_action_just_released("up")):
			get_anim_player().play("back")

		if (Input.is_action_pressed("right") or Input.is_action_pressed("down")):
			get_sprite().set_flip_h(Input.is_action_pressed("down"))
			get_anim_player().play("front_walk")
		elif (Input.is_action_pressed("left") or Input.is_action_pressed("up")):
			get_sprite().set_flip_h(Input.is_action_pressed("up"))
			get_anim_player().play("back_walk")

func get_input_vector() -> Vector2:
	return __input_vector

func set_input_vector(val: Vector2) -> void:
	__input_vector = val

func is_standing_on(unit: Unit) -> bool:
	return (
		get_sprite().get_z_index() > unit.get_sprite().get_z_index()
		and not unit.get_velocity())
