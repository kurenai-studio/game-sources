class_name TextBox
extends Label

static var __singleton: TextBox = null

var __text_arr: PackedStringArray
var __index: int
@onready var __timer: Timer = get_node("Timer")

static func get_singleton() -> TextBox:
	if (__singleton == null):
		__singleton = preload("res://src/text_box.tscn").instantiate()

	return __singleton

func _init() -> void:
	__text_arr = Consts.TEXT_NO_EGGS
	__index = 0
	update_text()

func _on_timer_timeout() -> void:
	if (get_node_or_null("Guide")):
		get_node("Guide").queue_free()

	if (
		Main.get_singleton().get_state() == Consts.GAME_STATE
		and not Mother.get_singleton().is_broken()
	):
		__index = __index + 1 if (__index + 1 < __text_arr.size()) else __index - 0b10
		update_text()

func update_text() -> void:
	set_text(__text_arr[__index])

func set_text_arr(eggs: int) -> void:
	match eggs:
		1:
			__text_arr = Consts.TEXT_ONE_EGG
		0b10:
			__text_arr = Consts.TEXT_TWO_EGGS
		0b11:
			__text_arr = Consts.TEXT_THREE_EGGS
		_:
			set_text("")
			return

	__index = 0
	__timer.start()
	update_text()
