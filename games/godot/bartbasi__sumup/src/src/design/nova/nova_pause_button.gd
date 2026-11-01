extends "res://src/design/shared/press_button.gd"
## Nova's HUD pause button (DESIGN_SYSTEM.md 6.7): the icon_hud pause icon in
## a hud_ring ring, ring_width wide, in line, centered in a touch_min touch
## area. While held it presses with Motion and the ring brightens to ink.

const NovaIcon: GDScript = preload("res://src/design/nova/nova_icon.gd")
const NovaRing: GDScript = preload("res://src/design/nova/nova_ring.gd")

var _ring: NovaRing = null
var _icon: SkinIcon = null


func setup(skin: SkinData) -> void:
	_skin = skin
	if _icon == null:
		_ring = NovaRing.new()
		add_child(_ring)
		_icon = NovaIcon.new()
		add_child(_icon)
	_icon.setup(skin)
	_icon.set_icon(&"pause")
	var touch: float = skin.num(&"touch_min")
	size = Vector2(touch, touch)
	_layout()
	_held_changed()


func _held_changed() -> void:
	if _skin == null:
		return
	var color: Color = _skin.color(&"ink") if held else _skin.color(&"line")
	_ring.show_ring(NovaRing.STYLE_SOLID, color, _skin.num(&"ring_width"))


func _layout() -> void:
	if _skin == null:
		return
	var ring: float = _skin.num(&"hud_ring")
	_ring.size = Vector2(ring, ring)
	_ring.position = (size - _ring.size) * 0.5
	var side: float = _skin.num(&"icon_hud")
	_icon.size = Vector2(side, side)
	_icon.position = (size - _icon.size) * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()
