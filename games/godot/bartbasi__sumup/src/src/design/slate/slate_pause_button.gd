extends "res://src/design/shared/press_button.gd"
## Slate's HUD pause button (DESIGN_SYSTEM.md 5.7): the icon_hud pause icon
## with no container, at the top of a touch_min touch area and centered
## across it. While held, the whole touch area fills surface; Slate does not
## scale. It draws behind its parent, so the HUD's BEST text, which the touch
## area reaches, stays on top of the held fill (ink and ink_muted on surface
## are listed pairs).

const SlateIcon: GDScript = preload("res://src/design/slate/slate_icon.gd")

var _icon: SkinIcon = null


func _init() -> void:
	show_behind_parent = true


func setup(skin: SkinData) -> void:
	_skin = skin
	if _icon == null:
		_icon = SlateIcon.new()
		add_child(_icon)
	_icon.setup(skin)
	_icon.set_icon(&"pause")
	var touch: float = skin.num(&"touch_min")
	size = Vector2(touch, touch)
	_layout()


func _layout() -> void:
	if _skin == null:
		return
	var side: float = _skin.num(&"icon_hud")
	_icon.size = Vector2(side, side)
	_icon.position = Vector2((size.x - side) * 0.5, 0.0)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _draw() -> void:
	if _skin != null and held:
		draw_rect(Rect2(Vector2.ZERO, size), _skin.color(&"surface"))
