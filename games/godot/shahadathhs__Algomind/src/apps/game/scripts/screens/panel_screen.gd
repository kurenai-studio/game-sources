class_name PanelScreen
extends ScreenBase
## The shared frame of the list screens (Profile, Badges, Leaderboard, Daily): a back tile, a
## small caption and a title, a scrolling list, and up to three actions at the bottom (primary,
## secondary, tertiary from the top down). Subclasses fill `_list` in `_populate` and set the
## actions with `_set_action`; `_populate` may run again whenever the state changes.
## `args["back"]` and `args["back_args"]` name where Back returns to.

var _back: TileButton
var _caption: Label
var _title: Label
var _scroll: ScrollContainer
var _list: VBoxContainer
var _primary: TileButton
var _secondary: TileButton
var _tertiary: TileButton


func _build() -> void:
	_back = TileButton.make(TileButton.Kind.SECONDARY, "", "back")
	_back.accessibility_name = "Back"
	_back.pressed.connect(go_back)
	add_child(_back)
	_caption = UiKit.label(_caption_text(), 14, Palette.MUTE, 3)
	add_child(_caption)
	_title = UiKit.label(_title_text(), 34, Palette.INK, 1)
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(_title)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_scroll.add_child(_list)
	_primary = _action_button(TileButton.Kind.PRIMARY, 24)
	_secondary = _action_button(TileButton.Kind.SECONDARY, 18)
	_tertiary = _action_button(TileButton.Kind.TERTIARY, 16)


func go_back() -> void:
	navigate.emit(str(args.get("back", "home")), args.get("back_args", {}))


func _caption_text() -> String:
	return ""


func _title_text() -> String:
	return ""


## The width a line of text in the list can use.
func _content_width() -> float:
	var width := size.x - 2.0 * margin()
	return width if width > 0.0 else 328.0


## Removes everything from the list so `_populate` can build it again.
func _clear_list() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


## Shows an action with this label (hides it for ""), and what it does.
func _set_action(button: TileButton, text: String = "", handler: Callable = Callable()) -> void:
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection["callable"])
	button.visible = not text.is_empty()
	button.label = text
	button.accessibility_name = text
	if handler.is_valid():
		button.pressed.connect(handler)
	button.queue_redraw()
	_layout()


func _action_button(kind: TileButton.Kind, font_px: int) -> TileButton:
	var button := TileButton.make(kind, "", "", font_px)
	button.visible = false
	add_child(button)
	return button


func _layout() -> void:
	if _tertiary == null:
		return
	var m := margin()
	var width := size.x - 2.0 * m
	var top := inset_top() + (28.0 if size.y >= 700.0 else 12.0)
	_back.position = Vector2(m, top)
	_back.size = Vector2(44.0, 44.0)
	_caption.position = Vector2(m, top + 54.0)
	_caption.size = Vector2(width, 18.0)
	_title.position = Vector2(m, top + 70.0)
	_title.size = Vector2(width, 40.0)
	var cursor := size.y - inset_bottom() - m
	var primary_h := 64.0 if size.y >= 700.0 else 56.0
	for item: Array in [[_tertiary, 48.0], [_secondary, 52.0], [_primary, primary_h]]:
		var button: TileButton = item[0]
		if not button.visible:
			continue
		button.size = Vector2(width, item[1])
		button.position = Vector2(m, cursor - item[1])
		cursor -= item[1] + 8.0
	var list_top := top + 126.0
	_scroll.position = Vector2(m, list_top)
	_scroll.size = Vector2(width, maxf(cursor - list_top, 40.0))
	_list.custom_minimum_size = Vector2(width, 0)
