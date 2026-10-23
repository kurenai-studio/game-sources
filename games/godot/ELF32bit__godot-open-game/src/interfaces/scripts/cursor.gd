extends Node

enum CursorType {
	DEFAULT = 0,
	HOVER = 1,
	INTERACT1 = 2,
	INTERACT2 = 3,
	ATTACK = 4,
	CHAT = 5,
}

const CURSOR_IMAGES: Dictionary = {
	CursorType.DEFAULT: preload("../textures/cursors/default.svg"),
	CursorType.HOVER: preload("../textures/cursors/hover.svg"),
	CursorType.INTERACT1: preload("../textures/cursors/interact1.svg"),
	CursorType.INTERACT2: preload("../textures/cursors/interact2.svg"),
	CursorType.ATTACK: preload("../textures/cursors/attack.svg"),
	CursorType.CHAT: preload("../textures/cursors/chat.svg"),
}

var image: Resource = null
@onready var image_hotspot: Vector2 = ProjectSettings.get_setting(
	"display/mouse_cursor/custom_image_hotspot")

@warning_ignore("shadowed_variable")
func set_custom_image(type: CursorType) -> void:
	if not CURSOR_IMAGES.has(type):
		_set_custom_image(CURSOR_IMAGES[CursorType.DEFAULT])
	else: _set_custom_image(CURSOR_IMAGES[type])


func set_custom_alternative_image(type: CursorType) -> void:
	var alternative_type := get_alternative_cursor(type)
	set_custom_image(alternative_type)

@warning_ignore("shadowed_variable")
func _set_custom_image(image: Resource) -> void:
	if self.image != image:
		Input.set_custom_mouse_cursor(image,
			Input.CURSOR_ARROW, image_hotspot)
	self.image = image


func _ready() -> void:
	set_custom_image(CursorType.DEFAULT)


func get_alternative_cursor(type: CursorType) -> CursorType:
	match type:
		CursorType.HOVER: return CursorType.ATTACK
		CursorType.INTERACT1: return CursorType.INTERACT2
	return type
