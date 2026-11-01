extends Control
## The frame every dialog panel shares (DESIGN_SYSTEM.md section 7):
## - the skin's scrim over the whole screen, which also takes every touch
##   meant for what is below it;
## - the skin's dialog panel (the CardPanel variation) anchored to the bottom
##   of the safe area, in the thumb zone, inside the content column (2.8). A
##   floating card (Gumdrop) sits board_margin inside the column and from the
##   bottom; a sheet (Slate, Nova) spans the column, reaches the screen's
##   bottom edge and pads its content by the bottom inset (2.2). On phones
##   the column is the whole width, so a sheet runs edge to edge.
## It comes in with dialog_in over the scrim and leaves with dialog_out.
##
## Subclasses call _frame(skin) at the start of setup and add their content to
## _content. The panel must be in the tree when setup runs, so the theme is
## there to read.

const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")
const Copy: GDScript = preload("res://src/ui/screen_copy.gd")

var _skin: SkinData = null
var _scrim: ColorRect = null
var _panel: PanelContainer = null
var _content: VBoxContainer = null
var _inset_pad: Control = null
var _closing: bool = false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## True once close() has started; the panel then takes no more input.
func is_closing() -> bool:
	return _closing


## Brings the panel in. Waits one frame so the panel has its final size.
func play_in() -> void:
	if _panel == null or not is_inside_tree():
		return
	_scrim.modulate.a = 0.0
	_panel.modulate.a = 0.0
	get_tree().process_frame.connect(_start_in, CONNECT_ONE_SHOT)


func _start_in() -> void:
	if _closing or _panel == null:
		return
	_layout()
	Motion.fade(_scrim, _skin, 1.0)
	Motion.dialog_in(_panel, _skin)


## Takes the panel out and frees it. It stops taking input at once.
func close() -> void:
	if _closing:
		return
	_closing = true
	_ignore_input(self)
	if not is_inside_tree() or _panel == null:
		queue_free()
		return
	Motion.fade(_scrim, _skin, 0.0)
	var tween: Tween = Motion.dialog_out(_panel, _skin)
	tween.finished.connect(queue_free)


## Clears the panel and builds the empty frame for skin.
func _frame(skin: SkinData) -> void:
	_skin = skin
	UiParts.clear(self)
	_scrim = ColorRect.new()
	_scrim.name = "Scrim"
	_scrim.color = skin.color(&"scrim")
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_scrim)
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme_type_variation = &"CardPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	var column: VBoxContainer = UiParts.vbox(0.0)
	_panel.add_child(column)
	_content = UiParts.vbox(skin.num(&"space_m"))
	_content.name = "Content"
	column.add_child(_content)
	_inset_pad = Control.new()
	_inset_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_inset_pad)
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
		_layout()


func _layout() -> void:
	if _panel == null or _skin == null or not is_inside_tree():
		return
	layout_in(get_global_rect(), SafeArea.content_column(get_viewport(), _skin), UiParts.panel_floats(self))


## The panel's place for the panel's own rect and the content column, both in
## the same (global) coordinates. floats: the skin's panel is a floating card.
## _layout calls it; tests call it with rects of their own, since headless
## tests never enter the scene tree.
func layout_in(screen: Rect2, column: Rect2, floats: bool) -> void:
	if _panel == null or _skin == null:
		return
	var origin: Vector2 = screen.position
	var size_now: Vector2 = screen.size
	var inner: Rect2 = Rect2(column.position - origin, column.size)
	var left: float = inner.position.x
	var right: float = maxf(0.0, size_now.x - inner.end.x)
	var bottom: float = 0.0
	var pad: float = maxf(0.0, size_now.y - inner.end.y)
	if floats:
		var margin: float = _skin.num(&"board_margin")
		left += margin
		right += margin
		bottom = pad + margin
		pad = 0.0
	_inset_pad.custom_minimum_size = Vector2(0.0, pad)
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = left
	_panel.offset_right = -right
	_panel.offset_bottom = -bottom
	_panel.offset_top = -bottom


## The skin's dialog panel. For tests.
func panel() -> PanelContainer:
	return _panel


static func _ignore_input(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_ignore_input(child)
