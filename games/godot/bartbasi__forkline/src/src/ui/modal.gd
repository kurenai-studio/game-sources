# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Modal
extends Control
## Base of Settings, Pause and the confirm dialog: a dimmed screen with one
## panel in the middle. The dim catches every touch, so nothing below reacts.
## There is no tap-outside-to-close: every way out is a button.

## The modal is done. The App frees it.
signal closed()

const CARD_MAX: float = 1000.0

var card: PanelContainer
## Put the rows here. The title is the first child.
var body: VBoxContainer
var title_label: Label

var _margin: MarginContainer


func _init(title: String) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.1, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(center)
	card = PanelContainer.new()
	center.add_child(card)
	body = VBoxContainer.new()
	body.add_theme_constant_override(&"separation", 20)
	card.add_child(body)
	title_label = UiKit.label(title, &"TitleLabel")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title_label)
	card.custom_minimum_size.x = CARD_MAX


## Called by the App on start and on every resize.
func apply_layout(window_size: Vector2, safe: Rect2) -> void:
	var left: float = safe.position.x + Layout.PAD
	var top: float = safe.position.y + Layout.PAD
	var right: float = window_size.x - safe.end.x + Layout.PAD
	var bottom: float = window_size.y - safe.end.y + Layout.PAD
	_margin.add_theme_constant_override(&"margin_left", roundi(left))
	_margin.add_theme_constant_override(&"margin_top", roundi(top))
	_margin.add_theme_constant_override(&"margin_right", roundi(right))
	_margin.add_theme_constant_override(&"margin_bottom", roundi(bottom))
	card.custom_minimum_size.x = minf(CARD_MAX, maxf(Layout.MIN_TOUCH, window_size.x - left - right))


## The back button asks this modal to close. Override when closing means
## something else (a dialog cancels, Pause resumes).
func request_close() -> void:
	closed.emit()
