extends SkinBoosterBar
## What the three skins' booster bars share: one button per status, reused
## across calls, the hint text, and a badge layer drawn over the buttons for
## the Suggested badges. Each skin's bar extends this, makes its buttons and
## lays them out.
##
## The Suggested badges hide while any shown booster is active (targeting
## from the offer), in every skin, and come back when none is
## (DESIGN_SYSTEM.md 4.7). Each skin asks badges_shown() when it places them.

const BoosterButtonBase: GDScript = preload("res://src/design/shared/booster_button_base.gd")
const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")

var _skin: SkinData = null
var _buttons: Array[BoosterButtonBase] = []
## The hint as shown, cased.
var _hint: String = ""
## Draws the Suggested badges above the buttons.
var _badges: Control = null
## Whether any shown status is active (targeting).
var _any_active: bool = false
## Suggested badge rects and their text origins, in bar space. Each skin fills
## them in _place() and draws them in _draw_badges().
var _badge_rects: Array[Rect2] = []
var _badge_origins: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData) -> void:
	_skin = skin
	if _badges == null:
		_badges = Control.new()
		_badges.name = "Badges"
		_badges.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badges.draw.connect(_draw_badges)
		add_child(_badges)
	_on_setup()
	for button: BoosterButtonBase in _buttons:
		button.setup(skin)
	_layout()


func show_boosters(statuses: Array[BoosterStatus]) -> void:
	while _buttons.size() > statuses.size():
		var extra: BoosterButtonBase = _buttons.pop_back()
		remove_child(extra)
		extra.queue_free()
	while _buttons.size() < statuses.size():
		var button: BoosterButtonBase = _make_button()
		button.tapped.connect(_on_tapped.bind(button))
		add_child(button)
		_buttons.append(button)
		if _skin != null:
			button.setup(_skin)
	if _badges != null:
		move_child(_badges, get_child_count() - 1)
	_any_active = false
	for i: int in statuses.size():
		_buttons[i].show_status(statuses[i])
		_any_active = _any_active or statuses[i].active
	_layout()


func set_hint(text: String) -> void:
	_hint = _skin.cased(&"label", text) if _skin != null else text
	_layout()


func preferred_height() -> float:
	return _skin.num(&"bar_height") if _skin != null else 0.0


## The buttons, in bar order. For screens' layout checks and for tests.
func buttons() -> Array[Control]:
	var out: Array[Control] = []
	for button: BoosterButtonBase in _buttons:
		out.append(button)
	return out


## The hint as shown, cased; "" when hidden.
func hint_text() -> String:
	return _hint


## Whether Suggested badges show now: not while any booster is active.
func badges_shown() -> bool:
	return not _any_active


## Suggested badges placed now. For tests.
func badge_count() -> int:
	return _badge_rects.size()


## Called by setup(), for the skin to read its tokens.
func _on_setup() -> void:
	pass


## A new button of the skin's own kind.
func _make_button() -> BoosterButtonBase:
	push_error("%s makes no booster buttons" % (get_script() as Script).resource_path)
	return BoosterButtonBase.new()


## Places everything for the current size and redraws.
func _layout() -> void:
	if _skin == null:
		return
	_badges.position = Vector2.ZERO
	_badges.size = size
	_badge_rects.clear()
	_badge_origins.clear()
	_place()
	queue_redraw()
	_badges.queue_redraw()


## Places the buttons and works out the hint and badge geometry in the
## current size. Each skin overrides it.
func _place() -> void:
	pass


## Draws the Suggested badges on _badges. Each skin overrides it.
func _draw_badges() -> void:
	pass


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized outside the tree gets
	# no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _on_tapped(button: BoosterButtonBase) -> void:
	booster_pressed.emit(button.booster_id)
