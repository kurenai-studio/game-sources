extends "res://src/design/shared/press_button.gd"
## Gumdrop's HUD pause button (DESIGN_SYSTEM.md 4.7): a raised squircle face
## hud_button_face wide (corners tile_radius of the face, like a tile) with an
## icon_hud pause icon, in a touch_min touch area. The face sits at the top of
## the touch area, its left edge where the control's face_left says.

const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")
const GumdropIcon: GDScript = preload("res://src/design/gumdrop/gumdrop_icon.gd")

var _normal: StyleBoxFlat = null
var _held_style: StyleBoxFlat = null
var _icon: SkinIcon = null
var _rest: Rect2 = Rect2()


func setup(skin: SkinData) -> void:
	_skin = skin
	var face: float = skin.num(&"hud_button_face")
	var radius: float = skin.num(&"tile_radius") * face
	_normal = Candy.style(skin, Candy.LOOK_NORMAL, false, radius)
	_held_style = Candy.style(skin, Candy.LOOK_NORMAL, true, radius)
	if _icon == null:
		_icon = GumdropIcon.new()
		add_child(_icon)
	_icon.setup(skin)
	_icon.set_icon(&"pause")
	var touch: float = skin.num(&"touch_min")
	size = Vector2(touch, touch)
	_layout()


## The face and lip at rest, in local space: centered across, at the top.
func rest_rect() -> Rect2:
	return _rest


func _layout() -> void:
	if _skin == null:
		return
	var face: float = _skin.num(&"hud_button_face")
	_rest = Rect2((size.x - face) * 0.5, 0.0, face, face + _skin.num(&"button_lip"))
	var icon_side: float = _skin.num(&"icon_hud")
	var face_rect: Rect2 = Candy.face_rect(_skin, _rest, Candy.LOOK_NORMAL, held)
	_icon.size = Vector2(icon_side, icon_side)
	_icon.position = face_rect.get_center() - _icon.size * 0.5
	queue_redraw()


func _held_changed() -> void:
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _draw() -> void:
	if _skin == null:
		return
	var style: StyleBoxFlat = _held_style if held else _normal
	draw_style_box(style, Candy.style_rect(_skin, _rest, Candy.LOOK_NORMAL, held))
