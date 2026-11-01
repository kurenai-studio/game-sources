# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name TapRow
extends MarginContainer
## A tappable row of any height. The content sits in a panel; a see-through
## TapButton lies over it and gives the clean tap (deadzone, no tap at the end of
## a scroll). The row is at least Layout.MIN_TOUCH tall.

signal tapped()

var panel: PanelContainer
var body: VBoxContainer
var overlay: TapButton


func _init(panel_variation: StringName = &"PanelContainer") -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(Layout.MIN_TOUCH, Layout.MIN_TOUCH)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel = PanelContainer.new()
	panel.theme_type_variation = panel_variation
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	body = VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override(&"separation", 8)
	panel.add_child(body)
	overlay = TapButton.new()
	overlay.flat = true
	overlay.custom_minimum_size = Vector2.ZERO
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.tapped.connect(func() -> void: tapped.emit())
	add_child(overlay)


## Gives the panel its own flat look: a fill, an edge and a border width. A chosen
## row uses a thick honey edge, so a choice differs by shape and not only by color.
func set_look(fill: Color, edge: Color, border: int, margin: int = 28) -> void:
	panel.add_theme_stylebox_override(&"panel", UiKit.box(fill, edge, border, UiTheme.RADIUS, margin))


func reset_look() -> void:
	panel.remove_theme_stylebox_override(&"panel")
