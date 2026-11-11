class_name Mother
extends Unit

static var __singleton: Mother = null

var __eggs: int
@onready var __timer: Timer = get_node("Timer")

static func get_singleton() -> Mother:
	if (__singleton == null):
		__singleton = preload("res://src/mother.tscn").instantiate()

	return __singleton

func _init() -> void:
	__eggs = 0
	set_position(Vector3(80.0, 8.0, 80.0))

func _ready() -> void:
	set_sprite(preload("res://src/mother_sprite.tscn").instantiate() as Sprite2D)
	super()

func _physics_process(_delta: float) -> void:
	super(_delta)

	if (get_velocity().y < 0 and Main.get_singleton().get_state() != Consts.ENDING_STATE):
		get_anim_player().stop()
		get_anim_player().play("scream")
		Main.get_singleton().play_sound(Consts.SFX_SCREAM)
		await Main.get_singleton().init_ending(Consts.TRUE_ENDING)
	set_velocity(Vector3(0, get_velocity().y, 0))

func _process(_delta: float) -> void:
	if (not is_broken() and Main.get_singleton().get_state() == Consts.GAME_STATE):
		if (__timer.get_time_left() < 15.0):
			get_anim_player().play("shake_fast")
		elif (__timer.get_time_left() < 30.0):
			get_anim_player().play("shake")

func _on_timer_timeout() -> void:
	get_anim_player().stop()
	set_broken(true)

func set_broken(val: bool) -> void:
	TextBox.get_singleton().set_text("")
	super(val)

func get_eggs() -> int:
	return __eggs

func increment_eggs() -> void:
	__eggs = __eggs + 1

func feed_mother() -> void:
	Main.get_singleton().play_sound(Consts.SFX_DING, 0.75)

	increment_eggs()
	if (get_eggs() > 0b11):
		set_broken(true)
		return

	get_anim_player().play("eye_open")
	__timer.start()
	if (get_eggs() == 0b11):
		__timer.set_paused(true)

	TextBox.get_singleton().set_text_arr(get_eggs())
