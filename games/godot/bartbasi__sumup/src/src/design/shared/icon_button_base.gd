extends BaseButton
## What the three skins' icon buttons share (UiKit.make_icon_button): a
## touch_min square button that draws its skin's IconButton theme styles
## (normal, pressed, disabled) and the skin's icon centered on the face. The
## icon follows the face, so it sinks with Gumdrop's pressed face and drops
## with its flat disabled face. The button presses with Motion.press while
## held and springs back with Motion.release.
##
## Taps are read here by TapInput, one rule for every design control (QA6-01):
## a finger, a real mouse click, or ui_accept while focused, and never the
## copies Godot's mouse and touch emulation make. Every tap event is accepted
## here, so BaseButton's own input handling never sees it and pressed fires
## exactly once per tap. A tap (press, then release inside) emits the
## built-in pressed signal; with toggle_mode it also flips button_pressed. A
## disabled button does nothing. It takes no keyboard focus by default: this
## is a touch game. Each skin's button extends this and names its icon and
## styles.

const TapInput: GDScript = preload("res://src/design/shared/tap_input.gd")

var _skin: SkinData = null
var _icon: SkinIcon = null
var _tap: TapInput = TapInput.new()
var _styles: Dictionary[StringName, StyleBox] = {}
var _held: bool = false
## The state the icon was last placed for, so _draw only moves it on change.
var _placed_state: StringName = &""
var _placed_size: Vector2 = Vector2(-1.0, -1.0)


func _init() -> void:
	focus_mode = Control.FOCUS_NONE


## Sets the button up for skin with the named icon (SkinIcon.ICON_NAMES).
func setup(skin: SkinData, icon_name: StringName) -> void:
	_skin = skin
	_styles = _make_styles(skin)
	if _icon == null:
		_icon = _make_icon()
		_icon.name = "Icon"
		add_child(_icon)
	_icon.setup(skin)
	_icon.set_icon(icon_name)
	var touch: float = skin.num(&"touch_min")
	custom_minimum_size = Vector2(touch, touch)
	if size.x < touch or size.y < touch:
		size = custom_minimum_size
	_place_icon()
	queue_redraw()


## The icon on the face. For tests and for screens that need its name.
func icon_view() -> SkinIcon:
	return _icon


## The style the button shows now: disabled, pressed (held, or a toggle
## that is on) or normal.
func state() -> StringName:
	if disabled:
		return &"disabled"
	if _held or (toggle_mode and button_pressed):
		return &"pressed"
	return &"normal"


## The skin's icon, new. Each skin overrides it.
func _make_icon() -> SkinIcon:
	push_error("%s makes no icon" % (get_script() as Script).resource_path)
	return SkinIcon.new()


## The skin's IconButton styles. Each skin overrides it.
func _make_styles(_for_skin: SkinData) -> Dictionary[StringName, StyleBox]:
	push_error("%s has no styles" % (get_script() as Script).resource_path)
	return {}


func _gui_input(event: InputEvent) -> void:
	if _skin == null:
		return
	var read: int = _tap.read(event, size)
	if read == TapInput.IGNORED:
		return
	accept_event()
	if disabled:
		_drop_hold()
		return
	match read:
		TapInput.PRESSED:
			_held = true
			Motion.press(self, _skin)
			queue_redraw()
		TapInput.TAPPED, TapInput.LIFTED:
			_held = false
			Motion.release(self, _skin)
			queue_redraw()
			if read == TapInput.TAPPED:
				if toggle_mode:
					button_pressed = not button_pressed
				pressed.emit()


## Ends a press with no tap and no motion.
func _drop_hold() -> void:
	_tap.reset()
	if _held:
		_held = false
		scale = Vector2.ONE
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_place_icon()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and _held and not is_visible_in_tree():
		# A button hidden while held would otherwise stay pressed.
		_drop_hold()


func _draw() -> void:
	if _skin == null:
		return
	var current: StringName = state()
	# disabled and toggle changes redraw the button but send no notification
	# of their own, so the icon catches up here.
	if current != _placed_state or size != _placed_size:
		_place_icon()
	draw_style_box(_styles[current], Rect2(Vector2.ZERO, size))


## Centers the icon on the current state's face and gives it the state's look.
func _place_icon() -> void:
	if _skin == null or _icon == null:
		return
	var current: StringName = state()
	_placed_state = current
	_placed_size = size
	var side: float = _skin.num(&"icon_hud")
	var face: Rect2 = _face(_styles[current])
	_icon.size = Vector2(side, side)
	_icon.position = face.get_center() - _icon.size * 0.5
	_icon.set_look(SkinIcon.LOOK_DISABLED if current == &"disabled" else SkinIcon.LOOK_NORMAL)


## The face a style draws in the button's rect: the rect moved by the style's
## expand margins, less a lip (a bottom border thicker than the top one).
func _face(style: StyleBox) -> Rect2:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var flat: StyleBoxFlat = style as StyleBoxFlat
	if flat == null:
		return rect
	rect = rect.grow_individual(flat.expand_margin_left, flat.expand_margin_top, flat.expand_margin_right, flat.expand_margin_bottom)
	if flat.border_width_bottom > flat.border_width_top:
		rect.size.y -= float(flat.border_width_bottom)
	return rect
