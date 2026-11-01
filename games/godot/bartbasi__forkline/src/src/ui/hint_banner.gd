# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name HintBanner
extends BattlePanel
## A level's one line hint (RULES 9.6). It shows at the start of the level the first
## time it is played, next to a glow on the thing it talks about. A tap anywhere on it
## closes it, and the screen closes it when the first wave starts. In portrait it takes
## no height from the map: the screen puts it at the top of the dock when that stays under
## the map, else over a band of map rows with nothing in it to see or tap
## (BattleScreen._place_hint). It is as tall as one 48 dp touch target. The hint always
## stays on the level card.

const HEIGHT: float = 152.0

var text_label: Label
var close_mark: TextureRect

var _down: bool = false
var _down_at: Vector2 = Vector2.ZERO
var _travel: float = 0.0


func _init() -> void:
	super()
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 16)
	var mark: TextureRect = TextureRect.new()
	mark.texture = IconTex.make(&"arrow", 64)
	mark.custom_minimum_size = Vector2(52.0, 52.0)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.modulate = Palette.HONEY
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(mark)
	text_label = UiKit.label("", &"Label")
	text_label.add_theme_font_size_override(&"font_size", UiTheme.FONT_SMALL)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text_label)
	close_mark = TextureRect.new()
	close_mark.texture = IconTex.make(&"close", 64)
	close_mark.custom_minimum_size = Vector2(48.0, 48.0)
	close_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	close_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	close_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_mark.modulate = Palette.TEXT_SOFT
	close_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(close_mark)
	custom_minimum_size.y = HEIGHT
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	closed.connect(func() -> void: visible = false)
	visible = false


## A tap anywhere on the banner closes it: the finger comes up on it after moving less
## than TapButton.DEADZONE.
func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_down = true
			_down_at = button.position
			_travel = 0.0
		else:
			var tapped: bool = _down and _travel < TapButton.DEADZONE
			_down = false
			if tapped:
				tap()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _down:
		_travel = maxf(_travel, motion.position.distance_to(_down_at))


## Closes the banner, as a tap on it does.
func tap() -> void:
	if visible:
		closed.emit()


## Shows the hint. An empty text hides the banner.
func show_hint(text: String) -> void:
	text_label.text = text
	visible = not text.is_empty()


func dismiss() -> void:
	if visible:
		closed.emit()
